# AddressSanitizer (ASan) Build Strategy for ShannonBase Rapid Engine Crash

## Executive Summary

This document provides a comprehensive strategy for building and testing ShannonBase with AddressSanitizer to debug a memory corruption issue in the Rapid engine that manifests after 100-200 connection cycles.

**System Information:**
- Base: MySQL 8.0 with custom Rapid (column-store) engine
- Compiler: GCC 11.2.0 (ASan supported)
- Current build: Release mode without instrumentation
- Issue: Crash after repeated connection cycles (memory corruption suspected)

---

## Part 1: Build Configuration Analysis

### Current Build Configuration

**File:** `/home/wuy/ShannonBase/run_cmake.sh`

Current configuration uses:
- `CMAKE_BUILD_TYPE=RELEASE`
- `WITH_DEBUG=0`
- Boost: `/home/wuy/software/boost_1_77_0`
- Port: 3307
- System SSL

**CMake ASan Support:** ✅ Available in `CMakeLists.txt` (lines 1213-1246)
- `WITH_ASAN`: Enable AddressSanitizer
- `WITH_ASAN_SCOPE`: Enable use-after-scope detection (recommended)
- `WITH_LSAN`: Leak Sanitizer (included with ASan on Linux)
- Automatic optimization flags: `-O1 -fno-inline` for better stack traces

---

## Part 2: ASan Build Instructions

### Step 1: Create ASan Build Script

Create `/home/wuy/ShannonBase/run_cmake_asan.sh`:

```bash
#!/bin/bash
# ShannonBase ASan Build Configuration
# For debugging Rapid engine memory corruption

SHANNON_BASE_DIR="/home/wuy/DB/ShannonBase"
SHANNON_INSTALL_DIR="${SHANNON_BASE_DIR}/shannon_bin_asan"

# Create separate build directory for ASan
mkdir -p cmake_build_asan

cd cmake_build_asan && cmake ../ \
  -DWITH_BOOST=/home/wuy/software/boost_1_77_0 \
  -DCMAKE_BUILD_TYPE=Debug \
  -DCMAKE_INSTALL_PREFIX=${SHANNON_INSTALL_DIR} \
  -DMYSQL_DATADIR=${SHANNON_BASE_DIR}/db/data_asan \
  -DSYSCONFDIR=${SHANNON_BASE_DIR}/db \
  -DMYSQL_UNIX_ADDR=/tmp/mysql_asan.sock \
  -DWITH_EMBEDDED_SERVER=OFF \
  -DWITH_MYISAM_STORAGE_ENGINE=1 \
  -DWITH_INNOBASE_STORAGE_ENGINE=1 \
  -DWITH_PARTITION_STORAGE_ENGINE=1 \
  -DMYSQL_TCP_PORT=3308 \
  -DENABLED_LOCAL_INFILE=1 \
  -DEXTRA_CHARSETS=all \
  -DWITH_PROTOBUF=bundled \
  -DWITH_SSL=system \
  -DDEFAULT_SET=community \
  -DWITH_UNIT_TESTS=OFF \
  -DWITH_DEBUG=1 \
  -DWITH_ASAN=ON \
  -DWITH_ASAN_SCOPE=ON \
  -DOPTIMIZE_SANITIZER_BUILDS=ON

# Build with parallel jobs (adjust -j based on CPU cores)
echo "Configuration complete. Building with ASan..."
echo "Build command: make -j$(nproc) && make install"
```

**Key Changes from Original:**
1. **CMAKE_BUILD_TYPE=Debug**: Required for maximum symbol information
2. **WITH_DEBUG=1**: Enable debug symbols and assertions
3. **WITH_ASAN=ON**: Enable AddressSanitizer
4. **WITH_ASAN_SCOPE=ON**: Detect use-after-scope bugs
5. **OPTIMIZE_SANITIZER_BUILDS=ON**: Add `-O1 -fno-inline` for readable stack traces
6. **Separate directories**: Avoid conflicts with release build
7. **Different port (3308)**: Run alongside production instance
8. **Separate data directory**: `data_asan` for clean testing

### Step 2: Build Commands

```bash
# Make script executable
chmod +x /home/wuy/ShannonBase/run_cmake_asan.sh

# Clean any previous ASan build
rm -rf /home/wuy/ShannonBase/cmake_build_asan

# Run CMake configuration
cd /home/wuy/ShannonBase
./run_cmake_asan.sh

# Build (this will take longer than release build)
cd cmake_build_asan
make -j$(nproc)

# Install
make install

# Expected build time: 30-60 minutes (vs 15-30 for release)
# Binary size: ~3-5x larger than release build
```

