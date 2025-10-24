# Rapid Query Crash - Debug Status

**Date**: 2025-10-23
**Status**: At decision point - need to choose debugging approach

---

## Current Situation

### What We Know
1. ✅ **Connection lifecycle bug** - FIXED (transaction.cpp)
2. ❌ **Query execution crash** - Active, blocking Rapid usage
3. ✅ **Phase 1 changes** - Present in codebase (nested loop support)
4. ❌ **Our connection fix** - NOT committed, so not the cause of query crash

### Crash Pattern
- `SELECT COUNT(*) FROM table` with Rapid crashes server
- SIGSEGV (signal 11) - Address not mapped
- Happens on most tables with data
- Small tables (< 10 rows) work fine

### Phase 1 Status
**Phase 1 IS implemented** in the codebase:
- File: `storage/rapid_engine/handler/ha_shannon_rapid.cc`
- Line 1019: `case AccessPath::NESTED_LOOP_JOIN:` - no blocking assertion
- Line 1739: `SecondaryEngineFlag::SUPPORTS_NESTED_LOOP_JOIN` - flag set
- Comments show: "PHASE 1: Now supporting nested loop joins"

**Timeline unclear**: Phase 1 changes were made sometime before our work, but:
- No specific Phase 1 git commits found
- Changes appear to be integrated into main branch
- README documents Phase 1 as complete

### Hypothesis
**Phase 1 may have exposed a bug** in Rapid's query execution:
- Removing assertions allowed queries to proceed
- But Rapid's nested loop iterator or table scanner has bugs
- Crashes when accessing certain data patterns or table sizes

---

## Two Debugging Approaches

### Option A: Revert Phase 1 and Test (Fast - 1 hour)

**Process**:
1. Backup current ha_shannon_rapid.cc
2. Add back blocking assertions for NESTED_LOOP_JOIN
3. Remove SUPPORTS_NESTED_LOOP_JOIN flag
4. Rebuild (30 min)
5. Test queries

**Expected Results**:
- **If crashes stop**: Phase 1 changes triggered the bug
- **If crashes continue**: Pre-existing bug, Phase 1 just exposed it OR unrelated

**Pros**:
- Fast (1 hour total)
- Definitive answer about Phase 1 involvement
- Can proceed with targeted fix

**Cons**:
- Loses Phase 1 functionality temporarily
- If Phase 1 isn't the cause, we wasted time
- Doesn't tell us WHERE the bug is

---

### Option B: Build with ASan and Debug (Thorough - 3-4 hours)

**Process**:
1. Build with AddressSanitizer (`make -j$(nproc)`) - 60-90 min
2. Initialize ASan database - 10 min
3. Start ASan server on port 3308
4. Reproduce crash under ASan - 5 min
5. Analyze ASan report - 30-60 min

**Expected Results**:
- **Exact file and line** where crash occurs
- **Memory issue type** (use-after-free, buffer overflow, etc.)
- **Stack traces** showing allocation/free/access
- **Root cause identified** with precision

**Pros**:
- Precise diagnosis - exact file:line
- No guessing - AS an tells us what's wrong
- Can fix the actual bug
- Professional debugging approach

**Cons**:
- Takes longer (3-4 hours total)
- Build uses significant resources
- More complex process

---

### Option C: Hybrid Approach (Pragmatic - 2 hours)

**Process**:
1. **First** (20 min): Quick Phase 1 revert test
   - Add back one assertion: `ut_a(false)` at line 1019
   - Rebuild with `-j$(nproc)`
   - Test one query

2. **If still crashes** (proceed to ASan):
   - Phase 1 not the cause
   - Need ASan for precision

3. **If crash stops** (investigate Phase 1):
   - Focus on nested loop iterator code
   - Look for memory issues in table scanning
   - Targeted fix without full ASan

**Pros**:
- Best of both approaches
- Fast initial test
- Falls back to thorough debugging if needed
- Minimizes wasted effort

