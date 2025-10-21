# Hybrid Optimizer Training Pipeline

This directory contains the complete pipeline for training a hybrid optimizer that routes queries between MySQL row store and ShannonBase column engine based on query characteristics.

## Overview

The system uses machine learning (LightGBM) to predict whether a query will run faster on the row store or column store engine based on 140 features extracted from the query plan. The training process includes:

1. **Workload Generation**: Create diverse AP (Analytical) and TP (Transactional) queries
2. **Data Collection**: Execute queries on both engines and collect features + latencies
3. **Model Training**: Train LightGBM with automatic feature selection
4. **Integration**: Export model and selected features for C++ integration

## Quick Start

Run the complete pipeline with a single command:

```bash
./run_training_pipeline.sh
```

This will:
- Generate 1000 queries (40% TP, 60% AP)
- Collect dual-engine execution data
- Train models with feature selection (top 32 features)
- Save all artifacts for integration

## Components

### 1. Advanced Workload Generator (`generate_training_workload_advanced.py`)

Generates realistic AP and TP queries with proper characteristics:

#### AP Queries (Analytical/OLAP):
- **Complex Joins**: 3-10 table joins
- **Aggregations**: Multiple GROUP BY columns, HAVING clauses
- **Window Functions**: Partitioning and ordering
- **Subqueries**: Correlated and uncorrelated
- **CTEs**: Complex common table expressions
- **Large Result Sets**: Full table scans with complex filters

#### TP Queries (Transactional/OLTP):
- **Point Lookups**: Single row access by primary key
- **Simple Filters**: Quick lookups on indexed columns
- **Range Scans**: Small range queries with LIMIT
- **Simple Updates**: Single-row modification patterns

Usage:
```bash
# Generate for a single database (50/50 TP/AP by default)
python3 generate_training_workload_advanced.py \
    --database tpch_sf1 \
    --num-queries 1000 \
    --output ./training_workloads

# Generate for ALL available datasets (default if no --database specified)
python3 generate_training_workload_advanced.py \
    --all-datasets \
    --num-queries 1000 \
    --output ./training_workloads

# Generate with custom TP/AP ratio
python3 generate_training_workload_advanced.py \
    --database tpch_sf1 \
    --num-queries 1000 \
    --tp-ratio 0.3 \
    --output ./training_workloads
```

Options:
- `--database`: Choose from tpch_sf1, tpcds_sf1, airline, credit, financial, employee
- `--all-datasets`: Generate for all available datasets (default if --database not specified)
- `--tp-ratio`: Ratio of TP queries (0.0-1.0, default 0.5 = 50/50 balanced)
- `--num-queries`: Number of queries per dataset (default: 1000)
- `--seed`: Random seed for reproducibility

Output:
- `.sql`: SQL queries with metadata comments
- `.json`: Structured workload with query types and categories
- `_stats.json`: Workload statistics

### 2. Dual Engine Data Collector (`collect_dual_engine_data.py`)

Executes queries on both MySQL and ShannonBase, collecting:
- 140 features from optimizer trace
- Execution latencies (mean, median, p95, p99)
- Per-category performance metrics

Usage:
```bash
python3 collect_dual_engine_data.py \
    --workload ./training_workloads/training_workload_tpch_sf1.json \
    --output ./training_data \
    --generate-dataset
```

Features:
- Supports both SQL and JSON workload formats
- Tracks AP/TP categories for analysis
- Parallel execution with warmup runs
- Generates LightGBM-ready dataset

### 3. Model Training with Feature Selection (`train_lightgbm_model.py`)

Two-stage training process:
1. Train on all 140 features to determine importance
2. Select top N features and retrain for efficiency

Usage:
```bash
# With automatic feature selection (recommended)
python3 train_lightgbm_model.py \
    --data ./training_data/lightgbm_dataset.csv \
    --output ./models \
    --top-n 32

# Without feature selection (baseline)
python3 train_lightgbm_model.py \
    --data ./training_data/lightgbm_dataset.csv \
    --output ./models \
    --no-feature-selection

# With importance threshold
python3 train_lightgbm_model.py \
    --data ./training_data/lightgbm_dataset.csv \
    --output ./models \
    --importance-threshold 0.1
```

Output:
- `hybrid_optimizer_full.txt`: Model with all 140 features
- `hybrid_optimizer_selected.txt`: Model with selected features
- `top_feature_indices.txt`: Selected feature indices for C++ integration
- `all_features_importance.csv`: Complete feature importance analysis
- `feature_importance.png`: Visualization
- `training_metrics.json`: Performance comparison

### 4. C++ Integration

The trained model integrates with ShannonBase optimizer:

