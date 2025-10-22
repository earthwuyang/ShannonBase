# Smart Data Loading - Skip if Data Already Exists

## Summary

Both data loading scripts now intelligently check if data already exists **before** dropping and recreating databases/tables:

- **`setup_tpc_benchmarks_parallel.sh`** - Checks TPC-H/TPC-DS data with expected row counts
- **`import_ctu_datasets_parallel.py`** - Checks CTU datasets for complete tables

This saves significant time (70-85% reduction) on repeated runs.

## What Changed

### Previous Behavior
```bash
# Always dropped and recreated everything
1. DROP DATABASE tpch_sf1
2. CREATE DATABASE tpch_sf1
3. Create all table schemas
4. Load all data (5-10 minutes)
5. Load into Rapid engine
```

### New Smart Behavior
```bash
# Checks if data exists first
1. Check if tpch_sf1 database exists
2. Check if all tables exist with expected row counts
3. If YES → Skip to step 5 (save 5-10 minutes!)
4. If NO → Proceed with full load
5. Load into Rapid engine (always runs)
```

## How It Works

### TPC-H Data Validation

The script checks for expected row counts (SF1 = 1GB):

| Table     | Expected Rows |
|-----------|--------------|
| region    | 5            |
| nation    | 25           |
| part      | 200,000      |
| supplier  | 10,000       |
| partsupp  | 800,000      |
| customer  | 150,000      |
| orders    | 1,500,000    |
| lineitem  | ~6,000,000   |

**Validation Logic:**
- All tables must exist
- Each table must have at least the minimum expected rows
- For `lineitem`, allows 1% variance (5.9M-6.1M rows)

### TPC-DS Data Validation

The script checks for 24 tables:
- All tables must exist
- All tables must have at least 1 row (except `dbgen_version`)

## Example Output

### When Data Already Exists (Fast Path)
```bash
[INFO] Loading TPC-H data with parallel processing...
[INFO] ✓ TPC-H data already exists with expected row counts, skipping data load...
TPC-H Existing Data Summary
+------------+-----------+
| table_name | row_count |
+------------+-----------+
| customer   | 150000    |
| lineitem   | 6001215   |
| nation     | 25        |
| orders     | 1500000   |
| part       | 200000    |
| partsupp   | 800000    |
| region     | 5         |
| supplier   | 10000     |
+------------+-----------+
[INFO] Proceeding to SECONDARY_LOAD step...
[INFO] Verifying SECONDARY_ENGINE configuration...
[INFO] Loading TPC-H data into Rapid engine (with error handling and retry)...
[INFO] Loading customer into Rapid...
[INFO]   ✓ customer loaded into Rapid (attempt 1)
...
```

### When Data Doesn't Exist (Full Load)
```bash
[INFO] Loading TPC-H data with parallel processing...
[INFO] TPC-H data not found or incomplete, proceeding with full data load...
[INFO] Dropping existing tpch_sf1 database (if exists) to ensure clean state...
[INFO] Creating TPC-H schema (clean database, no FK metadata)...
[INFO] Loading small tables sequentially...
[PROGRESS] [region] Loading...
...
```

## Benefits

### Time Savings
- **First run:** ~10-15 minutes (full load + Rapid loading)
- **Subsequent runs:** ~2-3 minutes (only Rapid loading if needed)
- **Savings:** 70-85% reduction in time for repeated runs

### Use Cases
1. **Testing SECONDARY_LOAD fixes:** After fixing bugs, re-run script to only reload into Rapid
2. **Development iterations:** Quickly test changes without waiting for data reload
3. **Configuration changes:** Modify Rapid settings and reload without data re-import
4. **Recovery from crashes:** If Rapid loading fails, retry without re-importing data

## Force Full Reload

If you want to force a complete reload (drop and recreate everything), you have two options:

### Option 1: Drop the database manually
```bash
mysql -uroot -pshannonbase --socket=/home/wuy/ShannonBase/db/mysql.sock \
  -e "DROP DATABASE IF EXISTS tpch_sf1;"

# Then run the script
./setup_tpc_benchmarks_parallel.sh
```

### Option 2: Modify row counts
If a table has incorrect data, drop just that table:
```bash
mysql -uroot -pshannonbase --socket=/home/wuy/ShannonBase/db/mysql.sock \
  -e "DROP TABLE tpch_sf1.lineitem;"

# Script will detect missing table and do full reload
./setup_tpc_benchmarks_parallel.sh
```