### Step 3: Verify ASan Build

```bash
# Check if ASan is linked
ldd /home/wuy/DB/ShannonBase/shannon_bin_asan/bin/mysqld | grep asan

# Should see: libasan.so.6 => /usr/lib/x86_64-linux-gnu/libasan.so.6

# Check binary for ASan symbols
nm /home/wuy/DB/ShannonBase/shannon_bin_asan/bin/mysqld | grep -i asan | head -5

# Should see: __asan_* symbols
```

---

## Part 3: ASan Runtime Configuration

### ASan Environment Variables

Create `/home/wuy/ShannonBase/asan_env.sh`:

```bash
#!/bin/bash
# AddressSanitizer Runtime Configuration
# Optimized for detecting connection lifecycle memory corruption

export ASAN_OPTIONS="
# Core Detection Options
detect_leaks=1:\
detect_stack_use_after_return=1:\
check_initialization_order=1:\
detect_invalid_pointer_pairs=2:\

# Output Configuration
log_path=/home/wuy/ShannonBase/asan_logs/asan:\
log_exe_name=1:\
print_stats=1:\
print_scariness=1:\

# Stack Trace Configuration
symbolize=1:\
fast_unwind_on_malloc=0:\
malloc_context_size=30:\

# Verbosity and Debugging
verbosity=1:\
print_summary=1:\
print_module_map=1:\

# Crash Behavior
abort_on_error=1:\
halt_on_error=0:\

# Memory Configuration
quarantine_size_mb=256:\
max_redzone=256:\

# Specific Detections for Connection Issues
detect_odr_violation=1:\
strict_string_checks=1:\
strict_init_order=1
"

export LSAN_OPTIONS="
# Leak Sanitizer (runs at exit or on demand)
suppressions=/home/wuy/ShannonBase/lsan_suppressions.txt:\
print_suppressions=0:\
use_poisoned=1:\
use_registers=1:\
use_stacks=1:\
use_globals=1
"

# Ensure logs directory exists
mkdir -p /home/wuy/ShannonBase/asan_logs

echo "ASan environment configured:"
echo "  - Logs: /home/wuy/ShannonBase/asan_logs/asan.*"
echo "  - Leak detection: ENABLED"
echo "  - Stack traces: FULL (slow but detailed)"
echo "  - Quarantine: 256MB (catches use-after-free)"
```

### Create Leak Suppressions File

Some MySQL internals may have known "acceptable" leaks. Create `/home/wuy/ShannonBase/lsan_suppressions.txt`:

```
# Suppress known MySQL shutdown leaks (optional - start without suppressions)
# leak:my_thread_global_init
# leak:_dl_allocate_tls

# Add suppressions here only after confirming they are not related to the crash
```

---

## Part 4: Minimal Crash Reproducer Script

### Connection Lifecycle Test Script

Create `/home/wuy/ShannonBase/test_connection_crash.py`:

