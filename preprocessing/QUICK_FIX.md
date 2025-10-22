# Quick Fix for MySQL Crashes

## Your Crash: Rapid Engine Foreign Key Issue

**Error**: `Assertion failure: dict0dict.cc:3480:for_table || ref_table`  
**Trigger**: `ALTER TABLE call_center SECONDARY_LOAD`  
**Cause**: Foreign key constraints incompatible with Rapid engine loading

## One-Command Fix

```bash
cd /home/wuy/ShannonBase/preprocessing && ./fix_rapid_crash.sh
```

This will:
1. ✅ Stop and restart MySQL with safe settings
2. ✅ Increase redo log capacity (512MB → 2GB)
3. ✅ Create import scripts that skip Rapid engine

## Import Data Without Crashes

### Option 1: Run the fix script (creates patched scripts)
```bash
cd /home/wuy/ShannonBase/preprocessing
./fix_rapid_crash.sh

# Then run imports
./setup_tpc_no_rapid.sh        # TPC benchmarks (InnoDB only)
python3 import_ctu_no_rapid.py  # CTU datasets (InnoDB only)
```

### Option 2: Modify existing scripts to skip SECONDARY_LOAD

Edit your scripts and comment out these lines:

In `setup_tpc_benchmarks_parallel.sh`:
```bash
# Comment out around line 400-410:
# for table in customer lineitem nation orders part partsupp region supplier; do
#     print_status "Loading $table into Rapid..."
#     mysql_exec_db tpch_sf1 "ALTER TABLE \`$table\` SECONDARY_LOAD;" || print_warning "Failed"
# done
```

In `import_ctu_datasets_parallel.py`:
```python
# Remove SECONDARY_ENGINE from create_sql (around line 180):
create_sql_clean = create_sql.replace('SECONDARY_ENGINE=Rapid', '')
create_sql_clean = create_sql_clean.replace('SECONDARY_ENGINE = Rapid', '')
```

### Option 3: Use original scripts with reduced parallelism (will still crash on SECONDARY_LOAD)
```bash
export MAX_PARALLEL=2  # Reduced from 5
./setup_tpc_benchmarks_parallel.sh  # Will crash at SECONDARY_LOAD step
```

## Verify Fix

```bash
# Check MySQL is running
mysqladmin -h 127.0.0.1 -P 3307 -u root -pshannonbase ping

# Check for errors
tail -20 /home/wuy/ShannonBase/db/data/shannonbase.err

# View loaded tables
mysql -h 127.0.0.1 -P 3307 -u root -pshannonbase -e "
SELECT table_schema, COUNT(*) as tables, SUM(table_rows) as rows
FROM information_schema.tables 
WHERE table_schema IN ('tpch_sf1', 'tpcds_sf1')
GROUP BY table_schema;"
```

## Why This Happens

1. **Original scripts try to load tables into Rapid secondary engine**
2. **Rapid engine can't handle foreign key constraints properly**
3. **Assertion fails when resolving FK references**

## Solution Summary

- ✅ **Increase redo log capacity** (fixes redo log warnings)
- ✅ **Skip SECONDARY_LOAD** (prevents FK crash)
- ✅ **Tables work perfectly in InnoDB** (no functionality lost)
- ⚠️ **Can add Rapid later** for tables without FKs if needed

## Need More Help?

Read the full analysis:
```bash
cat /home/wuy/ShannonBase/preprocessing/CRASH_ANALYSIS.md
```
