#!/usr/bin/env python3
import mysql.connector

conn = mysql.connector.connect(
    host='127.0.0.1',
    port=3307,
    user='root',
    database='financial'
)
conn.autocommit = True
cursor = conn.cursor()

print("Unloading order table from Rapid...")
try:
    cursor.execute("ALTER TABLE `order` SECONDARY_UNLOAD")
    print("✅ Unloaded")
except Exception as e:
    print(f"⚠️  Unload error (might not be loaded): {e}")

print("\nLoading order table into Rapid...")
try:
    cursor.execute("ALTER TABLE `order` SECONDARY_LOAD")
    print("✅ Loaded")
except Exception as e:
    print(f"❌ Load error: {e}")

print("\nTesting counts...")
cursor.execute("SET SESSION use_secondary_engine = OFF")
cursor.execute("SELECT COUNT(*) FROM `order`")
innodb_count = cursor.fetchone()[0]
print(f"InnoDB count: {innodb_count}")

cursor.execute("SET SESSION use_secondary_engine = FORCED")
cursor.execute("SELECT COUNT(*) FROM `order`")
rapid_count = cursor.fetchone()[0]
print(f"Rapid count: {rapid_count}")

if innodb_count == rapid_count:
    print("\n✅ SUCCESS: Counts match!")
else:
    print(f"\n⚠️  WARNING: Counts don't match (InnoDB: {innodb_count}, Rapid: {rapid_count})")

cursor.close()
conn.close()
