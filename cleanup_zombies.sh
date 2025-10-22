#!/bin/bash
# Cleanup script for zombie processes and stale resources

echo "=========================================="
echo "ShannonBase Zombie Cleanup Utility"
echo "=========================================="

# Kill all mysqld processes (including zombies)
echo "1. Killing all mysqld processes..."
pkill -9 mysqld 2>/dev/null
sleep 2

# Note: Zombies can't be killed directly, but killing their parent would reap them
# Since PPID=1 (init), we need init to reap them, which happens automatically over time

# Remove stale socket files
echo "2. Removing stale socket files..."
rm -f /home/wuy/ShannonBase/db/mysql*.sock*
rm -f /tmp/mysql*.sock*

# Remove PID files
echo "3. Removing stale PID files..."
rm -f /home/wuy/ShannonBase/db/data/*.pid
rm -f /home/wuy/*.pid

# Check for remaining zombies
echo ""
echo "4. Checking for remaining zombie mysqld processes..."
ZOMBIES=$(ps aux | grep mysqld | grep defunct | wc -l)
if [ $ZOMBIES -gt 0 ]; then
    echo "⚠️  Warning: $ZOMBIES zombie mysqld processes still exist"
    echo "These will be automatically reaped by init (PID 1) eventually"
    echo ""
    ps aux | grep mysqld | grep defunct
else
    echo "✅ No zombie mysqld processes found"
fi

echo ""
echo "=========================================="
echo "Cleanup complete! You can now start MySQL"
echo "=========================================="
