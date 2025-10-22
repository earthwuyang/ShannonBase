# MySQL Crash Analysis & Solutions

## Problem Summary

You're experiencing **two different types of crashes** in ShannonBase/MySQL during parallel data imports:

### Crash #1: File System Assertion (Original Issue)
- **Location**: `os0file.cc:2891:dir_fd != -1`
- **Trigger**: Parallel CREATE TABLE operations (5+ concurrent workers)
- **Cause**: InnoDB cannot open parent directory during concurrent tablespace file creation
- **Status**: ✅ Fixed by reducing parallelism

### Crash #2: Rapid Engine Foreign Key Issue (Current Issue)  
- **Location**: `dict0dict.cc:3480:for_table || ref_table`
- **Trigger**: `ALTER TABLE ... SECONDARY_LOAD` for tables with foreign keys
- **Cause**: Foreign key references not properly resolved when loading into Rapid engine
- **Status**: ⚠️ Needs workaround

## Current Crash Details

### Error Log (shannonbase.err)
```
2025-10-22T03:23:01.346468Z 153 [ERROR] [MY-013183] [InnoDB] 
Assertion failure: dict0dict.cc:3480:for_table || ref_table thread 281472556589760
Query (fffe601c42d0): ALTER TABLE `call_center` SECONDARY_LOAD
```

### Stack Trace Analysis
```
dict_foreign_add_to_cache()              # Adding foreign key to cache
  ↓
dd_table_load_fk_from_dd()               # Loading FK from data dictionary
  ↓
dd_table_open_on_id()                    # Opening referenced table
  ↓
ShannonBase::Populate::PopulatorImpl::load_indexes_caches_impl()
  ↓
ShannonBase::ha_rapid::load_table()      # Loading into Rapid engine
  ↓
Sql_cmd_secondary_load_unload::execute() # SECONDARY_LOAD command
```

### Additional Issues
- **Redo log too small**: Repeated warnings about redo log capacity (512MB insufficient)
- **Bulk loading pressure**: High transaction volume during parallel imports

## Solutions

### Solution 1: Skip Rapid Engine (Recommended)

Use the patched scripts that skip SECONDARY_LOAD:

```bash
cd /home/wuy/ShannonBase/preprocessing

# Run fix script
./fix_rapid_crash.sh

# Import without Rapid engine
./setup_tpc_no_rapid.sh        # TPC benchmarks
python3 import_ctu_no_rapid.py  # CTU datasets
```

**Pros**: 
- No crashes
- Tables fully functional in InnoDB
- Can add Rapid later for specific tables

**Cons**: 
- No Rapid engine acceleration (if needed)

### Solution 2: Remove Foreign Keys Before Loading

Temporarily disable foreign keys for Rapid loading:

```bash
mysql -h 127.0.0.1 -P 3307 -u root -pshannonbase <<EOF
-- For TPC-DS tables with foreign keys
SET FOREIGN_KEY_CHECKS=0;

-- Drop foreign keys temporarily
-- ALTER TABLE tpcds_sf1.catalog_sales DROP FOREIGN KEY ...;
-- (repeat for all FK constraints)

-- Now try SECONDARY_LOAD
ALTER TABLE tpcds_sf1.call_center SECONDARY_LOAD;

-- Re-add foreign keys after loading
SET FOREIGN_KEY_CHECKS=1;
EOF
```

### Solution 3: Load Only FK-Free Tables into Rapid

Some tables don't have foreign keys and can be safely loaded:

```bash
# Safe to load (no FKs in TPC-H):
ALTER TABLE tpch_sf1.region SECONDARY_LOAD;
ALTER TABLE tpch_sf1.nation SECONDARY_LOAD;

# May have FKs (skip or check first):
# ALTER TABLE tpch_sf1.customer SECONDARY_LOAD;  # Has FK to nation
```

### Solution 4: Increase System Resources

The `my_safe.cnf` has been updated with:

```ini
# Increased redo log capacity
innodb_redo_log_capacity=2147483648  # 2GB (was 512MB)

# Faster flush for bulk loading
innodb_flush_log_at_trx_commit=2  # Was 1
```

Restart MySQL after config changes:

```bash
cd /home/wuy/ShannonBase
./stop_mysql.sh
/home/wuy/ShannonBase/cmake_build/runtime_output_directory/mysqld \
    --defaults-file=/home/wuy/ShannonBase/db/my_safe.cnf \
    --user=root &
```

## Verification

### Check Current Status

