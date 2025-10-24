# AddressSanitizer Build and Testing for ShannonBase

Complete strategy for debugging the Rapid engine connection lifecycle crash using AddressSanitizer.

## Document Overview

| Document | Purpose | Audience |
|----------|---------|----------|
| **ASAN_QUICKSTART.md** | Get started in 5 steps | Quick testing |
| **ASAN_BUILD_STRATEGY.md** | Complete reference guide | Detailed debugging |
| This file | Overview and roadmap | All users |

## Problem Statement

**Issue:** ShannonBase crashes after 100-200 connection cycles when using Rapid (secondary) engine.

**Symptoms:**
- Crash during connection close/cleanup
- No clear error message in normal build
- Reproducible with repeated connections
- Memory corruption suspected

**Solution:** Build with AddressSanitizer to detect exact memory error.

## Quick Navigation

### For Quick Testing (30 minutes)
1. Read: `ASAN_QUICKSTART.md`
2. Run: Build → Initialize → Test
3. Analyze: ASan report

### For Detailed Debugging (2-4 hours)
1. Read: `ASAN_BUILD_STRATEGY.md` Parts 1-6
2. Build with ASan (Part 2)
3. Configure runtime (Part 3)
4. Run reproducer (Part 4)
5. Interpret report (Part 6)
6. Apply fix and validate

### For Advanced Analysis
- Part 7: Advanced debugging with GDB, Valgrind
- Part 8: Performance tuning and limitations
- Appendix: Common MySQL/Rapid patterns

## Files Created

### Documentation
- `ASAN_BUILD_STRATEGY.md` - Complete 10-part strategy guide
- `ASAN_QUICKSTART.md` - Quick start in 5 steps
- `ASAN_README.md` - This overview file

### Scripts
- `run_cmake_asan.sh` - CMake configuration for ASan build
- `asan_env.sh` - Runtime environment variables
- `test_connection_crash.py` - Minimal crash reproducer

### Configuration
- `lsan_suppressions.txt` - Leak sanitizer suppressions (empty initially)

### Generated at Runtime
- `asan_logs/asan.*` - ASan error reports
- `cmake_build_asan/` - Build directory
- `/home/wuy/DB/ShannonBase/shannon_bin_asan/` - ASan binaries
- `/home/wuy/DB/ShannonBase/db/data_asan/` - ASan data directory

## Workflow Overview

```
┌─────────────────────────────────────────────────────────┐
│ 1. BUILD PHASE (30-60 min)                             │
│    run_cmake_asan.sh → cmake → make → install          │
│    Result: ASan-instrumented binaries                   │
└─────────────────────────────────────────────────────────┘
                           ↓
┌─────────────────────────────────────────────────────────┐
│ 2. SETUP PHASE (5 min)                                 │
│    Initialize data → Start ASan server → Create tables │
│    Result: Running ASan server on port 3308            │
└─────────────────────────────────────────────────────────┘
                           ↓
┌─────────────────────────────────────────────────────────┐
│ 3. TEST PHASE (2-5 min)                                │
│    test_connection_crash.py → Trigger crash            │
│    Result: ASan detects and reports memory error       │
└─────────────────────────────────────────────────────────┘
                           ↓
┌─────────────────────────────────────────────────────────┐
│ 4. DEBUG PHASE (variable)                              │
│    Analyze report → Locate bug → Examine code          │
│    Result: Understanding of root cause                  │
└─────────────────────────────────────────────────────────┘
                           ↓
┌─────────────────────────────────────────────────────────┐
│ 5. FIX PHASE (variable)                                │
│    Implement fix → Rebuild → Re-test                   │
│    Result: Bug fixed and validated                      │
└─────────────────────────────────────────────────────────┘
```

## Key Concepts

### What is AddressSanitizer?

