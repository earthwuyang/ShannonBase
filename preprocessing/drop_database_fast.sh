#!/bin/bash
# Fast database drop script for MySQL/ShannonBase

DB_NAME="${1:-Airline}"
MYSQL_CMD="mysql -h 127.0.0.1 -P 3307 -u root -pshannonbase"

echo "============================================================"
echo "Fast Database Drop Script"
echo "Database: $DB_NAME"
echo "============================================================"

# Method 1: Drop tables individually first (faster than DROP DATABASE)
echo "Method 1: Dropping tables individually..."

$MYSQL_CMD -N -e "
SELECT CONCAT('DROP TABLE IF EXISTS \`', table_name, '\`;') 
FROM information_schema.tables 
WHERE table_schema = '$DB_NAME';
" 2>/dev/null | while read drop_cmd; do
    echo "  Executing: $drop_cmd"
    $MYSQL_CMD -e "SET FOREIGN_KEY_CHECKS = 0; $drop_cmd" 2>/dev/null
done

echo "  Tables dropped, now dropping empty database..."
$MYSQL_CMD -e "DROP DATABASE IF EXISTS $DB_NAME;" 2>/dev/null && echo "✓ Database dropped successfully!" || echo "✗ Could not drop database"

echo ""
echo "Verification:"
$MYSQL_CMD -e "SHOW DATABASES LIKE '$DB_NAME';" 2>/dev/null

if [ -z "$($MYSQL_CMD -N -e "SHOW DATABASES LIKE '$DB_NAME';" 2>/dev/null)" ]; then
    echo "✅ Database $DB_NAME successfully removed!"
else
    echo "⚠️ Database $DB_NAME still exists. Trying alternative method..."
    
    # Method 2: Drop with system command (last resort)
    echo "Method 2: Using filesystem approach..."
    DATA_DIR="/home/wuy/DB/ShannonBase/db/data"
    
    if [ -d "$DATA_DIR/$DB_NAME" ]; then
        echo "  Stopping any active connections..."
        $MYSQL_CMD -e "
        SELECT CONCAT('KILL ', id, ';') 
        FROM information_schema.processlist 
        WHERE db = '$DB_NAME' AND command != 'Sleep';
        " 2>/dev/null | while read kill_cmd; do
            $MYSQL_CMD -e "$kill_cmd" 2>/dev/null
        done
        
        echo "  Removing database directory..."
        rm -rf "$DATA_DIR/$DB_NAME"
        
        echo "  Restarting MySQL to recognize changes..."
        echo "  Please restart MySQL manually if needed."
    fi
fi

echo "============================================================"
echo "Done!"
echo "============================================================"
