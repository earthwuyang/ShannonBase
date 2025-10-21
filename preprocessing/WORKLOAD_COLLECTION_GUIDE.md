# Workload Collection Guide

This guide explains how to use the automated workload collection system for the hybrid optimizer.

## Overview

The system has two main components:
1. **Workload Generation** (`generate_training_workload_advanced.py`) - Creates diverse TP and AP queries
2. **Data Collection** (`collect_dual_engine_data.py`) - Executes queries on both engines and collects metrics

## Step 1: Generate Workloads

Generate training workloads for all available databases:

```bash
# Generate 1000 queries (500 TP, 500 AP) for all datasets
python3 generate_training_workload_advanced.py --all-datasets --num-queries 1000

# Generate for specific database
python3 generate_training_workload_advanced.py --database tpch_sf1 --num-queries 500

# Custom TP/AP ratio (80% TP, 20% AP)
python3 generate_training_workload_advanced.py --all-datasets --tp-ratio 0.8
```

**Output**: Workloads are saved to `../training_workloads/`:
- `training_workload_<database>.sql` - SQL queries with metadata
- `training_workload_<database>.json` - JSON format with full metadata
- `training_workload_<database>_stats.json` - Query distribution statistics

## Step 2: Collect Dual Engine Data

### Auto-Discovery Mode (Default)

The collector now automatically discovers and processes all generated workloads:

```bash
# Process ALL workloads automatically (RECOMMENDED)
python3 collect_dual_engine_data.py

# Same as above (explicit)
python3 collect_dual_engine_data.py --workload auto

# Auto-discover and generate LightGBM dataset
python3 collect_dual_engine_data.py --generate-dataset
```

### Filter by Database

Process workloads for specific databases:

```bash
# Only process TPC-H workload
python3 collect_dual_engine_data.py --database tpch_sf1

# Only process TPC-DS workload
python3 collect_dual_engine_data.py --database tpcds_sf1
```

### Process Specific Workload

You can still specify individual workload files:

```bash
# Single workload
python3 collect_dual_engine_data.py --workload ../training_workloads/training_workload_tpch_sf1.sql

# Multiple workloads with glob pattern
python3 collect_dual_engine_data.py --workload '../training_workloads/training_workload_tpc*.sql'
```

### Custom Output Directory

```bash
# Save to custom location
python3 collect_dual_engine_data.py --output ./my_training_data
```

## Output Structure

Data is collected into `./training_data/` (or custom directory):

```
training_data/
├── features/              # Feature vectors per query
│   ├── q_0000_features.csv
│   └── ...
├── latencies/            # Execution times
│   ├── q_0000_latency.csv
│   └── ...
├── queries/              # Original SQL queries
│   ├── q_0000.sql
│   └── ...
├── q_0000_results.json   # Combined results per query
├── collection_summary.json
└── lightgbm_dataset.csv  # Training dataset (if --generate-dataset)
```

## Complete Workflow Example

```bash
# 1. Generate workloads for all databases
cd /home/wuy/DB/ShannonBase/preprocessing
python3 generate_training_workload_advanced.py --all-datasets --num-queries 1000

# 2. Collect data from ALL workloads automatically
python3 collect_dual_engine_data.py --generate-dataset

# 3. Train the model
python3 train_lightgbm_model.py --data ./training_data/lightgbm_dataset.csv
```

## Selective Processing

Process only certain databases:

```bash
# Only benchmark databases
python3 collect_dual_engine_data.py --workload '../training_workloads/training_workload_tpc*.sql'

# Only a few specific databases
for db in tpch_sf1 tpcds_sf1 Airline; do
    python3 collect_dual_engine_data.py --database $db --output ./training_data_$db
done
```

## Performance Tips

1. **Start small**: Test with one database first
   ```bash
   python3 collect_dual_engine_data.py --database tpch_sf1
   ```

2. **Monitor progress**: The collector logs every 10 queries
   
3. **Parallel collection**: Process multiple databases separately (different output dirs)
   ```bash
   python3 collect_dual_engine_data.py --database tpch_sf1 --output ./data_tpch &
   python3 collect_dual_engine_data.py --database tpcds_sf1 --output ./data_tpcds &
   ```

## Troubleshooting

### No workloads found
```
Error: No workload files found. Please generate workloads first using:
  python3 generate_training_workload_advanced.py --all-datasets
```
**Solution**: Generate workloads first

### Connection errors
Check that both MySQL (port 3306) and ShannonBase (port 3307) are running:
```bash
mysql -h 127.0.0.1 -P 3306 -u root -pshannonbase -e "SELECT 1"
mysql -h 127.0.0.1 -P 3307 -u root -pshannonbase -e "SELECT 1"
```

### Database not found
Ensure the database exists in both engines:
```bash
mysql -h 127.0.0.1 -P 3307 -u root -pshannonbase -e "SHOW DATABASES LIKE 'tpch%'"
```

## Advanced Options

### Query Execution Settings

Edit `collect_dual_engine_data.py` to adjust:
- `warmup=3` - Number of warmup runs
- `runs=5` - Number of measured runs
- Optimizer trace settings

### Feature Collection

The collector extracts 60 optimizer features including:
- Table statistics (row counts, selectivity)
- Join characteristics (cardinality, type)
- Predicate information (complexity, types)
- Column statistics (min/max, nulls, distinct values)

## Summary

The automated workflow is now:

1. **Generate**: `python3 generate_training_workload_advanced.py --all-datasets`
2. **Collect**: `python3 collect_dual_engine_data.py` (auto-discovers all workloads)
3. **Train**: `python3 train_lightgbm_model.py --data ./training_data/lightgbm_dataset.csv`

No need to manually specify workload files - the system finds them automatically!
