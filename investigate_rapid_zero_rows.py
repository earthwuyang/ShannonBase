#!/usr/bin/env python3
"""
Investigate why Rapid shows 0 rows for some tables while InnoDB shows data.

This script:
1. Scans all databases and tables
2. Compares InnoDB vs Rapid row counts
3. Analyzes table schemas for incompatible features
4. Reports findings
"""

import mysql.connector
import sys
from collections import defaultdict

CONFIG = {
    'host': '127.0.0.1',
    'port': 3307,
    'user': 'root',
    'password': ''
}

DATABASES_TO_CHECK = [
    'Airline',
    'financial',
    'tpch_sf1',
    'tpcds_sf1',
    'Credit',
    'Carcinogenesis',
    'Hepatitis_std',
    'employee',
    'geneea'
]

def get_table_info(cursor, database, table):
    """Get detailed table information"""
    cursor.execute(f"SHOW CREATE TABLE `{database}`.`{table}`")
    create_table = cursor.fetchone()[1]

    # Parse features
    features = {
        'has_foreign_keys': 'FOREIGN KEY' in create_table,
        'has_secondary_engine': 'SECONDARY_ENGINE' in create_table,
        'engine': None,
        'row_format': None,
        'charset': None,
    }

    # Extract engine
    if 'ENGINE=' in create_table:
        parts = create_table.split('ENGINE=')[1].split()
        features['engine'] = parts[0]

    # Extract row format
    if 'ROW_FORMAT=' in create_table:
        parts = create_table.split('ROW_FORMAT=')[1].split()
        features['row_format'] = parts[0]

    # Extract charset
    if 'CHARSET=' in create_table:
        parts = create_table.split('CHARSET=')[1].split()
        features['charset'] = parts[0]

    return features, create_table

def check_table_counts(cursor, database, table):
    """Check row counts in InnoDB vs Rapid"""
    try:
        # InnoDB count
        cursor.execute("SET SESSION use_secondary_engine = OFF")
        cursor.execute(f"SELECT COUNT(*) FROM `{database}`.`{table}`")
        innodb_count = cursor.fetchone()[0]

        # Rapid count
        try:
            cursor.execute("SET SESSION use_secondary_engine = FORCED")
            cursor.execute(f"SELECT COUNT(*) FROM `{database}`.`{table}`")
            rapid_count = cursor.fetchone()[0]
        except Exception as e:
            rapid_count = None
            rapid_error = str(e)
            return innodb_count, rapid_count, rapid_error

        return innodb_count, rapid_count, None

    except Exception as e:
        return None, None, str(e)

