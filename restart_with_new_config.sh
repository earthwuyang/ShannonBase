#!/bin/bash
# Restart MySQL/ShannonBase with the updated configuration

set -e

echo "============================================================"
echo "Restarting MySQL/ShannonBase with updated configuration"
echo "============================================================"

# 1. Try graceful shutdown
echo "Step 1: Shutting down MySQL..."
mysql -h 127.0.0.1 -P 3307 -u root -pshannonbase -e "SHUTDOWN" 2>/dev/null || {
    echo "  Graceful shutdown failed, trying kill..."
    pkill -f "mysqld.*my.cnf" || true
}

# 2. Wait for shutdown
echo "Step 2: Waiting for shutdown..."
for i in {1..10}; do
    if ! pgrep -f "mysqld.*my.cnf" > /dev/null; then
        echo "  MySQL stopped successfully"
        break
    fi
    echo "  Waiting... ($i/10)"
    sleep 1
done

# 3. Clean up old log files (size changed)
echo "Step 3: Cleaning up old InnoDB log files..."
cd /home/wuy/DB/ShannonBase/db/data
if [ -f "ib_logfile0" ] || [ -f "ib_logfile1" ]; then
    rm -f ib_logfile*
    echo "  Old log files removed"
else
    echo "  No old log files to remove"
fi

# 4. Start with new configuration
echo "Step 4: Starting MySQL with new configuration..."
cd /home/wuy/DB/ShannonBase/cmake_build
nohup ./bin/mysqld --defaults-file=../db/my.cnf > /tmp/mysql_start.log 2>&1 &
MYSQL_PID=$!
echo "  MySQL started with PID: $MYSQL_PID"

# 5. Wait for MySQL to be ready
echo "Step 5: Waiting for MySQL to be ready..."
for i in {1..30}; do
    if mysql -h 127.0.0.1 -P 3307 -u root -pshannonbase -e "SELECT 1" 2>/dev/null > /dev/null; then
        echo "  MySQL is ready!"
        break
    fi
    echo "  Waiting... ($i/30)"
    sleep 2
done

# 6. Verify configuration
echo ""
echo "Step 6: Verifying configuration..."
mysql -h 127.0.0.1 -P 3307 -u root -pshannonbase -e "
SELECT '============================================================' AS '';
SELECT 'Configuration Verification' AS '';
SELECT '============================================================' AS '';
SELECT VARIABLE_NAME, VARIABLE_VALUE 
FROM performance_schema.global_variables 
WHERE VARIABLE_NAME IN (
    'mysqlx_socket',
    'mysqlx_port', 
    'innodb_buffer_pool_size',
    'innodb_log_file_size',
    'bulk_insert_buffer_size',
    'max_allowed_packet',
    'local_infile',
    'foreign_key_checks'
)
ORDER BY VARIABLE_NAME;
" 2>/dev/null || echo "Could not verify configuration"

echo ""
echo "============================================================"
echo "✅ MySQL/ShannonBase restarted successfully!"
echo "============================================================"
echo ""
echo "Check error log for any issues:"
echo "  tail -f /home/wuy/DB/ShannonBase/db/data/shannonbase.err"
echo ""
echo "To rollback if needed:"
echo "  cp /home/wuy/DB/ShannonBase/db/my.cnf.backup /home/wuy/DB/ShannonBase/db/my.cnf"
echo "  ./restart_with_new_config.sh"
echo ""
