#!/bin/bash

# Fix script for MySQL crash issues during parallel data import
# This script addresses the assertion failure in os_parent_dir_fsync_posix

set -e

echo "========================================="
echo "MySQL Crash Fix Script"
echo "========================================="

# 1. Clean up zombie processes
echo "Step 1: Cleaning up zombie processes..."
./cleanup_zombies.sh 2>/dev/null || true

# 2. Stop any running MySQL instances
echo "Step 2: Stopping MySQL if running..."
./stop_mysql.sh 2>/dev/null || true
sleep 2

# 3. Clean up lock files
echo "Step 3: Cleaning up lock files..."
rm -f /home/wuy/ShannonBase/db/data/*.pid 2>/dev/null || true
rm -f /home/wuy/ShannonBase/db/mysql.sock* 2>/dev/null || true

# 4. Ensure proper permissions on data directory
echo "Step 4: Fixing data directory permissions..."
chmod 750 /home/wuy/ShannonBase/db/data
chmod -R 750 /home/wuy/ShannonBase/db/data/*

# 5. Start MySQL with reduced parallelism settings
echo "Step 5: Starting MySQL with safer settings..."

# Check if my_safe.cnf exists
if [ ! -f "/home/wuy/ShannonBase/db/my_safe.cnf" ]; then
    echo "Error: my_safe.cnf not found at /home/wuy/ShannonBase/db/my_safe.cnf"
    echo "Please ensure the configuration file exists."
    exit 1
fi

# Start MySQL with the safer configuration
echo "Starting MySQL with safer configuration from my_safe.cnf..."
/home/wuy/ShannonBase/cmake_build/runtime_output_directory/mysqld \
    --defaults-file=/home/wuy/ShannonBase/db/my_safe.cnf \
    --user=root &

sleep 5

# Check if MySQL is running
if mysqladmin -h 127.0.0.1 -P 3307 -u root -pshannonbase ping >/dev/null 2>&1; then
    echo "✓ MySQL started successfully with safer settings"
else
    echo "✗ Failed to start MySQL. Check error log:"
    tail -20 /home/wuy/ShannonBase/db/data/shannonbase.err
    exit 1
fi

echo ""
echo "========================================="
echo "Fixes Applied:"
echo "1. Cleaned up zombie processes"
echo "2. Fixed directory permissions" 
echo "3. Reduced parallelism settings"
echo "4. Disabled parallel DDL operations"
echo "5. Limited connection pool"
echo ""
echo "Next Steps:"
echo "1. Use modified import scripts with reduced parallelism"
echo "2. Monitor error log: tail -f /home/wuy/ShannonBase/db/data/shannonbase.err"
echo "3. Run imports with MAX_PARALLEL=2 instead of 5"
echo "========================================="
