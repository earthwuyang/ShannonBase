#!/bin/bash

# Complete script to add SECONDARY_ENGINE=Rapid and load all tables

MYSQL_HOST="${MYSQL_HOST:-127.0.0.1}"
MYSQL_PORT="${MYSQL_PORT:-3307}"
MYSQL_USER="${MYSQL_USER:-root}"
MYSQL_PASSWORD="${MYSQL_PASSWORD:-shannonbase}"

export MYSQL_PWD="$MYSQL_PASSWORD"

echo "============================================"
echo "Enable Rapid Engine on All Tables"
echo "============================================"
echo ""

# TPC-H tables
echo "Step 1: Adding SECONDARY_ENGINE to TPC-H tables and loading..."
TPCH_SUCCESS=0

for table in customer lineitem nation orders part partsupp region supplier; do
    echo -n "  $table... "
    
    # Add SECONDARY_ENGINE
    if ! mysql -h "$MYSQL_HOST" -P "$MYSQL_PORT" -u "$MYSQL_USER" -e \
        "ALTER TABLE tpch_sf1.\`$table\` SECONDARY_ENGINE=Rapid;" 2>/dev/null; then
        echo "✗ (failed to add SECONDARY_ENGINE)"
        continue
    fi
    
    # Load data
    if timeout 120 mysql -h "$MYSQL_HOST" -P "$MYSQL_PORT" -u "$MYSQL_USER" -e \
        "ALTER TABLE tpch_sf1.\`$table\` SECONDARY_LOAD;" 2>/dev/null; then
        echo "✓"
        ((TPCH_SUCCESS++))
    else
        echo "⚠️  (SECONDARY_ENGINE added, but SECONDARY_LOAD failed)"
    fi
    sleep 1
done

echo "  TPC-H: $TPCH_SUCCESS/8 successfully loaded into Rapid"
echo ""

# TPC-DS tables  
echo "Step 2: Adding SECONDARY_ENGINE to TPC-DS tables and loading..."
TPCDS_SUCCESS=0

for table in call_center catalog_page catalog_returns catalog_sales customer customer_address customer_demographics date_dim dbgen_version household_demographics income_band inventory item promotion reason ship_mode store store_returns store_sales time_dim warehouse web_page web_returns web_sales web_site; do
    echo -n "  $table... "
    
    # Add SECONDARY_ENGINE
    if ! mysql -h "$MYSQL_HOST" -P "$MYSQL_PORT" -u "$MYSQL_USER" -e \
        "ALTER TABLE tpcds_sf1.\`$table\` SECONDARY_ENGINE=Rapid;" 2>/dev/null; then
        echo "✗ (failed to add SECONDARY_ENGINE)"
        continue
    fi
    
    # Load data
    if timeout 120 mysql -h "$MYSQL_HOST" -P "$MYSQL_PORT" -u "$MYSQL_USER" -e \
        "ALTER TABLE tpcds_sf1.\`$table\` SECONDARY_LOAD;" 2>/dev/null; then
        echo "✓"
        ((TPCDS_SUCCESS++))
    else
        echo "⚠️  (SECONDARY_ENGINE added, but SECONDARY_LOAD failed)"
    fi
    sleep 1
done

echo "  TPC-DS: $TPCDS_SUCCESS/25 successfully loaded into Rapid"
echo ""

TOTAL=$((TPCH_SUCCESS + TPCDS_SUCCESS))

echo "============================================"
echo "Summary: $TOTAL/33 tables loaded into Rapid"
echo "============================================"
echo ""

if [ $TOTAL -gt 0 ]; then
    echo "✓ Success! Testing query routing..."
    echo ""
    
    # Test queries
    echo "Test 1: Query on InnoDB:"
    mysql -h "$MYSQL_HOST" -P "$MYSQL_PORT" -u "$MYSQL_USER" << 'EOSQL'
SET use_secondary_engine=OFF;
SELECT COUNT(*) as count_innodb FROM tpcds_sf1.store_sales;
EOSQL
    
    echo ""
    echo "Test 2: Query on Rapid:"
    mysql -h "$MYSQL_HOST" -P "$MYSQL_PORT" -u "$MYSQL_USER" << 'EOSQL'
SET use_secondary_engine=FORCED;
SELECT COUNT(*) as count_rapid FROM tpcds_sf1.store_sales;
EOSQL
    
    echo ""
    echo "🎉 Rapid engine is working!"
    echo ""
    echo "You can now compare performance:"
    echo "  # InnoDB: SET use_secondary_engine=OFF;"
    echo "  # Rapid:  SET use_secondary_engine=FORCED;"
    echo "  # Auto:   SET use_secondary_engine=ON;"
fi

trap 'unset MYSQL_PWD' EXIT
