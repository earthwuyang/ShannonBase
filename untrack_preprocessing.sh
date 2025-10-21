#!/bin/bash
# Untrack large preprocessing files that are now in .gitignore

echo "Untracking large preprocessing files..."

# Remove from git index (but keep files on disk)
git rm -r --cached preprocessing/ctu_data 2>/dev/null || true
git rm -r --cached preprocessing/tpcds_data 2>/dev/null || true
git rm -r --cached preprocessing/tpch-dbgen 2>/dev/null || true
git rm -r --cached preprocessing/test_workloads 2>/dev/null || true
git rm -r --cached preprocessing/training_workloads 2>/dev/null || true
git rm -r --cached preprocessing/databricks-tpcds 2>/dev/null || true
git rm -r --cached preprocessing/__pycache__ 2>/dev/null || true
git rm -r --cached preprocessing/hybrid_optimizer_training 2>/dev/null || true

# Optional: Also untrack cross_db_benchmark (contains .git subdirectories)
# Uncomment if you don't want to track this:
# git rm -r --cached preprocessing/cross_db_benchmark 2>/dev/null || true

# Also untrack db/data (large database files)
git rm -r --cached db/data 2>/dev/null || true

echo ""
echo "✓ Files untracked from git (but still on disk)"
echo ""
echo "Now check status:"
echo "  git status"
echo ""
echo "If looks good, commit the changes:"
echo "  git add .gitignore"
echo "  git commit -m 'chore: untrack large data files and build artifacts'"
echo ""