ASan is a fast memory error detector that finds:
- **Use-after-free**: Accessing freed memory (likely this bug)
- **Heap buffer overflow**: Writing beyond allocated buffer
- **Stack buffer overflow**: Writing beyond stack array
- **Use-after-return**: Using stack variables after function returns
- **Double-free**: Freeing same memory twice

**How it works:**
1. Instruments all memory access at compile time
2. Adds "red zones" around allocations
3. Poisons freed memory in quarantine
4. Detects accesses to invalid memory
5. Reports with detailed stack traces

### Why ASan for This Bug?

**Symptoms suggest memory corruption:**
- Crash during cleanup (typical use-after-free)
- After repeated operations (memory gets freed)
- Connection lifecycle (ownership issues)

**ASan will tell us:**
- Exact line where invalid access occurs
- What memory was accessed
- When it was freed (and by whom)
- When it was allocated (and by whom)
- Complete stack traces for all events

## Expected Results

### Successful ASan Detection

You should see output like:
```
[2025-10-23 12:34:56] Iteration 120/200 - OK
[2025-10-23 12:34:57] Iteration 130/200 - OK

=================================================================
==12345==ERROR: AddressSanitizer: heap-use-after-free on address 0x61f000001234
READ of size 8 at 0x61f000001234 thread T0
    #0 0x55a123456789 in Rapid_connection::close()
       /home/wuy/ShannonBase/storage/rapid_engine/rapid_connection.cc:123
    #1 0x55a234567890 in Rapid_share::close_connection()
       /home/wuy/ShannonBase/storage/rapid_engine/rapid_share.cc:456
    ...

0x61f000001234 is located 64 bytes inside of 256-byte region
freed by thread T0 here:
    #0 0x7f8901234567 in operator delete(void*)
    #1 0x55a345678901 in Rapid_connection::~Rapid_connection()
       /home/wuy/ShannonBase/storage/rapid_engine/rapid_connection.cc:89
    ...

SUMMARY: AddressSanitizer: heap-use-after-free rapid_connection.cc:123
==12345==ABORTING
```

### What This Tells Us

1. **Bug type**: heap-use-after-free (memory used after being freed)
2. **Where**: `rapid_connection.cc` line 123, in `close()` method
3. **What**: 8-byte read (probably a pointer dereference)
4. **When freed**: In `~Rapid_connection()` destructor, line 89
5. **Root cause**: Connection is destroyed but still being accessed

**Next step**: Examine the code around these lines to understand object lifetime.

## System Requirements

### Compiler
- GCC 4.8+ or Clang 3.1+ (You have: GCC 11.2.0 ✓)
- AddressSanitizer support built-in

### Resources
- **Disk**: 30GB for ASan build (vs 10GB normal)
- **Memory**: 8GB minimum, 16GB recommended
- **CPU**: 2+ cores for reasonable build time

### Dependencies
- Python 3 with mysql-connector-python
- System OpenSSL
- Boost 1.77.0 (already configured)

## Performance Impact

| Metric | Normal | ASan | Notes |
|--------|--------|------|-------|
| Build time | 15-30 min | 30-60 min | 2x slower |
| Binary size | 200 MB | 600 MB | 3x larger |
| Runtime speed | 1x | 2-5x slower | Still usable |
| Memory usage | 1x | 2-3x more | Quarantine + shadow |
| Startup time | 2 sec | 5 sec | Initialization overhead |

**For testing:** Performance impact is acceptable and necessary.

## Troubleshooting Guide

### Issue 1: Build Fails

**Error:** "Do not know how to enable address sanitizer"

**Solution:**
```bash
export CC=gcc
export CXX=g++
rm -rf cmake_build_asan
./run_cmake_asan.sh
```

### Issue 2: Server Won't Start

**Check:**
```bash
# Port conflict
netstat -tuln | grep 3308

# Error log
tail -100 /home/wuy/DB/ShannonBase/db/data_asan/error.log

# Data directory
ls -la /home/wuy/DB/ShannonBase/db/data_asan/
```

