#!/bin/bash
# Debug script to reproduce SECONDARY_LOAD crash
set -e

echo "============================================"
echo "MySQL Crash Debugging Script"
echo "============================================"

# Clean up any existing MySQL instances
echo "[1/5] Cleaning up existing MySQL processes..."
killall -9 mysqld 2>/dev/null || true
sleep 2
rm -f /home/wuy/ShannonBase/db/mysql.sock* /home/wuy/ShannonBase/db/mysqlx.sock* 2>/dev/null || true

# Start MySQL normally first
echo "[2/5] Starting MySQL normally..."
cd /home/wuy/ShannonBase
./start_mysql.sh

# Wait for MySQL to be ready
echo "[3/5] Waiting for MySQL to be ready..."
for i in {1..30}; do
    if mysql -uroot -pshannonbase --socket=/home/wuy/ShannonBase/db/mysql.sock -e "SELECT 1" 2>/dev/null >/dev/null; then
        echo "✓ MySQL is ready"
        break
    fi
    sleep 1
done

# Create a simple test case that triggers the crash
echo "[4/5] Creating test database and table..."
mysql -uroot -pshannonbase --socket=/home/wuy/ShannonBase/db/mysql.sock <<'EOF'
DROP DATABASE IF EXISTS crash_test;
CREATE DATABASE crash_test;
USE crash_test;

-- Create a simple table
CREATE TABLE test_table (
    id INT PRIMARY KEY,
    name VARCHAR(100),
    value INT
) ENGINE=InnoDB;

-- Insert some data
INSERT INTO test_table VALUES 
    (1, 'test1', 100),
    (2, 'test2', 200),
    (3, 'test3', 300);

-- Add SECONDARY_ENGINE
ALTER TABLE test_table SECONDARY_ENGINE=Rapid;

SELECT 'Table created and configured' as status;
EOF

echo "[5/5] Attempting SECONDARY_LOAD (may crash)..."
echo "Running: ALTER TABLE crash_test.test_table SECONDARY_LOAD;"

# This should trigger the crash based on previous error logs
mysql -uroot -pshannonbase --socket=/home/wuy/ShannonBase/db/mysql.sock <<'EOF' || echo "MySQL crashed or returned error"
USE crash_test;
ALTER TABLE test_table SECONDARY_LOAD;
SELECT 'SUCCESS: Table loaded into Rapid' as result;
EOF

# Check if MySQL is still alive
if mysql -uroot -pshannonbase --socket=/home/wuy/ShannonBase/db/mysql.sock -e "SELECT 1" 2>/dev/null >/dev/null; then
    echo "✓ MySQL survived - no crash occurred"
    echo "Checking table status..."
    mysql -uroot -pshannonbase --socket=/home/wuy/ShannonBase/db/mysql.sock -e "
        SELECT table_name, create_options 
        FROM information_schema.tables 
        WHERE table_schema='crash_test';
    "
else
    echo "✗ MySQL crashed! Check error log:"
    echo ""
    tail -100 /home/wuy/ShannonBase/db/data/shannonbase.err | grep -A 20 "Assertion failure" | tail -25
fi
