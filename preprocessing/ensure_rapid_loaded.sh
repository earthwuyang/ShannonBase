#!/bin/bash
# Ensure all tables with SECONDARY_ENGINE are loaded into Rapid

DATABASES=("tpch_sf1" "tpcds_sf1" "Airline" "Credit" "Carcinogenesis" "Hepatitis_std" "employee" "financial" "geneea")

for DB in "${DATABASES[@]}"; do
    echo "Loading tables in $DB into Rapid..."
    
    # Get all tables with SECONDARY_ENGINE
    TABLES=$(mysql -u root -P3307 -h127.0.0.1 -N -B -e "
        SELECT TABLE_NAME 
        FROM information_schema.tables 
        WHERE table_schema='$DB' 
        AND CREATE_OPTIONS LIKE '%SECONDARY_ENGINE%'
    " 2>/dev/null)
    
    if [ -z "$TABLES" ]; then
        echo "  No tables with SECONDARY_ENGINE in $DB"
        continue
    fi
    
    # Load each table
    for TABLE in $TABLES; do
        echo -n "  Loading $TABLE... "
        mysql -u root -P3307 -h127.0.0.1 "$DB" -e "ALTER TABLE \`$TABLE\` SECONDARY_LOAD;" 2>&1 > /dev/null
        if [ $? -eq 0 ]; then
            echo "✓"
        else
            echo "✗ (may not be supported)"
        fi
    done
done

echo "Done! All tables loaded into Rapid engine."
