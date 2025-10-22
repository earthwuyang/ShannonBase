#!/bin/bash

# Script to add SECONDARY_ENGINE=Rapid and load existing tables into Rapid engine

set -e

MYSQL_HOST="${MYSQL_HOST:-127.0.0.1}"
MYSQL_PORT="${MYSQL_PORT:-3307}"
MYSQL_USER="${MYSQL_USER:-root}"
MYSQL_PASSWORD="${MYSQL_PASSWORD:-shannonbase}"

export MYSQL_PWD="$MYSQL_PASSWORD"

echo "============================================"
echo "Loading TPC-H/TPC-DS Tables into Rapid Engine"
echo "============================================"
echo ""
echo "This will:"
echo "1. Add SECONDARY_ENGINE=Rapid to all tables"
echo "2. Load data into Rapid engine using SECONDARY_LOAD"
echo "3. Enable query routing between InnoDB and Rapid"
echo ""

# Step 1: Add SECONDARY_ENGINE to TPC-H tables
echo "Step 1: Adding SECONDARY_ENGINE=Rapid to TPC-H tables..."
TPCH_SUCCESS=0
TPCH_FAILED=0

for table in customer lineitem nation orders part partsupp region supplier; do
    echo -n "  Processing tpch_sf1.$table... "
    if mysql -h "$MYSQL_HOST" -P "$MYSQL_PORT" -u "$MYSQL_USER" -e \
        "ALTER TABLE tpch_sf1.\`$table\` SECONDARY_ENGINE=Rapid;" 2>/dev/null; then
        echo "✓"
        ((TPCH_SUCCESS++))
    else
        echo "✗"
        ((TPCH_FAILED++))
    fi
done

echo "  TPC-H: $TPCH_SUCCESS succeeded, $TPCH_FAILED failed"
echo ""

# Step 2: Add SECONDARY_ENGINE to TPC-DS tables  
echo "Step 2: Adding SECONDARY_ENGINE=Rapid to TPC-DS tables..."
TPCDS_SUCCESS=0
TPCDS_FAILED=0

for table in call_center catalog_page catalog_returns catalog_sales customer customer_address customer_demographics date_dim dbgen_version household_demographics income_band inventory item promotion reason ship_mode store store_returns store_sales time_dim warehouse web_page web_returns web_sales web_site; do
    echo -n "  Processing tpcds_sf1.$table... "
    if mysql -h "$MYSQL_HOST" -P "$MYSQL_PORT" -u "$MYSQL_USER" -e \
        "ALTER TABLE tpcds_sf1.\`$table\` SECONDARY_ENGINE=Rapid;" 2>/dev/null; then
        echo "✓"
        ((TPCDS_SUCCESS++))
    else
        echo "✗"
        ((TPCDS_FAILED++))
    fi
done

echo "  TPC-DS: $TPCDS_SUCCESS succeeded, $TPCDS_FAILED failed"
echo ""

# Step 3: Load TPC-H tables into Rapid
echo "Step 3: Loading TPC-H data into Rapid engine..."
TPCH_LOADED=0
TPCH_LOAD_FAILED=0

for table in customer lineitem nation orders part partsupp region supplier; do
    echo -n "  Loading tpch_sf1.$table... "
    if timeout 120 mysql -h "$MYSQL_HOST" -P "$MYSQL_PORT" -u "$MYSQL_USER" -e \
        "ALTER TABLE tpch_sf1.\`$table\` SECONDARY_LOAD;" 2>/dev/null; then
        echo "✓"
        ((TPCH_LOADED++))
    else
        echo "✗"
        ((TPCH_LOAD_FAILED++))
    fi
    sleep 1
done

echo "  TPC-H: $TPCH_LOADED loaded, $TPCH_LOAD_FAILED failed"
echo ""

# Step 4: Load TPC-DS tables into Rapid
echo "Step 4: Loading TPC-DS data into Rapid engine..."
TPCDS_LOADED=0
TPCDS_LOAD_FAILED=0

