#!/bin/bash
# Start mysqld under gdb to catch crashes
# This script properly handles child processes to avoid zombies

# Trap to ensure cleanup
cleanup() {
    echo "Cleaning up gdb session..."
    # Kill any remaining mysqld processes started by this session
    pkill -P $$ mysqld 2>/dev/null || true
    wait 2>/dev/null || true
}
trap cleanup EXIT INT TERM

cd /home/wuy/ShannonBase/cmake_build

# Start gdb with proper cleanup
exec gdb -ex "set pagination off" \
    -ex "set logging file /home/wuy/ShannonBase/db/gdb_crash.log" \
    -ex "set logging on" \
    -ex "set logging overwrite on" \
    -ex "handle SIGPIPE nostop noprint pass" \
    -ex "run --defaults-file=/home/wuy/ShannonBase/db/my.cnf --user=root" \
    -ex "bt full" \
    -ex "info registers" \
    -ex "thread apply all bt" \
    -ex "quit" \
    /home/wuy/ShannonBase/cmake_build/runtime_output_directory/mysqld
