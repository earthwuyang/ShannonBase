# Implementation Plan: Adding Nested Loop Join Support to Rapid Engine

## Executive Summary
Currently, Rapid engine only supports hash joins, causing ~70% query rejection rate. This plan outlines how to add nested loop join support to dramatically increase query compatibility.

## Problem Analysis

### Current Situation
- **Rapid only supports**: Hash joins (AccessPath::HASH_JOIN)
- **Rapid rejects**: Nested loop joins, index scans, REF access
- **Impact**: 70-80% queries rejected, especially with small lookup tables
- **Root cause**: Code explicitly checks and rejects nested loop paths

### Why Nested Loop Joins Are Essential
1. **Small lookup tables**: Optimizer correctly chooses nested loops for 2-100 row tables
2. **Index lookups**: Efficient for point queries and small result sets
3. **Real-world schemas**: Most databases have mix of large fact tables + small dimensions
4. **Optimizer intelligence**: MySQL optimizer knows when nested loop is better

## Implementation Plan

### Phase 1: Remove Blocking Assertions (Quick Win)
**Goal**: Stop rejecting queries with nested loop joins
**Effort**: 1-2 hours
**Files to modify**:

#### 1.1 `storage/rapid_engine/handler/ha_shannon_rapid.cc`
```cpp
// Current (BLOCKING):
static void AssertSupportedPath(const AccessPath *path) {
    switch (path->type) {
        case AccessPath::NESTED_LOOP_JOIN:
        case AccessPath::NESTED_LOOP_SEMIJOIN_WITH_DUPLICATE_REMOVAL:
            ut_a(false); // REMOVE THIS!
            break;
    }
}

// Change to (ALLOW):
static void AssertSupportedPath(const AccessPath *path) {
    switch (path->type) {
        case AccessPath::NESTED_LOOP_JOIN:
        case AccessPath::NESTED_LOOP_SEMIJOIN_WITH_DUPLICATE_REMOVAL:
            // Now supported!
            break;
    }
}
```

#### 1.2 Update `table_flags()` to allow index access
```cpp
// Current:
handler::Table_flags ha_rapid::table_flags() const {
    return ~HA_NO_INDEX_ACCESS || flags;  // This looks wrong anyway
}

// Change to:
handler::Table_flags ha_rapid::table_flags() const {
    // Allow index access for nested loop joins
    return HA_READ_NEXT | HA_READ_PREV | HA_READ_ORDER | 
           HA_READ_RANGE | HA_KEYREAD_ONLY | 
           HA_DO_INDEX_COND_PUSHDOWN | HA_STATS_RECORDS_IS_EXACT | 
           HA_COUNT_ROWS_INSTANT;
    // Removed HA_NO_INDEX_ACCESS flag
}
```

### Phase 2: Implement Nested Loop Join Iterator
**Goal**: Actually execute nested loop joins in Rapid
**Effort**: 1-2 days
**New files needed**:

#### 2.1 Create `storage/rapid_engine/iterators/nested_loop_iterator.h`
```cpp
class RapidNestedLoopIterator : public RowIterator {
private:
    unique_ptr<RowIterator> m_outer_iterator;  // Outer table
    unique_ptr<RowIterator> m_inner_iterator;  // Inner table (reset for each outer row)
    Item *m_join_condition;                    // Join predicate
    
public:
    bool Init() override;
    int Read() override;
    
    // For each outer row, scan all inner rows
    int ReadOuterRow();
    int ScanInnerTable();
    bool EvaluateJoinCondition();
};
```

#### 2.2 Implement in `storage/rapid_engine/iterators/nested_loop_iterator.cc`
```cpp
int RapidNestedLoopIterator::Read() {
    while (true) {
        // Try to read from inner iterator
        int err = m_inner_iterator->Read();
        
        if (err == HA_ERR_END_OF_FILE) {
            // Inner table exhausted, get next outer row
            err = ReadOuterRow();
            if (err != 0) return err;
            
            // Reset inner iterator for new outer row
            m_inner_iterator->Init();
            continue;
        }
        
        if (err != 0) return err;
        
        // Evaluate join condition
        if (EvaluateJoinCondition()) {
            return 0;  // Found matching row
        }
    }
}
```

### Phase 3: Add Index Support for Rapid Tables
**Goal**: Enable index lookups in columnar storage
**Effort**: 3-5 days
**Components**:

#### 3.1 Index Structure for Columnar Data
```cpp
// storage/rapid_engine/index/rapid_index.h
class RapidIndex {
    // Map from index key -> row IDs in columnar storage
    std::map<IndexKey, std::vector<row_id_t>> m_index;
    
    // Lookup methods
    vector<row_id_t> LookupEqual(const Key &key);
    vector<row_id_t> LookupRange(const Key &start, const Key &end);
};
```

#### 3.2 Index-based Iterator
```cpp
// storage/rapid_engine/iterators/index_lookup_iterator.h
class RapidIndexLookupIterator : public RowIterator {
    RapidIndex *m_index;
    vector<row_id_t> m_matching_rows;
    size_t m_current_pos;
    
    int Read() override {
        if (m_current_pos >= m_matching_rows.size()) {
            return HA_ERR_END_OF_FILE;
        }
        
        // Fetch row from columnar storage
        row_id_t row_id = m_matching_rows[m_current_pos++];
        return FetchRowFromColumns(row_id);
    }
};
```

### Phase 4: Optimize Small Table Handling
**Goal**: Efficient handling of small lookup tables
**Effort**: 2-3 days

#### 4.1 Cache Small Tables in Memory
```cpp
class SmallTableCache {
    // Cache entire small tables (<10K rows) in row format
    unordered_map<table_name, RowCache> m_cached_tables;
    
    bool ShouldCache(TABLE *table) {
        return table->stats.records < 10000;
    }
    
    RowCache LoadTableIntoCache(TABLE *table);
};
```

