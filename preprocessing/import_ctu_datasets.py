#!/usr/bin/env python3
"""
Import specific CTU benchmark datasets into a local MySQL server.

This script pulls the following datasets from the CTU MySQL server and imports
them into a local MySQL instance:
- airline
- credit
- carcinogenesis
- employee
- financial
- geneea
- hepatitis
"""

import argparse
import csv
import json
import os
import sys
from datetime import datetime
from pathlib import Path

import mysql.connector
from mysql.connector import Error as MySQLError
from tqdm import tqdm

# CTU MySQL Server Configuration
MYSQL_CONFIG = {
    'host': 'relational.fel.cvut.cz',
    'port': 3306,
    'user': 'guest',
    'password': 'ctu-relational'
}

# Local MySQL Configuration (minimal for ShannonBase compatibility)
LOCAL_MYSQL_CONFIG = {
    'host': os.environ.get('LOCAL_MYSQL_HOST', '127.0.0.1'),
    'port': int(os.environ.get('LOCAL_MYSQL_PORT', '3307')),
    'user': os.environ.get('LOCAL_MYSQL_USER', 'root'),
    'password': os.environ.get('LOCAL_MYSQL_PASSWORD', 'shannonbase'),
    'allow_local_infile': True  # Required for LOAD DATA LOCAL INFILE
    # Note: Don't specify auth_plugin - let connector auto-negotiate
    # ShannonBase uses caching_sha2_password (root user), mysql_native_password is DISABLED
}

# Datasets to import (with correct case from CTU server)
SELECTED_DATABASES = [
    'Airline',
    'Credit',
    'Carcinogenesis',
    'employee',
    'financial',
    'geneea',
    'Hepatitis_std'  # Note: hepatitis is called Hepatitis_std on CTU
]

# Base directory for data storage
BASE_DIR = Path(__file__).resolve().parent
DATA_DIR = BASE_DIR / 'ctu_data'