```python
#!/usr/bin/env python3
"""
Minimal reproducer for Rapid engine connection lifecycle crash.
Tests connection open/close cycles with Rapid engine queries.
"""

import mysql.connector
import time
import sys
import argparse
from datetime import datetime

def test_connection_lifecycle(config, iterations=200, query_type='simple'):
    """
    Test connection lifecycle with various query types.

    Args:
        config: MySQL connection config
        iterations: Number of connection cycles (default 200 to trigger crash)
        query_type: 'simple', 'rapid', or 'complex'
    """

    queries = {
        'simple': "SELECT 1",
        'rapid': """
            SET SESSION use_secondary_engine = FORCED;
            SELECT COUNT(*) FROM test_table;
        """,
        'complex': """
            SET SESSION use_secondary_engine = FORCED;
            SELECT t1.col1, COUNT(*), AVG(t1.col2)
            FROM test_table t1
            JOIN test_table t2 ON t1.id = t2.id
            WHERE t1.col1 > 100
            GROUP BY t1.col1
            LIMIT 1000;
        """
    }

    query = queries.get(query_type, queries['simple'])
    crash_detected = False

    print(f"[{datetime.now()}] Starting connection lifecycle test")
    print(f"  Target: {iterations} iterations")
    print(f"  Query type: {query_type}")
    print(f"  Expected crash: ~100-200 connections")
    print("-" * 60)

    for i in range(1, iterations + 1):
        try:
            # Create new connection
            conn = mysql.connector.connect(**config)
            cursor = conn.cursor()

            # Execute query (may involve Rapid engine)
            for statement in query.strip().split(';'):
                if statement.strip():
                    cursor.execute(statement.strip())
                    if cursor.with_rows:
                        cursor.fetchall()  # Consume results

            # Close connection (this is where crash often happens)
            cursor.close()
            conn.close()

            # Progress reporting
            if i % 10 == 0:
                print(f"[{datetime.now()}] Iteration {i}/{iterations} - OK")

            # Small delay to simulate realistic connection pattern
            time.sleep(0.01)

        except mysql.connector.Error as e:
            print(f"\n[ERROR] Connection failed at iteration {i}")
            print(f"  Error: {e}")
            crash_detected = True
            break
        except KeyboardInterrupt:
            print(f"\n[INFO] Interrupted at iteration {i}")
            sys.exit(0)

    if not crash_detected:
        print(f"\n[SUCCESS] Completed {iterations} iterations without crash")
        print("  Note: Crash may require more iterations or different query pattern")

    return crash_detected

def setup_test_table(config, table_name='test_table', rows=10000):
    """
    Create and populate test table for Rapid engine testing.
    """
    print(f"[{datetime.now()}] Setting up test table: {table_name}")

    conn = mysql.connector.connect(**config)
    cursor = conn.cursor()

    # Create test database if needed
    cursor.execute("CREATE DATABASE IF NOT EXISTS test_rapid")
    cursor.execute("USE test_rapid")

    # Drop existing table
    cursor.execute(f"DROP TABLE IF EXISTS {table_name}")

    # Create table with appropriate structure for Rapid
    cursor.execute(f"""
        CREATE TABLE {table_name} (
            id INT PRIMARY KEY,
            col1 INT,
            col2 DECIMAL(10,2),
            col3 VARCHAR(100),
            col4 TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
            INDEX idx_col1 (col1)
        ) ENGINE=InnoDB
    """)

    # Insert test data
    print(f"  Inserting {rows} rows...")
    insert_query = f"""
        INSERT INTO {table_name} (id, col1, col2, col3)
        VALUES (%s, %s, %s, %s)
    """

    batch_size = 1000
    for batch_start in range(0, rows, batch_size):
        batch_data = [
            (i, i % 1000, float(i) * 1.5, f"test_value_{i}")
            for i in range(batch_start, min(batch_start + batch_size, rows))
        ]
        cursor.executemany(insert_query, batch_data)
        conn.commit()

        if (batch_start + batch_size) % 5000 == 0:
            print(f"    {batch_start + batch_size}/{rows} rows inserted")

    # Load table into Rapid engine (secondary engine)
    print("  Loading table into Rapid engine...")
    cursor.execute(f"ALTER TABLE {table_name} SECONDARY_ENGINE=rapid")
    cursor.execute(f"ALTER TABLE {table_name} SECONDARY_LOAD")

    # Wait for load to complete
    max_wait = 30
    for _ in range(max_wait):
        cursor.execute(f"""
            SELECT SECONDARY_ENGINE_LOAD_STATUS
            FROM information_schema.tables
            WHERE table_schema='test_rapid' AND table_name='{table_name}'
        """)
        status = cursor.fetchone()[0]
        if status == 'LOADED':
            print("  Table loaded into Rapid engine successfully")
            break
        time.sleep(1)
    else:
        print("  WARNING: Table load timeout - may not be in Rapid engine")

    cursor.close()
    conn.close()
    print("[{datetime.now()}] Test setup complete")

def main():
    parser = argparse.ArgumentParser(
        description='Test connection lifecycle to reproduce Rapid engine crash'
    )
    parser.add_argument('--host', default='127.0.0.1', help='MySQL host')
    parser.add_argument('--port', type=int, default=3308, help='MySQL port (ASan build: 3308)')
    parser.add_argument('--user', default='root', help='MySQL user')
    parser.add_argument('--password', default='', help='MySQL password')
    parser.add_argument('--iterations', type=int, default=200,
                       help='Number of connection cycles (default: 200)')
    parser.add_argument('--query-type', choices=['simple', 'rapid', 'complex'],
                       default='rapid', help='Query complexity level')
    parser.add_argument('--setup', action='store_true',
                       help='Setup test table before running test')
    parser.add_argument('--rows', type=int, default=10000,
                       help='Number of rows in test table (default: 10000)')

    args = parser.parse_args()

    config = {
        'host': args.host,
        'port': args.port,
        'user': args.user,
        'password': args.password,
        'database': 'test_rapid',
        'autocommit': True,
        'connection_timeout': 10
    }

    # Setup test table if requested
    if args.setup:
        setup_test_table(config, rows=args.rows)
        print()

    # Run connection lifecycle test
    crash_detected = test_connection_lifecycle(
        config,
        iterations=args.iterations,
        query_type=args.query_type
    )

    sys.exit(1 if crash_detected else 0)

if __name__ == '__main__':
    main()
```

