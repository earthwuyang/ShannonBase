#!/usr/bin/env python3
"""
Minimal reproducer for Rapid engine connection lifecycle crash.
Tests connection open/close cycles with Rapid engine queries.
"""

import mysql.connector
import time
import sys
import argparse
from datetime import datetime

def test_connection_lifecycle(config, iterations=200, query_type='simple'):
    """
    Test connection lifecycle with various query types.

    Args:
        config: MySQL connection config
        iterations: Number of connection cycles (default 200 to trigger crash)
        query_type: 'simple', 'rapid', or 'complex'
    """

    queries = {
        'simple': "SELECT 1",
        'rapid': """
            SET SESSION use_secondary_engine = FORCED;
            SELECT COUNT(*) FROM test_table;
        """,
        'complex': """
            SET SESSION use_secondary_engine = FORCED;
            SELECT t1.col1, COUNT(*), AVG(t1.col2)
            FROM test_table t1
            JOIN test_table t2 ON t1.id = t2.id
            WHERE t1.col1 > 100
            GROUP BY t1.col1
            LIMIT 1000;
        """
    }

    query = queries.get(query_type, queries['simple'])
    crash_detected = False

    print(f"[{datetime.now()}] Starting connection lifecycle test")
    print(f"  Target: {iterations} iterations")
    print(f"  Query type: {query_type}")
    print(f"  Expected crash: ~100-200 connections")
    print("-" * 60)

    for i in range(1, iterations + 1):
        try:
            # Create new connection
            conn = mysql.connector.connect(**config)
            cursor = conn.cursor()

            # Execute query (may involve Rapid engine)
            for statement in query.strip().split(';'):
                if statement.strip():
                    cursor.execute(statement.strip())
                    if cursor.with_rows:
                        cursor.fetchall()  # Consume results

            # Close connection (this is where crash often happens)
            cursor.close()
            conn.close()

            # Progress reporting
            if i % 10 == 0:
                print(f"[{datetime.now()}] Iteration {i}/{iterations} - OK")

            # Small delay to simulate realistic connection pattern
            time.sleep(0.01)

        except mysql.connector.Error as e:
            print(f"\n[ERROR] Connection failed at iteration {i}")
            print(f"  Error: {e}")
            crash_detected = True
            break
        except KeyboardInterrupt:
            print(f"\n[INFO] Interrupted at iteration {i}")
            sys.exit(0)

    if not crash_detected:
        print(f"\n[SUCCESS] Completed {iterations} iterations without crash")
        print("  Note: Crash may require more iterations or different query pattern")

    return crash_detected

def setup_test_table(config, table_name='test_table', rows=10000):
    """
    Create and populate test table for Rapid engine testing.
    """
    print(f"[{datetime.now()}] Setting up test table: {table_name}")

    conn = mysql.connector.connect(**config)
    cursor = conn.cursor()

    # Create test database if needed
    cursor.execute("CREATE DATABASE IF NOT EXISTS test_rapid")
    cursor.execute("USE test_rapid")

    # Drop existing table
    cursor.execute(f"DROP TABLE IF EXISTS {table_name}")

    # Create table with appropriate structure for Rapid
    cursor.execute(f"""
        CREATE TABLE {table_name} (
            id INT PRIMARY KEY,
            col1 INT,
            col2 DECIMAL(10,2),
            col3 VARCHAR(100),
            col4 TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
            INDEX idx_col1 (col1)
        ) ENGINE=InnoDB
    """)

    # Insert test data
    print(f"  Inserting {rows} rows...")
    insert_query = f"""
        INSERT INTO {table_name} (id, col1, col2, col3)
        VALUES (%s, %s, %s, %s)
    """

    batch_size = 1000
    for batch_start in range(0, rows, batch_size):
        batch_data = [
            (i, i % 1000, float(i) * 1.5, f"test_value_{i}")
            for i in range(batch_start, min(batch_start + batch_size, rows))
        ]
        cursor.executemany(insert_query, batch_data)
        conn.commit()

        if (batch_start + batch_size) % 5000 == 0:
            print(f"    {batch_start + batch_size}/{rows} rows inserted")

    # Load table into Rapid engine (secondary engine)
    print("  Loading table into Rapid engine...")
    cursor.execute(f"ALTER TABLE {table_name} SECONDARY_ENGINE=rapid")
    cursor.execute(f"ALTER TABLE {table_name} SECONDARY_LOAD")

    # Wait for load to complete
    max_wait = 30
    for _ in range(max_wait):
        cursor.execute(f"""
            SELECT SECONDARY_ENGINE_LOAD_STATUS
            FROM information_schema.tables
            WHERE table_schema='test_rapid' AND table_name='{table_name}'
        """)
        result = cursor.fetchone()
        if result and result[0] == 'LOADED':
            print("  Table loaded into Rapid engine successfully")
            break
        time.sleep(1)
    else:
        print("  WARNING: Table load timeout - may not be in Rapid engine")

    cursor.close()
    conn.close()
    print(f"[{datetime.now()}] Test setup complete\n")

def main():
    parser = argparse.ArgumentParser(
        description='Test connection lifecycle to reproduce Rapid engine crash'
    )
    parser.add_argument('--host', default='127.0.0.1', help='MySQL host')
    parser.add_argument('--port', type=int, default=3308, help='MySQL port (ASan build: 3308)')
    parser.add_argument('--user', default='root', help='MySQL user')
    parser.add_argument('--password', default='', help='MySQL password')
    parser.add_argument('--iterations', type=int, default=200,
                       help='Number of connection cycles (default: 200)')
    parser.add_argument('--query-type', choices=['simple', 'rapid', 'complex'],
                       default='rapid', help='Query complexity level')
    parser.add_argument('--setup', action='store_true',
                       help='Setup test table before running test')
    parser.add_argument('--rows', type=int, default=10000,
                       help='Number of rows in test table (default: 10000)')

    args = parser.parse_args()

    config = {
        'host': args.host,
        'port': args.port,
        'user': args.user,
        'password': args.password,
        'database': 'test_rapid',
        'autocommit': True,
        'connection_timeout': 10
    }

    # Setup test table if requested
    if args.setup:
        setup_test_table(config, rows=args.rows)

    # Run connection lifecycle test
    crash_detected = test_connection_lifecycle(
        config,
        iterations=args.iterations,
        query_type=args.query_type
    )

    sys.exit(1 if crash_detected else 0)

if __name__ == '__main__':
    main()
