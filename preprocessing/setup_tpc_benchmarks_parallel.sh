#!/bin/bash

# Parallel TPC-H and TPC-DS Setup Script for MySQL with Duplicate Handling
# Features:
# - Parallel table loading using GNU parallel or background jobs
# - INSERT IGNORE for duplicate handling
# - Resume capability - skips already loaded tables
# - Progress tracking

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# Data scale (1 = 1GB)
SCALE=1

# Parallelization settings
MAX_PARALLEL=${MAX_PARALLEL:-5}  # Default to number of CPUs
BATCH_SIZE=${BATCH_SIZE:-1000000}       # Rows per split file for large tables

# MySQL configuration
MYSQL_HOST="${MYSQL_HOST:-127.0.0.1}"
MYSQL_PORT="${MYSQL_PORT:-3307}"
MYSQL_USER="${MYSQL_USER:-root}"
MYSQL_PASSWORD="${MYSQL_PASSWORD:-shannonbase}"

if [ -n "$MYSQL_PASSWORD" ]; then
    export MYSQL_PWD="$MYSQL_PASSWORD"
fi

MYSQL_BASE_CMD=(mysql --local-infile=1 -h "$MYSQL_HOST" -P "$MYSQL_PORT" -u "$MYSQL_USER" --default-character-set=utf8mb4)
MYSQLADMIN_CMD=(mysqladmin -h "$MYSQL_HOST" -P "$MYSQL_PORT" -u "$MYSQL_USER")

trap 'unset MYSQL_PWD' EXIT

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

print_status() {
    echo -e "${GREEN}[INFO]${NC} $1"
}

print_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

print_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

print_progress() {
    echo -e "${BLUE}[PROGRESS]${NC} $1"
}

mysql_exec() {
    "${MYSQL_BASE_CMD[@]}" -e "$1"
}

mysql_exec_db() {
    local db="$1"
    shift
    "${MYSQL_BASE_CMD[@]}" "$db" -e "$1"
}

mysql_stream_db() {
    local db="$1"
    shift
    "${MYSQL_BASE_CMD[@]}" "$db"
}

mysql_scalar() {
    local db="$1"
    shift
    "${MYSQL_BASE_CMD[@]}" "$db" -N -B -e "$1"
}

escape_path_for_mysql() {
    printf "%s" "$1" | sed "s/'/\\'/g"
}

