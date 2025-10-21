#!/bin/bash

# TPC-H and TPC-DS Setup Script for MySQL
# This script downloads, compiles, and loads TPC-H and TPC-DS data into a local MySQL server.

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# Data scale (1 = 1GB)
SCALE=1

# MySQL configuration (override via environment variables)
# Note: Default to 'root' for ShannonBase compatibility (mysql_native_password is disabled)
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

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
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

load_data_file() {
    local db="$1"
    local table="$2"
    local file="$3"
    local escaped
    escaped=$(escape_path_for_mysql "$file")
    mysql_exec_db "$db" "LOAD DATA LOCAL INFILE '${escaped}' INTO TABLE \`${table}\` FIELDS TERMINATED BY '|' LINES TERMINATED BY '\n';"
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
    local count
    count=$(mysql_scalar "$db" "SELECT COUNT(*) FROM \`${table}\` LIMIT 1;")
    [ "${count:-0}" -gt 0 ]
}

check_mysql() {
    if ! "${MYSQLADMIN_CMD[@]}" ping >/dev/null 2>&1; then
        print_error "MySQL is not reachable. Adjust MYSQL_* environment variables if needed."
        exit 1
    fi
    
    # Enable local_infile on server side (required for LOAD DATA LOCAL INFILE)
    if mysql_exec "SET GLOBAL local_infile = 1" 2>/dev/null; then
        print_status "Enabled local_infile on MySQL server"
    else
        print_warning "Could not enable local_infile on server. If data loading fails, run: SET GLOBAL local_infile = 1;"
    fi
}

# Function to download and compile TPC-H
setup_tpch() {
    print_status "Setting up TPC-H..."
    
    # Clone TPC-H repository
    if [ ! -d "${SCRIPT_DIR}/tpch-dbgen" ]; then
        print_status "Cloning TPC-H repository..."
        git clone https://github.com/electrum/tpch-dbgen.git "${SCRIPT_DIR}/tpch-dbgen"
    else
        print_warning "TPC-H repository already exists, skipping clone"
    fi
    
    # Compile TPC-H
    cd "${SCRIPT_DIR}/tpch-dbgen"
    print_status "Compiling TPC-H dbgen..."
    make clean >/dev/null 2>&1 || true
    make -j$(nproc)
    
    # Generate TPC-H data
    if [ ! -f "lineitem.tbl" ]; then
        print_status "Generating ${SCALE}GB TPC-H data..."
        ./dbgen -vf -s ${SCALE}
        
        # Remove trailing pipes from data files
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
    else
        print_warning "TPC-H data already exists, skipping generation"
    fi
}

# Function to download and compile TPC-DS
setup_tpcds() {
    print_status "Setting up TPC-DS..."
    
    # Clone TPC-DS repository (using Databricks version that compiles cleanly)
    if [ ! -d "${SCRIPT_DIR}/databricks-tpcds" ]; then
        print_status "Cloning TPC-DS repository..."
        git clone https://github.com/databricks/tpcds-kit.git "${SCRIPT_DIR}/databricks-tpcds"
    else
        print_warning "TPC-DS repository already exists, skipping clone"
    fi
    
    # Compile TPC-DS
    cd "${SCRIPT_DIR}/databricks-tpcds/tools"
    print_status "Compiling TPC-DS dsdgen..."
    make clean >/dev/null 2>&1 || true
    make OS=LINUX
    
    # Generate TPC-DS data
    if [ ! -d "${SCRIPT_DIR}/tpcds_data" ] || [ -z "$(ls -A ${SCRIPT_DIR}/tpcds_data 2>/dev/null)" ]; then
        print_status "Generating ${SCALE}GB TPC-DS data..."
        mkdir -p "${SCRIPT_DIR}/tpcds_data"
        # Run dsdgen with proper flags
        ./dsdgen -SCALE ${SCALE} -DIR "${SCRIPT_DIR}/tpcds_data" -TERMINATE N -FORCE Y
        
        # Check if data was generated
        if [ -z "$(ls -A ${SCRIPT_DIR}/tpcds_data 2>/dev/null)" ]; then
            print_error "Failed to generate TPC-DS data"
            return 1
        fi
        
        # Clean and fix data files
        print_status "Cleaning TPC-DS data files..."
        cd "${SCRIPT_DIR}/tpcds_data"
        
        # Fix permissions first (dsdgen may create read-only files)
        chmod u+w *.dat 2>/dev/null || true
        
        for file in *.dat; do
            if [ -f "$file" ]; then
                print_status "Processing $file..."
                
                # Check if file is writable
                if [ ! -w "$file" ]; then
                    print_warning "$file is not writable, attempting to fix permissions..."
                    chmod u+w "$file" 2>/dev/null || {
                        print_error "Cannot make $file writable, skipping"
                        continue
                    }
                fi
                
                # Step 1: Convert from LATIN1 to UTF-8 to handle special characters
                # This fixes issues like "CÔTE D'IVOIRE" in customer.dat
                iconv -f LATIN1 -t UTF-8//IGNORE "$file" > "${file}.utf8" 2>/dev/null || {
                    print_warning "Could not convert $file from LATIN1, trying ISO-8859-1..."
                    iconv -f ISO-8859-1 -t UTF-8//IGNORE "$file" > "${file}.utf8" 2>/dev/null || {
                        print_warning "Could not convert $file, keeping original encoding"
                        cp "$file" "${file}.utf8"
                    }
                }
                
                # Step 2: Remove trailing pipes from each line
                sed 's/|$//' "${file}.utf8" > "$file"
                
                # Step 3: Clean up temporary file
                rm -f "${file}.utf8"
            fi
        done
        print_status "Data cleaning complete"
    else
        print_warning "TPC-DS data already exists, skipping generation"
    fi
}