### Make Script Executable

```bash
chmod +x /home/wuy/ShannonBase/test_connection_crash.py
```

---

## Part 5: Complete Testing Workflow

### Step-by-Step Testing Process

#### 1. Build with ASan

```bash
cd /home/wuy/ShannonBase
./run_cmake_asan.sh
cd cmake_build_asan
make -j$(nproc) && make install
```

#### 2. Initialize ASan Database

```bash
# Source ASan environment
source /home/wuy/ShannonBase/asan_env.sh

# Initialize data directory
SHANNON_ASAN_BIN="/home/wuy/DB/ShannonBase/shannon_bin_asan"
SHANNON_ASAN_DATA="/home/wuy/DB/ShannonBase/db/data_asan"

rm -rf ${SHANNON_ASAN_DATA}
${SHANNON_ASAN_BIN}/bin/mysqld --initialize-insecure \
  --basedir=${SHANNON_ASAN_BIN} \
  --datadir=${SHANNON_ASAN_DATA} \
  --user=$(whoami)
```

#### 3. Start ASan Server

```bash
# Start with ASan environment
source /home/wuy/ShannonBase/asan_env.sh

${SHANNON_ASAN_BIN}/bin/mysqld \
  --basedir=${SHANNON_ASAN_BIN} \
  --datadir=${SHANNON_ASAN_DATA} \
  --port=3308 \
  --socket=/tmp/mysql_asan.sock \
  --user=$(whoami) \
  --log-error=${SHANNON_ASAN_DATA}/error.log &

# Wait for server to start
sleep 5

# Verify server is running
${SHANNON_ASAN_BIN}/bin/mysql -uroot -h127.0.0.1 -P3308 -e "SELECT VERSION()"
```

#### 4. Setup Test Environment

```bash
# Create test table and load into Rapid
python3 /home/wuy/ShannonBase/test_connection_crash.py \
  --port 3308 \
  --setup \
  --rows 10000
```

#### 5. Run Crash Reproducer

```bash
# Run with ASan environment active
source /home/wuy/ShannonBase/asan_env.sh

# Test with Rapid engine queries (most likely to crash)
python3 /home/wuy/ShannonBase/test_connection_crash.py \
  --port 3308 \
  --iterations 200 \
  --query-type rapid

# Monitor ASan logs in real-time in another terminal
tail -f /home/wuy/ShannonBase/asan_logs/asan.*
```

#### 6. Trigger Crash and Capture Report

**Expected behavior:**
- Server will crash after 100-200 iterations
- ASan will print detailed report to stdout/stderr
- Log file will contain full stack trace

**If crash doesn't occur:**
1. Increase iterations: `--iterations 500`
2. Try complex queries: `--query-type complex`
3. Add concurrent connections (modify script)
4. Check server error log for other issues

---

## Part 6: Interpreting ASan Reports

### ASan Report Structure

When ASan detects an error, it prints a report like this:

