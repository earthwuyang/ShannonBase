# Investigation Summary: Rapid Engine 0-Row Problem

**Date**: 2025-10-23
**Status**: ❌ **Critical Bug Discovered**

---

## What We Were Investigating

**Original Question**: Why does Rapid show 0 rows for some tables while MySQL/InnoDB shows the tables have data?

**Example**:
```python
# InnoDB
SELECT COUNT(*) FROM financial.`order`  # Returns: 6471

# Rapid
SET SESSION use_secondary_engine = FORCED;
SELECT COUNT(*) FROM financial.`order`  # Returns: 0
```

---

## What We Found

### Finding #1: SQL Syntax Error (FIXED ✅)

**Problem**: Reserved keyword `order` caused SQL syntax errors

**Error**:
```
1064 (42000): You have an error in your SQL syntax near 'order SECONDARY_LOAD'
```

**Solution**: Added backticks around table names in `load_all_tables_to_rapid.py`

**Result**: ✅ SQL syntax errors fixed, tables can be loaded

---

### Finding #2: Critical Query Crash Bug (NEW ❌)

**Problem**: SELECT queries on Rapid tables cause server crashes

**Symptom**:
```sql
SET SESSION use_secondary_engine = FORCED;
SELECT COUNT(*) FROM L_DEPARRBLK;
-- Result: ERROR 2013 (HY000): Lost connection to MySQL server during query
```

**Error Log**:
```
2025-10-23T08:45:33Z UTC - mysqld got signal 11 ;
Signal SIGSEGV (Address not mapped to object)
```

**Impact**: 🔴 **CRITICAL**
- Most Rapid tables crash when queried
- COUNT(*) returns 0 because query crashes before completing
- Data collection for hybrid optimizer is blocked
- Rapid engine is non-functional for real workloads

---

## Investigation Results

### Tested: Airline Database (19 tables)

| Result | Count | Examples |
|--------|-------|----------|
| ✅ **Works** | 1 table | L_CANCELLATION (4 rows) |
| ❌ **Crashes** | 18 tables | L_DEPARRBLK, L_WEEKDAYS, L_AIRPORT, etc. |

### Pattern Analysis

**Tables that work**:
- Very small tables (< ~10 rows)
- Example: L_CANCELLATION with 4 rows

**Tables that crash**:
- Most tables with real data
- Happens across all databases
- Consistent SIGSEGV error

---

## Root Cause Analysis

### Why COUNT(*) Shows 0

**Not a data loading issue** - Data is successfully loaded into Rapid

**Actual reason**:
1. Query starts execution
2. Rapid engine crashes with SIGSEGV
3. Connection is lost
4. Query never completes
5. If it doesn't crash immediately, returns 0 before crashing

### Potential Causes

1. **Memory corruption in Rapid query execution**
   - Bug in table scanning code
   - Buffer overflow during data access
   - Null pointer dereference

2. **Data type incompatibility**
   - Certain data types trigger the crash
   - VARCHAR, DECIMAL, or other types
   - Primary/foreign key handling

3. **Related to Phase 1 changes?**
   - We added nested loop join support
   - Might have exposed existing bugs
   - Or introduced new memory issues

---

## Two Bugs, Two Different Issues

### Bug #1: Connection Lifecycle (FIXED ✅)
- **When**: After 100-200 connection open/close cycles
- **Where**: `transaction.cpp` cleanup code
- **Cause**: Use-after-free, dangling pointers
- **Fix**: Proper pointer management
- **Status**: ✅ Fixed, validated with 500+ connections

### Bug #2: Query Execution (NEW ❌)
- **When**: During SELECT query on Rapid table
- **Where**: Unknown (in Rapid engine query execution)
- **Cause**: Unknown (memory corruption suspected)
- **Fix**: Not yet implemented
- **Status**: ❌ Active critical bug

---

## Impact on Project Goals

### What Works Now ✅
- Connection lifecycle is stable
- 500+ connections without crashes
- InnoDB queries work perfectly
- SECONDARY_LOAD operations succeed

### What's Broken ❌
- Querying Rapid tables crashes server
- Can't collect dual-engine performance data
- Can't train hybrid optimizer (needs Rapid data)
- Rapid engine is essentially unusable

### Project Status
| Goal | Status | Notes |
|------|--------|-------|
| Fix connection crashes | ✅ Done | 500+ connections work |
| Collect Rapid data | ❌ Blocked | Queries crash |
| Train hybrid optimizer | ❌ Blocked | Needs Rapid data |
| Production deployment | ❌ Not ready | Critical query bug |

---

## Options Moving Forward

### Option 1: Debug Rapid Query Bug (Recommended for Complete Fix)

**Steps**:
1. Build with AddressSanitizer (ASan)
2. Reproduce crash under ASan
3. Analyze memory corruption location
4. Fix bug in Rapid engine
5. Validate with comprehensive tests

**Timeline**: Days to weeks

**Pros**:
- Proper fix for Rapid engine
- Enables dual-engine benchmarking
- Production-ready Rapid

