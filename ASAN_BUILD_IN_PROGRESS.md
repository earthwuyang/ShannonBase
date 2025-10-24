# AddressSanitizer Build In Progress

**Started**: 2025-10-23 17:05 CST
**Expected Completion**: 17:35 - 18:05 CST (30-60 minutes)
**Build Command**: `make -j80` (using all 80 cores)

---

## What's Being Built

**AddressSanitizer (ASan) Version of ShannonBase**:
- Same functionality as production build
- Additional memory error detection
- Debug symbols for detailed stack traces
- Runs on port **3308** (separate from production port 3307)

---

## Build Progress

Check build progress:
```bash
# See current compilation
tail -f /tmp/asan_build.log

# Check how many files compiled
grep "Built target" /tmp/asan_build.log | wc -l

# See errors (if any)
grep -i "error:" /tmp/asan_build.log
```

---

## What Happens Next

### Step 1: Install ASan Build (2 minutes)
```bash
cd /home/wuy/ShannonBase/cmake_build_asan
make install
```

Installs to: `/home/wuy/DB/ShannonBase/shannon_bin_asan`

### Step 2: Initialize ASan Database (5 minutes)
```bash
export SHANNON_ASAN_BIN="/home/wuy/DB/ShannonBase/shannon_bin_asan"
export SHANNON_ASAN_DATA="/home/wuy/DB/ShannonBase/db/data_asan"

# Initialize
${SHANNON_ASAN_BIN}/bin/mysqld --initialize-insecure \
  --basedir=${SHANNON_ASAN_BIN} \
  --datadir=${SHANNON_ASAN_DATA} \
  --user=$(whoami)
```

### Step 3: Configure ASan Environment (1 minute)
```bash
# ASan runtime options for maximum detail
export ASAN_OPTIONS="detect_leaks=1:abort_on_error=1:log_path=/home/wuy/ShannonBase/asan_logs/asan:print_stacktrace=1:symbolize=1"

# Create log directory
mkdir -p /home/wuy/ShannonBase/asan_logs
```

### Step 4: Start ASan Server (1 minute)
```bash
${SHANNON_ASAN_BIN}/bin/mysqld \
  --basedir=${SHANNON_ASAN_BIN} \
  --datadir=${SHANNON_ASAN_DATA} \
  --port=3308 \
  --socket=/tmp/mysql_asan.sock \
  --user=$(whoami) \
  --log-error=/home/wuy/ShannonBase/asan_logs/error.log &
```

### Step 5: Load Test Data (2 minutes)
```bash
# Create test database
mysql -h 127.0.0.1 -P 3308 -u root -e "CREATE DATABASE IF NOT EXISTS Airline"

# Import small test table
mysql -h 127.0.0.1 -P 3308 -u root Airline < test_data/L_WEEKDAYS.sql

# Configure and load into Rapid
mysql -h 127.0.0.1 -P 3308 -u root -D Airline -e "
ALTER TABLE L_WEEKDAYS SECONDARY_ENGINE=Rapid;
ALTER TABLE L_WEEKDAYS SECONDARY_LOAD;
"
```

### Step 6: Reproduce Crash Under ASan (1 minute)
```bash
# This will crash, but ASan will capture detailed diagnostics
mysql -h 127.0.0.1 -P 3308 -u root -D Airline -e "
SET SESSION use_secondary_engine = FORCED;
SELECT COUNT(*) FROM L_WEEKDAYS;
"
```

### Step 7: Analyze ASan Report (5-15 minutes)
```bash
# Check ASan log
cat /home/wuy/ShannonBase/asan_logs/asan.* | less

# Look for error report
grep -A 50 "ERROR: AddressSanitizer" /home/wuy/ShannonBase/asan_logs/asan.*
```

---

## What AS an Will Tell Us