```
=================================================================
==12345==ERROR: AddressSanitizer: heap-use-after-free on address 0x7f1234567890 at pc 0x12345678 bp 0x7fff1234 sp 0x7fff1230
READ of size 8 at 0x7f1234567890 thread T0
    #0 0x12345678 in Rapid_connection::close() /home/wuy/ShannonBase/storage/rapid_engine/rapid_connection.cc:123
    #1 0x23456789 in Rapid_share::close_connection() /home/wuy/ShannonBase/storage/rapid_engine/rapid_share.cc:456
    #2 0x34567890 in ha_rapid::close() /home/wuy/ShannonBase/storage/rapid_engine/ha_rapid.cc:789
    #3 0x45678901 in handler::ha_close() /home/wuy/ShannonBase/sql/handler.cc:1234
    #4 0x56789012 in close_thread_tables() /home/wuy/ShannonBase/sql/sql_base.cc:2345

0x7f1234567890 is located 64 bytes inside of 256-byte region [0x7f1234567850,0x7f1234567950)
freed by thread T0 here:
    #0 0x7f1245678901 in operator delete(void*) ../../../../src/libsanitizer/asan/asan_new_delete.cpp:160
    #1 0x67890123 in Rapid_connection::~Rapid_connection() /home/wuy/ShannonBase/storage/rapid_engine/rapid_connection.cc:89
    #2 0x78901234 in Rapid_share::cleanup() /home/wuy/ShannonBase/storage/rapid_engine/rapid_share.cc:234

previously allocated by thread T0 here:
    #0 0x7f1245678902 in operator new(unsigned long) ../../../../src/libsanitizer/asan/asan_new_delete.cpp:95
    #1 0x89012345 in Rapid_share::init() /home/wuy/ShannonBase/storage/rapid_engine/rapid_share.cc:123
    #2 0x90123456 in ha_rapid::open() /home/wuy/ShannonBase/storage/rapid_engine/ha_rapid.cc:456

SUMMARY: AddressSanitizer: heap-use-after-free /home/wuy/ShannonBase/storage/rapid_engine/rapid_connection.cc:123 in Rapid_connection::close()
Shadow bytes around the buggy address:
  [memory map output]
==12345==ABORTING
```

### Key Elements to Analyze

#### 1. Error Type
```
ERROR: AddressSanitizer: heap-use-after-free
```

**Common ASan error types:**
- `heap-use-after-free`: Accessing freed memory (most likely for this crash)
- `heap-buffer-overflow`: Writing beyond allocated buffer
- `stack-use-after-scope`: Using stack variable after it goes out of scope
- `global-buffer-overflow`: Array index out of bounds
- `use-after-return`: Using stack memory after function returns
- `double-free`: Freeing same memory twice
- `memcpy-param-overlap`: Overlapping src/dst in memcpy

#### 2. Location of Access
```
READ of size 8 at 0x7f1234567890 thread T0
    #0 in Rapid_connection::close() rapid_connection.cc:123
```

**Analysis:**
- **What**: 8-byte read (likely a pointer dereference)
- **Where**: `rapid_connection.cc` line 123
- **Function**: `Rapid_connection::close()`
- **Thread**: Main thread (T0)

**For connection lifecycle bugs, focus on:**
- Connection close/cleanup functions
- Destructor calls
- Resource cleanup order
- Shared pointer/reference management

#### 3. Deallocation Stack Trace
```
freed by thread T0 here:
    #1 in Rapid_connection::~Rapid_connection() rapid_connection.cc:89
    #2 in Rapid_share::cleanup() rapid_share.cc:234
```

**Key questions:**
- When was memory freed? (destructor call)
- Who freed it? (`Rapid_share::cleanup()`)
- Was this expected? (check object lifetime)

#### 4. Allocation Stack Trace
```
previously allocated by thread T0 here:
    #1 in Rapid_share::init() rapid_share.cc:123
    #2 in ha_rapid::open() ha_rapid.cc:456
```

**Key questions:**
- Where was memory allocated? (`Rapid_share::init()`)
- What lifecycle was expected? (connection lifetime)
- Is there a mismatch between allocation/deallocation owners?

#### 5. Memory Layout
```
0x7f1234567890 is located 64 bytes inside of 256-byte region [...]
```

**Analysis:**
- Bug is 64 bytes into object (not boundary issue)
- 256-byte object suggests small object or struct
- Middle-of-object access suggests field access, not buffer overflow

### Interpreting for Connection Lifecycle

**Typical pattern for this crash:**

1. **Object Ownership Issue**
   ```cpp
   // Example problematic pattern:
   Rapid_share* share = get_share();  // Returns raw pointer
   share->init_connection();
   // ... somewhere else ...
   delete share;  // Freed by another component
   // ... back in original code ...
   share->close_connection();  // Use after free!
   ```

2. **Reference Counting Bug**
   ```cpp
   // Share object has reference count
   share->increment_ref();  // Thread 1
   // ...
   share->decrement_ref();  // Thread 2 - triggers delete
   // ... Thread 1 still has "reference" ...
   share->do_something();  // Use after free!
   ```

3. **Double Close/Cleanup**
   ```cpp
   // Connection closed multiple times
   connection->close();  // First close - frees resources
   // ... error handling ...
   connection->close();  // Second close - use after free!
   ```

