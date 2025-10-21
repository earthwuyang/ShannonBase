#!/usr/bin/env python3
"""
Dual Engine Data Collection for Hybrid Optimizer
Collects query execution data from both MySQL row store and ShannonBase column engine
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
MYSQL_CONFIG = {
    'host': '127.0.0.1',
    'port': 3306,
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
    'optimizer_trace_features': 1,
    'optimizer_trace_limit': 5,
    'optimizer_trace_offset': -5,
    'optimizer_trace_max_mem_size': 65536
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
    
    def connect_mysql(self):
        """Connect to MySQL row store"""
        try:
            conn = mysql.connector.connect(**MYSQL_CONFIG)
            cursor = conn.cursor()
            # Enable optimizer trace
            for setting, value in OPTIMIZER_TRACE_SETTINGS.items():
                cursor.execute(f"SET {setting} = '{value}'")
            return conn, cursor
        except Exception as e:
            self.logger.error(f"Failed to connect to MySQL: {e}")
            raise
    
    def connect_shannonbase(self):
        """Connect to ShannonBase column engine"""
        try:
            conn = mysql.connector.connect(**SHANNONBASE_CONFIG)
            cursor = conn.cursor()
            # Enable optimizer trace
            for setting, value in OPTIMIZER_TRACE_SETTINGS.items():
                cursor.execute(f"SET {setting} = '{value}'")
            # Enable column store execution
            cursor.execute("SET use_column_engine = 1")
            return conn, cursor
        except Exception as e:
            self.logger.error(f"Failed to connect to ShannonBase: {e}")
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
    
    def collect_query_data(self, query, query_id):
        """Collect features and latencies for a single query"""
        results = {
            'query_id': query_id,
            'query_hash': hashlib.md5(query.encode()).hexdigest(),
            'timestamp': datetime.now().isoformat()
        }
        
        # Collect from MySQL (row store)
        try:
            mysql_conn, mysql_cursor = self.connect_mysql()
            
            # Get features
            mysql_cursor.execute(query)
            mysql_cursor.fetchall()
            features = self.extract_features_from_trace(mysql_cursor)
            
            # Get latency
            mysql_latency = self.execute_with_timing(mysql_cursor, query)
            
            results['mysql'] = {
                'features': features,
                'latency': mysql_latency
            }
            
            mysql_conn.close()
            
        except Exception as e:
            self.logger.error(f"MySQL execution failed for query {query_id}: {e}")
            results['mysql'] = {'error': str(e)}
        
        # Collect from ShannonBase (column store)
        try:
            shannon_conn, shannon_cursor = self.connect_shannonbase()
            
            # Get features (should be same as MySQL)
            shannon_cursor.execute(query)
            shannon_cursor.fetchall()
            shannon_features = self.extract_features_from_trace(shannon_cursor)
            
            # Get latency
            shannon_latency = self.execute_with_timing(shannon_cursor, query)
            
            results['shannonbase'] = {
                'features': shannon_features,
                'latency': shannon_latency
            }
            
            shannon_conn.close()
            
        except Exception as e:
            self.logger.error(f"ShannonBase execution failed for query {query_id}: {e}")
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
            
            result = self.collect_query_data(query_info['query'], query_id)
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


def main():
    parser = argparse.ArgumentParser(description='Collect dual engine execution data for AP and TP queries')
    parser.add_argument('--workload', type=str, required=True,
                       help='Path to workload file (SQL or JSON format from generate_training_workload_advanced.py)')
    parser.add_argument('--output', type=str, default='./training_data',
                       help='Output directory for collected data')
    parser.add_argument('--generate-dataset', action='store_true',
                       help='Generate LightGBM dataset after collection')
    
    args = parser.parse_args()
    
    collector = DualEngineCollector(output_dir=args.output)
    
    # Collect data from workload
    results = collector.collect_from_workload(args.workload)
    
    # Generate LightGBM dataset if requested
    if args.generate_dataset:
        collector.generate_lightgbm_dataset()
    
    print(f"Data collection complete. Results saved to {args.output}")


if __name__ == "__main__":
    main()
