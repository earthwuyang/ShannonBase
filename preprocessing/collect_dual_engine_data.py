#!/usr/bin/env python3
"""
Dual Engine Data Collection for Hybrid Optimizer

Collects query execution data from both engines:
1. Primary Engine (InnoDB) - Row-based storage, optimized for OLTP
2. Secondary Engine (Rapid) - Column-based storage, optimized for OLAP

Engine selection is controlled by use_secondary_engine variable:
  - OFF (0): Use primary engine only (InnoDB)
  - ON (1): Optimizer chooses based on cost
  - FORCED (2): Force use of secondary engine (Rapid) when eligible

This script forces each engine to collect accurate comparative data.
"""

import os
import sys
import time
import json
import csv
import mysql.connector
import numpy as np
import argparse
import logging
from datetime import datetime
from pathlib import Path
import concurrent.futures
import hashlib

# Configuration
# Note: Both connections use ShannonBase (port 3307) with different engine settings
# - MYSQL_CONFIG: ShannonBase with primary engine (InnoDB) forced
# - SHANNONBASE_CONFIG: ShannonBase with secondary engine (Rapid) forced
MYSQL_CONFIG = {
    'host': '127.0.0.1',
    'port': 3307,  # Changed to 3307 - use ShannonBase for both
    'user': 'root',
    'password': 'shannonbase',
    'database': 'tpch_sf1'
}

SHANNONBASE_CONFIG = {
    'host': '127.0.0.1', 
    'port': 3307,
    'user': 'root',
    'password': 'shannonbase',
    'database': 'tpch_sf1'
}

# Feature collection settings
OPTIMIZER_TRACE_SETTINGS = {
    'optimizer_trace': 'enabled=on,one_line=off',
    'optimizer_trace_features': 'greedy_search=on,range_optimizer=on,dynamic_range=on,repeated_subselect=on',
    'optimizer_trace_limit': 5,
    'optimizer_trace_offset': -5,
    'optimizer_trace_max_mem_size': 1048576
}

