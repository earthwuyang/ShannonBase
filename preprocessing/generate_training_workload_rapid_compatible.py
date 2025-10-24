#!/usr/bin/env python3
"""
Rapid Engine Compatible Training Workload Generator

Generates ONLY queries that are compatible with the Rapid secondary engine.

RAPID ENGINE LIMITATIONS:
- ONLY supports hash joins (not nested loop or index-based joins)
- NO index scans (REF, EQ_REF, INDEX_RANGE_SCAN)
- NO nested loop joins
- Table scans and hash joins only

COMPATIBLE QUERY PATTERNS:
- Full table scans with aggregations
- Large multi-table hash joins (3+ tables)
- Window functions over full scans
- Complex aggregations without index usage

REMOVED QUERY PATTERNS (from original generator):
- TP queries (all use indexes/nested loops)
- Point lookups (use index scans)
- Simple filters on indexed columns
- Range scans on indexes
- Subqueries that trigger nested loops
- UNION queries (syntax issues with Rapid)
- CTEs (Common Table Expressions) - causes INDEX_RANGE_SCAN crashes

USAGE:
    # Generate for all datasets (default)
    python3 generate_training_workload_rapid_compatible.py

    # Generate for specific database
    python3 generate_training_workload_rapid_compatible.py --database tpch_sf1

    # Generate more queries
    python3 generate_training_workload_rapid_compatible.py --num-queries 5000
"""

import os
import sys
import json
import random
import argparse
import mysql.connector
import numpy as np
from pathlib import Path
from datetime import datetime
from enum import Enum
from collections import defaultdict
import logging

# Add cross_db_benchmark to path
sys.path.append(str(Path(__file__).parent))
try:
    from cross_db_benchmark.benchmark_tools.utils import load_schema_json, load_column_statistics, load_string_statistics
    from cross_db_benchmark.benchmark_tools.column_types import Datatype
    CROSS_DB_AVAILABLE = True
except ImportError:
    CROSS_DB_AVAILABLE = False

# Database configurations
MYSQL_CONFIG = {
    'host': '127.0.0.1',
    'port': 3306,
    'user': 'root',
    'password': ''
}

SHANNONBASE_CONFIG = {
    'host': '127.0.0.1',
    'port': 3307,
    'user': 'root',
    'password': ''
}

# Base paths
BASE_DIR = Path(__file__).resolve().parent
BENCHMARK_DIR = BASE_DIR / 'advanced_benchmark_queries'
CROSS_DB_DIR = BASE_DIR / 'cross_db_benchmark'

# Available datasets
AVAILABLE_DATASETS = ['tpcds_sf1', 'tpch_sf1', 'Airline', 'Credit', 'Carcinogenesis', 'Hepatitis_std', 'employee', 'financial', 'geneea']

class JoinType(Enum):
    INNER = 'INNER JOIN'
    LEFT = 'LEFT JOIN'
    CROSS = 'CROSS JOIN'  # Removed RIGHT and FULL as they may have compatibility issues
    
class QueryType(Enum):
    # ONLY Analytical (AP) query types compatible with Rapid
    AP_COMPLEX_JOIN = 'ap_complex_join'          # Multi-table hash joins
    AP_AGGREGATION = 'ap_aggregation'            # Full scan with aggregation
    AP_WINDOW = 'ap_window'                      # Window functions
    AP_CTE = 'ap_cte'                            # CTEs with full scans
    AP_FULL_SCAN_FILTER = 'ap_full_scan_filter'  # Full table scan with non-selective filters

