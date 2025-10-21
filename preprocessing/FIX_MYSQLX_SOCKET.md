# MySQL X Plugin Socket Error Fix

## Problem

You're seeing this error:
```
[ERROR] [MY-011300] [Server] Plugin mysqlx reported: 
'Setup of socket: '/home/path-to-shannon-bin/tmp/mysqlx.sock' failed, 
can't create lock file /home/path-to-shannon-bin/tmp/mysqlx.sock.lock'
```

## Root Cause

The MySQL X Protocol plugin (mysqlx) is trying to create a socket in a non-existent directory. The path `/home/path-to-shannon-bin/tmp/` is a **placeholder** that wasn't replaced with the actual ShannonBase path during setup.

## Current Configuration

```sql
mysql> SHOW VARIABLES LIKE '%mysqlx%socket%';
+---------------+-----------------------------------------------+
| Variable_name | Value                                         |
+---------------+-----------------------------------------------+
| mysqlx_socket | /home/path-to-shannon-bin/tmp/mysqlx.sock   |
+---------------+-----------------------------------------------+
```

## Solutions

### Solution 1: Disable MySQL X Plugin (Recommended if not needed)

Add to `/home/wuy/DB/ShannonBase/db/my.cnf`:

```ini
[mysqld]
basedir=/home/wuy/DB/ShannonBase/cmake_build
datadir=/home/wuy/DB/ShannonBase/db/data
port=3307
socket=/tmp/mysql.sock

# Disable MySQL X Plugin
mysqlx=0
```

Then restart MySQL:
```bash
# Stop MySQL
mysql -h 127.0.0.1 -P 3307 -u root -pshannonbase -e "SHUTDOWN"

# Or kill the process
pkill -f "mysqld.*my.cnf"

# Restart with updated config
cd /home/wuy/DB/ShannonBase/cmake_build
./bin/mysqld --defaults-file=../db/my.cnf &
```

### Solution 2: Fix the Socket Path

Add to `/home/wuy/DB/ShannonBase/db/my.cnf`:

```ini
[mysqld]
basedir=/home/wuy/DB/ShannonBase/cmake_build
datadir=/home/wuy/DB/ShannonBase/db/data
port=3307
socket=/tmp/mysql.sock

# Fix MySQL X Plugin socket path
mysqlx_socket=/tmp/mysqlx.sock
mysqlx_port=33060
```

Then restart MySQL (same as above).

### Solution 3: Create the Missing Directory (Not Recommended)

```bash
# Create the placeholder directory
sudo mkdir -p /home/path-to-shannon-bin/tmp
sudo chmod 777 /home/path-to-shannon-bin/tmp
```

This works but creates a weird directory structure.

### Solution 4: Runtime Fix (Temporary)

```sql
-- Set the socket path at runtime (lost on restart)
SET GLOBAL mysqlx_socket='/tmp/mysqlx.sock';
```

Note: This may not work if the plugin is already initialized.

## Verification

After applying the fix and restarting:

```bash
# Check if error persists
tail -f /home/wuy/DB/ShannonBase/db/data/*.err

# Verify socket configuration
mysql -h 127.0.0.1 -P 3307 -u root -pshannonbase -e "
SHOW VARIABLES LIKE '%mysqlx%';
"

# Check if MySQL X is disabled
mysql -h 127.0.0.1 -P 3307 -u root -pshannonbase -e "
SHOW PLUGINS LIKE 'mysqlx';
"
```

## Why This Happens

1. **Build Configuration**: During ShannonBase compilation, a placeholder path wasn't replaced
2. **Default Settings**: MySQL X Plugin is enabled by default in MySQL 8.0+
3. **Template Issue**: The build process uses template configuration that contains placeholders

## Impact

### What's Affected
- MySQL X Protocol connections (port 33060 by default)
- MySQL Shell using X Protocol
- Document store features

### What's NOT Affected
- Regular MySQL connections (port 3307)
- Normal SQL queries
- Your current work

## Do You Need MySQL X Plugin?

**You probably DON'T need it if:**
- You only use traditional SQL
- You connect via standard MySQL protocol (port 3307)
- You don't use MySQL Shell's advanced features
- You don't use document store

**You DO need it if:**
- You use MySQL Shell with X Protocol
- You use MySQL as a document store
- You have applications using X DevAPI

## Quick Fix Commands

```bash
# Option 1: Disable MySQL X (if not needed)
echo "mysqlx=0" >> /home/wuy/DB/ShannonBase/db/my.cnf

# Option 2: Fix socket path
echo "mysqlx_socket=/tmp/mysqlx.sock" >> /home/wuy/DB/ShannonBase/db/my.cnf

# Restart MySQL
mysql -h 127.0.0.1 -P 3307 -u root -pshannonbase -e "SHUTDOWN"
sleep 2
cd /home/wuy/DB/ShannonBase/cmake_build
./bin/mysqld --defaults-file=../db/my.cnf &

# Verify
sleep 5
mysql -h 127.0.0.1 -P 3307 -u root -pshannonbase -e "SELECT 'MySQL restarted successfully'"
```

## Permanent Fix in Build

To fix this permanently for future builds:

1. Find the template configuration file:
```bash
grep -r "path-to-shannon-bin" /home/wuy/DB/ShannonBase/
```

2. Update the placeholder with actual path or use standard paths like `/tmp/`

3. Rebuild ShannonBase

## Summary

| Solution | Effort | Impact | Recommended |
|----------|--------|--------|-------------|
| Disable MySQL X | Low | No X Protocol | ✅ If not using X Protocol |
| Fix Socket Path | Low | X Protocol works | ✅ If using X Protocol |
| Create Directory | Low | Weird structure | ❌ Not clean |
| Runtime Fix | Low | Temporary only | ❌ Lost on restart |

**Most users should use Solution 1 or 2.**

---

**Issue**: MySQL X Plugin socket error  
**Status**: Fixable with config change  
**Impact**: Error messages only, doesn't affect normal MySQL operations  
**Date**: 2024
