#!/usr/bin/env python3
"""
Advanced Training Workload Generator
Combines approaches from generate_advanced_benchmark_queries.py and cross_db_benchmark
to create diverse, realistic query workloads for hybrid optimizer training

USAGE:
    # Generate 50/50 TP/AP balanced workload for all datasets (DEFAULT)
    python3 generate_training_workload_advanced.py

    # Generate for a single database
    python3 generate_training_workload_advanced.py --database tpch_sf1

    # Generate with custom TP/AP ratio (e.g., 80% TP, 20% AP)
    python3 generate_training_workload_advanced.py --all-datasets --tp-ratio 0.8

    # Generate more queries per dataset
    python3 generate_training_workload_advanced.py --all-datasets --num-queries 5000

FEATURES:
    - TP Queries (Transactional): Point lookups, simple filters, small range scans
    - AP Queries (Analytical): Complex joins (3-10 tables), aggregations, window functions
    - Default 50/50 balanced workload
    - Generates for all available datasets by default
    - Produces SQL, JSON, and statistics files
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

# Available datasets (use actual database names - case-sensitive on Linux)
AVAILABLE_DATASETS = ['tpcds_sf1', 'tpch_sf1', 'Airline', 'Credit', 'Carcinogenesis', 'Hepatitis_std', 'employee', 'financial', 'geneea']

class Operator(Enum):
    EQ = '='
    NEQ = '!='
    LT = '<'
    LE = '<='
    GT = '>'
    GE = '>='
    LIKE = 'LIKE'
    NOT_LIKE = 'NOT LIKE'
    IS_NULL = 'IS NULL'
    IS_NOT_NULL = 'IS NOT NULL'
    IN = 'IN'
    BETWEEN = 'BETWEEN'
    EXISTS = 'EXISTS'
    NOT_EXISTS = 'NOT EXISTS'

class AggregateFunction(Enum):
    COUNT = 'COUNT'
    SUM = 'SUM'
    AVG = 'AVG'
    MIN = 'MIN'
    MAX = 'MAX'
    STDDEV = 'STDDEV'
    VARIANCE = 'VARIANCE'

class JoinType(Enum):
    INNER = 'INNER JOIN'
    LEFT = 'LEFT JOIN'
    RIGHT = 'RIGHT JOIN'
    FULL = 'FULL OUTER JOIN'
    CROSS = 'CROSS JOIN'
    
class QueryType(Enum):
    # Transactional (TP) query types
    TP_POINT_LOOKUP = 'tp_point_lookup'      # Single row lookup by primary key
    TP_SIMPLE_FILTER = 'tp_simple_filter'    # Simple filter on indexed column
    TP_SIMPLE_UPDATE = 'tp_simple_update'    # Single row update pattern
    TP_SIMPLE_INSERT = 'tp_simple_insert'    # Single row insert pattern
    TP_RANGE_SCAN = 'tp_range_scan'          # Small range scan on index
    
    # Analytical (AP) query types  
    AP_COMPLEX_JOIN = 'ap_complex_join'      # 3-10 table joins with aggregation
    AP_AGGREGATION = 'ap_aggregation'        # Complex GROUP BY with HAVING
    AP_WINDOW = 'ap_window'                  # Window functions with partitioning
    AP_SUBQUERY = 'ap_subquery'              # Complex correlated subqueries
    AP_CTE_RECURSIVE = 'ap_cte_recursive'    # CTEs with multiple levels
    AP_UNION_COMPLEX = 'ap_union_complex'    # UNION with aggregations
    AP_FULL_SCAN = 'ap_full_scan'            # Full table scan with complex filters
    AP_OLAP_CUBE = 'ap_olap_cube'            # ROLLUP/CUBE operations
    
    # Aliases for backward compatibility with existing generator methods
    WINDOW = 'ap_window'                     # Alias for AP_WINDOW
    SUBQUERY = 'ap_subquery'                 # Alias for AP_SUBQUERY
    CTE = 'ap_cte_recursive'                 # Alias for AP_CTE_RECURSIVE
    UNION = 'ap_union_complex'               # Alias for AP_UNION_COMPLEX

class AdvancedWorkloadGenerator:
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
            # Prepare config without database key to avoid duplicate parameter
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
        
        # Load foreign key relationships
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
        
        self.relationships = cursor.fetchall()
        
        # Load advanced benchmark query stats if available
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
        
        # Also try loading cross_db_benchmark stats if available
        if CROSS_DB_AVAILABLE:
            cross_db_stats_dir = CROSS_DB_DIR / 'datasets' / self.database
            if cross_db_stats_dir.exists():
                try:
                    schema_json = load_schema_json(self.database, CROSS_DB_DIR / 'datasets')
                    col_stats = load_column_statistics(self.database, CROSS_DB_DIR / 'datasets')
                    str_stats = load_string_statistics(self.database, CROSS_DB_DIR / 'datasets')
                    
                    # Merge stats
                    if col_stats:
                        self.column_stats.update(col_stats)
                    if str_stats:
                        self.string_stats.update(str_stats)
                except:
                    pass  # Stats may not be available for all datasets
        
        cursor.close()
        
    def generate_predicate(self, table, column_info):
        """Generate a predicate for a column based on its statistics"""
        col_name = column_info['name']
        col_type = column_info['type']
        
        # Check if we have statistics for this column
        if table in self.column_stats and col_name in self.column_stats[table]:
            stats = self.column_stats[table][col_name]
            
            # Use statistics to generate realistic predicates
            if 'percentiles' in stats and stats['percentiles']:
                # Numeric column with percentiles
                percentiles = stats['percentiles']
                op = random.choice([Operator.EQ, Operator.LT, Operator.GT, Operator.LE, Operator.GE, Operator.BETWEEN])
                
                if op == Operator.BETWEEN:
                    p1, p2 = sorted(random.sample(percentiles, 2))
                    return f"{table}.{col_name} BETWEEN {p1} AND {p2}"
                elif op in [Operator.EQ]:
                    val = random.choice(percentiles)
                    return f"{table}.{col_name} {op.value} {val}"
                else:
                    val = random.choice(percentiles)
                    return f"{table}.{col_name} {op.value} {val}"
                    
            elif 'unique_vals' in stats and stats['unique_vals']:
                # Categorical column
                val = random.choice(stats['unique_vals'])
                if isinstance(val, str):
                    return f"{table}.{col_name} = '{val}'"
                else:
                    return f"{table}.{col_name} = {val}"
        
        # Fallback to type-based generation
        if 'int' in col_type.lower() or 'numeric' in col_type.lower():
            op = random.choice([Operator.EQ, Operator.LT, Operator.GT, Operator.BETWEEN])
            if op == Operator.BETWEEN:
                v1, v2 = sorted([random.randint(1, 1000), random.randint(1, 1000)])
                return f"{table}.{col_name} BETWEEN {v1} AND {v2}"
            else:
                val = random.randint(1, 1000)
                return f"{table}.{col_name} {op.value} {val}"
                
        elif 'char' in col_type.lower() or 'text' in col_type.lower():
            op = random.choice([Operator.EQ, Operator.LIKE])
            if op == Operator.LIKE:
                pattern = random.choice(['A%', '%B%', '%C'])
                return f"{table}.{col_name} LIKE '{pattern}'"
            else:
                val = ''.join(random.choices('ABCDEFGHIJKLMNOPQRSTUVWXYZ', k=5))
                return f"{table}.{col_name} = '{val}'"
                
        elif 'date' in col_type.lower():
            year = random.randint(1990, 2024)
            month = random.randint(1, 12)
            day = random.randint(1, 28)
            return f"{table}.{col_name} >= '{year:04d}-{month:02d}-{day:02d}'"
            
        return None
    
    def generate_complex_predicate(self, tables, num_predicates=3):
        """Generate complex predicates with AND/OR combinations"""
        predicates = []
        
        for _ in range(num_predicates):
            table = random.choice(tables)
            if table in self.schema_info:
                col = random.choice(self.schema_info[table]['columns'])
                pred = self.generate_predicate(table, col)
                if pred:
                    predicates.append(pred)
        
        if len(predicates) == 0:
            return None
        elif len(predicates) == 1:
            return predicates[0]
        else:
            # Mix AND and OR
            result = predicates[0]
            for pred in predicates[1:]:
                connector = random.choice(['AND', 'OR'])
                if connector == 'OR':
                    result = f"({result}) OR ({pred})"
                else:
                    result = f"{result} AND {pred}"
            return result
    
    def generate_join_clause(self, start_table, num_joins):
        """Generate JOIN clauses using relationships - only uses tables from current database"""
        if not self.relationships:
            return [], [start_table]
        
        # Filter relationships to only include tables in current schema
        valid_tables = set(self.schema_info.keys())
        valid_rels = [(t1, c1, t2, c2) for t1, c1, t2, c2 in self.relationships
                     if t1 in valid_tables and t2 in valid_tables]
        
        if not valid_rels:
            return [], [start_table]
            
        joins = []
        joined_tables = {start_table}
        available_rels = list(valid_rels)
        
        for _ in range(num_joins):
            # Find possible joins
            possible_joins = []
            for t1, c1, t2, c2 in available_rels:
                if t1 in joined_tables and t2 not in joined_tables and t2 in valid_tables:
                    possible_joins.append((t1, c1, t2, c2, t2))
                elif t2 in joined_tables and t1 not in joined_tables and t1 in valid_tables:
                    possible_joins.append((t2, c2, t1, c1, t1))
            
            if not possible_joins:
                break
                
            t1, c1, t2, c2, new_table = random.choice(possible_joins)
            join_type = random.choice([JoinType.INNER, JoinType.LEFT])
            joins.append(f"{join_type.value} {new_table} ON {t1}.{c1} = {new_table}.{c2}")
            joined_tables.add(new_table)
        
        return joins, list(joined_tables)
    
    # ========== TP Query Generators (Transactional/OLTP) ==========
    
    def generate_tp_point_lookup(self):
        """Generate single row point lookup query (typical TP pattern)"""
        table = random.choice(list(self.schema_info.keys()))
        columns = self.schema_info[table]['columns']
        
        # Try to find primary key or unique column
        key_column = None
        for col in columns:
            if 'id' in col['name'].lower() or 'key' in col['name'].lower():
                key_column = col
                break
        
        if not key_column:
            key_column = columns[0]  # Use first column as fallback
        
        # Generate point lookup value
        if 'int' in key_column['type'].lower():
            value = random.randint(1, 100000)
            predicate = f"{table}.{key_column['name']} = {value}"
        else:
            value = f"VAL_{random.randint(1, 10000)}"
            predicate = f"{table}.{key_column['name']} = '{value}'"
        
        # Select all columns for the matching row
        query = f"SELECT * FROM {table} WHERE {predicate} LIMIT 1"
        
        return query, QueryType.TP_POINT_LOOKUP
    
    def generate_tp_simple_filter(self):
        """Generate simple filter query (TP pattern with indexed column access)"""
        table = random.choice(list(self.schema_info.keys()))
        columns = self.schema_info[table]['columns']
        
        # Select 1-3 columns to return
        select_cols = random.sample(columns, min(3, len(columns)))
        col_list = ', '.join([f"{table}.{c['name']}" for c in select_cols])
        
        # Simple predicate on likely indexed column
        filter_col = random.choice(columns)
        if 'int' in filter_col['type'].lower():
            value = random.randint(1, 1000)
            predicate = f"{table}.{filter_col['name']} = {value}"
        elif 'date' in filter_col['type'].lower():
            predicate = f"{table}.{filter_col['name']} = '2023-01-01'"
        else:
            predicate = f"{table}.{filter_col['name']} = 'VALUE_1'"
        
        query = f"SELECT {col_list} FROM {table} WHERE {predicate} LIMIT 10"
        
        return query, QueryType.TP_SIMPLE_FILTER
    
    def generate_tp_range_scan(self):
        """Generate small range scan query (TP pattern)"""
        table = random.choice(list(self.schema_info.keys()))
        columns = self.schema_info[table]['columns']
        
        # Find numeric or date column for range
        range_cols = [c for c in columns if 'int' in c['type'].lower() or 
                     'date' in c['type'].lower() or 'numeric' in c['type'].lower()]
        
        if not range_cols:
            return self.generate_tp_simple_filter()  # Fallback
        
        range_col = random.choice(range_cols)
        
        if 'int' in range_col['type'].lower():
            start = random.randint(1, 10000)
            end = start + random.randint(10, 100)  # Small range
            predicate = f"{table}.{range_col['name']} BETWEEN {start} AND {end}"
        elif 'date' in range_col['type'].lower():
            predicate = f"{table}.{range_col['name']} BETWEEN '2023-01-01' AND '2023-01-07'"
        else:
            start = random.uniform(0, 1000)
            end = start + random.uniform(10, 100)
            predicate = f"{table}.{range_col['name']} BETWEEN {start:.2f} AND {end:.2f}"
        
        query = f"SELECT * FROM {table} WHERE {predicate} LIMIT 100"
        
        return query, QueryType.TP_RANGE_SCAN
    
    # ========== AP Query Generators (Analytical/OLAP) ==========
    
    def generate_ap_complex_join(self):
        """Generate complex multi-table join query with aggregations (AP pattern)"""
        start_table = random.choice(list(self.schema_info.keys()))
        
        # AP queries have many joins (3-10 tables)
        max_joins = min(10, len(self.schema_info) - 1)
        num_joins = random.randint(3, max_joins)
        
        joins, joined_tables = self.generate_join_clause(start_table, num_joins)
        
        # Complex SELECT with aggregations and regular columns
        select_list = []
        group_by_list = []
        
        # Add some regular columns for grouping
        for table in joined_tables[:3]:
            if table in self.schema_info:
                cols = random.sample(self.schema_info[table]['columns'], 
                                   min(2, len(self.schema_info[table]['columns'])))
                for col in cols[:1]:  # Add to GROUP BY
                    select_list.append(f"{table}.{col['name']}")
                    group_by_list.append(f"{table}.{col['name']}")
        
        # Add aggregations
        for table in joined_tables:
            if table in self.schema_info:
                numeric_cols = [c for c in self.schema_info[table]['columns']
                              if 'int' in c['type'].lower() or 'numeric' in c['type'].lower()]
                if numeric_cols:
                    for _ in range(random.randint(1, 3)):
                        col = random.choice(numeric_cols)
                        agg = random.choice(['SUM', 'AVG', 'COUNT', 'MAX', 'MIN'])
                        select_list.append(f"{agg}({table}.{col['name']}) AS {agg.lower()}_{col['name']}")
        
        query = f"SELECT {', '.join(select_list)} FROM {start_table}"
        for join in joins:
            query += f" {join}"
            
        # Complex WHERE clause
        predicates = []
        for _ in range(random.randint(2, 5)):
            table = random.choice(joined_tables)
            if table in self.schema_info:
                col = random.choice(self.schema_info[table]['columns'])
                pred = self.generate_predicate(table, col)
                if pred:
                    predicates.append(pred)
        
        if predicates:
            query += f" WHERE {' AND '.join(predicates)}"
        
        # GROUP BY
        if group_by_list:
            query += f" GROUP BY {', '.join(group_by_list)}"
            
            # HAVING clause
            if random.random() > 0.5:
                having_cond = f"COUNT(*) > {random.randint(10, 1000)}"
                query += f" HAVING {having_cond}"
        
        # ORDER BY
        if group_by_list and random.random() > 0.3:
            query += f" ORDER BY {group_by_list[0]}"
            
        return query, QueryType.AP_COMPLEX_JOIN
    
    def generate_ap_aggregation(self):
        """Generate complex aggregation query with multiple GROUP BY columns (AP pattern)"""
        start_table = random.choice(list(self.schema_info.keys()))
        
        # AP aggregations often have joins
        joins = []
        joined_tables = [start_table]
        num_joins = random.randint(1, min(4, len(self.schema_info) - 1))
        joins, joined_tables = self.generate_join_clause(start_table, num_joins)
        
        # Multiple aggregation columns
        agg_list = []
        group_by_list = []
        
        for table in joined_tables:
            if table not in self.schema_info:
                continue
                
            # Find numeric columns for aggregation
            numeric_cols = [c for c in self.schema_info[table]['columns'] 
                          if any(t in c['type'].lower() for t in ['int', 'numeric', 'decimal', 'float', 'double'])]
            
            if numeric_cols:
                # More aggregations for AP queries
                for _ in range(random.randint(2, 5)):
                    col = random.choice(numeric_cols)
                    agg_func = random.choice(['SUM', 'AVG', 'COUNT', 'MIN', 'MAX', 'STDDEV', 'VARIANCE'])
                    alias = f"{agg_func.lower()}_{table}_{col['name']}"
                    agg_list.append(f"{agg_func}({table}.{col['name']}) AS {alias}")
            
            # Multiple group by columns for AP
            categorical_cols = [c for c in self.schema_info[table]['columns']
                             if 'char' in c['type'].lower() or 'text' in c['type'].lower() or 
                             'date' in c['type'].lower()]
            if categorical_cols:
                for _ in range(random.randint(1, min(3, len(categorical_cols)))):
                    col = random.choice(categorical_cols)
                    col_expr = f"{table}.{col['name']}"
                    if col_expr not in group_by_list:
                        group_by_list.append(col_expr)
        
        # Build query
        if not agg_list:
            agg_list = ['COUNT(*)', 'COUNT(DISTINCT *)']
            
        select_list = group_by_list + agg_list
        query = f"SELECT {', '.join(select_list)} FROM {start_table}"
        
        for join in joins:
            query += f" {join}"
        
        # Complex WHERE clause
        predicates = []
        for _ in range(random.randint(1, 4)):
            table = random.choice(joined_tables)
            if table in self.schema_info:
                col = random.choice(self.schema_info[table]['columns'])
                pred = self.generate_predicate(table, col)
                if pred:
                    predicates.append(pred)
        
        if predicates:
            # Mix AND and OR for complexity
            combined = predicates[0]
            for pred in predicates[1:]:
                op = random.choice(['AND', 'OR'])
                if op == 'OR':
                    combined = f"({combined}) OR ({pred})"
                else:
                    combined = f"{combined} AND {pred}"
            query += f" WHERE {combined}"
        
        # Add GROUP BY
        if group_by_list:
            query += f" GROUP BY {', '.join(group_by_list)}"
            
            # HAVING clause with multiple conditions
            if random.random() > 0.6:
                having_conditions = []
                having_conditions.append(f"COUNT(*) > {random.randint(100, 10000)}")
                if agg_list:
                    agg_expr = random.choice(agg_list).split(' AS ')[0]
                    threshold = random.randint(100, 100000)
                    having_conditions.append(f"{agg_expr} > {threshold}")
                query += f" HAVING {' AND '.join(having_conditions)}"
                
            # ORDER BY with multiple columns
            order_cols = random.sample(group_by_list, min(2, len(group_by_list)))
            if order_cols:
                query += f" ORDER BY {', '.join(order_cols)}"
                
        return query, QueryType.AP_AGGREGATION
    
    def generate_window_query(self):
        """Generate query with window functions"""
        table = random.choice(list(self.schema_info.keys()))
        
        # Find numeric columns
        numeric_cols = [c for c in self.schema_info[table]['columns']
                       if any(t in c['type'].lower() for t in ['int', 'numeric', 'decimal', 'float'])]
        
        if not numeric_cols:
            return self.generate_ap_aggregation()  # Fallback
            
        # Select columns
        select_list = []
        
        # Regular columns
        for _ in range(2):
            col = random.choice(self.schema_info[table]['columns'])
            select_list.append(f"{table}.{col['name']}")
        
        # Window function
        win_col = random.choice(numeric_cols)
        win_func = random.choice(['ROW_NUMBER()', 'RANK()', 'DENSE_RANK()', 
                                 f"SUM({table}.{win_col['name']})", 
                                 f"AVG({table}.{win_col['name']})"])
        
        partition_col = random.choice(self.schema_info[table]['columns'])
        order_col = random.choice(self.schema_info[table]['columns'])
        
        window_expr = f"{win_func} OVER (PARTITION BY {table}.{partition_col['name']} ORDER BY {table}.{order_col['name']}) AS window_result"
        select_list.append(window_expr)
        
        query = f"SELECT {', '.join(select_list)} FROM {table}"
        
        # Add WHERE clause
        if random.random() > 0.3:
            predicate = self.generate_predicate(table, random.choice(self.schema_info[table]['columns']))
            if predicate:
                query += f" WHERE {predicate}"
                
        # Add LIMIT
        query += f" LIMIT {random.choice([100, 1000])}"
        
        return query, QueryType.WINDOW
    
    def generate_subquery(self):
        """Generate query with subquery - only uses tables from current database"""
        tables = list(self.schema_info.keys())
        if len(tables) < 2:
            # Need at least 2 tables for subquery, fallback to aggregation
            return self.generate_ap_aggregation()
        
        main_table = random.choice(tables)
        sub_table = random.choice(tables)
        
        # Find common column type for correlation
        main_cols = self.schema_info[main_table]['columns']
        sub_cols = self.schema_info[sub_table]['columns']
        
        # Generate based on pattern
        pattern = random.choice(['in', 'exists', 'scalar'])
        
        if pattern == 'in':
            main_col = random.choice(main_cols)
            sub_col = random.choice(sub_cols)
            
            subquery = f"SELECT {sub_table}.{sub_col['name']} FROM {sub_table}"
            if random.random() > 0.5:
                pred = self.generate_predicate(sub_table, random.choice(sub_cols))
                if pred:
                    subquery += f" WHERE {pred}"
                    
            query = f"SELECT * FROM {main_table} WHERE {main_table}.{main_col['name']} IN ({subquery})"
            
        elif pattern == 'exists':
            subquery = f"SELECT 1 FROM {sub_table}"
            
            # Try to correlate - only use relationships within current database
            if self.relationships:
                valid_tables = set(self.schema_info.keys())
                for t1, c1, t2, c2 in self.relationships:
                    if t1 not in valid_tables or t2 not in valid_tables:
                        continue
                    if t1 == main_table and t2 == sub_table:
                        subquery += f" WHERE {sub_table}.{c2} = {main_table}.{c1}"
                        break
                    elif t2 == main_table and t1 == sub_table:
                        subquery += f" WHERE {sub_table}.{c1} = {main_table}.{c2}"
                        break
                        
            query = f"SELECT * FROM {main_table} WHERE EXISTS ({subquery})"
            
        else:  # scalar
            numeric_sub_cols = [c for c in sub_cols if 'int' in c['type'].lower() or 'numeric' in c['type'].lower()]
            if numeric_sub_cols:
                agg_col = random.choice(numeric_sub_cols)
                subquery = f"SELECT AVG({sub_table}.{agg_col['name']}) FROM {sub_table}"
                numeric_main_cols = [c for c in main_cols if 'int' in c['type'].lower() or 'numeric' in c['type'].lower()]
                if numeric_main_cols:
                    main_col = random.choice(numeric_main_cols)
                    query = f"SELECT * FROM {main_table} WHERE {main_table}.{main_col['name']} > ({subquery})"
                else:
                    query = f"SELECT *, ({subquery}) as avg_val FROM {main_table}"
            else:
                return self.generate_ap_complex_join()  # Fallback
                
        return query + " LIMIT 100", QueryType.SUBQUERY
    
    def generate_cte_query(self):
        """Generate query with Common Table Expression - only uses tables from current database"""
        tables = list(self.schema_info.keys())
        if len(tables) < 1:
            return self.generate_ap_aggregation()
        
        cte_table = random.choice(tables)
        main_table = random.choice(tables)
        
        # Generate CTE
        cte_cols = random.sample(self.schema_info[cte_table]['columns'], 
                                min(3, len(self.schema_info[cte_table]['columns'])))
        cte_select = ', '.join([f"{cte_table}.{c['name']}" for c in cte_cols])
        
        cte_query = f"SELECT {cte_select} FROM {cte_table}"
        
        # Add aggregation to CTE
        if random.random() > 0.5:
            numeric_cols = [c for c in self.schema_info[cte_table]['columns']
                          if 'int' in c['type'].lower() or 'numeric' in c['type'].lower()]
            if numeric_cols:
                agg_col = random.choice(numeric_cols)
                cte_query = f"SELECT {cte_table}.{cte_cols[0]['name']}, SUM({cte_table}.{agg_col['name']}) as total FROM {cte_table} GROUP BY {cte_table}.{cte_cols[0]['name']}"
        
        # Main query
        query = f"WITH cte AS ({cte_query}) SELECT * FROM cte"
        
        # Maybe join with main table
        if random.random() > 0.5 and main_table != cte_table:
            query += f" CROSS JOIN {main_table} LIMIT 1000"
        else:
            query += " LIMIT 100"
            
        return query, QueryType.CTE
    
    def generate_union_query(self):
        """Generate UNION query - only uses tables from current database"""
        tables = list(self.schema_info.keys())
        if len(tables) < 2:
            # Need at least 2 tables for UNION, fallback to aggregation
            return self.generate_ap_aggregation()
        
        table1 = random.choice(tables)
        table2 = random.choice(tables)
        
        # Try to find compatible columns
        cols1 = self.schema_info[table1]['columns']
        cols2 = self.schema_info[table2]['columns']
        
        # Simplest approach: select same number of columns
        num_cols = min(3, len(cols1), len(cols2))
        
        select1_cols = random.sample(cols1, num_cols)
        select2_cols = random.sample(cols2, num_cols)
        
        select1 = ', '.join([f"{table1}.{c['name']}" for c in select1_cols])
        select2 = ', '.join([f"{table2}.{c['name']}" for c in select2_cols])
        
        query1 = f"SELECT {select1} FROM {table1}"
        query2 = f"SELECT {select2} FROM {table2}"
        
        # Add WHERE clauses
        if random.random() > 0.5:
            pred1 = self.generate_predicate(table1, random.choice(cols1))
            if pred1:
                query1 += f" WHERE {pred1}"
                
        if random.random() > 0.5:
            pred2 = self.generate_predicate(table2, random.choice(cols2))
            if pred2:
                query2 += f" WHERE {pred2}"
        
        union_type = random.choice(['UNION', 'UNION ALL'])
        query = f"{query1} {union_type} {query2} LIMIT 100"
        
        return query, QueryType.UNION
    
    def generate_workload(self, num_queries=1000, tp_ratio=0.4):
        """Generate diverse workload with TP and AP queries
        
        Args:
            num_queries: Total number of queries to generate
            tp_ratio: Ratio of TP queries (default 0.4 means 40% TP, 60% AP)
        """
        if not self.schema_info:
            self.load_schema_and_stats()
            
        # Separate distributions for TP and AP queries
        # NOTE: Subquery and UNION removed - not supported by Rapid secondary engine
        tp_distributions = [
            (QueryType.TP_POINT_LOOKUP, 0.40, self.generate_tp_point_lookup),
            (QueryType.TP_SIMPLE_FILTER, 0.30, self.generate_tp_simple_filter),
            (QueryType.TP_RANGE_SCAN, 0.30, self.generate_tp_range_scan)
        ]
        
        ap_distributions = [
            (QueryType.AP_COMPLEX_JOIN, 0.35, self.generate_ap_complex_join),     # Increased from 0.30
            (QueryType.AP_AGGREGATION, 0.35, self.generate_ap_aggregation),       # Increased from 0.25
            (QueryType.AP_WINDOW, 0.20, self.generate_window_query),             # Increased from 0.15
            (QueryType.AP_CTE_RECURSIVE, 0.10, self.generate_cte_query),         # Keep existing
            # Removed: AP_SUBQUERY (not supported by Rapid - error 1235)
            # Removed: AP_UNION_COMPLEX (not supported by Rapid - syntax error)
        ]
        
        workload = []
        
        # Calculate number of TP and AP queries
        num_tp = int(num_queries * tp_ratio)
        num_ap = num_queries - num_tp
        
        # Track actual counts for reporting
        tp_count = 0
        ap_count = 0
        
        for i in range(num_queries):
            # Decide if this should be TP or AP query
            if i < num_tp:
                # Generate TP query
                distributions = tp_distributions
                is_tp = True
            else:
                # Generate AP query
                distributions = ap_distributions
                is_tp = False
            
            # Choose specific query type based on distribution
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
                            'category': 'TP' if is_tp else 'AP'
                        })
                        
                        if is_tp:
                            tp_count += 1
                        else:
                            ap_count += 1
                            
                    except Exception as e:
                        self.logger.warning(f"Failed to generate {qtype.value}: {e}")
                    break
                    
            if i % 100 == 0:
                self.logger.info(f"Generated {i}/{num_queries} queries (TP: {tp_count}, AP: {ap_count})")
        
        # Shuffle workload to mix TP and AP queries
        random.shuffle(workload)
        
        # Re-number after shuffle
        for i, item in enumerate(workload):
            item['id'] = f'q_{i:04d}'
        
        self.queries = workload
        return workload
    
    def save_workload(self, output_dir, prefix='training_workload'):
        """Save workload to files"""
        output_path = Path(output_dir)
        output_path.mkdir(parents=True, exist_ok=True)
        
        # Save as SQL file
        sql_file = output_path / f'{prefix}_{self.database}.sql'
        with open(sql_file, 'w') as f:
            for item in self.queries:
                f.write(f"-- Query: {item['id']}, Type: {item['type']}\n")
                f.write(f"-- Database: {item['database']}\n")
                f.write(item['query'] + ';\n\n')
        
        # Save as JSON for metadata
        json_file = output_path / f'{prefix}_{self.database}.json'
        with open(json_file, 'w') as f:
            json.dump(self.queries, f, indent=2)
        
        # Save statistics
        stats = self._compute_workload_statistics()
        stats_file = output_path / f'{prefix}_{self.database}_stats.json'
        with open(stats_file, 'w') as f:
            json.dump(stats, f, indent=2)
        
        self.logger.info(f"Workload saved to {output_path}")
        self.logger.info(f"  SQL: {sql_file}")
        self.logger.info(f"  Metadata: {json_file}")
        self.logger.info(f"  Statistics: {stats_file}")
        
        return str(sql_file)
    
    def _compute_workload_statistics(self):
        """Compute workload statistics"""
        type_counts = defaultdict(int)
        category_counts = defaultdict(int)
        category_type_counts = defaultdict(lambda: defaultdict(int))
        
        for item in self.queries:
            type_counts[item['type']] += 1
            category = item.get('category', 'unknown')
            category_counts[category] += 1
            category_type_counts[category][item['type']] += 1
        
        stats = {
            'total_queries': len(self.queries),
            'database': self.database,
            'categories': dict(category_counts),
            'category_percentages': {
                cat: count / len(self.queries) * 100
                for cat, count in category_counts.items()
            },
            'query_types': dict(type_counts),
            'query_type_percentages': {
                qtype: count / len(self.queries) * 100
                for qtype, count in type_counts.items()
            },
            'category_breakdown': {
                cat: dict(types)
                for cat, types in category_type_counts.items()
            }
        }
        
        return stats


def main():
    parser = argparse.ArgumentParser(description='Generate advanced training workload with AP and TP queries')
    parser.add_argument('--database', type=str, default=None,
                       choices=AVAILABLE_DATASETS,
                       help='Database to use (default: generate for all datasets)')
    parser.add_argument('--all-datasets', action='store_true', default=True,
                       help='Generate workload for all available datasets')
    parser.add_argument('--num-queries', type=int, default=10000,
                       help='Number of queries to generate per dataset (default: 1000)')
    parser.add_argument('--output', type=str, default='../training_workloads',
                       help='Output directory')
    parser.add_argument('--seed', type=int, default=42,
                       help='Random seed')
    parser.add_argument('--config', type=str, choices=['mysql', 'shannonbase'],
                       default='shannonbase', help='Database configuration to use')
    parser.add_argument('--tp-ratio', type=float, default=0.5,
                       help='Ratio of TP queries (0.0-1.0, default 0.5 = 50%% TP, 50%% AP)')
    
    args = parser.parse_args()
    
    # Determine which datasets to process
    if args.all_datasets or args.database is None:
        databases = AVAILABLE_DATASETS
        print(f"\nGenerating workloads for all {len(databases)} datasets")
    else:
        databases = [args.database]
    
    random.seed(args.seed)
    np.random.seed(args.seed)
    
    # Select config
    config = MYSQL_CONFIG if args.config == 'mysql' else SHANNONBASE_CONFIG
    
    # Track overall statistics
    all_stats = []
    successful_datasets = []
    failed_datasets = []
    
    # Generate workload for each database
    for idx, database in enumerate(databases):
        print(f"\n{'='*60}")
        print(f"[{idx+1}/{len(databases)}] Processing database: {database}")
        print(f"{'='*60}")
        
        try:
            # Update database in config
            db_config = config.copy()
            db_config['database'] = database
            
            generator = AdvancedWorkloadGenerator(database=database, config=db_config)
            
            if not generator.connect():
                print(f"Failed to connect to database: {database}")
                failed_datasets.append(database)
                continue
            
            generator.load_schema_and_stats()
            
            # Check if database has tables
            if not generator.schema_info:
                print(f"Warning: No tables found in database {database}, skipping...")
                failed_datasets.append(database)
                continue
            
            workload = generator.generate_workload(args.num_queries, tp_ratio=args.tp_ratio)
            sql_file = generator.save_workload(args.output)
            
            # Print statistics
            stats = generator._compute_workload_statistics()
            stats['database'] = database
            stats['sql_file'] = sql_file
            all_stats.append(stats)
            successful_datasets.append(database)
            
            print(f"\nWorkload Statistics for {database}:")
            print(f"  Total queries: {stats['total_queries']}")
            
            print("\n  Category distribution:")
            for cat in ['TP', 'AP']:
                if cat in stats['categories']:
                    pct = stats['category_percentages'][cat]
                    count = stats['categories'][cat]
                    print(f"    {cat}: {pct:6.2f}% ({count} queries)")
            
            print("\n  Detailed query type distribution:")
            print("\n  TP Query Types:")
            if 'TP' in stats['category_breakdown']:
                for qtype, count in sorted(stats['category_breakdown']['TP'].items()):
                    pct = count / stats['total_queries'] * 100
                    print(f"    {qtype:25s}: {count:4d} ({pct:5.2f}%)")
            
            print("\n  AP Query Types:")
            if 'AP' in stats['category_breakdown']:
                for qtype, count in sorted(stats['category_breakdown']['AP'].items()):
                    pct = count / stats['total_queries'] * 100
                    print(f"    {qtype:25s}: {count:4d} ({pct:5.2f}%)")
            
            print(f"\nWorkload saved to: {sql_file}")
            
            # Close connection
            if generator.conn:
                generator.conn.close()
                
        except Exception as e:
            print(f"Error processing database {database}: {e}")
            failed_datasets.append(database)
            import traceback
            traceback.print_exc()
    
    # Print overall summary
    if len(databases) > 1:
        print(f"\n{'='*60}")
        print("OVERALL SUMMARY")
        print(f"{'='*60}")
        print(f"\nProcessed {len(databases)} databases:")
        print(f"  Successful: {len(successful_datasets)}")
        print(f"  Failed: {len(failed_datasets)}")
        
        # Initialize aggregate variables
        total_queries = 0
        total_tp = 0
        total_ap = 0
        
        if successful_datasets:
            print(f"\nSuccessful datasets:")
            for db in successful_datasets:
                print(f"  - {db}")
                
            # Aggregate statistics
            total_queries = sum(s['total_queries'] for s in all_stats)
            total_tp = sum(s['categories'].get('TP', 0) for s in all_stats)
            total_ap = sum(s['categories'].get('AP', 0) for s in all_stats)
            
            print(f"\nAggregate statistics:")
            print(f"  Total queries across all datasets: {total_queries}")
            print(f"  Total TP queries: {total_tp} ({total_tp/total_queries*100:.1f}%)")
            print(f"  Total AP queries: {total_ap} ({total_ap/total_queries*100:.1f}%)")
            
            # Per-dataset breakdown
            print(f"\nPer-dataset breakdown:")
            print(f"  {'Database':<20} {'Queries':>8} {'TP':>8} {'AP':>8}")
            print(f"  {'-'*20} {'-'*8} {'-'*8} {'-'*8}")
            for stat in all_stats:
                db = stat['database']
                total = stat['total_queries']
                tp = stat['categories'].get('TP', 0)
                ap = stat['categories'].get('AP', 0)
                print(f"  {db:<20} {total:>8} {tp:>8} {ap:>8}")
        
        if failed_datasets:
            print(f"\nFailed datasets:")
            for db in failed_datasets:
                print(f"  - {db}")
        
        # Save combined statistics
        output_path = Path(args.output)
        output_path.mkdir(parents=True, exist_ok=True)
        combined_stats_file = output_path / 'combined_workload_stats.json'
        with open(combined_stats_file, 'w') as f:
            json.dump({
                'successful_datasets': successful_datasets,
                'failed_datasets': failed_datasets,
                'per_database_stats': all_stats,
                'aggregate': {
                    'total_queries': total_queries,
                    'total_tp': total_tp,
                    'total_ap': total_ap,
                    'tp_percentage': total_tp/total_queries*100 if total_queries > 0 else 0,
                    'ap_percentage': total_ap/total_queries*100 if total_queries > 0 else 0
                }
            }, f, indent=2)
        
        print(f"\nCombined statistics saved to: {combined_stats_file}")
        print(f"\nAll workloads saved in: {args.output}")
    
    if failed_datasets:
        sys.exit(1)


if __name__ == "__main__":
    main()
