# TPC Benchmarks Troubleshooting Guide

## Common Issues and Solutions

### Issue 1: Permission Denied When Cleaning Data Files

#### Symptom
```bash
[INFO] Cleaning data files...
sed: can't read nation.tbl: Permission denied
sed: can't read region.tbl: Permission denied
```

#### Root Cause
The TPC-H `dbgen` and TPC-DS `dsdgen` tools sometimes create data files with read-only permissions, preventing the cleanup scripts from modifying them.

#### Solution 1: Use Updated Scripts (Recommended)

The updated scripts now automatically fix permissions:

```bash
# Updated scripts handle this automatically
./setup_tpc_benchmarks.sh
# or
./setup_tpc_benchmarks_parallel.sh
```

#### Solution 2: Manual Permission Fix

If using older scripts or encountering the issue:

```bash
# Quick fix script
./fix_tpc_permissions.sh

# Or manually fix TPC-H files
cd /home/wuy/DB/ShannonBase/preprocessing/tpch-dbgen
chmod u+w *.tbl

# Or manually fix TPC-DS files
cd /home/wuy/DB/ShannonBase/preprocessing/tpcds_data
chmod u+w *.dat
```

#### Solution 3: Run as Different User

If the files are owned by a different user:

```bash
# Check file ownership
ls -l *.tbl

# If owned by root or another user, fix ownership
sudo chown $USER:$USER *.tbl
chmod u+w *.tbl
```

#### Solution 4: Skip Cleaning (Not Recommended)

If you can't fix permissions, you can skip the cleaning step, but data loading may fail due to trailing pipes:

```bash
# Load data with trailing pipes (may cause issues)
# MySQL LOAD DATA expects clean format
```

---

### Issue 2: Data Files Not Found

#### Symptom
```bash
[ERROR] lineitem.tbl not found
```

#### Solution

```bash
# Regenerate data
cd /home/wuy/DB/ShannonBase/preprocessing/tpch-dbgen
./dbgen -vf -s 1

# Or re-run setup script with clean slate
rm -rf tpch-dbgen tpcds_data databricks-tpcds
./setup_tpc_benchmarks.sh
```

---

### Issue 3: Compilation Errors

#### Symptom
```bash
gcc: error: build.c:420:9: ...
make: *** [build.o] Error 1
```

#### Solution

```bash
# Update compiler
sudo apt-get update
sudo apt-get install build-essential

# Or specify C standard
cd tpch-dbgen
make clean
CFLAGS="-std=gnu99" make
```

---

### Issue 4: LOAD DATA LOCAL INFILE Disabled

#### Symptom
```bash
ERROR 1148 (42000): The used command is not allowed with this MySQL version
```

#### Solution

```bash
# Enable local_infile
mysql -h 127.0.0.1 -P 3307 -u root -p -e "SET GLOBAL local_infile = 1"

# Or add to my.cnf
[mysqld]
local_infile = 1

[mysql]
local_infile = 1
```

---

### Issue 5: Character Encoding Issues (TPC-DS)

#### Symptom
```bash
ERROR 1366 (HY000): Incorrect string value: '\xF4\x8F\xBF\xBF' for column 'ca_city'
```

#### Solution

The updated scripts now handle this automatically with `iconv`:

```bash
# Manual fix if needed
cd tpcds_data
for file in *.dat; do
    iconv -f LATIN1 -t UTF-8//IGNORE "$file" > "${file}.utf8"
    mv "${file}.utf8" "$file"
done
```

---

### Issue 6: Out of Disk Space

#### Symptom
```bash
No space left on device
```

#### Solution

```bash
# Check disk space
df -h

# Clean up old data
cd /home/wuy/DB/ShannonBase/preprocessing
rm -rf tpch-dbgen/*.tbl
rm -rf tpcds_data/*.dat

# Or use a different directory with more space
export TMPDIR=/mnt/large_disk
./setup_tpc_benchmarks.sh
```

