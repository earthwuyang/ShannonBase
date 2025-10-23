#!/usr/bin/env python3
"""Test what query patterns Rapid secondary engine actually supports"""

import mysql.connector

CONFIG = {
    'host': '127.0.0.1',
    'port': 3307,
    'user': 'root',
    'password': '',
    'database': 'tpch_sf1'
}

test_queries = [
    ("Simple COUNT", "SELECT COUNT(*) FROM customer"),
    ("Simple SELECT", "SELECT c_custkey, c_name FROM customer LIMIT 10"),
    ("Simple WHERE", "SELECT COUNT(*) FROM customer WHERE c_acctbal > 1000"),
    ("Simple GROUP BY", "SELECT c_mktsegment, COUNT(*) FROM customer GROUP BY c_mktsegment"),
    ("Simple JOIN", "SELECT COUNT(*) FROM customer c INNER JOIN orders o ON c.c_custkey = o.o_custkey"),
    ("GROUP BY with aggregations", "SELECT c_mktsegment, COUNT(*), AVG(c_acctbal) FROM customer GROUP BY c_mktsegment"),
    ("Window function", "SELECT c_custkey, ROW_NUMBER() OVER (ORDER BY c_custkey) FROM customer LIMIT 10"),
    ("Subquery", "SELECT * FROM customer WHERE c_custkey IN (SELECT o_custkey FROM orders LIMIT 10)"),
    ("CTE", "WITH cte AS (SELECT * FROM customer LIMIT 10) SELECT * FROM cte"),
    ("UNION", "SELECT c_custkey FROM customer LIMIT 5 UNION SELECT c_custkey FROM customer LIMIT 5"),
]

def test_query(name, query):
    try:
        conn = mysql.connector.connect(**CONFIG)
        cursor = conn.cursor(buffered=True)
        
        # Force Rapid engine (now works with the assertion fix!)
        cursor.execute("SET SESSION use_secondary_engine = FORCED")
        
        # Try the query
        cursor.execute(query)
        _ = cursor.fetchall()
        
        cursor.close()
        conn.close()
        
        return True, "✓ Supported"
        
    except mysql.connector.Error as e:
        error_msg = str(e)
        if '3889' in error_msg or 'rejected by the secondary storage engine' in error_msg:
            return False, "✗ Rejected by Rapid"
        elif '3877' in error_msg or 'not been loaded' in error_msg:
            return False, "✗ Table not loaded"
        else:
            return False, f"✗ Error: {error_msg[:50]}"

print("=" * 70)
print("Testing Rapid Secondary Engine Query Support")
print("=" * 70)
print(f"{'Query Type':<30} {'Status':<40}")
print("-" * 70)

for name, query in test_queries:
    supported, msg = test_query(name, query)
    print(f"{name:<30} {msg:<40}")

print("=" * 70)
