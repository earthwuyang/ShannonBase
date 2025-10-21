#!/usr/bin/env python3
"""
Parallel Import of CTU benchmark datasets into local MySQL server with duplicate handling.

Features:
- Parallel table processing using multiprocessing
- INSERT IGNORE for duplicate handling (skips on primary key constraint)
- Batch inserts for performance
- Progress tracking
- Resumable imports
"""

import argparse
import csv
import json
import os
import sys
from datetime import datetime
from pathlib import Path
from concurrent.futures import ProcessPoolExecutor, ThreadPoolExecutor, as_completed
from multiprocessing import cpu_count
import time

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

# Local MySQL Configuration
LOCAL_MYSQL_CONFIG = {
    'host': os.environ.get('LOCAL_MYSQL_HOST', '127.0.0.1'),
    'port': int(os.environ.get('LOCAL_MYSQL_PORT', '3307')),
    'user': os.environ.get('LOCAL_MYSQL_USER', 'root'),
    'password': os.environ.get('LOCAL_MYSQL_PASSWORD', 'shannonbase'),
    'allow_local_infile': True
}

# Datasets to import
SELECTED_DATABASES = [
    'Airline',
    'Credit',
    'Carcinogenesis',
    'employee',
    'financial',
    'geneea',
    'Hepatitis_std'
]

BASE_DIR = Path(__file__).resolve().parent
DATA_DIR = BASE_DIR / 'ctu_data'

# Performance tuning
BATCH_SIZE = 5000  # Rows per batch insert
MAX_WORKERS = min(cpu_count() * 2, 16)  # Max parallel workers
EXPORT_CHUNK_SIZE = 10000  # Rows to fetch at once during export

def connect_local_mysql(database=None):
    """Connect to local MySQL"""
    config = LOCAL_MYSQL_CONFIG.copy()
    if database:
        config['database'] = database
    # Add connection timeout to prevent hanging
    config['connection_timeout'] = 30
    return mysql.connector.connect(**config)

def connect_source_mysql(database=None):
    """Connect to CTU MySQL"""
    config = MYSQL_CONFIG.copy()
    if database:
        config['database'] = database
    return mysql.connector.connect(**config)

def get_table_schema(database, table):
    """Get table schema from source"""
    conn = connect_source_mysql(database)
    cursor = conn.cursor(buffered=True)
    cursor.execute(f"SHOW CREATE TABLE `{table}`")
    result = cursor.fetchone()
    create_sql = result[1] if result else None
    cursor.close()
    conn.close()
    return create_sql

def get_column_info(database, table):
    """Get column information"""
    conn = connect_source_mysql(database)
    cursor = conn.cursor(buffered=True)
    cursor.execute(f"""
        SELECT COLUMN_NAME, DATA_TYPE, COLUMN_TYPE, IS_NULLABLE, COLUMN_KEY
        FROM INFORMATION_SCHEMA.COLUMNS
        WHERE TABLE_SCHEMA = %s AND TABLE_NAME = %s
        ORDER BY ORDINAL_POSITION
    """, (database, table))
    
    columns = []
    for row in cursor.fetchall():
        columns.append({
            'name': row[0],
            'data_type': row[1],
            'full_type': row[2],
            'nullable': row[3] == 'YES',
            'is_primary': row[4] == 'PRI'
        })
    
    cursor.close()
    conn.close()
    return columns

def export_table_to_csv(args):
    """Export a table to CSV (worker function)"""
    database, table, output_path, force = args
    
    if not force and Path(output_path).exists():
        return {'table': table, 'status': 'cached', 'rows': None}
    
    try:
        conn = connect_source_mysql(database)
        cursor = conn.cursor(buffered=True)
        
        # Get row count
        cursor.execute(f"SELECT COUNT(*) FROM `{table}`")
        total_rows = cursor.fetchone()[0]
        
        if total_rows == 0:
            cursor.close()
            conn.close()
            return {'table': table, 'status': 'empty', 'rows': 0}
        
        # Get columns
        columns_info = get_column_info(database, table)
        columns = [c['name'] for c in columns_info]
        
        # Export data
        cursor.execute(f"SELECT * FROM `{table}`")
        
        os.makedirs(os.path.dirname(output_path), exist_ok=True)
        
        with open(output_path, 'w', newline='', encoding='utf-8') as csvfile:
            writer = csv.writer(csvfile, lineterminator='\n')
            writer.writerow(columns)  # Header
            
            row_count = 0
            while True:
                rows = cursor.fetchmany(EXPORT_CHUNK_SIZE)
                if not rows:
                    break
                
                for row in rows:
                    processed_row = []
                    for val in row:
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
        
        cursor.close()
        conn.close()
        
        return {'table': table, 'status': 'exported', 'rows': row_count}
    
    except Exception as e:
        return {'table': table, 'status': 'error', 'error': str(e)}

