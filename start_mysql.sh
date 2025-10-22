#!/bin/bash
# Start MySQL/ShannonBase with proper configuration

SHANNON_BASE="/home/wuy/ShannonBase"
# Use canonical path (runtime_output_directory is where CMake actually builds)
MYSQL_BIN="${SHANNON_BASE}/cmake_build/runtime_output_directory/mysqld"
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

# Clean up any stale socket files from crashed processes
echo "Cleaning up stale socket files..."
rm -f ${SHANNON_BASE}/db/mysql.sock
rm -f ${SHANNON_BASE}/db/mysqlx.sock
rm -f ${SHANNON_BASE}/db/mysql.sock.lock
rm -f ${SHANNON_BASE}/db/mysqlx.sock.lock

# Start MySQL
cd "${SHANNON_BASE}/cmake_build"
nohup ${MYSQL_BIN} --defaults-file=${CONFIG_FILE} --user=root > ${LOG_FILE} 2>&1 &
MYSQL_PID=$!

echo "Starting MySQL with PID: $MYSQL_PID"
echo "Log file: ${LOG_FILE}"

# Wait for MySQL to be ready
echo -n "Waiting for MySQL to start"
for i in {1..30}; do
    if mysql --socket=/home/wuy/ShannonBase/db/mysql.sock -u root --skip-password -e "SELECT 1" 2>/dev/null > /dev/null; then
        echo ""
        echo "✅ MySQL started successfully!"
        
        # Set root password to empty
        echo "Configuring root user without password..."
        mysql --socket=/home/wuy/ShannonBase/db/mysql.sock -u root --skip-password <<EOF 2>/dev/null
ALTER USER 'root'@'localhost' IDENTIFIED BY '';
CREATE USER IF NOT EXISTS 'root'@'%' IDENTIFIED BY '';
GRANT ALL PRIVILEGES ON *.* TO 'root'@'%' WITH GRANT OPTION;
CREATE USER IF NOT EXISTS 'root'@'127.0.0.1' IDENTIFIED BY '';
GRANT ALL PRIVILEGES ON *.* TO 'root'@'127.0.0.1' WITH GRANT OPTION;
FLUSH PRIVILEGES;
EOF
        
        echo ""
        echo "Connection info:"
        echo "  Host: 127.0.0.1"
        echo "  Port: 3307"
        echo "  User: root"
        echo "  Password: (none)"
        echo ""
        echo "Connect with:"
        echo "  mysql --socket=/home/wuy/ShannonBase/db/mysql.sock -u root"
        echo "  mysql -u root -P3307 -h127.0.0.1"
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
