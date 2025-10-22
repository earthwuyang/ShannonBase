#!/bin/bash

# Quick test script to check SECONDARY_LOAD errors

MYSQL_HOST="${MYSQL_HOST:-127.0.0.1}"
MYSQL_PORT="${MYSQL_PORT:-3307}"
MYSQL_USER="${MYSQL_USER:-root}"
MYSQL_PASSWORD="${MYSQL_PASSWORD:-shannonbase}"

export MYSQL_PWD="$MYSQL_PASSWORD"

echo "============================================"
echo "Testing SECONDARY_LOAD on a single table"
echo "============================================"
echo ""

# Test on date_dim (simple table, no data dependencies)
echo "Test 1: Checking if table has SECONDARY_ENGINE..."
mysql -h "$MYSQL_HOST" -P "$MYSQL_PORT" -u "$MYSQL_USER" -e "
    SHOW CREATE TABLE tpcds_sf1.date_dim\G
" 2>&1 | grep -i "SECONDARY_ENGINE"

echo ""
echo "Test 2: Checking FK constraints..."
mysql -h "$MYSQL_HOST" -P "$MYSQL_PORT" -u "$MYSQL_USER" -e "
    SELECT constraint_name, referenced_table_name 
    FROM information_schema.key_column_usage 
    WHERE table_schema='tpcds_sf1' 
    AND table_name='date_dim' 
    AND referenced_table_name IS NOT NULL;
"

echo ""
echo "Test 3: Checking current FK checks setting..."
mysql -h "$MYSQL_HOST" -P "$MYSQL_PORT" -u "$MYSQL_USER" -e "
    SELECT @@SESSION.foreign_key_checks, @@GLOBAL.foreign_key_checks;
"

echo ""
echo "Test 4: Attempting SECONDARY_LOAD..."
mysql -h "$MYSQL_HOST" -P "$MYSQL_PORT" -u "$MYSQL_USER" -e "
    SET SESSION FOREIGN_KEY_CHECKS=0;
    ALTER TABLE tpcds_sf1.date_dim SECONDARY_LOAD;
" 2>&1

EXIT_CODE=$?

echo ""
if [ $EXIT_CODE -eq 0 ]; then
    echo "✓ SECONDARY_LOAD succeeded!"
    
    # Check if data is in Rapid
    echo ""
    echo "Test 5: Verifying data in Rapid..."
    mysql -h "$MYSQL_HOST" -P "$MYSQL_PORT" -u "$MYSQL_USER" -e "
        SELECT table_name, engine, create_options, table_rows
        FROM information_schema.tables 
        WHERE table_schema='tpcds_sf1' AND table_name='date_dim';
    "
else
    echo "✗ SECONDARY_LOAD failed with exit code $EXIT_CODE"
fi

echo ""
echo "Test 6: Checking MySQL is still alive..."
if mysqladmin -h "$MYSQL_HOST" -P "$MYSQL_PORT" -u "$MYSQL_USER" -p"$MYSQL_PASSWORD" ping >/dev/null 2>&1; then
    echo "✓ MySQL is still running"
else
    echo "✗ MySQL appears to have crashed!"
fi

trap 'unset MYSQL_PWD' EXIT
echo ""
echo "============================================"
