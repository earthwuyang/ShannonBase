#!/bin/bash

# Load all tables from all databases into Rapid engine
# This is required before running collect_dual_engine_data.py

MYSQL="mysql -h 127.0.0.1 -P 3307 -u root -pshannonbase"

echo "=== Loading Tables into Rapid Engine ==="
echo ""

# List of databases to process
DATABASES=("tpch_sf1" "tpcds_sf1" "Airline" "Credit" "Carcinogenesis" "Hepatitis_std" "employee" "financial" "geneea")

for DB in "${DATABASES[@]}"; do
    echo "Processing database: $DB"
    
    # Check if database exists
    DB_EXISTS=$($MYSQL -e "SHOW DATABASES LIKE '$DB';" 2>/dev/null | grep -c "$DB")
    
    if [ "$DB_EXISTS" -eq 0 ]; then
        echo "  ⚠ Database $DB does not exist, skipping"
        continue
    fi
    
    # Get all tables in the database
    TABLES=$($MYSQL -D "$DB" -N -e "SHOW TABLES;" 2>/dev/null)
    
    if [ -z "$TABLES" ]; then
        echo "  ⚠ No tables found in $DB"
        continue
    fi
    
    # Load each table into Rapid engine
    TABLE_COUNT=0
    while IFS= read -r TABLE; do
        echo "  Processing: $DB.$TABLE"
        
        # First, add secondary engine to the table
        echo "    1. Adding SECONDARY_ENGINE=Rapid"
        RESULT=$($MYSQL -D "$DB" -e "ALTER TABLE \`$TABLE\` SECONDARY_ENGINE=Rapid;" 2>&1)
        
        if [ $? -ne 0 ]; then
            if echo "$RESULT" | grep -q "already"; then
                echo "       ✓ Already has secondary engine"
            else
                echo "       ✗ Failed to add secondary engine: $RESULT"
                continue
            fi
        else
            echo "       ✓ Secondary engine added"
        fi
        
        # Then, load the data into Rapid
        echo "    2. Loading data into Rapid"
        RESULT=$($MYSQL -D "$DB" -e "ALTER TABLE \`$TABLE\` SECONDARY_LOAD;" 2>&1)
        
        if [ $? -eq 0 ]; then
            echo "       ✓ Data loaded successfully"
            ((TABLE_COUNT++))
        else
            # Check if it's already loaded
            if echo "$RESULT" | grep -q "already loaded\|already exists"; then
                echo "       ✓ Already loaded"
                ((TABLE_COUNT++))
            else
                echo "       ✗ Load failed: $RESULT"
            fi
        fi
        echo ""
    done <<< "$TABLES"
    
    echo "  Summary: Loaded $TABLE_COUNT tables from $DB"
    echo ""
done

echo ""
echo "=== Verifying Rapid Engine Tables ==="
echo ""

for DB in "${DATABASES[@]}"; do
    DB_EXISTS=$($MYSQL -e "SHOW DATABASES LIKE '$DB';" 2>/dev/null | grep -c "$DB")
    
    if [ "$DB_EXISTS" -eq 0 ]; then
        continue
    fi
    
    # Check tables loaded into Rapid
    RAPID_COUNT=$($MYSQL -D "$DB" -N -e "
        SELECT COUNT(*) 
        FROM information_schema.tables 
        WHERE table_schema = '$DB' 
        AND engine = 'Rapid';" 2>/dev/null)
    
    TOTAL_COUNT=$($MYSQL -D "$DB" -N -e "
        SELECT COUNT(*) 
        FROM information_schema.tables 
        WHERE table_schema = '$DB' 
        AND table_type = 'BASE TABLE';" 2>/dev/null)
    
    if [ -n "$RAPID_COUNT" ] && [ -n "$TOTAL_COUNT" ]; then
        echo "$DB: $RAPID_COUNT/$TOTAL_COUNT tables in Rapid engine"
    fi
done

echo ""
echo "=== Load Complete ==="
echo ""
echo "Now you can run: python3 collect_dual_engine_data.py"
