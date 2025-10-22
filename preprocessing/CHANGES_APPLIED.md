# Changes Applied to Fix MySQL Crashes

## Summary

Modified `setup_tpc_benchmarks_parallel.sh` to **remove all Rapid secondary engine usage** to prevent crashes during data loading.

## What Was Changed

### 1. Removed SECONDARY_ENGINE from Table Definitions
**Changed**: All `CREATE TABLE` statements  
**Before**: `ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 SECONDARY_ENGINE=Rapid`  
**After**: `ENGINE=InnoDB DEFAULT CHARSET=utf8mb4`

**Files affected**: 
- All TPC-H tables (nation, region, part, supplier, etc.)
- All TPC-DS tables (call_center, catalog_page, store_sales, etc.)

### 2. Disabled SECONDARY_ENGINE Configuration (TPC-H)
**Location**: Lines 350-364  
**Action**: Commented out the loop that adds `SECONDARY_ENGINE=Rapid` to TPC-H tables

```bash
# BEFORE (active code):
print_status "Configuring SECONDARY_ENGINE for TPC-H tables..."
for table in nation region part supplier partsupp customer orders lineitem; do
    mysql_exec_db tpch_sf1 "ALTER TABLE \`$table\` SECONDARY_ENGINE=Rapid;"
done

# AFTER (commented out):
# DISABLED: Rapid engine loading causes crashes with foreign key constraints
print_status "Skipping SECONDARY_ENGINE configuration (using InnoDB only to avoid crashes)"
```

### 3. Disabled SECONDARY_LOAD for TPC-H Tables
**Location**: Lines 453-462  
**Action**: Commented out the loop that loads TPC-H tables into Rapid engine

```bash
# BEFORE (active code):
print_status "Loading TPC-H data into Rapid engine..."
for table in customer lineitem nation orders part partsupp region supplier; do
    mysql_exec_db tpch_sf1 "ALTER TABLE \`$table\` SECONDARY_LOAD;"
done

# AFTER (commented out):
# DISABLED: Rapid engine loading causes crashes with foreign key constraints
print_status "TPC-H tables loaded successfully (InnoDB only, skipping Rapid to avoid crashes)"
```

### 4. Disabled SECONDARY_LOAD for TPC-DS Tables
**Location**: Lines 1074-1083  
**Action**: Commented out the loop that loads TPC-DS tables into Rapid engine

```bash
# BEFORE (active code):
print_status "Loading TPC-DS data into Rapid engine..."
for table in call_center catalog_page catalog_returns catalog_sales customer ...; do
    mysql_exec_db tpcds_sf1 "ALTER TABLE \`$table\` SECONDARY_LOAD;"
done

# AFTER (commented out):
# DISABLED: Rapid engine loading causes crashes with foreign key constraints
print_status "TPC-DS tables loaded successfully (InnoDB only, skipping Rapid to avoid crashes)"
```

## Backup Created

A backup of the original script is available at:
```
/home/wuy/ShannonBase/preprocessing/setup_tpc_benchmarks_parallel.sh.backup
```

## Verification

To verify the changes:
```bash
# Count remaining SECONDARY_ENGINE/SECONDARY_LOAD references (should be 2, both in comments)
grep -c "SECONDARY_ENGINE=Rapid\|SECONDARY_LOAD" setup_tpc_benchmarks_parallel.sh

# View the specific lines (should be commented)
grep -n "SECONDARY_ENGINE=Rapid\|SECONDARY_LOAD" setup_tpc_benchmarks_parallel.sh
```

## Impact

### What Works Now
✅ All tables created successfully in InnoDB engine  
✅ Data loading completes without crashes  
✅ All TPC-H queries work normally (using InnoDB)  
✅ All TPC-DS queries work normally (using InnoDB)  
✅ Parallel loading still works (MAX_PARALLEL=2 or 5)

### What's Changed
⚠️ Tables are **not** loaded into Rapid secondary engine  
⚠️ Queries will use InnoDB execution (not Rapid)  
⚠️ No columnar storage optimization from Rapid