def main():
    print("="*80)
    print("RAPID ENGINE ZERO ROWS INVESTIGATION")
    print("="*80)
    print()

    conn = mysql.connector.connect(**CONFIG)
    conn.autocommit = True
    cursor = conn.cursor()

    # Get all databases
    cursor.execute("SHOW DATABASES")
    all_dbs = [row[0] for row in cursor.fetchall()]
    databases = [db for db in DATABASES_TO_CHECK if db in all_dbs]

    print(f"Checking {len(databases)} databases...")
    print()

    mismatches = []
    errors = []
    ok_tables = []

    for database in databases:
        print(f"\nDatabase: {database}")
        print("-" * 60)

        # Get tables with SECONDARY_ENGINE
        cursor.execute(f"""
            SELECT table_name
            FROM information_schema.tables
            WHERE table_schema = '{database}'
              AND table_type = 'BASE TABLE'
              AND create_options LIKE '%SECONDARY_ENGINE%'
            ORDER BY table_name
        """)

        tables = [row[0] for row in cursor.fetchall()]

        if not tables:
            print(f"  No tables with SECONDARY_ENGINE configured")
            continue

        print(f"  Found {len(tables)} tables with SECONDARY_ENGINE")

        for table in tables:
            innodb_count, rapid_count, error = check_table_counts(cursor, database, table)

            if error:
                print(f"    ❌ {table}: Error - {error}")
                errors.append({
                    'database': database,
                    'table': table,
                    'error': error
                })
            elif rapid_count is None:
                print(f"    ⚠️  {table}: Rapid query failed")
                errors.append({
                    'database': database,
                    'table': table,
                    'error': 'Rapid query failed'
                })
            elif innodb_count == 0 and rapid_count == 0:
                print(f"    ✓  {table}: Both empty (InnoDB: {innodb_count}, Rapid: {rapid_count})")
                ok_tables.append({'database': database, 'table': table, 'innodb': innodb_count, 'rapid': rapid_count})
            elif innodb_count == rapid_count:
                print(f"    ✅ {table}: Counts match (InnoDB: {innodb_count}, Rapid: {rapid_count})")
                ok_tables.append({'database': database, 'table': table, 'innodb': innodb_count, 'rapid': rapid_count})
            else:
                print(f"    🔴 {table}: MISMATCH - InnoDB: {innodb_count}, Rapid: {rapid_count}")

                # Get detailed info for mismatched table
                features, create_table = get_table_info(cursor, database, table)

                mismatches.append({
                    'database': database,
                    'table': table,
                    'innodb_count': innodb_count,
                    'rapid_count': rapid_count,
                    'features': features,
                    'create_table': create_table
                })

    # Summary
    print("\n" + "="*80)
    print("SUMMARY")
    print("="*80)

    print(f"\n✅ Tables with matching counts: {len(ok_tables)}")
    print(f"🔴 Tables with mismatched counts: {len(mismatches)}")
    print(f"❌ Tables with errors: {len(errors)}")

    # Analyze mismatches
    if mismatches:
        print("\n" + "="*80)
        print("DETAILED ANALYSIS OF MISMATCHES")
        print("="*80)

        # Group by common features
        feature_analysis = defaultdict(list)

        for mismatch in mismatches:
            features = mismatch['features']

            if features['has_foreign_keys']:
                feature_analysis['has_foreign_keys'].append(mismatch)

            if features['row_format']:
                feature_analysis[f"row_format_{features['row_format']}"].append(mismatch)

            if features['charset']:
                feature_analysis[f"charset_{features['charset']}"].append(mismatch)

        print("\nPattern Analysis:")
        for feature, tables in feature_analysis.items():
            print(f"  {feature}: {len(tables)} tables")
            for t in tables[:3]:  # Show first 3
                print(f"    - {t['database']}.{t['table']}: InnoDB={t['innodb_count']}, Rapid={t['rapid_count']}")
            if len(tables) > 3:
                print(f"    ... and {len(tables)-3} more")

        # Detailed info for first few mismatches
        print("\n" + "="*80)
        print("SAMPLE MISMATCHED TABLES (First 3)")
        print("="*80)

        for i, mismatch in enumerate(mismatches[:3], 1):
            print(f"\n[{i}] {mismatch['database']}.{mismatch['table']}")
            print(f"    InnoDB count: {mismatch['innodb_count']}")
            print(f"    Rapid count: {mismatch['rapid_count']}")
            print(f"    Features:")
            for key, value in mismatch['features'].items():
                print(f"      - {key}: {value}")
            print(f"    Create statement:")
            for line in mismatch['create_table'].split('\n')[:10]:
                print(f"      {line}")
            if len(mismatch['create_table'].split('\n')) > 10:
                print(f"      ... (truncated)")

    # Error details
    if errors:
        print("\n" + "="*80)
        print("ERRORS")
        print("="*80)
        for error in errors[:5]:
            print(f"\n{error['database']}.{error['table']}")
            print(f"  Error: {error['error']}")

    cursor.close()
    conn.close()

    # Save detailed report
    with open('/home/wuy/ShannonBase/rapid_zero_rows_report.txt', 'w') as f:
        f.write("="*80 + "\n")
        f.write("RAPID ENGINE ZERO ROWS INVESTIGATION - DETAILED REPORT\n")
        f.write("="*80 + "\n\n")

        f.write(f"Total tables checked: {len(ok_tables) + len(mismatches) + len(errors)}\n")
        f.write(f"  ✅ OK: {len(ok_tables)}\n")
        f.write(f"  🔴 Mismatched: {len(mismatches)}\n")
        f.write(f"  ❌ Errors: {len(errors)}\n\n")

        f.write("="*80 + "\n")
        f.write("MISMATCHED TABLES\n")
        f.write("="*80 + "\n\n")

        for mismatch in mismatches:
            f.write(f"\n{mismatch['database']}.{mismatch['table']}\n")
            f.write(f"  InnoDB: {mismatch['innodb_count']}, Rapid: {mismatch['rapid_count']}\n")
            f.write(f"  Features: {mismatch['features']}\n")
            f.write(f"  Create statement:\n")
            f.write(mismatch['create_table'])
            f.write("\n\n" + "-"*80 + "\n")

    print(f"\nDetailed report saved to: /home/wuy/ShannonBase/rapid_zero_rows_report.txt")

    return 0 if not mismatches else 1

if __name__ == "__main__":
    sys.exit(main())