**Fix:**
```bash
# Kill existing server
fuser -k 3308/tcp

# Re-initialize
rm -rf ${SHANNON_ASAN_DATA} && mysqld --initialize-insecure [...]
```

### Issue 3: No Crash Detected

**Try:**
```bash
# More iterations
python3 test_connection_crash.py --port 3308 --iterations 1000

# Different query type
python3 test_connection_crash.py --port 3308 --query-type complex

# Verify Rapid is used
mysql -uroot -P3308 test_rapid -e "
SET SESSION use_secondary_engine=FORCED;
EXPLAIN SELECT * FROM test_table LIMIT 1;
" | grep -i "secondary engine"
```

### Issue 4: ASan Report Truncated

**Fix:**
```bash
# Increase context
export ASAN_OPTIONS="${ASAN_OPTIONS}:malloc_context_size=50"

# Save full output
source asan_env.sh
mysqld [...] 2>&1 | tee asan_full_output.log
```

## Next Steps After Bug Detection

### 1. Analyze the Report
- Identify error type (heap-use-after-free, etc.)
- Find exact location (file:line)
- Understand when memory was freed
- Understand when it was allocated

### 2. Examine Source Code
```bash
# Open file at exact line
vim storage/rapid_engine/rapid_connection.cc +123

# Search for related code
grep -rn "Rapid_connection" storage/rapid_engine/
```

### 3. Understand Object Lifetime
- Who owns the object?
- When should it be freed?
- Is there reference counting?
- Are there multiple cleanup paths?

### 4. Common Patterns to Check

**Use-after-free:**
- Object freed while still in use
- Reference counting bug
- Double cleanup

**Solution examples:**
```cpp
// Before: Bug
Rapid_connection* conn = get_connection();
delete conn;  // Freed
conn->close();  // Use after free!

// After: Fix
Rapid_connection* conn = get_connection();
conn->close();  // Use first
delete conn;  // Then free

// Or better: Smart pointer
std::shared_ptr<Rapid_connection> conn = get_connection();
conn->close();  // Automatic cleanup
```

### 5. Validate Fix
```bash
# Rebuild
cd cmake_build_asan && make -j$(nproc) && make install

# Restart server
pkill mysqld && source asan_env.sh && mysqld [...] &

# Re-test with extended iterations
python3 test_connection_crash.py --port 3308 --iterations 2000
```

## Additional Resources

### AddressSanitizer
- Official wiki: https://github.com/google/sanitizers/wiki/AddressSanitizer
- Clang docs: https://clang.llvm.org/docs/AddressSanitizer.html
- GCC docs: https://gcc.gnu.org/onlinedocs/gcc/Instrumentation-Options.html

### MySQL Storage Engine Development
- Handler API: https://dev.mysql.com/doc/dev/mysql-server/latest/PAGE_STORAGE_ENGINE_API.html
- Plugin development: https://dev.mysql.com/doc/extending-mysql/8.0/en/

### Debugging Tools
- GDB: https://sourceware.org/gdb/documentation/
- Valgrind: https://valgrind.org/docs/manual/manual.html
- perf: https://perf.wiki.kernel.org/

## Support and Feedback

For issues with this guide:
1. Check troubleshooting section in `ASAN_BUILD_STRATEGY.md`
2. Review common patterns in Appendix
3. Consult ASan documentation for advanced usage

## Version History

- **v1.0** (2025-10-23): Initial comprehensive strategy
  - Complete build instructions
  - Runtime configuration
  - Test scripts
  - Interpretation guide

## License and Credits

**ShannonBase:** MySQL 8.0 based with Rapid (secondary) engine
**AddressSanitizer:** Google Sanitizers project
**This guide:** Created for debugging connection lifecycle crash

---

**Ready to start?** → See `ASAN_QUICKSTART.md` for immediate action items.

**Need details?** → See `ASAN_BUILD_STRATEGY.md` for comprehensive guide.
