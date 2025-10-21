#!/bin/bash
# Start MySQL/ShannonBase with proper configuration

SHANNON_BASE="/home/wuy/DB/ShannonBase"
MYSQL_BIN="${SHANNON_BASE}/cmake_build/bin/mysqld"
CONFIG_FILE="${SHANNON_BASE}/db/my.cnf"
LOG_FILE="${SHANNON_BASE}/mysql_start.log"

echo "============================================================"
echo "Starting MySQL/ShannonBase"
echo "============================================================"

# Check if MySQL is already running
if pgrep -f "bin/mysqld.*my.cnf" > /dev/null; then
    echo "⚠️  MySQL is already running!"
    echo "To restart, first run: ./stop_mysql.sh"
    exit 1
fi

# Start MySQL
cd "${SHANNON_BASE}/cmake_build"
nohup ${MYSQL_BIN} --defaults-file=${CONFIG_FILE} > ${LOG_FILE} 2>&1 &
MYSQL_PID=$!

echo "Starting MySQL with PID: $MYSQL_PID"
echo "Log file: ${LOG_FILE}"

# Wait for MySQL to be ready
echo -n "Waiting for MySQL to start"
for i in {1..30}; do
    if mysql -h 127.0.0.1 -P 3307 -u root -pshannonbase -e "SELECT 1" 2>/dev/null > /dev/null; then
        echo ""
        echo "✅ MySQL started successfully!"
        echo ""
        echo "Connection info:"
        echo "  Host: 127.0.0.1"
        echo "  Port: 3307"
        echo "  User: root"
        echo "  Password: shannonbase"
        echo ""
        echo "Connect with:"
        echo "  mysql -h 127.0.0.1 -P 3307 -u root -pshannonbase"
        echo ""
        exit 0
    fi
    echo -n "."
    sleep 2
done

echo ""
echo "❌ MySQL failed to start!"
echo "Check the log file: ${LOG_FILE}"
tail -20 ${LOG_FILE}
exit 1