class DualEngineCollector:
    def __init__(self, output_dir='./training_data'):
        self.output_dir = Path(output_dir)
        self.output_dir.mkdir(parents=True, exist_ok=True)
        
        # Create subdirectories
        self.features_dir = self.output_dir / 'features'
        self.latency_dir = self.output_dir / 'latencies'
        self.queries_dir = self.output_dir / 'queries'
        
        for dir in [self.features_dir, self.latency_dir, self.queries_dir]:
            dir.mkdir(parents=True, exist_ok=True)
            
        self.logger = self._setup_logging()
        
    def _setup_logging(self):
        logging.basicConfig(
            level=logging.INFO,
            format='%(asctime)s - %(levelname)s - %(message)s'
        )
        return logging.getLogger(__name__)
    
    def connect_mysql(self, database=None):
        """Connect to MySQL row store (primary engine - InnoDB)"""
        try:
            config = MYSQL_CONFIG.copy()
            if database:
                config['database'] = database
            conn = mysql.connector.connect(**config)
            cursor = conn.cursor()
            # Enable optimizer trace
            for setting, value in OPTIMIZER_TRACE_SETTINGS.items():
                # Use quotes only for string values, not for integers
                if isinstance(value, str):
                    cursor.execute(f"SET {setting} = '{value}'")
                else:
                    cursor.execute(f"SET {setting} = {value}")
                # Consume any result to avoid "Unread result found" error
                try:
                    cursor.fetchall()
                except:
                    pass
            # Force use of primary engine (InnoDB) - disable secondary engine
            cursor.execute("SET SESSION use_secondary_engine = OFF")
            cursor.fetchall()  # Consume result
            return conn, cursor
        except Exception as e:
            self.logger.error(f"Failed to connect to MySQL/InnoDB: {e}")
            raise
    
    def connect_shannonbase(self, database=None):
        """Connect to ShannonBase rapid/column engine (secondary engine)"""
        try:
            config = SHANNONBASE_CONFIG.copy()
            if database:
                config['database'] = database
            conn = mysql.connector.connect(**config)
            cursor = conn.cursor()
            # Enable optimizer trace
            for setting, value in OPTIMIZER_TRACE_SETTINGS.items():
                # Use quotes only for string values, not for integers
                if isinstance(value, str):
                    cursor.execute(f"SET {setting} = '{value}'")
                else:
                    cursor.execute(f"SET {setting} = {value}")
                # Consume any result to avoid "Unread result found" error
                try:
                    cursor.fetchall()
                except:
                    pass
            # Force use of secondary engine (Rapid/Column Store)
            # FORCED means queries will always use secondary engine if eligible
            cursor.execute("SET SESSION use_secondary_engine = FORCED")
            cursor.fetchall()  # Consume result
            return conn, cursor
        except Exception as e:
            self.logger.error(f"Failed to connect to ShannonBase Rapid Engine: {e}")
            raise
    
    def execute_with_timing(self, cursor, query, warmup=3, runs=5):
        """Execute query and measure latency"""
        latencies = []
        
        # Warmup runs
        for _ in range(warmup):
            cursor.execute(query)
            cursor.fetchall()
        
        # Measured runs
        for _ in range(runs):
            start = time.perf_counter()
            cursor.execute(query)
            cursor.fetchall()
            end = time.perf_counter()
            latencies.append((end - start) * 1000)  # Convert to ms
        
        return {
            'mean_ms': np.mean(latencies),
            'median_ms': np.median(latencies),
            'std_ms': np.std(latencies),
            'p95_ms': np.percentile(latencies, 95),
            'p99_ms': np.percentile(latencies, 99),
            'all_runs': latencies
        }
    
    def verify_engine_used(self, cursor):
        """Verify which engine is actually being used"""
        try:
            cursor.execute("SHOW SESSION VARIABLES LIKE 'use_secondary_engine'")
            result = cursor.fetchone()
            if result:
                return result[1]  # Returns 'OFF', 'ON', or 'FORCED'
        except Exception as e:
            self.logger.warning(f"Failed to verify engine: {e}")
        return None
    
    def extract_features_from_trace(self, cursor):
        """Extract optimizer features from trace"""
        cursor.execute("SELECT TRACE FROM information_schema.OPTIMIZER_TRACE")
        trace = cursor.fetchone()
        
        if not trace:
            return None
            
        try:
            trace_json = json.loads(trace[0])
            # Look for hybrid_optimizer_features in trace
            for step in trace_json.get('steps', []):
                if 'hybrid_optimizer_features' in step:
                    return step['hybrid_optimizer_features']['features']
                # Also check in join_optimization
                if 'join_optimization' in step:
                    join_opt = step['join_optimization']
                    if 'steps' in join_opt:
                        for substep in join_opt['steps']:
                            if 'hybrid_optimizer_features' in substep:
                                return substep['hybrid_optimizer_features']['features']
        except Exception as e:
            self.logger.warning(f"Failed to parse trace: {e}")
            
        return None
    
    def collect_query_data(self, query, query_id, database=None):
        """Collect features and latencies for a single query"""
        results = {
            'query_id': query_id,
            'query_hash': hashlib.md5(query.encode()).hexdigest(),
            'timestamp': datetime.now().isoformat(),
            'database': database
        }
        
        # Collect from MySQL (row store - primary engine)
        try:
            mysql_conn, mysql_cursor = self.connect_mysql(database)
            
            # Verify engine setting
            engine_mode = self.verify_engine_used(mysql_cursor)
            self.logger.debug(f"MySQL engine mode: {engine_mode} (expected: OFF)")
            
            # Get features
            mysql_cursor.execute(query)
            mysql_cursor.fetchall()
            features = self.extract_features_from_trace(mysql_cursor)
            
            # Get latency
            mysql_latency = self.execute_with_timing(mysql_cursor, query)
            
            results['mysql'] = {
                'features': features,
                'latency': mysql_latency,
                'engine_mode': engine_mode,
                'engine_type': 'InnoDB (Primary/Row Store)'
            }
            
            mysql_conn.close()
            
        except Exception as e:
            self.logger.error(f"MySQL/InnoDB execution failed for query {query_id}: {e}")
            results['mysql'] = {'error': str(e)}
        
        # Collect from ShannonBase (column store - secondary engine)
        try:
            shannon_conn, shannon_cursor = self.connect_shannonbase(database)
            
            # Verify engine setting
            engine_mode = self.verify_engine_used(shannon_cursor)
            self.logger.debug(f"ShannonBase engine mode: {engine_mode} (expected: FORCED)")
            
            # Get features (should be same as MySQL)
            shannon_cursor.execute(query)
            shannon_cursor.fetchall()
            shannon_features = self.extract_features_from_trace(shannon_cursor)
            
            # Get latency
            shannon_latency = self.execute_with_timing(shannon_cursor, query)
            
            results['shannonbase'] = {
                'features': shannon_features,
                'latency': shannon_latency,
                'engine_mode': engine_mode,
                'engine_type': 'Rapid (Secondary/Column Store)'
            }
            
            shannon_conn.close()
            
        except Exception as e:
            self.logger.error(f"ShannonBase Rapid execution failed for query {query_id}: {e}")
            results['shannonbase'] = {'error': str(e)}
        
        # Save results
        self._save_results(results, query, query_id)
        
        return results
    
    def _save_results(self, results, query, query_id):
        """Save collected data to files"""
        # Save query
        query_file = self.queries_dir / f"{query_id}.sql"
        with open(query_file, 'w') as f:
            f.write(query)
        
        # Save raw results JSON
        results_file = self.output_dir / f"{query_id}_results.json"
        with open(results_file, 'w') as f:
            json.dump(results, f, indent=2)
        
        # Save features if available
        if 'mysql' in results and 'features' in results['mysql']:
            features = results['mysql']['features']
            if features:
                features_file = self.features_dir / f"{query_id}_features.csv"
                with open(features_file, 'w', newline='') as f:
                    writer = csv.writer(f)
                    writer.writerow(['feature_idx', 'value'])
                    for idx, val in enumerate(features):
                        writer.writerow([idx, val])
        
        # Save latencies
        latency_data = []
        if 'mysql' in results and 'latency' in results['mysql']:
            mysql_lat = results['mysql']['latency']
            latency_data.append(['mysql', mysql_lat['mean_ms'], mysql_lat['median_ms'], 
                               mysql_lat['p95_ms'], mysql_lat['p99_ms']])
        
        if 'shannonbase' in results and 'latency' in results['shannonbase']:
            shannon_lat = results['shannonbase']['latency']
            latency_data.append(['shannonbase', shannon_lat['mean_ms'], shannon_lat['median_ms'],
                               shannon_lat['p95_ms'], shannon_lat['p99_ms']])
        
        if latency_data:
            latency_file = self.latency_dir / f"{query_id}_latency.csv"
            with open(latency_file, 'w', newline='') as f:
                writer = csv.writer(f)
                writer.writerow(['engine', 'mean_ms', 'median_ms', 'p95_ms', 'p99_ms'])
                writer.writerows(latency_data)
    
    def collect_from_workload(self, workload_file):
        """Collect data from a workload file (SQL or JSON format)"""
        workload_path = Path(workload_file)
        queries = []
        
        # Extract database name from filename (e.g., training_workload_tpch_sf1.sql -> tpch_sf1)
        database_name = None
        if 'training_workload_' in workload_path.name:
            parts = workload_path.stem.replace('training_workload_', '')
            database_name = parts
            self.logger.info(f"Detected database: {database_name}")
        
        # Load queries based on file format
        if workload_path.suffix == '.json':
            # Load from JSON format (includes metadata)
            with open(workload_path, 'r') as f:
                workload = json.load(f)
                for item in workload:
                    queries.append({
                        'id': item.get('id', f'q_{len(queries)}'),
                        'query': item['query'],
                        'type': item.get('type', 'unknown'),
                        'category': item.get('category', 'unknown')
                    })
                    
        elif workload_path.suffix == '.sql':
            # Load from SQL format with metadata comments
            with open(workload_path, 'r') as f:
                content = f.read()
            
            # Parse SQL with metadata
            current_query = []
            current_meta = {}
            
            for line in content.split('\n'):
                if line.strip().startswith('-- Query:'):
                    # Parse metadata line
                    parts = line.split(',')
                    for part in parts:
                        if 'Query:' in part:
                            current_meta['id'] = part.split('Query:')[1].strip()
                        elif 'Type:' in part:
                            current_meta['type'] = part.split('Type:')[1].strip()
                            
                elif line.strip().startswith('-- Database:'):
                    # Skip database line or extract if needed
                    pass
                    
                elif line.strip() and not line.startswith('--'):
                    current_query.append(line)
                    if line.rstrip().endswith(';'):
                        # Complete query found
                        query_text = ' '.join(current_query).strip()
                        if query_text.endswith(';'):
                            query_text = query_text[:-1]
                            
                        if query_text:
                            # Determine category from type
                            qtype = current_meta.get('type', 'unknown')
                            if qtype.startswith('tp_'):
                                category = 'TP'
                            elif qtype.startswith('ap_'):
                                category = 'AP'
                            else:
                                category = 'unknown'
                                
                            queries.append({
                                'id': current_meta.get('id', f'q_{len(queries):04d}'),
                                'query': query_text,
                                'type': qtype,
                                'category': category
                            })
                        
                        current_query = []
                        current_meta = {}
        else:
            # Fallback: plain text with semicolon-separated queries
            with open(workload_path, 'r') as f:
                content = f.read()
                
            for query in content.split(';'):
                query = query.strip()
                if query and not query.startswith('--'):
                    queries.append({
                        'id': f'q_{len(queries):04d}',
                        'query': query,
                        'type': 'unknown',
                        'category': 'unknown'
                    })
        
        self.logger.info(f"Loaded {len(queries)} queries from {workload_file}")
        
        # Log category breakdown
        categories = {}
        types = {}
        for q in queries:
            cat = q['category']
            typ = q['type']
            categories[cat] = categories.get(cat, 0) + 1
            types[typ] = types.get(typ, 0) + 1
            
        self.logger.info(f"Query categories: {categories}")
        self.logger.info(f"Query types: {types}")
        
        results = []
        for idx, query_info in enumerate(queries):
            query_id = query_info['id']
            self.logger.info(f"Processing {query_info['category']} query {query_id} ({idx+1}/{len(queries)}) - Type: {query_info['type']}")
            
            result = self.collect_query_data(query_info['query'], query_id, database=database_name)
            result['metadata'] = {
                'type': query_info['type'],
                'category': query_info['category']
            }
            results.append(result)
            
            # Save intermediate summary
            if idx % 10 == 0:
                self._save_summary(results)
        
        # Save final summary
        self._save_summary(results)
        
        return results
    
    def _save_summary(self, results):
        """Save summary of collected data"""
        summary = {
            'total_queries': len(results),
            'successful_mysql': sum(1 for r in results if 'mysql' in r and 'error' not in r.get('mysql', {})),
            'successful_shannon': sum(1 for r in results if 'shannonbase' in r and 'error' not in r.get('shannonbase', {})),
            'timestamp': datetime.now().isoformat()
        }
        
        # Add category breakdown
        category_counts = {}
        type_counts = {}
        for r in results:
            if 'metadata' in r:
                cat = r['metadata'].get('category', 'unknown')
                typ = r['metadata'].get('type', 'unknown')
                category_counts[cat] = category_counts.get(cat, 0) + 1
                type_counts[typ] = type_counts.get(typ, 0) + 1
        
        summary['category_breakdown'] = category_counts
        summary['type_breakdown'] = type_counts
        
        # Calculate latency statistics per category
        mysql_latencies = []
        shannon_latencies = []
        mysql_latencies_by_cat = {'TP': [], 'AP': []}
        shannon_latencies_by_cat = {'TP': [], 'AP': []}
        
        for r in results:
            cat = r.get('metadata', {}).get('category', 'unknown')
            
            if 'mysql' in r and 'latency' in r.get('mysql', {}):
                lat = r['mysql']['latency']['mean_ms']
                mysql_latencies.append(lat)
                if cat in mysql_latencies_by_cat:
                    mysql_latencies_by_cat[cat].append(lat)
                    
            if 'shannonbase' in r and 'latency' in r.get('shannonbase', {}):
                lat = r['shannonbase']['latency']['mean_ms']
                shannon_latencies.append(lat)
                if cat in shannon_latencies_by_cat:
                    shannon_latencies_by_cat[cat].append(lat)
        
        if mysql_latencies:
            summary['mysql_latency_stats'] = {
                'mean': np.mean(mysql_latencies),
                'median': np.median(mysql_latencies),
                'p95': np.percentile(mysql_latencies, 95),
                'p99': np.percentile(mysql_latencies, 99)
            }
        
        if shannon_latencies:
            summary['shannon_latency_stats'] = {
                'mean': np.mean(shannon_latencies),
                'median': np.median(shannon_latencies),
                'p95': np.percentile(shannon_latencies, 95),
                'p99': np.percentile(shannon_latencies, 99)
            }
        
        # Add per-category latency stats
        for cat in ['TP', 'AP']:
            if mysql_latencies_by_cat[cat]:
                summary[f'mysql_{cat}_latency'] = {
                    'mean': np.mean(mysql_latencies_by_cat[cat]),
                    'median': np.median(mysql_latencies_by_cat[cat]),
                    'count': len(mysql_latencies_by_cat[cat])
                }
            
            if shannon_latencies_by_cat[cat]:
                summary[f'shannon_{cat}_latency'] = {
                    'mean': np.mean(shannon_latencies_by_cat[cat]),
                    'median': np.median(shannon_latencies_by_cat[cat]),
                    'count': len(shannon_latencies_by_cat[cat])
                }
        
        summary_file = self.output_dir / 'collection_summary.json'
        with open(summary_file, 'w') as f:
            json.dump(summary, f, indent=2)
        
        self.logger.info(f"Summary saved to {summary_file}")
    
    def generate_lightgbm_dataset(self):
        """Generate LightGBM training dataset from collected data"""
        train_data = []
        
        # Process all results files
        for results_file in self.output_dir.glob('q_*_results.json'):
            with open(results_file, 'r') as f:
                result = json.load(f)
            
            # Skip if missing data
            if ('mysql' not in result or 'features' not in result['mysql'] or
                'shannonbase' not in result or 'latency' not in result['shannonbase']):
                continue
            
            features = result['mysql']['features']
            mysql_lat = result['mysql']['latency']['mean_ms']
            shannon_lat = result['shannonbase']['latency']['mean_ms']
            
            # Label: 1 if column engine is faster, 0 if row is faster
            label = 1 if shannon_lat < mysql_lat else 0
            
            # Create training row
            row = features + [label, mysql_lat, shannon_lat]
            train_data.append(row)
        
        # Save as CSV
        if train_data:
            dataset_file = self.output_dir / 'lightgbm_dataset.csv'
            header = [f'f{i}' for i in range(len(train_data[0])-3)] + ['label', 'row_latency', 'col_latency']
            
            with open(dataset_file, 'w', newline='') as f:
                writer = csv.writer(f)
                writer.writerow(header)
                writer.writerows(train_data)
            
            self.logger.info(f"LightGBM dataset saved to {dataset_file}")
            self.logger.info(f"Total samples: {len(train_data)}")
            
            # Calculate class distribution
            labels = [row[-3] for row in train_data]
            col_better = sum(labels)
            row_better = len(labels) - col_better
            
            self.logger.info(f"Class distribution: Column better: {col_better}, Row better: {row_better}")