# Load data with INSERT IGNORE (handles duplicates automatically)
load_data_file_ignore() {
    local db="$1"
    local table="$2"
    local file="$3"
    local escaped
    escaped=$(escape_path_for_mysql "$file")
    
    # Set SQL mode to allow empty strings to be converted to NULL/0
    # Remove STRICT_TRANS_TABLES and STRICT_ALL_TABLES to allow implicit conversions
    # Use REPLACE instead of INSERT IGNORE to handle duplicates by updating
    "${MYSQL_BASE_CMD[@]}" "$db" <<EOSQL
SET SESSION sql_mode = '';
LOAD DATA LOCAL INFILE '${escaped}' 
REPLACE INTO TABLE \`${table}\` 
FIELDS TERMINATED BY '|' 
LINES TERMINATED BY '\n';
EOSQL
}

table_exists() {
    local db="$1"
    local table="$2"
    local sql="SELECT COUNT(*) FROM information_schema.tables WHERE table_schema='${db}' AND table_name='${table}';"
    local count
    count=$(mysql_scalar information_schema "$sql")
    [ "${count:-0}" -gt 0 ]
}

table_has_rows() {
    local db="$1"
    local table="$2"
    if ! table_exists "$db" "$table"; then
        return 1
    fi
    local count
    count=$(mysql_scalar "$db" "SELECT COUNT(*) FROM \`${table}\` LIMIT 1;")
    [ "${count:-0}" -gt 0 ]
}

get_table_row_count() {
    local db="$1"
    local table="$2"
    mysql_scalar "$db" "SELECT COUNT(*) FROM \`${table}\`;" 2>/dev/null || echo "0"
}

database_exists() {
    local db="$1"
    local count
    count=$(mysql_scalar information_schema "SELECT COUNT(*) FROM information_schema.schemata WHERE schema_name='${db}';" 2>/dev/null || echo "0")
    [ "${count:-0}" -gt 0 ]
}

check_tpch_data_complete() {
    # Check if TPC-H database exists with expected data
    if ! database_exists tpch_sf1; then
        return 1
    fi
    
    # Expected approximate row counts for SF1 (Scale Factor 1 = 1GB)
    local expected_rows=(
        "region:5"
        "nation:25"
        "part:200000"
        "supplier:10000"
        "partsupp:800000"
        "customer:150000"
        "orders:1500000"
        "lineitem:6000000"  # Approximate, actual is ~6001215
    )
    
    local all_match=1
    for entry in "${expected_rows[@]}"; do
        IFS=':' read -r table min_rows <<< "$entry"
        if ! table_exists tpch_sf1 "$table"; then
            all_match=0
            break
        fi
        local actual_rows
        actual_rows=$(get_table_row_count tpch_sf1 "$table")
        # Allow some variance for lineitem (within 1% of 6M)
        if [ "$table" = "lineitem" ]; then
            if [ "${actual_rows:-0}" -lt 5900000 ]; then
                all_match=0
                break
            fi
        else
            if [ "${actual_rows:-0}" -lt "$min_rows" ]; then
                all_match=0
                break
            fi
        fi
    done
    
    return $((1 - all_match))
}

check_tpcds_data_complete() {
    # Check if TPC-DS database exists with all tables having data
    if ! database_exists tpcds_sf1; then
        return 1
    fi
    
    # List of all TPC-DS tables
    local tables=(call_center catalog_page catalog_returns catalog_sales customer customer_address 
                  customer_demographics date_dim dbgen_version household_demographics income_band 
                  inventory item promotion reason ship_mode store store_returns store_sales 
                  time_dim warehouse web_page web_returns web_sales web_site)
    
    local all_exist=1
    for table in "${tables[@]}"; do
        if ! table_exists tpcds_sf1 "$table"; then
            all_exist=0
            break
        fi
        # Check that table has at least some data (skip dbgen_version which may be empty)
        if [ "$table" != "dbgen_version" ]; then
            local row_count
            row_count=$(get_table_row_count tpcds_sf1 "$table")
            if [ "${row_count:-0}" -eq 0 ]; then
                all_exist=0
                break
            fi
        fi
    done
    
    return $((1 - all_exist))
}

check_mysql() {
    if ! "${MYSQLADMIN_CMD[@]}" ping >/dev/null 2>&1; then
        print_error "MySQL is not reachable"
        exit 1
    fi
    
    if mysql_exec "SET GLOBAL local_infile = 1" 2>/dev/null; then
        print_status "Enabled local_infile on MySQL server"
    else
        print_warning "Could not enable local_infile on server"
    fi
}

# Function to load a single table (used for parallel execution)
load_tpch_table() {
    local table="$1"
    local file="$2"
    
    # Check if already loaded
    if table_has_rows tpch_sf1 "$table"; then
        local count
        count=$(get_table_row_count tpch_sf1 "$table")
        print_warning "[$table] Already has $count rows, skipping"
        return 0
    fi
    
    print_progress "[$table] Loading..."
    
    if [ -f "$file" ]; then
        if load_data_file_ignore tpch_sf1 "$table" "$file"; then
            local count
            count=$(get_table_row_count tpch_sf1 "$table")
            print_status "[$table] ✓ Loaded $count rows"
            return 0
        else
            print_error "[$table] Failed to load"
            return 1
        fi
    else
        print_error "[$table] File not found: $file"
        return 1
    fi
}

# Export function for parallel execution
export -f load_tpch_table
export -f load_data_file_ignore
export -f table_has_rows
export -f table_exists
export -f get_table_row_count
export -f mysql_exec_db
export -f mysql_scalar
export -f escape_path_for_mysql
export -f print_status
export -f print_error
export -f print_warning
export -f print_progress

# TPC-H setup functions
setup_tpch() {
    print_status "Setting up TPC-H..."
    
    if [ ! -d "${SCRIPT_DIR}/tpch-dbgen" ]; then
        print_status "Cloning TPC-H repository..."
        git clone https://github.com/electrum/tpch-dbgen.git "${SCRIPT_DIR}/tpch-dbgen"
    fi
    
    cd "${SCRIPT_DIR}/tpch-dbgen"
    print_status "Compiling TPC-H dbgen..."
    make clean >/dev/null 2>&1 || true
    make -j"$(nproc)"
    
    if [ ! -f "lineitem.tbl" ]; then
        print_status "Generating ${SCALE}GB TPC-H data..."
        ./dbgen -vf -s ${SCALE}
        
        print_status "Cleaning data files..."
        # Fix permissions first (dbgen may create read-only files)
        chmod u+w *.tbl 2>/dev/null || true
        
        for file in *.tbl; do
            if [ -f "$file" ] && [ -w "$file" ]; then
                sed -i 's/|$//' "$file"
            else
                print_warning "Cannot write to $file, skipping cleanup"
            fi
        done
    fi
}

load_tpch_parallel() {
    print_status "Loading TPC-H data with parallel processing..."

    # Check if data already exists with correct row counts
    if check_tpch_data_complete; then
        print_status "✓ TPC-H data already exists with expected row counts, skipping data load..."
        mysql_stream_db tpch_sf1 <<'EOF'
SELECT 'TPC-H Existing Data Summary' AS info;
SELECT 'customer' AS table_name, COUNT(*) AS row_count FROM customer
UNION ALL SELECT 'lineitem', COUNT(*) FROM lineitem
UNION ALL SELECT 'nation', COUNT(*) FROM nation
UNION ALL SELECT 'orders', COUNT(*) FROM orders
UNION ALL SELECT 'part', COUNT(*) FROM part
UNION ALL SELECT 'partsupp', COUNT(*) FROM partsupp
UNION ALL SELECT 'region', COUNT(*) FROM region
UNION ALL SELECT 'supplier', COUNT(*) FROM supplier
ORDER BY table_name;
EOF
        # Jump directly to SECONDARY_LOAD step
        print_status "Proceeding to SECONDARY_LOAD step..."
        
        # Ensure SECONDARY_ENGINE is set on all tables
        print_status "Verifying SECONDARY_ENGINE configuration..."
        for table in nation region part supplier partsupp customer orders lineitem; do
            has_secondary=$(mysql_scalar tpch_sf1 "SELECT CREATE_OPTIONS FROM information_schema.tables WHERE table_schema='tpch_sf1' AND table_name='$table'" 2>/dev/null | grep -q "SECONDARY_ENGINE" && echo "1" || echo "0")
            
            if [ "$has_secondary" = "0" ]; then
                print_status "  Adding SECONDARY_ENGINE to $table..."
                mysql_exec_db tpch_sf1 "ALTER TABLE \`$table\` SECONDARY_ENGINE=Rapid;" || print_warning "Failed to add SECONDARY_ENGINE to $table"
            fi
        done
        
        # Continue to SECONDARY_LOAD at the end of function
    else
        # Data doesn't exist or is incomplete, proceed with full load
        print_status "TPC-H data not found or incomplete, proceeding with full data load..."
        
        # Drop database completely to ensure no FK metadata from previous runs
        print_status "Dropping existing tpch_sf1 database (if exists) to ensure clean state..."
        mysql_exec "DROP DATABASE IF EXISTS \`tpch_sf1\`;" || true
        
        # Create fresh database
        mysql_exec "CREATE DATABASE \`tpch_sf1\` DEFAULT CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;"
    
    # Disable foreign key checks globally
    mysql_exec "SET GLOBAL FOREIGN_KEY_CHECKS=0;" || true
    mysql_exec_db tpch_sf1 "SET FOREIGN_KEY_CHECKS=0;"
    
    # Create schema (reuse from original script - omitted for brevity, same as before)
    print_status "Creating TPC-H schema (clean database, no FK metadata)..."
    mysql_stream_db tpch_sf1 <<'EOF'
CREATE TABLE IF NOT EXISTS nation (
    n_nationkey INT NOT NULL,
    n_name CHAR(25) NOT NULL,
    n_regionkey INT NOT NULL,
    n_comment VARCHAR(152),
    PRIMARY KEY (n_nationkey)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

CREATE TABLE IF NOT EXISTS region (
    r_regionkey INT NOT NULL,
    r_name CHAR(25) NOT NULL,
    r_comment VARCHAR(152),
    PRIMARY KEY (r_regionkey)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

CREATE TABLE IF NOT EXISTS part (
    p_partkey INT NOT NULL,
    p_name VARCHAR(55) NOT NULL,
    p_mfgr CHAR(25) NOT NULL,
    p_brand CHAR(10) NOT NULL,
    p_type VARCHAR(25) NOT NULL,
    p_size INT NOT NULL,
    p_container CHAR(10) NOT NULL,
    p_retailprice DECIMAL(15,2) NOT NULL,
    p_comment VARCHAR(23) NOT NULL,
    PRIMARY KEY (p_partkey)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

CREATE TABLE IF NOT EXISTS supplier (
    s_suppkey INT NOT NULL,
    s_name CHAR(25) NOT NULL,
    s_address VARCHAR(40) NOT NULL,
    s_nationkey INT NOT NULL,
    s_phone CHAR(15) NOT NULL,
    s_acctbal DECIMAL(15,2) NOT NULL,
    s_comment VARCHAR(101) NOT NULL,
    PRIMARY KEY (s_suppkey),
    KEY idx_supplier_nation (s_nationkey)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

CREATE TABLE IF NOT EXISTS partsupp (
    ps_partkey INT NOT NULL,
    ps_suppkey INT NOT NULL,
    ps_availqty INT NOT NULL,
    ps_supplycost DECIMAL(15,2) NOT NULL,
    ps_comment VARCHAR(199) NOT NULL,
    PRIMARY KEY (ps_partkey, ps_suppkey)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

CREATE TABLE IF NOT EXISTS customer (
    c_custkey INT NOT NULL,
    c_name VARCHAR(25) NOT NULL,
    c_address VARCHAR(40) NOT NULL,
    c_nationkey INT NOT NULL,
    c_phone CHAR(15) NOT NULL,
    c_acctbal DECIMAL(15,2) NOT NULL,
    c_mktsegment CHAR(10) NOT NULL,
    c_comment VARCHAR(117) NOT NULL,
    PRIMARY KEY (c_custkey),
    KEY idx_customer_nation (c_nationkey)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

CREATE TABLE IF NOT EXISTS orders (
    o_orderkey INT NOT NULL,
    o_custkey INT NOT NULL,
    o_orderstatus CHAR(1) NOT NULL,
    o_totalprice DECIMAL(15,2) NOT NULL,
    o_orderdate DATE NOT NULL,
    o_orderpriority CHAR(15) NOT NULL,
    o_clerk CHAR(15) NOT NULL,
    o_shippriority INT NOT NULL,
    o_comment VARCHAR(79) NOT NULL,
    PRIMARY KEY (o_orderkey),
    KEY idx_orders_cust (o_custkey),
    KEY idx_orders_date (o_orderdate)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

CREATE TABLE IF NOT EXISTS lineitem (
    l_orderkey INT NOT NULL,
    l_partkey INT NOT NULL,
    l_suppkey INT NOT NULL,
    l_linenumber INT NOT NULL,
    l_quantity DECIMAL(15,2) NOT NULL,
    l_extendedprice DECIMAL(15,2) NOT NULL,
    l_discount DECIMAL(15,2) NOT NULL,
    l_tax DECIMAL(15,2) NOT NULL,
    l_returnflag CHAR(1) NOT NULL,
    l_linestatus CHAR(1) NOT NULL,
    l_shipdate DATE NOT NULL,
    l_commitdate DATE NOT NULL,
    l_receiptdate DATE NOT NULL,
    l_shipinstruct CHAR(25) NOT NULL,
    l_shipmode CHAR(10) NOT NULL,
    l_comment VARCHAR(44) NOT NULL,
    KEY idx_lineitem_order (l_orderkey),
    KEY idx_lineitem_part_supp (l_partkey, l_suppkey),
    KEY idx_lineitem_shipdate (l_shipdate)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

-- Add indexes that weren't created in table definitions
-- Check if index exists before creating to avoid duplicate key error
SET @index_exists = (
    SELECT COUNT(*) 
    FROM information_schema.statistics 
    WHERE table_schema = 'tpch_sf1' 
    AND table_name = 'nation' 
    AND index_name = 'idx_nation_region'
);

SET @sql = IF(@index_exists = 0, 
    'CREATE INDEX idx_nation_region ON nation(n_regionkey)', 
    'SELECT "Index idx_nation_region already exists, skipping" AS message'
);

PREPARE stmt FROM @sql;
EXECUTE stmt;
DEALLOCATE PREPARE stmt;

-- Note: idx_supplier_nation is already defined in supplier CREATE TABLE, no need to add it again
EOF

    # Add SECONDARY_ENGINE to tables if not already set (outside of the main SQL block to avoid errors)
    print_status "Configuring SECONDARY_ENGINE for TPC-H tables..."
    for table in nation region part supplier partsupp customer orders lineitem; do
        # Check if table already has SECONDARY_ENGINE
        has_secondary=$(mysql_scalar tpch_sf1 "SELECT CREATE_OPTIONS FROM information_schema.tables WHERE table_schema='tpch_sf1' AND table_name='$table'" 2>/dev/null | grep -q "SECONDARY_ENGINE" && echo "1" || echo "0")
        
        if [ "$has_secondary" = "0" ]; then
            print_status "  Adding SECONDARY_ENGINE to $table..."
            mysql_exec_db tpch_sf1 "ALTER TABLE \`$table\` SECONDARY_ENGINE=Rapid;" || print_warning "Failed to add SECONDARY_ENGINE to $table"
        else
            print_status "  $table already has SECONDARY_ENGINE, skipping"
        fi
    done
    
    cd "${SCRIPT_DIR}/tpch-dbgen"
    
    # Check if already loaded
    if table_has_rows tpch_sf1 lineitem; then
        local count
        count=$(get_table_row_count tpch_sf1 lineitem)
        print_warning "TPC-H data already loaded (lineitem has $count rows), skipping"
        return
    fi
    
    print_status "Loading small tables sequentially..."
    load_tpch_table region "${SCRIPT_DIR}/tpch-dbgen/region.tbl"
    load_tpch_table nation "${SCRIPT_DIR}/tpch-dbgen/nation.tbl"
    
    print_status "Loading large tables in parallel (${MAX_PARALLEL} workers)..."
    
    # Prepare table list for parallel loading
    declare -a LARGE_TABLES=(
        "part:${SCRIPT_DIR}/tpch-dbgen/part.tbl"
        "supplier:${SCRIPT_DIR}/tpch-dbgen/supplier.tbl"
        "partsupp:${SCRIPT_DIR}/tpch-dbgen/partsupp.tbl"
        "customer:${SCRIPT_DIR}/tpch-dbgen/customer.tbl"
        "orders:${SCRIPT_DIR}/tpch-dbgen/orders.tbl"
    )
    
    # Check if GNU parallel is available
    if command -v parallel >/dev/null 2>&1; then
        print_status "Using GNU parallel for faster loading..."
        printf "%s\n" "${LARGE_TABLES[@]}" | \
            parallel -j "$MAX_PARALLEL" --colsep ':' \
            load_tpch_table {1} {2}
    else
        print_status "GNU parallel not found, using background jobs..."
        for entry in "${LARGE_TABLES[@]}"; do
            IFS=':' read -r table file <<< "$entry"
            load_tpch_table "$table" "$file" &
            
            # Limit concurrent jobs
            while [ "$(jobs -r | wc -l)" -ge "$MAX_PARALLEL" ]; do
                sleep 1
            done
        done
        wait
    fi
    
    # Handle lineitem separately (largest table)
    print_status "Loading lineitem table (largest, may take time)..."
    if [ -f "lineitem.tbl" ]; then
        LINE_COUNT=$(wc -l < lineitem.tbl)
        if [ "$LINE_COUNT" -gt "$BATCH_SIZE" ]; then
            print_status "Splitting lineitem for parallel loading..."
            split -l "$BATCH_SIZE" lineitem.tbl lineitem_part_ --additional-suffix=.tbl
            
            if command -v parallel >/dev/null 2>&1; then
                find . -name "lineitem_part_*.tbl" -print0 | \
                    parallel -0 -j "$MAX_PARALLEL" \
                    load_tpch_table lineitem {}
            else
                for file in lineitem_part_*.tbl; do
                    load_tpch_table lineitem "${SCRIPT_DIR}/tpch-dbgen/${file}" &
                    while [ "$(jobs -r | wc -l)" -ge "$MAX_PARALLEL" ]; do
                        sleep 1
                    done
                done
                wait
            fi
            
            rm -f lineitem_part_*.tbl
        else
            load_tpch_table lineitem "${SCRIPT_DIR}/tpch-dbgen/lineitem.tbl"
        fi
    fi
    
        print_status "Verifying TPC-H data load..."
        mysql_stream_db tpch_sf1 <<'EOF'
SELECT 'TPC-H Data Load Summary' AS info;
SELECT 'customer' AS table_name, COUNT(*) AS row_count FROM customer
UNION ALL SELECT 'lineitem', COUNT(*) FROM lineitem
UNION ALL SELECT 'nation', COUNT(*) FROM nation
UNION ALL SELECT 'orders', COUNT(*) FROM orders
UNION ALL SELECT 'part', COUNT(*) FROM part
UNION ALL SELECT 'partsupp', COUNT(*) FROM partsupp
UNION ALL SELECT 'region', COUNT(*) FROM region
UNION ALL SELECT 'supplier', COUNT(*) FROM supplier
ORDER BY table_name;
EOF
    fi  # End of data load check
    
    # SECONDARY_LOAD applies whether data was loaded or already existed
    print_status "Loading TPC-H data into Rapid engine (with error handling and retry)..."
    # Disable FK checks before SECONDARY_LOAD
    mysql_exec_db tpch_sf1 "SET SESSION FOREIGN_KEY_CHECKS=0;"
    mysql_exec_db tpch_sf1 "SET GLOBAL FOREIGN_KEY_CHECKS=0;" 2>/dev/null || true
    
    # Load all tables into the secondary engine (Rapid) with individual error handling and retry
    RAPID_LOADED=0
    RAPID_FAILED=0
    declare -a FAILED_TABLES
    MAX_RETRIES=2
    
    for table in customer lineitem nation orders part partsupp region supplier; do
        print_status "Loading $table into Rapid..."
        
        SUCCESS=0
        for attempt in $(seq 1 $MAX_RETRIES); do
            # Try to load with timeout to detect crashes - capture error
            ERROR_MSG=$(timeout 120 mysql_exec_db tpch_sf1 "SET SESSION FOREIGN_KEY_CHECKS=0; ALTER TABLE \`$table\` SECONDARY_LOAD;" 2>&1)
            if [ $? -eq 0 ]; then
                print_status "  ✓ $table loaded into Rapid (attempt $attempt)"
                RAPID_LOADED=$((RAPID_LOADED + 1))
                SUCCESS=1
                break
            else
                # Check if MySQL is still alive
                if ! "${MYSQLADMIN_CMD[@]}" ping >/dev/null 2>&1; then
                    print_error "MySQL crashed during SECONDARY_LOAD of $table!"
                    print_error "Error: $ERROR_MSG"
                    return 1
                fi
                
                # Check if table is already loaded (error 3877 means not loaded, other errors may mean already loaded)
                if echo "$ERROR_MSG" | grep -qi "already loaded\|SECONDARY_LOAD_STATUS"; then
                    print_status "  ✓ $table was already loaded"
                    RAPID_LOADED=$((RAPID_LOADED + 1))
                    SUCCESS=1
                    break
                fi
                
                if [ $attempt -lt $MAX_RETRIES ]; then
                    print_warning "  ⚠ $table attempt $attempt failed, retrying..."
                    sleep 2
                fi
            fi
        done
        
        if [ $SUCCESS -eq 0 ]; then
            print_warning "  ✗ $table FAILED after $MAX_RETRIES attempts: ${ERROR_MSG}"
            RAPID_FAILED=$((RAPID_FAILED + 1))
            FAILED_TABLES+=("$table")
        fi
        
        # Small delay between tables
        sleep 1
    done
    
    print_status "TPC-H Rapid loading complete: $RAPID_LOADED/$((RAPID_LOADED + RAPID_FAILED)) loaded"
    if [ "$RAPID_FAILED" -gt 0 ]; then
        print_warning "Failed tables: ${FAILED_TABLES[*]}"
        print_warning "These tables will still work in InnoDB, just not in Rapid engine"
    else
        print_status "✅ All TPC-H tables successfully loaded into Rapid!"
    fi

    cd "$SCRIPT_DIR"
}

# TPC-DS setup (similar parallelization)
setup_tpcds() {
    print_status "Setting up TPC-DS..."
    
    if [ ! -d "${SCRIPT_DIR}/databricks-tpcds" ]; then
        print_status "Cloning TPC-DS repository..."
        git clone https://github.com/databricks/tpcds-kit.git "${SCRIPT_DIR}/databricks-tpcds"
    fi
    
    cd "${SCRIPT_DIR}/databricks-tpcds/tools"
    print_status "Compiling TPC-DS dsdgen..."
    make clean >/dev/null 2>&1 || true
    make OS=LINUX
    
    if [ ! -d "${SCRIPT_DIR}/tpcds_data" ] || [ -z "$(ls -A ${SCRIPT_DIR}/tpcds_data 2>/dev/null)" ]; then
        print_status "Generating ${SCALE}GB TPC-DS data..."
        mkdir -p "${SCRIPT_DIR}/tpcds_data"
        ./dsdgen -SCALE ${SCALE} -DIR "${SCRIPT_DIR}/tpcds_data" -TERMINATE N -FORCE Y
        
        print_status "Cleaning TPC-DS data files (parallel)..."
        cd "${SCRIPT_DIR}/tpcds_data"
        
        # Fix permissions first (dsdgen may create read-only files)
        chmod u+w *.dat 2>/dev/null || true
        
        if command -v parallel >/dev/null 2>&1; then
            find . -name "*.dat" -type f -writable -print0 | parallel -0 -j "$MAX_PARALLEL" \
                'iconv -f LATIN1 -t UTF-8//IGNORE {} | sed "s/|$//" > {}.clean && mv {}.clean {}'
        else
            for file in *.dat; do
                if [ -f "$file" ]; then
                    # Check if writable, try to fix if not
                    if [ ! -w "$file" ]; then
                        chmod u+w "$file" 2>/dev/null || {
                            print_warning "Cannot make $file writable, skipping"
                            continue
                        }
                    fi
                    
                    (iconv -f LATIN1 -t UTF-8//IGNORE "$file" | sed 's/|$//' > "${file}.clean" && mv "${file}.clean" "$file") &
                    while [ "$(jobs -r | wc -l)" -ge "$MAX_PARALLEL" ]; do
                        sleep 1
                    done
                fi
            done
            wait
        fi
    fi
}

load_tpcds_parallel() {
    print_status "Loading TPC-DS data with parallel processing..."

    # Check if data already exists with all tables populated
    if check_tpcds_data_complete; then
        print_status "✓ TPC-DS data already exists with all tables populated, skipping data load..."
        mysql_stream_db tpcds_sf1 <<'EOF'
SELECT 'TPC-DS Existing Data Summary' AS info;
SELECT table_name, table_rows
FROM information_schema.tables
WHERE table_schema = 'tpcds_sf1'
ORDER BY table_name;
EOF
        # Jump directly to SECONDARY_LOAD step
        print_status "Proceeding to SECONDARY_LOAD step..."
        
        # Ensure SECONDARY_ENGINE is set on all tables
        print_status "Verifying SECONDARY_ENGINE configuration..."
        for table in call_center catalog_page catalog_returns catalog_sales customer customer_address customer_demographics date_dim dbgen_version household_demographics income_band inventory item promotion reason ship_mode store store_returns store_sales time_dim warehouse web_page web_returns web_sales web_site; do
            has_secondary=$(mysql_scalar tpcds_sf1 "SELECT CREATE_OPTIONS FROM information_schema.tables WHERE table_schema='tpcds_sf1' AND table_name='$table'" 2>/dev/null | grep -q "SECONDARY_ENGINE" && echo "1" || echo "0")
            
            if [ "$has_secondary" = "0" ]; then
                print_status "  Adding SECONDARY_ENGINE to $table..."
                mysql_exec_db tpcds_sf1 "ALTER TABLE \`$table\` SECONDARY_ENGINE=Rapid;" || print_warning "Failed to add SECONDARY_ENGINE to $table"
            fi
        done
        
        # Continue to SECONDARY_LOAD at the end of function
    else
        # Data doesn't exist or is incomplete, proceed with full load
        print_status "TPC-DS data not found or incomplete, proceeding with full data load..."
        
        # Drop database completely to ensure no FK metadata from previous runs
        print_status "Dropping existing tpcds_sf1 database (if exists) to ensure clean state..."
        mysql_exec "DROP DATABASE IF EXISTS \`tpcds_sf1\`;" || true
        
        # Create fresh database
        mysql_exec "CREATE DATABASE \`tpcds_sf1\` DEFAULT CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;"
    
    # Disable FK checks globally
    mysql_exec "SET GLOBAL FOREIGN_KEY_CHECKS=0;" || true
    mysql_exec_db tpcds_sf1 "SET FOREIGN_KEY_CHECKS=0;"
    
    print_status "Creating TPC-DS schema (clean database, no FK metadata)..."
    mysql_stream_db tpcds_sf1 <<'EOF'
CREATE TABLE date_dim (
    d_date_sk INT NOT NULL PRIMARY KEY,
    d_date_id CHAR(16) NOT NULL,
    d_date DATE,
    d_month_seq INT,
    d_week_seq INT,
    d_quarter_seq INT,
    d_year INT,
    d_dow INT,
    d_moy INT,
    d_dom INT,
    d_qoy INT,
    d_fy_year INT,
    d_fy_quarter_seq INT,
    d_fy_week_seq INT,
    d_day_name CHAR(9),
    d_quarter_name CHAR(6),
    d_holiday CHAR(1),
    d_weekend CHAR(1),
    d_following_holiday CHAR(1),
    d_first_dom INT,
    d_last_dom INT,
    d_same_day_ly INT,
    d_same_day_lq INT,
    d_current_day CHAR(1),
    d_current_week CHAR(1),
    d_current_month CHAR(1),
    d_current_quarter CHAR(1),
    d_current_year CHAR(1)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 SECONDARY_ENGINE=Rapid;

CREATE TABLE store (
    s_store_sk INT NOT NULL PRIMARY KEY,
    s_store_id CHAR(16) NOT NULL,
    s_rec_start_date DATE,
    s_rec_end_date DATE,
    s_closed_date_sk INT,
    s_store_name VARCHAR(50),
    s_number_employees INT,
    s_floor_space INT,
    s_hours CHAR(20),
    s_manager VARCHAR(40),
    s_market_id INT,
    s_geography_class VARCHAR(100),
    s_market_desc VARCHAR(100),
    s_market_manager VARCHAR(40),
    s_division_id INT,
    s_division_name VARCHAR(50),
    s_company_id INT,
    s_company_name VARCHAR(50),
    s_street_number VARCHAR(10),
    s_street_name VARCHAR(60),
    s_street_type CHAR(15),
    s_suite_number CHAR(10),
    s_city VARCHAR(60),
    s_county VARCHAR(30),
    s_state CHAR(2),
    s_zip CHAR(10),
    s_country VARCHAR(20),
    s_gmt_offset DECIMAL(5,2),
    s_tax_percentage DECIMAL(5,2)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 SECONDARY_ENGINE=Rapid;

CREATE TABLE item (
    i_item_sk INT NOT NULL PRIMARY KEY,
    i_item_id CHAR(16) NOT NULL,
    i_rec_start_date DATE,
    i_rec_end_date DATE,
    i_item_desc VARCHAR(200),
    i_current_price DECIMAL(7,2),
    i_wholesale_cost DECIMAL(7,2),
    i_brand_id INT,
    i_brand CHAR(50),
    i_class_id INT,
    i_class CHAR(50),
    i_category_id INT,
    i_category CHAR(50),
    i_manufact_id INT,
    i_manufact CHAR(50),
    i_size CHAR(20),
    i_formulation CHAR(20),
    i_color CHAR(20),
    i_units CHAR(10),
    i_container CHAR(10),
    i_manager_id INT,
    i_product_name CHAR(50)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 SECONDARY_ENGINE=Rapid;

CREATE TABLE customer (
    c_customer_sk INT NOT NULL PRIMARY KEY,
    c_customer_id CHAR(16) NOT NULL,
    c_current_cdemo_sk INT,
    c_current_hdemo_sk INT,
    c_current_addr_sk INT,
    c_first_shipto_date_sk INT,
    c_first_sales_date_sk INT,
    c_salutation CHAR(10),
    c_first_name CHAR(20),
    c_last_name CHAR(30),
    c_preferred_cust_flag CHAR(1),
    c_birth_day INT,
    c_birth_month INT,
    c_birth_year INT,
    c_birth_country VARCHAR(20),
    c_login CHAR(13),
    c_email_address CHAR(50),
    c_last_review_date_sk INT
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 SECONDARY_ENGINE=Rapid;

CREATE TABLE store_sales (
    ss_sold_date_sk INT,
    ss_sold_time_sk INT,
    ss_item_sk INT NOT NULL,
    ss_customer_sk INT,
    ss_cdemo_sk INT,
    ss_hdemo_sk INT,
    ss_addr_sk INT,
    ss_store_sk INT,
    ss_promo_sk INT,
    ss_ticket_number BIGINT NOT NULL,
    ss_quantity INT,
    ss_wholesale_cost DECIMAL(7,2),
    ss_list_price DECIMAL(7,2),
    ss_sales_price DECIMAL(7,2),
    ss_ext_discount_amt DECIMAL(7,2),
    ss_ext_sales_price DECIMAL(7,2),
    ss_ext_wholesale_cost DECIMAL(7,2),
    ss_ext_list_price DECIMAL(7,2),
    ss_ext_tax DECIMAL(7,2),
    ss_coupon_amt DECIMAL(7,2),
    ss_net_paid DECIMAL(7,2),
    ss_net_paid_inc_tax DECIMAL(7,2),
    ss_net_profit DECIMAL(7,2),
    PRIMARY KEY (ss_item_sk, ss_ticket_number)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 SECONDARY_ENGINE=Rapid;

CREATE TABLE time_dim (
    t_time_sk INT NOT NULL PRIMARY KEY,
    t_time_id CHAR(16) NOT NULL,
    t_time INT,
    t_hour INT,
    t_minute INT,
    t_second INT,
    t_am_pm CHAR(2),
    t_shift CHAR(20),
    t_sub_shift CHAR(20),
    t_meal_time CHAR(20)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 SECONDARY_ENGINE=Rapid;

CREATE TABLE warehouse (
    w_warehouse_sk INT NOT NULL PRIMARY KEY,
    w_warehouse_id CHAR(16) NOT NULL,
    w_warehouse_name VARCHAR(20),
    w_warehouse_sq_ft INT,
    w_street_number CHAR(10),
    w_street_name VARCHAR(60),
    w_street_type CHAR(15),
    w_suite_number CHAR(10),
    w_city VARCHAR(60),
    w_county VARCHAR(30),
    w_state CHAR(2),
    w_zip CHAR(10),
    w_country VARCHAR(20),
    w_gmt_offset DECIMAL(5,2)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 SECONDARY_ENGINE=Rapid;

CREATE TABLE web_site (
    web_site_sk INT NOT NULL PRIMARY KEY,
    web_site_id CHAR(16) NOT NULL,
    web_rec_start_date DATE,
    web_rec_end_date DATE,
    web_name VARCHAR(50),
    web_open_date_sk INT,
    web_close_date_sk INT,
    web_class VARCHAR(50),
    web_manager VARCHAR(40),
    web_mkt_id INT,
    web_mkt_class VARCHAR(50),
    web_mkt_desc VARCHAR(100),
    web_market_manager VARCHAR(40),
    web_company_id INT,
    web_company_name CHAR(50),
    web_street_number CHAR(10),
    web_street_name VARCHAR(60),
    web_street_type CHAR(15),
    web_suite_number CHAR(10),
    web_city VARCHAR(60),
    web_county VARCHAR(30),
    web_state CHAR(2),
    web_zip CHAR(10),
    web_country VARCHAR(20),
    web_gmt_offset DECIMAL(5,2),
    web_tax_percentage DECIMAL(5,2)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 SECONDARY_ENGINE=Rapid;

CREATE TABLE web_page (
    wp_web_page_sk INT NOT NULL PRIMARY KEY,
    wp_web_page_id CHAR(16) NOT NULL,
    wp_rec_start_date DATE,
    wp_rec_end_date DATE,
    wp_creation_date_sk INT,
    wp_access_date_sk INT,
    wp_autogen_flag CHAR(1),
    wp_customer_sk INT,
    wp_url VARCHAR(100),
    wp_type CHAR(50),
    wp_char_count INT,
    wp_link_count INT,
    wp_image_count INT,
    wp_max_ad_count INT
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 SECONDARY_ENGINE=Rapid;

CREATE TABLE web_sales (
    ws_sold_date_sk INT,
    ws_sold_time_sk INT,
    ws_ship_date_sk INT,
    ws_item_sk INT NOT NULL,
    ws_bill_customer_sk INT,
    ws_bill_cdemo_sk INT,
    ws_bill_hdemo_sk INT,
    ws_bill_addr_sk INT,
    ws_ship_customer_sk INT,
    ws_ship_cdemo_sk INT,
    ws_ship_hdemo_sk INT,
    ws_ship_addr_sk INT,
    ws_web_page_sk INT,
    ws_web_site_sk INT,
    ws_ship_mode_sk INT,
    ws_warehouse_sk INT,
    ws_promo_sk INT,
    ws_order_number BIGINT NOT NULL,
    ws_quantity INT,
    ws_wholesale_cost DECIMAL(7,2),
    ws_list_price DECIMAL(7,2),
    ws_sales_price DECIMAL(7,2),
    ws_ext_discount_amt DECIMAL(7,2),
    ws_ext_sales_price DECIMAL(7,2),
    ws_ext_wholesale_cost DECIMAL(7,2),
    ws_ext_list_price DECIMAL(7,2),
    ws_ext_tax DECIMAL(7,2),
    ws_coupon_amt DECIMAL(7,2),
    ws_ext_ship_cost DECIMAL(7,2),
    ws_net_paid DECIMAL(7,2),
    ws_net_paid_inc_tax DECIMAL(7,2),
    ws_net_paid_inc_ship DECIMAL(7,2),
    ws_net_paid_inc_ship_tax DECIMAL(7,2),
    ws_net_profit DECIMAL(7,2),
    PRIMARY KEY (ws_item_sk, ws_order_number)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 SECONDARY_ENGINE=Rapid;

CREATE TABLE web_returns (
    wr_returned_date_sk INT,
    wr_returned_time_sk INT,
    wr_item_sk INT NOT NULL,
    wr_refunded_customer_sk INT,
    wr_refunded_cdemo_sk INT,
    wr_refunded_hdemo_sk INT,
    wr_refunded_addr_sk INT,
    wr_returning_customer_sk INT,
    wr_returning_cdemo_sk INT,
    wr_returning_hdemo_sk INT,
    wr_returning_addr_sk INT,
    wr_web_page_sk INT,
    wr_reason_sk INT,
    wr_order_number BIGINT NOT NULL,
    wr_return_quantity INT,
    wr_return_amt DECIMAL(7,2),
    wr_return_tax DECIMAL(7,2),
    wr_return_amt_inc_tax DECIMAL(7,2),
    wr_fee DECIMAL(7,2),
    wr_return_ship_cost DECIMAL(7,2),
    wr_refunded_cash DECIMAL(7,2),
    wr_reversed_charge DECIMAL(7,2),
    wr_account_credit DECIMAL(7,2),
    wr_net_loss DECIMAL(7,2),
    PRIMARY KEY (wr_item_sk, wr_order_number)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 SECONDARY_ENGINE=Rapid;

CREATE TABLE call_center (
    cc_call_center_sk INT NOT NULL PRIMARY KEY,
    cc_call_center_id CHAR(16) NOT NULL,
    cc_rec_start_date DATE,
    cc_rec_end_date DATE,
    cc_closed_date_sk INT,
    cc_open_date_sk INT,
    cc_name VARCHAR(50),
    cc_class VARCHAR(50),
    cc_employees INT,
    cc_sq_ft INT,
    cc_hours CHAR(20),
    cc_manager VARCHAR(40),
    cc_mkt_id INT,
    cc_mkt_class CHAR(50),
    cc_mkt_desc VARCHAR(100),
    cc_market_manager VARCHAR(40),
    cc_division INT,
    cc_division_name VARCHAR(50),
    cc_company INT,
    cc_company_name CHAR(50),
    cc_street_number CHAR(10),
    cc_street_name VARCHAR(60),
    cc_street_type CHAR(15),
    cc_suite_number CHAR(10),
    cc_city VARCHAR(60),
    cc_county VARCHAR(30),
    cc_state CHAR(2),
    cc_zip CHAR(10),
    cc_country VARCHAR(20),
    cc_gmt_offset DECIMAL(5,2),
    cc_tax_percentage DECIMAL(5,2)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 SECONDARY_ENGINE=Rapid;

CREATE TABLE catalog_page (
    cp_catalog_page_sk INT NOT NULL PRIMARY KEY,
    cp_catalog_page_id CHAR(16) NOT NULL,
    cp_start_date_sk INT,
    cp_end_date_sk INT,
    cp_department VARCHAR(50),
    cp_catalog_number INT,
    cp_catalog_page_number INT,
    cp_description VARCHAR(100),
    cp_type VARCHAR(100)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 SECONDARY_ENGINE=Rapid;

CREATE TABLE catalog_returns (
    cr_returned_date_sk INT,
    cr_returned_time_sk INT,
    cr_item_sk INT NOT NULL,
    cr_refunded_customer_sk INT,
    cr_refunded_cdemo_sk INT,
    cr_refunded_hdemo_sk INT,
    cr_refunded_addr_sk INT,
    cr_returning_customer_sk INT,
    cr_returning_cdemo_sk INT,
    cr_returning_hdemo_sk INT,
    cr_returning_addr_sk INT,
    cr_call_center_sk INT,
    cr_catalog_page_sk INT,
    cr_ship_mode_sk INT,
    cr_warehouse_sk INT,
    cr_reason_sk INT,
    cr_order_number BIGINT NOT NULL,
    cr_return_quantity INT,
    cr_return_amount DECIMAL(7,2),
    cr_return_tax DECIMAL(7,2),
    cr_return_amt_inc_tax DECIMAL(7,2),
    cr_fee DECIMAL(7,2),
    cr_return_ship_cost DECIMAL(7,2),
    cr_refunded_cash DECIMAL(7,2),
    cr_reversed_charge DECIMAL(7,2),
    cr_store_credit DECIMAL(7,2),
    cr_net_loss DECIMAL(7,2),
    PRIMARY KEY (cr_item_sk, cr_order_number)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 SECONDARY_ENGINE=Rapid;

CREATE TABLE catalog_sales (
    cs_sold_date_sk INT,
    cs_sold_time_sk INT,
    cs_ship_date_sk INT,
    cs_bill_customer_sk INT,
    cs_bill_cdemo_sk INT,
    cs_bill_hdemo_sk INT,
    cs_bill_addr_sk INT,
    cs_ship_customer_sk INT,
    cs_ship_cdemo_sk INT,
    cs_ship_hdemo_sk INT,
    cs_ship_addr_sk INT,
    cs_call_center_sk INT,
    cs_catalog_page_sk INT,
    cs_ship_mode_sk INT,
    cs_warehouse_sk INT,
    cs_item_sk INT NOT NULL,
    cs_promo_sk INT,
    cs_order_number BIGINT NOT NULL,
    cs_quantity INT,
    cs_wholesale_cost DECIMAL(7,2),
    cs_list_price DECIMAL(7,2),
    cs_sales_price DECIMAL(7,2),
    cs_ext_discount_amt DECIMAL(7,2),
    cs_ext_sales_price DECIMAL(7,2),
    cs_ext_wholesale_cost DECIMAL(7,2),
    cs_ext_list_price DECIMAL(7,2),
    cs_ext_tax DECIMAL(7,2),
    cs_coupon_amt DECIMAL(7,2),
    cs_ext_ship_cost DECIMAL(7,2),
    cs_net_paid DECIMAL(7,2),
    cs_net_paid_inc_tax DECIMAL(7,2),
    cs_net_paid_inc_ship DECIMAL(7,2),
    cs_net_paid_inc_ship_tax DECIMAL(7,2),
    cs_net_profit DECIMAL(7,2),
    PRIMARY KEY (cs_item_sk, cs_order_number)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 SECONDARY_ENGINE=Rapid;

CREATE TABLE customer_address (
    ca_address_sk INT NOT NULL PRIMARY KEY,
    ca_address_id CHAR(16) NOT NULL,
    ca_street_number CHAR(10),
    ca_street_name VARCHAR(60),
    ca_street_type CHAR(15),
    ca_suite_number CHAR(10),
    ca_city VARCHAR(60),
    ca_county VARCHAR(30),
    ca_state CHAR(2),
    ca_zip CHAR(10),
    ca_country VARCHAR(20),
    ca_gmt_offset DECIMAL(5,2),
    ca_location_type CHAR(20)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 SECONDARY_ENGINE=Rapid;

CREATE TABLE customer_demographics (
    cd_demo_sk INT NOT NULL PRIMARY KEY,
    cd_gender CHAR(1),
    cd_marital_status CHAR(1),
    cd_education_status CHAR(20),
    cd_purchase_estimate INT,
    cd_credit_rating CHAR(10),
    cd_dep_count INT,
    cd_dep_employed_count INT,
    cd_dep_college_count INT
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 SECONDARY_ENGINE=Rapid;

CREATE TABLE household_demographics (
    hd_demo_sk INT NOT NULL PRIMARY KEY,
    hd_income_band_sk INT,
    hd_buy_potential CHAR(15),
    hd_dep_count INT,
    hd_vehicle_count INT
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 SECONDARY_ENGINE=Rapid;

CREATE TABLE income_band (
    ib_income_band_sk INT NOT NULL PRIMARY KEY,
    ib_lower_bound INT,
    ib_upper_bound INT
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 SECONDARY_ENGINE=Rapid;

CREATE TABLE inventory (
    inv_date_sk INT NOT NULL,
    inv_item_sk INT NOT NULL,
    inv_warehouse_sk INT NOT NULL,
    inv_quantity_on_hand INT,
    PRIMARY KEY (inv_date_sk, inv_item_sk, inv_warehouse_sk)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 SECONDARY_ENGINE=Rapid;

CREATE TABLE promotion (
    p_promo_sk INT NOT NULL PRIMARY KEY,
    p_promo_id CHAR(16) NOT NULL,
    p_start_date_sk INT,
    p_end_date_sk INT,
    p_item_sk INT,
    p_cost DECIMAL(15,2),
    p_response_target INT,
    p_promo_name CHAR(50),
    p_channel_dmail CHAR(1),
    p_channel_email CHAR(1),
    p_channel_catalog CHAR(1),
    p_channel_tv CHAR(1),
    p_channel_radio CHAR(1),
    p_channel_press CHAR(1),
    p_channel_event CHAR(1),
    p_channel_demo CHAR(1),
    p_channel_details VARCHAR(100),
    p_purpose CHAR(15),
    p_discount_active CHAR(1)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 SECONDARY_ENGINE=Rapid;

CREATE TABLE reason (
    r_reason_sk INT NOT NULL PRIMARY KEY,
    r_reason_id CHAR(16) NOT NULL,
    r_reason_desc CHAR(100)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 SECONDARY_ENGINE=Rapid;

CREATE TABLE ship_mode (
    sm_ship_mode_sk INT NOT NULL PRIMARY KEY,
    sm_ship_mode_id CHAR(16) NOT NULL,
    sm_type CHAR(30),
    sm_code CHAR(10),
    sm_carrier CHAR(20),
    sm_contract CHAR(20)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 SECONDARY_ENGINE=Rapid;

CREATE TABLE store_returns (
    sr_returned_date_sk INT,
    sr_return_time_sk INT,
    sr_item_sk INT NOT NULL,
    sr_customer_sk INT,
    sr_cdemo_sk INT,
    sr_hdemo_sk INT,
    sr_addr_sk INT,
    sr_store_sk INT,
    sr_reason_sk INT,
    sr_ticket_number BIGINT NOT NULL,
    sr_return_quantity INT,
    sr_return_amt DECIMAL(7,2),
    sr_return_tax DECIMAL(7,2),
    sr_return_amt_inc_tax DECIMAL(7,2),
    sr_fee DECIMAL(7,2),
    sr_return_ship_cost DECIMAL(7,2),
    sr_refunded_cash DECIMAL(7,2),
    sr_reversed_charge DECIMAL(7,2),
    sr_store_credit DECIMAL(7,2),
    sr_net_loss DECIMAL(7,2),
    PRIMARY KEY (sr_item_sk, sr_ticket_number)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 SECONDARY_ENGINE=Rapid;

CREATE TABLE dbgen_version (
    dv_version VARCHAR(16),
    dv_create_date DATE,
    dv_create_time TIME,
    dv_cmdline_args VARCHAR(200)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 SECONDARY_ENGINE=Rapid;
EOF
    
    cd "${SCRIPT_DIR}/tpcds_data"
    print_status "Loading TPC-DS tables in parallel (${MAX_PARALLEL} workers)..."
    
    # Get list of .dat files
    mapfile -t DAT_FILES < <(find . -maxdepth 1 -name "*.dat" -printf "%f\n")
    
    if command -v parallel >/dev/null 2>&1; then
        printf "%s\n" "${DAT_FILES[@]}" | parallel -j "$MAX_PARALLEL" \
            'table="${1%.dat}"; if table_exists tpcds_sf1 "$table" && ! table_has_rows tpcds_sf1 "$table"; then load_data_file_ignore tpcds_sf1 "$table" "${SCRIPT_DIR}/tpcds_data/$1"; fi' _ {}
    else
        for file in "${DAT_FILES[@]}"; do
            table_name="${file%.dat}"
            if table_exists tpcds_sf1 "$table_name"; then
                if ! table_has_rows tpcds_sf1 "$table_name"; then
                    (load_data_file_ignore tpcds_sf1 "$table_name" "${SCRIPT_DIR}/tpcds_data/${file}") &
                    while [ "$(jobs -r | wc -l)" -ge "$MAX_PARALLEL" ]; do
                        sleep 1
                    done
                else
                    print_warning "[$table_name] Already loaded, skipping"
                fi
            fi
        done
        wait
    fi
    
        print_status "Verifying TPC-DS data load..."
        mysql_stream_db tpcds_sf1 <<'EOF'
SELECT 'TPC-DS Data Load Summary' AS info;
SELECT table_name, table_rows
FROM information_schema.tables
WHERE table_schema = 'tpcds_sf1'
ORDER BY table_name;
EOF
    fi  # End of data load check
    
    # SECONDARY_LOAD applies whether data was loaded or already existed
    print_status "Loading TPC-DS data into Rapid engine (with error handling and retry)..."
    # Ensure FK checks are disabled before SECONDARY_LOAD
    mysql_exec_db tpcds_sf1 "SET SESSION FOREIGN_KEY_CHECKS=0;"
    mysql_exec_db tpcds_sf1 "SET GLOBAL FOREIGN_KEY_CHECKS=0;" 2>/dev/null || true
    
    # Load all tables into the secondary engine (Rapid) with individual error handling and retry
    RAPID_LOADED=0
    RAPID_FAILED=0
    declare -a FAILED_TABLES
    MAX_RETRIES=2
    
    for table in call_center catalog_page catalog_returns catalog_sales customer customer_address customer_demographics date_dim dbgen_version household_demographics income_band inventory item promotion reason ship_mode store store_returns store_sales time_dim warehouse web_page web_returns web_sales web_site; do
        print_status "Loading $table into Rapid..."
        
        SUCCESS=0
        for attempt in $(seq 1 $MAX_RETRIES); do
            # Try to load with timeout to detect crashes - capture error
            ERROR_MSG=$(timeout 120 mysql_exec_db tpcds_sf1 "SET SESSION FOREIGN_KEY_CHECKS=0; ALTER TABLE \`$table\` SECONDARY_LOAD;" 2>&1)
            if [ $? -eq 0 ]; then
                print_status "  ✓ $table loaded into Rapid (attempt $attempt)"
                RAPID_LOADED=$((RAPID_LOADED + 1))
                SUCCESS=1
                break
            else
                # Check if MySQL is still alive
                if ! "${MYSQLADMIN_CMD[@]}" ping >/dev/null 2>&1; then
                    print_error "MySQL crashed during SECONDARY_LOAD of $table!"
                    print_error "Error: $ERROR_MSG"
                    return 1
                fi
                
                # Check if table is already loaded
                if echo "$ERROR_MSG" | grep -qi "already loaded\|SECONDARY_LOAD_STATUS"; then
                    print_status "  ✓ $table was already loaded"
                    RAPID_LOADED=$((RAPID_LOADED + 1))
                    SUCCESS=1
                    break
                fi
                
                if [ $attempt -lt $MAX_RETRIES ]; then
                    print_warning "  ⚠ $table attempt $attempt failed, retrying..."
                    sleep 2
                fi
            fi
        done
        
        if [ $SUCCESS -eq 0 ]; then
            print_warning "  ✗ $table FAILED after $MAX_RETRIES attempts: ${ERROR_MSG}"
            RAPID_FAILED=$((RAPID_FAILED + 1))
            FAILED_TABLES+=("$table")
        fi
        
        # Small delay between tables
        sleep 1
    done
    
    print_status "TPC-DS Rapid loading complete: $RAPID_LOADED/$((RAPID_LOADED + RAPID_FAILED)) loaded"
    if [ "$RAPID_FAILED" -gt 0 ]; then
        print_warning "Failed tables: ${FAILED_TABLES[*]}"
        print_warning "These tables will still work in InnoDB, just not in Rapid engine"
    else
        print_status "✅ All TPC-DS tables successfully loaded into Rapid!"
    fi

    cd "$SCRIPT_DIR"
}

# Main execution
main() {
    echo "========================================="
    echo "Parallel TPC-H and TPC-DS Benchmark Setup"
    echo "========================================="
    echo "Parallelization: ${MAX_PARALLEL} workers"
    echo "Batch size: ${BATCH_SIZE} rows"
    echo "Duplicate handling: INSERT IGNORE/REPLACE"
    echo
    
    check_mysql
    
    echo
    echo "1. Setting up TPC-H..."
    echo "----------------------"
    setup_tpch
    load_tpch_parallel
    
    echo
    echo "2. Setting up TPC-DS..."
    echo "-----------------------"
    setup_tpcds
    load_tpcds_parallel
    
    echo
    print_status "Setup complete!"
    echo
    echo "Databases created:"
    echo "  - tpch_sf1  : TPC-H benchmark data (${SCALE}GB)"
    echo "  - tpcds_sf1 : TPC-DS benchmark data (${SCALE}GB)"
    echo
    echo "Performance: Loaded with ${MAX_PARALLEL} parallel workers"
}

main "$@"
