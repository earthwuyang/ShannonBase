#!/usr/bin/env python3
import os
import mysql.connector

# Same config as import_ctu_datasets.py
LOCAL_MYSQL_CONFIG = {
    'host': os.environ.get('LOCAL_MYSQL_HOST', '127.0.0.1'),
    'port': int(os.environ.get('LOCAL_MYSQL_PORT', '3307')),
    'user': os.environ.get('LOCAL_MYSQL_USER', os.environ.get('USER', 'root')),
    'password': os.environ.get('LOCAL_MYSQL_PASSWORD', 'shannonbase'),
    'allow_local_infile': True  # Required for LOAD DATA LOCAL INFILE
}

print("Config:", LOCAL_MYSQL_CONFIG)
print("\nAttempting connection...")

try:
    conn = mysql.connector.connect(**LOCAL_MYSQL_CONFIG)
    print("✓ Connected successfully!")
    cursor = conn.cursor()
    cursor.execute("SELECT VERSION()")
    print(f"  Server version: {cursor.fetchone()[0]}")
    cursor.close()
    conn.close()
except Exception as e:
    print(f"✗ Failed: {e}")
    print(f"  Type: {type(e)}")
    if hasattr(e, 'errno'):
        print(f"  errno: {e.errno}")
    if hasattr(e, 'msg'):
        print(f"  msg: {e.msg}")
