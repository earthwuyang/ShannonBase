#!/usr/bin/env python3
"""
Minimal reproducer for Rapid query crash.
Tests different scenarios to identify crash pattern.
"""

import mysql.connector
import sys

CONFIG = {
    'host': '127.0.0.1',
    'port': 3307,
    'user': 'root',
    'password': ''
}

def test_scenario(name, database, table, query_type="COUNT"):
    """Test a specific scenario"""
    print(f"\n[TEST] {name}")
    print(f"  Database: {database}, Table: {table}")

    try:
        conn = mysql.connector.connect(**CONFIG, database=database)
        conn.autocommit = True
        cursor = conn.cursor()

        # InnoDB count
        cursor.execute("SET SESSION use_secondary_engine = OFF")
        cursor.execute(f"SELECT COUNT(*) FROM `{table}`")
        innodb_count = cursor.fetchone()[0]
        print(f"  InnoDB count: {innodb_count}")

        # Rapid count
        cursor.execute("SET SESSION use_secondary_engine = FORCED")

        if query_type == "COUNT":
            query = f"SELECT COUNT(*) FROM `{table}`"
        elif query_type == "SELECT_STAR":
            query = f"SELECT * FROM `{table}` LIMIT 1"
        elif query_type == "SELECT_COL":
            # Get first column name
            cursor.execute(f"SHOW COLUMNS FROM `{table}`")
            col = cursor.fetchone()[0]
            query = f"SELECT `{col}` FROM `{table}` LIMIT 1"

        print(f"  Query: {query}")
        cursor.execute(query)
        result = cursor.fetchall()
        print(f"  Rapid result: {result}")
        print(f"  ✅ SUCCESS - No crash")

        cursor.close()
        conn.close()
        return True

    except mysql.connector.errors.OperationalError as e:
        if "2013" in str(e):
            print(f"  ❌ CRASH - Lost connection (2013)")
            return False
        else:
            print(f"  ❌ ERROR - {e}")
            return None
    except Exception as e:
        print(f"  ❌ ERROR - {e}")
        return None

def main():
    print("="*80)
    print("RAPID QUERY CRASH - MINIMAL REPRODUCER")
    print("="*80)

    # Test cases
    tests = [
        # Small table that works
        ("Small table (works)", "Airline", "L_CANCELLATION", "COUNT"),
        ("Small table SELECT", "Airline", "L_CANCELLATION", "SELECT_STAR"),

        # Medium tables
        ("Medium table COUNT", "Airline", "L_WEEKDAYS", "COUNT"),
        ("Medium table SELECT", "Airline", "L_WEEKDAYS", "SELECT_STAR"),

        # Large table
        ("Large table COUNT", "Airline", "L_AIRPORT", "COUNT"),

        # Financial order table
        ("Financial order COUNT", "financial", "order", "COUNT"),
    ]

    results = {}
    for test in tests:
        result = test_scenario(*test)
        results[test[0]] = result

        if result == False:  # Crash detected
            print("\n⚠️  CRASH DETECTED - Stopping tests to preserve server")
            break

    # Summary
    print("\n" + "="*80)
    print("SUMMARY")
    print("="*80)

    passed = [k for k, v in results.items() if v == True]
    crashed = [k for k, v in results.items() if v == False]
    errors = [k for k, v in results.items() if v == None]

    print(f"\n✅ Passed: {len(passed)}")
    for t in passed:
        print(f"  - {t}")

    if crashed:
        print(f"\n❌ Crashed: {len(crashed)}")
        for t in crashed:
            print(f"  - {t}")

    if errors:
        print(f"\n⚠️  Errors: {len(errors)}")
        for t in errors:
            print(f"  - {t}")

    return 0 if not crashed else 1

if __name__ == "__main__":
    sys.exit(main())
