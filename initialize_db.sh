#!/bin/bash
# Initialize MySQL database and configure root without password

SHANNON_BASE="/home/wuy/ShannonBase"
MYSQLD_BIN="${SHANNON_BASE}/cmake_build/bin/mysqld"
RUNTIME_MYSQLD_BIN="${SHANNON_BASE}/cmake_build/runtime_output_directory/mysqld"
CONFIG_FILE="${SHANNON_BASE}/db/my.cnf"
DATA_DIR="${SHANNON_BASE}/db/data"

echo "============================================================"
echo "MySQL/ShannonBase Database Initialization"
echo "============================================================"

# Check if MySQL is running
if pgrep -f "bin/mysqld.*my.cnf" > /dev/null; then
    echo "⚠️  MySQL is currently running. Stopping it first..."
    ${SHANNON_BASE}/stop_mysql.sh
    sleep 2
fi

# Backup existing data directory if it exists
if [ -d "${DATA_DIR}" ]; then
    BACKUP_DIR="${DATA_DIR}_backup_$(date +%Y%m%d_%H%M%S)"
    echo "⚠️  Data directory exists. Creating backup: ${BACKUP_DIR}"
    mv "${DATA_DIR}" "${BACKUP_DIR}"
fi

# Create fresh data directory
echo "Creating data directory: ${DATA_DIR}"
mkdir -p "${DATA_DIR}"

# Determine which mysqld binary to use
if [ -f "${MYSQLD_BIN}" ]; then
    MYSQLD="${MYSQLD_BIN}"
elif [ -f "${RUNTIME_MYSQLD_BIN}" ]; then
    MYSQLD="${RUNTIME_MYSQLD_BIN}"
else
    echo "❌ Error: mysqld binary not found!"
    echo "   Checked: ${MYSQLD_BIN}"
    echo "   Checked: ${RUNTIME_MYSQLD_BIN}"
    exit 1
fi

echo "Using mysqld binary: ${MYSQLD}"

# Initialize database
echo ""
echo "Initializing database..."
${MYSQLD} --defaults-file=${CONFIG_FILE} --initialize --user=${USER}

# Check if initialization succeeded
if [ $? -ne 0 ]; then
    echo "❌ Database initialization failed!"
    echo "Check the log: ${DATA_DIR}/shannonbase.err"
    exit 1
fi

# Extract temporary password from shannonbase.err (get the latest one)
ERROR_LOG="${DATA_DIR}/shannonbase.err"
TEMP_PASSWORD=$(grep "temporary password" ${ERROR_LOG} | tail -1 | awk '{print $NF}')

if [ -z "${TEMP_PASSWORD}" ]; then
    echo "❌ Failed to extract temporary password from ${ERROR_LOG}"
    exit 1
fi

echo "Temporary password extracted: ${TEMP_PASSWORD}"

echo ""
echo "✅ Database initialized successfully!"

# Start MySQL normally to reset password
echo ""
echo "Starting MySQL to reset password..."

# Start MySQL normally
nohup ${MYSQLD} --defaults-file=${CONFIG_FILE} --user=${USER} > /tmp/mysql_temp_init.log 2>&1 &
TEMP_PID=$!

echo "Waiting for MySQL to start..."
sleep 5

# Wait for socket to be available
for i in {1..30}; do
    if [ -S "${SHANNON_BASE}/db/mysql.sock" ]; then
        echo "MySQL socket is ready"
        break
    fi
    sleep 1
done

# Reset root password to empty using temporary password
echo ""
echo "Configuring root user without password..."
mysql --socket=${SHANNON_BASE}/db/mysql.sock -u root -p"${TEMP_PASSWORD}" --connect-expired-password <<EOF
ALTER USER 'root'@'localhost' IDENTIFIED BY '';
CREATE USER IF NOT EXISTS 'root'@'%' IDENTIFIED BY '';
GRANT ALL PRIVILEGES ON *.* TO 'root'@'%' WITH GRANT OPTION;
CREATE USER IF NOT EXISTS 'root'@'127.0.0.1' IDENTIFIED BY '';
GRANT ALL PRIVILEGES ON *.* TO 'root'@'127.0.0.1' WITH GRANT OPTION;
FLUSH PRIVILEGES;
EOF

if [ $? -eq 0 ]; then
    echo "✅ Root password configured (no password required)"
else
    echo "❌ Failed to configure root password"
fi

# Gracefully shutdown MySQL to ensure changes are saved
echo ""
echo "Shutting down MySQL gracefully to save changes..."
mysql --socket=${SHANNON_BASE}/db/mysql.sock -u root -e "SHUTDOWN;" 2>/dev/null
sleep 3

# Make sure it's stopped
if ps -p ${TEMP_PID} > /dev/null 2>&1; then
    echo "Force stopping MySQL..."
    kill -9 ${TEMP_PID} 2>/dev/null
fi
killall -9 mysqld 2>/dev/null
sleep 1

# Clean up temporary files
rm -f /tmp/mysql_init.log
rm -f /tmp/mysql_temp_init.log

echo ""
echo "============================================================"
echo "✅ Initialization Complete!"
echo "============================================================"
echo ""
echo "To start MySQL, run: ./start_mysql.sh"
echo ""
echo "Connect with:"
echo "  mysql --socket=/home/wuy/ShannonBase/db/mysql.sock -u root"
echo "  mysql -u root -P3307 -h127.0.0.1"
echo ""
