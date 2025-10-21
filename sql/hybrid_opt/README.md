# Hybrid Optimizer Feature Extraction and Training

This directory contains the implementation for extracting features from query plans and training LightGBM models for the hybrid row/column store optimizer.

## Overview

The hybrid optimizer uses machine learning to decide whether a query should be executed on the row store (MySQL) or column store (ShannonBase) engine. Features are extracted from the query plan during optimization and fed to a LightGBM model for routing decisions.

## Components

### 1. Feature Extraction (C++)

- **feature_extractor.h/cc**: Core feature extraction implementation
  - Extracts 140+ features from JOIN objects
  - Includes table statistics, join patterns, predicate types, aggregations, etc.
  - Integrates with optimizer_trace for debugging

### 2. Data Collection (Python)

- **collect_dual_engine_data.py**: Collects execution data from both engines
  - Runs queries on both MySQL and ShannonBase
  - Captures features from optimizer trace
  - Measures execution latencies
  - Generates training dataset

- **generate_training_workload.py**: Creates diverse SQL queries for training
  - Generates various query patterns (scans, joins, aggregations, etc.)
  - Configurable query distribution
  - Outputs SQL workload files

### 3. Model Training (Python)

- **train_lightgbm_model.py**: Trains the routing model
  - Binary classification (row vs column)
  - Feature importance analysis
  - Cross-validation
  - Model export for C++ integration

## Setup Instructions

### 1. Apply the Optimizer Patch

```bash
cd /home/wuy/DB/ShannonBase
patch -p1 < sql/hybrid_opt/optimizer_integration.patch
```

### 2. Build ShannonBase with Feature Extraction

```bash
cd /home/wuy/DB/ShannonBase
mkdir -p cmake_build && cd cmake_build
cmake .. -DWITH_DEBUG=1 -DWITH_BOOST=/path/to/boost
make -j$(nproc)
```

### 3. Set Up Python Environment

```bash
pip install numpy pandas lightgbm scikit-learn matplotlib mysql-connector-python
```

### 4. Configure Databases

Ensure both MySQL and ShannonBase are running with TPC-H/TPC-DS data loaded:

```bash
# Load TPC-H data
cd /home/wuy/DB/ShannonBase/preprocessing
./setup_tpc_benchmarks.sh

# Import CTU datasets (optional)
python import_ctu_datasets.py
```

## Training Pipeline

### Step 1: Generate Training Workload

```bash
cd /home/wuy/DB/ShannonBase/preprocessing
python generate_training_workload.py \
    --num-queries 5000 \
    --output training_workload
```

### Step 2: Collect Dual Engine Data

```bash
python collect_dual_engine_data.py \
    --workload training_workload.sql \
    --output ./training_data \
    --generate-dataset
```

This will:
- Execute each query on both engines
- Extract features from optimizer trace
- Measure execution times
- Generate `lightgbm_dataset.csv`

### Step 3: Train the Model with Feature Selection

```bash
# Train with automatic feature selection (recommended)
python train_lightgbm_model.py \
    --data ./training_data/lightgbm_dataset.csv \
    --output ./models \
    --top-n 32

# Or train without feature selection (baseline)
python train_lightgbm_model.py \
    --data ./training_data/lightgbm_dataset.csv \
    --output ./models \
    --no-feature-selection

# Or use importance threshold instead of fixed top-n
python train_lightgbm_model.py \
    --data ./training_data/lightgbm_dataset.csv \
    --output ./models \
    --importance-threshold 0.1
```

This produces:
- `hybrid_optimizer_full.txt`: Full model with all features
- `hybrid_optimizer_selected.txt`: Selected model with top features
- `top_feature_indices.txt`: Indices of selected features for C++ integration
- `all_features_importance.csv`: Feature importance scores
- `feature_importance.png`: Feature importance visualization
- `training_metrics.json`: Performance comparison

The training process works as follows:
1. **Train on all 140 features** to determine feature importance
2. **Select top N features** based on importance scores
3. **Retrain on selected features** for better efficiency
4. **Compare performance** between full and selected models

