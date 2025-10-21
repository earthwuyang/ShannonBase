#!/bin/bash
# End-to-end training pipeline for hybrid optimizer with AP/TP workloads

set -e

# Configuration
ALL_DATASETS=false  # Set to true to process all datasets
DATABASE="tpch_sf1"  # Used only if ALL_DATASETS=false
NUM_QUERIES=1000
TP_RATIO=0.5  # 50% TP, 50% AP (balanced workload)
OUTPUT_BASE="./hybrid_optimizer_training"
DATE_SUFFIX=$(date +%Y%m%d_%H%M%S)

echo "==========================================="
echo "Hybrid Optimizer Training Pipeline"
echo "==========================================="
if [ "$ALL_DATASETS" = true ]; then
    echo "Mode: Generate for ALL available datasets"
else
    echo "Database: $DATABASE"
fi
echo "Queries per dataset: $NUM_QUERIES"
echo "TP/AP Ratio: ${TP_RATIO} (50/50 balanced)"
echo ""

# Create output directory
mkdir -p "$OUTPUT_BASE"

# Step 1: Generate advanced workload with AP and TP queries
echo "[1/4] Generating AP/TP workload..."
WORKLOAD_DIR="$OUTPUT_BASE/workloads_$DATE_SUFFIX"

if [ "$ALL_DATASETS" = true ]; then
    python3 generate_training_workload_advanced.py \
        --all-datasets \
        --num-queries "$NUM_QUERIES" \
        --tp-ratio "$TP_RATIO" \
        --output "$WORKLOAD_DIR" \
        --seed 42
else
    python3 generate_training_workload_advanced.py \
        --database "$DATABASE" \
        --num-queries "$NUM_QUERIES" \
        --tp-ratio "$TP_RATIO" \
        --output "$WORKLOAD_DIR" \
        --seed 42
fi

# Find generated workload files
WORKLOAD_SQL=$(ls "$WORKLOAD_DIR"/training_workload_*.sql | head -1)
WORKLOAD_JSON=$(ls "$WORKLOAD_DIR"/training_workload_*.json | head -1)

echo "  Generated workload: $WORKLOAD_SQL"
echo ""

# Step 2: Collect dual engine execution data
echo "[2/4] Collecting dual engine data..."
DATA_DIR="$OUTPUT_BASE/data_$DATE_SUFFIX"
python3 collect_dual_engine_data.py \
    --workload "$WORKLOAD_JSON" \
    --output "$DATA_DIR" \
    --generate-dataset

echo "  Data collected in: $DATA_DIR"
echo ""

# Step 3: Train LightGBM models with feature selection
echo "[3/4] Training models with feature selection..."
MODEL_DIR="$OUTPUT_BASE/models_$DATE_SUFFIX"
python3 train_lightgbm_model.py \
    --data "$DATA_DIR/lightgbm_dataset.csv" \
    --output "$MODEL_DIR" \
    --top-n 32

echo "  Models saved in: $MODEL_DIR"
echo ""

# Step 4: Display results summary
echo "[4/4] Training Complete!"
echo ""
echo "Summary:"
echo "--------"

# Display workload statistics
if [ -f "$WORKLOAD_DIR"/training_workload_*_stats.json ]; then
    echo "Workload Statistics:"
    python3 -c "
import json
with open('$WORKLOAD_DIR/training_workload_${DATABASE}_stats.json') as f:
    stats = json.load(f)
    print(f\"  Total queries: {stats['total_queries']}\")
    if 'category_percentages' in stats:
        for cat, pct in stats['category_percentages'].items():
            print(f\"    {cat}: {pct:.1f}%\")
"
fi

# Display collection summary
if [ -f "$DATA_DIR/collection_summary.json" ]; then
    echo ""
    echo "Collection Summary:"
    python3 -c "
import json
with open('$DATA_DIR/collection_summary.json') as f:
    summary = json.load(f)
    print(f\"  Successful MySQL: {summary.get('successful_mysql', 0)}\")
    print(f\"  Successful ShannonBase: {summary.get('successful_shannon', 0)}\")
    if 'mysql_TP_latency' in summary:
        print(f\"  TP Queries:\")
        print(f\"    MySQL mean: {summary['mysql_TP_latency']['mean']:.2f}ms\")
        print(f\"    Shannon mean: {summary['shannon_TP_latency']['mean']:.2f}ms\")
    if 'mysql_AP_latency' in summary:
        print(f\"  AP Queries:\")
        print(f\"    MySQL mean: {summary['mysql_AP_latency']['mean']:.2f}ms\")
        print(f\"    Shannon mean: {summary['shannon_AP_latency']['mean']:.2f}ms\")
"
fi

# Display model performance
if [ -f "$MODEL_DIR/training_metrics.json" ]; then
    echo ""
    echo "Model Performance:"
    python3 -c "
import json
with open('$MODEL_DIR/training_metrics.json') as f:
    metrics = json.load(f)
    if 'selected_model' in metrics:
        print(f\"  Selected Model ({metrics['selected_model'].get('num_features', 'N/A')} features):\")
        print(f\"    Accuracy: {metrics['selected_model'].get('accuracy', 0):.3f}\")
        print(f\"    AUC: {metrics['selected_model'].get('auc', 0):.3f}\")
    if 'full_model' in metrics:
        print(f\"  Full Model (140 features):\")
        print(f\"    Accuracy: {metrics['full_model'].get('accuracy', 0):.3f}\")
        print(f\"    AUC: {metrics['full_model'].get('auc', 0):.3f}\")
"
fi

echo ""
echo "==========================================="
echo "Pipeline completed successfully!"
echo "Results saved in: $OUTPUT_BASE"
echo ""
echo "Next steps:"
echo "1. Review selected features: $MODEL_DIR/top_feature_indices.txt"
echo "2. Integrate model into ShannonBase using $MODEL_DIR/hybrid_optimizer_selected.txt"
echo "3. Copy feature indices to ShannonBase data directory"
echo "==========================================="