---

### Issue 7: MySQL Connection Refused

#### Symptom
```bash
ERROR 2003 (HY000): Can't connect to MySQL server on '127.0.0.1:3307'
```

#### Solution

```bash
# Check if MySQL is running
mysql -h 127.0.0.1 -P 3307 -u root -p -e "SELECT 1"

# Check correct port
netstat -tlnp | grep mysql

# Verify credentials
export MYSQL_HOST=127.0.0.1
export MYSQL_PORT=3307
export MYSQL_USER=root
export MYSQL_PASSWORD=shannonbase
```

---

### Issue 8: Foreign Key Constraint Failures

#### Symptom
```bash
ERROR 1452 (23000): Cannot add or update a child row: a foreign key constraint fails
```

#### Solution

```bash
# Load in correct order (the scripts do this automatically)
# Or disable foreign key checks temporarily
mysql -e "SET FOREIGN_KEY_CHECKS = 0;"

# Re-enable after load
mysql -e "SET FOREIGN_KEY_CHECKS = 1;"
```

---

### Issue 9: Parallel Loading Hangs

#### Symptom
```bash
[PROGRESS] Loading part...
[PROGRESS] Loading supplier...
# ... hangs indefinitely
```

#### Solution

```bash
# Reduce parallel workers
MAX_PARALLEL=4 ./setup_tpc_benchmarks_parallel.sh

# Or check for deadlocks
mysql -e "SHOW ENGINE INNODB STATUS\G" | grep DEADLOCK

# Kill stuck jobs
pkill -f load_tpch_table
```

---

### Issue 10: Duplicate Entry Errors

#### Symptom
```bash
ERROR 1062 (23000): Duplicate entry '1' for key 'PRIMARY'
```

#### Solution

The parallel scripts now use `REPLACE INTO` which handles this automatically:

```bash
# Use parallel scripts
./setup_tpc_benchmarks_parallel.sh

# Or manually use REPLACE
mysql -e "LOAD DATA LOCAL INFILE 'data.tbl' REPLACE INTO TABLE lineitem ..."
```

---

## Verification Steps

### Check Data Generation

```bash
# TPC-H
cd /home/wuy/DB/ShannonBase/preprocessing/tpch-dbgen
ls -lh *.tbl
wc -l lineitem.tbl  # Should be ~6M rows for SF1

# TPC-DS
cd /home/wuy/DB/ShannonBase/preprocessing/tpcds_data
ls -lh *.dat
wc -l store_sales.dat  # Should be ~2.8M rows for SF1
```

### Check File Permissions

```bash
# TPC-H
cd tpch-dbgen
ls -l *.tbl | head -5
# Should show: -rw-r--r-- (at least -rw for user)

# TPC-DS
cd tpcds_data
ls -l *.dat | head -5
# Should show: -rw-r--r-- (at least -rw for user)
```

### Check Data Quality

```bash
# Check for trailing pipes (should be removed)
cd tpch-dbgen
tail -n 1 nation.tbl
# Should NOT end with "|"

# Check for proper encoding
cd tpcds_data
file customer.dat
# Should show: UTF-8 Unicode text

# Check record counts match
head -1 lineitem.tbl | awk -F'|' '{print NF}'
# Should match number of columns in table definition
```

### Verify Database Load

```sql
-- Check all tables loaded
USE tpch_sf1;
SELECT table_name, table_rows 
FROM information_schema.tables 
WHERE table_schema = 'tpch_sf1';

-- Expected row counts for SF1:
-- region: 5
-- nation: 25
-- customer: 150,000
-- part: 200,000
-- supplier: 10,000
-- partsupp: 800,000
-- orders: 1,500,000
-- lineitem: 6,001,215

-- Check data integrity
SELECT COUNT(*) FROM lineitem WHERE l_orderkey IS NULL;
-- Should be 0

-- Check foreign keys
SELECT COUNT(*) FROM lineitem l
LEFT JOIN orders o ON l.l_orderkey = o.o_orderkey
WHERE o.o_orderkey IS NULL;
-- Should be 0
```