### Step 4: Integration

The trained model can be integrated into ShannonBase:

1. Copy the selected feature indices file:
```bash
cp ./models/top_feature_indices.txt /path/to/shannonbase/data/
```

2. Convert model to C++ code:
```bash
lightgbm convert_model ./models/hybrid_optimizer_selected.txt \
    --language cpp > hybrid_model_selected.cpp
```

3. Include in ShannonBase build:
```cpp
// In sql_optimizer.cc
#include "hybrid_opt/feature_extractor.h"
#include "hybrid_opt/hybrid_model_selected.cpp"

// Load selected feature indices at startup
std::vector<int> feature_indices = 
    FeatureExtractor::LoadFeatureIndices("/path/to/top_feature_indices.txt");

// During optimization
std::vector<float> selected_features;
if (FeatureExtractor::ExtractSelectedFeatures(join, feature_indices, 
                                              selected_features, &thd->opt_trace)) {
    bool use_column = predict_with_model(selected_features.data());
    // Route to appropriate engine
}
```

## Feature Categories

The feature extractor captures:

1. **Table Features** (0-8)
   - Table count, row statistics, access patterns

2. **Join Features** (9-15)
   - Join types, fanout, costs

3. **Predicate Features** (16-22)
   - Filter types, selectivity estimates

4. **Aggregation Features** (23-30)
   - GROUP BY, DISTINCT, window functions

5. **Ordering Features** (31-37)
   - ORDER BY, LIMIT, sort avoidance

6. **Cost Features** (38-42)
   - Read costs, evaluation costs

7. **Extended Features** (43-140)
   - Index usage, partitioning, histograms, etc.

## Monitoring and Debugging

### Enable Optimizer Trace

```sql
SET optimizer_trace='enabled=on';
SET optimizer_trace_features=1;

-- Run query
SELECT * FROM lineitem WHERE l_quantity > 30;

-- View trace with features
SELECT * FROM information_schema.OPTIMIZER_TRACE\G
```

### Feature Analysis

```python
# Analyze feature importance
import pandas as pd
import matplotlib.pyplot as plt

df = pd.read_csv('models/top_features.csv')
df.head(10).plot(x='feature', y='importance', kind='barh')
plt.show()
```

## Performance Tuning

### Data Collection Tips

1. **Warm up caches**: Run queries 3 times before measuring
2. **Use diverse workloads**: Mix OLTP and OLAP patterns
3. **Balance classes**: Ensure both engines win sometimes
4. **Validate results**: Check that both engines return same results

### Model Tuning

Adjust LightGBM parameters in `train_lightgbm_model.py`:

```python
params = {
    'num_leaves': 31,        # Increase for more complex patterns
    'learning_rate': 0.05,   # Decrease for more stable training
    'feature_fraction': 0.9, # Subsample features
    'bagging_fraction': 0.8, # Subsample data
}
```

### Feature Selection

Use top-32 features for production (based on importance):



## Troubleshooting

### Issue: Features not appearing in trace

Solution: Ensure optimizer_trace_features is enabled:
```sql
SET optimizer_trace_features=1;
```

### Issue: Connection errors to MySQL/ShannonBase

Solution: Check credentials in collection scripts:
```python
MYSQL_CONFIG = {
    'host': '127.0.0.1',
    'port': 3306,  # or 3307 for ShannonBase
    'user': 'root',
    'password': 'shannonbase'
}
```

### Issue: Model accuracy is low

Solutions:
1. Collect more diverse queries
2. Check feature extraction correctness
3. Perform hyperparameter tuning
4. Analyze misclassified queries

## References

- [ShannonBase Wiki - Practices](https://github.com/Shannon-Data/ShannonBase/wiki/Practices)
- [ShannonBase Wiki - Internals](https://github.com/Shannon-Data/ShannonBase/wiki/Internals-of-ShannonBase)
- [LightGBM Documentation](https://lightgbm.readthedocs.io/)
- [MySQL Optimizer Trace](https://dev.mysql.com/doc/internals/en/optimizer-tracing.html)
