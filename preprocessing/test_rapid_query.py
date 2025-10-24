#!/usr/bin/env python3
"""Test script to debug why queries are failing in collect_dual_engine_data.py"""

import mysql.connector

SHANNONBASE_CONFIG = {
    'host': '127.0.0.1',
    'port': 3307,
    'user': 'root',
    'password': ''
}

# Test query from workload
query = """SELECT L_DEPARRBLK.Code, COUNT(*) AS total_count 
FROM L_DEPARRBLK 
WHERE L_DEPARRBLK.Description LIKE '%' AND L_DEPARRBLK.Code LIKE '%' 
GROUP BY L_DEPARRBLK.Code"""

print("="*60)
print("Testing Rapid Query Execution")
print("="*60)

try:
    # Connect
    config = SHANNONBASE_CONFIG.copy()
    config['database'] = 'Airline'
    conn = mysql.connector.connect(**config)
    cursor = conn.cursor(buffered=True)
    
    print("\n1. Setting up session...")
    cursor.execute("SET SESSION use_secondary_engine = FORCED")
    cursor.execute("SET SESSION max_execution_time = 60000")
    cursor.execute("SET optimizer_trace='enabled=on'")
    cursor.execute("SET optimizer_trace_max_mem_size=1048576")
    print("  ✅ Session configured")
    
    print("\n2. Executing query for feature extraction...")
    cursor.execute(query)
    results = cursor.fetchall()
    print(f"  ✅ Query executed, got {len(results)} rows")
    
    print("\n3. Extracting optimizer trace...")
    cursor.execute("SELECT TRACE FROM information_schema.OPTIMIZER_TRACE")
    trace_result = cursor.fetchone()
    if trace_result:
        trace = trace_result[0]
        print(f"  ✅ Trace extracted, length: {len(trace)} chars")
        
        # Check for rejection
        if "rejected_by_secondary_engine" in trace or "not_supported_by_secondary_engine" in trace:
            print("  ⚠️  WARNING: Query was rejected by Rapid!")
        else:
            print("  ✅ Query was NOT rejected")
    
    print("\n4. Executing query again for timing...")
    cursor.execute(query)
    results2 = cursor.fetchall()
    print(f"  ✅ Query executed again, got {len(results2)} rows")
    
    cursor.close()
    conn.close()
    
    print("\n" + "="*60)
    print("✅ ALL TESTS PASSED - Query works correctly!")
    print("="*60)
    
except mysql.connector.Error as e:
    error_msg = str(e)
    print(f"\n❌ ERROR: {error_msg}")
    if '3889' in error_msg:
        print("  This is the 'Secondary engine operation failed' error")
    print("\n" + "="*60)
    print("❌ TEST FAILED")
    print("="*60)
except Exception as e:
    print(f"\n❌ UNEXPECTED ERROR: {e}")
    print("\n" + "="*60)
    print("❌ TEST FAILED")
    print("="*60)