# Function to create TPC-H database and load data
load_tpch() {
    print_status "Loading TPC-H data into MySQL..."

    mysql_exec "CREATE DATABASE IF NOT EXISTS \`tpch_sf1\` DEFAULT CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;"
    mysql_exec_db tpch_sf1 "SET FOREIGN_KEY_CHECKS=0;"
    mysql_exec_db tpch_sf1 "DROP TABLE IF EXISTS lineitem, orders, partsupp, customer, supplier, part, nation, region;"
    mysql_exec_db tpch_sf1 "SET FOREIGN_KEY_CHECKS=1;"

    print_status "Creating TPC-H schema..."
    mysql_stream_db tpch_sf1 <<'EOF'
CREATE TABLE nation (
    n_nationkey INT NOT NULL,
    n_name CHAR(25) NOT NULL,
    n_regionkey INT NOT NULL,
    n_comment VARCHAR(152),
    PRIMARY KEY (n_nationkey)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

CREATE TABLE region (
    r_regionkey INT NOT NULL,
    r_name CHAR(25) NOT NULL,
    r_comment VARCHAR(152),
    PRIMARY KEY (r_regionkey)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

CREATE TABLE part (
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

CREATE TABLE supplier (
    s_suppkey INT NOT NULL,
    s_name CHAR(25) NOT NULL,
    s_address VARCHAR(40) NOT NULL,
    s_nationkey INT NOT NULL,
    s_phone CHAR(15) NOT NULL,
    s_acctbal DECIMAL(15,2) NOT NULL,
    s_comment VARCHAR(101) NOT NULL,
    PRIMARY KEY (s_suppkey),
    KEY idx_supplier_nation (s_nationkey),
    CONSTRAINT fk_supplier_nation FOREIGN KEY (s_nationkey) REFERENCES nation(n_nationkey)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

CREATE TABLE partsupp (
    ps_partkey INT NOT NULL,
    ps_suppkey INT NOT NULL,
    ps_availqty INT NOT NULL,
    ps_supplycost DECIMAL(15,2) NOT NULL,
    ps_comment VARCHAR(199) NOT NULL,
    PRIMARY KEY (ps_partkey, ps_suppkey),
    KEY idx_partsupp_part (ps_partkey),
    KEY idx_partsupp_supp (ps_suppkey),
    CONSTRAINT fk_partsupp_part FOREIGN KEY (ps_partkey) REFERENCES part(p_partkey),
    CONSTRAINT fk_partsupp_supplier FOREIGN KEY (ps_suppkey) REFERENCES supplier(s_suppkey)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

CREATE TABLE customer (
    c_custkey INT NOT NULL,
    c_name VARCHAR(25) NOT NULL,
    c_address VARCHAR(40) NOT NULL,
    c_nationkey INT NOT NULL,
    c_phone CHAR(15) NOT NULL,
    c_acctbal DECIMAL(15,2) NOT NULL,
    c_mktsegment CHAR(10) NOT NULL,
    c_comment VARCHAR(117) NOT NULL,
    PRIMARY KEY (c_custkey),
    KEY idx_customer_nation (c_nationkey),
    CONSTRAINT fk_customer_nation FOREIGN KEY (c_nationkey) REFERENCES nation(n_nationkey)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

CREATE TABLE orders (
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
    KEY idx_orders_date (o_orderdate),
    CONSTRAINT fk_orders_customer FOREIGN KEY (o_custkey) REFERENCES customer(c_custkey)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

CREATE TABLE lineitem (
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
-- nation table doesn't have this index in its CREATE TABLE statement
CREATE INDEX idx_nation_region ON nation(n_regionkey);
-- Note: idx_supplier_nation is already defined in supplier CREATE TABLE, no need to add it again
EOF

    LINEITEM_COUNT=$(mysql_scalar tpch_sf1 "SELECT COUNT(*) FROM lineitem;") || true
    if [ -n "$LINEITEM_COUNT" ] && [ "$LINEITEM_COUNT" -gt 0 ]; then
        print_warning "TPC-H data already loaded (lineitem has $LINEITEM_COUNT rows), skipping data load"
        return
    fi

    cd "${SCRIPT_DIR}/tpch-dbgen"
    print_status "Loading TPC-H data (this may take a while)..."

    load_data_file tpch_sf1 region "${SCRIPT_DIR}/tpch-dbgen/region.tbl"
    load_data_file tpch_sf1 nation "${SCRIPT_DIR}/tpch-dbgen/nation.tbl"
    load_data_file tpch_sf1 part "${SCRIPT_DIR}/tpch-dbgen/part.tbl"
    load_data_file tpch_sf1 supplier "${SCRIPT_DIR}/tpch-dbgen/supplier.tbl"
    load_data_file tpch_sf1 partsupp "${SCRIPT_DIR}/tpch-dbgen/partsupp.tbl"
    load_data_file tpch_sf1 customer "${SCRIPT_DIR}/tpch-dbgen/customer.tbl"
    load_data_file tpch_sf1 orders "${SCRIPT_DIR}/tpch-dbgen/orders.tbl"

    if [ -f "lineitem.tbl" ]; then
        LINE_COUNT=$(wc -l < lineitem.tbl)
        if [ "$LINE_COUNT" -gt 1000000 ]; then
            print_status "Splitting lineitem table for loading..."
            split -l 1000000 lineitem.tbl lineitem_part_
            for file in lineitem_part_*; do
                print_status "Loading $file..."
                load_data_file tpch_sf1 lineitem "${SCRIPT_DIR}/tpch-dbgen/${file}"
            done
            rm -f lineitem_part_*
        else
            load_data_file tpch_sf1 lineitem "${SCRIPT_DIR}/tpch-dbgen/lineitem.tbl"
        fi
    fi

    print_status "Adding lineitem foreign key constraints..."
    mysql_exec_db tpch_sf1 "ALTER TABLE lineitem ADD CONSTRAINT fk_lineitem_orders FOREIGN KEY (l_orderkey) REFERENCES orders(o_orderkey);"
    mysql_exec_db tpch_sf1 "ALTER TABLE lineitem ADD CONSTRAINT fk_lineitem_partsupp FOREIGN KEY (l_partkey, l_suppkey) REFERENCES partsupp(ps_partkey, ps_suppkey);"

    print_status "Verifying TPC-H data load..."
    LINEITEM_COUNT=$(mysql_scalar tpch_sf1 "SELECT COUNT(*) FROM lineitem;") || true
    if [ -z "$LINEITEM_COUNT" ] || [ "$LINEITEM_COUNT" -eq 0 ]; then
        print_warning "TPC-H data not loaded correctly"
    else
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
    fi

    cd "$SCRIPT_DIR"
}

# Function to create TPC-DS database and load data
load_tpcds() {
    print_status "Loading TPC-DS data into MySQL..."

    mysql_exec "CREATE DATABASE IF NOT EXISTS \`tpcds_sf1\` DEFAULT CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;"
    mysql_exec_db tpcds_sf1 "SET FOREIGN_KEY_CHECKS=0;"
    mysql_exec_db tpcds_sf1 "DROP TABLE IF EXISTS call_center, catalog_page, catalog_returns, catalog_sales, customer, customer_address, customer_demographics, date_dim, dbgen_version, household_demographics, income_band, inventory, item, promotion, reason, ship_mode, store, store_returns, store_sales, time_dim, warehouse, web_page, web_returns, web_sales, web_site;"
    mysql_exec_db tpcds_sf1 "SET FOREIGN_KEY_CHECKS=1;"

    print_status "Creating TPC-DS schema..."
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
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

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
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

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
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

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
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

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
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

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
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

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
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

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
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

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
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

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
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

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
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

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
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

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
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

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
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

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
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

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
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

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
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

CREATE TABLE household_demographics (
    hd_demo_sk INT NOT NULL PRIMARY KEY,
    hd_income_band_sk INT,
    hd_buy_potential CHAR(15),
    hd_dep_count INT,
    hd_vehicle_count INT
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

CREATE TABLE income_band (
    ib_income_band_sk INT NOT NULL PRIMARY KEY,
    ib_lower_bound INT,
    ib_upper_bound INT
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

CREATE TABLE inventory (
    inv_date_sk INT NOT NULL,
    inv_item_sk INT NOT NULL,
    inv_warehouse_sk INT NOT NULL,
    inv_quantity_on_hand INT,
    PRIMARY KEY (inv_date_sk, inv_item_sk, inv_warehouse_sk)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

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
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

CREATE TABLE reason (
    r_reason_sk INT NOT NULL PRIMARY KEY,
    r_reason_id CHAR(16) NOT NULL,
    r_reason_desc CHAR(100)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

CREATE TABLE ship_mode (
    sm_ship_mode_sk INT NOT NULL PRIMARY KEY,
    sm_ship_mode_id CHAR(16) NOT NULL,
    sm_type CHAR(30),
    sm_code CHAR(10),
    sm_carrier CHAR(20),
    sm_contract CHAR(20)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

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
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

CREATE TABLE dbgen_version (
    dv_version VARCHAR(16),
    dv_create_date DATE,
    dv_create_time TIME,
    dv_cmdline_args VARCHAR(200)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;
EOF

    local has_data
    has_data=$(mysql_scalar information_schema "SELECT COUNT(*) FROM tables WHERE table_schema='tpcds_sf1';") || true
    if [ "${has_data:-0}" -gt 0 ] && table_has_rows tpcds_sf1 store; then
        print_warning "TPC-DS data already loaded, skipping data load"
        return
    fi

    cd "${SCRIPT_DIR}/tpcds_data"
    print_status "Loading TPC-DS data (this may take a while)..."

    for file in *.dat; do
        if [ -f "$file" ]; then
            table_name="${file%.dat}"
            if table_exists tpcds_sf1 "$table_name"; then
                print_status "Loading ${table_name}..."
                load_data_file tpcds_sf1 "$table_name" "${SCRIPT_DIR}/tpcds_data/${file}" || print_warning "Failed to load ${table_name}, skipping..."
            else
                print_warning "Table ${table_name} does not exist, skipping data load"
            fi
        fi
    done

    print_status "Verifying TPC-DS data load..."
    mysql_stream_db tpcds_sf1 <<'EOF'
SELECT 'TPC-DS Data Load Summary' AS info;
SELECT table_name, table_rows
FROM information_schema.tables
WHERE table_schema = 'tpcds_sf1'
ORDER BY table_name;
EOF

    cd "$SCRIPT_DIR"
}

# Main execution
main() {
    echo "========================================="
    echo "TPC-H and TPC-DS Benchmark Setup Script"
    echo "========================================="
    echo
    
    check_mysql
    
    # # Setup TPC-H
    # echo
    # echo "1. Setting up TPC-H..."
    # echo "----------------------"
    # setup_tpch
    # load_tpch
    
    # Setup TPC-DS
    echo
    echo "2. Setting up TPC-DS..."
    echo "-----------------------"
    setup_tpcds
    load_tpcds
    
    echo
    print_status "Setup complete!"
    echo
    echo "Databases created:"
    echo "  - tpch_sf1  : TPC-H benchmark data (${SCALE}GB)"
    echo "  - tpcds_sf1 : TPC-DS benchmark data (${SCALE}GB)"
    echo
    echo "Databases are available on MySQL at ${MYSQL_HOST}:${MYSQL_PORT}."
    echo
    echo "You can connect using:"
    echo "  mysql -h ${MYSQL_HOST} -P ${MYSQL_PORT} -u ${MYSQL_USER} tpch_sf1"
    echo "  mysql -h ${MYSQL_HOST} -P ${MYSQL_PORT} -u ${MYSQL_USER} tpcds_sf1"
    echo "(set MYSQL_PASSWORD if authentication is required)"
}

# Run main function
main "$@"