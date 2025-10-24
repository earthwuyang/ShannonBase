# Rapid Workload Quick Start Guide

Complete workflow for generating and collecting Rapid-compatible training data.

## 🚀 Quick Start (3 Commands)

```bash
# 1. Generate Rapid-compatible workloads
cd /home/wuy/ShannonBase/preprocessing
python3 generate_training_workload_rapid_compatible.py --all-datasets

# 2. Run data collection (now uses Rapid workloads by default!)
cd /home/wuy/ShannonBase
python3 preprocessing/collect_dual_engine_data.py --workload auto

# 3. Check results
cat training_data/collection_summary.json | jq '.successful_shannon, .total_queries'
```

## 📊 What to Expect

### Before (Original Workloads)
- **Success Rate**: ~30%
- **Rapid Rejections**: ~70% 
- **Reason**: TP queries use indexes (not supported by Rapid)

### After (Rapid-Compatible Workloads)
- **Success Rate**: ~90-95%
- **Rapid Rejections**: ~5-10%
- **Reason**: Only edge cases or missing tables

## 📁 File Overview

### New Files Created
```
ShannonBase/
├── preprocessing/
│   ├── generate_training_workload_rapid_compatible.py  # NEW: Rapid generator
│   ├── collect_dual_engine_data.py                     # UPDATED: Uses Rapid by default
│   ├── RAPID_WORKLOAD_GENERATOR_CHANGES.md            # Documentation
│   └── COLLECTION_UPDATE_SUMMARY.md                    # Update details
├── RAPID_ENGINE_LIMITATIONS.md                         # Analysis document
└── RAPID_WORKLOAD_QUICK_START.md                       # This file
```

### Generated Workloads
```
training_workloads/
├── training_workload_rapid_tpch_sf1.sql               # ✅ Rapid-compatible
├── training_workload_rapid_tpch_sf1.json
├── training_workload_rapid_tpcds_sf1.sql              # ✅ Rapid-compatible
├── training_workload_rapid_Airline.sql                # ✅ Rapid-compatible
├── ...
├── training_workload_tpch_sf1.sql                     # ⚠️  Original (70% rejection)
└── training_workload_tpcds_sf1.sql                    # ⚠️  Original (70% rejection)
```

## 🔧 Detailed Workflow

### Step 1: Generate Workloads

```bash
cd /home/wuy/ShannonBase/preprocessing

# For all datasets (recommended)
python3 generate_training_workload_rapid_compatible.py --all-datasets --num-queries 10000

# For single database
python3 generate_training_workload_rapid_compatible.py --database tpch_sf1 --num-queries 5000

# Check generated files
ls -lh ../training_workloads/training_workload_rapid_*
```

**Output:**
```
Generating Rapid-compatible workloads for 9 datasets
[1/9] Processing: tpch_sf1
  ✓ Generated 10000 Rapid-compatible queries
  Query type distribution:
    ap_complex_join      : 3000 (30.0%)
    ap_aggregation       : 3000 (30.0%)
    ap_window            : 2000 (20.0%)
    ap_cte               : 1000 (10.0%)
    ap_full_scan_filter  : 1000 (10.0%)
...
```

### Step 2: Verify Tables Are Loaded in Rapid (Optional)

```bash
# Check which tables have secondary engine
mysql -h 127.0.0.1 -P 3307 -u root -D tpch_sf1 -e "
SELECT table_name 
FROM information_schema.tables 
WHERE table_schema='tpch_sf1' 
  AND engine='InnoDB'
" | while read table; do
  echo "Checking $table..."
  mysql -h 127.0.0.1 -P 3307 -u root -D tpch_sf1 -e "SHOW CREATE TABLE $table" | grep -i secondary
done

# If tables don't have SECONDARY_ENGINE, add it:
# mysql -h 127.0.0.1 -P 3307 -u root -D tpch_sf1 -e "
#   ALTER TABLE customer SECONDARY_ENGINE=RAPID;
#   ALTER TABLE customer SECONDARY_LOAD=ON;
# "
```

### Step 3: Collect Data

```bash
cd /home/wuy/ShannonBase

# Default: Process all Rapid-compatible workloads
python3 preprocessing/collect_dual_engine_data.py --workload auto

# Process specific database
python3 preprocessing/collect_dual_engine_data.py --workload auto --database tpch_sf1

# With dataset generation
python3 preprocessing/collect_dual_engine_data.py --workload auto --generate-dataset

# Check progress (in another terminal)
tail -f preprocessing/collect_dual_engine_data.log  # if logging to file
# OR just watch the output
```

**Expected Output:**
```
Auto-discovering workload files (pattern: training_workload_rapid_*.sql)...
Found 9 workload files:
  - training_workload_rapid_tpch_sf1.sql
  - training_workload_rapid_tpcds_sf1.sql
  - ...

Processing workload 1/9: training_workload_rapid_tpch_sf1.sql
Loaded 10000 queries from workload
Target database: tpch_sf1

Processing AP query q_0000 (1/10000) - Type: ap_complex_join
Processing AP query q_0001 (2/10000) - Type: ap_aggregation
...
✓ ~9000+ queries successful
⚠️ ~500-1000 queries with issues (timeout, table not found, etc.)
```

### Step 4: Analyze Results

