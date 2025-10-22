#!/bin/bash
# Reset root password to empty

SHANNON_BASE="/home/wuy/ShannonBase"
CONFIG_FILE="${SHANNON_BASE}/db/my.cnf"
TEMP_CONFIG="/tmp/my_temp.cnf"

echo "============================================================"
echo "Resetting root password"
echo "============================================================"

# Stop MySQL
echo "Stopping MySQL..."
${SHANNON_BASE}/stop_mysql.sh

# Create temporary config with skip-grant-tables
cp ${CONFIG_FILE} ${TEMP_CONFIG}
echo "skip-grant-tables" >> ${TEMP_CONFIG}

# Start MySQL with skip-grant-tables
echo "Starting MySQL in password reset mode..."
${SHANNON_BASE}/cmake_build/runtime_output_directory/mysqld --defaults-file=${TEMP_CONFIG} --user=$USER &
TEMP_PID=$!

# Wait for MySQL to start
sleep 5

# Reset root password
echo "Resetting root password..."
mysql --socket=${SHANNON_BASE}/db/mysql.sock -u root <<EOF
FLUSH PRIVILEGES;
ALTER USER 'root'@'localhost' IDENTIFIED BY '';
CREATE USER IF NOT EXISTS 'root'@'%' IDENTIFIED BY '';
GRANT ALL PRIVILEGES ON *.* TO 'root'@'%' WITH GRANT OPTION;
CREATE USER IF NOT EXISTS 'root'@'127.0.0.1' IDENTIFIED BY '';
GRANT ALL PRIVILEGES ON *.* TO 'root'@'127.0.0.1' WITH GRANT OPTION;
FLUSH PRIVILEGES;
EOF

# Stop temporary MySQL
echo "Stopping temporary MySQL..."
kill $TEMP_PID
sleep 2
killall -9 mysqld 2>/dev/null

# Clean up
rm ${TEMP_CONFIG}

# Start MySQL normally
echo "Starting MySQL normally..."
${SHANNON_BASE}/start_mysql.sh

echo "✅ Root password reset complete!"