def create_table_if_not_exists(database, table, create_sql):
    """Create table in local database with SECONDARY_ENGINE=Rapid
    
    To avoid DDL errors, we:
    1. Create table WITHOUT SECONDARY_ENGINE (even if indexes are present)
    2. Add SECONDARY_ENGINE after table is created
    """
    try:
        # Add timeout to prevent hanging
        conn = connect_local_mysql(database)
        cursor = conn.cursor()
        
        # Disable foreign key checks to avoid constraint issues during creation
        cursor.execute("SET FOREIGN_KEY_CHECKS = 0")
        
        cursor.execute(f"DROP TABLE IF EXISTS `{table}`")
        
        # Remove SECONDARY_ENGINE from create_sql if present (to avoid DDL errors)
        # We'll add it separately after table creation
        create_sql_clean = create_sql.replace('SECONDARY_ENGINE=Rapid', '').replace('SECONDARY_ENGINE = Rapid', '')
        create_sql_clean = create_sql_clean.rstrip(';').rstrip() + ';'
        
        # Create table without SECONDARY_ENGINE
        cursor.execute(create_sql_clean)
        
        # Now add SECONDARY_ENGINE=Rapid separately (after all DDL in CREATE TABLE)
        cursor.execute(f"ALTER TABLE `{table}` SECONDARY_ENGINE=Rapid")
        
        # Re-enable foreign key checks
        cursor.execute("SET FOREIGN_KEY_CHECKS = 1")
        
        conn.commit()
        cursor.close()
        conn.close()
        return True
    except Exception as e:
        print(f"    ✗ Failed to create table {table}: {e}")
        return False

def import_table_batch(args):
    """Import table data using batch INSERT IGNORE (worker function)"""
    database, table, csv_path = args
    
    try:
        # Get column info
        columns_info = get_column_info(database, table)
        columns = [c['name'] for c in columns_info]
        
        # Open CSV
        if not Path(csv_path).exists():
            return {'table': table, 'status': 'no_csv', 'rows': 0}
        
        conn = connect_local_mysql(database)
        cursor = conn.cursor()
        
        # Disable keys for faster bulk insert
        cursor.execute(f"ALTER TABLE `{table}` DISABLE KEYS")
        
        total_rows = 0
        batch = []
        
        with open(csv_path, 'r', encoding='utf-8') as csvfile:
            reader = csv.reader(csvfile)
            next(reader)  # Skip header
            
            for row in reader:
                # Convert empty strings to NULL
                processed_row = []
                for i, val in enumerate(row):
                    if val == '' and columns_info[i]['nullable']:
                        processed_row.append(None)
                    else:
                        processed_row.append(val if val != '' else None)
                
                batch.append(tuple(processed_row))
                
                if len(batch) >= BATCH_SIZE:
                    # Batch INSERT IGNORE
                    placeholders = ', '.join(['%s'] * len(columns))
                    col_names = ', '.join([f"`{c}`" for c in columns])
                    insert_sql = f"INSERT IGNORE INTO `{table}` ({col_names}) VALUES ({placeholders})"
                    
                    cursor.executemany(insert_sql, batch)
                    conn.commit()
                    total_rows += len(batch)
                    batch = []
            
            # Insert remaining batch
            if batch:
                placeholders = ', '.join(['%s'] * len(columns))
                col_names = ', '.join([f"`{c}`" for c in columns])
                insert_sql = f"INSERT IGNORE INTO `{table}` ({col_names}) VALUES ({placeholders})"
                
                cursor.executemany(insert_sql, batch)
                conn.commit()
                total_rows += len(batch)
        
        # Re-enable keys
        cursor.execute(f"ALTER TABLE `{table}` ENABLE KEYS")
        conn.commit()
        
        cursor.close()
        conn.close()
        
        return {'table': table, 'status': 'success', 'rows': total_rows}
    
    except Exception as e:
        return {'table': table, 'status': 'error', 'error': str(e)}

