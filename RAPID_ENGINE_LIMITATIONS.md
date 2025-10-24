# Rapid Engine Query Rejection Analysis

## Root Cause

The Rapid (secondary) engine is rejecting most queries because it has **limited access pattern support**. Based on the source code analysis:

### Supported Features
- **Hash Joins ONLY** - The engine is configured with only `SUPPORTS_HASH_JOIN` flag
- **Table Scans** - Full table scans are supported
- **Aggregate Operations** - COUNT(*), MIN(), MAX() with implicit grouping

### NOT Supported (Explicitly Disabled)
- **Nested Loop Joins** - Most TP queries use these
- **Index Scans** - Any query requiring index access
- **Index Range Scans** - Range queries on indexed columns
- **REF/EQ_REF Access** - Foreign key and primary key lookups
- **BKA (Batched Key Access) Joins**

## Why Queries Are Rejected

When `use_secondary_engine = FORCED`:

1. MySQL optimizer still analyzes the query
2. Optimizer determines the best execution plan (often using indexes for TP queries)
3. Plan is sent to Rapid engine for execution
4. Rapid engine sees the plan requires unsupported access paths (index scans, nested loop joins, etc.)
5. Rapid engine rejects with error 3889: "Secondary engine operation failed"

## Query Types Most Affected

### Transactional Processing (TP) Queries
- **Simple filters** - Usually require index scans (`WHERE id = 123`)
- **Range scans** - Need index range access (`WHERE date BETWEEN x AND y`)
- **Point lookups** - Require EQ_REF access
- **Small joins** - Optimizer prefers nested loop over hash join

### Analytical Processing (AP) Queries  
- **Complex joins WITHOUT indexes** - ✅ More likely to work (uses hash joins)
- **Full table aggregations** - ✅ Work well (table scans + aggregation)
- **Queries with ORDER BY** - ❌ May fail if optimizer uses index for sorting

## Evidence from Code

```cpp
// In ha_shannon_rapid.cc:
shannon_rapid_hton->secondary_engine_flags = 
    MakeSecondaryEngineFlags(SecondaryEngineFlag::SUPPORTS_HASH_JOIN);
    // ONLY hash joins supported!

// Explicitly asserted as unsupported:
case AccessPath::NESTED_LOOP_JOIN:
case AccessPath::INDEX_SCAN:
case AccessPath::REF:
case AccessPath::EQ_REF:
case AccessPath::INDEX_RANGE_SCAN:
    ut_a(false); // Will fail if these paths are chosen
```

## Solutions

### Option 1: Filter Queries Before Collection (Recommended)
Modify `collect_dual_engine_data.py` to:
- Analyze EXPLAIN output before running on Rapid
- Skip queries that require index access or nested loop joins
- Only collect data for compatible queries

### Option 2: Force Hash Joins in MySQL
Add these settings before query execution:
```sql
SET optimizer_switch='block_nested_loop=off,batched_key_access=off';
SET join_buffer_size = 256M; -- Encourage hash joins
```

### Option 3: Analyze Query Patterns
Look at which TP query types DO work:
```sql
-- These might work:
SELECT * FROM table;  -- Full scan
SELECT COUNT(*) FROM table;  -- Aggregate scan
SELECT * FROM t1 JOIN t2 ON t1.x=t2.x WHERE /* no indexes used */;
```

### Option 4: Add Query Filtering to Collection Script
Detect and skip incompatible patterns:
- Queries with `WHERE col = value` on indexed columns
- Queries with ORDER BY on indexed columns
- Small table joins (< 1000 rows) that prefer nested loop

## Recommendation

**The Rapid engine is designed for OLAP (analytical) workloads, not OLTP (transactional) workloads.**

For your data collection:
1. **Accept that most TP queries will be rejected** - this is by design
2. **Focus on AP queries that use hash joins** - these are the target use case
3. **Modify collection script to gracefully handle rejections** - don't treat as errors
4. **Add pre-flight checks** to skip obviously incompatible queries

Would you like me to update the collection script to:
1. Pre-analyze queries and skip incompatible ones?
2. Add optimizer hints to encourage hash joins where possible?
3. Better categorize which TP query patterns might still work?
