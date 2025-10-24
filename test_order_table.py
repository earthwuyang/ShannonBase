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

# Check table definition
cursor.execute("SHOW CREATE TABLE `order`")
result = cursor.fetchone()
print("Table Definition:")
print(result[1])
print("\n" + "="*60 + "\n")

# Count in InnoDB
cursor.execute("SET SESSION use_secondary_engine = OFF")
cursor.execute("SELECT COUNT(*) FROM `order`")
innodb_count = cursor.fetchone()[0]
print(f"InnoDB count: {innodb_count}")

# Count in Rapid
cursor.execute("SET SESSION use_secondary_engine = FORCED")
cursor.execute("SELECT COUNT(*) FROM `order`")
rapid_count = cursor.fetchone()[0]
print(f"Rapid count: {rapid_count}")

cursor.close()
conn.close()