```cpp
// In sql/hybrid_opt/feature_extractor.h
#include "sql/hybrid_opt/feature_extractor.h"

// Load selected features at startup
std::vector<int> feature_indices = 
    FeatureExtractor::LoadFeatureIndices("/path/to/top_feature_indices.txt");

// During query optimization
std::vector<float> features;
if (FeatureExtractor::ExtractSelectedFeatures(join, feature_indices, 
                                              features, &thd->opt_trace)) {
    // Use LightGBM model to predict
    bool use_column_engine = predict_with_model(features);
    
    // Route to appropriate engine
    if (use_column_engine) {
        // Execute on ShannonBase column store
    } else {
        // Execute on MySQL row store
    }
}
```

## Performance Characteristics

### TP Query Performance
- **Row Store (MySQL)**: Generally faster for:
  - Single-row lookups
  - Small result sets
  - High selectivity filters
  - Simple predicates

- **Column Store (ShannonBase)**: May be slower due to:
  - Columnar storage overhead for point queries
  - Decompression costs for small data

### AP Query Performance
- **Row Store (MySQL)**: May struggle with:
  - Large table scans
  - Complex aggregations
  - Many-column GROUP BY

- **Column Store (ShannonBase)**: Excels at:
  - Full column scans
  - Aggregations on compressed data
  - Complex analytical operations
  - Better cache utilization for large datasets

## File Structure

```
preprocessing/
├── generate_training_workload_advanced.py  # AP/TP workload generator
├── collect_dual_engine_data.py            # Dual engine data collection
├── train_lightgbm_model.py                # Model training with feature selection
├── run_training_pipeline.sh               # End-to-end pipeline script
├── cross_db_benchmark/                    # Query generation utilities
│   ├── benchmark_tools/
│   └── datasets/
└── hybrid_optimizer_training/             # Output directory
    ├── workloads_*/                       # Generated queries
    ├── data_*/                            # Collected execution data
    └── models_*/                          # Trained models
```

## Requirements

- MySQL 8.0+ with optimizer trace support
- ShannonBase with column engine
- Python 3.8+ with packages:
  - mysql-connector-python
  - lightgbm
  - numpy
  - pandas
  - matplotlib
  - scikit-learn

## Advanced Usage

### Custom Workload Distributions

Adjust the TP/AP ratio based on your workload:

```bash
# Balanced workload (50% TP, 50% AP) - DEFAULT
python3 generate_training_workload_advanced.py \
    --all-datasets \
    --num-queries 1000

# OLTP-heavy workload (80% TP, 20% AP)
python3 generate_training_workload_advanced.py \
    --all-datasets \
    --tp-ratio 0.8 \
    --num-queries 1000

# OLAP-heavy workload (20% TP, 80% AP)
python3 generate_training_workload_advanced.py \
    --all-datasets \
    --tp-ratio 0.2 \
    --num-queries 1000

# Pure OLAP workload (100% AP)
python3 generate_training_workload_advanced.py \
    --all-datasets \
    --tp-ratio 0.0 \
    --num-queries 1000
```

### Feature Selection Strategies

```bash
# Select top 16 features for minimal overhead
python3 train_lightgbm_model.py \
    --data dataset.csv \
    --top-n 16

# Select features above importance threshold
python3 train_lightgbm_model.py \
    --data dataset.csv \
    --importance-threshold 0.05

# Use all features (no selection)
python3 train_lightgbm_model.py \
    --data dataset.csv \
    --no-feature-selection
```

### Cross-Validation

Evaluate model performance:

```bash
python3 train_lightgbm_model.py \
    --data dataset.csv \
    --cv-only
```

## Monitoring and Analysis

The pipeline generates comprehensive statistics:

1. **Workload Statistics**: Query type distribution, AP/TP breakdown
2. **Collection Summary**: Success rates, latency comparisons
3. **Model Metrics**: Accuracy, AUC, feature importance
4. **Per-Category Analysis**: TP vs AP performance characteristics

## Troubleshooting

### Connection Issues
- Ensure MySQL and ShannonBase are running
- Check port configurations (3306 for MySQL, 3307 for ShannonBase)
- Verify user credentials and permissions

### Feature Extraction
- Enable optimizer_trace: `SET optimizer_trace = 'enabled=on'`
- Enable feature extraction: `SET optimizer_trace_features = 1`
- Check trace output in information_schema.optimizer_trace

### Memory Issues
- Reduce batch size in data collection
- Use sampling for large workloads
- Increase optimizer_trace_max_mem_size if needed

## Future Enhancements

- [ ] Support for more query patterns (recursive CTEs, spatial queries)
- [ ] Online learning capabilities
- [ ] Cost-based routing fallback
- [ ] Multi-model ensemble for better accuracy
- [ ] Automatic workload characterization
- [ ] Integration with query optimizer hints

## References

- [LightGBM Documentation](https://lightgbm.readthedocs.io/)
- [MySQL Optimizer Trace](https://dev.mysql.com/doc/refman/8.0/en/optimizer-trace.html)
- [ShannonBase Column Engine](internal documentation)