class CTUDatasetImporter:
    def __init__(self, force: bool = False):
        self.mysql_conn = None
        self.local_mysql_conn = None
        self.force = force
        self.stats = {
            'databases_imported': 0,
            'tables_imported': 0,
            'total_rows': 0,
            'start_time': datetime.now()
        }
        
    def connect(self):
        """Connect to source (CTU) MySQL and local MySQL"""
        print("🔌 Connecting to databases...")

        # Connect to CTU MySQL server
        print("  Connecting to CTU MySQL server...")
        try:
            self.mysql_conn = mysql.connector.connect(**MYSQL_CONFIG)
            print("  ✓ Connected to CTU MySQL server")
        except Exception as e:
            print(f"  ✗ Failed to connect to CTU MySQL: {e}")
            sys.exit(1)

        # Connect to local MySQL server
        print("  Connecting to local MySQL server...")
        try:
            self.local_mysql_conn = self.connect_local_mysql()
            print("  ✓ Connected to local MySQL")
            
            # Try to enable local_infile on server side
            try:
                cursor = self.local_mysql_conn.cursor(buffered=True)
                cursor.execute("SET GLOBAL local_infile = 1")
                cursor.close()
                print("  ✓ Enabled local_infile on server")
            except Exception as e:
                print(f"  ⚠ Note: Could not enable local_infile on server: {e}")
                print("    If you get 'Loading local data is disabled' errors, run:")
                print("    SET GLOBAL local_infile = 1;")
                
        except Exception as e:
            print(f"  ✗ Failed to connect to local MySQL: {e}")
            print("  Configure LOCAL_MYSQL_* environment variables or LOCAL_MYSQL_AUTH_PLUGIN if needed.")
            sys.exit(1)

    def connect_local_mysql(self):
        """Connect to ShannonBase MySQL using auto-negotiated authentication."""
        # Use minimal config - let MySQL connector auto-negotiate auth method
        # ShannonBase has mysql_native_password DISABLED, uses caching_sha2_password
        return mysql.connector.connect(**LOCAL_MYSQL_CONFIG)
    
    def get_mysql_column_types(self, database, table):
        """Get column types from MySQL"""
        cursor = self.mysql_conn.cursor(buffered=True)
        cursor.execute(f"USE `{database}`")
        cursor.execute(f"""
            SELECT COLUMN_NAME, DATA_TYPE, COLUMN_TYPE, IS_NULLABLE, COLUMN_KEY
            FROM INFORMATION_SCHEMA.COLUMNS
            WHERE TABLE_SCHEMA = '{database}' AND TABLE_NAME = '{table}'
            ORDER BY ORDINAL_POSITION
        """)
        
        columns = {}
        for row in cursor.fetchall():
            col_name, data_type, col_type, nullable, key = row
            columns[col_name] = {
                'mysql_type': data_type.upper(),
                'full_type': col_type,
                'nullable': nullable == 'YES',
                'is_primary': key == 'PRI'
            }
        
        cursor.close()
        return columns
    
    def export_to_csv(self, database, table, output_path):
        """Export MySQL table to CSV"""
        cursor = self.mysql_conn.cursor(buffered=True)
        cursor.execute(f"USE `{database}`")
        
        # Get column info
        column_types = self.get_mysql_column_types(database, table)
        columns = list(column_types.keys())
        
        # Count rows first
        count_cursor = self.mysql_conn.cursor(buffered=True)
        count_cursor.execute(f"USE `{database}`")
        count_cursor.execute(f"SELECT COUNT(*) FROM `{table}`")
        total_rows = count_cursor.fetchone()[0]
        count_cursor.close()
        
        # Export data
        cursor.execute(f"SELECT * FROM `{table}`")
        
        os.makedirs(os.path.dirname(output_path), exist_ok=True)
        
        with open(output_path, 'w', newline='', encoding='utf-8') as csvfile:
            writer = csv.writer(csvfile, lineterminator='\n')
            writer.writerow(columns)  # Header
            
            batch_size = 10000
            row_count = 0
            
            with tqdm(total=total_rows, desc=f"    Exporting {table}", unit=" rows") as pbar:
                while True:
                    rows = cursor.fetchmany(batch_size)
                    if not rows:
                        break
                    
                    for row in rows:
                        processed_row = []
                        for i, val in enumerate(row):
                            if val is None:
                                processed_row.append('')
                            elif isinstance(val, bytes):
                                processed_row.append(val.decode('utf-8', errors='ignore'))
                            elif isinstance(val, datetime):
                                processed_row.append(val.isoformat())
                            else:
                                processed_row.append(val)
                        writer.writerow(processed_row)
                        row_count += 1
                    pbar.update(len(rows))
        
        cursor.close()
        return row_count, columns, column_types
    
    def import_database(self, database):
        """Import a database from CTU MySQL to local MySQL"""
        print(f"\n📦 Processing dataset: {database}")
        
        # Check if database exists on MySQL
        cursor = self.mysql_conn.cursor(buffered=True)
        cursor.execute("SHOW DATABASES")
        databases = [db[0] for db in cursor.fetchall()]
        cursor.close()
        
        if database not in databases:
            print(f"  ✗ Database '{database}' not found on CTU server")
            return False
        
        # Get list of tables
        cursor = self.mysql_conn.cursor(buffered=True)
        cursor.execute(f"USE `{database}`")
        cursor.execute("SHOW TABLES")
        tables = [t[0] for t in cursor.fetchall()]
        cursor.close()
        
        if not tables:
            print(f"  ✗ No tables in database '{database}'")
            return False
        
        print(f"  Found {len(tables)} tables: {', '.join(tables)}")

        if not self.ensure_local_mysql_database(database):
            return False
        
        target_config = LOCAL_MYSQL_CONFIG.copy()
        target_config['database'] = database
        target_config['charset'] = 'utf8mb4'  # Match CTU server charset
        target_conn = None
        try:
            target_conn = mysql.connector.connect(**target_config)
        except Exception as e:
            print(f"  ✗ Failed to connect to local MySQL database '{database}': {e}")
            return False
        
        target_cursor = target_conn.cursor()
        target_cursor.execute("SET foreign_key_checks = 0")
        target_conn.commit()
        
        # Export and import each table
        data_dir = DATA_DIR / database
        data_dir.mkdir(parents=True, exist_ok=True)
        
        total_rows = 0
        for table in tables:
            print(f"\n  📋 Processing table: {table}")
            
            csv_path = data_dir / f"{table}.csv"
            
            # Export from MySQL if needed
            if self.force or not csv_path.exists():
                print("    Exporting from MySQL...")
                row_count, columns, column_types = self.export_to_csv(
                    database, table, str(csv_path)
                )
                print(f"    ✓ Exported {row_count:,} rows to CSV")
            else:
                print("    Using cached CSV file")
                column_types = self.get_mysql_column_types(database, table)
                columns = list(column_types.keys())
                # Count rows in CSV
                with open(csv_path, 'r') as f:
                    row_count = sum(1 for _ in f) - 1  # Subtract header
            
            if not self.create_mysql_table(database, table, target_conn):
                continue
            
            if self.load_csv_into_mysql(table, columns, str(csv_path), target_conn):
                total_rows += row_count
                self.stats['tables_imported'] += 1

        target_cursor.execute("SET foreign_key_checks = 1")
        target_conn.commit()
        target_cursor.close()
        target_conn.close()
        
        # Update stats
        self.stats['databases_imported'] += 1
        self.stats['total_rows'] += total_rows
        
        print(f"\n  ✅ Successfully imported {database}")
        return True

    def ensure_local_mysql_database(self, database):
        """Create or recreate the target MySQL database."""
        cursor = self.local_mysql_conn.cursor(buffered=True)
        cursor.execute("SHOW DATABASES LIKE %s", (database,))
        exists = cursor.fetchone() is not None

        if exists and not self.force:
            print(f"    Database '{database}' already exists (use --force to recreate)")
            cursor.close()
            return True

        if exists and self.force:
            print(f"    Dropping existing database '{database}'...")
            cursor.execute(f"DROP DATABASE `{database}`")

        try:
            cursor.execute(
                f"CREATE DATABASE `{database}` CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci"
            )
            print(f"    ✓ Created database: {database}")
            cursor.close()
            return True
        except Exception as e:
            print(f"    ✗ Failed to create database {database}: {e}")
            cursor.close()
            return False

    def create_mysql_table(self, database, table, target_conn):
        """Create table in local MySQL using CTU schema."""
        source_cursor = self.mysql_conn.cursor(buffered=True)
        source_cursor.execute(f"USE `{database}`")
        source_cursor.execute(f"SHOW CREATE TABLE `{table}`")
        result = source_cursor.fetchone()
        source_cursor.close()

        if not result:
            print(f"    ✗ Could not fetch schema for {table}")
            return False

        create_sql = result[1]
        cursor = target_conn.cursor()
        try:
            cursor.execute(f"DROP TABLE IF EXISTS `{table}`")
            cursor.execute(create_sql)
            target_conn.commit()
            return True
        except Exception as e:
            print(f"    ✗ Failed to create table {table}: {e}")
            return False
        finally:
            cursor.close()

    def load_csv_into_mysql(self, table, columns, csv_path, target_conn):
        """Load CSV data into the local MySQL table."""
        cursor = target_conn.cursor()

        column_vars = [f"@col_{i}" for i in range(len(columns))]
        set_clauses = ',\n'.join(
            [f"`{col}` = NULLIF({var}, '')" for col, var in zip(columns, column_vars)]
        )

        infile = csv_path.replace('\\', '\\\\').replace("'", "\\'")
        load_sql = (
            f"LOAD DATA LOCAL INFILE '{infile}'\n"
            f"INTO TABLE `{table}`\n"
            "FIELDS TERMINATED BY ','\n"
            "OPTIONALLY ENCLOSED BY '\"'\n"
            "LINES TERMINATED BY '\\n'\n"
            "IGNORE 1 ROWS\n"
            f"({', '.join(column_vars)})\n"
            f"SET {set_clauses}"
        )

        try:
            cursor.execute(load_sql)
            target_conn.commit()
            print(f"    ✓ Loaded {table}")
            return True
        except Exception as e:
            print(f"    ✗ Failed to load data into {table}: {e}")
            return False
        finally:
            cursor.close()
    
    def run(self):
        """Run the import process"""
        print("🚀 Starting CTU Dataset Import to local MySQL")
        print("=" * 60)
        
        self.connect()
        
        # Process each database
        success = []
        failed = []
        
        for database in SELECTED_DATABASES:
            try:
                if self.import_database(database):
                    success.append(database)
                else:
                    failed.append(database)
            except Exception as e:
                print(f"  ✗ Error importing {database}: {e}")
                failed.append(database)
        
        # Print summary
        print("\n" + "=" * 60)
        print("📊 Import Summary")
        print(f"  Successfully imported: {', '.join(success) if success else 'None'}")
        if failed:
            print(f"  Failed: {', '.join(failed)}")
        print(f"  Total databases: {self.stats['databases_imported']}")
        print(f"  Total tables: {self.stats['tables_imported']}")
        print(f"  Total rows: {self.stats['total_rows']:,}")
        print(f"  Duration: {datetime.now() - self.stats['start_time']}")
        
        # Save metadata
        metadata_path = DATA_DIR / 'import_metadata.json'
        with open(metadata_path, 'w') as f:
            json.dump({
                'databases': success,
                'stats': {
                    'databases_imported': self.stats['databases_imported'],
                    'tables_imported': self.stats['tables_imported'],
                    'total_rows': self.stats['total_rows']
                },
                'timestamp': datetime.now().isoformat()
            }, f, indent=2)
        
        print(f"\n✅ Import complete! Metadata saved to {metadata_path}")
        
        # Close connections
        if self.mysql_conn:
            self.mysql_conn.close()
        if self.local_mysql_conn:
            self.local_mysql_conn.close()

if __name__ == "__main__":
    parser = argparse.ArgumentParser(
        description="Import CTU benchmark datasets into PostgreSQL with pg_duckdb"
    )
    parser.add_argument(
        '--force', 
        action='store_true',
        help='Force re-import: drop existing databases and re-download data'
    )
    
    args = parser.parse_args()
    
    # Dependencies are imported at the top of the file
    # No need to check again here
    
    importer = CTUDatasetImporter(force=args.force)
    importer.run()