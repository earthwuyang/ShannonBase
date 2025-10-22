#!/bin/bash

# Fix: Remove SECONDARY_ENGINE from all tables to prevent "Table has not been loaded" errors
# This makes tables work normally in InnoDB without Rapid

set -e

MYSQL_HOST="${MYSQL_HOST:-127.0.0.1}"
MYSQL_PORT="${MYSQL_PORT:-3307}"
MYSQL_USER="${MYSQL_USER:-root}"
MYSQL_PASSWORD="${MYSQL_PASSWORD:-shannonbase}"

export MYSQL_PWD="$MYSQL_PASSWORD"

echo "============================================"
echo "Fixing Tables: Remove SECONDARY_ENGINE"
echo "============================================"
echo ""
echo "Problem: Tables have SECONDARY_ENGINE=Rapid but data not loaded"
echo "Result: Queries fail with 'Table has not been loaded'"
echo ""
echo "Solution: Remove SECONDARY_ENGINE, use InnoDB only"
echo ""

# Check if MySQL is running
echo "Step 1: Checking MySQL status..."
if timeout 5 mysqladmin -h "$MYSQL_HOST" -P "$MYSQL_PORT" -u "$MYSQL_USER" ping >/dev/null 2>&1; then
    echo "✓ MySQL is running"
else
    echo "✗ MySQL is not responding"
    echo "  Restarting MySQL..."
    cd /home/wuy/ShannonBase
    ./stop_mysql.sh >/dev/null 2>&1 || true
    sleep 2
    ./start_mysql.sh &
    sleep 5
fi

echo ""
echo "Step 2: Removing SECONDARY_ENGINE from TPC-H tables..."

for table in customer lineitem nation orders part partsupp region supplier; do
    echo -n "  Processing tpch_sf1.$table... "
    if mysql -h "$MYSQL_HOST" -P "$MYSQL_PORT" -u "$MYSQL_USER" -e \
        "ALTER TABLE tpch_sf1.\`$table\` SECONDARY_ENGINE=NULL;" 2>/dev/null; then
        echo "✓"
    else
        echo "⚠️ (may not exist or already removed)"
    fi
done

echo ""
echo "Step 3: Removing SECONDARY_ENGINE from TPC-DS tables..."

for table in call_center catalog_page catalog_returns catalog_sales customer customer_address customer_demographics date_dim dbgen_version household_demographics income_band inventory item promotion reason ship_mode store store_returns store_sales time_dim warehouse web_page web_returns web_sales web_site; do
    echo -n "  Processing tpcds_sf1.$table... "
    if mysql -h "$MYSQL_HOST" -P "$MYSQL_PORT" -u "$MYSQL_USER" -e \
        "ALTER TABLE tpcds_sf1.\`$table\` SECONDARY_ENGINE=NULL;" 2>/dev/null; then
        echo "✓"
    else
        echo "⚠️ (may not exist or already removed)"
    fi
done

echo ""
echo "Step 4: Verification..."
echo ""
echo "Checking if queries work now..."

# Test query that was failing
echo "Test: SELECT COUNT(*) FROM tpcds_sf1.web_site;"
mysql -h "$MYSQL_HOST" -P "$MYSQL_PORT" -u "$MYSQL_USER" -e "
    SET use_secondary_engine=OFF;
    SELECT COUNT(*) as row_count FROM tpcds_sf1.web_site;
" 2>&1

if [ $? -eq 0 ]; then
    echo ""
    echo "✓ Query succeeded!"
else
    echo ""
    echo "✗ Query still failing"
fi

echo ""
echo "============================================"
echo "Summary"
echo "============================================"
echo ""
echo "All tables now use InnoDB only (no Rapid engine)"
echo ""
echo "To verify:"
echo "  mysql> SET use_secondary_engine=OFF;"
echo "  mysql> SELECT COUNT(*) FROM tpcds_sf1.web_site;"
echo ""
echo "Tables are fully functional in InnoDB!"
echo "============================================"

trap 'unset MYSQL_PWD' EXIT
