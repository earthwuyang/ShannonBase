# Rapid-Compatible Workload Generator - Changes Summary

## Overview
Created `generate_training_workload_rapid_compatible.py` - a version that ONLY generates queries compatible with the Rapid secondary engine.

## Key Differences from Original Generator

### 1. **Removed ALL TP (Transactional) Query Types**
**Why:** TP queries use index scans and nested loop joins, which Rapid doesn't support.

**Removed:**
- `TP_POINT_LOOKUP` - Uses index scans on primary keys
- `TP_SIMPLE_FILTER` - Uses index scans on indexed columns
- `TP_RANGE_SCAN` - Uses index range scans
- All other TP patterns

### 2. **Removed Unsupported AP Query Types**
**Removed:**
- `AP_SUBQUERY` - Often triggers nested loop joins
- `AP_UNION_COMPLEX` - Has syntax compatibility issues with Rapid

**Kept:**
- `AP_COMPLEX_JOIN` - Modified to ensure 3+ tables (forces hash joins)
- `AP_AGGREGATION` - With full table scans
- `AP_WINDOW` - Over full table scans
- `AP_CTE_RECURSIVE` - With full scans

### 3. **Modified Join Generation**
**Original:**
```python
# Could generate 0-10 joins
num_joins = random.randint(0, 10)
# Could use any join type
join_type = random.choice([INNER, LEFT, RIGHT, FULL, CROSS])
```

**Rapid-Compatible:**
```python
# Forces 3-8 tables to trigger hash joins
num_joins = random.randint(3, 8)  # Minimum 3 for hash join
# Only compatible join types
join_type = random.choice([INNER, LEFT, CROSS])  # Removed RIGHT and FULL
```

**Why:** Rapid needs 3+ tables to use hash joins instead of nested loops.

### 4. **Changed Predicate Generation**
**Original:**
```python
# Selective predicates that use indexes
f"{table}.{column} = 123"          # Index scan
f"{table}.{column} BETWEEN 1 AND 100"  # Index range scan
f"{table}.{column} = 'VALUE'"      # Index lookup
```

**Rapid-Compatible:**
```python
# NON-selective predicates that force full table scans
f"{table}.{column} > 0"            # Very broad
f"{table}.{column} IS NOT NULL"    # Almost everything
f"{table}.{column} LIKE '%'"       # Matches all
f"({table}.{column} < 10000000 OR {table}.{column} IS NULL)"  # Very broad OR
```

**Why:** Selective predicates trigger index usage; broad predicates force full scans that Rapid supports.

### 5. **Removed Index Hints and Selective Operations**
**Original:** Could generate ORDER BY on indexed columns, specific value lookups, etc.

**Rapid-Compatible:** 
- ORDER BY only on GROUP BY columns (already computed)
- No specific value lookups
- No range scans on specific values

### 6. **Updated Query Distributions**
**Original (with TP/AP ratio 0.5):**
- 50% TP queries (point lookups, simple filters, range scans)
- 50% AP queries (complex joins, aggregations, window, subquery, union, etc.)

**Rapid-Compatible:**
- 0% TP queries (removed entirely)
- 100% AP queries (only compatible types)
  - 30% Complex joins (3-8 tables)
  - 30% Aggregations
  - 20% Window functions
  - 10% CTEs
  - 10% Full scan filters

### 7. **Added Rapid-Specific Features**

#### Full Scan Filter Query Type
```python
def generate_ap_full_scan_filter(self):
    """Full table scan with multiple non-selective filters"""
    # Intentionally broad predicates
    # Mix AND and OR to keep non-selective
    # Forces Rapid to do full scan
```

**Purpose:** Exercises Rapid's full scan capabilities with complex predicates.

#### Minimum Join Requirement
```python
min_joins = 3  # Force hash join threshold
max_joins = 8  # Complex enough for Rapid
```

**Purpose:** Ensures optimizer chooses hash joins over nested loops.

## Usage Comparison

### Original Generator
```bash
# Generates mixed TP/AP workload
python3 generate_training_workload_advanced.py --all-datasets --tp-ratio 0.5

# Result: 50% queries will be rejected by Rapid
```

### Rapid-Compatible Generator
```bash
# Generates 100% Rapid-compatible queries
python3 generate_training_workload_rapid_compatible.py --all-datasets

# Result: All queries should execute on Rapid engine
```

## Expected Results

### Original Workload on Rapid
```
✗ q_0000: rejected (index scan)
✗ q_0001: rejected (nested loop join)
✗ q_0002: rejected (point lookup)
✓ q_0003: success (large hash join)
✗ q_0004: rejected (range scan)
...
Success rate: ~20-30% (only large AP queries work)
```

### Rapid-Compatible Workload on Rapid
```
✓ q_0000: success (hash join, 5 tables)
✓ q_0001: success (full scan aggregation)
✓ q_0002: success (window function)
✓ q_0003: success (hash join, 7 tables)
✓ q_0004: success (CTE with aggregation)
...
Success rate: ~90-95% (most should work)
```

## Testing the Generator

```bash
# Generate for single database
python3 generate_training_workload_rapid_compatible.py --database tpch_sf1 --num-queries 100

# Test with collection script
python3 collect_dual_engine_data.py --workload ../training_workloads/training_workload_rapid_tpch_sf1.sql

# Check success rate
cat training_data/collection_summary.json | grep -A5 successful_shannon
```

## Remaining Limitations

Even with Rapid-compatible queries, some may still fail due to:

1. **Table not loaded into Rapid** - Ensure tables have `SECONDARY_ENGINE=RAPID`
2. **Very complex predicates** - Some edge cases may still trigger issues
3. **Specific data types** - Certain column types not supported
4. **Query timeout** - Very large joins may exceed 1-minute timeout

## Recommendations

1. **Use this generator for Rapid testing** instead of the original
2. **Set appropriate timeout** (already done - 60 seconds)
3. **Pre-load tables into Rapid** before collection
4. **Monitor rejection reasons** to identify any remaining issues
5. **Consider increasing min_joins** if still seeing nested loops (change to 4 or 5)

## File Locations

- Original: `preprocessing/generate_training_workload_advanced.py`
- Rapid-compatible: `preprocessing/generate_training_workload_rapid_compatible.py`
- Output: `training_workloads/training_workload_rapid_*.sql`
- Analysis: `RAPID_ENGINE_LIMITATIONS.md`