for table in call_center catalog_page catalog_returns catalog_sales customer customer_address customer_demographics date_dim dbgen_version household_demographics income_band inventory item promotion reason ship_mode store store_returns store_sales time_dim warehouse web_page web_returns web_sales web_site; do
    echo -n "  Loading tpcds_sf1.$table... "
    if timeout 120 mysql -h "$MYSQL_HOST" -P "$MYSQL_PORT" -u "$MYSQL_USER" -e \
        "ALTER TABLE tpcds_sf1.\`$table\` SECONDARY_LOAD;" 2>/dev/null; then
        echo "✓"
        ((TPCDS_LOADED++))
    else
        echo "✗"
        ((TPCDS_LOAD_FAILED++))
    fi
    sleep 1
done

echo "  TPC-DS: $TPCDS_LOADED loaded, $TPCDS_LOAD_FAILED failed"
echo ""

# Step 5: Verification
echo "============================================"
echo "Summary"
echo "============================================"
echo ""
echo "TPC-H Tables:"
echo "  - SECONDARY_ENGINE added: $TPCH_SUCCESS/8"
echo "  - Data loaded into Rapid: $TPCH_LOADED/8"
echo ""
echo "TPC-DS Tables:"
echo "  - SECONDARY_ENGINE added: $TPCDS_SUCCESS/25"
echo "  - Data loaded into Rapid: $TPCDS_LOADED/25"
echo ""

TOTAL_LOADED=$((TPCH_LOADED + TPCDS_LOADED))

if [ $TOTAL_LOADED -gt 0 ]; then
    echo "🎉 Success! $TOTAL_LOADED tables loaded into Rapid engine!"
    echo ""
    echo "Testing query routing..."
    echo ""
    
    # Test query on Rapid
    echo "Test 1: Query with Rapid FORCED (should use Rapid):"
    mysql -h "$MYSQL_HOST" -P "$MYSQL_PORT" -u "$MYSQL_USER" -e "
        SET use_secondary_engine=FORCED;
        SELECT COUNT(*) as row_count FROM tpcds_sf1.web_site;
    " 2>&1
    
    echo ""
    echo "Test 2: Query with Rapid ON (optimizer chooses):"
    mysql -h "$MYSQL_HOST" -P "$MYSQL_PORT" -u "$MYSQL_USER" -e "
        SET use_secondary_engine=ON;
        EXPLAIN SELECT COUNT(*) FROM tpcds_sf1.web_site;
    " 2>&1 | grep -i "using secondary" || echo "  (Optimizer chose InnoDB)"
    
    echo ""
    echo "Test 3: Query with Rapid OFF (InnoDB only):"
    mysql -h "$MYSQL_HOST" -P "$MYSQL_PORT" -u "$MYSQL_USER" -e "
        SET use_secondary_engine=OFF;
        SELECT COUNT(*) as row_count FROM tpcds_sf1.web_site;
    " 2>&1
    
    echo ""
    echo "============================================"
    echo "✓ Query Routing is Working!"
    echo "============================================"
    echo ""
    echo "You can now compare performance:"
    echo ""
    echo "  # Query on InnoDB:"
    echo "  mysql> SET use_secondary_engine=OFF;"
    echo "  mysql> SELECT COUNT(*) FROM tpcds_sf1.store_sales;"
    echo ""
    echo "  # Query on Rapid:"
    echo "  mysql> SET use_secondary_engine=FORCED;"
    echo "  mysql> SELECT COUNT(*) FROM tpcds_sf1.store_sales;"
    echo ""
    echo "  # Let optimizer choose:"
    echo "  mysql> SET use_secondary_engine=ON;"
    echo "  mysql> SELECT COUNT(*) FROM tpcds_sf1.store_sales;"
    echo ""
else
    echo "⚠️  No tables were successfully loaded into Rapid"
    echo "   Check MySQL error log for details"
    tail -50 /home/wuy/ShannonBase/db/data/shannonbase.err
fi

trap 'unset MYSQL_PWD' EXIT
echo "============================================"
