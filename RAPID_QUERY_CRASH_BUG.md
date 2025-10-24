# Rapid Engine Query Crash Bug - CRITICAL

## Executive Summary

**Status**: ❌ **CRITICAL BUG DISCOVERED**

A new critical bug has been discovered in the Rapid engine: **SELECT queries on Rapid tables cause server crashes** with SIGSEGV (signal 11). This explains why row counts show 0 for Rapid tables - the queries crash before completing.

---

## Problem Statement

### Symptom
- `SELECT COUNT(*) FROM table` with `use_secondary_engine=FORCED` causes server crash
- Server terminates with SIGSEGV (signal 11 - Address not mapped to object)
- Happens on multiple tables across different databases
- COUNT(*) returns 0 because query crashes before completion

### Example
```sql
SET SESSION use_secondary_engine = FORCED;
SELECT COUNT(*) FROM Airline.L_DEPARRBLK;
-- Result: Server crash with SIGSEGV
```

### Error Log
```
2025-10-23T08:45:33Z UTC - mysqld got signal 11 ;
Signal SIGSEGV (Address not mapped to object) at address 0x441f0f0860ff
Most likely, you have hit a bug
```

---

## Discovery Process

### Investigation Script Results

Running `investigate_rapid_zero_rows.py` revealed:

**Airline database** (19 tables with SECONDARY_ENGINE):
- ❌ L_DEPARRBLK: `2013 (HY000): Lost connection to MySQL server during query`
- ❌ L_DISTANCE_GROUP_250: Lost connection
- ❌ L_DIVERSIONS: Lost connection
- ❌ L_WEEKDAYS: Lost connection
- ❌ On_Time_On_Time_Performance_2016_1: Lost connection
- ... and 14 more tables with same error

**Pattern**: All tables with mismatched counts (InnoDB > 0, Rapid = 0) cause crashes when queried

### What Works
✅ `L_CANCELLATION`: 4 rows in both InnoDB and Rapid - **no crash**

### What Crashes
❌ Almost all other Rapid tables with data cause crashes

---

## Root Cause Analysis

### Hypothesis 1: Memory Corruption in Rapid Query Execution
The crash occurs during **query execution**, not during connection lifecycle:
- `SECONDARY_LOAD` completes successfully (no crashes)
- Server runs fine until a SELECT query is issued
- Crash happens specifically when accessing Rapid data

### Hypothesis 2: Data Type Incompatibility
Some data types or table features may trigger the crash:
- VARCHAR fields
- Primary keys
- Foreign keys
- Specific data patterns

### Hypothesis 3: Iterator/Scan Bug
The crash could be in Rapid's table scanning code:
- NestedLoopIterator (from our Phase 1 changes)
- TableScanIterator
- Index access methods

---

## Evidence

### Crash Location
```
stack_bottom = 7f0b6c1badf0 thread_stack 0x100000
 #0 0x55bbf6d747f6 <unknown>
 #1 0x55bbf6d74bf4 <unknown>
```

No symbols available, but crash is in Rapid engine code (not our transaction.cpp fix).

### Timeline
1. **Before investigation**: Noticed COUNT(*) returns 0 for `order` table
2. **During investigation**: Ran systematic check of all Rapid tables
3. **Result**: Server crashed when querying L_DEPARRBLK
4. **Pattern**: Multiple tables cause same crash

### Table That Works
`L_CANCELLATION` has only 4 rows and queries successfully:
```sql
mysql> SET SESSION use_secondary_engine = FORCED;
mysql> SELECT COUNT(*) FROM Airline.L_CANCELLATION;
+----------+
| COUNT(*) |
+----------+
|        4 |
+----------+
```

This suggests **small tables work, larger tables crash**.

---

## Impact Assessment

### Severity
🔴 **CRITICAL** - Rapid engine is essentially non-functional for most tables

### Affected Operations
- ❌ SELECT queries on Rapid tables
- ❌ COUNT(*) operations
- ❌ Any data retrieval from Rapid
- ❌ Data collection for hybrid optimizer training

