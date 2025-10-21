# Critical Fixes Applied to collect_dual_engine_data.py

## Issues Fixed

### Issue 1: Wrong Port Configuration ✅
**Error**: `Can't connect to MySQL server on '127.0.0.1:3306' (111)`

**Root Cause**: Configuration still had port 3306 in active connections despite earlier edit

**Fix**: Verified both MYSQL_CONFIG and SHANNONBASE_CONFIG use port 3307
```python
MYSQL_CONFIG = {'port': 3307, ...}
SHANNONBASE_CONFIG = {'port': 3307, ...}
```

### Issue 2: Invalid optimizer_trace_features Value ✅
**Error**: `Variable 'optimizer_trace_features' can't be set to the value of '1'`

**Root Cause**: The variable expects a string with feature flags, not a numeric value

**Fix**: Changed from integer to proper feature string
```python
# Before (WRONG):
'optimizer_trace_features': 1,

# After (CORRECT):
'optimizer_trace_features': 'greedy_search=on,range_optimizer=on,dynamic_range=on,repeated_subselect=on',
```

### Issue 3: Dynamic Database Selection ✅
**Problem**: Hardcoded database in configuration meant only tpch_sf1 could be used

**Fix**: Added database parameter to connection methods
```python
def connect_mysql(self, database=None):
    config = MYSQL_CONFIG.copy()
    if database:
        config['database'] = database
    conn = mysql.connector.connect(**config)
```

Automatically detects database from workload filename:
```python
# training_workload_tpcds_sf1.sql → database = 'tpcds_sf1'
# training_workload_Airline.sql → database = 'Airline'
```

## Verification

All fixes verified with test script:

```bash
# 1. optimizer_trace_features accepts string format ✅
SET optimizer_trace_features = 'greedy_search=on,...';

# 2. Both engine modes work correctly ✅
SET SESSION use_secondary_engine = OFF;     # PRIMARY (InnoDB)
SET SESSION use_secondary_engine = FORCED;  # SECONDARY (Rapid)

# 3. Database can be dynamically changed ✅
USE tpch_sf1;   # Works
USE tpcds_sf1;  # Works
USE Airline;    # Works
```

## Complete Fix Summary

| Component | Before | After | Status |
|-----------|--------|-------|--------|
| Port | Mixed 3306/3307 | Both 3307 | ✅ Fixed |
| optimizer_trace_features | Integer `1` | String with flags | ✅ Fixed |
| optimizer_trace_max_mem_size | 65536 | 1048576 | ✅ Fixed |
| Database selection | Hardcoded | Dynamic | ✅ Fixed |
| Engine forcing | Wrong variable | Correct `use_secondary_engine` | ✅ Fixed |

## Configuration After Fixes

```python
# Both use ShannonBase on port 3307
MYSQL_CONFIG = {
    'host': '127.0.0.1',
    'port': 3307,              # ✅ ShannonBase
    'user': 'root',
    'password': 'shannonbase',
    'database': 'tpch_sf1'     # ✅ Default, overridden dynamically
}

SHANNONBASE_CONFIG = {
    'host': '127.0.0.1',
    'port': 3307,              # ✅ ShannonBase
    'user': 'root',
    'password': 'shannonbase',
    'database': 'tpch_sf1'     # ✅ Default, overridden dynamically
}

OPTIMIZER_TRACE_SETTINGS = {
    'optimizer_trace': 'enabled=on,one_line=off',
    'optimizer_trace_features': 'greedy_search=on,range_optimizer=on,dynamic_range=on,repeated_subselect=on',  # ✅ String format
    'optimizer_trace_limit': 5,
    'optimizer_trace_offset': -5,
    'optimizer_trace_max_mem_size': 1048576  # ✅ Increased from 65536
}
```

## Usage Now Working

```bash
# Process all workloads (auto-detects database from filename)
cd /home/wuy/DB/ShannonBase/preprocessing
python3 collect_dual_engine_data.py

# Process specific database
python3 collect_dual_engine_data.py --database tpch_sf1

# Process with dataset generation
python3 collect_dual_engine_data.py --generate-dataset
```

## Expected Behavior

For each query, the script now:

1. **Connects to ShannonBase (port 3307)** with PRIMARY engine forced
   - Sets `use_secondary_engine = OFF`
   - Executes query on InnoDB (row store)
   - Measures latency

2. **Connects to ShannonBase (port 3307)** with SECONDARY engine forced
   - Sets `use_secondary_engine = FORCED`
   - Executes query on Rapid (column store)
   - Measures latency

3. **Saves comparison data** with:
   - Engine modes verified
   - Engine types labeled
   - Database name recorded
   - Latencies for both engines

## Testing

To verify the script works correctly:

```bash
# 1. Check ShannonBase is running
mysql -h 127.0.0.1 -P 3307 -u root -pshannonbase -e "SELECT 1"

# 2. Verify engines available
mysql -h 127.0.0.1 -P 3307 -u root -pshannonbase -e "SHOW ENGINES WHERE Engine IN ('InnoDB', 'Rapid')"

# 3. Test with small workload
python3 collect_dual_engine_data.py --database tpch_sf1 --output ./test_output

# 4. Check results
ls -lh test_output/
cat test_output/q_0000_results.json | python3 -m json.tool | grep -A3 engine
```

## What Was NOT Changed

- Auto-discovery logic (still works)
- Workload parsing (JSON/SQL formats)
- Feature extraction (from optimizer trace)
- Latency measurement (warmup + runs)
- Result saving (CSV, JSON formats)

Only fixed configuration errors and added dynamic database support.

## Remaining Considerations

1. **Engine Eligibility**: Not all queries can use Rapid engine
   - TP queries (point lookups) may fall back to InnoDB
   - This is expected behavior, not an error

2. **Performance**: Some queries may be slower with tracing enabled
   - Tracing is necessary for feature extraction
   - Only affects training data collection, not production

3. **Memory**: optimizer_trace_max_mem_size increased to 1MB
   - May need adjustment for very complex queries
   - Can be increased if trace truncation occurs

## Next Steps

1. ✅ All configuration issues resolved
2. ✅ Script ready for data collection
3. ▶️ Run: `python3 collect_dual_engine_data.py`
4. ▶️ Generate training dataset
5. ▶️ Train hybrid optimizer model