class RapidCompatibleGenerator:
    """Generator that ONLY creates queries compatible with Rapid engine"""
    
    def __init__(self, database='tpch_sf1', config=None):
        self.database = database
        self.config = config or MYSQL_CONFIG
        self.logger = self._setup_logging()
        self.conn = None
        self.schema_info = {}
        self.column_stats = {}
        self.string_stats = {}
        self.relationships = []
        self.queries = []
        
    def _setup_logging(self):
        logging.basicConfig(
            level=logging.INFO,
            format='%(asctime)s - %(levelname)s - %(message)s'
        )
        return logging.getLogger(__name__)
    
    def connect(self):
        """Connect to database"""
        try:
            conn_config = {k: v for k, v in self.config.items() if k != 'database'}
            self.conn = mysql.connector.connect(
                **conn_config,
                database=self.database
            )
            self.logger.info(f"Connected to database: {self.database}")
            return True
        except Exception as e:
            self.logger.error(f"Failed to connect: {e}")
            return False
    
    def load_schema_and_stats(self):
        """Load schema information and statistics"""
        if not self.conn:
            self.connect()
            
        cursor = self.conn.cursor()
        
        # Load tables and columns
        cursor.execute("""
            SELECT table_name, column_name, data_type, is_nullable
            FROM information_schema.columns
            WHERE table_schema = %s
            ORDER BY table_name, ordinal_position
        """, (self.database,))
        
        for table, column, dtype, nullable in cursor.fetchall():
            if table not in self.schema_info:
                self.schema_info[table] = {'columns': [], 'stats': {}}
            self.schema_info[table]['columns'].append({
                'name': column,
                'type': dtype,
                'nullable': nullable == 'YES'
            })
        
        # Load table sizes to filter out small lookup tables (Rapid needs large table joins for hash joins)
        cursor.execute("""
            SELECT table_name, table_rows
            FROM information_schema.tables
            WHERE table_schema = %s AND table_type = 'BASE TABLE'
        """, (self.database,))
        
        table_sizes = {}
        for table, rows in cursor.fetchall():
            table_sizes[table] = rows
        
        # Filter out small tables (lookup tables cause nested loop joins which Rapid doesn't support)
        # Keep only tables with > 10,000 rows to ensure hash joins
        MIN_ROWS_FOR_HASH_JOIN = 10000
        large_tables = {t for t, size in table_sizes.items() if size and size > MIN_ROWS_FOR_HASH_JOIN}
        
        # Remove small tables from schema_info
        self.schema_info = {t: info for t, info in self.schema_info.items() if t in large_tables}
        
        if len(self.schema_info) < 2:
            self.logger.warning(f"Database {self.database} has only {len(self.schema_info)} tables with >{MIN_ROWS_FOR_HASH_JOIN} rows")
            self.logger.warning(f"  Large tables: {list(self.schema_info.keys())}")
            self.logger.warning(f"  This database may not be suitable for Rapid (needs multiple large tables for hash joins)")
        
        self.logger.info(f"Using {len(self.schema_info)} large tables (>{MIN_ROWS_FOR_HASH_JOIN} rows) for Rapid-compatible queries")
        
        # Load foreign key relationships (filtered to large tables only)
        cursor.execute("""
            SELECT 
                kcu1.table_name AS table1,
                kcu1.column_name AS column1,
                kcu2.table_name AS table2,
                kcu2.column_name AS column2
            FROM information_schema.key_column_usage kcu1
            JOIN information_schema.referential_constraints rc
                ON kcu1.constraint_name = rc.constraint_name
            JOIN information_schema.key_column_usage kcu2
                ON rc.unique_constraint_name = kcu2.constraint_name
            WHERE kcu1.table_schema = %s
        """, (self.database,))
        
        # Filter relationships to only include large tables
        all_relationships = cursor.fetchall()
        self.relationships = [(t1, c1, t2, c2) for t1, c1, t2, c2 in all_relationships
                             if t1 in large_tables and t2 in large_tables]
        
        self.logger.info(f"Found {len(self.relationships)} relationships between large tables")
        
        # Load statistics if available
        stats_dir = BENCHMARK_DIR / self.database
        if stats_dir.exists():
            stats_file = stats_dir / 'column_statistics.json'
            if stats_file.exists():
                with open(stats_file, 'r') as f:
                    self.column_stats = json.load(f)
                    
            string_stats_file = stats_dir / 'string_statistics.json'
            if string_stats_file.exists():
                with open(string_stats_file, 'r') as f:
                    self.string_stats = json.load(f)
        
        cursor.close()
    
    def generate_non_selective_predicate(self, table, column_info):
        """Generate NON-selective predicates that force full table scans (Rapid compatible)"""
        col_name = column_info['name']
        col_type = column_info['type']
        
        # Use predicates that are intentionally non-selective to avoid index usage
        
        if 'int' in col_type.lower() or 'numeric' in col_type.lower():
            # Use very broad ranges or OR conditions
            predicates = [
                f"{table}.{col_name} > 0",  # Very non-selective
                f"{table}.{col_name} IS NOT NULL",
                f"({table}.{col_name} < 10000000 OR {table}.{col_name} IS NULL)",  # Almost everything
                f"{table}.{col_name} != -999999"  # Excludes almost nothing
            ]
            return random.choice(predicates)
                
        elif 'char' in col_type.lower() or 'text' in col_type.lower():
            # Broad string patterns
            predicates = [
                f"{table}.{col_name} IS NOT NULL",
                f"{table}.{col_name} != ''",
                f"{table}.{col_name} LIKE '%'",  # Matches everything
                f"LENGTH({table}.{col_name}) > 0"
            ]
            return random.choice(predicates)
                
        elif 'date' in col_type.lower():
            # Very broad date ranges
            predicates = [
                f"{table}.{col_name} >= '1900-01-01'",  # Almost everything
                f"{table}.{col_name} IS NOT NULL",
                f"YEAR({table}.{col_name}) > 1900"
            ]
            return random.choice(predicates)
            
        return f"{table}.{col_name} IS NOT NULL"  # Safest fallback
    
    def generate_join_clause_rapid_compatible(self, start_table, min_joins=3, max_joins=8):
        """Generate JOIN clauses that will use HASH JOINS (3+ tables to avoid nested loops)"""
        if not self.relationships:
            return [], [start_table]

        valid_tables = set(self.schema_info.keys())
        valid_rels = [(t1, c1, t2, c2) for t1, c1, t2, c2 in self.relationships
                     if t1 in valid_tables and t2 in valid_tables]

        if not valid_rels:
            return [], [start_table]

        joins = []
        joined_tables = {start_table}
        available_rels = list(valid_rels)

        # Rapid needs 3+ tables to use hash joins
        # But we need to ensure we have enough tables available
        max_possible_joins = len(valid_tables) - 1
        if max_possible_joins < 1:
            # Not enough tables to create any joins
            return [], [start_table]

        # Adjust min_joins if we don't have enough tables
        actual_min_joins = min(min_joins, max_possible_joins)
        num_joins = random.randint(actual_min_joins, min(max_joins, max_possible_joins))
        
        for _ in range(num_joins):
            possible_joins = []
            for t1, c1, t2, c2 in available_rels:
                if t1 in joined_tables and t2 not in joined_tables and t2 in valid_tables:
                    possible_joins.append((t1, c1, t2, c2, t2))
                elif t2 in joined_tables and t1 not in joined_tables and t1 in valid_tables:
                    possible_joins.append((t2, c2, t1, c1, t1))
            
            if not possible_joins:
                break
                
            t1, c1, t2, c2, new_table = random.choice(possible_joins)
            # Prefer INNER JOIN for hash joins
            join_type = random.choice([JoinType.INNER, JoinType.INNER, JoinType.LEFT])  # 2:1 ratio
            joins.append(f"{join_type.value} {new_table} ON {t1}.{c1} = {new_table}.{c2}")
            joined_tables.add(new_table)
        
        return joins, list(joined_tables)
    
    def generate_ap_complex_join(self):
        """Generate complex multi-table join with HASH JOINS (Rapid compatible)"""
        start_table = random.choice(list(self.schema_info.keys()))
        
        # Force 3-8 table joins for hash joins
        joins, joined_tables = self.generate_join_clause_rapid_compatible(start_table, min_joins=3, max_joins=8)
        
        if len(joined_tables) < 3:
            # Not enough tables, try again with different start table
            start_table = random.choice(list(self.schema_info.keys()))
            joins, joined_tables = self.generate_join_clause_rapid_compatible(start_table, min_joins=2, max_joins=8)
        
        # Build SELECT with aggregations
        select_list = []
        group_by_list = []
        
        # Add grouping columns from first 2-3 tables
        for table in joined_tables[:min(3, len(joined_tables))]:
            if table in self.schema_info and self.schema_info[table]['columns']:
                num_cols_to_sample = min(2, len(self.schema_info[table]['columns']))
                if num_cols_to_sample > 0:
                    cols = random.sample(self.schema_info[table]['columns'], num_cols_to_sample)
                    for col in cols[:1]:
                        select_list.append(f"{table}.{col['name']}")
                        group_by_list.append(f"{table}.{col['name']}")
        
        # Add multiple aggregations
        for table in joined_tables:
            if table in self.schema_info:
                numeric_cols = [c for c in self.schema_info[table]['columns']
                              if any(t in c['type'].lower() for t in ['int', 'numeric', 'decimal', 'float', 'double'])]
                if numeric_cols:
                    for _ in range(random.randint(2, 4)):
                        col = random.choice(numeric_cols)
                        agg = random.choice(['SUM', 'AVG', 'COUNT', 'MAX', 'MIN'])
                        select_list.append(f"{agg}({table}.{col['name']}) AS {agg.lower()}_{table}_{col['name']}")

        # Ensure we have at least some columns in SELECT
        if not select_list:
            select_list.append('COUNT(*) AS total_count')

        query = f"SELECT {', '.join(select_list)} FROM {start_table}"
        for join in joins:
            query += f" {join}"
            
        # Add NON-selective WHERE clauses (to maintain full scan)
        predicates = []
        for _ in range(random.randint(1, 3)):
            table = random.choice(joined_tables)
            if table in self.schema_info:
                col = random.choice(self.schema_info[table]['columns'])
                pred = self.generate_non_selective_predicate(table, col)
                if pred:
                    predicates.append(pred)
        
        if predicates:
            query += f" WHERE {' AND '.join(predicates)}"
        
        # GROUP BY
        if group_by_list:
            query += f" GROUP BY {', '.join(group_by_list)}"
            
            # HAVING with count filter
            if random.random() > 0.5:
                query += f" HAVING COUNT(*) > {random.randint(1, 10)}"
        
        return query, QueryType.AP_COMPLEX_JOIN
    
    def generate_ap_aggregation(self):
        """Generate full table scan aggregation (Rapid compatible)"""
        start_table = random.choice(list(self.schema_info.keys()))
        
        # Maybe add 1-3 joins for variety
        joins = []
        joined_tables = [start_table]
        if random.random() > 0.3 and self.relationships:
            joins, joined_tables = self.generate_join_clause_rapid_compatible(start_table, min_joins=1, max_joins=4)
        
        agg_list = []
        group_by_list = []
        
        for table in joined_tables:
            if table not in self.schema_info:
                continue
                
            numeric_cols = [c for c in self.schema_info[table]['columns'] 
                          if any(t in c['type'].lower() for t in ['int', 'numeric', 'decimal', 'float', 'double'])]
            
            if numeric_cols:
                for _ in range(random.randint(3, 6)):
                    col = random.choice(numeric_cols)
                    agg_func = random.choice(['SUM', 'AVG', 'COUNT', 'MIN', 'MAX', 'STDDEV'])
                    alias = f"{agg_func.lower()}_{table}_{col['name']}"
                    agg_list.append(f"{agg_func}({table}.{col['name']}) AS {alias}")
            
            # Group by columns
            categorical_cols = [c for c in self.schema_info[table]['columns']
                             if 'char' in c['type'].lower() or 'text' in c['type'].lower() or 
                             'date' in c['type'].lower()]
            if categorical_cols:
                for _ in range(random.randint(1, 2)):
                    col = random.choice(categorical_cols)
                    col_expr = f"{table}.{col['name']}"
                    if col_expr not in group_by_list:
                        group_by_list.append(col_expr)
        
        if not agg_list:
            agg_list = ['COUNT(*) AS total_count']
            
        select_list = group_by_list + agg_list
        query = f"SELECT {', '.join(select_list)} FROM {start_table}"
        
        for join in joins:
            query += f" {join}"
        
        # Non-selective WHERE
        predicates = []
        for _ in range(random.randint(0, 2)):
            table = random.choice(joined_tables)
            if table in self.schema_info and self.schema_info[table]['columns']:
                col = random.choice(self.schema_info[table]['columns'])
                pred = self.generate_non_selective_predicate(table, col)
                if pred:
                    predicates.append(pred)
        
        if predicates:
            query += f" WHERE {' AND '.join(predicates)}"
        
        if group_by_list:
            query += f" GROUP BY {', '.join(group_by_list)}"
            
            if random.random() > 0.5:
                query += f" HAVING COUNT(*) > {random.randint(1, 100)}"
                
        return query, QueryType.AP_AGGREGATION
    
    def generate_ap_window(self):
        """Generate window function query (Rapid compatible)"""
        table = random.choice(list(self.schema_info.keys()))

        numeric_cols = [c for c in self.schema_info[table]['columns']
                       if any(t in c['type'].lower() for t in ['int', 'numeric', 'decimal', 'float'])]

        if not numeric_cols:
            return self.generate_ap_aggregation()

        select_list = []

        # Regular columns for partitioning
        num_cols_to_sample = min(2, len(self.schema_info[table]['columns']))
        if num_cols_to_sample == 0:
            return self.generate_ap_aggregation()
        regular_cols = random.sample(self.schema_info[table]['columns'], num_cols_to_sample)
        for col in regular_cols:
            select_list.append(f"{table}.{col['name']}")
        
        # Window functions
        for _ in range(random.randint(2, 4)):
            win_col = random.choice(numeric_cols)
            win_func = random.choice([
                'ROW_NUMBER()', 
                'RANK()', 
                'DENSE_RANK()', 
                f"SUM({table}.{win_col['name']})", 
                f"AVG({table}.{win_col['name']})"
            ])
            
            partition_col = random.choice(self.schema_info[table]['columns'])
            order_col = random.choice(self.schema_info[table]['columns'])
            
            window_expr = f"{win_func} OVER (PARTITION BY {table}.{partition_col['name']} ORDER BY {table}.{order_col['name']}) AS win_{len(select_list)}"
            select_list.append(window_expr)
        
        query = f"SELECT {', '.join(select_list)} FROM {table}"
        
        # Non-selective filter
        if random.random() > 0.3:
            col = random.choice(self.schema_info[table]['columns'])
            predicate = self.generate_non_selective_predicate(table, col)
            if predicate:
                query += f" WHERE {predicate}"
                
        return query, QueryType.AP_WINDOW
    
    def generate_ap_cte(self):
        """Generate CTE query with full scans (Rapid compatible)"""
        tables = list(self.schema_info.keys())
        if len(tables) < 1:
            return self.generate_ap_aggregation()

        cte_table = random.choice(tables)

        # CTE with aggregation
        num_cols_to_sample = min(3, len(self.schema_info[cte_table]['columns']))
        if num_cols_to_sample == 0:
            return self.generate_ap_aggregation()
        cte_cols = random.sample(self.schema_info[cte_table]['columns'], num_cols_to_sample)
        
        group_col = cte_cols[0]
        numeric_cols = [c for c in self.schema_info[cte_table]['columns']
                      if 'int' in c['type'].lower() or 'numeric' in c['type'].lower()]
        
        if numeric_cols:
            agg_col = random.choice(numeric_cols)
            cte_query = f"SELECT {cte_table}.{group_col['name']}, SUM({cte_table}.{agg_col['name']}) as total, AVG({cte_table}.{agg_col['name']}) as average FROM {cte_table} GROUP BY {cte_table}.{group_col['name']}"
        else:
            cte_select = ', '.join([f"{cte_table}.{c['name']}" for c in cte_cols])
            cte_query = f"SELECT {cte_select} FROM {cte_table}"
        
        # Main query uses CTE
        query = f"WITH cte AS ({cte_query}) SELECT * FROM cte"
        
        # Maybe join with another table
        if len(tables) > 1 and random.random() > 0.5:
            main_table = random.choice([t for t in tables if t != cte_table])
            # Use CROSS JOIN to avoid index usage
            query += f" CROSS JOIN {main_table}"
            # Add LIMIT to prevent huge results
            query += f" LIMIT {random.choice([100, 1000, 10000])}"
        
        return query, QueryType.AP_CTE
    
    def generate_ap_full_scan_filter(self):
        """Generate full table scan with non-selective filters (Rapid compatible)"""
        table = random.choice(list(self.schema_info.keys()))

        # Select multiple columns
        columns = self.schema_info[table]['columns']
        if not columns:
            return self.generate_ap_aggregation()

        num_cols_to_select = min(random.randint(3, 8), len(columns))
        select_cols = random.sample(columns, num_cols_to_select)
        col_list = ', '.join([f"{table}.{c['name']}" for c in select_cols])

        # Multiple non-selective predicates
        predicates = []
        for _ in range(random.randint(2, 5)):
            col = random.choice(columns)
            pred = self.generate_non_selective_predicate(table, col)
            if pred:
                predicates.append(pred)
        
        query = f"SELECT {col_list} FROM {table}"
        
        if predicates:
            # Mix with OR to make even less selective
            if len(predicates) > 2 and random.random() > 0.5:
                combined = f"({predicates[0]}) OR ({predicates[1]})"
                for pred in predicates[2:]:
                    combined = f"({combined}) AND ({pred})"
                query += f" WHERE {combined}"
            else:
                query += f" WHERE {' AND '.join(predicates)}"
        
        return query, QueryType.AP_FULL_SCAN_FILTER
    
    def generate_workload(self, num_queries=1000):
        """Generate Rapid-compatible workload (100% AP queries, no TP, no CTEs)"""
        if not self.schema_info:
            self.load_schema_and_stats()

        # ALL queries are AP, optimized for Rapid
        # Removed: subquery, union, CTE (CTE causes crashes with INDEX_RANGE_SCAN)
        distributions = [
            (QueryType.AP_COMPLEX_JOIN, 0.35, self.generate_ap_complex_join),
            (QueryType.AP_AGGREGATION, 0.35, self.generate_ap_aggregation),
            (QueryType.AP_WINDOW, 0.20, self.generate_ap_window),
            # (QueryType.AP_CTE, 0.10, self.generate_ap_cte),  # DISABLED: causes crashes
            (QueryType.AP_FULL_SCAN_FILTER, 0.10, self.generate_ap_full_scan_filter)
        ]
        
        workload = []
        type_counts = defaultdict(int)
        
        for i in range(num_queries):
            rand = random.random()
            cumulative = 0
            
            for qtype, prob, generator in distributions:
                cumulative += prob
                if rand <= cumulative:
                    try:
                        query, query_type = generator()
                        workload.append({
                            'id': f'q_{i:04d}',
                            'query': query,
                            'type': query_type.value,
                            'database': self.database,
                            'category': 'AP',  # All queries are AP
                            'rapid_compatible': True
                        })
                        type_counts[query_type.value] += 1
                    except Exception as e:
                        self.logger.warning(f"Failed to generate {qtype.value}: {e}")
                    break
                    
            if i % 100 == 0 and i > 0:
                self.logger.info(f"Generated {i}/{num_queries} Rapid-compatible queries")
        
        self.logger.info(f"\nQuery type distribution:")
        for qtype, count in sorted(type_counts.items()):
            pct = count / len(workload) * 100
            self.logger.info(f"  {qtype:30s}: {count:4d} ({pct:5.1f}%)")
        
        self.queries = workload
        return workload
    
    def save_workload(self, output_dir, prefix='training_workload_rapid'):
        """Save workload to files"""
        output_path = Path(output_dir)
        output_path.mkdir(parents=True, exist_ok=True)
        
        # Save as SQL file
        sql_file = output_path / f'{prefix}_{self.database}.sql'
        with open(sql_file, 'w') as f:
            f.write("-- RAPID ENGINE COMPATIBLE WORKLOAD\n")
            f.write("-- Generated for Rapid secondary engine (hash joins only)\n")
            f.write(f"-- Database: {self.database}\n")
            f.write(f"-- Total queries: {len(self.queries)}\n\n")
            
            for item in self.queries:
                f.write(f"-- Query: {item['id']}, Type: {item['type']}, Category: {item['category']}\n")
                f.write(f"-- Database: {item['database']}\n")
                f.write(item['query'] + ';\n\n')
        
        # Save as JSON
        json_file = output_path / f'{prefix}_{self.database}.json'
        with open(json_file, 'w') as f:
            json.dump(self.queries, f, indent=2)
        
        # Save statistics
        stats = self._compute_workload_statistics()
        stats_file = output_path / f'{prefix}_{self.database}_stats.json'
        with open(stats_file, 'w') as f:
            json.dump(stats, f, indent=2)
        
        self.logger.info(f"Rapid-compatible workload saved:")
        self.logger.info(f"  SQL: {sql_file}")
        self.logger.info(f"  JSON: {json_file}")
        self.logger.info(f"  Stats: {stats_file}")
        
        return str(sql_file)
    
    def _compute_workload_statistics(self):
        """Compute workload statistics"""
        type_counts = defaultdict(int)
        
        for item in self.queries:
            type_counts[item['type']] += 1
        
        stats = {
            'total_queries': len(self.queries),
            'database': self.database,
            'rapid_compatible': True,
            'category': 'AP',  # 100% AP
            'category_percentage': 100.0,
            'query_types': dict(type_counts),
            'query_type_percentages': {
                qtype: count / len(self.queries) * 100
                for qtype, count in type_counts.items()
            },
            'notes': [
                'All queries designed for Rapid secondary engine',
                'Uses hash joins only (3+ table joins)',
                'No index scans or nested loop joins',
                'Full table scans with non-selective predicates',
                'CTEs disabled due to INDEX_RANGE_SCAN crashes'
            ]
        }
        
        return stats


