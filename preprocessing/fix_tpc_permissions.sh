#!/bin/bash
# Fix permissions for TPC-H and TPC-DS data files
# Run this if you encounter "Permission denied" errors during data cleaning

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

echo "Fixing file permissions for TPC data files..."

# Fix TPC-H files
if [ -d "${SCRIPT_DIR}/tpch-dbgen" ]; then
    echo "Fixing TPC-H .tbl files..."
    cd "${SCRIPT_DIR}/tpch-dbgen"
    chmod u+w *.tbl 2>/dev/null && echo "  ✓ Fixed TPC-H permissions" || echo "  ✗ No TPC-H .tbl files found"
fi

# Fix TPC-DS files
if [ -d "${SCRIPT_DIR}/tpcds_data" ]; then
    echo "Fixing TPC-DS .dat files..."
    cd "${SCRIPT_DIR}/tpcds_data"
    chmod u+w *.dat 2>/dev/null && echo "  ✓ Fixed TPC-DS permissions" || echo "  ✗ No TPC-DS .dat files found"
fi

echo ""
echo "Done! You can now run the setup scripts again."
echo ""
echo "To clean TPC-H data files:"
echo "  cd ${SCRIPT_DIR}/tpch-dbgen"
echo "  for f in *.tbl; do sed -i 's/|$//' \"\$f\"; done"
echo ""
echo "To clean TPC-DS data files:"
echo "  cd ${SCRIPT_DIR}/tpcds_data"  
echo "  for f in *.dat; do iconv -f LATIN1 -t UTF-8 \"\$f\" | sed 's/|$//' > \"\$f.clean\" && mv \"\$f.clean\" \"\$f\"; done"
