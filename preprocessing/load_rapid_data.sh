#!/bin/bash

# Script to load existing tables (that already have SECONDARY_ENGINE=Rapid) into Rapid engine

# Note: Don't use "set -e" so script continues even if some tables fail

MYSQL_HOST="${MYSQL_HOST:-127.0.0.1}"
MYSQL_PORT="${MYSQL_PORT:-3307}"
MYSQL_USER="${MYSQL_USER:-root}"
MYSQL_PASSWORD="${MYSQL_PASSWORD:-shannonbase}"

export MYSQL_PWD="$MYSQL_PASSWORD"

echo "============================================"
echo "Loading Data into Rapid Engine"
echo "============================================"
echo ""

# Load TPC-H tables
echo "Step 1: Loading TPC-H tables into Rapid..."
TPCH_LOADED=0
TPCH_FAILED=0

for table in customer lineitem nation orders part partsupp region supplier; do
    echo -n "  Loading tpch_sf1.$table... "
    if timeout 120 mysql -h "$MYSQL_HOST" -P "$MYSQL_PORT" -u "$MYSQL_USER" -e \
        "ALTER TABLE tpch_sf1.\`$table\` SECONDARY_LOAD;" 2>/dev/null; then
        echo "✓"
        ((TPCH_LOADED++))
    else
        echo "✗"
        ((TPCH_FAILED++))
    fi
    sleep 1
done

echo "  TPC-H: $TPCH_LOADED/8 loaded"
echo ""

# Load TPC-DS tables
echo "Step 2: Loading TPC-DS tables into Rapid..."
TPCDS_LOADED=0
TPCDS_FAILED=0

for table in call_center catalog_page catalog_returns catalog_sales customer customer_address customer_demographics date_dim dbgen_version household_demographics income_band inventory item promotion reason ship_mode store store_returns store_sales time_dim warehouse web_page web_returns web_sales web_site; do
    echo -n "  Loading tpcds_sf1.$table... "
    if timeout 120 mysql -h "$MYSQL_HOST" -P "$MYSQL_PORT" -u "$MYSQL_USER" -e \
        "ALTER TABLE tpcds_sf1.\`$table\` SECONDARY_LOAD;" 2>/dev/null; then
        echo "✓"
        ((TPCDS_LOADED++))
    else
        echo "✗"
        ((TPCDS_FAILED++))
    fi
    sleep 1
done

echo "  TPC-DS: $TPCDS_LOADED/25 loaded"
echo ""

# Summary
TOTAL_LOADED=$((TPCH_LOADED + TPCDS_LOADED))
TOTAL_TABLES=33

echo "============================================"
echo "Summary: $TOTAL_LOADED/$TOTAL_TABLES tables loaded into Rapid"
echo "============================================"
echo ""

if [ $TOTAL_LOADED -gt 0 ]; then
    echo "🎉 Success! Testing query routing..."
    echo ""
    
    # Test 1: InnoDB only
    echo "Test 1: Query on InnoDB (secondary engine OFF):"
    TIME1=$(mysql -h "$MYSQL_HOST" -P "$MYSQL_PORT" -u "$MYSQL_USER" -e "
        SET use_secondary_engine=OFF;
        SELECT COUNT(*) as count_innodb FROM tpcds_sf1.store_sales;
    " 2>&1 | tail -1)
    echo "  Result: $TIME1 rows"
    
    echo ""
    
    # Test 2: Rapid only
    echo "Test 2: Query on Rapid (secondary engine FORCED):"
    TIME2=$(mysql -h "$MYSQL_HOST" -P "$MYSQL_PORT" -u "$MYSQL_USER" -e "
        SET use_secondary_engine=FORCED;
        SELECT COUNT(*) as count_rapid FROM tpcds_sf1.store_sales;
    " 2>&1 | tail -1)
    echo "  Result: $TIME2 rows"
    
    echo ""
    
    if [ "$TIME1" = "$TIME2" ]; then
        echo "✓ Both engines return same results!"
    else
        echo "⚠️  Results differ - may need investigation"
    fi
    
    echo ""
    echo "============================================"
    echo "Query Routing Enabled!"
    echo "============================================"
    echo ""
    echo "You can now compare performance between InnoDB and Rapid:"
    echo ""
    echo "# Benchmark on InnoDB:"
    echo "  mysql> SET use_secondary_engine=OFF;"
    echo "  mysql> SELECT COUNT(*), AVG(ss_sales_price) FROM tpcds_sf1.store_sales;"
    echo ""
    echo "# Benchmark on Rapid:"
    echo "  mysql> SET use_secondary_engine=FORCED;"
    echo "  mysql> SELECT COUNT(*), AVG(ss_sales_price) FROM tpcds_sf1.store_sales;"
    echo ""
    echo "# Let MySQL optimizer choose:"
    echo "  mysql> SET use_secondary_engine=ON;"
    echo "  mysql> SELECT COUNT(*), AVG(ss_sales_price) FROM tpcds_sf1.store_sales;"
    echo ""
    echo "# Check which engine was used:"
    echo "  mysql> EXPLAIN SELECT COUNT(*) FROM tpcds_sf1.store_sales;"
    echo ""
fi

trap 'unset MYSQL_PWD' EXIT
