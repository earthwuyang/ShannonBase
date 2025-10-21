# Automatic Rapid Engine Loading for All Datasets

## Overview

Both data loading scripts have been updated to automatically configure tables for the Rapid (secondary) engine:

1. **setup_tpc_benchmarks_parallel.sh** - TPC-H and TPC-DS benchmarks
2. **import_ctu_datasets_parallel.py** - CTU and other datasets

## What Changed

### 1. Table Definitions Include SECONDARY_ENGINE=Rapid

All `CREATE TABLE` statements now include `SECONDARY_ENGINE=Rapid`:

**Before**:
```sql
CREATE TABLE nation (
    ...
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;
```

**After**:
```sql
CREATE TABLE nation (
    ...
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 SECONDARY_ENGINE=Rapid;
```

### 2. Automatic Data Loading into Rapid

After data is loaded into InnoDB, it's automatically loaded into Rapid:

```bash
# After loading data into InnoDB primary engine
ALTER TABLE nation SECONDARY_LOAD;
ALTER TABLE region SECONDARY_LOAD;
...
```

## Updated Scripts

### setup_tpc_benchmarks_parallel.sh

**Changes**:
- ✅ All 8 TPC-H table definitions include `SECONDARY_ENGINE=Rapid`
- ✅ All 24 TPC-DS table definitions include `SECONDARY_ENGINE=Rapid`
- ✅ Automatic SECONDARY_LOAD after TPC-H data import (Line ~437-444)
- ✅ Automatic SECONDARY_LOAD after TPC-DS data import (Line ~1056-1063)

**Tables Updated**:

TPC-H (8 tables):
- customer, lineitem, nation, orders, part, partsupp, region, supplier

TPC-DS (24 tables):
- call_center, catalog_page, catalog_returns, catalog_sales
- customer, customer_address, customer_demographics
- date_dim, dbgen_version, household_demographics
- income_band, inventory, item, promotion, reason
- ship_mode, store, store_returns, store_sales
- time_dim, warehouse, web_page, web_returns, web_sales, web_site

### import_ctu_datasets_parallel.py

**Changes**:
- ✅ Automatically adds `SECONDARY_ENGINE=Rapid` to CREATE TABLE statements (Line 189-192)
- ✅ New Phase 4: Loads all tables into Rapid after import (Line 421-437)

**Applies to all CTU datasets**:
- Airline, Credit, Carcinogenesis, Hepatitis_std
- employee, financial, geneea, and any other datasets

## Usage

### For TPC Benchmarks

Simply run the setup script as before - Rapid loading is automatic:

```bash
cd /home/wuy/DB/ShannonBase/preprocessing

# Run the setup script - now includes Rapid loading
./setup_tpc_benchmarks_parallel.sh
```

**Output will include**:
```
[INFO] Loading TPC-H data into Rapid engine...
[INFO] Loading customer into Rapid...
[INFO] Loading lineitem into Rapid...
...
[INFO] TPC-H tables loaded into Rapid engine!
```

### For CTU Datasets

Import datasets as before - Rapid loading is automatic:

```bash
cd /home/wuy/DB/ShannonBase/preprocessing

# Import datasets - now includes Rapid loading
python3 import_ctu_datasets_parallel.py
```

**Output will include**:
```
  🚀 Phase 4: Loading tables into Rapid engine...
    [1/5] Loading table1 into Rapid... ✓
    [2/5] Loading table2 into Rapid... ✓
    ...
  ✅ All tables loaded into Rapid engine!
```

## Verification

Check that tables are configured for Rapid:

```bash
# Show table definition
mysql -h 127.0.0.1 -P 3307 -u root -pshannonbase -e "SHOW CREATE TABLE tpch_sf1.nation\G"

# Expected output includes:
# ) ENGINE=InnoDB ... SECONDARY_ENGINE=Rapid
```

Check which tables are in Rapid engine:

```bash
mysql -h 127.0.0.1 -P 3307 -u root -pshannonbase <<'EOF'
SELECT table_schema, table_name, engine
FROM information_schema.tables
WHERE table_schema IN ('tpch_sf1', 'tpcds_sf1', 'Airline', 'Credit', 'employee')
  AND engine = 'Rapid'
ORDER BY table_schema, table_name;
EOF
```

## Benefits

1. **Automatic Configuration**: No manual `ALTER TABLE` commands needed
2. **Consistent Setup**: All datasets configured the same way
3. **Ready for Hybrid Optimizer**: Tables available in both engines immediately
4. **Data Collection Ready**: `collect_dual_engine_data.py` can run immediately

