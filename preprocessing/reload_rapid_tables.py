#!/usr/bin/env python3
"""
Reload tables into Rapid secondary engine before data collection

This ensures all tables are actually loaded in Rapid memory,
not just marked as SECONDARY_LOAD="1"
"""

import mysql.connector
import sys

DATABASES = ['tpch_sf1', 'tpcds_sf1', 'Airline', 'Credit', 'Carcinogenesis', 
             'Hepatitis_std', 'employee', 'financial', 'geneea']

CONFIG = {
    'host': '127.0.0.1',
    'port': 3307,
    'user': 'root',
    'password': ''
}

def reload_database_tables(database):
    """Reload all tables with SECONDARY_ENGINE in a database"""
    print(f"\nProcessing database: {database}")
    
    try:
        conn = mysql.connector.connect(**CONFIG, database=database)
        cursor = conn.cursor(buffered=True)
        
        # Get tables with SECONDARY_ENGINE
        cursor.execute("""
            SELECT TABLE_NAME, CREATE_OPTIONS
            FROM information_schema.tables
            WHERE table_schema = %s
            AND CREATE_OPTIONS LIKE '%%SECONDARY_ENGINE%%'
        """, (database,))
        
        tables = cursor.fetchall()
        
        if not tables:
            print(f"  No tables with SECONDARY_ENGINE found")
            cursor.close()
            conn.close()
            return
        
        print(f"  Found {len(tables)} tables with SECONDARY_ENGINE")
        
        for table_name, options in tables:
            # Check if already loaded
            if 'SECONDARY_LOAD="1"' in options or 'SECONDARY_LOAD=1' in options:
                print(f"  ✓ {table_name} - already loaded")
                continue
            
            # Try to load
            print(f"  Loading {table_name}...", end='', flush=True)
            try:
                cursor.execute(f"ALTER TABLE `{table_name}` SECONDARY_LOAD")
                conn.commit()
                print(" ✓")
            except mysql.connector.Error as e:
                if '3877' in str(e) and 'already loaded' in str(e):
                    print(" ✓ (already loaded)")
                else:
                    print(f" ✗ Error: {e}")
        
        cursor.close()
        conn.close()
        print(f"  ✅ {database} complete")
        
    except Exception as e:
        print(f"  ✗ Error processing {database}: {e}")

def main():
    print("=" * 60)
    print("Reloading tables into Rapid secondary engine")
    print("=" * 60)
    
    for db in DATABASES:
        reload_database_tables(db)
    
    print("\n" + "=" * 60)
    print("✅ All databases processed!")
    print("=" * 60)

if __name__ == "__main__":
    main()
