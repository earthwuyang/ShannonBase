#!/bin/bash
source setup_tpc_benchmarks_parallel.sh

# Override the load functions to be safer
load_tpch_parallel_safe() {
    print_status "Loading TPC-H data with SAFE parallel processing..."
    
    # Create database and ALL tables first (sequentially to avoid race)
    mysql_exec "CREATE DATABASE IF NOT EXISTS tpch_sf1 DEFAULT CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;"
    
    print_status "Creating ALL TPC-H tables sequentially (avoiding parallel DDL)..."
    # ... (table creation SQL here, run sequentially)
    
    print_status "Now loading data with parallelism=${MAX_PARALLEL}..."
    # ... (data loading here, can be parallel)
}

# Replace the original function
load_tpch_parallel() {
    load_tpch_parallel_safe
}
