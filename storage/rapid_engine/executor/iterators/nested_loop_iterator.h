/**
   This program is free software; you can redistribute it and/or modify
   it under the terms of the GNU General Public License, version 2.0,
   as published by the Free Software Foundation.

   Copyright (c) 2025, Shannon Data AI and/or its affiliates.
*/
/**
 * Optimized Nested Loop Iterator for Rapid Engine
 * 
 * Phase 2 Enhancement: Optimizes nested loop joins by:
 * 1. Caching small inner tables in row format
 * 2. Efficient in-memory nested loop for cached tables
 * 3. Fallback to standard iteration for large tables
 */
#ifndef STORAGE_RAPID_ENGINE_NESTED_LOOP_ITERATOR_H_
#define STORAGE_RAPID_ENGINE_NESTED_LOOP_ITERATOR_H_

#include <memory>
#include "sql/iterators/row_iterator.h"
#include "sql/join_type.h"
#include "storage/rapid_engine/include/small_table_cache.h"

namespace ShannonBase {
namespace Executor {

/**
 * Optimized Nested Loop Iterator
 * 
 * Implements efficient nested loop joins for columnar storage by:
 * - Detecting and caching small inner tables
 * - Using row-format cache for fast inner loop scans
 * - Minimizing columnar data access overhead
 */
class OptimizedNestedLoopIterator final : public RowIterator {
 public:
  /**
   * Constructor
   * 
   * @param thd Thread handle
   * @param outer_iterator Iterator for outer table
   * @param inner_iterator Iterator for inner table  
   * @param join_type Type of join (INNER, LEFT, etc.)
   * @param pfs_batch_mode Performance schema batch mode
   */
  OptimizedNestedLoopIterator(
      THD *thd,
      unique_ptr_destroy_only<RowIterator> outer_iterator,
      unique_ptr_destroy_only<RowIterator> inner_iterator,
      JoinType join_type,
      bool pfs_batch_mode);
  
  ~OptimizedNestedLoopIterator() override = default;
  
  bool Init() override;
  int Read() override;
  
  void SetNullRowFlag(bool is_null_row) override {
    outer_iterator_->SetNullRowFlag(is_null_row);
    inner_iterator_->SetNullRowFlag(is_null_row);
  }
  
  void UnlockRow() override {
    outer_iterator_->UnlockRow();
    inner_iterator_->UnlockRow();
  }
  
  void EndPSIBatchModeIfStarted() override {
    outer_iterator_->EndPSIBatchModeIfStarted();
    inner_iterator_->EndPSIBatchModeIfStarted();
  }
  
 private:
  enum class State {
    READING_FIRST_OUTER_ROW,   // Initial state
    READING_FROM_CACHE,         // Scanning cached inner table
    READING_FROM_ITERATOR,      // Scanning non-cached inner table
    END_OF_OUTER_ROWS,          // No more outer rows
    END_OF_JOIN                 // Join complete
  };
  
  // Read next outer row
  int ReadOuterRow();
  
  // Scan cached inner table
  int ScanCachedInnerTable();
  
  // Scan inner table via iterator
  int ScanInnerIterator();
  
  // Check if inner table should be cached
  bool ShouldCacheInnerTable();
  
  // Load inner table into cache
  bool LoadInnerTableCache();
  
  THD *thd_;
  unique_ptr_destroy_only<RowIterator> outer_iterator_;
  unique_ptr_destroy_only<RowIterator> inner_iterator_;
  JoinType join_type_;
  bool pfs_batch_mode_;
  
  State state_;
  std::shared_ptr<CachedTable> cached_inner_table_;
  size_t current_inner_row_index_;
  bool outer_row_matched_;
  
  // Statistics
  uint64_t outer_rows_scanned_;
  uint64_t inner_rows_scanned_;
  uint64_t cache_hits_;
};

}  // namespace Executor
}  // namespace ShannonBase

#endif  // STORAGE_RAPID_ENGINE_NESTED_LOOP_ITERATOR_H_
