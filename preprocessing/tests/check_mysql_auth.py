#!/usr/bin/env python3
"""
Diagnostic script to check MySQL/ShannonBase authentication configuration.
"""

import mysql.connector
from mysql.connector import Error as MySQLError

# Configuration
HOST = '127.0.0.1'
PORT = 3307
USER = 'root'
PASSWORD = 'shannonbase'

def test_connection(config_name, **kwargs):
    """Test a connection configuration."""
    print(f"\n{'='*60}")
    print(f"Testing: {config_name}")
    print(f"Config: {kwargs}")
    print('-'*60)
    
    try:
        conn = mysql.connector.connect(**kwargs)
        print("✓ Connection successful!")
        
        # Try to get server info
        cursor = conn.cursor()
        cursor.execute("SELECT VERSION()")
        version = cursor.fetchone()[0]
        print(f"  Server version: {version}")
        
        # Check available plugins
        cursor.execute("""
            SELECT PLUGIN_NAME, PLUGIN_STATUS, PLUGIN_TYPE 
            FROM INFORMATION_SCHEMA.PLUGINS 
            WHERE PLUGIN_TYPE = 'AUTHENTICATION'
            ORDER BY PLUGIN_NAME
        """)
        plugins = cursor.fetchall()
        if plugins:
            print(f"\n  Available authentication plugins:")
            for plugin_name, status, ptype in plugins:
                print(f"    - {plugin_name}: {status}")
        else:
            print("  No authentication plugins found in INFORMATION_SCHEMA.PLUGINS")
        
        cursor.close()
        conn.close()
        return True
        
    except MySQLError as exc:
        print(f"✗ Connection failed:")
        print(f"  Error code: {exc.errno}")
        print(f"  Error msg: {exc.msg}")
        return False
    except Exception as e:
        print(f"✗ Unexpected error: {e}")
        return False

# Test various connection strategies
print("="*60)
print("MySQL/ShannonBase Authentication Diagnostics")
print("="*60)

# Strategy 1: Absolute minimal
test_connection(
    "Minimal (auto-negotiate)",
    host=HOST,
    port=PORT,
    user=USER,
    password=PASSWORD
)

# Strategy 2: With get_server_public_key
test_connection(
    "With get_server_public_key",
    host=HOST,
    port=PORT,
    user=USER,
    password=PASSWORD,
    get_server_public_key=True
)

# Strategy 3: With SSL disabled
test_connection(
    "With SSL disabled",
    host=HOST,
    port=PORT,
    user=USER,
    password=PASSWORD,
    ssl_disabled=True
)

# Strategy 4: With allow_local_infile
test_connection(
    "With allow_local_infile",
    host=HOST,
    port=PORT,
    user=USER,
    password=PASSWORD,
    allow_local_infile=True
)

# Strategy 5: With charset
test_connection(
    "With charset utf8mb4",
    host=HOST,
    port=PORT,
    user=USER,
    password=PASSWORD,
    charset='utf8mb4'
)

# Strategy 6: Combine successful options
test_connection(
    "Combined (minimal + pubkey + ssl_disabled)",
    host=HOST,
    port=PORT,
    user=USER,
    password=PASSWORD,
    get_server_public_key=True,
    ssl_disabled=True
)

print(f"\n{'='*60}")
print("Diagnostics complete")
print("="*60)