```bash
# Check if MySQL is running
mysqladmin -h 127.0.0.1 -P 3307 -u root -pshannonbase ping

# Check redo log warnings
tail -f /home/wuy/ShannonBase/db/data/shannonbase.err | grep -i "redo\|warning\|error"

# List tables and their engines
mysql -h 127.0.0.1 -P 3307 -u root -pshannonbase -e "
SELECT 
    table_schema,
    table_name,
    engine,
    create_options
FROM information_schema.tables 
WHERE table_schema IN ('tpch_sf1', 'tpcds_sf1')
ORDER BY table_schema, table_name;"
```

### Check Foreign Keys

```bash
# List all foreign keys in TPC-DS
mysql -h 127.0.0.1 -P 3307 -u root -pshannonbase -e "
SELECT 
    constraint_name,
    table_name,
    referenced_table_name
FROM information_schema.key_column_usage
WHERE table_schema = 'tpcds_sf1' 
AND referenced_table_name IS NOT NULL;"
```

## Recommended Workflow

### For Safe Import Without Crashes:

```bash
# 1. Stop MySQL
cd /home/wuy/ShannonBase
./stop_mysql.sh

# 2. Start with safe config
/home/wuy/ShannonBase/cmake_build/runtime_output_directory/mysqld \
    --defaults-file=/home/wuy/ShannonBase/db/my_safe.cnf \
    --user=root &

sleep 5

# 3. Run imports WITHOUT Rapid engine
cd preprocessing
export MAX_PARALLEL=2  # Keep parallelism low

# Import TPC benchmarks
./setup_tpc_no_rapid.sh

# Import CTU datasets
python3 import_ctu_no_rapid.py

# 4. Verify data loaded
mysql -h 127.0.0.1 -P 3307 -u root -pshannonbase -e "
SELECT 
    table_schema as 'Database',
    COUNT(*) as 'Tables',
    SUM(table_rows) as 'Total Rows'
FROM information_schema.tables 
WHERE table_schema IN ('tpch_sf1', 'tpcds_sf1', 
                       'Airline', 'Credit', 'Carcinogenesis')
GROUP BY table_schema;"
```

## Understanding the Problem

### Why Does SECONDARY_LOAD Crash?

1. **Foreign Key Resolution**: When loading a table into Rapid engine, MySQL needs to:
   - Load the table structure
   - Load all foreign key constraints
   - Open referenced tables to verify FKs

2. **Dictionary Cache Issue**: The assertion `for_table || ref_table` fails because:
   - Either the source table (`for_table`) is NULL
   - Or the referenced table (`ref_table`) is NULL
   - This shouldn't happen, but occurs during Rapid loading

3. **Race Condition**: During bulk parallel loading:
   - Multiple tables loaded simultaneously
   - Dictionary cache not fully populated
   - FK references can't be resolved

### Why Original Crash Occurred?

1. **File System Limits**: With `MAX_PARALLEL=5`:
   - 5 threads create tablespace files simultaneously
   - Each thread tries to fsync parent directory
   - Directory file descriptor limited/locked
   - `dir_fd` returns -1 (failed)
   - Assertion fails

2. **Docker/Container Environment**: 
   - File system may be overlay FS
   - Limited file descriptors
   - Concurrent directory access restricted

## Prevention

### Best Practices

1. **Reduce Parallelism**:
   ```bash
   export MAX_PARALLEL=2  # Instead of 5
   ```

2. **Skip Rapid Engine**:
   - InnoDB works perfectly fine
   - Add Rapid later if needed
   - Test with small datasets first

3. **Monitor Resources**:
   ```bash
   # Watch for redo log warnings
   tail -f db/data/shannonbase.err
   
   # Monitor MySQL performance
   mysqladmin -h 127.0.0.1 -P 3307 -u root -pshannonbase extended-status | grep -i innodb
   ```

4. **Sequential DDL Operations**:
   - Create all tables first (sequential)
   - Load data in parallel
   - Add Rapid engine last (if needed)

## Support

If issues persist:

1. **Check Error Log**:
   ```bash
   tail -100 /home/wuy/ShannonBase/db/data/shannonbase.err
   ```

2. **Check GDB Log** (if crash occurs):
   ```bash
   tail -100 /home/wuy/ShannonBase/db/gdb_crash.log
   ```

3. **Verify Configuration**:
   ```bash
   cat /home/wuy/ShannonBase/db/my_safe.cnf
   ```

4. **Test with Single Table**:
   ```bash
   # Try loading one table at a time
   mysql -h 127.0.0.1 -P 3307 -u root -pshannonbase -e "
   CREATE DATABASE test_db;
   CREATE TABLE test_db.simple_test (id INT PRIMARY KEY, name VARCHAR(100));
   INSERT INTO test_db.simple_test VALUES (1, 'test');
   SELECT * FROM test_db.simple_test;"
   ```