def main():
    parser = argparse.ArgumentParser(
        description='Generate Rapid-compatible training workload (AP queries only)',
        formatter_class=argparse.RawDescriptionHelpFormatter,
        epilog="""
Examples:
  # Generate for all datasets
  python3 generate_training_workload_rapid_compatible.py --all-datasets

  # Generate for specific database
  python3 generate_training_workload_rapid_compatible.py --database tpch_sf1

  # Generate more queries
  python3 generate_training_workload_rapid_compatible.py --num-queries 5000

Note: This generator only creates queries compatible with Rapid engine:
  - Hash joins only (no nested loop or index-based joins)
  - Full table scans (no index range scans)
  - All queries are analytical (AP) - no transactional (TP) queries
  - CTEs (Common Table Expressions) excluded - cause crashes
        """)
    parser.add_argument('--database', type=str, default=None,
                       choices=AVAILABLE_DATASETS,
                       help='Database to use (default: all datasets)')
    parser.add_argument('--all-datasets', action='store_true', default=True,
                       help='Generate for all available datasets')
    parser.add_argument('--num-queries', type=int, default=10000,
                       help='Number of queries per dataset (default: 10000)')
    parser.add_argument('--output', type=str, default='../training_workloads',
                       help='Output directory')
    parser.add_argument('--seed', type=int, default=42,
                       help='Random seed')
    parser.add_argument('--config', type=str, choices=['mysql', 'shannonbase'],
                       default='shannonbase', help='Database config')
    
    args = parser.parse_args()
    
    # Determine datasets
    if args.all_datasets or args.database is None:
        databases = AVAILABLE_DATASETS
        print(f"\nGenerating Rapid-compatible workloads for {len(databases)} datasets")
    else:
        databases = [args.database]
    
    random.seed(args.seed)
    np.random.seed(args.seed)
    
    config = MYSQL_CONFIG if args.config == 'mysql' else SHANNONBASE_CONFIG
    
    print("\n" + "="*60)
    print("RAPID ENGINE COMPATIBLE WORKLOAD GENERATOR")
    print("="*60)
    print("\nQuery characteristics:")
    print("  ✓ Hash joins only (3+ tables)")
    print("  ✓ Full table scans")
    print("  ✓ Non-selective predicates")
    print("  ✓ Aggregations and window functions")
    print("  ✗ NO index scans")
    print("  ✗ NO nested loop joins")
    print("  ✗ NO TP queries")
    print("  ✗ NO CTEs (causes crashes)")
    print("="*60 + "\n")
    
    successful = []
    failed = []
    all_stats = []
    
    for idx, database in enumerate(databases):
        print(f"\n[{idx+1}/{len(databases)}] Processing: {database}")
        print("-" * 60)
        
        try:
            db_config = config.copy()
            db_config['database'] = database
            
            generator = RapidCompatibleGenerator(database=database, config=db_config)
            
            if not generator.connect():
                print(f"❌ Failed to connect to: {database}")
                failed.append(database)
                continue
            
            generator.load_schema_and_stats()
            
            if not generator.schema_info:
                print(f"⚠️  No tables in: {database}")
                failed.append(database)
                continue
            
            workload = generator.generate_workload(args.num_queries)
            sql_file = generator.save_workload(args.output)
            
            stats = generator._compute_workload_statistics()
            stats['sql_file'] = sql_file
            all_stats.append(stats)
            successful.append(database)
            
            print(f"\n✓ Generated {len(workload)} Rapid-compatible queries")
            print(f"  Saved to: {sql_file}")
            
            if generator.conn:
                generator.conn.close()
                
        except Exception as e:
            print(f"❌ Error processing {database}: {e}")
            failed.append(database)
            import traceback
            traceback.print_exc()
    
    # Summary
    print(f"\n{'='*60}")
    print("GENERATION COMPLETE")
    print(f"{'='*60}")
    print(f"Successful: {len(successful)}/{len(databases)}")
    print(f"Failed: {len(failed)}/{len(databases)}")
    
    if successful:
        print(f"\n✓ Successful datasets:")
        for db in successful:
            print(f"  - {db}")
    
    if failed:
        print(f"\n✗ Failed datasets:")
        for db in failed:
            print(f"  - {db}")
    
    # Save combined stats
    if all_stats:
        output_path = Path(args.output)
        combined_file = output_path / 'rapid_compatible_workload_stats.json'
        with open(combined_file, 'w') as f:
            json.dump({
                'successful': successful,
                'failed': failed,
                'per_database': all_stats,
                'total_queries': sum(s['total_queries'] for s in all_stats),
                'rapid_compatible': True
            }, f, indent=2)
        print(f"\n📊 Combined stats: {combined_file}")
    
    print(f"\n📁 All files saved in: {args.output}")


if __name__ == "__main__":
    main()
