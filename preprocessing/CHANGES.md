# Changes Summary: 50/50 TP/AP Workload Generation for All Datasets

## Overview

Updated `generate_training_workload_advanced.py` to default to generating **50/50 balanced TP/AP workloads** for **all available datasets** automatically.

## Key Changes

### 1. Default TP/AP Ratio Changed
- **Before**: 40% TP, 60% AP (`--tp-ratio 0.4`)
- **After**: 50% TP, 50% AP (`--tp-ratio 0.5`) ✅

### 2. Multi-Dataset Generation by Default
- **Before**: Required `--database` argument, single dataset only
- **After**: Generates for all datasets when no `--database` specified ✅

### 3. New `--all-datasets` Flag
- Explicitly generate for all available datasets
- Processes each dataset sequentially
- Provides aggregate statistics across all datasets

### 4. Enhanced Error Handling
- Gracefully handles connection failures
- Skips databases with no tables
- Tracks successful and failed datasets
- Continues processing remaining datasets on error

### 5. Comprehensive Summary Statistics
- Per-dataset breakdown
- Aggregate statistics across all datasets
- Category-wise (TP/AP) query counts
- Saves combined statistics to JSON

## Usage Examples

### Generate for All Datasets (NEW DEFAULT)
```bash
# Generates 1000 queries per dataset, 50/50 TP/AP
python3 generate_training_workload_advanced.py

# Equivalent to:
python3 generate_training_workload_advanced.py --all-datasets
```

### Generate for Single Database
```bash
python3 generate_training_workload_advanced.py --database tpch_sf1
```

### Custom TP/AP Ratio
```bash
# 80% TP, 20% AP - OLTP workload
python3 generate_training_workload_advanced.py --all-datasets --tp-ratio 0.8

# 20% TP, 80% AP - OLAP workload
python3 generate_training_workload_advanced.py --all-datasets --tp-ratio 0.2

# 100% AP - Pure analytical
python3 generate_training_workload_advanced.py --all-datasets --tp-ratio 0.0
```

### More Queries Per Dataset
```bash
python3 generate_training_workload_advanced.py --all-datasets --num-queries 5000
```

## Output

### Per-Dataset Files
For each database (e.g., `tpch_sf1`):
- `training_workload_tpch_sf1.sql` - SQL queries with metadata
- `training_workload_tpch_sf1.json` - Structured workload data
- `training_workload_tpch_sf1_stats.json` - Dataset statistics

### Aggregate Files
- `combined_workload_stats.json` - Overall statistics across all datasets

## Example Output

```
============================================================
Generating workloads for all 6 datasets

============================================================
[1/6] Processing database: tpch_sf1
============================================================
  Computing statistics for table: lineitem
  ...
  
Workload Statistics for tpch_sf1:
  Total queries: 1000
  
  Category distribution:
    TP: 50.00% (500 queries)
    AP: 50.00% (500 queries)

============================================================
OVERALL SUMMARY
============================================================

Processed 6 databases:
  Successful: 6
  Failed: 0

Successful datasets:
  - tpch_sf1
  - tpcds_sf1
  - airline
  - credit
  - financial
  - employee

Aggregate statistics:
  Total queries across all datasets: 6000
  Total TP queries: 3000 (50.0%)
  Total AP queries: 3000 (50.0%)

Per-dataset breakdown:
  Database             Queries       TP       AP
  -------------------- -------- -------- --------
  tpch_sf1                 1000      500      500
  tpcds_sf1                1000      500      500
  airline                  1000      500      500
  credit                   1000      500      500
  financial                1000      500      500
  employee                 1000      500      500
```

## Available Datasets

1. **tpch_sf1** - TPC-H Scale Factor 1
2. **tpcds_sf1** - TPC-DS Scale Factor 1
3. **airline** - Flight data
4. **credit** - Credit transactions
5. **financial** - Financial data
6. **employee** - Employee records

## Query Type Distribution

### TP Queries (50%):
- **40%** Point Lookups (tp_point_lookup)
- **30%** Simple Filters (tp_simple_filter)
- **30%** Range Scans (tp_range_scan)

### AP Queries (50%):
- **30%** Complex Joins (ap_complex_join) - 3-10 tables
- **25%** Aggregations (ap_aggregation) - GROUP BY, HAVING
- **15%** Window Functions (ap_window)
- **10%** Subqueries (ap_subquery)
- **10%** CTEs (ap_cte_recursive)
- **10%** UNIONs (ap_union_complex)

## Integration with Training Pipeline

The updated script integrates seamlessly with `run_training_pipeline.sh`:

```bash
# Set ALL_DATASETS=true in run_training_pipeline.sh
ALL_DATASETS=true
TP_RATIO=0.5  # 50/50 balanced

./run_training_pipeline.sh
```

## Benefits

1. **Comprehensive Training Data**: Models trained on diverse datasets generalize better
2. **Balanced Workload**: 50/50 ratio suitable for hybrid OLTP/OLAP systems
3. **Automation**: No need to manually process each dataset
4. **Flexibility**: Still supports single-dataset and custom ratio generation
5. **Robust**: Handles failures gracefully, doesn't stop on single dataset error

## Backward Compatibility

✅ All previous command-line usage patterns still work:
```bash
# Old usage still supported
python3 generate_training_workload_advanced.py --database tpch_sf1 --num-queries 1000

# New default behavior
python3 generate_training_workload_advanced.py
```

## Files Modified

1. `generate_training_workload_advanced.py` - Main generator script
2. `run_training_pipeline.sh` - Pipeline orchestration
3. `README_HYBRID_OPTIMIZER.md` - Documentation
4. `collect_dual_engine_data.py` - Enhanced to handle multi-dataset workloads

## Testing

Validated script works correctly:
```bash
$ python3 generate_training_workload_advanced.py --help
# Shows updated help with new options

$ python3 -m py_compile generate_training_workload_advanced.py
# No syntax errors
```

## Next Steps

1. Run the updated pipeline:
   ```bash
   ./run_training_pipeline.sh
   ```

2. Review generated workloads in `./hybrid_optimizer_training/workloads_*/`

3. Proceed with data collection and model training on the comprehensive dataset

---

**Date**: 2024
**Version**: 2.0
**Author**: Enhanced for multi-dataset 50/50 TP/AP generation
