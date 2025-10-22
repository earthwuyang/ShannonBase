# MySQL Crash Debug Summary

## Crash Location

**File:** `storage/innobase/os/os0file.cc`  
**Line:** 2891  
**Assertion:** `ut_a(dir_fd != -1);`  
**Function:** `os_parent_dir_fsync_posix()`

## When It Crashes

1. **During `DROP DATABASE`** - When trying to delete database directories
2. **During MySQL startup** - During XA crash recovery  
3. **During file operations** - When InnoDB tries to fsync parent directories

## The Problematic Code

```cpp
/** fsync the parent directory of a path. Useful following rename, unlink, etc..
@param[in]      path            path of file */
static void os_parent_dir_fsync_posix(const char *path) {
  ut_a(path[0] != '\0');

  auto parent_in_path = os_file_get_parent_dir(path);
  const char *parent_dir = parent_in_path;
  if (parent_in_path == nullptr) {
    /** if there is no parent dir in the path, then the real parent is
    either the current directory, or the root directory */
    if (path[0] == '/') {
      parent_dir = "/";
    } else {
      parent_dir = ".";
    }
  }

  /* Open the parent directory */
  auto dir_fd = ::open(parent_dir, O_RDONLY);

  ut_a(dir_fd != -1);  // ❌ LINE 2891 - CRASHES HERE
  
  // ... rest of function
}
```

## Root Cause

The `::open(parent_dir, O_RDONLY)` call fails (returns -1) when:

1. **Directory doesn't exist** - Parent directory was already deleted
2. **Permission denied** - No access to parent directory  
3. **Path is invalid** - Extracted parent path is malformed
4. **Race condition** - Directory deleted between check and open

**errno value would tell us why**, but the code just asserts instead of handling the error.

## Crash Triggers Observed

### Trigger 1: DROP DATABASE Airline
```sql
DROP DATABASE IF EXISTS Airline;
```
- Tries to delete database directory
- Calls `os_parent_dir_fsync_posix()` to fsync parent
- Parent directory open fails
- **Crash**

### Trigger 2: MySQL Startup with Crash Recovery
```
2025-10-22T06:59:04.348872Z 0 [System] [MY-010229] [Server] Starting XA crash recovery...
2025-10-22T06:59:04.515903Z 0 [ERROR] [MY-013183] [InnoDB] Assertion failure: os0file.cc:2891:dir_fd != -1
```
- During XA recovery, tries to clean up temporary files
- Calls `os_parent_dir_fsync_posix()`
- Parent directory open fails  
- **Crash** - MySQL won't start!

## Why `open()` Fails

Likely reasons in this environment:

1. **Docker/Container filesystem** - May have special restrictions
2. **Path with spaces/special characters** - Not properly escaped
3. **Deleted parent directory** - Race condition during cleanup
4. **Insufficient permissions** - Container user lacks access

## Recommended Fix

Replace the assertion with proper error handling:

```cpp
/* Open the parent directory */
auto dir_fd = ::open(parent_dir, O_RDONLY);

if (dir_fd == -1) {
  // Log warning instead of crashing
  ib::warn(ER_IB_MSG_xxx) 
    << "Cannot open parent directory '" << parent_dir 
    << "' for fsync: " << strerror(errno)
    << ". Skipping directory fsync.";
  
  if (parent_in_path != nullptr) {
    ut::free(parent_in_path);
  }
  return;  // ✅ Gracefully handle error
}

// Continue with fsync...
```

## Workaround (Temporary)

Until the code is fixed, avoid operations that trigger parent directory fsync:

1. **Don't drop databases** - Use `DELETE FROM table` instead
2. **Clean shutdown** - Avoid crashes that trigger XA recovery
3. **Manual cleanup** - Stop MySQL, manually delete database dirs, restart

## Testing the Fix

After applying the fix:

```bash
# Should not crash
mysql -e "DROP DATABASE IF EXISTS test_db;"

# Should start successfully after crash
./start_mysql.sh
```

## Related Code

- `os_file_get_parent_dir()` - Extracts parent directory path
- `os_parent_dir_fsync_posix()` - Fsyncs parent directory (CRASHES HERE)
- Called by: file deletion, rename, database drop operations

## Debug Information

To get more details, need to check errno:

```cpp
auto dir_fd = ::open(parent_dir, O_RDONLY);
if (dir_fd == -1) {
  int err = errno;
  ib::error() << "open(" << parent_dir << ") failed with errno=" << err 
              << " (" << strerror(err) << ")";
}
```

Common errno values:
- `ENOENT (2)` - Directory doesn't exist
- `EACCES (13)` - Permission denied
- `ENOTDIR (20)` - Not a directory

## Date

2025-10-22