### Example ASan Output
```
==12345==ERROR: AddressSanitizer: heap-use-after-free on address 0x60300000eff0 at pc 0x7f8a1234 bp 0x7fff sp 0x7ff8
READ of size 8 at 0x60300000eff0 thread T0
    #0 0x7f8a1234 in ShannonBase::Imcs::TableIterator::next() storage/rapid_engine/storage/table_iterator.cc:156
    #1 0x7f8a5678 in ha_rapid::rnd_next(uchar*) storage/rapid_engine/handler/ha_shannon_rapid.cc:892
    #2 0x7f8a9abc in ExecuteIteratorQuery(THD*, Query_block*) sql/sql_executor.cc:1245

0x60300000eff0 is located 16 bytes inside of 128-byte region [0x60300000efe0,0x60300000f060)
freed by thread T0 here:
    #0 0x7f8b1234 in operator delete(void*) (/usr/lib/x86_64-linux-gnu/libasan.so.5+0x10d6a8)
    #1 0x7f8a3456 in ShannonBase::Imcs::TableScanner::~TableScanner() storage/rapid_engine/storage/table_scanner.cc:45
    #2 0x7f8a7890 in ha_rapid::close() storage/rapid_engine/handler/ha_shannon_rapid.cc:234

previously allocated by thread T0 here:
    #0 0x7f8b5678 in operator new(unsigned long) (/usr/lib/x86_64-linux-gnu/libasan.so.5+0x10d3d8)
    #1 0x7f8a2345 in ShannonBase::Imcs::TableScanner::TableScanner() storage/rapid_engine/storage/table_scanner.cc:23
    #2 0x7f8a6789 in ha_rapid::rnd_init(bool) storage/rapid_engine/handler/ha_shannon_rapid.cc:456
```

### Information We Get
1. **Error Type**: `heap-use-after-free` (accessing freed memory)
2. **Exact Location**: `table_iterator.cc:156` in `TableIterator::next()`
3. **When Freed**: `table_scanner.cc:45` in destructor
4. **When Allocated**: `table_scanner.cc:23` in constructor
5. **Call Stack**: Full stack trace showing how we got there

### This Tells Us
- **WHERE**: Exact file and line number
- **WHAT**: Type of memory error
- **WHY**: Lifecycle of the problematic memory
- **HOW TO FIX**: Clear path to the bug

---

## Estimated Timeline

| Step | Duration | ETA |
|------|----------|-----|
| Build ASan | 30-60 min | 17:35 - 18:05 |
| Install | 2 min | 18:07 |
| Initialize DB | 5 min | 18:12 |
| Start server & load data | 3 min | 18:15 |
| Reproduce crash | 1 min | 18:16 |
| Analyze report | 10 min | 18:26 |
| **Total** | **51-81 min** | **17:56 - 18:26** |

---

## Build Monitoring Commands

```bash
# Watch build progress in real-time
tail -f /tmp/asan_build.log | grep "^\["

# Count completed targets
grep -c "Built target" /tmp/asan_build.log

# Check for errors
grep -i "error" /tmp/asan_build.log | grep -v "error_messages"

# See what's currently compiling
ps aux | grep "c++" | wc -l  # Should show ~80 processes

# Build completion check
ls -lh /home/wuy/ShannonBase/cmake_build_asan/runtime_output_directory/mysqld
# If this file exists and is large (>100MB), build is done
```

---

## Current Status

**Build Running**: Yes - Restarted without NDB after compilation errors
**Parallel Jobs**: 80
**Log File**: `/tmp/asan_build.log`
**Output Directory**: `/home/wuy/ShannonBase/cmake_build_asan`
**Configuration**: `-DWITH_NDB=OFF` to avoid NDB portlib errors
**Progress**: ~19% complete, building ICU libraries

---

## After ASan Identifies the Bug

### Expected Findings
Based on the crash pattern, ASan will likely show:
1. **Use-after-free** in table iterator or scanner
2. **Buffer overflow** when accessing Rapid table data
3. **Null pointer dereference** in query execution path

### Fix Strategy
Once we know the exact location:
1. **Analyze the code** at the identified line
2. **Check object lifetimes** - is something deleted too early?
3. **Check buffer sizes** - are we writing past array bounds?
4. **Check null checks** - are we missing a nullptr check?
5. **Implement fix** - targeted, precise fix
6. **Test with ASan** - verify fix eliminates the error
7. **Test with production build** - confirm query works
8. **Deploy** - update production server

---

## Why This Is Worth The Wait

**Without ASan**:
- "It crashes somewhere" ← Useless
- Days/weeks of trial-and-error debugging
- Might never find the exact bug
- Risk of incomplete fix

**With ASan**:
- "heap-use-after-free at table_iterator.cc:156" ← Precise!
- Fix in hours, not days
- Know exactly what's wrong
- Confident, complete fix

**Investment**: 1 hour to build
**Return**: Days saved in debugging
**Confidence**: 100% vs guessing

---

**Status**: Build in progress
**Check back in**: 30-40 minutes
**Next update**: When build completes