**Cons**:
- Two-phase process
- If Phase 1 isn't the cause, delays ASan by 20 min

---

## Recommendation: Option C (Hybrid)

**Rationale**:
1. **Quick Phase 1 test** (20 min) tells us if we're on the right track
2. **If Phase 1 caused it**: We can focus investigation on nested loop code
3. **If Phase 1 didn't cause it**: We know we need ASan, only 20 min lost

**Implementation**:

### Step 1: Quick Phase 1 Revert Test
```bash
# Backup current file
cp storage/rapid_engine/handler/ha_shannon_rapid.cc storage/rapid_engine/handler/ha_shannon_rapid.cc.backup

# Add blocking assertion back (temporarily)
# Edit line 1019 to add: ut_a(false);  // TEMPORARY TEST

# Rebuild quickly
cd cmake_build && make -j$(nproc) && make install

# Restart server
./stop_mysql.sh && ./start_mysql.sh

# Test ONE query
mysql -h 127.0.0.1 -P 3307 -u root -D Airline -e "
SET SESSION use_secondary_engine = FORCED;
SELECT COUNT(*) FROM L_CANCELLATION;
"
# This should work (small table)

mysql -h 127.0.0.1 -P 3307 -u root -D Airline -e "
SET SESSION use_secondary_engine = FORCED;
SELECT COUNT(*) FROM L_WEEKDAYS;
"
# This crashes normally - will it crash with assertion?
# If it hits the assertion instead of crashing, Phase 1 is involved
```

### Step 2A: If Assertion Hit (Phase 1 involved)
- Investigate nested loop iterator code
- Look at table scanning implementation
- Check for memory management issues in those paths

### Step 2B: If Still Crashes (Phase 1 not the cause)
- Restore backup
- Proceed with full ASan build
- Get exact diagnostics

---

## Decision Point

**Need user input**: Which approach?

1. **Option A**: Revert Phase 1, test, see if crashes stop
2. **Option B**: Go straight to ASan for precision
3. **Option C**: Hybrid - quick Phase 1 test, then ASan if needed

**My recommendation**: Option C (Hybrid) - best balance of speed and thoroughness

---

## Current Build Status

### ASan Build
- **Status**: Started but killed (was taking too long)
- **Command used**: `cmake ../ -DWITH_ASAN=ON`
- **Issue**: Used `make -j8` instead of `make -j$(nproc)`
- **Restart command**: `cd cmake_build_asan && make -j$(nproc)`
- **Expected time**: 60-90 minutes with full parallelism

### Production Build
- **Status**: Current, running on port 3307
- **Has**: Phase 1 changes (nested loop support)
- **Has**: Our connection lifecycle fixes (not committed)
- **Issue**: Query execution crashes

---

## Files Modified (Not Committed)

| File | Changes | Status |
|------|---------|--------|
| `storage/rapid_engine/trx/transaction.cpp` | Connection lifecycle fix | Not committed |
| `preprocessing/load_all_tables_to_rapid.py` | Reserved keyword fix | Not committed |

---

## Next Steps (Awaiting Decision)

**If Option A chosen**:
1. Add blocking assertion to line 1019
2. Rebuild with `make -j$(nproc)`
3. Test queries
4. Analyze results

**If Option B chosen**:
1. Resume AS an build: `cd cmake_build_asan && make -j$(nproc)`
2. Wait 60-90 minutes
3. Initialize and start ASan server
4. Reproduce crash with detailed diagnostics

**If Option C chosen** (RECOMMENDED):
1. Quick assertion test (20 min)
2. If inconclusive, proceed to ASan
3. Best use of time with fallback option

---

**Status**: Waiting for decision on debugging approach
**Estimated time to resolution**:
- Option A: 1 hour
- Option B: 3-4 hours
- Option C: 20 min - 3 hours (depending on Phase 1 test result)