## How It Works

### Two-Step Process

1. **Primary Engine (InnoDB)**:
   - Table created with `SECONDARY_ENGINE=Rapid` attribute
   - Data loaded into InnoDB (primary storage)
   - Data persisted on disk in row format

2. **Secondary Engine (Rapid)**:
   - `ALTER TABLE ... SECONDARY_LOAD` executed
   - Data loaded into Rapid (columnar format)
   - Data available for OLAP queries

### Execution Flow

```
┌─────────────────────────────────────────┐
│ 1. CREATE TABLE ... SECONDARY_ENGINE=Rapid │
├─────────────────────────────────────────┤
│ 2. LOAD DATA INTO TABLE (InnoDB)        │
├─────────────────────────────────────────┤
│ 3. ALTER TABLE SECONDARY_LOAD           │
├─────────────────────────────────────────┤
│ ✅ Table available in both engines      │
└─────────────────────────────────────────┘
```

## Troubleshooting

### Issue: "No secondary engine defined"

**Symptom**:
```
ERROR 3889 (HY000): Secondary engine operation failed. 
No secondary engine defined.
```

**Cause**: Table doesn't have `SECONDARY_ENGINE=Rapid` attribute

**Solution**: Re-run the setup script or manually add:
```sql
ALTER TABLE tablename SECONDARY_ENGINE=Rapid;
ALTER TABLE tablename SECONDARY_LOAD;
```

### Issue: SECONDARY_LOAD fails

**Possible Causes**:
1. Table has no data (empty tables can't be loaded)
2. Data type incompatibility with Rapid engine
3. Rapid engine not available

**Check Rapid engine**:
```sql
SHOW ENGINES WHERE Engine = 'Rapid';
```

### Issue: Already loaded warning

**Symptom**:
```
Warning: Table already loaded into secondary engine
```

**Action**: This is informational, not an error. The table is already in Rapid.

## Impact on collect_dual_engine_data.py

The data collection script will now work correctly because:

1. ✅ All tables have `SECONDARY_ENGINE=Rapid` defined
2. ✅ Data is loaded into both engines
3. ✅ `use_secondary_engine = OFF` uses InnoDB
4. ✅ `use_secondary_engine = FORCED` uses Rapid
5. ✅ Accurate performance comparison possible

## Performance Impact

**Setup Time**:
- Adds ~1-5 minutes per database (depending on size)
- TPC-H: ~2-3 minutes for SECONDARY_LOAD
- TPC-DS: ~5-10 minutes for SECONDARY_LOAD
- CTU datasets: ~1-2 minutes per dataset

**Worth It Because**:
- One-time cost during setup
- Enables immediate data collection
- No manual intervention needed
- Consistent across all datasets

## Migration Guide

### For Existing Installations

If you already have data loaded without Rapid:

**Option 1: Re-run setup scripts** (recommended):
```bash
# Drops and recreates everything with Rapid support
./setup_tpc_benchmarks_parallel.sh
python3 import_ctu_datasets_parallel.py
```

**Option 2: Manually add Rapid** (preserves data):
```bash
# Run the load script we created earlier
./load_tables_to_rapid.sh
```

**Option 3: Per-database manual**:
```sql
USE tpch_sf1;

-- For each table
ALTER TABLE customer SECONDARY_ENGINE=Rapid;
ALTER TABLE customer SECONDARY_LOAD;

ALTER TABLE lineitem SECONDARY_ENGINE=Rapid;
ALTER TABLE lineitem SECONDARY_LOAD;
-- ... repeat for all tables
```

## Summary

| Aspect | Before | After |
|--------|--------|-------|
| Table Definition | InnoDB only | InnoDB + SECONDARY_ENGINE=Rapid |
| Data Loading | Manual Rapid load needed | Automatic Rapid load |
| Setup Steps | 2 separate steps | 1 unified step |
| Ready for Collection | ❌ Requires manual work | ✅ Immediate |
| User Effort | High (manual ALTER) | Low (automatic) |

## Next Steps

1. ✅ Scripts updated with Rapid support
2. ✅ Automatic loading implemented
3. ▶️ Run setup scripts to load data
4. ▶️ Verify tables are in Rapid
5. ▶️ Run `collect_dual_engine_data.py` for data collection
6. ▶️ Train hybrid optimizer model

All datasets will now be automatically configured for dual-engine operation! 🎉