4. **Destructor Order Issue**
   ```cpp
   struct Rapid_share {
       Rapid_connection* conn;
       ~Rapid_share() {
           delete conn;  // Destroys connection first
           cleanup_resources();  // Tries to use conn->resources
       }
   };
   ```

### Next Steps After ASan Report

#### 1. Locate the Bug in Source Code

```bash
# Open the file at the exact line
vim /home/wuy/ShannonBase/storage/rapid_engine/rapid_connection.cc +123

# Look for:
# - Pointer dereferences
# - Member access (->)
# - Array/vector access
# - Resource usage
```

#### 2. Examine Object Lifecycle

```bash
# Search for all places object is created/destroyed
grep -rn "Rapid_connection" storage/rapid_engine/ | grep -E "new|delete|~Rapid"

# Check reference counting
grep -rn "ref_count\|increment_ref\|decrement_ref" storage/rapid_engine/
```

#### 3. Check MySQL Handler Integration

The Rapid engine integrates with MySQL's handler interface. Common issues:

```cpp
// ha_rapid.h/cc - Check handler methods:
virtual int open();          // Object creation
virtual int close();         // Object destruction
virtual int reset();         // State reset between queries
virtual void unbind_psi();   // PSI cleanup

// Look for:
// - Is close() called multiple times?
// - Is reset() using objects that close() freed?
// - Are there multiple paths to cleanup?
```

#### 4. Check Connection Pooling/Sharing

```bash
# Look for connection/table sharing logic
grep -rn "get_share\|free_share" storage/rapid_engine/

# Check for:
# - Thread-safe reference counting
# - Proper locking around share access
# - Cleanup ordering in destructor
```

#### 5. Validate Fix with ASan

After identifying and fixing the bug:

```bash
# Rebuild with fix
cd /home/wuy/ShannonBase/cmake_build_asan
make -j$(nproc) && make install

# Restart server
pkill -f mysqld
source /home/wuy/ShannonBase/asan_env.sh
${SHANNON_ASAN_BIN}/bin/mysqld [...] &

# Re-run test
python3 test_connection_crash.py --port 3308 --iterations 500

# If successful, run extended test
python3 test_connection_crash.py --port 3308 --iterations 2000
```

---

## Part 7: Advanced Debugging Techniques

### Technique 1: ASan with GDB

For detailed debugging when ASan catches an error:

```bash
# Set breakpoint on ASan error
export ASAN_OPTIONS="${ASAN_OPTIONS}:abort_on_error=0:halt_on_error=1"

# Run under GDB
gdb --args ${SHANNON_ASAN_BIN}/bin/mysqld \
  --basedir=${SHANNON_ASAN_BIN} \
  --datadir=${SHANNON_ASAN_DATA} \
  --port=3308

# In GDB:
(gdb) run
# Wait for ASan to detect error and pause
(gdb) bt full          # Full backtrace with local variables
(gdb) frame 3          # Navigate to interesting frame
(gdb) print *this      # Examine object state
(gdb) info locals      # Show all local variables
```

### Technique 2: ASan Print Stats

After test run, ASan prints statistics:

```
Stats: 2048M malloced (1536M for red zones) by 524288 calls
Stats: 1024M realloced by 32768 calls
Stats: 1536M freed by 491520 calls
Stats: 512M really freed by MmapOrDie
Stats: 256M (512M-256M) mmaped; 128M max; 64M by malloc
```

**Analyze for:**
- Memory growth: `malloced - freed` should be ~0 at end
- Leak indicators: Large positive difference
- Allocation patterns: High realloc suggests resizing issues

### Technique 3: Generate Suppression File

If ASan reports known/acceptable issues:

```bash
# Run with suppression generation
export ASAN_OPTIONS="${ASAN_OPTIONS}:print_suppressions=1"

# ASan will print suppression entries for each error:
# AddressSanitizer: ... in function_name
# Suppression:
# { function_name }
# fun:function_name

# Add to lsan_suppressions.txt
```

### Technique 4: Compare with Valgrind

For validation, also test with Valgrind:

```bash
# Valgrind is slower but sometimes catches different issues
valgrind --tool=memcheck \
  --leak-check=full \
  --show-leak-kinds=all \
  --track-origins=yes \
  --log-file=valgrind.log \
  ${SHANNON_ASAN_BIN}/bin/mysqld [...]
```

---

## Part 8: Performance Impact and Limitations