---

## Performance Tuning

### Speed Up Data Generation

```bash
# Use all CPU cores for compilation
cd tpch-dbgen
make clean
make -j$(nproc)

# Generate larger scale factors in parallel
# (split by chunks, then combine)
```

### Speed Up Data Loading

```bash
# Increase MySQL buffer sizes temporarily
mysql -e "
SET GLOBAL innodb_buffer_pool_size = 4294967296;
SET GLOBAL innodb_log_file_size = 536870912;
SET GLOBAL bulk_insert_buffer_size = 268435456;
"

# Use parallel loading
MAX_PARALLEL=16 ./setup_tpc_benchmarks_parallel.sh

# Disable safety features temporarily (DANGER!)
mysql -e "
SET GLOBAL innodb_flush_log_at_trx_commit = 2;
SET GLOBAL sync_binlog = 0;
"

# IMPORTANT: Re-enable after load!
mysql -e "
SET GLOBAL innodb_flush_log_at_trx_commit = 1;
SET GLOBAL sync_binlog = 1;
"
```

---

## Clean Up and Reset

### Remove All TPC Data

```bash
cd /home/wuy/DB/ShannonBase/preprocessing

# Remove source files
rm -rf tpch-dbgen
rm -rf databricks-tpcds
rm -rf tpcds_data

# Drop databases
mysql -e "DROP DATABASE IF EXISTS tpch_sf1"
mysql -e "DROP DATABASE IF EXISTS tpcds_sf1"
```

### Start Fresh

```bash
# Clean slate
./setup_tpc_benchmarks.sh

# Or with parallel loading
./setup_tpc_benchmarks_parallel.sh
```

---

## Getting Help

### Debug Mode

```bash
# Enable bash debug output
bash -x ./setup_tpc_benchmarks.sh 2>&1 | tee debug.log

# Check MySQL error log
tail -f /var/log/mysql/error.log
```

### Collect Diagnostics

```bash
# System info
uname -a
df -h
free -h
nproc

# MySQL info
mysql --version
mysql -e "SHOW VARIABLES LIKE '%version%'"
mysql -e "SHOW VARIABLES LIKE 'local_infile'"

# File permissions
ls -lR tpch-dbgen/*.tbl 2>/dev/null
ls -lR tpcds_data/*.dat 2>/dev/null

# Process info
ps aux | grep mysql
ps aux | grep dbgen
```

---

## Quick Reference

### Essential Commands

```bash
# Fix permissions
./fix_tpc_permissions.sh

# Run setup (original)
./setup_tpc_benchmarks.sh

# Run setup (parallel, faster)
./setup_tpc_benchmarks_parallel.sh

# Custom settings
MAX_PARALLEL=8 BATCH_SIZE=500000 ./setup_tpc_benchmarks_parallel.sh

# Verify data
mysql -e "SELECT COUNT(*) FROM tpch_sf1.lineitem"
mysql -e "SELECT COUNT(*) FROM tpcds_sf1.store_sales"
```

### File Locations

```
/home/wuy/DB/ShannonBase/preprocessing/
├── tpch-dbgen/              # TPC-H source and data
│   ├── dbgen                # Data generator
│   └── *.tbl                # Generated data files
├── databricks-tpcds/        # TPC-DS source
│   └── tools/dsdgen         # Data generator
├── tpcds_data/              # TPC-DS data
│   └── *.dat                # Generated data files
├── setup_tpc_benchmarks.sh              # Original setup
├── setup_tpc_benchmarks_parallel.sh     # Parallel setup
└── fix_tpc_permissions.sh               # Permission fix utility
```

---

**Last Updated**: 2024  
**Version**: 1.0  
**Author**: Droid (Factory AI)