def process_database(database, force=False, workers=MAX_WORKERS):
    """Process a single database with parallel table handling"""
    print(f"\n📦 Processing dataset: {database}")
    
    # Check if database exists on source
    try:
        conn = connect_source_mysql()
        cursor = conn.cursor(buffered=True)
        cursor.execute("SHOW DATABASES")
        databases = [db[0] for db in cursor.fetchall()]
        cursor.close()
        conn.close()
        
        if database not in databases:
            print(f"  ✗ Database '{database}' not found on CTU server")
            return False
    except Exception as e:
        print(f"  ✗ Failed to connect to CTU: {e}")
        return False
    
    # Get tables
    try:
        conn = connect_source_mysql(database)
        cursor = conn.cursor(buffered=True)
        cursor.execute("SHOW TABLES")
        tables = [t[0] for t in cursor.fetchall()]
        cursor.close()
        conn.close()
        
        if not tables:
            print(f"  ✗ No tables in database '{database}'")
            return False
        
        print(f"  Found {len(tables)} tables: {', '.join(tables)}")
    except Exception as e:
        print(f"  ✗ Failed to get tables: {e}")
        return False
    
    # Create database if not exists
    try:
        conn = connect_local_mysql()
        cursor = conn.cursor()
        
        cursor.execute("SHOW DATABASES LIKE %s", (database,))
        exists = cursor.fetchone() is not None
        
        if exists and force:
            print(f"    Dropping existing database '{database}'...")
            cursor.execute(f"DROP DATABASE `{database}`")
        
        if not exists or force:
            cursor.execute(
                f"CREATE DATABASE `{database}` CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci"
            )
            print(f"    ✓ Created database: {database}")
        else:
            print(f"    Database '{database}' already exists")
        
        # Enable local_infile
        cursor.execute("SET GLOBAL local_infile = 1")
        
        cursor.close()
        conn.close()
    except Exception as e:
        print(f"  ✗ Failed to setup database: {e}")
        return False
    
    data_dir = DATA_DIR / database
    data_dir.mkdir(parents=True, exist_ok=True)
    
    # Phase 1: Parallel export
    print(f"\n  📤 Phase 1: Exporting tables (parallel)...")
    export_tasks = []
    for table in tables:
        csv_path = data_dir / f"{table}.csv"
        export_tasks.append((database, table, str(csv_path), force))
    
    export_results = {}
    with ProcessPoolExecutor(max_workers=workers) as executor:
        futures = {executor.submit(export_table_to_csv, task): task[1] for task in export_tasks}
        
        with tqdm(total=len(tables), desc="    Exporting", unit="table") as pbar:
            for future in as_completed(futures):
                table = futures[future]
                try:
                    result = future.result()
                    export_results[table] = result
                    
                    if result['status'] == 'exported':
                        pbar.write(f"      ✓ {table}: {result['rows']:,} rows")
                    elif result['status'] == 'cached':
                        pbar.write(f"      ⚡ {table}: cached")
                    elif result['status'] == 'error':
                        pbar.write(f"      ✗ {table}: {result['error']}")
                    
                    pbar.update(1)
                except Exception as e:
                    pbar.write(f"      ✗ {table}: {e}")
                    pbar.update(1)
    
    # Phase 2: Create tables
    print(f"\n  📋 Phase 2: Creating tables...")
    for i, table in enumerate(tables, 1):
        print(f"    [{i}/{len(tables)}] Creating {table}...", end='', flush=True)
        create_sql = get_table_schema(database, table)
        if create_sql:
            if create_table_if_not_exists(database, table, create_sql):
                print(f" ✓")
            else:
                print(f" ✗ Failed")
        else:
            print(f" ✗ Could not get schema")
    
    # Phase 3: Parallel import
    print(f"\n  📥 Phase 3: Importing data (parallel with INSERT IGNORE)...")
    import_tasks = []
    for table in tables:
        csv_path = data_dir / f"{table}.csv"
        if csv_path.exists():
            import_tasks.append((database, table, str(csv_path)))
    
    total_rows = 0
    with ProcessPoolExecutor(max_workers=workers) as executor:
        futures = {executor.submit(import_table_batch, task): task[1] for task in import_tasks}
        
        with tqdm(total=len(import_tasks), desc="    Importing", unit="table") as pbar:
            for future in as_completed(futures):
                table = futures[future]
                try:
                    result = future.result()
                    
                    if result['status'] == 'success':
                        pbar.write(f"      ✓ {table}: {result['rows']:,} rows")
                        total_rows += result['rows']
                    elif result['status'] == 'error':
                        pbar.write(f"      ✗ {table}: {result['error']}")
                    
                    pbar.update(1)
                except Exception as e:
                    pbar.write(f"      ✗ {table}: {e}")
                    pbar.update(1)
    
    print(f"\n  ✅ Successfully imported {database}: {total_rows:,} total rows")
    
    # Phase 4: Load data into Rapid engine
    print(f"\n  🚀 Phase 4: Loading tables into Rapid engine...")
    conn = connect_local_mysql(database)
    cursor = conn.cursor()
    
    for i, table in enumerate(tables, 1):
        print(f"    [{i}/{len(tables)}] Loading {table} into Rapid...", end='', flush=True)
        try:
            cursor.execute(f"ALTER TABLE `{table}` SECONDARY_LOAD")
            print(" ✓")
        except Exception as e:
            print(f" ⚠ Warning: {e}")
    
    cursor.close()
    conn.close()
    
    print(f"\n  ✅ All tables loaded into Rapid engine!")
    return True