### Expected Performance Impact

| Metric | Normal Build | ASan Build | Impact |
|--------|--------------|------------|--------|
| CPU overhead | Baseline | 2-5x slower | Acceptable for testing |
| Memory overhead | Baseline | 2-3x more | 256MB quarantine + shadow memory |
| Binary size | ~200MB | ~600MB | 3x larger |
| Startup time | ~2s | ~5s | Slower initialization |

### ASan Limitations

**Cannot detect:**
- Logic errors (wrong calculation, incorrect algorithm)
- Race conditions (use ThreadSanitizer instead)
- Uninitialized memory reads (use MemorySanitizer)
- Resource leaks (file descriptors, etc.) - only memory leaks

**May have false positives in:**
- Custom memory allocators
- System libraries without ASan
- JIT-compiled code

### When to Use Other Sanitizers

| Sanitizer | Use When | Flag |
|-----------|----------|------|
| AddressSanitizer (ASan) | Memory safety, use-after-free, buffer overflows | `-DWITH_ASAN=ON` |
| LeakSanitizer (LSan) | Memory leaks at exit | Included with ASan on Linux |
| ThreadSanitizer (TSan) | Data races, thread synchronization | `-DWITH_TSAN=ON` |
| UndefinedBehaviorSanitizer (UBSan) | Undefined behavior, null pointer | `-DWITH_UBSAN=ON` |
| MemorySanitizer (MSan) | Uninitialized reads | `-DWITH_MSAN=ON` (experimental) |

**Note:** Cannot combine ASan with TSan or MSan in same build.

---

## Part 9: Quick Reference Commands

### Build Commands

```bash
# Clean build
rm -rf cmake_build_asan && ./run_cmake_asan.sh

# Build only
cd cmake_build_asan && make -j$(nproc)

# Install
cd cmake_build_asan && make install

# Check ASan linking
ldd shannon_bin_asan/bin/mysqld | grep asan
```

### Server Management

```bash
# Start ASan server
source asan_env.sh
${SHANNON_ASAN_BIN}/bin/mysqld --defaults-file=my_asan.cnf &

# Stop server
${SHANNON_ASAN_BIN}/bin/mysqladmin -uroot -P3308 shutdown

# Kill if unresponsive
pkill -9 -f mysqld
```

### Testing

```bash
# Setup test
python3 test_connection_crash.py --port 3308 --setup

# Run quick test
python3 test_connection_crash.py --port 3308 --iterations 50

# Run full test
python3 test_connection_crash.py --port 3308 --iterations 200 --query-type rapid

# Monitor logs
tail -f asan_logs/asan.*
```

### Log Analysis

```bash
# Find all ASan errors
grep -r "ERROR: AddressSanitizer" asan_logs/

# Extract stack traces
awk '/ERROR: AddressSanitizer/,/ABORTING/' asan_logs/asan.* > crash_report.txt

# Count error types
grep "ERROR: AddressSanitizer" asan_logs/* | cut -d: -f5 | sort | uniq -c
```

---

## Part 10: Troubleshooting

### Issue: ASan Build Fails

**Error: "Do not know how to enable address sanitizer"**

Solution:
```bash
# Check GCC version (need 4.8+)
gcc --version

# Ensure GCC is default compiler
export CC=gcc
export CXX=g++

# Re-run cmake
rm -rf cmake_build_asan && ./run_cmake_asan.sh
```

### Issue: Server Won't Start

**Check 1: Port conflict**
```bash
# Check if port 3308 is in use
netstat -tuln | grep 3308

# Kill existing process
fuser -k 3308/tcp
```

**Check 2: Data directory**
```bash
# Ensure data directory is initialized
ls -la ${SHANNON_ASAN_DATA}/

# Re-initialize if needed
rm -rf ${SHANNON_ASAN_DATA} && mysqld --initialize-insecure [...]
```

**Check 3: Error log**
```bash
# Check server error log
tail -100 ${SHANNON_ASAN_DATA}/error.log
```

### Issue: No Crash Occurs

**Possible reasons:**
1. Crash is timing-dependent (add delays/stress)
2. Crash requires specific query pattern
3. Need more iterations
4. Database state affects crash

**Solutions:**
```bash
# Increase iterations
--iterations 1000

# Try different query types
--query-type complex

# Add concurrent connections (modify script)

# Check if Rapid is actually being used:
mysql -uroot -P3308 -e "
SET SESSION use_secondary_engine=FORCED;
EXPLAIN SELECT * FROM test_rapid.test_table LIMIT 1;
"
# Should show "Using secondary engine RAPID" in Extra column
```

