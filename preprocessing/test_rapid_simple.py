#!/usr/bin/env python3
import mysql.connector

config = {
    'host': '127.0.0.1',
    'port': 3307,
    'user': 'root',
    'password': '',
    'database': 'Airline'
}

query = "SELECT L_DEPARRBLK.Code, COUNT(*) AS total_count FROM L_DEPARRBLK WHERE L_DEPARRBLK.Description LIKE '%' AND L_DEPARRBLK.Code LIKE '%' GROUP BY L_DEPARRBLK.Code"

print("Test 1: Without optimizer trace")
try:
    conn = mysql.connector.connect(**config)
    cursor = conn.cursor()
    cursor.execute("SET SESSION use_secondary_engine = FORCED")
    cursor.execute(query)
    print(f"✅ Success - {len(cursor.fetchall())} rows")
    cursor.close()
    conn.close()
except Exception as e:
    print(f"❌ Failed: {e}")

print("\nTest 2: With optimizer trace")
try:
    conn = mysql.connector.connect(**config)
    cursor = cursor.cursor()
    cursor.execute("SET SESSION use_secondary_engine = FORCED")
    cursor.execute("SET optimizer_trace='enabled=on'")
    cursor.execute(query)
    print(f"✅ Success - {len(cursor.fetchall())} rows")
    cursor.close()
    conn.close()
except Exception as e:
    print(f"❌ Failed: {e}")
