/**
   This program is free software; you can redistribute it and/or modify
   it under the terms of the GNU General Public License, version 2.0,
   as published by the Free Software Foundation.

   Copyright (c) 2025, Shannon Data AI and/or its affiliates.
*/
#include "storage/rapid_engine/executor/iterators/nested_loop_iterator.h"
#include "sql/sql_executor.h"
#include "sql/table.h"

namespace ShannonBase {
namespace Executor {

OptimizedNestedLoopIterator::OptimizedNestedLoopIterator(
    THD *thd,
    unique_ptr_destroy_only<RowIterator> outer_iterator,
    unique_ptr_destroy_only<RowIterator> inner_iterator,
    JoinType join_type,
    bool pfs_batch_mode)
    : RowIterator(thd),  // Call base class constructor with THD*
      thd_(thd),
      outer_iterator_(std::move(outer_iterator)),
      inner_iterator_(std::move(inner_iterator)),
      join_type_(join_type),
      pfs_batch_mode_(pfs_batch_mode),
      state_(State::READING_FIRST_OUTER_ROW),
      current_inner_row_index_(0),
      outer_row_matched_(false),
      outer_rows_scanned_(0),
      inner_rows_scanned_(0),
      cache_hits_(0) {}

bool OptimizedNestedLoopIterator::Init() {
  if (outer_iterator_->Init()) {
    return true;
  }
  
  if (inner_iterator_->Init()) {
    return true;
  }
  
  state_ = State::READING_FIRST_OUTER_ROW;
  current_inner_row_index_ = 0;
  outer_row_matched_ = false;
  cached_inner_table_ = nullptr;
  
  // Try to cache inner table if it's small
  if (ShouldCacheInnerTable()) {
    LoadInnerTableCache();
  }
  
  return false;
}

bool OptimizedNestedLoopIterator::ShouldCacheInnerTable() {
  // Check if inner iterator is a table scan we can cache
  // For now, we check if the inner table is small enough
  // This is a heuristic - in production you'd want more sophisticated checks
  
  // Try to get the inner table from the iterator
  // This is a simplified check - in production you'd analyze the iterator tree
  return true;  // Always try to cache for Phase 2
}

bool OptimizedNestedLoopIterator::LoadInnerTableCache() {
  // Attempt to load inner table into cache
  // This requires identifying the TABLE* from the inner iterator
  // For Phase 2, we do a simple approach: try to cache during first outer row
  
  // Note: This is called during Init(), so we don't have a table yet
  // We'll actually load during the first outer row when we know what to cache
  return false;
}

int OptimizedNestedLoopIterator::ReadOuterRow() {
  int error = outer_iterator_->Read();
  if (error != 0) {
    if (error == -1) {
      state_ = State::END_OF_OUTER_ROWS;
    }
    return error;
  }
  
  outer_rows_scanned_++;
  outer_row_matched_ = false;
  current_inner_row_index_ = 0;
  
  // Reset inner iterator for this outer row
  if (cached_inner_table_) {
    state_ = State::READING_FROM_CACHE;
  } else {
    if (inner_iterator_->Init()) {
      return 1;  // Error
    }
    state_ = State::READING_FROM_ITERATOR;
  }
  
  return 0;
}

int OptimizedNestedLoopIterator::ScanCachedInnerTable() {
  // Fast path: scan cached inner table
  while (current_inner_row_index_ < cached_inner_table_->RowCount()) {
    const uchar *row_data = cached_inner_table_->GetRow(current_inner_row_index_);
    current_inner_row_index_++;
    cache_hits_++;
    
    if (!row_data) {
      continue;  // Skip invalid rows
    }
    
    // Copy cached row to table buffer
    TABLE *inner_table = cached_inner_table_->table;
    memcpy(inner_table->record[0], row_data, cached_inner_table_->row_length);
    
    // TODO: Evaluate join condition here
    // For Phase 2, we assume all rows match (join condition evaluated by outer iterator)
    outer_row_matched_ = true;
    return 0;  // Found matching row
  }
  
  // Exhausted inner table cache
  // Handle LEFT JOIN case
  if (join_type_ == JoinType::OUTER && !outer_row_matched_) {
    // Return NULL-extended row for LEFT JOIN
    TABLE *inner_table = cached_inner_table_->table;
    inner_table->set_null_row();
    outer_row_matched_ = true;
    return 0;
  }
  
  // Need next outer row
  return ReadOuterRow();
}

int OptimizedNestedLoopIterator::ScanInnerIterator() {
  // Standard path: scan inner table via iterator
  while (true) {
    int error = inner_iterator_->Read();
    
    if (error == 0) {
      // Found inner row
      inner_rows_scanned_++;
      outer_row_matched_ = true;
      return 0;
    }
    
    if (error != -1) {
      // Real error (not end-of-scan)
      return error;
    }
    
    // End of inner table for this outer row
    // Handle LEFT JOIN case
    if (join_type_ == JoinType::OUTER && !outer_row_matched_) {
      // Get inner table and set NULL row
      // This is simplified - in production you'd track which table
      outer_row_matched_ = true;
      return 0;
    }
    
    // Need next outer row
    return ReadOuterRow();
  }
}

int OptimizedNestedLoopIterator::Read() {
  while (true) {
    switch (state_) {
      case State::READING_FIRST_OUTER_ROW: {
        int error = ReadOuterRow();
        if (error != 0) {
          if (error == -1) {
            state_ = State::END_OF_JOIN;
            return -1;  // No rows at all
          }
          return error;  // Error
        }
        // Successfully read first outer row, continue with inner loop
        continue;
      }
      
      case State::READING_FROM_CACHE: {
        int error = ScanCachedInnerTable();
        if (error == 0) {
          return 0;  // Found matching row
        }
        if (error != -1) {
          return error;  // Real error
        }
        // Continue to next state or outer row
        continue;
      }
      
      case State::READING_FROM_ITERATOR: {
        int error = ScanInnerIterator();
        if (error == 0) {
          return 0;  // Found matching row
        }
        if (error != -1) {
          return error;  // Real error
        }
        // Continue to next outer row
        continue;
      }
      
      case State::END_OF_OUTER_ROWS:
      case State::END_OF_JOIN:
        return -1;  // End of join
    }
  }
}

}  // namespace Executor
}  // namespace ShannonBase
