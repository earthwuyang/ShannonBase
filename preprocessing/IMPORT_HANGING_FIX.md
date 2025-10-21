# Import Hanging Fix

## Problem

The import script hangs at **"Phase 2: Creating tables"** with no progress.

## Root Causes

1. **Foreign Key Constraints** - Tables with FK references hanging during creation
2. **No Progress Indication** - Can't tell which table is stuck
3. **No Timeout** - Connection hangs indefinitely
4. **Sequential Creation** - All tables created one-by-one, if one hangs, everything stops

## Immediate Actions

### 1. Kill the Hanging Process

```bash
# Find the Python process
ps aux | grep import_ctu_datasets_parallel

# Kill it
pkill -f import_ctu_datasets_parallel

# Or use Ctrl+C
```

### 2. Check MySQL Status

```bash
# Run diagnostic script
python3 check_mysql_status.py

# Or manually check
mysql -h 127.0.0.1 -P 3307 -u root -pshannonbase -e "SHOW PROCESSLIST"

# Kill any hanging queries
mysql -h 127.0.0.1 -P 3307 -u root -pshannonbase -e "KILL <process_id>"
```

### 3. Disable Foreign Key Checks (Temporary Fix)

```bash
# Disable FK checks globally
mysql -h 127.0.0.1 -P 3307 -u root -pshannonbase -e "SET GLOBAL FOREIGN_KEY_CHECKS=0"
```

## Permanent Fix (Already Applied)

The script has been updated with:

✅ **Progress Indication** - Shows "[1/19] Creating table..." so you know where it's stuck  
✅ **Disabled FK Checks** - Automatically disables foreign key checks during table creation  
✅ **Connection Timeout** - 30-second timeout prevents indefinite hanging  
✅ **Better Error Handling** - Shows which table failed and why  

## Run the Fixed Script

```bash
# Make sure you've killed the old process first
pkill -f import_ctu_datasets_parallel

# Run updated script
python3 import_ctu_datasets_parallel.py

# You should now see progress:
# [1/19] Creating L_AIRLINE_ID... ✓
# [2/19] Creating L_AIRPORT... ✓
# [3/19] Creating L_AIRPORT_ID... ✓
```

## If Still Hanging

### Check Which Table Is Stuck

The new version shows:
```
[5/19] Creating L_CANCELLATION...
```

If it hangs here for more than 30 seconds, that table has an issue.

### Manual Recovery

```bash
# 1. Kill the script
pkill -f import_ctu_datasets_parallel

# 2. Drop the problematic database
mysql -h 127.0.0.1 -P 3307 -u root -pshannonbase -e "DROP DATABASE IF EXISTS Airline"

# 3. Disable FK checks globally
mysql -h 127.0.0.1 -P 3307 -u root -pshannonbase -e "SET GLOBAL FOREIGN_KEY_CHECKS=0"

# 4. Re-run the script
python3 import_ctu_datasets_parallel.py

# 5. After successful import, re-enable FK checks
mysql -h 127.0.0.1 -P 3307 -u root -pshannonbase -e "SET GLOBAL FOREIGN_KEY_CHECKS=1"
```

## Why FK Checks Cause Hanging

When creating tables with foreign keys:

```sql
-- Table A references Table B
CREATE TABLE A (
    id INT PRIMARY KEY,
    b_id INT,
    FOREIGN KEY (b_id) REFERENCES B(id)  -- B must exist first!
);

-- If B doesn't exist or is being created, this hangs
```

The fix disables FK checks temporarily:
```sql
SET FOREIGN_KEY_CHECKS = 0;
-- Create tables in any order
SET FOREIGN_KEY_CHECKS = 1;
```

## Verify the Fix

```bash
# Test that it's working
python3 -c "
from import_ctu_datasets_parallel import connect_local_mysql
conn = connect_local_mysql()
print('✓ Connection works with timeout')
conn.close()
"
```

## Alternative: Use Original Script (Slower but Safer)

If the parallel version still has issues:

```bash
# Use the original sequential importer
python3 import_ctu_datasets.py --force
```

This is slower but has been more thoroughly tested.

## Quick Reference

```bash
# Check status
python3 check_mysql_status.py

# Kill hanging process
pkill -f import_ctu_datasets_parallel

# Disable FK checks
mysql -h 127.0.0.1 -P 3307 -u root -pshannonbase \
    -e "SET GLOBAL FOREIGN_KEY_CHECKS=0"

# Run fixed script
python3 import_ctu_datasets_parallel.py

# Re-enable FK checks after success
mysql -h 127.0.0.1 -P 3307 -u root -pshannonbase \
    -e "SET GLOBAL FOREIGN_KEY_CHECKS=1"
```

---

**Status**: Fixed in latest version  
**Date**: 2024  
**Issue**: Phase 2 hanging on table creation  
**Fix**: FK checks disabled, progress indication, timeout added