### Issue: ASan Report is Truncated

**Solution:**
```bash
# Increase malloc context size
export ASAN_OPTIONS="${ASAN_OPTIONS}:malloc_context_size=50"

# Increase log size limit
export ASAN_OPTIONS="${ASAN_OPTIONS}:log_to_syslog=0"

# Redirect to file
${SHANNON_ASAN_BIN}/bin/mysqld [...] 2>&1 | tee asan_full.log
```

---

## Summary Checklist

**Build Phase:**
- [ ] GCC 11+ installed and verified
- [ ] ASan build script created (`run_cmake_asan.sh`)
- [ ] Build completed successfully
- [ ] ASan libraries linked (verify with `ldd`)

**Setup Phase:**
- [ ] ASan environment script created (`asan_env.sh`)
- [ ] Log directory created (`asan_logs/`)
- [ ] Separate data directory initialized (`data_asan/`)
- [ ] ASan server starts on port 3308
- [ ] Test database and table created

**Testing Phase:**
- [ ] ASan environment sourced
- [ ] Test script created (`test_connection_crash.py`)
- [ ] Crash reproducer runs successfully
- [ ] ASan log files being generated
- [ ] Crash occurs within expected range (100-200 iterations)

**Debug Phase:**
- [ ] ASan error report captured
- [ ] Bug location identified (file:line)
- [ ] Object lifecycle analyzed
- [ ] Fix implemented
- [ ] Fix validated with extended test (500+ iterations)

---

## Additional Resources

**ASan Documentation:**
- https://github.com/google/sanitizers/wiki/AddressSanitizer
- https://github.com/google/sanitizers/wiki/AddressSanitizerLeakSanitizer

**MySQL Handler API:**
- https://dev.mysql.com/doc/dev/mysql-server/latest/PAGE_STORAGE_ENGINE_API.html

**GCC Sanitizer Options:**
- https://gcc.gnu.org/onlinedocs/gcc/Instrumentation-Options.html

---

## Appendix: Common Rapid Engine Patterns

### Pattern 1: Share Management

Typical MySQL storage engine pattern:
```cpp
// ha_rapid.cc
RAPID_SHARE* ha_rapid::get_share() {
  lock_shared_ha_data();
  RAPID_SHARE* tmp_share = static_cast<RAPID_SHARE*>(get_ha_share_ptr());

  if (!tmp_share) {
    tmp_share = new RAPID_SHARE;
    tmp_share->init();
    tmp_share->ref_count = 1;
    set_ha_share_ptr(static_cast<Handler_share*>(tmp_share));
  } else {
    tmp_share->ref_count++;
  }

  unlock_shared_ha_data();
  return tmp_share;
}

// Bug: If free_share() is called while another thread still holds reference
void ha_rapid::free_share() {
  lock_shared_ha_data();
  if (share && --share->ref_count == 0) {
    delete share;  // Can cause use-after-free in other threads
  }
  unlock_shared_ha_data();
}
```

### Pattern 2: Handler Lifecycle

```cpp
// MySQL calls these in sequence:
int ha_rapid::open()   // Create/get share, initialize connection
int ha_rapid::external_lock()  // Begin transaction
int ha_rapid::rnd_init()       // Start table scan
int ha_rapid::rnd_next()       // Read rows
int ha_rapid::rnd_end()        // End scan
int ha_rapid::external_lock()  // End transaction
int ha_rapid::close()  // Close connection, free share

// Bug: If close() is called twice, or if rnd_next() uses freed memory
```

### Pattern 3: Connection Pooling

```cpp
// Rapid may pool connections:
struct RAPID_SHARE {
  std::vector<Rapid_connection*> connection_pool;

  Rapid_connection* get_connection() {
    if (connection_pool.empty()) {
      return new Rapid_connection();
    }
    Rapid_connection* conn = connection_pool.back();
    connection_pool.pop_back();
    return conn;  // Bug: What if connection was already freed?
  }

  void return_connection(Rapid_connection* conn) {
    connection_pool.push_back(conn);  // Bug: What if conn is deleted elsewhere?
  }
};
```

---

**Document Version:** 1.0
**Last Updated:** 2025-10-23
**Target:** ShannonBase Rapid Engine Connection Lifecycle Bug
**Status:** Ready for testing