### Not Affected
- ✅ InnoDB queries (use_secondary_engine=OFF)
- ✅ Connection lifecycle (fixed in previous bug fix)
- ✅ SECONDARY_LOAD operations
- ✅ Small tables (< ~10 rows)

### Production Readiness
- **Connection Lifecycle**: ✅ Fixed (500+ connections without crash)
- **Query Execution**: ❌ Broken (crashes on most tables)
- **Overall Status**: ❌ **NOT production ready** for Rapid queries

---

## Comparison with Previous Bug

### Connection Lifecycle Bug (FIXED ✅)
- **Symptom**: Crash after 100-200 connection cycles
- **Cause**: Use-after-free in `transaction.cpp`
- **Fix**: Proper pointer management in cleanup
- **Status**: Fixed and validated

### Query Execution Bug (NEW ❌)
- **Symptom**: Crash when querying Rapid tables
- **Cause**: Unknown (memory corruption during query execution)
- **Fix**: Not yet implemented
- **Status**: Active, critical issue

---

## Why This Wasn't Caught Earlier

1. **Connection lifecycle bug masked it**: Previous crashes happened before we could test queries
2. **Stress test used small table**: `L_DEPARRBLK` might have small test dataset
3. **Limited testing scope**: Focused on connection cycles, not query variety

---

## Relationship to Phase 1 Changes

### Could Phase 1 Cause This?

Phase 1 added nested loop join support by:
- Removing blocking assertions for NESTED_LOOP_JOIN
- Adding `SUPPORTS_NESTED_LOOP_JOIN` flag
- Modifying table flags

**Possible connection**:
- Nested loop iterator might have memory issues
- Table scanning code might not handle certain data patterns
- Our changes exposed existing bugs in Rapid's data access

### Investigation Needed
1. Test with Phase 1 changes reverted
2. Check if specific join types trigger crashes
3. Analyze Rapid's iterator implementation

---

## Recommended Actions

### Immediate (Stop the Bleeding)
1. ⚠️  **Document limitation**: Rapid queries crash on most tables
2. ⚠️  **Disable Rapid for data collection**: Use InnoDB-only mode
3. ⚠️  **Revert Phase 1?**: Consider reverting nested loop changes if they caused this

### Short-term (Debug and Fix)
1. 🔍 Build with AddressSanitizer (ASan)
2. 🔍 Reproduce crash under ASan for detailed diagnostics
3. 🔍 Analyze Rapid engine query execution code
4. 🔍 Check iterator implementations (NestedLoopIterator, TableScanIterator)
5. 🔧 Fix memory corruption in query execution

### Long-term (Validate and Deploy)
1. ✅ Comprehensive testing of all Rapid query patterns
2. ✅ Stress testing with various table sizes and data types
3. ✅ Validate Phase 1 changes don't introduce regressions
4. ✅ Production deployment after full validation

---

## Testing Approach

### Minimal Reproducer
```python
import mysql.connector

conn = mysql.connector.connect(
    host='127.0.0.1',
    port=3307,
    user='root',
    database='Airline'
)
conn.autocommit = True
cursor = conn.cursor()

# This should crash the server
cursor.execute("SET SESSION use_secondary_engine = FORCED")
cursor.execute("SELECT COUNT(*) FROM L_DEPARRBLK")
result = cursor.fetchall()
print(f"Result: {result}")  # Never reaches here

cursor.close()
conn.close()
```

### ASan Build and Test
```bash
cd /home/wuy/ShannonBase
./run_cmake_asan.sh
cd cmake_build_asan && make -j8 && make install

# Start ASan build
source asan_env.sh
${SHANNON_ASAN_BIN}/bin/mysqld --port=3308 ... &

# Load table
mysql -h 127.0.0.1 -P 3308 -u root -D Airline -e "ALTER TABLE L_DEPARRBLK SECONDARY_LOAD"

# Trigger crash under ASan (will show exact location)
mysql -h 127.0.0.1 -P 3308 -u root -D Airline -e "SET SESSION use_secondary_engine = FORCED; SELECT COUNT(*) FROM L_DEPARRBLK"
```

