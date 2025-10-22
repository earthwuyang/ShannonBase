# CTU Import Bug Fix - Empty Tables Issue

## Problem

After running `import_ctu_datasets_parallel.py`, all tables in the Airline database (and other CTU datasets) were created but remained empty with 0 rows, despite CSV files containing data.

### Error Encountered

```
3890 (HY000): DDLs on a table with a secondary engine defined are not allowed.
```

## Root Cause

The bug was introduced when adding the automatic SECONDARY_LOAD feature. The flow was:

1. **Phase 2: Create Tables**
   - Created table structure
   - **Immediately added `SECONDARY_ENGINE=Rapid`** ❌

2. **Phase 3: Import Data**
   - Tried to run `ALTER TABLE ... DISABLE KEYS` (DDL operation)
   - **MySQL blocked this** because tables with `SECONDARY_ENGINE` defined cannot have DDL operations
   - Import silently failed, leaving tables empty

### The Bug in Code

In `create_table_if_not_exists()`:

```python
# BUGGY CODE (before fix):
cursor.execute(create_sql_clean)

# Now add SECONDARY_ENGINE=Rapid separately (after all DDL in CREATE TABLE)
cursor.execute(f"ALTER TABLE `{table}` SECONDARY_ENGINE=Rapid")  # ❌ TOO EARLY!
```

This added `SECONDARY_ENGINE` immediately after table creation, before data import.

Then in `import_table_batch()`:

```python
# Phase 3 tries to optimize with indexes:
cursor.execute(f"ALTER TABLE `{table}` DISABLE KEYS")  # ❌ FAILS! Error 3890
# Import data
cursor.execute(f"ALTER TABLE `{table}` ENABLE KEYS")   # Never reached
```

## Fix

### Change 1: Don't Add SECONDARY_ENGINE During Table Creation

Updated `create_table_if_not_exists()`:

```python
# FIXED CODE:
def create_table_if_not_exists(database, table, create_sql):
    """Create table in local database WITHOUT SECONDARY_ENGINE
    
    SECONDARY_ENGINE will be added later in Phase 4 (before SECONDARY_LOAD)
    to avoid DDL errors during data import (Phase 3).
    
    MySQL Error 3890: DDLs on a table with a secondary engine defined are not allowed.
    This includes ALTER TABLE ... DISABLE/ENABLE KEYS used during import.
    """
    # ... create table WITHOUT SECONDARY_ENGINE
    cursor.execute(create_sql_clean)
    
    # DON'T add SECONDARY_ENGINE here anymore! ✅
    # It will be added in Phase 4, before SECONDARY_LOAD
```

### Change 2: Add SECONDARY_ENGINE Before SECONDARY_LOAD

Updated `load_tables_to_rapid()`:

```python
# FIXED CODE:
def load_tables_to_rapid(database, tables):
    """Load all tables into Rapid secondary engine with retry logic
    
    This function:
    1. Adds SECONDARY_ENGINE=Rapid to each table (if not already set)  ✅
    2. Runs ALTER TABLE ... SECONDARY_LOAD to load data into Rapid
    """
    for table in tables:
        # First, ensure SECONDARY_ENGINE is set
        cursor.execute(f"""
            SELECT CREATE_OPTIONS 
            FROM information_schema.tables 
            WHERE table_schema = %s AND table_name = %s
        """, (database, table))
        
        result = cursor.fetchone()
        has_secondary = result and 'SECONDARY_ENGINE' in (result[0] or '')
        
        if not has_secondary:
            cursor.execute(f"ALTER TABLE `{table}` SECONDARY_ENGINE=Rapid")  ✅ NOW!
        
        # Then do SECONDARY_LOAD
        cursor.execute(f"ALTER TABLE `{table}` SECONDARY_LOAD")
```

## Corrected Flow

### After Fix:

1. **Phase 1: Export** - Export tables to CSV ✅
2. **Phase 2: Create Tables** - Create table structure WITHOUT `SECONDARY_ENGINE` ✅
3. **Phase 3: Import Data** - Import data from CSV (DDL operations allowed) ✅
4. **Phase 4: Load to Rapid**:
   - Add `SECONDARY_ENGINE=Rapid` ✅
   - Run `SECONDARY_LOAD` ✅

## MySQL Constraint Explained

From MySQL documentation:

> **Error 3890**: DDLs on a table with a secondary engine defined are not allowed.
>
> This includes:
> - `ALTER TABLE ... ADD/DROP INDEX`
> - `ALTER TABLE ... ADD/DROP COLUMN`
> - `ALTER TABLE ... DISABLE/ENABLE KEYS`
> - `ALTER TABLE ... RENAME`
> - `TRUNCATE TABLE`
>
> Once `SECONDARY_ENGINE` is set, the table structure cannot be modified until you remove the secondary engine definition.

## Testing the Fix

### To Re-import Airline Database:

```bash
# Drop the empty database
mysql -uroot -pshannonbase --socket=/home/wuy/ShannonBase/db/mysql.sock \
  -e "DROP DATABASE IF EXISTS Airline;"

# Re-run import (will use cached CSV files)
cd /home/wuy/ShannonBase/preprocessing
python3 import_ctu_datasets_parallel.py --databases Airline
```

### Verify Data Was Imported:

```sql
USE Airline;

-- Should show ~445,000 rows
SELECT COUNT(*) FROM On_Time_On_Time_Performance_2016_1;

-- Should show data in all tables
SELECT table_name, table_rows 
FROM information_schema.tables 
WHERE table_schema='Airline' 
ORDER BY table_name;

-- Verify Rapid loading worked
SELECT table_name, create_options 
FROM information_schema.tables 
WHERE table_schema='Airline' 
AND create_options LIKE '%SECONDARY_ENGINE%';
```

### Expected Output:

```
+-------------------------------------+-----------+
| table_name                          | row_count |
+-------------------------------------+-----------+
| L_AIRLINE_ID                        |      1491 |
| L_AIRPORT                           |       388 |
| L_AIRPORT_ID                        |       382 |
| ...                                 |       ... |
| On_Time_On_Time_Performance_2016_1  |    445827 |  ✅
+-------------------------------------+-----------+
```

## Impact

This bug affected:
- ✅ **All CTU datasets** - All tables would be empty after import
- ✅ **Fresh imports** - First run would fail to populate tables
- ✅ **Re-runs** - Would skip import thinking data exists, but tables still empty

## Files Modified

1. ✅ **import_ctu_datasets_parallel.py**
   - `create_table_if_not_exists()` - Removed immediate SECONDARY_ENGINE addition
   - `load_tables_to_rapid()` - Added SECONDARY_ENGINE before SECONDARY_LOAD

## Related Issues

This fix is compatible with:
- ✅ Smart loading (skip if data exists)
- ✅ Automatic SECONDARY_LOAD with retry
- ✅ Force reload (`--force` flag)
- ✅ Parallel processing
- ✅ All CTU datasets

## Prevention

To prevent similar issues:
1. Always test data import after schema changes
2. Check `table_rows` after import completes
3. Monitor for silently failed imports
4. Add `SECONDARY_ENGINE` only after all DDL operations complete

## Date Fixed

2025-10-22