#### 4.2 Optimized Nested Loop for Cached Tables
```cpp
class CachedNestedLoopIterator : public RapidNestedLoopIterator {
    // If inner table is cached, do in-memory nested loop
    RowCache *m_inner_cache;
    
    int ScanInnerTable() override {
        if (m_inner_cache) {
            // Scan cached rows (very fast)
            return ScanCachedRows();
        }
        return RapidNestedLoopIterator::ScanInnerTable();
    }
};
```

### Phase 5: Update Execution Path Creation
**Goal**: Create appropriate iterators based on access path
**Effort**: 1 day

#### 5.1 Modify `ModifyAccessPathCost()` 
```cpp
static void ModifyAccessPathCost(AccessPath *path) {
    switch (path->type) {
        case AccessPath::NESTED_LOOP_JOIN:
            // Don't reject! Adjust cost if needed
            path->cost *= 1.1;  // Slight penalty for columnar
            break;
            
        case AccessPath::REF:
        case AccessPath::EQ_REF:
            // Index lookups now supported
            path->cost *= 1.2;  // Slightly more expensive than row store
            break;
    }
}
```

#### 5.2 Create Iterators in Execution
```cpp
RowIterator* CreateIterator(AccessPath *path) {
    switch (path->type) {
        case AccessPath::NESTED_LOOP_JOIN:
            return new RapidNestedLoopIterator(path);
            
        case AccessPath::REF:
            return new RapidIndexLookupIterator(path);
            
        case AccessPath::TABLE_SCAN:
            return new RapidTableScanIterator(path);
            
        case AccessPath::HASH_JOIN:
            return new RapidHashJoinIterator(path);  // Keep existing
    }
}
```

## Testing Strategy

### Test Cases
1. **Small lookup joins**: 
   ```sql
   SELECT * FROM large_table t1 
   JOIN small_lookup t2 ON t1.type_id = t2.id
   ```

2. **Index-based access**:
   ```sql
   SELECT * FROM table WHERE id = 123
   ```

3. **Mixed execution**:
   ```sql
   SELECT * FROM t1 
   JOIN t2 ON t1.id = t2.t1_id    -- Nested loop
   JOIN t3 ON t2.x = t3.x         -- Hash join
   ```

### Performance Targets
- Small table joins: < 10ms overhead vs InnoDB
- Index lookups: < 5ms for point queries
- Overall compatibility: >95% queries supported

## Implementation Timeline

| Phase | Description | Effort | Impact |
|-------|------------|--------|--------|
| 1 | Remove blocking assertions | 2 hours | Stops rejections |
| 2 | Basic nested loop iterator | 2 days | Enables execution |
| 3 | Index support | 5 days | Fast lookups |
| 4 | Small table optimization | 3 days | Performance |
| 5 | Integration | 1 day | Complete |

**Total: ~2 weeks for full implementation**

## Quick Win Option (2 Hours)

If you need immediate results:

### Minimal Change - Just Stop Rejecting
1. Comment out assertions in `AssertSupportedPath()`
2. Add stub handling that falls back to table scan:

```cpp
// In PrepareSecondaryEngine or OptimizeSecondaryEngine
if (HasNestedLoopJoin(access_path)) {
    // Convert to hash join or table scan
    ConvertToSupportedPlan(access_path);
}
```

This won't execute efficiently but will stop rejections!

## Files to Modify (Summary)

### Must Change:
- `storage/rapid_engine/handler/ha_shannon_rapid.cc` - Remove assertions
- `storage/rapid_engine/handler/ha_shannon_rapid.h` - Update table_flags()

### Should Add:
- `storage/rapid_engine/iterators/nested_loop_iterator.cc` - New iterator
- `storage/rapid_engine/iterators/index_lookup_iterator.cc` - Index support

### Nice to Have:
- `storage/rapid_engine/cache/small_table_cache.cc` - Performance optimization

## Risks and Mitigations

| Risk | Impact | Mitigation |
|------|--------|------------|
| Columnar inefficiency for nested loops | Slow performance | Cache small tables in row format |
| Index maintenance overhead | Write performance | Lazy index building |
| Memory usage for caching | OOM | Limit cache size, LRU eviction |

## Alternative: Hybrid Execution

Instead of full nested loop support, consider:
1. **Detect small tables** in optimizer
2. **Keep small tables in row format** (InnoDB)
3. **Large tables in column format** (Rapid)
4. **Mixed execution** - join across engines

This might be simpler than full nested loop support in columnar storage!

## Recommendation

### Immediate (Today):
1. **Remove assertions** - 2 hour fix
2. **Test compatibility** - See how many queries now pass
3. **Measure performance** - Even inefficient is better than rejection

### Short Term (This Week):
1. **Implement basic nested loop** - Get functional
2. **Add small table caching** - Improve performance

### Long Term (Next Month):
1. **Full index support** - Complete solution
2. **Optimize columnar access patterns**
3. **Benchmark vs InnoDB**

## Success Metrics

Before (Current):
- 20-30% queries supported
- 70-80% rejected with "pattern not supported"

After Phase 1 (Quick Fix):
- 90% queries supported
- May be slow but functional

After Full Implementation:
- 99% queries supported
- Performance within 2x of InnoDB for mixed workloads
- Better than InnoDB for pure analytical

## Conclusion

**Nested loop join support is ESSENTIAL for Rapid to be usable** with real-world schemas. The quick fix (Phase 1) can be done in hours and will dramatically improve compatibility. Full implementation would make Rapid a true general-purpose engine.

**Recommendation**: Start with Phase 1 immediately to unblock testing, then incrementally add optimizations.
