#!/bin/bash

# Script to rebuild ShannonBase with Rapid engine bug fix and test SECONDARY_LOAD

set -e

MYSQL_HOST="${MYSQL_HOST:-127.0.0.1}"
MYSQL_PORT="${MYSQL_PORT:-3307}"
MYSQL_USER="${MYSQL_USER:-root}"
MYSQL_PASSWORD="${MYSQL_PASSWORD:-shannonbase}"

export MYSQL_PWD="$MYSQL_PASSWORD"

echo "============================================"
echo "Rebuild ShannonBase with Rapid Engine Fix"
echo "============================================"
echo ""
echo "Bug Fixed: dict0dict.cc:3480 assertion failure"
echo "Solution: Handle case where FK tables not in cache"
echo ""

# Step 1: Stop MySQL
echo "Step 1: Stopping MySQL..."
cd /home/wuy/ShannonBase
./stop_mysql.sh >/dev/null 2>&1 || true
pkill -9 mysqld 2>/dev/null || true
sleep 2
echo "✓ MySQL stopped"
echo ""

# Step 2: Recompile InnoDB storage engine
echo "Step 2: Recompiling InnoDB storage engine with bug fix..."
echo "  This will take a few minutes..."
cd /home/wuy/ShannonBase/cmake_build

# Compile just the changed file and link
echo "  Compiling dict0dict.cc..."
if make -j10 2>&1 | tee /tmp/rebuild.log | grep -E "Error|error:|failed" && [ ${PIPESTATUS[0]} -ne 0 ]; then
    echo "✗ Compilation failed!"
    echo "  Check /tmp/rebuild.log for details"
    tail -50 /tmp/rebuild.log
    exit 1
fi

echo "✓ Compilation successful"
echo ""

# Step 3: Restart MySQL
echo "Step 3: Starting MySQL with fixed binary..."
cd /home/wuy/ShannonBase
./start_mysql.sh >/dev/null 2>&1 &

sleep 8

# Wait for MySQL to be ready
echo "  Waiting for MySQL to start..."
for i in {1..30}; do
    if timeout 2 mysqladmin -h "$MYSQL_HOST" -P "$MYSQL_PORT" -u "$MYSQL_USER" ping >/dev/null 2>&1; then
        echo "✓ MySQL started successfully"
        break
    fi
    if [ $i -eq 30 ]; then
        echo "✗ MySQL failed to start"
        tail -30 /home/wuy/ShannonBase/mysql_start.log
        exit 1
    fi
    sleep 1
done
echo ""

# Step 4: Test SECONDARY_LOAD on a simple table
echo "Step 4: Testing SECONDARY_LOAD (the moment of truth!)..."
echo ""

# First, ensure test table exists with SECONDARY_ENGINE
echo "  Creating test table with SECONDARY_ENGINE=Rapid..."
mysql -h "$MYSQL_HOST" -P "$MYSQL_PORT" -u "$MYSQL_USER" << 'EOF'
CREATE DATABASE IF NOT EXISTS test_rapid;
USE test_rapid;

DROP TABLE IF EXISTS test_table;

CREATE TABLE test_table (
    id INT PRIMARY KEY,
    name VARCHAR(100),
    value DECIMAL(10,2)
) ENGINE=InnoDB SECONDARY_ENGINE=Rapid;

INSERT INTO test_table VALUES 
    (1, 'Test1', 100.50),
    (2, 'Test2', 200.75),
    (3, 'Test3', 300.25);
EOF

if [ $? -ne 0 ]; then
    echo "✗ Failed to create test table"
    exit 1
fi

echo "✓ Test table created with data"
echo ""

# Now try SECONDARY_LOAD
echo "  Attempting SECONDARY_LOAD (this previously crashed)..."
SECONDARY_LOAD_OUTPUT=$(mysql -h "$MYSQL_HOST" -P "$MYSQL_PORT" -u "$MYSQL_USER" -e "
    ALTER TABLE test_rapid.test_table SECONDARY_LOAD;
    SELECT 'SECONDARY_LOAD succeeded!' as result;
" 2>&1)

SECONDARY_LOAD_EXIT=$?

echo "$SECONDARY_LOAD_OUTPUT"
echo ""

if [ $SECONDARY_LOAD_EXIT -eq 0 ]; then
    echo "🎉 ✓ SECONDARY_LOAD SUCCEEDED! Bug is fixed!"
    echo ""
    
    # Verify data is in Rapid
    echo "  Verifying data loaded into Rapid engine..."
    mysql -h "$MYSQL_HOST" -P "$MYSQL_PORT" -u "$MYSQL_USER" -e "
        SET use_secondary_engine=FORCED;
        SELECT COUNT(*) as row_count FROM test_rapid.test_table;
        SELECT * FROM test_rapid.test_table;
    " 2>&1
    
    if [ $? -eq 0 ]; then
        echo ""
        echo "🎉 ✓ Rapid engine is working! Queries execute on Rapid!"
    else
        echo ""
        echo "⚠️  SECONDARY_LOAD succeeded but queries still fail"
        echo "    May need additional investigation"
    fi
else
    echo "✗ SECONDARY_LOAD failed or MySQL crashed"
    echo ""
    echo "Checking if MySQL is still alive..."
    if timeout 2 mysqladmin -h "$MYSQL_HOST" -P "$MYSQL_PORT" -u "$MYSQL_USER" ping >/dev/null 2>&1; then
        echo "✓ MySQL is alive (SECONDARY_LOAD failed but didn't crash)"
        echo "  This is progress! Check error message above."
    else
        echo "✗ MySQL crashed - bug fix may not be complete"
        tail -50 /home/wuy/ShannonBase/db/data/shannonbase.err
    fi
fi

echo ""
echo "============================================"
echo "Next Steps"
echo "============================================"

if [ $SECONDARY_LOAD_EXIT -eq 0 ]; then
    echo ""
    echo "✓ Bug fix successful! Now load TPC-DS tables into Rapid:"
    echo ""
    echo "  1. First, re-add SECONDARY_ENGINE to existing tables:"
    echo "     cd /home/wuy/ShannonBase/preprocessing"
    echo "     ./add_secondary_engine_back.sh"
    echo ""
    echo "  2. Then load tables into Rapid:"
    echo "     ./load_into_rapid.sh"
    echo ""
    echo "  3. Test query routing:"
    echo "     mysql> SET use_secondary_engine=ON;"
    echo "     mysql> SELECT COUNT(*) FROM tpcds_sf1.web_site;"
    echo "     mysql> EXPLAIN SELECT COUNT(*) FROM tpcds_sf1.web_site;"
else
    echo ""
    echo "✗ Bug fix incomplete. Further investigation needed."
    echo "  Check /tmp/rebuild.log and shannonbase.err"
fi

trap 'unset MYSQL_PWD' EXIT
echo "============================================"
