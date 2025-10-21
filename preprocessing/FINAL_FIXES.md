# Final Fixes for collect_dual_engine_data.py

## Issue: Incorrect Argument Type for optimizer_trace Variables

### Error Messages
```
ERROR: 1232 (42000): Incorrect argument type to variable 'optimizer_trace_limit'
ERROR: 1232 (42000): Incorrect argument type to variable 'optimizer_trace_offset'
ERROR: 1232 (42000): Incorrect argument type to variable 'optimizer_trace_max_mem_size'
```

### Root Cause

The script was wrapping ALL variable values in quotes:
```python
# WRONG - quotes everything
cursor.execute(f"SET {setting} = '{value}'")

# This becomes:
SET optimizer_trace_limit = '5'      # ❌ Wrong - string, expects integer
SET optimizer_trace_offset = '-5'    # ❌ Wrong - string, expects integer
SET optimizer_trace_max_mem_size = '1048576'  # ❌ Wrong - string, expects integer
```

### Fix Applied

Added type checking to use quotes only for strings:
```python
# CORRECT - type-aware setting
for setting, value in OPTIMIZER_TRACE_SETTINGS.items():
    if isinstance(value, str):
        cursor.execute(f"SET {setting} = '{value}'")  # String values get quotes
    else:
        cursor.execute(f"SET {setting} = {value}")    # Numeric values no quotes
```

### Result

Now correctly sets:
```sql
-- String values (quoted)
SET optimizer_trace = 'enabled=on,one_line=off'
SET optimizer_trace_features = 'greedy_search=on,...'

-- Numeric values (unquoted)
SET optimizer_trace_limit = 5
SET optimizer_trace_offset = -5
SET optimizer_trace_max_mem_size = 1048576
```

## Complete Configuration

```python
OPTIMIZER_TRACE_SETTINGS = {
    # Strings - will be quoted
    'optimizer_trace': 'enabled=on,one_line=off',
    'optimizer_trace_features': 'greedy_search=on,range_optimizer=on,dynamic_range=on,repeated_subselect=on',
    
    # Integers - will NOT be quoted
    'optimizer_trace_limit': 5,
    'optimizer_trace_offset': -5,
    'optimizer_trace_max_mem_size': 1048576
}
```

## All Issues Now Resolved ✅

| Issue | Status | Fix |
|-------|--------|-----|
| Port 3306 connection error | ✅ Fixed | Both use port 3307 |
| optimizer_trace_features = 1 | ✅ Fixed | Changed to string format |
| optimizer_trace_limit type error | ✅ Fixed | Type-aware setting (no quotes for integers) |
| Hardcoded database | ✅ Fixed | Dynamic database from filename |
| Wrong engine variable | ✅ Fixed | use_secondary_engine (not use_column_engine) |

## Verification Test

```bash
# Test all settings work correctly
mysql -h 127.0.0.1 -P 3307 -u root -pshannonbase tpch_sf1 <<'EOF'
-- String settings
SET optimizer_trace = 'enabled=on,one_line=off';
SET optimizer_trace_features = 'greedy_search=on,range_optimizer=on,dynamic_range=on,repeated_subselect=on';

-- Numeric settings
SET optimizer_trace_limit = 5;
SET optimizer_trace_offset = -5;
SET optimizer_trace_max_mem_size = 1048576;

-- Engine control
SET SESSION use_secondary_engine = OFF;
SET SESSION use_secondary_engine = FORCED;

-- Verify all settings
SHOW VARIABLES LIKE 'optimizer_trace%';
SELECT @@session.use_secondary_engine;
EOF
```

## Changes Made (Lines)

1. **Lines 92-96**: Type-aware variable setting in `connect_mysql()`
2. **Lines 114-118**: Type-aware variable setting in `connect_shannonbase()`

### Code Changes

```python
# Before (BROKEN):
for setting, value in OPTIMIZER_TRACE_SETTINGS.items():
    cursor.execute(f"SET {setting} = '{value}'")  # Always quotes

# After (FIXED):
for setting, value in OPTIMIZER_TRACE_SETTINGS.items():
    if isinstance(value, str):
        cursor.execute(f"SET {setting} = '{value}'")  # Quote strings
    else:
        cursor.execute(f"SET {setting} = {value}")    # No quotes for numbers
```

## Ready to Run

```bash
cd /home/wuy/DB/ShannonBase/preprocessing

# Process all workloads
python3 collect_dual_engine_data.py

# Process specific database
python3 collect_dual_engine_data.py --database tpch_sf1

# With dataset generation
python3 collect_dual_engine_data.py --generate-dataset
```

## Expected Behavior

Each query will now:

1. ✅ Connect to ShannonBase on port 3307 with correct database
2. ✅ Set optimizer trace settings with correct types
3. ✅ Force PRIMARY engine (use_secondary_engine = OFF)
4. ✅ Execute query on InnoDB and measure latency
5. ✅ Force SECONDARY engine (use_secondary_engine = FORCED)
6. ✅ Execute query on Rapid and measure latency
7. ✅ Save comparison data with metadata

## Testing Output

When working correctly, you'll see:
```
2025-10-21 HH:MM:SS - INFO - Detected database: tpch_sf1
2025-10-21 HH:MM:SS - INFO - Processing TP query q_0001 (1/9954) - Type: tp_point_lookup
[No connection errors]
[No type errors]
2025-10-21 HH:MM:SS - INFO - Processing TP query q_0002 (2/9954) - Type: tp_range_scan
...
```

## Summary

All configuration and type issues are now resolved:
- ✅ Correct port (3307)
- ✅ Correct optimizer trace format
- ✅ Correct variable types (strings quoted, integers not)
- ✅ Dynamic database selection
- ✅ Proper engine forcing

The script is now fully functional and ready for data collection! 🎉
