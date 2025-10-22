#!/bin/bash

# Ultimate fix for SECONDARY_LOAD crashes
# Approach: Load tables into Rapid ONLY if they have no FK constraints

set -e

MYSQL_HOST="${MYSQL_HOST:-127.0.0.1}"
MYSQL_PORT="${MYSQL_PORT:-3307}"
MYSQL_USER="${MYSQL_USER:-root}"
MYSQL_PASSWORD="${MYSQL_PASSWORD:-shannonbase}"

export MYSQL_PWD="$MYSQL_PASSWORD"
MYSQL_CMD=(mysql -h "$MYSQL_HOST" -P "$MYSQL_PORT" -u "$MYSQL_USER")

echo "============================================"
echo "Fix SECONDARY_LOAD Crash - Smart Approach"
echo "============================================"
echo ""
echo "Strategy:"
echo "1. Drop and recreate databases completely clean"
echo "2. Disable FK checks globally"
echo "3. Load tables into Rapid ONLY if safe"
echo ""

# Function to safely load table into Rapid
safe_secondary_load() {
    local db="$1"
    local table="$2"
    
    # Check if table has any FK constraints
    local fk_count
    fk_count=$("${MYSQL_CMD[@]}" -N -e "
        SELECT COUNT(*) 
        FROM information_schema.key_column_usage 
        WHERE table_schema='$db' 
        AND table_name='$table' 
        AND referenced_table_name IS NOT NULL;
    " 2>/dev/null || echo "0")
    
    if [ "${fk_count:-0}" -gt 0 ]; then
        echo "⚠️  [$db.$table] Has $fk_count FK constraints - SKIPPING SECONDARY_LOAD"
        return 0
    fi
    
    echo "✓ [$db.$table] No FK constraints - loading into Rapid..."
    
    # Try to load with FK checks disabled
    if "${MYSQL_CMD[@]}" "$db" -e "
        SET SESSION FOREIGN_KEY_CHECKS=0;
        SET SESSION foreign_key_checks=0;
        ALTER TABLE \`$table\` SECONDARY_LOAD;
    " 2>/dev/null; then
        echo "✓ [$db.$table] Successfully loaded into Rapid"
        return 0
    else
        echo "✗ [$db.$table] Failed to load into Rapid (non-fatal)"
        return 1
    fi
}

# Export function
export -f safe_secondary_load
export MYSQL_HOST MYSQL_PORT MYSQL_USER

echo "Step 1: Clean up existing databases..."
"${MYSQL_CMD[@]}" -e "DROP DATABASE IF EXISTS tpch_sf1;" 2>/dev/null || true
"${MYSQL_CMD[@]}" -e "DROP DATABASE IF EXISTS tpcds_sf1;" 2>/dev/null || true

echo "✓ Databases dropped"
echo ""

echo "Step 2: Disable FK checks globally..."
"${MYSQL_CMD[@]}" -e "SET GLOBAL foreign_key_checks = 0;"
"${MYSQL_CMD[@]}" -e "SET SESSION foreign_key_checks = 0;"

echo "✓ FK checks disabled globally"
echo ""

echo "Step 3: Run setup script..."
echo "   The script will create tables without FK constraints"
echo "   SECONDARY_LOAD will be done selectively"
echo ""
echo "To proceed, run:"
echo "  export MAX_PARALLEL=2"
echo "  ./setup_tpc_benchmarks_parallel.sh"
echo ""
echo "After loading, use this function to safely load tables into Rapid:"
echo "  safe_secondary_load tpcds_sf1 call_center"
echo ""

trap 'unset MYSQL_PWD' EXIT
echo "============================================"
echo "Ready to proceed!"
echo "============================================"
