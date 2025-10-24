# ASan Quick Start Guide

This is a condensed version of the full ASan build strategy. For complete details, see `ASAN_BUILD_STRATEGY.md`.

## Prerequisites

- GCC 11+ (already installed: GCC 11.2.0)
- Python 3 with mysql-connector
- 30GB disk space for ASan build
- 2+ CPU cores for reasonable build time

## Quick Start (5 Steps)

### Step 1: Build with ASan (30-60 minutes)

```bash
cd /home/wuy/ShannonBase
./run_cmake_asan.sh
cd cmake_build_asan
make -j$(nproc)
make install
```

### Step 2: Initialize ASan Server

```bash
# Set paths
export SHANNON_ASAN_BIN="/home/wuy/DB/ShannonBase/shannon_bin_asan"
export SHANNON_ASAN_DATA="/home/wuy/DB/ShannonBase/db/data_asan"

# Initialize data directory
rm -rf ${SHANNON_ASAN_DATA}
${SHANNON_ASAN_BIN}/bin/mysqld --initialize-insecure \
  --basedir=${SHANNON_ASAN_BIN} \
  --datadir=${SHANNON_ASAN_DATA} \
  --user=$(whoami)
```

### Step 3: Start ASan Server

```bash
# Source ASan environment
source /home/wuy/ShannonBase/asan_env.sh

# Start server
${SHANNON_ASAN_BIN}/bin/mysqld \
  --basedir=${SHANNON_ASAN_BIN} \
  --datadir=${SHANNON_ASAN_DATA} \
  --port=3308 \
  --socket=/tmp/mysql_asan.sock \
  --user=$(whoami) \
  --log-error=${SHANNON_ASAN_DATA}/error.log &

# Wait and verify
sleep 5
${SHANNON_ASAN_BIN}/bin/mysql -uroot -h127.0.0.1 -P3308 -e "SELECT VERSION()"
```

### Step 4: Setup Test Environment

```bash
python3 /home/wuy/ShannonBase/test_connection_crash.py \
  --port 3308 \
  --setup \
  --rows 10000
```

### Step 5: Run Crash Reproducer

```bash
# Open separate terminal for log monitoring:
tail -f /home/wuy/ShannonBase/asan_logs/asan.*

# In main terminal, run test:
python3 /home/wuy/ShannonBase/test_connection_crash.py \
  --port 3308 \
  --iterations 200 \
  --query-type rapid
```

## Expected Output

**If bug is present:**
- Server crashes after 100-200 iterations
- ASan prints detailed report to terminal
- Log file contains full stack trace

**Example ASan report:**
```
=================================================================
==12345==ERROR: AddressSanitizer: heap-use-after-free on address 0x...
READ of size 8 at 0x7f1234567890 thread T0
    #0 in Rapid_connection::close() rapid_connection.cc:123
    #1 in Rapid_share::close_connection() rapid_share.cc:456
    ...
freed by thread T0 here:
    #0 in operator delete(void*) ...
    #1 in Rapid_connection::~Rapid_connection() rapid_connection.cc:89
    ...
SUMMARY: AddressSanitizer: heap-use-after-free rapid_connection.cc:123
==12345==ABORTING
```

## What to Do with ASan Report

1. **Identify error type**: `heap-use-after-free`, `buffer-overflow`, etc.
2. **Find bug location**: File and line number in "READ/WRITE at" section
3. **Check when freed**: Look at "freed by thread" stack trace
4. **Check when allocated**: Look at "previously allocated" stack trace
5. **Analyze object lifetime**: Is there a ownership/reference counting bug?

## Common Commands

```bash
# Stop ASan server
${SHANNON_ASAN_BIN}/bin/mysqladmin -uroot -P3308 shutdown

# Kill if unresponsive
pkill -9 -f "mysqld.*3308"

# Check ASan logs
ls -lh /home/wuy/ShannonBase/asan_logs/

# Extract crash reports
grep -A 50 "ERROR: AddressSanitizer" /home/wuy/ShannonBase/asan_logs/asan.*

# Re-run test with more iterations
python3 test_connection_crash.py --port 3308 --iterations 500
```

## Troubleshooting

### Build fails with sanitizer error
```bash
# Ensure GCC is used
export CC=gcc
export CXX=g++
rm -rf cmake_build_asan
./run_cmake_asan.sh
```

### Server won't start
```bash
# Check port conflict
netstat -tuln | grep 3308
fuser -k 3308/tcp

# Check error log
tail -100 ${SHANNON_ASAN_DATA}/error.log
```

### No crash occurs
```bash
# Increase iterations
python3 test_connection_crash.py --port 3308 --iterations 1000

# Try different query type
python3 test_connection_crash.py --port 3308 --query-type complex

# Verify Rapid is actually used
mysql -uroot -P3308 -e "
SET SESSION use_secondary_engine=FORCED;
EXPLAIN SELECT * FROM test_rapid.test_table LIMIT 1;
" | grep -i rapid
```

## File Locations

| File | Location |
|------|----------|
| Full strategy guide | `/home/wuy/ShannonBase/ASAN_BUILD_STRATEGY.md` |
| ASan build script | `/home/wuy/ShannonBase/run_cmake_asan.sh` |
| ASan environment | `/home/wuy/ShannonBase/asan_env.sh` |
| Test script | `/home/wuy/ShannonBase/test_connection_crash.py` |
| ASan logs | `/home/wuy/ShannonBase/asan_logs/` |
| ASan binary | `/home/wuy/DB/ShannonBase/shannon_bin_asan/` |
| ASan data | `/home/wuy/DB/ShannonBase/db/data_asan/` |

## Next Steps After Finding Bug

1. Examine source code at reported line number
2. Check object lifecycle and ownership
3. Look for reference counting bugs
4. Check for double-free or premature deletion
5. Implement fix
6. Rebuild with ASan: `cd cmake_build_asan && make -j$(nproc) && make install`
7. Restart server and re-test
8. Run extended test: `--iterations 2000`

## Performance Notes

- ASan build is 2-5x slower than normal build
- Uses 2-3x more memory
- Binary is ~3x larger
- This is normal and expected for ASan

## Get Help

For detailed information on:
- ASan report interpretation → See Part 6 in `ASAN_BUILD_STRATEGY.md`
- Advanced debugging techniques → See Part 7 in `ASAN_BUILD_STRATEGY.md`
- Common Rapid engine patterns → See Appendix in `ASAN_BUILD_STRATEGY.md`
