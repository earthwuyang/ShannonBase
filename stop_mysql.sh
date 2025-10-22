#!/bin/bash
# Stop MySQL/ShannonBase gracefully

echo "============================================================"
echo "Stopping MySQL/ShannonBase"
echo "============================================================"

# Try graceful shutdown first
echo "Attempting graceful shutdown..."
mysql -h 127.0.0.1 -P 3307 -u root -pshannonbase -e "SHUTDOWN;" 2>/dev/null && {
    echo "✅ Shutdown command sent"
    
    # Wait for MySQL to stop
    echo -n "Waiting for MySQL to stop"
    for i in {1..10}; do
        if ! pgrep -f "mysqld.*my.cnf" > /dev/null; then
            echo ""
            echo "✅ MySQL stopped successfully!"
            exit 0
        fi
        echo -n "."
        sleep 1
    done
}

# If graceful shutdown didn't work, try kill
echo ""
echo "Graceful shutdown failed, trying kill..."
pkill -f "mysqld.*my.cnf" 2>/dev/null && {
    sleep 2
    if ! pgrep -f "mysqld.*my.cnf" > /dev/null; then
        echo "✅ MySQL stopped with kill signal"
        exit 0
    fi
}

# Last resort - force kill
echo "Trying force kill..."
pkill -9 -f "bin/mysqld.*my.cnf" 2>/dev/null
sleep 1

if ! pgrep -f "bin/mysqld.*my.cnf" > /dev/null; then
    echo "✅ MySQL force stopped"
else
    echo "❌ Failed to stop MySQL!"
    echo "Running processes:"
    ps aux | grep mysqld | grep -v grep
    exit 1
fi

# Clean up socket files and PID file
echo "Cleaning up socket files..."
rm -f /home/wuy/ShannonBase/db/mysql.sock
rm -f /home/wuy/ShannonBase/db/mysqlx.sock
rm -f /home/wuy/ShannonBase/db/mysql.sock.lock
rm -f /home/wuy/ShannonBase/db/mysqlx.sock.lock
rm -f /home/wuy/*.pid
echo "✅ Cleanup complete"
