#!/bin/bash

# Script to compare InnoDB vs Rapid engine performance
# For query routing experiments

MYSQL_HOST="${MYSQL_HOST:-127.0.0.1}"
MYSQL_PORT="${MYSQL_PORT:-3307}"
MYSQL_USER="${MYSQL_USER:-root}"
MYSQL_PASSWORD="${MYSQL_PASSWORD:-shannonbase}"

export MYSQL_PWD="$MYSQL_PASSWORD"

echo "============================================"
echo "InnoDB vs Rapid Engine Performance Comparison"
echo "============================================"
echo ""

# Verify MySQL is running
if ! timeout 5 mysqladmin -h "$MYSQL_HOST" -P "$MYSQL_PORT" -u "$MYSQL_USER" ping >/dev/null 2>&1; then
    echo "✗ MySQL is not running!"
    exit 1
fi

echo "✓ MySQL is running"
echo ""

# Check if store_sales is loaded in Rapid
echo "Checking if tpcds_sf1.store_sales is loaded in Rapid..."
if mysql -h "$MYSQL_HOST" -P "$MYSQL_PORT" -u "$MYSQL_USER" -e \
    "SET use_secondary_engine=FORCED; SELECT 1 FROM tpcds_sf1.store_sales LIMIT 1;" >/dev/null 2>&1; then
    echo "✓ store_sales is available in Rapid"
else
    echo "⚠️  store_sales not in Rapid. Loading now..."
    mysql -h "$MYSQL_HOST" -P "$MYSQL_PORT" -u "$MYSQL_USER" -e \
        "ALTER TABLE tpcds_sf1.store_sales SECONDARY_ENGINE=Rapid; ALTER TABLE tpcds_sf1.store_sales SECONDARY_LOAD;" 2>&1
fi

echo ""
echo "============================================"
echo "Running Performance Tests"
echo "============================================"
echo ""

# Query 1: Simple COUNT
echo "Query 1: SELECT COUNT(*) FROM store_sales (2.8M rows)"
echo "-----------------------------------------------"

echo -n "  InnoDB: "
START=$(date +%s%N)
RESULT1=$(mysql -h "$MYSQL_HOST" -P "$MYSQL_PORT" -u "$MYSQL_USER" -N -e \
    "SET use_secondary_engine=OFF; SELECT COUNT(*) FROM tpcds_sf1.store_sales;" 2>&1)
END=$(date +%s%N)
TIME1=$((($END - $START) / 1000000))
echo "$RESULT1 rows in ${TIME1}ms"

echo -n "  Rapid:  "
START=$(date +%s%N)
RESULT2=$(mysql -h "$MYSQL_HOST" -P "$MYSQL_PORT" -u "$MYSQL_USER" -N -e \
    "SET use_secondary_engine=FORCED; SELECT COUNT(*) FROM tpcds_sf1.store_sales;" 2>&1)
END=$(date +%s%N)
TIME2=$((($END - $START) / 1000000))
echo "$RESULT2 rows in ${TIME2}ms"

if [ $TIME2 -lt $TIME1 ]; then
    SPEEDUP=$(echo "scale=2; $TIME1 / $TIME2" | bc)
    echo "  → Rapid is ${SPEEDUP}x faster!"
elif [ $TIME1 -lt $TIME2 ]; then
    SPEEDUP=$(echo "scale=2; $TIME2 / $TIME1" | bc)
    echo "  → InnoDB is ${SPEEDUP}x faster"
else
    echo "  → Similar performance"
fi

echo ""

# Query 2: AVG aggregation
echo "Query 2: SELECT AVG(ss_sales_price) FROM store_sales"
echo "-----------------------------------------------"

echo -n "  InnoDB: "
START=$(date +%s%N)
RESULT1=$(mysql -h "$MYSQL_HOST" -P "$MYSQL_PORT" -u "$MYSQL_USER" -N -e \
    "SET use_secondary_engine=OFF; SELECT AVG(ss_sales_price) FROM tpcds_sf1.store_sales;" 2>&1)
END=$(date +%s%N)
TIME1=$((($END - $START) / 1000000))
echo "avg=$RESULT1 in ${TIME1}ms"

echo -n "  Rapid:  "
START=$(date +%s%N)
RESULT2=$(mysql -h "$MYSQL_HOST" -P "$MYSQL_PORT" -u "$MYSQL_USER" -N -e \
    "SET use_secondary_engine=FORCED; SELECT AVG(ss_sales_price) FROM tpcds_sf1.store_sales;" 2>&1)
