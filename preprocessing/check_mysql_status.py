#!/usr/bin/env python3
"""
Check MySQL/ShannonBase status to diagnose hanging imports
"""

import mysql.connector
import os

LOCAL_MYSQL_CONFIG = {
    'host': os.environ.get('LOCAL_MYSQL_HOST', '127.0.0.1'),
    'port': int(os.environ.get('LOCAL_MYSQL_PORT', '3307')),
    'user': os.environ.get('LOCAL_MYSQL_USER', 'root'),
    'password': os.environ.get('LOCAL_MYSQL_PASSWORD', 'shannonbase'),
}

def main():
    print("=" * 60)
    print("MySQL/ShannonBase Status Check")
    print("=" * 60)
    
    try:
        conn = mysql.connector.connect(**LOCAL_MYSQL_CONFIG)
        cursor = conn.cursor()
        
        print("\n✓ Connection successful\n")
        
        # Check processlist
        print("Active Processes:")
        print("-" * 60)
        cursor.execute("""
            SELECT ID, USER, HOST, DB, COMMAND, TIME, STATE, 
                   LEFT(INFO, 50) as INFO
            FROM information_schema.PROCESSLIST
            WHERE COMMAND != 'Sleep'
            ORDER BY TIME DESC
        """)
        
        rows = cursor.fetchall()
        if rows:
            for row in rows:
                print(f"  ID: {row[0]}")
                print(f"  User: {row[1]} | DB: {row[3]}")
                print(f"  Command: {row[4]} | Time: {row[5]}s")
                print(f"  State: {row[6]}")
                print(f"  Query: {row[7]}")
                print("-" * 60)
        else:
            print("  No active processes (other than this query)")
        
        # Check for locks
        print("\nTable Locks:")
        print("-" * 60)
        cursor.execute("""
            SELECT TABLE_SCHEMA, TABLE_NAME, TABLE_TYPE
            FROM information_schema.TABLES
            WHERE TABLE_SCHEMA = 'Airline'
            LIMIT 5
        """)
        
        tables = cursor.fetchall()
        if tables:
            print(f"  Found {len(tables)} tables in Airline database")
            for t in tables[:5]:
                print(f"    - {t[1]} ({t[2]})")
        else:
            print("  No tables in Airline database yet")
        
        # Check innodb status
        print("\nInnoDB Status (checking for deadlocks):")
        print("-" * 60)
        cursor.execute("SHOW ENGINE INNODB STATUS")
        status = cursor.fetchone()[2]
        
        if "DEADLOCK" in status:
            print("  ⚠ DEADLOCK DETECTED!")
            # Print relevant section
            lines = status.split('\n')
            for i, line in enumerate(lines):
                if 'DEADLOCK' in line:
                    print('\n'.join(lines[max(0, i-5):min(len(lines), i+10)]))
                    break
        else:
            print("  ✓ No deadlocks detected")
        
        # Check if foreign key checks are disabled
        cursor.execute("SHOW VARIABLES LIKE 'foreign_key_checks'")
        fk_status = cursor.fetchone()
        print(f"\nForeign Key Checks: {fk_status[1]}")
        
        cursor.close()
        conn.close()
        
    except Exception as e:
        print(f"\n✗ Error: {e}")
        return 1
    
    print("\n" + "=" * 60)
    print("To kill a hanging process:")
    print("  mysql -h 127.0.0.1 -P 3307 -u root -p -e 'KILL <ID>;'")
    print("\nTo disable foreign key checks globally:")
    print("  mysql -h 127.0.0.1 -P 3307 -u root -p -e 'SET GLOBAL FOREIGN_KEY_CHECKS=0;'")
    print("=" * 60)

if __name__ == "__main__":
    main()
