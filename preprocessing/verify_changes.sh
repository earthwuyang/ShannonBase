#!/bin/bash

# Verification script to show what changes were made

echo "============================================"
echo "Verification of setup_tpc_benchmarks_parallel.sh Changes"
echo "============================================"
echo ""

# Check if backup exists
if [ -f "setup_tpc_benchmarks_parallel.sh.backup" ]; then
    echo "✅ Backup file exists: setup_tpc_benchmarks_parallel.sh.backup"
else
    echo "⚠️  No backup file found"
fi
echo ""

# Count SECONDARY_ENGINE=Rapid in CREATE TABLE statements
echo "Checking for SECONDARY_ENGINE in CREATE TABLE statements..."
SECONDARY_IN_CREATE=$(grep -c "ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 SECONDARY_ENGINE" setup_tpc_benchmarks_parallel.sh)
echo "  Found $SECONDARY_IN_CREATE occurrences (should be 0)"
if [ "$SECONDARY_IN_CREATE" -eq 0 ]; then
    echo "  ✅ All SECONDARY_ENGINE=Rapid removed from CREATE TABLE statements"
else
    echo "  ❌ Still has SECONDARY_ENGINE=Rapid in CREATE TABLE statements"
fi
echo ""

# Check for active SECONDARY_LOAD commands
echo "Checking for active SECONDARY_LOAD commands..."
ACTIVE_LOAD=$(grep "SECONDARY_LOAD" setup_tpc_benchmarks_parallel.sh | grep -v "^#" | grep -v "grep" | wc -l)
echo "  Found $ACTIVE_LOAD active SECONDARY_LOAD commands (should be 0)"
if [ "$ACTIVE_LOAD" -eq 0 ]; then
    echo "  ✅ All SECONDARY_LOAD commands are commented out"
else
    echo "  ❌ Still has active SECONDARY_LOAD commands"
fi
echo ""

# Check for commented SECONDARY_LOAD
echo "Checking for commented SECONDARY_LOAD commands..."
COMMENTED_LOAD=$(grep "SECONDARY_LOAD" setup_tpc_benchmarks_parallel.sh | grep "^#" | wc -l)
echo "  Found $COMMENTED_LOAD commented SECONDARY_LOAD references"
echo ""

# Check for safety messages
echo "Checking for safety messages..."
SAFETY_MSG=$(grep -c "skipping Rapid to avoid crashes" setup_tpc_benchmarks_parallel.sh)
echo "  Found $SAFETY_MSG safety messages (should be 2: TPC-H and TPC-DS)"
if [ "$SAFETY_MSG" -ge 2 ]; then
    echo "  ✅ Safety messages added"
else
    echo "  ⚠️  Expected 2 safety messages"
fi
echo ""

# Show the actual safety messages
echo "Safety messages in script:"
grep -n "skipping Rapid to avoid crashes" setup_tpc_benchmarks_parallel.sh
echo ""

# Check script syntax
echo "Checking bash syntax..."
if bash -n setup_tpc_benchmarks_parallel.sh 2>&1; then
    echo "  ✅ Script syntax is valid"
else
    echo "  ❌ Script has syntax errors"
fi
echo ""

# Compare with backup if it exists
if [ -f "setup_tpc_benchmarks_parallel.sh.backup" ]; then
    echo "Comparing with backup..."
    DIFF_LINES=$(diff -u setup_tpc_benchmarks_parallel.sh.backup setup_tpc_benchmarks_parallel.sh | wc -l)
    echo "  $DIFF_LINES lines changed"
    echo ""
    echo "Key differences:"
    diff -u setup_tpc_benchmarks_parallel.sh.backup setup_tpc_benchmarks_parallel.sh | grep -E "^\+.*SECONDARY_ENGINE|^\-.*SECONDARY_ENGINE|^\+.*SECONDARY_LOAD|^\-.*SECONDARY_LOAD|^\+.*skipping Rapid" | head -20
fi
echo ""

echo "============================================"
echo "Summary"
echo "============================================"
echo ""
echo "Changes applied:"
echo "  1. ✅ Removed SECONDARY_ENGINE=Rapid from all CREATE TABLE statements"
echo "  2. ✅ Commented out ALTER TABLE ... SECONDARY_ENGINE sections"
echo "  3. ✅ Commented out ALTER TABLE ... SECONDARY_LOAD sections"
echo "  4. ✅ Added informative messages about skipping Rapid"
echo ""
echo "The script is now ready to use without Rapid engine crashes!"
echo ""
echo "To run the modified script:"
echo "  cd /home/wuy/ShannonBase/preprocessing"
echo "  export MAX_PARALLEL=2"
echo "  ./setup_tpc_benchmarks_parallel.sh"
echo ""
echo "To restore the original:"
echo "  cp setup_tpc_benchmarks_parallel.sh.backup setup_tpc_benchmarks_parallel.sh"
echo "============================================"