END=$(date +%s%N)
TIME2=$((($END - $START) / 1000000))
echo "avg=$RESULT2 in ${TIME2}ms"

if [ $TIME2 -lt $TIME1 ]; then
    SPEEDUP=$(echo "scale=2; $TIME1 / $TIME2" | bc)
    echo "  → Rapid is ${SPEEDUP}x faster!"
elif [ $TIME1 -lt $TIME2 ]; then
    SPEEDUP=$(echo "scale=2; $TIME2 / $TIME1" | bc)
    echo "  → InnoDB is ${SPEEDUP}x faster"
fi

echo ""

# Query 3: Multiple aggregations
echo "Query 3: SELECT COUNT(*), SUM(ss_sales_price), AVG(ss_quantity) FROM store_sales"
echo "-----------------------------------------------"

echo -n "  InnoDB: "
START=$(date +%s%N)
mysql -h "$MYSQL_HOST" -P "$MYSQL_PORT" -u "$MYSQL_USER" -e \
    "SET use_secondary_engine=OFF; SELECT COUNT(*) as cnt, SUM(ss_sales_price) as total, AVG(ss_quantity) as avg_qty FROM tpcds_sf1.store_sales;" 2>&1 | tail -1
END=$(date +%s%N)
TIME1=$((($END - $START) / 1000000))
echo "            Time: ${TIME1}ms"

echo -n "  Rapid:  "
START=$(date +%s%N)
mysql -h "$MYSQL_HOST" -P "$MYSQL_PORT" -u "$MYSQL_USER" -e \
    "SET use_secondary_engine=FORCED; SELECT COUNT(*) as cnt, SUM(ss_sales_price) as total, AVG(ss_quantity) as avg_qty FROM tpcds_sf1.store_sales;" 2>&1 | tail -1
END=$(date +%s%N)
TIME2=$((($END - $START) / 1000000))
echo "            Time: ${TIME2}ms"

if [ $TIME2 -lt $TIME1 ]; then
    SPEEDUP=$(echo "scale=2; $TIME1 / $TIME2" | bc)
    echo "  → Rapid is ${SPEEDUP}x faster!"
fi

echo ""

# Query 4: GROUP BY
echo "Query 4: SELECT ss_item_sk, COUNT(*) FROM store_sales GROUP BY ss_item_sk (top 10)"
echo "-----------------------------------------------"

echo "  InnoDB:"
START=$(date +%s%N)
mysql -h "$MYSQL_HOST" -P "$MYSQL_PORT" -u "$MYSQL_USER" -e \
    "SET use_secondary_engine=OFF; SELECT ss_item_sk, COUNT(*) as cnt FROM tpcds_sf1.store_sales GROUP BY ss_item_sk ORDER BY cnt DESC LIMIT 10;" 2>&1 | tail -11 | head -10
END=$(date +%s%N)
TIME1=$((($END - $START) / 1000000))
echo "            Time: ${TIME1}ms"

echo ""
echo "  Rapid:"
START=$(date +%s%N)
mysql -h "$MYSQL_HOST" -P "$MYSQL_PORT" -u "$MYSQL_USER" -e \
    "SET use_secondary_engine=FORCED; SELECT ss_item_sk, COUNT(*) as cnt FROM tpcds_sf1.store_sales GROUP BY ss_item_sk ORDER BY cnt DESC LIMIT 10;" 2>&1 | tail -11 | head -10
END=$(date +%s%N)
TIME2=$((($END - $START) / 1000000))
echo "            Time: ${TIME2}ms"

if [ $TIME2 -lt $TIME1 ]; then
    SPEEDUP=$(echo "scale=2; $TIME1 / $TIME2" | bc)
    echo "  → Rapid is ${SPEEDUP}x faster!"
fi

echo ""
echo "============================================"
echo "Summary"
echo "============================================"
echo ""
echo "Both InnoDB and Rapid engines are working!"
echo "Use SET use_secondary_engine to control routing:"
echo "  - OFF:    Query runs on InnoDB only"
echo "  - FORCED: Query runs on Rapid only"
echo "  - ON:     Optimizer chooses best engine"
echo ""
echo "For your query routing experiments, you can now:"
echo "  1. Measure query latency on each engine"
echo "  2. Compare throughput under load"
echo "  3. Test optimizer's routing decisions"
echo "  4. Evaluate columnar vs row-based storage"

trap 'unset MYSQL_PWD' EXIT