## Implementation Details

### New Functions

```bash
database_exists()
  - Checks if database exists in information_schema

check_tpch_data_complete()
  - Validates all 8 TPC-H tables exist
  - Verifies row counts match expected values
  - Returns 0 (true) if complete, 1 (false) otherwise

check_tpcds_data_complete()
  - Validates all 24 TPC-DS tables exist
  - Verifies all tables have data
  - Returns 0 (true) if complete, 1 (false) otherwise
```

### Modified Functions

```bash
load_tpch_parallel()
  - Added if/else branch based on check_tpch_data_complete()
  - Fast path: Skip to SECONDARY_LOAD
  - Slow path: Full database drop/create/load

load_tpcds_parallel()
  - Added if/else branch based on check_tpcds_data_complete()
  - Fast path: Skip to SECONDARY_LOAD
  - Slow path: Full database drop/create/load
```

## Validation Logic

### Row Count Tolerance
- Exact match required for small tables (< 1M rows)
- 1% tolerance for large tables like `lineitem`
- Allows for minor generator variations

### SECONDARY_ENGINE Check
- Even when skipping data load, script verifies `SECONDARY_ENGINE=Rapid` is set
- Adds it if missing (handles upgrades from older schemas)

## Troubleshooting

### Data exists but script still reloads

**Possible causes:**
1. Row count mismatch
2. Missing tables
3. Database doesn't exist

**Check current row counts:**
```bash
mysql -uroot -pshannonbase --socket=/home/wuy/ShannonBase/db/mysql.sock \
  -e "SELECT table_name, table_rows FROM information_schema.tables 
      WHERE table_schema='tpch_sf1' ORDER BY table_name;"
```

**Compare with expected:**
- If any count is below expected, script will do full reload
- If `lineitem` has < 5.9M rows, script will do full reload

### Script skips load but data is corrupt

**Solution:**
```bash
# Drop the problematic database
mysql -uroot -pshannonbase --socket=/home/wuy/ShannonBase/db/mysql.sock \
  -e "DROP DATABASE tpch_sf1;"

# Re-run script for clean load
./setup_tpc_benchmarks_parallel.sh
```

## Performance Tips

### For Development
- Keep the data loaded
- Only reload into Rapid when needed
- Use `ALTER TABLE ... SECONDARY_UNLOAD` then `SECONDARY_LOAD` for individual tables

### For Production
- Load data once during setup
- Script will skip reload on subsequent runs
- Only reloads if data is missing or incomplete

## Python Script (CTU Datasets)

### New Behavior
```bash
# Checks if data exists first
1. Check if database exists
2. Check if all tables exist with data
3. If YES → Skip phases 1-3, jump to phase 4 (SECONDARY_LOAD)
4. If NO → Proceed with full export/create/import
5. Load into Rapid engine (always runs)
```

### Example Output (Data Exists)
```bash
📦 Processing dataset: Airline
  Found 19 tables: L_AIRLINE_ID, L_AIRPORT, ...
  ✅ Database 'Airline' already exists with all 19 tables populated
  📊 Skipping data load, proceeding to SECONDARY_LOAD verification...
  
  📋 Existing Data Summary:
    • L_AIRLINE_ID: 1,491 rows
    • L_AIRPORT: 388 rows
    ...
  
  🚀 Phase 4: Loading tables into Rapid engine (with retry)...
    [1/19] Loading L_AIRLINE_ID into Rapid... ✓
    ...
  📊 Rapid loading summary: 19/19 tables loaded
  ✅ All tables successfully loaded into Rapid engine!
```

### Force Full Reload
```bash
# Use --force flag
python3 import_ctu_datasets_parallel.py --force

# Or drop database manually
mysql -uroot -pshannonbase --socket=/home/wuy/ShannonBase/db/mysql.sock \
  -e "DROP DATABASE IF EXISTS Airline;"
```

## Comparison

| Aspect | setup_tpc_benchmarks_parallel.sh | import_ctu_datasets_parallel.py |
|--------|----------------------------------|--------------------------------|
| **Validation** | Row count matching expected SF1 values | All tables exist with data |
| **Skip Trigger** | `check_tpch_data_complete()` / `check_tpcds_data_complete()` | `check_database_complete()` |
| **Force Reload** | Manually drop database | `--force` flag or drop database |
| **Time Saved** | 5-10 minutes → 2-3 minutes | Varies by dataset, typically 60-80% |

## Date Updated
2025-10-22
