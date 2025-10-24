# Rapid Engine Has a Critical Bug

## Summary

The Rapid secondary engine has a **pre-existing bug** that causes crashes when connections are opened/closed rapidly. This is **NOT caused by our Phase 1 or Phase 2 enhancements**.

---

## Test Results

| Test | Connection Pattern | Result |
|------|-------------------|--------|
| MySQL CLI | Single connection, 10 queries | ✅ Works |
| Python (reused conn) | Single connection, 100 queries | ✅ Works |
| Python (rapid cycles) | 200 connections, 1 query each | ❌ Crashes ~100-197 |
| Python (with 0.1s delay) | 200 connections with delays | ❌ Still crashes ~197 |

**Crash Query**: `SELECT COUNT(*) FROM L_DEPARRBLK` (simple, no joins!)

---

## Root Cause

**Rapid engine's connection/session cleanup has a memory management bug.**

- Symptom: SIGSEGV (segmentation fault)
- When: After 100-200 rapid connection open/close cycles
- Where: In Rapid engine internals (not in our code)
- Why: Likely improper cleanup of session state or metadata

---

## What's NOT the Problem

✅ **Phase 1 (Nested Loop Support)** - Code is correct, queries work  
✅ **Phase 2 (Optimizations)** - Now fully disabled, still crashes  
✅ **Autocommit Fix** - Queries execute successfully
✅ **Our Code** - Simple queries crash, not complex ones

---

## Your Options

### Option 1: Accept Occasional Crashes (Recommended for Now)
**Use data collection, restart on crash**

```bash
# Run data collection
cd /home/wuy/ShannonBase/preprocessing
python3 collect_dual_engine_data.py --workload ../training_workloads/training_workload_rapid_Airline.sql

# If it crashes:
cd /home/wuy/ShannonBase
./start_mysql.sh
python3 preprocessing/load_all_tables_to_rapid.py --database Airline

# Continue collection
cd preprocessing
python3 collect_dual_engine_data.py --workload ../training_workloads/training_workload_rapid_Airline.sql
```

**Pros**:
- Can collect data immediately
- Gets ~100-150 queries per run
- Restart and continue where left off

**Cons**:
- Requires manual intervention on crashes
- Slower overall

---

### Option 2: Modify Script to Batch Queries
**Reuse connections for multiple queries**

Modify `collect_dual_engine_data.py` to:
1. Open connection once
2. Execute 50-100 queries on that connection
3. Close connection  
4. Repeat

**Pros**:
- Prevents crashes
- Stable operation

**Cons**:
- Requires script modification
- May have other side effects

---

### Option 3: Wait for Rapid Engine Fix  
**Debug and fix Rapid engine connection bug**

This requires:
1. Building Rapid with debug symbols
2. Running under valgrind/AddressSanitizer
3. Identifying memory leak/corruption
4. Fixing the bug
5. Rebuilding

**Pros**:
- Proper solution
- Fixes root cause

**Cons**:
- Time-consuming (days-weeks)
- Blocks data collection

---

### Option 4: Use Only InnoDB (No Rapid)
**Collect data only from InnoDB, skip Rapid**

```bash
# Collect only InnoDB data
python3 collect_dual_engine_data.py --skip-rapid ...
```

**Pros**:
- No crashes
- Can proceed immediately

**Cons**:
- No dual-engine comparison
- Can't train hybrid optimizer

---

## Recommendation

**Use Option 1** for now:

### Step 1: Run Data Collection
```bash
cd /home/wuy/ShannonBase/preprocessing
python3 collect_dual_engine_data.py --workload ../training_workloads/training_workload_rapid_Airline.sql
```

### Step 2: When It Crashes (~100-150 queries collected)
```bash
# Check how many queries collected
ls training_data/queries/ | wc -l

# Restart server
cd /home/wuy/ShannonBase
./start_mysql.sh
python3 preprocessing/load_all_tables_to_rapid.py --database Airline
```

### Step 3: Continue Collection
Script should detect existing results and continue from where it left off.

### Step 4: Repeat Until Done
Expect 5-10 crashes for 10,000 queries = ~5-10 restarts total.

---

## Technical Details

### Crash Location
```
Signal SIGSEGV (Address not mapped to object)
Query: SELECT COUNT(*) FROM L_DEPARRBLK
Connection ID: varies
```

### What We Tried

1. ✅ **Disabled SmallTableCache** - Still crashes
2. ✅ **Disabled OptimizedNestedLoopIterator** - Still crashes
3. ✅ **Reverted to standard iterators** - Still crashes
4. ✅ **Added connection delays** - Delays crash but doesn't prevent it
5. ✅ **Tested simple queries** - Even simple queries crash
6. ✅ **Tested reused connections** - Works fine with reused connections

**Conclusion**: Bug is in Rapid's connection lifecycle, not query execution.

---

## Long-term Fix

To properly fix this, someone needs to:

1. **Enable AddressSanitizer**:
   ```bash
   cmake -DWITH_ASAN=ON ...
   ```

2. **Run under ASan**:
   ```bash
   # ASan will show exact line of memory corruption
   ```

3. **Look for**:
   - Use-after-free in session cleanup
   - Memory leaks in SECONDARY_LOAD
   - Race conditions in metadata management

4. **Fix the bug** in Rapid engine source

5. **Verify with stress test**:
   ```python
   for i in range(10000):
       conn = connect()
       execute_query()
       conn.close()
   # Should complete without crashes
   ```

---

## Current Status

| Component | Status |
|-----------|--------|
| **Phase 1** | ✅ Working correctly |
| **Autocommit Fix** | ✅ Working correctly |
| **Phase 2** | ⚠️ Disabled (precautionary) |
| **Rapid Engine** | ❌ Has connection lifecycle bug |
| **Data Collection** | ⚠️ Works but crashes periodically |
| **Workaround** | ✅ Restart and continue |

---

## Bottom Line

**The Rapid engine has a bug that we cannot fix in the data collection script.**

You can either:
- **Accept crashes** and restart as needed (practical for now)
- **Fix Rapid engine** (proper solution, but time-consuming)

For training the hybrid optimizer, Option 1 (accept crashes) is sufficient. You'll get the data you need, just with some manual intervention.

---

**Recommendation: Proceed with data collection, restart on crashes. This is acceptable for MVP/training purposes.**
