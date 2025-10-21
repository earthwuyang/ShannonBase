# Engine Forcing Guide for Dual Engine Data Collection

## Overview

ShannonBase is a Hybrid Transactional/Analytical Processing (HTAP) database with two storage engines:

1. **Primary Engine (InnoDB)** - Row-based storage, optimized for OLTP workloads
2. **Secondary Engine (Rapid)** - Column-based storage, optimized for OLAP workloads

## Engine Control Variable

The `use_secondary_engine` session variable controls which engine processes queries:

```sql
-- Values:
SET SESSION use_secondary_engine = OFF;     -- 0: Primary engine only (InnoDB)
SET SESSION use_secondary_engine = ON;      -- 1: Optimizer chooses (default)
SET SESSION use_secondary_engine = FORCED;  -- 2: Force secondary engine (Rapid)
```

## How collect_dual_engine_data.py Works

### Previous Implementation (INCORRECT)

The old script attempted to use a non-existent variable:
```python
# WRONG - this variable doesn't exist
cursor.execute("SET use_column_engine = 1")
```

This didn't actually force the Rapid engine, leading to inconsistent results.

### Current Implementation (CORRECT)

The updated script properly forces each engine:

```python
# Force PRIMARY engine (InnoDB)
def connect_mysql(self):
    cursor.execute("SET SESSION use_secondary_engine = OFF")
    # Now all queries use InnoDB row store
    
# Force SECONDARY engine (Rapid)  
def connect_shannonbase(self):
    cursor.execute("SET SESSION use_secondary_engine = FORCED")
    # Now all queries use Rapid column store (when eligible)
```

## Verification

The script now verifies which engine is being used:

```python
def verify_engine_used(self, cursor):
    cursor.execute("SHOW SESSION VARIABLES LIKE 'use_secondary_engine'")
    result = cursor.fetchone()
    return result[1]  # Returns 'OFF', 'ON', or 'FORCED'
```

### Example Output

```json
{
  "mysql": {
    "engine_mode": "OFF",
    "engine_type": "InnoDB (Primary/Row Store)",
    "latency": {
      "mean_ms": 12.5
    }
  },
  "shannonbase": {
    "engine_mode": "FORCED",
    "engine_type": "Rapid (Secondary/Column Store)",
    "latency": {
      "mean_ms": 5.2
    }
  }
}
```

## Engine Eligibility

Not all queries can use the Rapid engine. The secondary engine is typically used for:

- **Analytical queries**: Complex aggregations, multi-table joins
- **Table scans**: Full table scans on large tables
- **Column-oriented operations**: Operations that benefit from columnar storage

Queries that may NOT be eligible for Rapid:
- Point lookups by primary key
- Small indexed range scans
- Queries requiring row-level locking
- DML operations (INSERT, UPDATE, DELETE)

When `use_secondary_engine = FORCED`, ineligible queries will fall back to InnoDB with a warning.

## Architecture Details

### Storage Layers

```
┌─────────────────────────────────────────┐
│        SQL Layer (MySQL Compatible)     │
├─────────────────────────────────────────┤
│           Query Optimizer                │
│  (Chooses engine based on cost/setting) │
├──────────────────┬──────────────────────┤
│  Primary Engine  │  Secondary Engine    │
│    (InnoDB)      │     (Rapid)          │
│   Row-based      │   Column-based       │
│   OLTP-focused   │   OLAP-focused       │
└──────────────────┴──────────────────────┘
```

### Data Flow

1. **OFF mode**: 
   - All queries → InnoDB
   - Original MySQL behavior

2. **ON mode** (default):
   - Optimizer evaluates cost
   - Small/transactional → InnoDB
   - Large/analytical → Rapid (if eligible)

3. **FORCED mode**:
   - Try Rapid first (if eligible)
   - Fall back to InnoDB if not eligible
   - Used for data collection to isolate Rapid performance

## Configuration References

From ShannonBase source code:

```cpp
// sql/system_variables.h
enum use_secondary_engine {
  SECONDARY_ENGINE_OFF = 0,
  SECONDARY_ENGINE_ON = 1,
  SECONDARY_ENGINE_FORCED = 2
};
```

```cpp
// sql/sys_vars.cc
static Sys_var_enum Sys_use_secondary_engine(
    "use_secondary_engine",
    "Controls the use of secondary storage engine",
    ...
);
```

## Testing Engine Forcing

### Verify Engine Setting

```sql
-- Check current setting
SHOW SESSION VARIABLES LIKE 'use_secondary_engine';

-- Test with different modes
SET SESSION use_secondary_engine = OFF;
EXPLAIN SELECT * FROM large_table WHERE column > 1000;
-- Should show InnoDB in execution plan

SET SESSION use_secondary_engine = FORCED;
EXPLAIN SELECT * FROM large_table WHERE column > 1000;
-- Should show Rapid engine if eligible
```

### Monitor Engine Usage

```sql
-- Check if query used secondary engine
SELECT 
  query_id,
  engine_used
FROM performance_schema.events_statements_history
WHERE sql_text LIKE '%your_query%';
```

## Best Practices for Data Collection

1. **Always verify engine mode** after connection:
   ```python
   engine_mode = self.verify_engine_used(cursor)
   assert engine_mode == 'FORCED', "Engine not forced correctly"
   ```

2. **Log engine information** in results:
   ```python
   results['engine_mode'] = engine_mode
   results['engine_type'] = 'InnoDB' or 'Rapid'
   ```

3. **Handle engine eligibility** gracefully:
   - Not all queries can use Rapid
   - Log warnings when queries fall back
   - Don't treat fallback as error

4. **Separate data by engine**:
   - Keep InnoDB and Rapid results in separate directories
   - Include engine metadata in all outputs
   - Makes analysis clearer

## Troubleshooting

### Issue: Both engines show similar performance

**Cause**: Rapid engine not actually being used
**Solution**: 
- Verify `use_secondary_engine = FORCED` is set
- Check if queries are eligible for Rapid
- Review optimizer trace for engine selection

### Issue: "Query cannot use secondary engine"

**Cause**: Query is not eligible for Rapid engine
**Solution**:
- This is expected for some queries (TP workloads)
- Query will automatically use InnoDB
- Log this as informational, not an error

### Issue: Connection to port 3307 fails

**Cause**: ShannonBase not running or wrong port
**Solution**:
```bash
# Check ShannonBase is running
mysql -h 127.0.0.1 -P 3307 -u root -pshannonbase -e "SELECT @@version"

# Verify rapid engine is available
mysql -h 127.0.0.1 -P 3307 -u root -pshannonbase \
  -e "SHOW ENGINES WHERE Engine = 'RAPID'"
```

## Summary

The key changes in `collect_dual_engine_data.py`:

1. ✅ Use correct variable: `use_secondary_engine` (not `use_column_engine`)
2. ✅ Force OFF for InnoDB: Guarantees row store execution
3. ✅ Force FORCED for Rapid: Maximizes column store usage
4. ✅ Verify engine mode: Confirms correct forcing
5. ✅ Log engine metadata: Enables post-analysis validation

This ensures accurate dual-engine performance comparison for training the hybrid optimizer.