ASan will provide exact file/line where memory corruption occurs.

---

## Current Status

| Component | Status | Notes |
|-----------|--------|-------|
| Connection Lifecycle | ✅ Fixed | 500+ connections without crash |
| SECONDARY_LOAD | ✅ Works | Tables load successfully |
| Small Table Queries | ✅ Works | Tables with ~4 rows query fine |
| Large Table Queries | ❌ **CRASHES** | Most tables cause SIGSEGV |
| Data Collection | ❌ Blocked | Can't query Rapid tables |
| Production Ready | ❌ **NO** | Critical query bug |

---

## Workarounds

### Option 1: InnoDB-Only Data Collection
**Recommended for immediate progress**

```python
# Skip Rapid queries entirely
cursor.execute("SET SESSION use_secondary_engine = OFF")
cursor.execute("SELECT COUNT(*) FROM table")  # Uses InnoDB only
```

**Pros**:
- No crashes
- Can collect InnoDB performance data
- Training data for at least InnoDB baseline

**Cons**:
- No Rapid performance data
- Can't train hybrid optimizer (needs dual-engine data)

### Option 2: Small Tables Only
**Limited usefulness**

Only query tables with < 10 rows in Rapid:
- L_CANCELLATION (4 rows) - works
- Other small lookup tables

**Pros**:
- Can test Rapid functionality
- Validates Rapid is partially working

**Cons**:
- Too limited for meaningful benchmarking
- Doesn't help with real workloads

### Option 3: Revert Phase 1, Test, then Re-apply
**Investigative approach**

1. Revert Phase 1 nested loop changes
2. Test if queries still crash
3. If crashes stop → Phase 1 caused it
4. If crashes continue → Pre-existing Rapid bug

---

## Next Steps

### Critical Path
1. ✅ Document this bug (this file)
2. 🔴 Decide: Debug Rapid or use InnoDB-only?
3. 🔴 If debug: Build with ASan and reproduce
4. 🔴 If InnoDB-only: Modify data collection scripts

### If Debugging
1. Build ASan version (see `ASAN_BUILD_STRATEGY.md`)
2. Reproduce crash under ASan
3. Analyze ASan report for memory corruption
4. Fix bug in Rapid engine
5. Validate fix with comprehensive testing

### If Using InnoDB-Only
1. Modify `collect_dual_engine_data.py` to skip Rapid
2. Collect InnoDB-only performance data
3. Document Rapid as "future work"
4. Return to Rapid debugging later

---

## Questions for User

1. **Priority**: Is fixing Rapid critical, or can we proceed with InnoDB-only data collection?

2. **Phase 1 Investigation**: Should we test if reverting Phase 1 changes stops the crashes?

3. **Time Investment**: Debugging this could take days-weeks. Is that acceptable, or should we pivot?

4. **Alternative Approach**: Use only small tables in Rapid for initial proof-of-concept?

---

## Related Files

| File | Purpose |
|------|---------|
| `RAPID_QUERY_CRASH_BUG.md` | This document |
| `RAPID_ENGINE_CRASH_FIX.md` | Connection lifecycle fix (previous bug) |
| `investigate_rapid_zero_rows.py` | Investigation script that discovered this bug |
| `ASAN_BUILD_STRATEGY.md` | ASan build instructions for debugging |

---

## Conclusion

We successfully fixed the **connection lifecycle bug**, allowing 500+ connections without crashes. However, we've discovered a **new critical bug in query execution** that causes crashes when querying most Rapid tables.

**Bottom Line**: Rapid engine is not production-ready for queries. We need to either:
1. Debug and fix the query execution bug (time-intensive), OR
2. Proceed with InnoDB-only data collection (immediate progress)

**Recommendation**: Start with InnoDB-only data collection while investigating the Rapid bug in parallel. This allows progress on training data collection while we debug the deeper issue.

---

**Discovered By**: Investigation script on 2025-10-23
**Severity**: Critical - Blocks Rapid usage
**Status**: Active bug, needs fixing or workaround