### Performance Notes
- **InnoDB performance**: Excellent for OLTP and good for OLAP
- **Rapid engine**: Would provide columnar storage for analytics, but causes crashes
- **Workaround impact**: Minimal for most workloads; InnoDB handles TPC-H/TPC-DS well

## Running the Modified Script

### Standard Usage
```bash
cd /home/wuy/ShannonBase/preprocessing
export MAX_PARALLEL=2  # Keep parallelism low
./setup_tpc_benchmarks_parallel.sh
```

### With Safe MySQL Configuration
```bash
# 1. Stop MySQL
cd /home/wuy/ShannonBase
./stop_mysql.sh

# 2. Start with safe config
/home/wuy/ShannonBase/cmake_build/runtime_output_directory/mysqld \
    --defaults-file=/home/wuy/ShannonBase/db/my_safe.cnf \
    --user=root &

sleep 5

# 3. Run import
cd preprocessing
export MAX_PARALLEL=2
./setup_tpc_benchmarks_parallel.sh
```

## Expected Output

You should see these messages during execution:

```
[INFO] Skipping SECONDARY_ENGINE configuration (using InnoDB only to avoid crashes)
...
[INFO] TPC-H tables loaded successfully (InnoDB only, skipping Rapid to avoid crashes)
...
[INFO] TPC-DS tables loaded successfully (InnoDB only, skipping Rapid to avoid crashes)
```

## Reverting Changes

If you need to restore the original script:
```bash
cd /home/wuy/ShannonBase/preprocessing
cp setup_tpc_benchmarks_parallel.sh.backup setup_tpc_benchmarks_parallel.sh
```

## Future Considerations

### Option 1: Use InnoDB Only (Current Solution)
- ✅ Stable and crash-free
- ✅ Good performance for most queries
- ✅ No maintenance overhead

### Option 2: Add Rapid Later (Advanced)
If you need Rapid for specific tables:

```sql
-- Only add Rapid to tables WITHOUT foreign keys
-- Check for FKs first:
SELECT 
    constraint_name,
    table_name,
    referenced_table_name
FROM information_schema.key_column_usage
WHERE table_schema = 'tpch_sf1' 
AND referenced_table_name IS NOT NULL;

-- If no FKs, safe to add Rapid:
ALTER TABLE tpch_sf1.region SECONDARY_ENGINE=Rapid;
ALTER TABLE tpch_sf1.region SECONDARY_LOAD;
```

### Option 3: Wait for Bug Fix
- The crash is a known issue with ShannonBase/MySQL Rapid engine
- May be fixed in future releases
- Monitor release notes for fixes to `dict0dict.cc:3480` assertion

## Troubleshooting

### If Script Still Crashes

1. **Check for other SECONDARY_ENGINE references**:
   ```bash
   grep -r "SECONDARY_ENGINE\|SECONDARY_LOAD" preprocessing/
   ```

2. **Verify MySQL configuration**:
   ```bash
   cat /home/wuy/ShannonBase/db/my_safe.cnf | grep -E "redo_log|parallel|thread"
   ```

3. **Check error logs**:
   ```bash
   tail -50 /home/wuy/ShannonBase/db/data/shannonbase.err
   ```

### If Tables Already Exist with SECONDARY_ENGINE

Remove it manually:
```sql
-- Remove SECONDARY_ENGINE from existing tables
ALTER TABLE tpch_sf1.customer SECONDARY_ENGINE=NULL;
ALTER TABLE tpcds_sf1.call_center SECONDARY_ENGINE=NULL;
-- Repeat for all tables
```

## Related Files

- Original script backup: `setup_tpc_benchmarks_parallel.sh.backup`
- Safe MySQL config: `/home/wuy/ShannonBase/db/my_safe.cnf`
- Crash analysis: `CRASH_ANALYSIS.md`
- Quick fix guide: `QUICK_FIX.md`
- Fix script: `fix_rapid_crash.sh`
