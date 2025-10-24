#!/usr/bin/env python3
"""
Load All Tables into Rapid Engine

This script loads all tables from specified databases into the Rapid secondary engine.
Must be run before collect_dual_engine_data.py to ensure tables are available in Rapid.

Usage:
    python3 load_all_tables_to_rapid.py --all
    python3 load_all_tables_to_rapid.py --database Airline
"""

import mysql.connector
import argparse
import sys

SHANNONBASE_CONFIG = {
    'host': '127.0.0.1',
    'port': 3307,
    'user': 'root',
    'password': ''
}

# Databases to load
AVAILABLE_DATABASES = [
    'Airline',
    'tpch_sf1', 
    'tpcds_sf1',
    'Credit',
    'Carcinogenesis',
    'Hepatitis_std',
    'employee',
    'financial',
    'geneea'
]

def load_tables_for_database(database):
    """Load all tables in a database into Rapid"""
    print(f"\n{'='*60}")
    print(f"Loading tables for database: {database}")
    print(f"{'='*60}")
    
    try:
        # Connect to database
        config = SHANNONBASE_CONFIG.copy()
        config['database'] = database
        conn = mysql.connector.connect(**config)
        cursor = conn.cursor()
        
        # Get all tables
        cursor.execute("""
            SELECT table_name 
            FROM information_schema.tables 
            WHERE table_schema = %s 
              AND table_type = 'BASE TABLE'
            ORDER BY table_name
        """, (database,))
        
        tables = [row[0] for row in cursor.fetchall()]
        
        if not tables:
            print(f"⚠️  No tables found in database: {database}")
            cursor.close()
            conn.close()
            return False
        
        print(f"Found {len(tables)} tables")
        
        # Load each table into Rapid
        loaded = 0
        failed = 0
        
        for table in tables:
            try:
                print(f"  Loading {table}...", end=" ", flush=True)
                # Use backticks to handle reserved keywords like 'order'
                cursor.execute(f"ALTER TABLE `{table}` SECONDARY_LOAD")
                print("✅")
                loaded += 1
            except mysql.connector.Error as e:
                error_msg = str(e)
                if '3877' in error_msg:  # Already loaded
                    print("✅ (already loaded)")
                    loaded += 1
                elif '3876' in error_msg:  # No secondary engine defined
                    print(f"⚠️  No SECONDARY_ENGINE defined")
                    # Define secondary engine first
                    try:
                        cursor.execute(f"ALTER TABLE `{table}` SECONDARY_ENGINE=RAPID")
                        cursor.execute(f"ALTER TABLE `{table}` SECONDARY_LOAD")
                        print(f"  Retrying {table}... ✅")
                        loaded += 1
                    except Exception as e2:
                        print(f"❌ Error: {e2}")
                        failed += 1
                else:
                    print(f"❌ Error: {error_msg}")
                    failed += 1
        
        cursor.close()
        conn.close()
        
        print(f"\nSummary for {database}:")
        print(f"  Total tables: {len(tables)}")
        print(f"  Loaded: {loaded}")
        print(f"  Failed: {failed}")
        
        return failed == 0
        
    except mysql.connector.Error as e:
        print(f"❌ Failed to connect to database {database}: {e}")
        return False
    except Exception as e:
        print(f"❌ Unexpected error for database {database}: {e}")
        return False


def main():
    parser = argparse.ArgumentParser(
        description='Load all tables into Rapid secondary engine',
        formatter_class=argparse.RawDescriptionHelpFormatter,
        epilog="""
Examples:
  # Load tables for all databases
  python3 load_all_tables_to_rapid.py --all

  # Load tables for specific database
  python3 load_all_tables_to_rapid.py --database Airline

  # Load tables for multiple specific databases
  python3 load_all_tables_to_rapid.py --database Airline --database tpch_sf1
        """)
    
    parser.add_argument('--all', action='store_true', default=True,
                       help='Load tables for all available databases')
    parser.add_argument('--database', type=str, action='append', dest='databases',
                       help='Database name (can be specified multiple times)')
    
    args = parser.parse_args()
    
    # Determine which databases to process
    if args.all:
        databases = AVAILABLE_DATABASES
        print(f"Loading tables for all {len(databases)} databases")
    elif args.databases:
        databases = args.databases
        print(f"Loading tables for {len(databases)} specified database(s)")
    else:
        print("Error: Must specify either --all or --database")
        print("Run with --help for usage information")
        sys.exit(1)
    
    # Load tables for each database
    results = {}
    for db in databases:
        success = load_tables_for_database(db)
        results[db] = success
    
    # Print final summary
    print(f"\n{'='*60}")
    print("FINAL SUMMARY")
    print(f"{'='*60}")
    
    successful = [db for db, success in results.items() if success]
    failed = [db for db, success in results.items() if not success]
    
    print(f"\nSuccessful: {len(successful)}/{len(databases)}")
    if successful:
        for db in successful:
            print(f"  ✅ {db}")
    
    if failed:
        print(f"\nFailed: {len(failed)}/{len(databases)}")
        for db in failed:
            print(f"  ❌ {db}")
    
    print("\n✅ All tables loaded into Rapid engine!")
    print("You can now run: python3 collect_dual_engine_data.py")
    
    sys.exit(0 if not failed else 1)


if __name__ == "__main__":
    main()
