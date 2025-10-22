# Debugging SECONDARY_LOAD Failures

## Current Status

✅ **Good news**: mysqld no longer crashes!  
❌ **Problem**: All tables fail to load into Rapid with SECONDARY_LOAD

From your output:
```
[WARNING]   ✗ call_center FAILED to load into Rapid (continuing anyway)
[WARNING]   ✗ catalog_page FAILED to load into Rapid (continuing anyway)
...
[INFO] TPC-DS Rapid loading complete: 0 loaded, 25 failed
```

## Changes Made

I've modified the script to **show actual error messages** instead of hiding them with `2>/dev/null`. This will help us diagnose why SECONDARY_LOAD is failing.

### Modified Files:
- `setup_tpc_benchmarks_parallel.sh` - Now captures and displays SECONDARY_LOAD errors
- `test_secondary_load.sh` - New test script to manually test one table

## Next Steps

### Option 1: Run Test Script First

Test a single table to see the exact error:

```bash
cd /home/wuy/ShannonBase/preprocessing
./test_secondary_load.sh
```

This will:
1. Check if table has `SECONDARY_ENGINE=Rapid`
2. Check for FK constraints
3. Try SECONDARY_LOAD and show the actual error
4. Verify MySQL doesn't crash

### Option 2: Re-run Main Script

Run the main script again to see error messages:

```bash
cd /home/wuy/ShannonBase/preprocessing
export MAX_PARALLEL=2
./setup_tpc_benchmarks_parallel.sh
```

**Look for lines like:**
```
[WARNING]   ✗ call_center FAILED to load into Rapid: ERROR: <actual error message>
[WARNING]   First error details: <full error message>
```

## Common Reasons for SECONDARY_LOAD Failure

### 1. Table doesn't have SECONDARY_ENGINE=Rapid

**Check**:
```sql
SHOW CREATE TABLE tpcds_sf1.call_center;
```

**Should see**: `SECONDARY_ENGINE=Rapid`

**If missing**:
```sql
ALTER TABLE tpcds_sf1.call_center SECONDARY_ENGINE=Rapid;
ALTER TABLE tpcds_sf1.call_center SECONDARY_LOAD;
```

### 2. Rapid engine not enabled

**Check**:
```sql
SHOW VARIABLES LIKE 'use_secondary_engine';
```

**Should be**: `ON` or `FORCED`

**If OFF**:
```sql
SET GLOBAL use_secondary_engine = ON;
```

### 3. Insufficient memory or resources

**Check error log**:
```bash
tail -100 /home/wuy/ShannonBase/db/data/shannonbase.err
```

**Look for**: Memory allocation errors, out of space, etc.

### 4. Rapid engine not compiled in

**Check**:
```sql
SHOW ENGINES;
```

**Should see**: Entry for `RAPID` or similar secondary engine

### 5. Foreign key metadata still present

**Check**:
```sql
SELECT constraint_name, table_name, referenced_table_name 
FROM information_schema.key_column_usage 
WHERE table_schema='tpcds_sf1' 
AND referenced_table_name IS NOT NULL;
```

**If FK constraints found**, they may be causing issues.

## Likely Scenarios

Based on your situation where **no tables load** but **MySQL doesn't crash**:

### Scenario A: Rapid engine not available/enabled

Most likely cause. Check:
```bash
mysql -h 127.0.0.1 -P 3307 -u root -pshannonbase -e "
SHOW ENGINES;
SHOW VARIABLES LIKE '%secondary%';
"
```

### Scenario B: Tables created without SECONDARY_ENGINE

Check one table:
```bash
mysql -h 127.0.0.1 -P 3307 -u root -pshannonbase -e "
SHOW CREATE TABLE tpcds_sf1.call_center\G
" | grep -i SECONDARY
```

If nothing found, the `SECONDARY_ENGINE=Rapid` didn't get applied during table creation.

### Scenario C: Permission or configuration issue

Check permissions:
```bash
mysql -h 127.0.0.1 -P 3307 -u root -pshannonbase -e "
SELECT CURRENT_USER();
SHOW GRANTS;
"
```

## Quick Manual Test

Test SECONDARY_LOAD manually on one table:

```bash
mysql -h 127.0.0.1 -P 3307 -u root -pshannonbase << 'EOF'
-- Check table structure
SHOW CREATE TABLE tpcds_sf1.date_dim\G

-- Try to load
SET SESSION FOREIGN_KEY_CHECKS=0;
ALTER TABLE tpcds_sf1.date_dim SECONDARY_LOAD;

-- Check result
SELECT table_name, create_options, table_rows
FROM information_schema.tables 
WHERE table_schema='tpcds_sf1' AND table_name='date_dim'\G
EOF
```

## After Getting Error Message

Once you see the actual error message, we can:

1. **If Rapid not available**: May need to rebuild MySQL with Rapid support
2. **If SECONDARY_ENGINE missing**: Script has a bug, need to fix table creation
3. **If FK issue persists**: Need different workaround
4. **If resource issue**: Adjust MySQL configuration
5. **If permission issue**: Grant necessary privileges

## Temporary Workaround

If you need to proceed without Rapid engine:

```bash
# Comment out SECONDARY_ENGINE in table definitions (lines 552-1025)
# Comment out entire SECONDARY_LOAD sections (lines 455-492, 1114-1149)

# Or use this sed command:
cd /home/wuy/ShannonBase/preprocessing
sed -i 's/SECONDARY_ENGINE=Rapid//g' setup_tpc_benchmarks_parallel.sh
sed -i '/SECONDARY_LOAD/,+5d' setup_tpc_benchmarks_parallel.sh
```

**Result**: All tables work perfectly in InnoDB, just without Rapid's columnar benefits.

## Summary

**Current state**: Tables are loaded and functional in InnoDB, but not in Rapid

**Next action**: Run test script or main script to see actual error messages

**Then**: Based on error, we can apply the appropriate fix

Please run either script and share the error message you see!
