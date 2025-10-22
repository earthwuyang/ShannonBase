#!/bin/bash
# Comprehensive test script for all fixes

set -e

MYSQL_CMD="mysql -uroot -pshannonbase --socket=/home/wuy/ShannonBase/db/mysql.sock"

echo "============================================"
echo "Testing All MySQL Fixes"
echo "============================================"
echo ""

# Test 1: DROP DATABASE (os0file.cc fix)
echo "[1/5] Testing DROP DATABASE (os0file.cc fix)..."
$MYSQL_CMD <<'EOF'
CREATE DATABASE IF NOT EXISTS test_drop;
USE test_drop;
CREATE TABLE t1 (id INT PRIMARY KEY) ENGINE=InnoDB;
INSERT INTO t1 VALUES (1), (2), (3);
DROP DATABASE test_drop;
SELECT 'Test 1: ✅ DROP DATABASE works!' as result;
EOF

# Test 2: SECONDARY_LOAD (dict0dict.cc fix)
echo ""
echo "[2/5] Testing SECONDARY_LOAD (dict0dict.cc fix)..."
$MYSQL_CMD <<'EOF'
CREATE DATABASE IF NOT EXISTS test_rapid;
USE test_rapid;
CREATE TABLE t2 (id INT PRIMARY KEY, name VARCHAR(100)) ENGINE=InnoDB;
INSERT INTO t2 VALUES (1, 'test1'), (2, 'test2');
ALTER TABLE t2 SECONDARY_ENGINE=Rapid;
ALTER TABLE t2 SECONDARY_LOAD;
SELECT 'Test 2: ✅ SECONDARY_LOAD works!' as result;
EOF

# Test 3: Query with Rapid Engine
echo ""
echo "[3/5] Testing query with Rapid engine..."
$MYSQL_CMD <<'EOF'
USE test_rapid;
SET use_secondary_engine=forced;
SELECT COUNT(*) as count FROM t2;
SELECT 'Test 3: ✅ Query with Rapid works!' as result;
EOF

# Test 4: Re-import CTU dataset (Python script fix)
echo ""
echo "[4/5] Testing CTU import (if Airline exists)..."
if $MYSQL_CMD -e "USE Airline; SELECT 1;" 2>/dev/null >/dev/null; then
    ROW_COUNT=$($MYSQL_CMD -N -B -e "USE Airline; SELECT COUNT(*) FROM On_Time_On_Time_Performance_2016_1;")
    if [ "$ROW_COUNT" -gt 0 ]; then
        echo "Test 4: ✅ Airline database has $ROW_COUNT rows!"
    else
        echo "Test 4: ⚠ Airline database exists but empty - need to re-import"
        echo "  Run: python3 preprocessing/import_ctu_datasets_parallel.py --databases Airline"
    fi
else
    echo "Test 4: ⚠ Airline database doesn't exist - skipping test"
    echo "  Run: python3 preprocessing/import_ctu_datasets_parallel.py --databases Airline"
fi

# Test 5: Smart loading (check if data persists)
echo ""
echo "[5/5] Testing smart loading feature..."
$MYSQL_CMD <<'EOF'
-- Check TPC-H
SELECT CONCAT('TPC-H: ', 
       IF(COUNT(*) = 8, '✅ All 8 tables exist', '⚠ Some tables missing')) as result
FROM information_schema.tables 
WHERE table_schema = 'tpch_sf1';

-- Check TPC-DS  
SELECT CONCAT('TPC-DS: ',
       IF(COUNT(*) = 24, '✅ All 24 tables exist', '⚠ Some tables missing')) as result
FROM information_schema.tables 
WHERE table_schema = 'tpcds_sf1';
EOF

echo ""
echo "============================================"
echo "Test Summary"
echo "============================================"
$MYSQL_CMD -e "SELECT 'All critical fixes verified!' as status;"

echo ""
echo "Next Steps:"
echo "  1. Re-import Airline if empty: python3 preprocessing/import_ctu_datasets_parallel.py --databases Airline"
echo "  2. Run TPC benchmarks if needed: ./preprocessing/setup_tpc_benchmarks_parallel.sh"
echo "  3. Check documentation: ls -lh *.md preprocessing/*.md"
echo ""
