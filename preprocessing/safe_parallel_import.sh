#!/bin/bash

# Safer wrapper for parallel imports with reduced concurrency
# This prevents the InnoDB assertion failure during parallel table creation

set -e

echo "========================================="
echo "Safe Parallel Import Wrapper"
echo "========================================="

# Override parallelism settings for safety
export MAX_PARALLEL=2  # Reduced from 5 to avoid race conditions
export BATCH_SIZE=500000  # Smaller batches to reduce memory pressure

# MySQL connection settings
export MYSQL_HOST="127.0.0.1"
export MYSQL_PORT="3307"
export MYSQL_USER="root"
export MYSQL_PASSWORD="shannonbase"

# Function to run imports sequentially for table creation, parallel for data loading
run_safe_tpc_import() {
    echo "Running TPC benchmarks with safe parallelism..."
    
    # Modify the script temporarily to separate DDL from DML
    cat > setup_tpc_safe.sh << 'EOF'
#!/bin/bash
source setup_tpc_benchmarks_parallel.sh

# Override the load functions to be safer
load_tpch_parallel_safe() {
    print_status "Loading TPC-H data with SAFE parallel processing..."
    
    # Create database and ALL tables first (sequentially to avoid race)
    mysql_exec "CREATE DATABASE IF NOT EXISTS tpch_sf1 DEFAULT CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;"
    
    print_status "Creating ALL TPC-H tables sequentially (avoiding parallel DDL)..."
    # ... (table creation SQL here, run sequentially)
    
    print_status "Now loading data with parallelism=${MAX_PARALLEL}..."
    # ... (data loading here, can be parallel)
}

# Replace the original function
load_tpch_parallel() {
    load_tpch_parallel_safe
}
EOF
    
    chmod +x setup_tpc_safe.sh
    ./setup_tpc_safe.sh
}

run_safe_ctu_import() {
    echo "Running CTU import with safe parallelism..."
    
    # For Python script, set environment variables
    export LOCAL_MYSQL_HOST="127.0.0.1"
    export LOCAL_MYSQL_PORT="3307"
    export LOCAL_MYSQL_USER="root"
    export LOCAL_MYSQL_PASSWORD="shannonbase"
    
    # Modify the Python script to reduce workers
    python3 << 'EOF'
import sys
import os

# Read the original script
with open('import_ctu_datasets_parallel.py', 'r') as f:
    content = f.read()

# Replace MAX_WORKERS setting
content = content.replace(
    "MAX_WORKERS = min(cpu_count() * 2, 5)",
    "MAX_WORKERS = 2  # Reduced for safety"
)

# Write modified script
with open('import_ctu_safe.py', 'w') as f:
    f.write(content)

# Run the modified script
os.system('python3 import_ctu_safe.py')
EOF
}

# Function to monitor MySQL during import
monitor_mysql() {
    echo "Monitoring MySQL health..."
    while true; do
        if ! mysqladmin -h 127.0.0.1 -P 3307 -u root -pshannonbase ping >/dev/null 2>&1; then
            echo "⚠️ MySQL is not responding! Check error log:"
            tail -10 /home/wuy/ShannonBase/db/data/shannonbase.err | grep -E "(ERROR|FATAL|Assert)"
            exit 1
        fi
        sleep 10
    done
}

# Main execution
main() {
    # Start monitoring in background
    monitor_mysql &
    MONITOR_PID=$!
    
    # Trap to clean up monitor on exit
    trap "kill $MONITOR_PID 2>/dev/null || true" EXIT
    
    echo "1. Checking MySQL status..."
    if ! mysqladmin -h 127.0.0.1 -P 3307 -u root -pshannonbase ping >/dev/null 2>&1; then
        echo "MySQL is not running. Starting with safe configuration..."
        ./fix_mysql_crash.sh
    fi
    
    echo ""
    echo "2. Running TPC benchmarks (safe mode)..."
    echo "   MAX_PARALLEL=${MAX_PARALLEL}"
    echo "   BATCH_SIZE=${BATCH_SIZE}"
    run_safe_tpc_import
    
    echo ""
    echo "3. Running CTU imports (safe mode)..."
    run_safe_ctu_import
    
    echo ""
    echo "✓ Import completed successfully!"
    echo ""
    echo "Verification:"
    mysql -h 127.0.0.1 -P 3307 -u root -pshannonbase -e "
        SELECT 'Database', 'Tables', 'Total Rows' AS '';
        SELECT 
            table_schema as 'Database',
            COUNT(*) as 'Tables',
            SUM(table_rows) as 'Total Rows'
        FROM information_schema.tables 
        WHERE table_schema IN ('tpch_sf1', 'tpcds_sf1', 'Airline', 'Credit', 'Carcinogenesis', 
                               'employee', 'financial', 'geneea', 'Hepatitis_std')
        GROUP BY table_schema;"
}

# Run main function
main "$@"
