/**
   This program is free software; you can redistribute it and/or modify
   it under the terms of the GNU General Public License, version 2.0,
   as published by the Free Software Foundation.

   Copyright (c) 2025, Shannon Data AI and/or its affiliates.
*/
#include "storage/rapid_engine/include/small_table_cache.h"
#include "sql/handler.h"

namespace ShannonBase {

std::shared_ptr<CachedTable> SmallTableCache::LoadTable(TABLE *table) {
  // TEMPORARY: Disable caching to debug crashes
  // TODO: Re-enable after fixing underlying issue
  return nullptr;
  
  if (!table || !table->file) return nullptr;
  
  std::string key = GetCacheKey(table);
  
  // CRITICAL: Hold lock during entire load to prevent race conditions
  // Multiple threads loading the same table caused crashes
  std::lock_guard<std::mutex> lock(mutex_);
  
  // Double-check if already cached (another thread may have loaded it)
  auto it = cache_.find(key);
  if (it != cache_.end()) {
    return it->second;
  }
  
  // Create new cached table
  auto cached = std::make_shared<CachedTable>(table);
  
  // Scan table and cache all rows (still holding lock!)
  handler *file = table->file;
  int error = file->ha_rnd_init(true);
  if (error) return nullptr;
  
  uchar *record = table->record[0];
  size_t row_count = 0;
  
  while (row_count < SMALL_TABLE_CACHE_THRESHOLD) {
    error = file->ha_rnd_next(record);
    
    if (error == HA_ERR_END_OF_FILE) {
      break;  // End of table
    }
    
    if (error == HA_ERR_RECORD_DELETED) {
      continue;  // Skip deleted rows
    }
    
    if (error) {
      file->ha_rnd_end();
      return nullptr;  // Error reading
    }
    
    // Cache this row
    cached->AddRow(record);
    row_count++;
  }
  
  file->ha_rnd_end();
  
  // Don't cache if too large
  if (row_count > SMALL_TABLE_CACHE_THRESHOLD) {
    return nullptr;
  }
  
  // Store in cache (already holding lock!)
  cache_[key] = cached;
  
  return cached;
}

std::shared_ptr<CachedTable> SmallTableCache::GetTable(TABLE *table) {
  if (!table) return nullptr;
  
  std::string key = GetCacheKey(table);
  
  std::lock_guard<std::mutex> lock(mutex_);
  auto it = cache_.find(key);
  return (it != cache_.end()) ? it->second : nullptr;
}

void SmallTableCache::Clear() {
  std::lock_guard<std::mutex> lock(mutex_);
  cache_.clear();
}

SmallTableCache::CacheStats SmallTableCache::GetStats() const {
  std::lock_guard<std::mutex> lock(mutex_);
  
  CacheStats stats{};
  stats.cached_tables = cache_.size();
  
  for (const auto &pair : cache_) {
    stats.total_rows += pair.second->RowCount();
    stats.memory_used += pair.second->RowCount() * pair.second->row_length;
  }
  
  return stats;
}

}  // namespace ShannonBase