```bash
# View summary
cat training_data/collection_summary.json | jq '.'

# Key metrics
jq '{
  total: .total_queries,
  mysql_success: .successful_mysql,
  rapid_success: .successful_shannon,
  rapid_success_rate: (.successful_shannon / .total_queries * 100 | tostring + "%"),
  errors: .errors
}' training_data/collection_summary.json

# Expected output:
# {
#   "total": 10000,
#   "mysql_success": 9800,
#   "rapid_success": 9200,
#   "rapid_success_rate": "92.0%",
#   "errors": {
#     "table_not_found": 50,
#     "rapid_not_supported": 100,
#     "timeout": 50,
#     "total_errors": 800
#   }
# }
```

## 🔄 Comparing Original vs Rapid-Compatible

### Run Both for Comparison

```bash
# 1. Collect with Rapid-compatible workloads
python3 preprocessing/collect_dual_engine_data.py \
  --workload auto \
  --workload-pattern 'training_workload_rapid_*.sql' \
  --output training_data_rapid

# 2. Collect with original workloads
python3 preprocessing/collect_dual_engine_data.py \
  --workload auto \
  --workload-pattern 'training_workload_*.sql' \
  --output training_data_original

# 3. Compare results
echo "Rapid-Compatible:"
jq '.successful_shannon, .total_queries' training_data_rapid/collection_summary.json

echo "Original:"
jq '.successful_shannon, .total_queries' training_data_original/collection_summary.json
```

## 🐛 Troubleshooting

### Issue: No workload files found

```bash
# Check if workloads exist
ls ../training_workloads/training_workload_rapid_*.sql

# If not, generate them
python3 preprocessing/generate_training_workload_rapid_compatible.py --all-datasets
```

### Issue: High rejection rate (>20%)

**Possible causes:**

1. **Tables not loaded into Rapid**
   ```bash
   # Check loaded tables
   mysql -h 127.0.0.1 -P 3307 -u root -e "SELECT * FROM information_schema.rapid_tables"
   
   # Load table
   mysql -h 127.0.0.1 -P 3307 -u root -D your_db -e "
     ALTER TABLE your_table SECONDARY_ENGINE=RAPID;
     ALTER TABLE your_table SECONDARY_LOAD=ON;
   "
   ```

2. **Using wrong workload files**
   ```bash
   # Make sure you're using rapid_* workloads
   python3 preprocessing/collect_dual_engine_data.py \
     --workload auto \
     --workload-pattern 'training_workload_rapid_*.sql'  # ✅ Correct
   ```

3. **Database schema mismatch**
   ```bash
   # Check workload targets correct database
   head -20 ../training_workloads/training_workload_rapid_tpch_sf1.sql
   # Should see: -- Database: tpch_sf1
   
   # Verify database exists
   mysql -h 127.0.0.1 -P 3307 -u root -e "SHOW DATABASES" | grep tpch_sf1
   ```

### Issue: Query timeouts

```bash
# Queries timing out (>60 seconds)
# This is expected for very large joins

# Option 1: Increase timeout (already done in script)
# Edit collect_dual_engine_data.py:
# max_execution_time = 120000  # 2 minutes

# Option 2: Reduce query complexity
python3 preprocessing/generate_training_workload_rapid_compatible.py \
  --database tpch_sf1 \
  --num-queries 5000  # Fewer queries
```

## 📈 Success Metrics

### Good Results (Rapid-Compatible Workloads)
```
✅ Rapid success rate: 90-95%
✅ MySQL success rate: 95-98%
✅ Most errors: timeout or table_not_found
✅ Few "rapid_not_supported" errors
```

### Poor Results (Original Workloads)
```
❌ Rapid success rate: 20-30%
❌ Many "rapid_not_supported" errors
❌ High rejection on TP queries
⚠️  Wasted collection time
```

## 🎯 Next Steps After Collection

### 1. Generate Training Dataset
```bash
python3 preprocessing/collect_dual_engine_data.py --workload auto --generate-dataset

# Check output
ls -lh training_data/lightgbm_dataset.csv
```

### 2. Train Model
```bash
# Example using LightGBM
python3 ml/train_hybrid_optimizer.py \
  --data training_data/lightgbm_dataset.csv \
  --output models/hybrid_optimizer_v1.model
```

### 3. Evaluate Model
```bash
python3 ml/evaluate_model.py \
  --model models/hybrid_optimizer_v1.model \
  --test-data training_data/lightgbm_dataset.csv
```

## 📚 Documentation Files

- **`RAPID_ENGINE_LIMITATIONS.md`** - Why queries are rejected
- **`RAPID_WORKLOAD_GENERATOR_CHANGES.md`** - Generator differences
- **`COLLECTION_UPDATE_SUMMARY.md`** - Collection script changes
- **`RAPID_WORKLOAD_QUICK_START.md`** - This file

## ✅ Checklist

Before starting:
- [ ] ShannonBase is running on port 3307
- [ ] Databases exist (tpch_sf1, tpcds_sf1, etc.)
- [ ] Tables have data loaded
- [ ] Python dependencies installed (mysql-connector-python, numpy)

Generate workloads:
- [ ] Run `generate_training_workload_rapid_compatible.py`
- [ ] Verify output files in `training_workloads/`
- [ ] Check workload statistics JSON files

Collect data:
- [ ] Run `collect_dual_engine_data.py --workload auto`
- [ ] Monitor progress (no Ctrl+C interruptions)
- [ ] Check `training_data/collection_summary.json`
- [ ] Verify success rate >90%

Post-processing:
- [ ] Generate LightGBM dataset (optional)
- [ ] Review error patterns
- [ ] Train/evaluate models

## 🤝 Support

If issues persist:
1. Check logs in `training_data/` directory
2. Review `collection_summary.json` for error details
3. Verify database connectivity and table schemas
4. Ensure Rapid engine is properly initialized