def main():
    parser = argparse.ArgumentParser(
        description="Parallel import of CTU benchmark datasets with duplicate handling"
    )
    parser.add_argument(
        '--force', 
        action='store_true',
        help='Force re-import: drop existing databases and re-download data'
    )
    parser.add_argument(
        '--workers',
        type=int,
        default=MAX_WORKERS,
        help=f'Number of parallel workers (default: {MAX_WORKERS})'
    )
    parser.add_argument(
        '--databases',
        nargs='+',
        choices=SELECTED_DATABASES,
        help='Specific databases to import (default: all)'
    )
    
    args = parser.parse_args()
    
    databases = args.databases if args.databases else SELECTED_DATABASES
    
    print("🚀 Starting Parallel CTU Dataset Import")
    print(f"   Workers: {args.workers}")
    print(f"   Batch size: {BATCH_SIZE}")
    print(f"   Databases: {', '.join(databases)}")
    print("=" * 60)
    
    start_time = time.time()
    success = []
    failed = []
    
    for database in databases:
        try:
            if process_database(database, args.force, args.workers):
                success.append(database)
            else:
                failed.append(database)
        except Exception as e:
            print(f"  ✗ Error importing {database}: {e}")
            failed.append(database)
    
    duration = time.time() - start_time
    
    # Print summary
    print("\n" + "=" * 60)
    print("📊 Import Summary")
    print(f"  Successfully imported: {', '.join(success) if success else 'None'}")
    if failed:
        print(f"  Failed: {', '.join(failed)}")
    print(f"  Duration: {duration:.1f} seconds")
    print(f"  Speedup: Using {args.workers} parallel workers")
    
    # Save metadata
    metadata_path = DATA_DIR / 'import_metadata_parallel.json'
    with open(metadata_path, 'w') as f:
        json.dump({
            'databases': success,
            'failed': failed,
            'workers': args.workers,
            'batch_size': BATCH_SIZE,
            'duration_seconds': duration,
            'timestamp': datetime.now().isoformat()
        }, f, indent=2)
    
    print(f"\n✅ Import complete! Metadata saved to {metadata_path}")

if __name__ == "__main__":
    main()
