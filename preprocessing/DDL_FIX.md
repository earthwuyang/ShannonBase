# Fix for DDL Error with SECONDARY_ENGINE

## Error

```
ERROR 3890 (HY000) at line 116: DDLs on a table with a secondary engine defined are not allowed.
```

## Root Cause

ShannonBase doesn't allow DDL operations (like CREATE INDEX) on tables that already have `SECONDARY_ENGINE=Rapid` defined.

## Solution

**Two-step approach**:

1. **Create tables WITHOUT `SECONDARY_ENGINE`**
2. **Add indexes/constraints**
3. **Then add `SECONDARY_ENGINE=Rapid`**

## Implementation in setup_tpc_benchmarks_parallel.sh

### TPC-H Tables (Lines 229-326)

```sql
-- Step 1: Create tables WITHOUT SECONDARY_ENGINE
CREATE TABLE nation (
    ...
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;  -- No SECONDARY_ENGINE here

-- Step 2: Add indexes
CREATE INDEX idx_nation_region ON nation(n_regionkey);

-- Step 3: Add SECONDARY_ENGINE after all DDL
ALTER TABLE nation SECONDARY_ENGINE=Rapid;
ALTER TABLE region SECONDARY_ENGINE=Rapid;
ALTER TABLE part SECONDARY_ENGINE=Rapid;
ALTER TABLE supplier SECONDARY_ENGINE=Rapid;
ALTER TABLE partsupp SECONDARY_ENGINE=Rapid;
ALTER TABLE customer SECONDARY_ENGINE=Rapid;
ALTER TABLE orders SECONDARY_ENGINE=Rapid;
ALTER TABLE lineitem SECONDARY_ENGINE=Rapid;
```

### TPC-DS Tables (Lines 529+)

TPC-DS tables can keep `SECONDARY_ENGINE=Rapid` in CREATE TABLE because:
- No additional indexes are created after table creation
- All indexes are defined within the CREATE TABLE statement

```sql
CREATE TABLE store (
    ...
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 SECONDARY_ENGINE=Rapid;  -- OK here
```

## General Rule

**Order of operations**:
1. CREATE TABLE (without SECONDARY_ENGINE)
2. CREATE INDEX / ADD CONSTRAINT / Other DDL
3. ALTER TABLE ... SECONDARY_ENGINE=Rapid
4. LOAD DATA
5. ALTER TABLE ... SECONDARY_LOAD

OR

1. CREATE TABLE with all indexes inline + SECONDARY_ENGINE=Rapid
2. LOAD DATA  
3. ALTER TABLE ... SECONDARY_LOAD

## Why This Restriction Exists

When a table has `SECONDARY_ENGINE` defined:
- Schema changes must be synchronized between primary and secondary engines
- Index changes affect both storage engines
- ShannonBase restricts DDL to prevent schema inconsistencies

## Changes Made

**File**: `preprocessing/setup_tpc_benchmarks_parallel.sh`

**Lines 235, 242, 255, 267, 276, 289, 304, 326**:
- Changed from: `) ENGINE=InnoDB ... SECONDARY_ENGINE=Rapid;`
- Changed to: `) ENGINE=InnoDB ...;`

**Lines 351-358**: Added
```bash
ALTER TABLE nation SECONDARY_ENGINE=Rapid;
ALTER TABLE region SECONDARY_ENGINE=Rapid;
ALTER TABLE part SECONDARY_ENGINE=Rapid;
ALTER TABLE supplier SECONDARY_ENGINE=Rapid;
ALTER TABLE partsupp SECONDARY_ENGINE=Rapid;
ALTER TABLE customer SECONDARY_ENGINE=Rapid;
ALTER TABLE orders SECONDARY_ENGINE=Rapid;
ALTER TABLE lineitem SECONDARY_ENGINE=Rapid;
```

## Testing

Run the script to verify it works:

```bash
cd /home/wuy/DB/ShannonBase/preprocessing
./setup_tpc_benchmarks_parallel.sh
```

Should now complete without DDL errors.

## Verification

Check that SECONDARY_ENGINE was added:

```bash
mysql -h 127.0.0.1 -P 3307 -u root -pshannonbase \
  -e "SHOW CREATE TABLE tpch_sf1.nation\G"
```

Should show:
```sql
CREATE TABLE `nation` (
  ...
) ENGINE=InnoDB ... SECONDARY_ENGINE=Rapid
```

And the index should exist:
```bash
mysql -h 127.0.0.1 -P 3307 -u root -pshannonbase \
  -e "SHOW INDEXES FROM tpch_sf1.nation\G"
```

Should show `idx_nation_region`.

## CTU Datasets (import_ctu_datasets_parallel.py)

The CTU import script gets CREATE TABLE statements from source databases which may include indexes inline. 

**Fix applied (Lines 177-211)**:
```python
def create_table_if_not_exists(database, table, create_sql):
    # Step 1: Remove SECONDARY_ENGINE if present in source
    create_sql_clean = create_sql.replace('SECONDARY_ENGINE=Rapid', '')
    
    # Step 2: Create table (with indexes) but without SECONDARY_ENGINE
    cursor.execute(create_sql_clean)
    
    # Step 3: Add SECONDARY_ENGINE after table creation
    cursor.execute(f"ALTER TABLE `{table}` SECONDARY_ENGINE=Rapid")
```

This approach:
- ✅ Works with tables that have inline indexes
- ✅ Works with tables from any source
- ✅ Avoids DDL errors by separating SECONDARY_ENGINE from CREATE TABLE
- ✅ Always adds SECONDARY_ENGINE after table creation

## Summary

✅ **TPC-H**: CREATE TABLE → CREATE INDEX → ALTER TABLE SECONDARY_ENGINE  
✅ **TPC-DS**: CREATE TABLE with SECONDARY_ENGINE (no post-creation DDL)  
✅ **CTU Datasets**: CREATE TABLE (strip SECONDARY_ENGINE) → ALTER TABLE SECONDARY_ENGINE  
✅ **All**: ALTER TABLE SECONDARY_LOAD after data import

This ensures schema operations complete without conflicts while still loading all data into Rapid engine.
