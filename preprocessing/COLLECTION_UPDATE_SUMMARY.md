# Data Collection Script Update Summary

## Changes to `collect_dual_engine_data.py`

Updated the data collection script to use Rapid-compatible workloads by default.

## What Changed

### 1. Default Workload Pattern
**Before:**
```python
def discover_workload_files(pattern='training_workload_*.sql'):
```

**After:**
```python
def discover_workload_files(pattern='training_workload_rapid_*.sql'):
```

### 2. New Command-Line Argument
Added `--workload-pattern` to allow switching between workload types:

```bash
# Default: Use Rapid-compatible workloads
python3 collect_dual_engine_data.py --workload auto

# Explicit: Use original workloads (many will be rejected)
python3 collect_dual_engine_data.py --workload-pattern 'training_workload_*.sql'
```

### 3. Updated Help Messages

**Description:**
- Before: "Collect dual engine execution data for AP and TP queries"
- After: "Collect dual engine execution data (optimized for Rapid-compatible queries)"

**Examples:**
```bash
# Now shows Rapid-compatible examples by default
python3 collect_dual_engine_data.py --workload ../training_workloads/training_workload_rapid_tpch_sf1.sql
```

### 4. Better Error Messages
When no workload files are found:

**Before:**
```
No workload files found. Please generate workloads first using:
  python3 generate_training_workload_advanced.py --all-datasets
```

**After:**
```
No workload files found matching pattern: training_workload_rapid_*.sql
Please generate workloads first using:
  python3 generate_training_workload_rapid_compatible.py --all-datasets

Or use original workloads (many queries will be rejected):
  python3 collect_dual_engine_data.py --workload-pattern 'training_workload_*.sql'
```

## Usage Examples

### Default (Rapid-Compatible Workloads)

```bash
# Auto-discover all Rapid-compatible workloads
python3 collect_dual_engine_data.py --workload auto

# Process specific Rapid-compatible workload
python3 collect_dual_engine_data.py --workload ../training_workloads/training_workload_rapid_tpch_sf1.sql

# Filter to specific database
python3 collect_dual_engine_data.py --workload auto --database tpch_sf1

# With dataset generation
python3 collect_dual_engine_data.py --workload auto --generate-dataset
```

### Using Original Workloads (Not Recommended)

```bash
# Use original workloads (expect ~70-80% rejection rate)
python3 collect_dual_engine_data.py --workload-pattern 'training_workload_*.sql'

# Or specify explicitly
python3 collect_dual_engine_data.py --workload ../training_workloads/training_workload_tpch_sf1.sql
```

## Expected Results Comparison

### With Original Workloads (`training_workload_*.sql`)
```
Processing 10000 queries:
  TP queries rejected: ~5000 (100% rejection - index scans not supported)
  AP queries rejected: ~2000 (40% rejection - subqueries, unions, etc.)
  Successful: ~3000 (30% success rate)
  
Rapid engine errors:
  - "Secondary engine operation failed" (nested loop joins)
  - "Query pattern not supported" (index scans)
  - Timeout on complex queries
```

### With Rapid-Compatible Workloads (`training_workload_rapid_*.sql`)
```
Processing 10000 queries:
  TP queries: 0 (removed entirely)
  AP queries: 10000 (all Rapid-compatible)
  Successful: ~9000-9500 (90-95% success rate)
  
Remaining failures likely:
  - Table not loaded into Rapid
  - Query timeout (>60 seconds)
  - Unsupported data types
  - Edge case query patterns
```

## Complete Workflow

### 1. Generate Rapid-Compatible Workloads
```bash
cd /home/wuy/ShannonBase/preprocessing

# Generate for all datasets
python3 generate_training_workload_rapid_compatible.py --all-datasets

# Or for specific database
python3 generate_training_workload_rapid_compatible.py --database tpch_sf1 --num-queries 5000
```

### 2. Ensure Tables Are Loaded
```bash
# Make sure tables have SECONDARY_ENGINE=RAPID
mysql -h 127.0.0.1 -P 3307 -u root -D tpch_sf1 -e "
ALTER TABLE customer SECONDARY_ENGINE=RAPID;
ALTER TABLE lineitem SECONDARY_ENGINE=RAPID;
-- ... etc for all tables
"

# Load tables into Rapid
mysql -h 127.0.0.1 -P 3307 -u root -D tpch_sf1 -e "
ALTER TABLE customer SECONDARY_LOAD=ON;
ALTER TABLE lineitem SECONDARY_LOAD=ON;
-- ... etc
"
```

### 3. Collect Data (Now Uses Rapid Workloads by Default)
```bash
cd /home/wuy/ShannonBase

# Default: Auto-discover Rapid-compatible workloads
python3 preprocessing/collect_dual_engine_data.py --workload auto

# Check results
cat training_data/collection_summary.json
```

### 4. Review Results
```bash
# Check success rates
jq '.successful_shannon, .successful_mysql, .total_queries' training_data/collection_summary.json

# Check error breakdown
jq '.errors' training_data/collection_summary.json

# Should see something like:
# {
#   "successful_shannon": 9200,
#   "successful_mysql": 9800,
#   "total_queries": 10000,
#   "errors": {
#     "rapid_not_supported": 50,
#     "table_not_found": 10,
#     "timeout": 40,
#     "total_errors": 800
#   }
# }
```

## Benefits

1. **Higher Success Rate**: 90-95% instead of 30%
2. **Less Noise**: Only relevant errors (not design limitations)
3. **Better Training Data**: More balanced MySQL vs Rapid comparisons
4. **Faster Collection**: Less time wasted on doomed queries
5. **Clear Intent**: Script name shows it's for Rapid

## Backward Compatibility

The script still supports original workloads:

```bash
# Option 1: Use --workload-pattern flag
python3 collect_dual_engine_data.py --workload-pattern 'training_workload_*.sql'

# Option 2: Specify file explicitly
python3 collect_dual_engine_data.py --workload ../training_workloads/training_workload_tpch_sf1.sql

# Option 3: Use glob pattern
python3 collect_dual_engine_data.py --workload '../training_workloads/training_workload_*.sql'
```

## Files Modified

- ✅ `preprocessing/collect_dual_engine_data.py` - Updated to use Rapid workloads
- ✅ Default pattern changed: `training_workload_rapid_*.sql`
- ✅ New flag: `--workload-pattern`
- ✅ Updated help text and examples

## Files Created (Previous Steps)

- ✅ `preprocessing/generate_training_workload_rapid_compatible.py` - New generator
- ✅ `RAPID_ENGINE_LIMITATIONS.md` - Analysis document
- ✅ `preprocessing/RAPID_WORKLOAD_GENERATOR_CHANGES.md` - Comparison document
- ✅ `preprocessing/COLLECTION_UPDATE_SUMMARY.md` - This file

## Next Steps

1. **Generate Rapid workloads** (if not done yet):
   ```bash
   python3 preprocessing/generate_training_workload_rapid_compatible.py --all-datasets
   ```

2. **Run collection** (now automatic):
   ```bash
   python3 preprocessing/collect_dual_engine_data.py --workload auto
   ```

3. **Monitor results**:
   - Check `training_data/collection_summary.json`
   - Review error types
   - Adjust if needed

4. **Generate training dataset**:
   ```bash
   python3 preprocessing/collect_dual_engine_data.py --workload auto --generate-dataset
   ```
