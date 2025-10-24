#!/usr/bin/env python3
"""
Stress test for Rapid engine connection lifecycle bug.
Tests rapid connection open/close cycles to verify crash fix.
"""

import mysql.connector
import sys
import time
from datetime import datetime

def test_connection_stress(host='127.0.0.1', port=3307, user='root', database='Airline', iterations=500):
    """
    Stress test with rapid connection cycles.

    Args:
        host: MySQL host
        port: MySQL port
        user: MySQL user
        database: Database to test
        iterations: Number of connection cycles
    """
    print(f"[{datetime.now()}] Starting connection stress test...")
    print(f"Configuration: {host}:{port}, database={database}, iterations={iterations}")
    print("=" * 80)

    success_count = 0
    error_count = 0
    start_time = time.time()

    for i in range(iterations):
        try:
            # Open new connection
            conn = mysql.connector.connect(
                host=host,
                port=port,
                user=user,
                database=database
            )

            # CRITICAL: Enable autocommit for Rapid compatibility
            conn.autocommit = True

            cursor = conn.cursor()

            # Force Rapid engine
            cursor.execute("SET SESSION use_secondary_engine = FORCED")

            # Execute simple query
            cursor.execute("SELECT COUNT(*) FROM L_DEPARRBLK")
            result = cursor.fetchall()

            # Verify result
            if result and len(result) > 0:
                success_count += 1

            # Close connection (triggers cleanup code)
            cursor.close()
            conn.close()

            # Progress reporting
            if (i + 1) % 10 == 0:
                elapsed = time.time() - start_time
                rate = (i + 1) / elapsed
                print(f"[{datetime.now()}] Iteration {i+1}/{iterations} - "
                      f"Success: {success_count}, Errors: {error_count}, "
                      f"Rate: {rate:.2f} conn/sec")

        except Exception as e:
            error_count += 1
            print(f"[{datetime.now()}] ERROR at iteration {i+1}: {e}")
            if error_count > 10:
                print(f"\n❌ Too many errors ({error_count}), stopping test.")
                return False

    elapsed = time.time() - start_time
    print("\n" + "=" * 80)
    print(f"[{datetime.now()}] Test completed!")
    print(f"Total iterations: {iterations}")
    print(f"Successful: {success_count}")
    print(f"Errors: {error_count}")
    print(f"Total time: {elapsed:.2f} seconds")
    print(f"Average rate: {iterations/elapsed:.2f} connections/sec")

    if success_count == iterations:
        print("\n✅ SUCCESS: All connection cycles completed without crashes!")
        return True
    else:
        print(f"\n⚠️  WARNING: {error_count} errors occurred during test")
        return False

def test_reused_connection(host='127.0.0.1', port=3307, user='root', database='Airline', queries=200):
    """
    Test with reused connection (should work even with old bug).

    Args:
        host: MySQL host
        port: MySQL port
        user: MySQL user
        database: Database to test
        queries: Number of queries to execute
    """
    print(f"\n[{datetime.now()}] Testing reused connection...")
    print(f"Configuration: {host}:{port}, database={database}, queries={queries}")
    print("=" * 80)

    try:
        conn = mysql.connector.connect(
            host=host,
            port=port,
            user=user,
            database=database
        )
        conn.autocommit = True
        cursor = conn.cursor()
        cursor.execute("SET SESSION use_secondary_engine = FORCED")

        success_count = 0
        start_time = time.time()

        for i in range(queries):
            cursor.execute("SELECT COUNT(*) FROM L_DEPARRBLK")
            result = cursor.fetchall()
            if result:
                success_count += 1

            if (i + 1) % 50 == 0:
                elapsed = time.time() - start_time
                rate = (i + 1) / elapsed
                print(f"[{datetime.now()}] Query {i+1}/{queries} - Rate: {rate:.2f} queries/sec")

        cursor.close()
        conn.close()

        elapsed = time.time() - start_time
        print(f"\n✅ SUCCESS: Executed {success_count}/{queries} queries on single connection")
        print(f"Total time: {elapsed:.2f} seconds, Rate: {queries/elapsed:.2f} queries/sec")
        return True

    except Exception as e:
        print(f"\n❌ ERROR: {e}")
        return False

if __name__ == "__main__":
    import argparse

    parser = argparse.ArgumentParser(description='Stress test Rapid engine connection lifecycle')
    parser.add_argument('--host', default='127.0.0.1', help='MySQL host')
    parser.add_argument('--port', type=int, default=3307, help='MySQL port')
    parser.add_argument('--user', default='root', help='MySQL user')
    parser.add_argument('--database', default='Airline', help='Database to test')
    parser.add_argument('--iterations', type=int, default=500,
                       help='Number of connection cycles for stress test')
    parser.add_argument('--reused-only', action='store_true',
                       help='Only run reused connection test (should work even with bug)')

    args = parser.parse_args()

    print("=" * 80)
    print("RAPID ENGINE CONNECTION LIFECYCLE STRESS TEST")
    print("=" * 80)
    print(f"Purpose: Verify fix for crash after 100-200 connection cycles")
    print(f"Target: {args.host}:{args.port}")
    print(f"Database: {args.database}")
    print("=" * 80)

    # Test 1: Reused connection (baseline - should always work)
    print("\n[TEST 1] Reused Connection Test (Baseline)")
    reused_ok = test_reused_connection(args.host, args.port, args.user, args.database, queries=200)

    if args.reused_only:
        sys.exit(0 if reused_ok else 1)

    # Test 2: Rapid connection cycles (this should crash with old bug, pass with fix)
    print("\n[TEST 2] Rapid Connection Cycles (Stress Test)")
    stress_ok = test_connection_stress(args.host, args.port, args.user, args.database, args.iterations)

    # Final verdict
    print("\n" + "=" * 80)
    print("FINAL RESULTS")
    print("=" * 80)
    print(f"[TEST 1] Reused Connection: {'✅ PASS' if reused_ok else '❌ FAIL'}")
    print(f"[TEST 2] Connection Stress: {'✅ PASS' if stress_ok else '❌ FAIL'}")

    if reused_ok and stress_ok:
        print("\n🎉 ALL TESTS PASSED - Bug appears to be fixed!")
        sys.exit(0)
    elif reused_ok and not stress_ok:
        print("\n⚠️  Reused connections work but stress test fails")
        print("This indicates the connection lifecycle bug still exists")
        sys.exit(1)
    else:
        print("\n❌ Tests failed - basic connectivity issues")
        sys.exit(1)