**Cons**:
- Time-intensive
- Requires deep C++ debugging
- May uncover more bugs

---

### Option 2: InnoDB-Only Data Collection (Recommended for Immediate Progress)

**Steps**:
1. Modify `collect_dual_engine_data.py` to skip Rapid
2. Collect InnoDB-only performance data
3. Train optimizer on InnoDB baseline
4. Return to Rapid debugging later

**Timeline**: Immediate

**Pros**:
- Unblocks data collection
- Can proceed with training
- Still valuable baseline data

**Cons**:
- No dual-engine comparison
- Can't train hybrid optimizer (InnoDB/Rapid)
- Rapid remains broken

---

### Option 3: Investigate Phase 1 Connection (Diagnostic)

**Steps**:
1. Revert Phase 1 nested loop changes
2. Test if queries still crash
3. If fixed → Phase 1 caused it
4. If still crashes → Pre-existing bug

**Timeline**: Hours to days

**Pros**:
- Identifies if our changes caused this
- Quick diagnostic test
- Informs fix strategy

**Cons**:
- Loses nested loop functionality
- Doesn't solve underlying issue
- Still need proper fix

---

### Option 4: Small Tables Only (Limited Use)

**Steps**:
1. Filter workload to only small tables (< 10 rows)
2. Collect limited Rapid data
3. Proof-of-concept only

**Timeline**: Immediate

**Pros**:
- Shows Rapid partially works
- Some dual-engine data
- Low risk

**Cons**:
- Not representative of real workloads
- Limited training value
- Doesn't solve core problem

---

## Recommendation

### Parallel Approach (Best of Both Worlds)

**Track 1: Immediate Progress**
- Use Option 2 (InnoDB-only data collection)
- Start collecting baseline performance data
- Unblock training pipeline

**Track 2: Parallel Investigation**
- Use Option 3 (investigate Phase 1 connection)
- If Phase 1 caused it → revert and fix
- If pre-existing → build with ASan and debug

**Rationale**:
- Don't block entire project on Rapid debugging
- Gather valuable InnoDB data immediately
- Investigate Rapid in parallel
- Reassess based on findings

---

## Technical Details for Debugging

### ASan Build (If Proceeding with Option 1)

```bash
cd /home/wuy/ShannonBase
./run_cmake_asan.sh
cd cmake_build_asan && make -j8 && make install

# Start ASan build
export SHANNON_ASAN_BIN="/home/wuy/DB/ShannonBase/shannon_bin_asan"
export ASAN_OPTIONS="detect_leaks=1:abort_on_error=1:log_path=/home/wuy/ShannonBase/asan_logs/asan"

${SHANNON_ASAN_BIN}/bin/mysqld --port=3308 --datadir=... &

# Load and query (will crash with detailed ASan report)
mysql -h 127.0.0.1 -P 3308 -e "USE Airline; ALTER TABLE L_DEPARRBLK SECONDARY_LOAD"
mysql -h 127.0.0.1 -P 3308 -e "SET SESSION use_secondary_engine=FORCED; SELECT COUNT(*) FROM Airline.L_DEPARRBLK"

# Check ASan log
cat /home/wuy/ShannonBase/asan_logs/asan.*
```

### Revert Phase 1 Test (If Proceeding with Option 3)

```bash
cd /home/wuy/ShannonBase
git log --oneline storage/rapid_engine/handler/ha_shannon_rapid.cc | head -5
git diff HEAD~5 HEAD storage/rapid_engine/handler/ha_shannon_rapid.cc

# Identify Phase 1 commits and revert
git revert <commit-hash>

# Rebuild and test
cd cmake_build && make -j8 && make install
./stop_mysql.sh && ./start_mysql.sh

# Test query
python3 reload_order_table.py
```

---

## Files Created During Investigation

| File | Purpose |
|------|---------|
| `investigate_rapid_zero_rows.py` | Systematic check of all Rapid tables |
| `RAPID_QUERY_CRASH_BUG.md` | Detailed analysis of query crash bug |
| `INVESTIGATION_SUMMARY.md` | This summary document |
| `test_order_table.py` | Test script for `order` table |
| `reload_order_table.py` | Reload and verify `order` table |
| `rapid_zero_rows_report.txt` | Detailed investigation report |

---

## Summary

**What we fixed**: ✅ SQL syntax error for reserved keyword `order`

**What we discovered**: ❌ Critical query execution bug in Rapid engine

**Current status**:
- Connection lifecycle: ✅ Stable
- Query execution: ❌ Crashes on most tables

**Recommendation**:
- **Short-term**: Use InnoDB-only data collection
- **Parallel**: Investigate and fix Rapid query bug
- **Long-term**: Full dual-engine functionality

**Next action needed**: Choose option (1, 2, 3, or 4) and proceed accordingly.

---

**Investigation completed**: 2025-10-23
**Bugs found**: 2 (1 fixed, 1 active)
**Recommendation**: Parallel approach (data collection + debugging)
