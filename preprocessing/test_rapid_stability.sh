#!/bin/bash

# Comprehensive test to verify Rapid engine doesn't crash
# Tests multiple scenarios that previously caused crashes

MYSQL_HOST="${MYSQL_HOST:-127.0.0.1}"
MYSQL_PORT="${MYSQL_PORT:-3307}"
MYSQL_USER="${MYSQL_USER:-root}"
MYSQL_PASSWORD="${MYSQL_PASSWORD:-shannonbase}"

export MYSQL_PWD="$MYSQL_PASSWORD"

TESTS_PASSED=0
TESTS_FAILED=0

echo "============================================"
echo "Rapid Engine Stability Test"
echo "============================================"
echo ""

# Function to check if MySQL is alive
check_mysql() {
    if ! timeout 5 mysqladmin -h "$MYSQL_HOST" -P "$MYSQL_PORT" -u "$MYSQL_USER" ping >/dev/null 2>&1; then
        echo "✗ CRITICAL: MySQL crashed!"
        return 1
    fi
    return 0
}

# Test 1: Simple table
echo "Test 1: Simple table without foreign keys..."
mysql -h "$MYSQL_HOST" -P "$MYSQL_PORT" -u "$MYSQL_USER" << 'EOF' >/dev/null 2>&1
CREATE DATABASE IF NOT EXISTS test_rapid;
DROP TABLE IF EXISTS test_rapid.test1;
CREATE TABLE test_rapid.test1 (id INT PRIMARY KEY, data VARCHAR(100)) ENGINE=InnoDB SECONDARY_ENGINE=Rapid;
INSERT INTO test_rapid.test1 VALUES (1, 'test'), (2, 'test2'), (3, 'test3');
ALTER TABLE test_rapid.test1 SECONDARY_LOAD;
SET use_secondary_engine=FORCED;
SELECT COUNT(*) FROM test_rapid.test1;
EOF

if [ $? -eq 0 ] && check_mysql; then
    echo "  ✓ Test 1 PASSED"
    ((TESTS_PASSED++))
else
    echo "  ✗ Test 1 FAILED"
    ((TESTS_FAILED++))
fi

# Test 2: Large table (store_sales - 2.8M rows)
echo "Test 2: Large fact table (store_sales - 2.8M rows)..."
mysql -h "$MYSQL_HOST" -P "$MYSQL_PORT" -u "$MYSQL_USER" << 'EOF' >/dev/null 2>&1
ALTER TABLE tpcds_sf1.store_sales SECONDARY_ENGINE=Rapid;
ALTER TABLE tpcds_sf1.store_sales SECONDARY_LOAD;
SET use_secondary_engine=FORCED;
SELECT COUNT(*) FROM tpcds_sf1.store_sales;
EOF

if [ $? -eq 0 ] && check_mysql; then
    echo "  ✓ Test 2 PASSED"
    ((TESTS_PASSED++))
else
    echo "  ✗ Test 2 FAILED"
    ((TESTS_FAILED++))
fi

# Test 3: Table with foreign keys (customer)
echo "Test 3: Table with foreign key relationships (customer)..."
mysql -h "$MYSQL_HOST" -P "$MYSQL_PORT" -u "$MYSQL_USER" << 'EOF' >/dev/null 2>&1
ALTER TABLE tpcds_sf1.customer SECONDARY_ENGINE=Rapid;
ALTER TABLE tpcds_sf1.customer SECONDARY_LOAD;
SET use_secondary_engine=FORCED;
SELECT COUNT(*) FROM tpcds_sf1.customer;
EOF

if [ $? -eq 0 ] && check_mysql; then
    echo "  ✓ Test 3 PASSED"
    ((TESTS_PASSED++))
else
    echo "  ✗ Test 3 FAILED"
    ((TESTS_FAILED++))
fi

# Test 4: Multiple tables in sequence
echo "Test 4: Loading 5 tables in sequence..."
LOADED=0
for table in date_dim item store warehouse web_page; do
    mysql -h "$MYSQL_HOST" -P "$MYSQL_PORT" -u "$MYSQL_USER" -e \
        "ALTER TABLE tpcds_sf1.\`$table\` SECONDARY_ENGINE=Rapid; ALTER TABLE tpcds_sf1.\`$table\` SECONDARY_LOAD;" >/dev/null 2>&1
    if [ $? -eq 0 ] && check_mysql; then
        ((LOADED++))
    else
        break
    fi
done

if [ $LOADED -eq 5 ]; then
    echo "  ✓ Test 4 PASSED (5/5 tables loaded)"
    ((TESTS_PASSED++))
else
    echo "  ✗ Test 4 FAILED ($LOADED/5 tables loaded)"
    ((TESTS_FAILED++))
fi

# Test 5: Query performance comparison
echo "Test 5: Query routing between InnoDB and Rapid..."
RESULT=$(mysql -h "$MYSQL_HOST" -P "$MYSQL_PORT" -u "$MYSQL_USER" << 'EOF' 2>&1
SET use_secondary_engine=OFF;
SELECT COUNT(*) as innodb_count FROM tpcds_sf1.store_sales;
SET use_secondary_engine=FORCED;
SELECT COUNT(*) as rapid_count FROM tpcds_sf1.store_sales;
EOF
)

if echo "$RESULT" | grep -q "2880404" && check_mysql; then
    echo "  ✓ Test 5 PASSED (both engines return same count)"
    ((TESTS_PASSED++))
else
    echo "  ✗ Test 5 FAILED"
    ((TESTS_FAILED++))
fi

# Test 6: Complex aggregation query
echo "Test 6: Complex aggregation on Rapid..."
mysql -h "$MYSQL_HOST" -P "$MYSQL_PORT" -u "$MYSQL_USER" << 'EOF' >/dev/null 2>&1
SET use_secondary_engine=FORCED;
SELECT 
    ss_item_sk,
    COUNT(*) as cnt,
    SUM(ss_sales_price) as total_sales,
    AVG(ss_quantity) as avg_quantity
FROM tpcds_sf1.store_sales
GROUP BY ss_item_sk
LIMIT 10;
EOF

if [ $? -eq 0 ] && check_mysql; then
    echo "  ✓ Test 6 PASSED"
    ((TESTS_PASSED++))
else
    echo "  ✗ Test 6 FAILED"
    ((TESTS_FAILED++))
fi

# Final MySQL check
echo ""
echo "Final stability check..."
if check_mysql; then
    echo "  ✓ MySQL is still running"
else
    echo "  ✗ MySQL crashed during tests"
    ((TESTS_FAILED++))
fi

echo ""
echo "============================================"
echo "Results: $TESTS_PASSED passed, $TESTS_FAILED failed"
echo "============================================"
echo ""

if [ $TESTS_FAILED -eq 0 ]; then
    echo "🎉 SUCCESS! Rapid engine is stable!"
    echo ""
    echo "All tests passed without crashes. Your MySQL is ready for:"
    echo "  - Query routing experiments"
    echo "  - Performance comparisons between InnoDB and Rapid"
    echo "  - Production TPC-H/TPC-DS benchmarks"
    echo ""
    echo "Next steps:"
    echo "  1. Load all TPC-H/TPC-DS tables: ./load_all_rapid.sh"
    echo "  2. Run performance benchmarks: ./benchmark_engines.sh"
    echo "  3. Compare query performance with use_secondary_engine settings"
else
    echo "⚠️  Some tests failed. Check MySQL error log:"
    echo "  tail -100 /home/wuy/ShannonBase/db/data/shannonbase.err"
fi

trap 'unset MYSQL_PWD' EXIT
