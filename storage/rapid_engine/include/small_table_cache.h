/**
   This program is free software; you can redistribute it and/or modify
   it under the terms of the GNU General Public License, version 2.0,
   as published by the Free Software Foundation.

   Copyright (c) 2025, Shannon Data AI and/or its affiliates.
*/
/**
 * Small Table Cache for Rapid Engine
 * 
 * Caches small lookup tables in row format for efficient nested loop joins.
 * When joining large fact tables with small dimension tables, storing the
 * dimension tables in row format dramatically improves nested loop performance.
 */
#ifndef STORAGE_RAPID_ENGINE_SMALL_TABLE_CACHE_H_
#define STORAGE_RAPID_ENGINE_SMALL_TABLE_CACHE_H_

#include <memory>
#include <unordered_map>
#include <vector>
#include <string>
#include <mutex>

#include "sql/table.h"

namespace ShannonBase {

// Threshold for caching tables (tables with <= this many rows are cached)
constexpr size_t SMALL_TABLE_CACHE_THRESHOLD = 10000;

// Cached row data
struct CachedRow {
  std::unique_ptr<uchar[]> data;  // Row data in MySQL format
  size_t length;                   // Row length in bytes
  
  CachedRow(const uchar *src, size_t len) : length(len) {
    data.reset(new uchar[len]);
    memcpy(data.get(), src, len);
  }
  
  CachedRow(CachedRow &&other) noexcept 
    : data(std::move(other.data)), length(other.length) {}
  
  CachedRow &operator=(CachedRow &&other) noexcept {
    if (this != &other) {
      data = std::move(other.data);
      length = other.length;
    }
    return *this;
  }
  
  // No copy
  CachedRow(const CachedRow &) = delete;
  CachedRow &operator=(const CachedRow &) = delete;
};

// Cached table data
class CachedTable {
 public:
  std::vector<CachedRow> rows;
  size_t row_length;
  TABLE *table;  // Reference to original table definition
  
  CachedTable(TABLE *tbl) : row_length(tbl->s->rec_buff_length), table(tbl) {
    rows.reserve(SMALL_TABLE_CACHE_THRESHOLD);
  }
  
  void AddRow(const uchar *row_data) {
    rows.emplace_back(row_data, row_length);
  }
  
  size_t RowCount() const { return rows.size(); }
  
  const uchar *GetRow(size_t index) const {
    return (index < rows.size()) ? rows[index].data.get() : nullptr;
  }
};

// Global cache for small tables
class SmallTableCache {
 public:
  static SmallTableCache &Instance() {
    static SmallTableCache instance;
    return instance;
  }
  
  // Check if table should be cached
  static bool ShouldCache(TABLE *table) {
    if (!table || !table->file) return false;
    
    // Only cache tables with known small row counts
    ha_rows rows = table->file->stats.records;
    return (rows > 0 && rows <= SMALL_TABLE_CACHE_THRESHOLD);
  }
  
  // Load table into cache
  std::shared_ptr<CachedTable> LoadTable(TABLE *table);
  
  // Get cached table
  std::shared_ptr<CachedTable> GetTable(TABLE *table);
  
  // Clear cache (for memory management)
  void Clear();
  
  // Get cache statistics
  struct CacheStats {
    size_t cached_tables;
    size_t total_rows;
    size_t memory_used;
  };
  
  CacheStats GetStats() const;
  
 private:
  SmallTableCache() = default;
  ~SmallTableCache() { Clear(); }
  
  // Cache key: database_name.table_name
  std::string GetCacheKey(TABLE *table) const {
    return std::string(table->s->db.str) + "." + std::string(table->s->table_name.str);
  }
  
  mutable std::mutex mutex_;
  std::unordered_map<std::string, std::shared_ptr<CachedTable>> cache_;
};

}  // namespace ShannonBase

#endif  // STORAGE_RAPID_ENGINE_SMALL_TABLE_CACHE_H_
