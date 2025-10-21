#!/bin/bash

# Test MySQL connection with the same config as setup_tpc_benchmarks.sh

MYSQL_HOST="${MYSQL_HOST:-127.0.0.1}"
MYSQL_PORT="${MYSQL_PORT:-3307}"
MYSQL_USER="${MYSQL_USER:-root}"
MYSQL_PASSWORD="${MYSQL_PASSWORD:-shannonbase}"

if [ -n "$MYSQL_PASSWORD" ]; then
    export MYSQL_PWD="$MYSQL_PASSWORD"
fi

MYSQL_CMD=(mysql -h "$MYSQL_HOST" -P "$MYSQL_PORT" -u "$MYSQL_USER")

echo "Testing MySQL connection..."
echo "  Host: $MYSQL_HOST"
echo "  Port: $MYSQL_PORT"
echo "  User: $MYSQL_USER"
echo ""

# Test connection
if "${MYSQL_CMD[@]}" -e "SELECT VERSION();" 2>&1; then
    echo ""
    echo "✓ Connection successful!"
    
    # Try to set local_infile
    echo ""
    echo "Testing local_infile setting..."
    if "${MYSQL_CMD[@]}" -e "SET GLOBAL local_infile = 1;" 2>&1; then
        echo "✓ Successfully set local_infile = 1"
    else
        echo "✗ Could not set local_infile"
    fi
else
    echo ""
    echo "✗ Connection failed!"
    exit 1
fi

unset MYSQL_PWD
