# Dual Engine Data Collection Updates

## Summary of Changes

The `collect_dual_engine_data.py` script has been updated to correctly force execution on different storage engines in ShannonBase.

## Key Changes

### 1. Correct Engine Forcing (CRITICAL FIX)

**Previous (INCORRECT)**:
```python
# This variable doesn't exist in ShannonBase
cursor.execute("SET use_column_engine = 1")
```

**Current (CORRECT)**:
```python
# Primary Engine (InnoDB - Row Store)
cursor.execute("SET SESSION use_secondary_engine = OFF")

# Secondary Engine (Rapid - Column Store)
cursor.execute("SET SESSION use_secondary_engine = FORCED")
```

### 2. Single ShannonBase Instance

Both "engines" now connect to the same ShannonBase instance (port 3307) with different engine settings:

```python
MYSQL_CONFIG = {
    'port': 3307,  # ShannonBase with primary engine forced
}

SHANNONBASE_CONFIG = {
    'port': 3307,  # ShannonBase with secondary engine forced
}
```

### 3. Engine Verification

Added method to verify which engine is being used:

```python
def verify_engine_used(self, cursor):
    cursor.execute("SHOW SESSION VARIABLES LIKE 'use_secondary_engine'")
    result = cursor.fetchone()
    return result[1]  # Returns 'OFF', 'ON', or 'FORCED'
```

### 4. Enhanced Result Metadata

Results now include engine information:

```json
{
  "mysql": {
    "engine_mode": "OFF",
    "engine_type": "InnoDB (Primary/Row Store)",
    "latency": {...}
  },
  "shannonbase": {
    "engine_mode": "FORCED", 
    "engine_type": "Rapid (Secondary/Column Store)",
    "latency": {...}
  }
}
```

## How It Works

### Engine Control

ShannonBase's `use_secondary_engine` variable has 3 modes:

| Value | Mode | Behavior |
|-------|------|----------|
| OFF (0) | Primary Only | All queries use InnoDB |
| ON (1) | Optimizer Choice | Optimizer decides based on cost |
| FORCED (2) | Secondary Forced | Eligible queries use Rapid |

### Data Collection Flow

```
┌────────────────────────────────────────────┐
│     collect_dual_engine_data.py            │
├────────────────────────────────────────────┤
│                                            │
│  Connection 1: "MySQL"                     │
│  ├─ Connect to localhost:3307              │
│  ├─ SET use_secondary_engine = OFF         │
│  └─ Execute queries → InnoDB (row store)   │
│                                            │
│  Connection 2: "ShannonBase"               │
│  ├─ Connect to localhost:3307              │
│  ├─ SET use_secondary_engine = FORCED      │
│  └─ Execute queries → Rapid (column store) │
│                                            │
└────────────────────────────────────────────┘
```

## Documentation Added

1. **ENGINE_FORCING_GUIDE.md** - Complete guide on engine forcing
2. **DUAL_ENGINE_UPDATES.md** - This file
3. **WORKLOAD_COLLECTION_GUIDE.md** - End-to-end workflow guide

## Testing

### Verify Engine Settings

```bash
# Test that engine forcing works
mysql -h 127.0.0.1 -P 3307 -u root -pshannonbase <<EOF
SET SESSION use_secondary_engine = OFF;
SELECT @@session.use_secondary_engine;  -- Should show 'OFF'

SET SESSION use_secondary_engine = FORCED;
SELECT @@session.use_secondary_engine;  -- Should show 'FORCED'
EOF
```

### Check Available Engines

```bash
mysql -h 127.0.0.1 -P 3307 -u root -pshannonbase \
  -e "SHOW ENGINES WHERE Engine IN ('InnoDB', 'Rapid');"
```

Expected output:
```
Engine  Support  Comment
InnoDB  DEFAULT  Supports transactions...
Rapid   YES      Shannon Rapid storage engine
```

## Usage

### Basic Usage (Auto-discover all workloads)

```bash
cd /home/wuy/DB/ShannonBase/preprocessing

# Process all generated workloads automatically
python3 collect_dual_engine_data.py

# Process specific database
python3 collect_dual_engine_data.py --database tpch_sf1

# Generate LightGBM dataset
python3 collect_dual_engine_data.py --generate-dataset
```

### Verify Correct Engine Usage

Check the generated results to ensure engines are being forced correctly:

```bash
# Examine a result file
cat training_data/q_0000_results.json | python3 -m json.tool | grep -A2 engine_
```

Expected output:
```json
"engine_mode": "OFF",
"engine_type": "InnoDB (Primary/Row Store)",
--
"engine_mode": "FORCED",
"engine_type": "Rapid (Secondary/Column Store)",
```

## Troubleshooting

### Issue: Both engines show same performance

**Diagnosis**: Rapid engine not being forced correctly
**Solution**: 
```python
# Add debug logging
logging.basicConfig(level=logging.DEBUG)
# Check engine_mode in results
```

### Issue: "Query cannot use secondary engine"

**Expected behavior** for:
- Point lookups by primary key
- Small indexed range scans  
- Most TP (transactional) queries

These will fall back to InnoDB even with `FORCED` mode.

### Issue: Connection refused on port 3307

**Cause**: ShannonBase not running
**Solution**:
```bash
# Check ShannonBase status
mysql -h 127.0.0.1 -P 3307 -u root -pshannonbase -e "SELECT 1"

# Start ShannonBase if needed
cd /home/wuy/DB/ShannonBase
./start_mysql.sh
```

## Performance Expectations

### Typical Results

**OLTP Queries (TP)**:
- InnoDB: Faster (row-oriented, indexed access)
- Rapid: Slower (column-oriented, full scans)

**OLAP Queries (AP)**:
- InnoDB: Slower (row scans, join overhead)
- Rapid: Faster (columnar compression, vectorization)

### Example

```
Query: SELECT COUNT(*), AVG(amount) FROM orders 
       WHERE date > '2023-01-01' GROUP BY customer_id

InnoDB:  250ms (row-by-row scan)
Rapid:    45ms (columnar aggregation)
```

## Next Steps

1. **Generate Workloads**:
   ```bash
   python3 generate_training_workload_advanced.py --all-datasets
   ```

2. **Collect Data**:
   ```bash
   python3 collect_dual_engine_data.py --generate-dataset
   ```

3. **Train Model**:
   ```bash
   python3 train_lightgbm_model.py --data ./training_data/lightgbm_dataset.csv
   ```

## References

- **ShannonBase Source**: `/sql/sys_vars.cc` - `use_secondary_engine` definition
- **Engine Implementation**: `/storage/rapid_engine/` - Rapid engine source
- **System Variables**: `/sql/system_variables.h` - Engine enum definitions

## Changelog

**2025-10-21**:
- Fixed engine forcing to use correct `use_secondary_engine` variable
- Changed both connections to use ShannonBase on port 3307
- Added engine verification and metadata
- Added comprehensive documentation
- Updated auto-discovery to find all workloads

**Previous**:
- Used incorrect `use_column_engine` variable
- Connected to MySQL on port 3306 (separate instance)
- No engine verification