def discover_workload_files(workload_dir='../training_workloads', pattern='training_workload_*.sql'):
    """Discover all generated workload files"""
    workload_path = Path(__file__).parent / workload_dir
    if not workload_path.exists():
        return []
    
    workload_files = list(workload_path.glob(pattern))
    return sorted(workload_files)


def main():
    parser = argparse.ArgumentParser(
        description='Collect dual engine execution data for AP and TP queries',
        formatter_class=argparse.RawDescriptionHelpFormatter,
        epilog="""
Examples:
  # Auto-discover and process all workloads
  python3 collect_dual_engine_data.py --workload auto
  
  # Process specific workload
  python3 collect_dual_engine_data.py --workload ../training_workloads/training_workload_tpch_sf1.sql
  
  # Process multiple workloads
  python3 collect_dual_engine_data.py --workload ../training_workloads/training_workload_tpch*.sql
  
  # Auto-discover with dataset generation
  python3 collect_dual_engine_data.py --workload auto --generate-dataset
        """)
    parser.add_argument('--workload', type=str, default='auto',
                       help='Path to workload file, glob pattern, or "auto" to discover all workloads (default: auto)')
    parser.add_argument('--output', type=str, default='./training_data',
                       help='Output directory for collected data (default: ./training_data)')
    parser.add_argument('--generate-dataset', action='store_true',
                       help='Generate LightGBM dataset after collection')
    parser.add_argument('--database', type=str, default=None,
                       help='Filter to specific database when using auto-discovery (e.g., tpch_sf1)')
    
    args = parser.parse_args()
    
    # Determine which workload files to process
    workload_files = []
    
    if args.workload == 'auto':
        # Auto-discover workload files
        print("Auto-discovering workload files...")
        workload_files = discover_workload_files()
        
        # Filter by database if specified
        if args.database:
            workload_files = [f for f in workload_files if args.database in f.name]
            print(f"Filtered to database: {args.database}")
        
        if not workload_files:
            print("No workload files found. Please generate workloads first using:")
            print("  python3 generate_training_workload_advanced.py --all-datasets")
            return
        
        print(f"Found {len(workload_files)} workload files:")
        for f in workload_files:
            print(f"  - {f.name}")
    
    elif '*' in args.workload or '?' in args.workload:
        # Glob pattern
        from glob import glob
        workload_files = [Path(f) for f in glob(args.workload)]
        if not workload_files:
            print(f"No workload files matching pattern: {args.workload}")
            return
        print(f"Found {len(workload_files)} workload files matching pattern")
    
    else:
        # Single file
        workload_files = [Path(args.workload)]
        if not workload_files[0].exists():
            print(f"Error: Workload file not found: {args.workload}")
            return
    
    # Process each workload file
    collector = DualEngineCollector(output_dir=args.output)
    all_results = []
    
    for idx, workload_file in enumerate(workload_files, 1):
        print(f"\n{'='*60}")
        print(f"Processing workload {idx}/{len(workload_files)}: {workload_file.name}")
        print(f"{'='*60}")
        
        try:
            results = collector.collect_from_workload(str(workload_file))
            all_results.extend(results)
        except Exception as e:
            print(f"Error processing {workload_file.name}: {e}")
            import traceback
            traceback.print_exc()
    
    # Generate LightGBM dataset if requested
    if args.generate_dataset and all_results:
        print(f"\n{'='*60}")
        print("Generating LightGBM dataset from all collected data")
        print(f"{'='*60}")
        collector.generate_lightgbm_dataset()
    
    print(f"\nData collection complete!")
    print(f"  Total workloads processed: {len(workload_files)}")
    print(f"  Total queries collected: {len(all_results)}")
    print(f"  Results saved to: {args.output}")


if __name__ == "__main__":
    main()
