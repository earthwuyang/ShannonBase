-- Copyright (c) 2014, 2024, Oracle and/or its affiliates.
--
-- This program is free software; you can redistribute it and/or modify
-- it under the terms of the GNU General Public License as published by
-- the Free Software Foundation; version 2 of the License.
--
-- This program is distributed in the hope that it will be useful,
-- but WITHOUT ANY WARRANTY; without even the implied warranty of
-- MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
-- GNU General Public License for more details.
--
-- You should have received a copy of the GNU General Public License
-- along with this program; if not, write to the Free Software
-- Foundation, Inc., 51 Franklin St, Fifth Floor, Boston, MA 02110-1301 USA

SET NAMES utf8mb4;
SET @sql_log_bin = @@sql_log_bin;
SET sql_log_bin = 0;

CREATE DATABASE IF NOT EXISTS sys DEFAULT CHARACTER SET utf8mb4;

ALTER DATABASE sys CHARACTER SET utf8mb4;

USE sys;
-- Copyright (c) 2014, 2024, Oracle and/or its affiliates.
--
-- This program is free software; you can redistribute it and/or modify
-- it under the terms of the GNU General Public License as published by
-- the Free Software Foundation; version 2 of the License.
--
-- This program is distributed in the hope that it will be useful,
-- but WITHOUT ANY WARRANTY; without even the implied warranty of
-- MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
-- GNU General Public License for more details.
--
-- You should have received a copy of the GNU General Public License
-- along with this program; if not, write to the Free Software
-- Foundation, Inc., 51 Franklin St, Fifth Floor, Boston, MA 02110-1301 USA

INSERT IGNORE INTO mysql.user VALUES
('localhost','mysql.sys','N','N','N','N','N','N','N','N','N','N','N','N','N','N','N','N','N','N','N','N','N','N','N','N','N','N','N','N','N','','','','',0,0,0,0,'caching_sha2_password','\$A\$005\$THISISACOMBINATIONOFINVALIDSALTANDPASSWORDTHATMUSTNEVERBRBEUSED','N',CURRENT_TIMESTAMP,NULL,'Y','N','N',NULL,NULL,NULL,NULL);

INSERT IGNORE INTO mysql.db VALUES
('localhost','sys','mysql.sys','N','N','N','N','N','N','N','N','N','N','N','N','N','N','N','N','N','N','Y');

INSERT IGNORE INTO mysql.tables_priv VALUES
('localhost','sys','mysql.sys','sys_config','root@localhost',
CURRENT_TIMESTAMP, 'Select', '');

-- GRANT SYSTEM_USER ON *.* TO 'mysql.sys'@localhost
INSERT IGNORE INTO mysql.global_grants (USER,HOST,PRIV,WITH_GRANT_OPTION)
VALUES ('mysql.sys','localhost','SYSTEM_USER','N');

-- GRANT AUDIT_ABORT_EXEMPT ON *.* TO 'mysql.sys'@localhost
INSERT IGNORE INTO mysql.global_grants (USER,HOST,PRIV,WITH_GRANT_OPTION)
VALUES ('mysql.sys','localhost','AUDIT_ABORT_EXEMPT','N');

-- GRANT FIREWALL_EXEMPT ON *.* TO 'mysql.sys'@localhost
INSERT IGNORE INTO mysql.global_grants (USER,HOST,PRIV,WITH_GRANT_OPTION)
VALUES ('mysql.sys','localhost','FIREWALL_EXEMPT','N');
-- Copyright (c) 2014, 2024, Oracle and/or its affiliates.
--
-- This program is free software; you can redistribute it and/or modify
-- it under the terms of the GNU General Public License as published by
-- the Free Software Foundation; version 2 of the License.
--
-- This program is designed to work with certain software (including
-- but not limited to OpenSSL) that is licensed under separate terms,
-- as designated in a particular file or component or in included license
-- documentation.  The authors of MySQL hereby grant you an additional
-- permission to link the program and your derivative works with the
-- separately licensed software that they have either included with
-- the program or referenced in the documentation.
--
-- This program is distributed in the hope that it will be useful,
-- but WITHOUT ANY WARRANTY; without even the implied warranty of
-- MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
-- GNU General Public License for more details.
--
-- You should have received a copy of the GNU General Public License
-- along with this program; if not, write to the Free Software
-- Foundation, Inc., 51 Franklin St, Fifth Floor, Boston, MA 02110-1301 USA

--
-- View: version
--
-- Shows the sys schema and mysql versions
--
-- NOTE: This view is deprecated and will be removed in a future release.
--
-- mysql> select * from sys.version;
-- +-------------+---------------+
-- | sys_version | mysql_version |
-- +-------------+---------------+
-- | 2.1.2       | 8.0.28        |
-- +-------------+---------------+
-- 

CREATE OR REPLACE
  DEFINER = 'mysql.sys'@'localhost'
  SQL SECURITY INVOKER 
VIEW version (
  sys_version,
  mysql_version
) AS 
SELECT '2.1.3' AS sys_version,
        version() AS mysql_version;
-- Copyright (c) 2014, 2024, Oracle and/or its affiliates.
--
-- This program is free software; you can redistribute it and/or modify
-- it under the terms of the GNU General Public License as published by
-- the Free Software Foundation; version 2 of the License.
--
-- This program is distributed in the hope that it will be useful,
-- but WITHOUT ANY WARRANTY; without even the implied warranty of
-- MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
-- GNU General Public License for more details.
--
-- You should have received a copy of the GNU General Public License
-- along with this program; if not, write to the Free Software
-- Foundation, Inc., 51 Franklin St, Fifth Floor, Boston, MA 02110-1301 USA

--
-- Table: sys_config
--
-- Stores configuration options for sys objects
--

CREATE TABLE IF NOT EXISTS sys_config (
    variable VARCHAR(128) PRIMARY KEY,
    value VARCHAR(128),
    set_time TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    set_by VARCHAR(128)
) ENGINE = InnoDB;
-- Copyright (c) 2018, 2024, Oracle and/or its affiliates.
--
-- This program is free software; you can redistribute it and/or modify
-- it under the terms of the GNU General Public License as published by
-- the Free Software Foundation; version 2 of the License.
--
-- This program is distributed in the hope that it will be useful,
-- but WITHOUT ANY WARRANTY; without even the implied warranty of
-- MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
-- GNU General Public License for more details.
--
-- You should have received a copy of the GNU General Public License
-- along with this program; if not, write to the Free Software
-- Foundation, Inc., 51 Franklin St, Fifth Floor, Boston, MA 02110-1301 USA

--
-- Alters the sys_config table for upgrades
--

ALTER TABLE sys_config CHARACTER SET utf8mb4;
-- Copyright (c) 2015, 2024, Oracle and/or its affiliates.
--
-- This program is free software; you can redistribute it and/or modify
-- it under the terms of the GNU General Public License as published by
-- the Free Software Foundation; version 2 of the License.
--
-- This program is distributed in the hope that it will be useful,
-- but WITHOUT ANY WARRANTY; without even the implied warranty of
-- MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
-- GNU General Public License for more details.
--
-- You should have received a copy of the GNU General Public License
-- along with this program; if not, write to the Free Software
-- Foundation, Inc., 51 Franklin St, Fifth Floor, Boston, MA 02110-1301 USA

-- NOTE: This needs to be replicated within the sys_config_clean.inc file

INSERT IGNORE INTO sys.sys_config (variable, value) VALUES
    ('statement_truncate_len', 64),
    ('statement_performance_analyzer.limit', 100),
    ('statement_performance_analyzer.view', NULL),
    ('diagnostics.allow_i_s_tables', 'OFF'),
    ('diagnostics.include_raw', 'OFF'),
    ('ps_thread_trx_info.max_length', 65535);
-- Copyright (c) 2014, 2024, Oracle and/or its affiliates.
--
-- This program is free software; you can redistribute it and/or modify
-- it under the terms of the GNU General Public License as published by
-- the Free Software Foundation; version 2 of the License.
--
-- This program is distributed in the hope that it will be useful,
-- but WITHOUT ANY WARRANTY; without even the implied warranty of
-- MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
-- GNU General Public License for more details.
--
-- You should have received a copy of the GNU General Public License
-- along with this program; if not, write to the Free Software
-- Foundation, Inc., 51 Franklin St, Fifth Floor, Boston, MA 02110-1301 USA

--
-- Trigger: sys_config_insert_set_user
--
-- Sets the user that inserts configuration
--
--

DROP TRIGGER IF EXISTS sys_config_insert_set_user;

DELIMITER $$

CREATE DEFINER='mysql.sys'@'localhost' TRIGGER sys_config_insert_set_user BEFORE INSERT on sys_config
    FOR EACH ROW
BEGIN
    IF @sys.ignore_sys_config_triggers != true AND NEW.set_by IS NULL THEN
        SET NEW.set_by = USER();
    END IF;
END$$

DELIMITER ;
-- Copyright (c) 2014, 2024, Oracle and/or its affiliates.
--
-- This program is free software; you can redistribute it and/or modify
-- it under the terms of the GNU General Public License as published by
-- the Free Software Foundation; version 2 of the License.
--
-- This program is distributed in the hope that it will be useful,
-- but WITHOUT ANY WARRANTY; without even the implied warranty of
-- MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
-- GNU General Public License for more details.
--
-- You should have received a copy of the GNU General Public License
-- along with this program; if not, write to the Free Software
-- Foundation, Inc., 51 Franklin St, Fifth Floor, Boston, MA 02110-1301 USA

--
-- Trigger: sys_config_update_set_user
--
-- Sets the user that updates configuration
--
--


DROP TRIGGER IF EXISTS sys_config_update_set_user;

DELIMITER $$

CREATE DEFINER='mysql.sys'@'localhost' TRIGGER sys_config_update_set_user BEFORE UPDATE on sys_config
    FOR EACH ROW
BEGIN
    IF @sys.ignore_sys_config_triggers != true AND NEW.set_by IS NULL THEN
        SET NEW.set_by = USER();
    END IF;
END$$

DELIMITER ;
-- Copyright (c) 2014, 2024, Oracle and/or its affiliates.
--
-- This program is free software; you can redistribute it and/or modify
-- it under the terms of the GNU General Public License as published by
-- the Free Software Foundation; version 2 of the License.
--
-- This program is distributed in the hope that it will be useful,
-- but WITHOUT ANY WARRANTY; without even the implied warranty of
-- MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
-- GNU General Public License for more details.
--
-- You should have received a copy of the GNU General Public License
-- along with this program; if not, write to the Free Software
-- Foundation, Inc., 51 Franklin St, Fifth Floor, Boston, MA 02110-1301 USA

DROP FUNCTION IF EXISTS extract_schema_from_file_name;

DELIMITER $$

CREATE DEFINER='mysql.sys'@'localhost' FUNCTION extract_schema_from_file_name (
        path VARCHAR(512)
    )
    RETURNS VARCHAR(64) 
    COMMENT '
Description
-----------

Takes a raw file path, and attempts to extract the schema name from it.

Useful for when interacting with Performance Schema data 
concerning IO statistics, for example.

Currently relies on the fact that a table data file will be within a 
specified database directory (will not work with partitions or tables
that specify an individual DATA_DIRECTORY).

Parameters
-----------

path (VARCHAR(512)):
  The full file path to a data file to extract the schema name from.

Returns
-----------

VARCHAR(64)

Example
-----------

mysql> SELECT sys.extract_schema_from_file_name(\'/var/lib/mysql/employees/employee.ibd\');
+----------------------------------------------------------------------------+
| sys.extract_schema_from_file_name(\'/var/lib/mysql/employees/employee.ibd\') |
+----------------------------------------------------------------------------+
| employees                                                                  |
+----------------------------------------------------------------------------+
1 row in set (0.00 sec)
'
    SQL SECURITY INVOKER
    DETERMINISTIC
    NO SQL
BEGIN
    RETURN LEFT(SUBSTRING_INDEX(SUBSTRING_INDEX(REPLACE(path, '\\', '/'), '/', -2), '/', 1), 64);
END$$

DELIMITER ;
-- Copyright (c) 2014, 2024, Oracle and/or its affiliates.
--
-- This program is free software; you can redistribute it and/or modify
-- it under the terms of the GNU General Public License as published by
-- the Free Software Foundation; version 2 of the License.
--
-- This program is distributed in the hope that it will be useful,
-- but WITHOUT ANY WARRANTY; without even the implied warranty of
-- MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
-- GNU General Public License for more details.
--
-- You should have received a copy of the GNU General Public License
-- along with this program; if not, write to the Free Software
-- Foundation, Inc., 51 Franklin St, Fifth Floor, Boston, MA 02110-1301 USA

DROP FUNCTION IF EXISTS extract_table_from_file_name;

DELIMITER $$

CREATE DEFINER='mysql.sys'@'localhost' FUNCTION extract_table_from_file_name (
        path VARCHAR(512)
    )
    RETURNS VARCHAR(64) 
    COMMENT '
Description
-----------

Takes a raw file path, and extracts the table name from it.

Useful for when interacting with Performance Schema data 
concerning IO statistics, for example.

Parameters
-----------

path (VARCHAR(512)):
  The full file path to a data file to extract the table name from.

Returns
-----------

VARCHAR(64)

Example
-----------

mysql> SELECT sys.extract_table_from_file_name(\'/var/lib/mysql/employees/employee.ibd\');
+---------------------------------------------------------------------------+
| sys.extract_table_from_file_name(\'/var/lib/mysql/employees/employee.ibd\') |
+---------------------------------------------------------------------------+
| employee                                                                  |
+---------------------------------------------------------------------------+
1 row in set (0.02 sec)
'
    SQL SECURITY INVOKER
    DETERMINISTIC
    NO SQL
BEGIN
    RETURN LEFT(SUBSTRING_INDEX(REPLACE(SUBSTRING_INDEX(REPLACE(path, '\\', '/'), '/', -1), '@0024', '$'), '.', 1), 64);
END$$

DELIMITER ;
-- Copyright (c) 2014, 2024, Oracle and/or its affiliates.
--
-- This program is free software; you can redistribute it and/or modify
-- it under the terms of the GNU General Public License as published by
-- the Free Software Foundation; version 2 of the License.
--
-- This program is distributed in the hope that it will be useful,
-- but WITHOUT ANY WARRANTY; without even the implied warranty of
-- MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
-- GNU General Public License for more details.
--
-- You should have received a copy of the GNU General Public License
-- along with this program; if not, write to the Free Software
-- Foundation, Inc., 51 Franklin St, Fifth Floor, Boston, MA 02110-1301 USA

DROP FUNCTION IF EXISTS sys.format_bytes;

DELIMITER $$

CREATE DEFINER='mysql.sys'@'localhost' FUNCTION sys.format_bytes (
        -- We feed in and return TEXT here, as aggregates of
        -- bytes can return numbers larger than BIGINT UNSIGNED
        bytes TEXT
    )
    RETURNS TEXT
    COMMENT '
Description
-----------

Takes a raw bytes value, and converts it to a human readable format.

Parameters
-----------

bytes (TEXT):
  A raw bytes value.

Returns
-----------

TEXT

Example
-----------

mysql> SELECT sys.format_bytes(2348723492723746) AS size;
+----------+
| size     |
+----------+
| 2.09 PiB |
+----------+
1 row in set (0.00 sec)

mysql> SELECT sys.format_bytes(2348723492723) AS size;
+----------+
| size     |
+----------+
| 2.14 TiB |
+----------+
1 row in set (0.00 sec)

mysql> SELECT sys.format_bytes(23487234) AS size;
+-----------+
| size      |
+-----------+
| 22.40 MiB |
+-----------+
1 row in set (0.00 sec)
'
    SQL SECURITY INVOKER
    DETERMINISTIC
    NO SQL
BEGIN
  IF (bytes IS NULL) THEN
    RETURN NULL;
  ELSE
    RETURN format_bytes(bytes);
  END IF;
END$$

DELIMITER ;
-- Copyright (c) 2014, 2024, Oracle and/or its affiliates.
--
-- This program is free software; you can redistribute it and/or modify
-- it under the terms of the GNU General Public License as published by
-- the Free Software Foundation; version 2 of the License.
--
-- This program is distributed in the hope that it will be useful,
-- but WITHOUT ANY WARRANTY; without even the implied warranty of
-- MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
-- GNU General Public License for more details.
--
-- You should have received a copy of the GNU General Public License
-- along with this program; if not, write to the Free Software
-- Foundation, Inc., 51 Franklin St, Fifth Floor, Boston, MA 02110-1301 USA

DROP FUNCTION IF EXISTS format_path;

DELIMITER $$

CREATE DEFINER='mysql.sys'@'localhost' FUNCTION format_path (
        in_path VARCHAR(512)
    )
    RETURNS VARCHAR(512) CHARSET UTF8MB4
    COMMENT '
Description
-----------

Takes a raw path value, and strips out the datadir or tmpdir
replacing with @@datadir and @@tmpdir respectively.

Also normalizes the paths across operating systems, so backslashes
on Windows are converted to forward slashes

Parameters
-----------

path (VARCHAR(512)):
  The raw file path value to format.

Returns
-----------

VARCHAR(512) CHARSET UTF8MB4

Example
-----------

mysql> select @@datadir;
+-----------------------------------------------+
| @@datadir                                     |
+-----------------------------------------------+
| /Users/mark/sandboxes/SmallTree/AMaster/data/ |
+-----------------------------------------------+
1 row in set (0.06 sec)

mysql> select format_path(\'/Users/mark/sandboxes/SmallTree/AMaster/data/mysql/proc.MYD\') AS path;
+--------------------------+
| path                     |
+--------------------------+
| @@datadir/mysql/proc.MYD |
+--------------------------+
1 row in set (0.03 sec)
'
    SQL SECURITY INVOKER
    DETERMINISTIC
    NO SQL
BEGIN
  DECLARE v_path VARCHAR(512);
  DECLARE v_undo_dir VARCHAR(1024);

  DECLARE path_separator CHAR(1) DEFAULT '/';

  IF @@global.version_compile_os LIKE 'win%' THEN
    SET path_separator = '\\';
  END IF;

  -- OSX hides /private/ in variables, but Performance Schema does not
  IF in_path LIKE '/private/%' THEN
    SET v_path = REPLACE(in_path, '/private', '');
  ELSE
    SET v_path = in_path;
  END IF;

  -- @@global.innodb_undo_directory is only set when separate undo logs are used
  SET v_undo_dir = IFNULL((SELECT VARIABLE_VALUE FROM performance_schema.global_variables WHERE VARIABLE_NAME = 'innodb_undo_directory'), '');

  IF v_path IS NULL THEN
    RETURN NULL;
  ELSEIF v_path LIKE CONCAT(@@global.datadir, IF(SUBSTRING(@@global.datadir, -1) = path_separator, '%', CONCAT(path_separator, '%'))) ESCAPE '|' THEN
    SET v_path = REPLACE(v_path, @@global.datadir, CONCAT('@@datadir', IF(SUBSTRING(@@global.datadir, -1) = path_separator, path_separator, '')));
  ELSEIF v_path LIKE CONCAT(@@global.tmpdir, IF(SUBSTRING(@@global.tmpdir, -1) = path_separator, '%', CONCAT(path_separator, '%'))) ESCAPE '|' THEN
    SET v_path = REPLACE(v_path, @@global.tmpdir, CONCAT('@@tmpdir', IF(SUBSTRING(@@global.tmpdir, -1) = path_separator, path_separator, '')));
  ELSEIF v_path LIKE CONCAT(@@global.replica_load_tmpdir, IF(SUBSTRING(@@global.replica_load_tmpdir, -1) = path_separator, '%', CONCAT(path_separator, '%'))) ESCAPE '|' THEN
    SET v_path = REPLACE(v_path, @@global.replica_load_tmpdir, CONCAT('@@replica_load_tmpdir', IF(SUBSTRING(@@global.replica_load_tmpdir, -1) = path_separator, path_separator, '')));
  ELSEIF v_path LIKE CONCAT(@@global.innodb_data_home_dir, IF(SUBSTRING(@@global.innodb_data_home_dir, -1) = path_separator, '%', CONCAT(path_separator, '%'))) ESCAPE '|' THEN
    SET v_path = REPLACE(v_path, @@global.innodb_data_home_dir, CONCAT('@@innodb_data_home_dir', IF(SUBSTRING(@@global.innodb_data_home_dir, -1) = path_separator, path_separator, '')));
  ELSEIF v_path LIKE CONCAT(@@global.innodb_log_group_home_dir, IF(SUBSTRING(@@global.innodb_log_group_home_dir, -1) = path_separator, '%', CONCAT(path_separator, '%'))) ESCAPE '|' THEN
    SET v_path = REPLACE(v_path, @@global.innodb_log_group_home_dir, CONCAT('@@innodb_log_group_home_dir', IF(SUBSTRING(@@global.innodb_log_group_home_dir, -1) = path_separator, path_separator, '')));
  ELSEIF v_path LIKE CONCAT(v_undo_dir, IF(SUBSTRING(v_undo_dir, -1) = path_separator, '%', CONCAT(path_separator, '%'))) ESCAPE '|' THEN
    SET v_path = REPLACE(v_path, v_undo_dir, CONCAT('@@innodb_undo_directory', IF(SUBSTRING(v_undo_dir, -1) = path_separator, path_separator, '')));
  ELSEIF v_path LIKE CONCAT(@@global.basedir, IF(SUBSTRING(@@global.basedir, -1) = path_separator, '%', CONCAT(path_separator, '%'))) ESCAPE '|' THEN
    SET v_path = REPLACE(v_path, @@global.basedir, CONCAT('@@basedir', IF(SUBSTRING(@@global.basedir, -1) = path_separator, path_separator, '')));
  END IF;

  RETURN v_path;
END$$

DELIMITER ;
-- Copyright (c) 2014, 2024, Oracle and/or its affiliates.
--
-- This program is free software; you can redistribute it and/or modify
-- it under the terms of the GNU General Public License as published by
-- the Free Software Foundation; version 2 of the License.
--
-- This program is distributed in the hope that it will be useful,
-- but WITHOUT ANY WARRANTY; without even the implied warranty of
-- MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
-- GNU General Public License for more details.
--
-- You should have received a copy of the GNU General Public License
-- along with this program; if not, write to the Free Software
-- Foundation, Inc., 51 Franklin St, Fifth Floor, Boston, MA 02110-1301 USA

DROP FUNCTION IF EXISTS format_statement;

DELIMITER $$

CREATE DEFINER='mysql.sys'@'localhost' FUNCTION format_statement (
        statement LONGTEXT
    )
    RETURNS LONGTEXT
    COMMENT '
Description
-----------

Formats a normalized statement, truncating it if it is > 64 characters long by default.

To configure the length to truncate the statement to by default, update the `statement_truncate_len`
variable with `sys_config` table to a different value. Alternatively, to change it just for just 
your particular session, use `SET @sys.statement_truncate_len := <some new value>`.

Useful for printing statement related data from Performance Schema from 
the command line.

Parameters
-----------

statement (LONGTEXT): 
  The statement to format.

Returns
-----------

LONGTEXT

Example
-----------

mysql> SELECT sys.format_statement(digest_text)
    ->   FROM performance_schema.events_statements_summary_by_digest
    ->  ORDER by sum_timer_wait DESC limit 5;
+-------------------------------------------------------------------+
| sys.format_statement(digest_text)                                 |
+-------------------------------------------------------------------+
| CREATE SQL SECURITY INVOKER VI ... KE ? AND `variable_value` > ?  |
| CREATE SQL SECURITY INVOKER VI ... ait` IS NOT NULL , `esc` . ... |
| CREATE SQL SECURITY INVOKER VI ... ait` IS NOT NULL , `sys` . ... |
| CREATE SQL SECURITY INVOKER VI ...  , `compressed_size` ) ) DESC  |
| CREATE SQL SECURITY INVOKER VI ... LIKE ? ORDER BY `timer_start`  |
+-------------------------------------------------------------------+
5 rows in set (0.00 sec)
'
    SQL SECURITY INVOKER
    DETERMINISTIC
    NO SQL
BEGIN
  -- Check if we have the configured length, if not, init it
  IF @sys.statement_truncate_len IS NULL THEN
      SET @sys.statement_truncate_len = sys_get_config('statement_truncate_len', 64);
  END IF;

  IF CHAR_LENGTH(statement) > @sys.statement_truncate_len THEN
      RETURN REPLACE(CONCAT(LEFT(statement, (@sys.statement_truncate_len/2)-2), ' ... ', RIGHT(statement, (@sys.statement_truncate_len/2)-2)), '\n', ' ');
  ELSE 
      RETURN REPLACE(statement, '\n', ' ');
  END IF;
END$$

DELIMITER ;
-- Copyright (c) 2014, 2024, Oracle and/or its affiliates.
--
-- This program is free software; you can redistribute it and/or modify
-- it under the terms of the GNU General Public License as published by
-- the Free Software Foundation; version 2 of the License.
--
-- This program is distributed in the hope that it will be useful,
-- but WITHOUT ANY WARRANTY; without even the implied warranty of
-- MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
-- GNU General Public License for more details.
--
-- You should have received a copy of the GNU General Public License
-- along with this program; if not, write to the Free Software
-- Foundation, Inc., 51 Franklin St, Fifth Floor, Boston, MA 02110-1301 USA

DROP FUNCTION IF EXISTS sys.format_time;

DELIMITER $$

CREATE DEFINER='mysql.sys'@'localhost' FUNCTION sys.format_time (
-- We feed in and return TEXT here, as aggregates of
-- picoseconds can return numbers larger than BIGINT UNSIGNED
        picoseconds TEXT
    )
    RETURNS TEXT CHARSET UTF8MB4
    COMMENT '
Description
-----------

Takes a raw picoseconds value, and converts it to a human readable form.

Picoseconds are the precision that all latency values are printed in
within Performance Schema, however are not user friendly when wanting
to scan output from the command line.

Parameters
-----------

picoseconds (TEXT):
  The raw picoseconds value to convert.

Returns
-----------

TEXT CHARSET UTF8MB4

Example
-----------

mysql> select format_time(342342342342345);
+------------------------------+
| format_time(342342342342345) |
+------------------------------+
| 00:05:42                     |
+------------------------------+
1 row in set (0.00 sec)

mysql> select format_time(342342342);
+------------------------+
| format_time(342342342) |
+------------------------+
| 342.34 us              |
+------------------------+
1 row in set (0.00 sec)

mysql> select format_time(34234);
+--------------------+
| format_time(34234) |
+--------------------+
| 34.23 ns           |
+--------------------+
1 row in set (0.00 sec)
'
    SQL SECURITY INVOKER
    DETERMINISTIC
    NO SQL
BEGIN
  IF picoseconds IS NULL THEN RETURN NULL;
  ELSEIF picoseconds >= 604800000000000000 THEN RETURN CONCAT(ROUND(picoseconds / 604800000000000000, 2), ' w');
  ELSEIF picoseconds >= 86400000000000000 THEN RETURN CONCAT(ROUND(picoseconds / 86400000000000000, 2), ' d');
  ELSEIF picoseconds >= 3600000000000000 THEN RETURN CONCAT(ROUND(picoseconds / 3600000000000000, 2), ' h');
  ELSEIF picoseconds >= 60000000000000 THEN RETURN CONCAT(ROUND(picoseconds / 60000000000000, 2), ' m');
  ELSEIF picoseconds >= 1000000000000 THEN RETURN CONCAT(ROUND(picoseconds / 1000000000000, 2), ' s');
  ELSEIF picoseconds >= 1000000000 THEN RETURN CONCAT(ROUND(picoseconds / 1000000000, 2), ' ms');
  ELSEIF picoseconds >= 1000000 THEN RETURN CONCAT(ROUND(picoseconds / 1000000, 2), ' us');
  ELSEIF picoseconds >= 1000 THEN RETURN CONCAT(ROUND(picoseconds / 1000, 2), ' ns');
  ELSE RETURN CONCAT(picoseconds, ' ps');
  END IF;
END$$

DELIMITER ;
-- Copyright (c) 2015, 2024, Oracle and/or its affiliates.
--
-- This program is free software; you can redistribute it and/or modify
-- it under the terms of the GNU General Public License as published by
-- the Free Software Foundation; version 2 of the License.
--
-- This program is distributed in the hope that it will be useful,
-- but WITHOUT ANY WARRANTY; without even the implied warranty of
-- MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
-- GNU General Public License for more details.
--
-- You should have received a copy of the GNU General Public License
-- along with this program; if not, write to the Free Software
-- Foundation, Inc., 51 Franklin St, Fifth Floor, Boston, MA 02110-1301 USA

DROP FUNCTION IF EXISTS list_add;

DELIMITER $$

CREATE DEFINER='mysql.sys'@'localhost' FUNCTION list_add (
        in_list TEXT,
        in_add_value TEXT
    )
    RETURNS TEXT
    COMMENT '
Description
-----------

Takes a list, and a value to add to the list, and returns the resulting list.

Useful for altering certain session variables, like sql_mode or optimizer_switch for instance.

Parameters
-----------

in_list (TEXT):
  The comma separated list to add a value to

in_add_value (TEXT):
  The value to add to the input list

Returns
-----------

TEXT

Example
--------

mysql> select @@sql_mode;
+-----------------------------------------------------------------------------------+
| @@sql_mode                                                                        |
+-----------------------------------------------------------------------------------+
| ONLY_FULL_GROUP_BY,STRICT_TRANS_TABLES,NO_AUTO_CREATE_USER,NO_ENGINE_SUBSTITUTION |
+-----------------------------------------------------------------------------------+
1 row in set (0.00 sec)

mysql> set sql_mode = sys.list_add(@@sql_mode, ''ANSI_QUOTES'');
Query OK, 0 rows affected (0.06 sec)

mysql> select @@sql_mode;
+-----------------------------------------------------------------------------------------------+
| @@sql_mode                                                                                    |
+-----------------------------------------------------------------------------------------------+
| ANSI_QUOTES,ONLY_FULL_GROUP_BY,STRICT_TRANS_TABLES,NO_AUTO_CREATE_USER,NO_ENGINE_SUBSTITUTION |
+-----------------------------------------------------------------------------------------------+
1 row in set (0.00 sec)

'
    SQL SECURITY INVOKER
    DETERMINISTIC
    CONTAINS SQL
BEGIN

    IF (in_add_value IS NULL) THEN
        SIGNAL SQLSTATE '02200'
           SET MESSAGE_TEXT = 'Function sys.list_add: in_add_value input variable should not be NULL',
               MYSQL_ERRNO = 1138;
    END IF;

    IF (in_list IS NULL OR LENGTH(in_list) = 0) THEN
        -- return the new value as a single value list
        RETURN in_add_value;
    END IF;

    RETURN (SELECT CONCAT(TRIM(BOTH ',' FROM TRIM(in_list)), ',', in_add_value));

END$$

DELIMITER ;
-- Copyright (c) 2015, 2024, Oracle and/or its affiliates.
--
-- This program is free software; you can redistribute it and/or modify
-- it under the terms of the GNU General Public License as published by
-- the Free Software Foundation; version 2 of the License.
--
-- This program is distributed in the hope that it will be useful,
-- but WITHOUT ANY WARRANTY; without even the implied warranty of
-- MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
-- GNU General Public License for more details.
--
-- You should have received a copy of the GNU General Public License
-- along with this program; if not, write to the Free Software
-- Foundation, Inc., 51 Franklin St, Fifth Floor, Boston, MA 02110-1301 USA

DROP FUNCTION IF EXISTS list_drop;

DELIMITER $$

CREATE DEFINER='mysql.sys'@'localhost' FUNCTION list_drop (
        in_list TEXT,
        in_drop_value TEXT
    )
    RETURNS TEXT
    COMMENT '
Description
-----------

Takes a list, and a value to attempt to remove from the list, and returns the resulting list.

Useful for altering certain session variables, like sql_mode or optimizer_switch for instance.

Parameters
-----------

in_list (TEXT):
  The comma separated list to drop a value from

in_drop_value (TEXT):
  The value to drop from the input list

Returns
-----------

TEXT

Example
--------

mysql> select @@sql_mode;
+-----------------------------------------------------------------------------------------------+
| @@sql_mode                                                                                    |
+-----------------------------------------------------------------------------------------------+
| ANSI_QUOTES,ONLY_FULL_GROUP_BY,STRICT_TRANS_TABLES,NO_AUTO_CREATE_USER,NO_ENGINE_SUBSTITUTION |
+-----------------------------------------------------------------------------------------------+
1 row in set (0.00 sec)

mysql> set sql_mode = sys.list_drop(@@sql_mode, ''ONLY_FULL_GROUP_BY'');
Query OK, 0 rows affected (0.03 sec)

mysql> select @@sql_mode;
+----------------------------------------------------------------------------+
| @@sql_mode                                                                 |
+----------------------------------------------------------------------------+
| ANSI_QUOTES,STRICT_TRANS_TABLES,NO_AUTO_CREATE_USER,NO_ENGINE_SUBSTITUTION |
+----------------------------------------------------------------------------+
1 row in set (0.00 sec)

'
    SQL SECURITY INVOKER
    DETERMINISTIC
    CONTAINS SQL
BEGIN

    IF (in_drop_value IS NULL) THEN
        SIGNAL SQLSTATE '02200'
           SET MESSAGE_TEXT = 'Function sys.list_drop: in_drop_value input variable should not be NULL',
               MYSQL_ERRNO = 1138;
    END IF;

    IF (in_list IS NULL OR LENGTH(in_list) = 0) THEN
        -- return the list as it was passed in
        RETURN in_list;
    END IF;

    -- ensure that leading / trailing commas are remove, support values with either spaces or not between commas
    RETURN (SELECT TRIM(BOTH ',' FROM REPLACE(REPLACE(CONCAT(',', in_list), CONCAT(',', in_drop_value), ''), CONCAT(', ', in_drop_value), '')));

END$$

DELIMITER ;
-- Copyright (c) 2014, 2024, Oracle and/or its affiliates.
--
-- This program is free software; you can redistribute it and/or modify
-- it under the terms of the GNU General Public License as published by
-- the Free Software Foundation; version 2 of the License.
--
-- This program is distributed in the hope that it will be useful,
-- but WITHOUT ANY WARRANTY; without even the implied warranty of
-- MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
-- GNU General Public License for more details.
--
-- You should have received a copy of the GNU General Public License
-- along with this program; if not, write to the Free Software
-- Foundation, Inc., 51 Franklin St, Fifth Floor, Boston, MA 02110-1301 USA

DROP FUNCTION IF EXISTS ps_is_account_enabled;

DELIMITER $$

CREATE DEFINER='mysql.sys'@'localhost' FUNCTION ps_is_account_enabled (
        in_host VARCHAR(255), 
        in_user VARCHAR(32)
    ) 
    RETURNS ENUM('YES', 'NO')
    COMMENT '
Description
-----------

Determines whether instrumentation of an account is enabled 
within Performance Schema.

Parameters
-----------

in_host VARCHAR(255): 
  The hostname of the account to check.
in_user VARCHAR(32):
  The username of the account to check.

Returns
-----------

ENUM(\'YES\', \'NO\', \'PARTIAL\')

Example
-----------

mysql> SELECT sys.ps_is_account_enabled(\'localhost\', \'root\');
+------------------------------------------------+
| sys.ps_is_account_enabled(\'localhost\', \'root\') |
+------------------------------------------------+
| YES                                            |
+------------------------------------------------+
1 row in set (0.01 sec)
'
    SQL SECURITY INVOKER
    DETERMINISTIC 
    READS SQL DATA 
BEGIN
    RETURN IF(EXISTS(SELECT 1
                       FROM performance_schema.setup_actors
                      WHERE (`HOST` = '%' OR in_host LIKE `HOST`)
                        AND (`USER` = '%' OR `USER` = in_user)
                        AND (`ENABLED` = 'YES')
                    ),
              'YES', 'NO'
           );
END$$

DELIMITER ;
-- Copyright (c) 2014, 2024, Oracle and/or its affiliates.
--
-- This program is free software; you can redistribute it and/or modify
-- it under the terms of the GNU General Public License as published by
-- the Free Software Foundation; version 2 of the License.
--
-- This program is distributed in the hope that it will be useful,
-- but WITHOUT ANY WARRANTY; without even the implied warranty of
-- MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
-- GNU General Public License for more details.
--
-- You should have received a copy of the GNU General Public License
-- along with this program; if not, write to the Free Software
-- Foundation, Inc., 51 Franklin St, Fifth Floor, Boston, MA 02110-1301 USA

DROP FUNCTION IF EXISTS ps_is_consumer_enabled;

DELIMITER $$

CREATE DEFINER='mysql.sys'@'localhost' FUNCTION ps_is_consumer_enabled (
        in_consumer varchar(64)
   )
   RETURNS enum('YES', 'NO')
    COMMENT '
Description
-----------

Determines whether a consumer is enabled (taking the consumer hierarchy into consideration)
within the Performance Schema.

An exception with errno 3047 is thrown if an unknown consumer name is passed to the function.
A consumer name of NULL returns NULL.

Parameters
-----------

in_consumer VARCHAR(64): 
  The name of the consumer to check.

Returns
-----------

ENUM(\'YES\', \'NO\')

Example
-----------

mysql> SELECT sys.ps_is_consumer_enabled(\'events_stages_history\');
+-----------------------------------------------------+
| sys.ps_is_consumer_enabled(\'events_stages_history\') |
+-----------------------------------------------------+
| NO                                                  |
+-----------------------------------------------------+
1 row in set (0.00 sec)
'
    SQL SECURITY INVOKER
    DETERMINISTIC 
    READS SQL DATA 
BEGIN
    DECLARE v_is_enabled ENUM('YES', 'NO') DEFAULT NULL;
    DECLARE v_error_msg VARCHAR(128);

    -- Return NULL for a NULL argument.
    IF (in_consumer IS NULL) THEN
        RETURN NULL;
    END IF;

    SET v_is_enabled = (
        SELECT (CASE
                   WHEN c.NAME = 'global_instrumentation' THEN c.ENABLED
                   WHEN c.NAME = 'thread_instrumentation' THEN IF(cg.ENABLED = 'YES' AND c.ENABLED = 'YES', 'YES', 'NO')
                   WHEN c.NAME LIKE '%\_digest'           THEN IF(cg.ENABLED = 'YES' AND c.ENABLED = 'YES', 'YES', 'NO')
                   WHEN c.NAME LIKE '%\_current'          THEN IF(cg.ENABLED = 'YES' AND ct.ENABLED = 'YES' AND c.ENABLED = 'YES', 'YES', 'NO')
                   ELSE IF(cg.ENABLED = 'YES' AND ct.ENABLED = 'YES' AND c.ENABLED = 'YES'
                           AND ( SELECT cc.ENABLED FROM performance_schema.setup_consumers cc WHERE NAME = CONCAT(SUBSTRING_INDEX(c.NAME, '_', 2), '_current')
                               ) = 'YES', 'YES', 'NO')
                END) AS IsEnabled
          FROM performance_schema.setup_consumers c
               INNER JOIN performance_schema.setup_consumers cg
               INNER JOIN performance_schema.setup_consumers ct
         WHERE cg.NAME       = 'global_instrumentation'
               AND ct.NAME   = 'thread_instrumentation'
               AND c.NAME    = in_consumer
        );

    IF (v_is_enabled IS NOT NULL) THEN
        RETURN v_is_enabled;
    ELSE
        -- A value of NULL here means it is an unknown consumer name that was passed as an argument.
        -- Only an input value of NULL is allowed to return a NULL result value, to throw a signal instead.
        SET v_error_msg = CONCAT('Invalid argument error: ', in_consumer, ' in function sys.ps_is_consumer_enabled.');
        SIGNAL SQLSTATE 'HY000'
           SET MESSAGE_TEXT = v_error_msg,
               MYSQL_ERRNO  = 3047;
    END IF;
END$$

DELIMITER ;
-- Copyright (c) 2014, 2024, Oracle and/or its affiliates.
--
-- This program is free software; you can redistribute it and/or modify
-- it under the terms of the GNU General Public License as published by
-- the Free Software Foundation; version 2 of the License.
--
-- This program is distributed in the hope that it will be useful,
-- but WITHOUT ANY WARRANTY; without even the implied warranty of
-- MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
-- GNU General Public License for more details.
--
-- You should have received a copy of the GNU General Public License
-- along with this program; if not, write to the Free Software
-- Foundation, Inc., 51 Franklin St, Fifth Floor, Boston, MA 02110-1301 USA

DROP FUNCTION IF EXISTS ps_is_instrument_default_enabled;

DELIMITER $$

CREATE DEFINER='mysql.sys'@'localhost' FUNCTION ps_is_instrument_default_enabled (
        in_instrument VARCHAR(128)
    ) 
    RETURNS ENUM('YES', 'NO')
    COMMENT '
Description
-----------

Returns whether an instrument is enabled by default in this version of MySQL.

Parameters
-----------

in_instrument VARCHAR(128): 
  The instrument to check.

Returns
-----------

ENUM(\'YES\', \'NO\')

Example
-----------

mysql> SELECT sys.ps_is_instrument_default_enabled(\'statement/sql/select\');
+--------------------------------------------------------------+
| sys.ps_is_instrument_default_enabled(\'statement/sql/select\') |
+--------------------------------------------------------------+
| YES                                                          |
+--------------------------------------------------------------+
1 row in set (0.00 sec)
'
    SQL SECURITY INVOKER
    DETERMINISTIC 
    READS SQL DATA 
BEGIN
    DECLARE v_enabled ENUM('YES', 'NO');

    IF (in_instrument LIKE 'stage/%') THEN
    BEGIN
      /* Stages are enabled by default if the progress property is set. */
      SET v_enabled = (SELECT
                        IF(find_in_set("progress", PROPERTIES) != 0, 'YES', 'NO')
                        FROM performance_schema.setup_instruments
                        WHERE NAME = in_instrument);
      SET v_enabled = IFNULL(v_enabled, 'NO');
    END;
    ELSE
      SET v_enabled = IF(in_instrument LIKE 'wait/synch/%'
                         OR in_instrument LIKE 'wait/io/socket/%'
                        ,
                         'NO',
                         'YES'
                      );
    END IF;

    RETURN v_enabled;
END$$


DELIMITER ;
-- Copyright (c) 2014, 2024, Oracle and/or its affiliates.
--
-- This program is free software; you can redistribute it and/or modify
-- it under the terms of the GNU General Public License as published by
-- the Free Software Foundation; version 2 of the License.
--
-- This program is distributed in the hope that it will be useful,
-- but WITHOUT ANY WARRANTY; without even the implied warranty of
-- MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
-- GNU General Public License for more details.
--
-- You should have received a copy of the GNU General Public License
-- along with this program; if not, write to the Free Software
-- Foundation, Inc., 51 Franklin St, Fifth Floor, Boston, MA 02110-1301 USA

DROP FUNCTION IF EXISTS ps_is_instrument_default_timed;

DELIMITER $$

CREATE DEFINER='mysql.sys'@'localhost' FUNCTION ps_is_instrument_default_timed (
        in_instrument VARCHAR(128)
    ) 
    RETURNS ENUM('YES', 'NO')
    COMMENT '
Description
-----------

Returns whether an instrument is timed by default in this version of MySQL.

Parameters
-----------

in_instrument VARCHAR(128): 
  The instrument to check.

Returns
-----------

ENUM(\'YES\', \'NO\')

Example
-----------

mysql> SELECT sys.ps_is_instrument_default_timed(\'statement/sql/select\');
+------------------------------------------------------------+
| sys.ps_is_instrument_default_timed(\'statement/sql/select\') |
+------------------------------------------------------------+
| YES                                                        |
+------------------------------------------------------------+
1 row in set (0.00 sec)
'
    SQL SECURITY INVOKER
    DETERMINISTIC 
    READS SQL DATA 
BEGIN
    DECLARE v_timed ENUM('YES', 'NO');

    IF (in_instrument LIKE 'stage/%') THEN
    BEGIN
      -- Stages are timed by default if the progress property is set.
      SET v_timed = (SELECT
                      IF(find_in_set("progress", PROPERTIES) != 0, 'YES', 'NO')
                      FROM performance_schema.setup_instruments
                      WHERE NAME = in_instrument);
      SET v_timed = IFNULL(v_timed, 'NO');
    END;
    ELSE
      -- Mutex, rwlock, prlock, sxlock, cond are not timed by default
      -- Memory instruments are never timed.
      SET v_timed = IF(in_instrument LIKE 'wait/synch/%'
                       OR in_instrument LIKE 'memory/%'
                      ,
                       'NO',
                       'YES'
                    );
    END IF;

    RETURN v_timed;
END$$

DELIMITER ;
-- Copyright (c) 2015, 2024, Oracle and/or its affiliates.
--
-- This program is free software; you can redistribute it and/or modify
-- it under the terms of the GNU General Public License as published by
-- the Free Software Foundation; version 2 of the License.
--
-- This program is distributed in the hope that it will be useful,
-- but WITHOUT ANY WARRANTY; without even the implied warranty of
-- MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
-- GNU General Public License for more details.
--
-- You should have received a copy of the GNU General Public License
-- along with this program; if not, write to the Free Software
-- Foundation, Inc., 51 Franklin St, Fifth Floor, Boston, MA 02110-1301 USA

DROP FUNCTION IF EXISTS ps_is_thread_instrumented;

DELIMITER $$

CREATE DEFINER='mysql.sys'@'localhost' FUNCTION ps_is_thread_instrumented (
        in_connection_id BIGINT UNSIGNED
    ) RETURNS ENUM('YES', 'NO', 'UNKNOWN')
    COMMENT '
Description
-----------

Checks whether the provided connection id is instrumented within Performance Schema.

Parameters
-----------

in_connection_id (BIGINT UNSIGNED):
  The id of the connection to check.

Returns
-----------

ENUM(\'YES\', \'NO\', \'UNKNOWN\')

Example
-----------

mysql> SELECT sys.ps_is_thread_instrumented(CONNECTION_ID());
+------------------------------------------------+
| sys.ps_is_thread_instrumented(CONNECTION_ID()) |
+------------------------------------------------+
| YES                                            |
+------------------------------------------------+
'

    SQL SECURITY INVOKER
    NOT DETERMINISTIC
    READS SQL DATA
BEGIN
    DECLARE v_enabled ENUM('YES', 'NO', 'UNKNOWN');

    IF (in_connection_id IS NULL) THEN
        RETURN NULL;
    END IF;

    SELECT INSTRUMENTED INTO v_enabled
      FROM performance_schema.threads 
     WHERE PROCESSLIST_ID = in_connection_id;

    IF (v_enabled IS NULL) THEN
        RETURN 'UNKNOWN';
    ELSE
        RETURN v_enabled;
    END IF;
END$$

DELIMITER ;
-- Copyright (c) 2014, 2024, Oracle and/or its affiliates.
--
-- This program is free software; you can redistribute it and/or modify
-- it under the terms of the GNU General Public License as published by
-- the Free Software Foundation; version 2 of the License.
--
-- This program is distributed in the hope that it will be useful,
-- but WITHOUT ANY WARRANTY; without even the implied warranty of
-- MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
-- GNU General Public License for more details.
--
-- You should have received a copy of the GNU General Public License
-- along with this program; if not, write to the Free Software
-- Foundation, Inc., 51 Franklin St, Fifth Floor, Boston, MA 02110-1301 USA

DROP FUNCTION IF EXISTS sys.ps_thread_id;

DELIMITER $$

CREATE DEFINER='mysql.sys'@'localhost' FUNCTION sys.ps_thread_id (
        in_connection_id BIGINT UNSIGNED
    ) RETURNS BIGINT UNSIGNED
    COMMENT '
Description
-----------

Return the Performance Schema THREAD_ID for the specified connection ID.

Parameters
-----------

in_connection_id (BIGINT UNSIGNED):
  The id of the connection to return the thread id for. If NULL, the current
  connection thread id is returned.

Example
-----------

mysql> SELECT sys.ps_thread_id(79);
+----------------------+
| sys.ps_thread_id(79) |
+----------------------+
|                   98 |
+----------------------+
1 row in set (0.00 sec)

mysql> SELECT sys.ps_thread_id(CONNECTION_ID());
+-----------------------------------+
| sys.ps_thread_id(CONNECTION_ID()) |
+-----------------------------------+
|                                98 |
+-----------------------------------+
1 row in set (0.00 sec)
'

    SQL SECURITY INVOKER
    NOT DETERMINISTIC
    READS SQL DATA
BEGIN
  IF (in_connection_id IS NULL) THEN
    RETURN ps_current_thread_id();
  ELSE
    RETURN ps_thread_id(in_connection_id);
  END IF;

END$$

DELIMITER ;
-- Copyright (c) 2015, 2024, Oracle and/or its affiliates.
--
-- This program is free software; you can redistribute it and/or modify
-- it under the terms of the GNU General Public License as published by
-- the Free Software Foundation; version 2 of the License.
--
-- This program is distributed in the hope that it will be useful,
-- but WITHOUT ANY WARRANTY; without even the implied warranty of
-- MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
-- GNU General Public License for more details.
--
-- You should have received a copy of the GNU General Public License
-- along with this program; if not, write to the Free Software
-- Foundation, Inc., 51 Franklin St, Fifth Floor, Boston, MA 02110-1301 USA

DROP FUNCTION IF EXISTS ps_thread_account;

DELIMITER $$

CREATE DEFINER='mysql.sys'@'localhost' FUNCTION ps_thread_account (
        in_thread_id BIGINT UNSIGNED
    ) RETURNS TEXT
    COMMENT '
Description
-----------

Return the user@host account for the given Performance Schema thread id.

Parameters
-----------

in_thread_id (BIGINT UNSIGNED):
  The id of the thread to return the account for.

Example
-----------

mysql> select thread_id, processlist_user, processlist_host from performance_schema.threads where type = ''foreground'';
+-----------+------------------+------------------+
| thread_id | processlist_user | processlist_host |
+-----------+------------------+------------------+
|        23 | NULL             | NULL             |
|        30 | root             | localhost        |
|        31 | msandbox         | localhost        |
|        32 | msandbox         | localhost        |
+-----------+------------------+------------------+
4 rows in set (0.00 sec)

mysql> select sys.ps_thread_account(31);
+---------------------------+
| sys.ps_thread_account(31) |
+---------------------------+
| msandbox@localhost        |
+---------------------------+
1 row in set (0.00 sec)
'

    SQL SECURITY INVOKER
    NOT DETERMINISTIC
    READS SQL DATA
BEGIN
    RETURN (SELECT IF(
                      type = 'FOREGROUND',
                      CONCAT(processlist_user, '@', processlist_host),
                      type
                     ) AS account
              FROM `performance_schema`.`threads`
             WHERE thread_id = in_thread_id);
END$$

DELIMITER ;
-- Copyright (c) 2014, 2024, Oracle and/or its affiliates.
--
-- This program is free software; you can redistribute it and/or modify
-- it under the terms of the GNU General Public License as published by
-- the Free Software Foundation; version 2 of the License.
--
-- This program is distributed in the hope that it will be useful,
-- but WITHOUT ANY WARRANTY; without even the implied warranty of
-- MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
-- GNU General Public License for more details.
--
-- You should have received a copy of the GNU General Public License
-- along with this program; if not, write to the Free Software
-- Foundation, Inc., 51 Franklin St, Fifth Floor, Boston, MA 02110-1301 USA

DROP FUNCTION IF EXISTS ps_thread_stack;

DELIMITER $$

CREATE DEFINER='mysql.sys'@'localhost' FUNCTION ps_thread_stack (
        thd_id BIGINT UNSIGNED,
        debug BOOLEAN
    )
RETURNS LONGTEXT CHARSET latin1
    COMMENT '
Description
-----------

Outputs a JSON formatted stack of all statements, stages and events
within Performance Schema for the specified thread.

Parameters
-----------

thd_id (BIGINT UNSIGNED):
  The id of the thread to trace. This should match the thread_id
  column from the performance_schema.threads table.
in_verbose (BOOLEAN):
  Include file:lineno information in the events.

Example
-----------

(line separation added for output)

mysql> SELECT sys.ps_thread_stack(37, FALSE) AS thread_stack\\G
*************************** 1. row ***************************
thread_stack: {"rankdir": "LR","nodesep": "0.10","stack_created": "2014-02-19 13:39:03",
"mysql_version": "5.7.3-m13","mysql_user": "root@localhost","events": 
[{"nesting_event_id": "0", "event_id": "10", "timer_wait": 256.35, "event_info": 
"sql/select", "wait_info": "select @@version_comment limit 1\\nerrors: 0\\nwarnings: 0\\nlock time:
...
'
SQL SECURITY INVOKER
NOT DETERMINISTIC
READS SQL DATA
BEGIN

    DECLARE json_objects LONGTEXT;

    -- Do not track the current thread, it will kill the stack
    UPDATE performance_schema.threads
       SET instrumented = 'NO'
     WHERE processlist_id = CONNECTION_ID();

    SET SESSION group_concat_max_len=@@global.max_allowed_packet;

    -- Select the entire stack of events
    SELECT GROUP_CONCAT(CONCAT( '{'
              , CONCAT_WS( ', '
              , CONCAT('"nesting_event_id": "', IF(nesting_event_id IS NULL, '0', nesting_event_id), '"')
              , CONCAT('"event_id": "', event_id, '"')
              -- Convert from picoseconds to microseconds
              , CONCAT( '"timer_wait": ', ROUND(timer_wait/1000000, 2))  
              , CONCAT( '"event_info": "'
                  , CASE
                        WHEN event_name NOT LIKE 'wait/io%' THEN REPLACE(SUBSTRING_INDEX(event_name, '/', -2), '\\', '\\\\')
                        WHEN event_name NOT LIKE 'wait/io/file%' OR event_name NOT LIKE 'wait/io/socket%' THEN REPLACE(SUBSTRING_INDEX(event_name, '/', -4), '\\', '\\\\')
                        ELSE event_name
                    END
                  , '"'
              )
              -- Always dump the extra wait information gathered for statements
              , CONCAT( '"wait_info": "', IFNULL(wait_info, ''), '"')
              -- If debug is enabled, add the file:lineno information for waits
              , CONCAT( '"source": "', IF(true AND event_name LIKE 'wait%', IFNULL(wait_info, ''), ''), '"')
              -- Depending on the type of event, name it appropriately
              , CASE 
                     WHEN event_name LIKE 'wait/io/file%'      THEN '"event_type": "io/file"'
                     WHEN event_name LIKE 'wait/io/table%'     THEN '"event_type": "io/table"'
                     WHEN event_name LIKE 'wait/io/socket%'    THEN '"event_type": "io/socket"'
                     WHEN event_name LIKE 'wait/synch/mutex%'  THEN '"event_type": "synch/mutex"'
                     WHEN event_name LIKE 'wait/synch/cond%'   THEN '"event_type": "synch/cond"'
                     WHEN event_name LIKE 'wait/synch/rwlock%' THEN '"event_type": "synch/rwlock"'
                     WHEN event_name LIKE 'wait/lock%'         THEN '"event_type": "lock"'
                     WHEN event_name LIKE 'statement/%'        THEN '"event_type": "stmt"'
                     WHEN event_name LIKE 'stage/%'            THEN '"event_type": "stage"'
                     WHEN event_name LIKE '%idle%'             THEN '"event_type": "idle"'
                     ELSE '' 
                END                   
            )
            , '}'
          )
          ORDER BY event_id ASC SEPARATOR ',') event
    INTO json_objects
    FROM (
          -- Select all statements, with the extra tracing information available
          (SELECT thread_id, event_id, event_name, timer_wait, timer_start, nesting_event_id, 
                  CONCAT(sql_text, '\\n',
                         'errors: ', errors, '\\n',
                         'warnings: ', warnings, '\\n',
                         'lock time: ', ROUND(lock_time/1000000, 2),'us\\n',
                         'rows affected: ', rows_affected, '\\n',
                         'rows sent: ', rows_sent, '\\n',
                         'rows examined: ', rows_examined, '\\n',
                         'tmp tables: ', created_tmp_tables, '\\n',
                         'tmp disk tables: ', created_tmp_disk_tables, '\\n',
                         'select scan: ', select_scan, '\\n',
                         'select full join: ', select_full_join, '\\n',
                         'select full range join: ', select_full_range_join, '\\n',
                         'select range: ', select_range, '\\n',
                         'select range check: ', select_range_check, '\\n', 
                         'sort merge passes: ', sort_merge_passes, '\\n',
                         'sort rows: ', sort_rows, '\\n',
                         'sort range: ', sort_range, '\\n',
                         'sort scan: ', sort_scan, '\\n',
                         'no index used: ', IF(no_index_used, 'TRUE', 'FALSE'), '\\n',
                         'no good index used: ', IF(no_good_index_used, 'TRUE', 'FALSE'), '\\n'
                         ) AS wait_info
             FROM performance_schema.events_statements_history_long WHERE thread_id = thd_id)
          UNION 
          -- Select all stages
          (SELECT thread_id, event_id, event_name, timer_wait, timer_start, nesting_event_id, null AS wait_info
             FROM performance_schema.events_stages_history_long WHERE thread_id = thd_id) 
          UNION
          -- Select all events, adding information appropriate to the event
          (SELECT thread_id, event_id, 
                  CONCAT(event_name , 
                         IF(event_name NOT LIKE 'wait/synch/mutex%', IFNULL(CONCAT(' - ', operation), ''), ''), 
                         IF(number_of_bytes IS NOT NULL, CONCAT(' ', number_of_bytes, ' bytes'), ''),
                         IF(event_name LIKE 'wait/io/file%', '\\n', ''),
                         IF(object_schema IS NOT NULL, CONCAT('\\nObject: ', object_schema, '.'), ''), 
                         IF(object_name IS NOT NULL, 
                            IF (event_name LIKE 'wait/io/socket%',
                                -- Print the socket if used, else the IP:port as reported
                                CONCAT(IF (object_name LIKE ':0%', @@socket, object_name)),
                                object_name),
                            ''),
                         IF(index_name IS NOT NULL, CONCAT(' Index: ', index_name), ''),'\\n'
                         ) AS event_name,
                  timer_wait, timer_start, nesting_event_id, source AS wait_info
             FROM performance_schema.events_waits_history_long WHERE thread_id = thd_id)) events 
    ORDER BY event_id;

    RETURN CONCAT('{', 
                  CONCAT_WS(',', 
                            '"rankdir": "LR"',
                            '"nodesep": "0.10"',
                            CONCAT('"stack_created": "', NOW(), '"'),
                            CONCAT('"mysql_version": "', VERSION(), '"'),
                            CONCAT('"mysql_user": "', CURRENT_USER(), '"'),
                            CONCAT('"events": [', IFNULL(json_objects,''), ']')
                           ),
                  '}');

END$$

DELIMITER ;
-- Copyright (c) 2015, 2024, Oracle and/or its affiliates.
--
-- This program is free software; you can redistribute it and/or modify
-- it under the terms of the GNU General Public License as published by
-- the Free Software Foundation; version 2 of the License.
--
-- This program is distributed in the hope that it will be useful,
-- but WITHOUT ANY WARRANTY; without even the implied warranty of
-- MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
-- GNU General Public License for more details.
--
-- You should have received a copy of the GNU General Public License
-- along with this program; if not, write to the Free Software
-- Foundation, Inc., 51 Franklin St, Fifth Floor, Boston, MA 02110-1301 USA

DROP FUNCTION IF EXISTS ps_thread_trx_info;

DELIMITER $$

CREATE DEFINER='mysql.sys'@'localhost' FUNCTION ps_thread_trx_info (
        in_thread_id BIGINT UNSIGNED
    ) RETURNS LONGTEXT
    COMMENT '
Description
-----------

Returns a JSON object with info on the given threads current transaction, 
and the statements it has already executed, derived from the
performance_schema.events_transactions_current and
performance_schema.events_statements_history tables (so the consumers 
for these also have to be enabled within Performance Schema to get full
data in the object).

When the output exceeds the default truncation length (65535), a JSON error
object is returned, such as:

{ "error": "Trx info truncated: Row 6 was cut by GROUP_CONCAT()" }

Similar error objects are returned for other warnings/and exceptions raised
when calling the function.

The max length of the output of this function can be controlled with the
ps_thread_trx_info.max_length variable set via sys_config, or the
@sys.ps_thread_trx_info.max_length user variable, as appropriate.

Parameters
-----------

in_thread_id (BIGINT UNSIGNED):
  The id of the thread to return the transaction info for.

Example
-----------

SELECT sys.ps_thread_trx_info(48)\\G
*************************** 1. row ***************************
sys.ps_thread_trx_info(48): [
  {
    "time": "790.70 us",
    "state": "COMMITTED",
    "mode": "READ WRITE",
    "autocommitted": "NO",
    "gtid": "AUTOMATIC",
    "isolation": "REPEATABLE READ",
    "statements_executed": [
      {
        "sql_text": "INSERT INTO info VALUES (1, \'foo\')",
        "time": "471.02 us",
        "schema": "trx",
        "rows_examined": 0,
        "rows_affected": 1,
        "rows_sent": 0,
        "tmp_tables": 0,
        "tmp_disk_tables": 0,
        "sort_rows": 0,
        "sort_merge_passes": 0
      },
      {
        "sql_text": "COMMIT",
        "time": "254.42 us",
        "schema": "trx",
        "rows_examined": 0,
        "rows_affected": 0,
        "rows_sent": 0,
        "tmp_tables": 0,
        "tmp_disk_tables": 0,
        "sort_rows": 0,
        "sort_merge_passes": 0
      }
    ]
  },
  {
    "time": "426.20 us",
    "state": "COMMITTED",
    "mode": "READ WRITE",
    "autocommitted": "NO",
    "gtid": "AUTOMATIC",
    "isolation": "REPEATABLE READ",
    "statements_executed": [
      {
        "sql_text": "INSERT INTO info VALUES (2, \'bar\')",
        "time": "107.33 us",
        "schema": "trx",
        "rows_examined": 0,
        "rows_affected": 1,
        "rows_sent": 0,
        "tmp_tables": 0,
        "tmp_disk_tables": 0,
        "sort_rows": 0,
        "sort_merge_passes": 0
      },
      {
        "sql_text": "COMMIT",
        "time": "213.23 us",
        "schema": "trx",
        "rows_examined": 0,
        "rows_affected": 0,
        "rows_sent": 0,
        "tmp_tables": 0,
        "tmp_disk_tables": 0,
        "sort_rows": 0,
        "sort_merge_passes": 0
      }
    ]
  }
]
1 row in set (0.03 sec)
'

    SQL SECURITY INVOKER
    NOT DETERMINISTIC
    READS SQL DATA
BEGIN
    DECLARE v_output LONGTEXT DEFAULT '{}';
    DECLARE v_msg_text TEXT DEFAULT '';
    DECLARE v_signal_msg TEXT DEFAULT '';
    DECLARE v_mysql_errno INT;
    DECLARE v_max_output_len BIGINT;
    -- Capture warnings/errors such as group_concat truncation
    -- and report as JSON error objects
    DECLARE EXIT HANDLER FOR SQLWARNING, SQLEXCEPTION
    BEGIN
        GET DIAGNOSTICS CONDITION 1
            v_msg_text = MESSAGE_TEXT,
            v_mysql_errno = MYSQL_ERRNO;

        IF v_mysql_errno = 1260 THEN
            SET v_signal_msg = CONCAT('{ "error": "Trx info truncated: ', v_msg_text, '" }');
        ELSE
            SET v_signal_msg = CONCAT('{ "error": "', v_msg_text, '" }');
        END IF;

        RETURN v_signal_msg;
    END;

    -- Set configuration options
    IF (@sys.ps_thread_trx_info.max_length IS NULL) THEN
        SET @sys.ps_thread_trx_info.max_length = sys.sys_get_config('ps_thread_trx_info.max_length', 65535);
    END IF;

    IF (@sys.ps_thread_trx_info.max_length != @@session.group_concat_max_len) THEN
        SET @old_group_concat_max_len = @@session.group_concat_max_len;
        -- Convert to int value for the SET, and give some surrounding space
        SET v_max_output_len = (@sys.ps_thread_trx_info.max_length - 5);
        SET SESSION group_concat_max_len = v_max_output_len;
    END IF;

    SET v_output = (
        SELECT CONCAT('[', IFNULL(GROUP_CONCAT(trx_info ORDER BY event_id), ''), '\n]') AS trx_info
          FROM (SELECT trxi.thread_id, 
                       trxi.event_id,
                       GROUP_CONCAT(
                         IFNULL(
                           CONCAT('\n  {\n',
                                  '    "time": "', IFNULL(format_pico_time(trxi.timer_wait), ''), '",\n',
                                  '    "state": "', IFNULL(trxi.state, ''), '",\n',
                                  '    "mode": "', IFNULL(trxi.access_mode, ''), '",\n',
                                  '    "autocommitted": "', IFNULL(trxi.autocommit, ''), '",\n',
                                  '    "gtid": "', IFNULL(trxi.gtid, ''), '",\n',
                                  '    "isolation": "', IFNULL(trxi.isolation_level, ''), '",\n',
                                  '    "statements_executed": [', IFNULL(s.stmts, ''), IF(s.stmts IS NULL, ' ]\n', '\n    ]\n'),
                                  '  }'
                           ), 
                           '') 
                         ORDER BY event_id) AS trx_info

                  FROM (
                        (SELECT thread_id, event_id, timer_wait, state,access_mode, autocommit, gtid, isolation_level
                           FROM performance_schema.events_transactions_current
                          WHERE thread_id = in_thread_id
                            AND end_event_id IS NULL)
                        UNION
                        (SELECT thread_id, event_id, timer_wait, state,access_mode, autocommit, gtid, isolation_level
                           FROM performance_schema.events_transactions_history
                          WHERE thread_id = in_thread_id)
                       ) AS trxi
                  LEFT JOIN (SELECT thread_id,
                                    nesting_event_id,
                                    GROUP_CONCAT(
                                      IFNULL(
                                        CONCAT('\n      {\n',
                                               '        "sql_text": "', IFNULL(sys.format_statement(REPLACE(sql_text, '\\', '\\\\')), ''), '",\n',
                                               '        "time": "', IFNULL(format_pico_time(timer_wait), ''), '",\n',
                                               '        "schema": "', IFNULL(current_schema, ''), '",\n',
                                               '        "rows_examined": ', IFNULL(rows_examined, ''), ',\n',
                                               '        "rows_affected": ', IFNULL(rows_affected, ''), ',\n',
                                               '        "rows_sent": ', IFNULL(rows_sent, ''), ',\n',
                                               '        "tmp_tables": ', IFNULL(created_tmp_tables, ''), ',\n',
                                               '        "tmp_disk_tables": ', IFNULL(created_tmp_disk_tables, ''), ',\n',
                                               '        "sort_rows": ', IFNULL(sort_rows, ''), ',\n',
                                               '        "sort_merge_passes": ', IFNULL(sort_merge_passes, ''), '\n',
                                               '      }'), '') ORDER BY event_id) AS stmts
                               FROM performance_schema.events_statements_history
                              WHERE sql_text IS NOT NULL
                                AND thread_id = in_thread_id
                              GROUP BY thread_id, nesting_event_id
                            ) AS s 
                    ON trxi.thread_id = s.thread_id 
                   AND trxi.event_id = s.nesting_event_id
                 WHERE trxi.thread_id = in_thread_id
                 GROUP BY trxi.thread_id, trxi.event_id
                ) trxs
          GROUP BY thread_id
    );

    IF (@old_group_concat_max_len IS NOT NULL) THEN
        SET SESSION group_concat_max_len = @old_group_concat_max_len;
    END IF;

    RETURN v_output;
END$$

DELIMITER ;
-- Copyright (c) 2016, 2024, Oracle and/or its affiliates.
--
-- This program is free software; you can redistribute it and/or modify
-- it under the terms of the GNU General Public License as published by
-- the Free Software Foundation; version 2 of the License.
--
-- This program is distributed in the hope that it will be useful,
-- but WITHOUT ANY WARRANTY; without even the implied warranty of
-- MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
-- GNU General Public License for more details.
--
-- You should have received a copy of the GNU General Public License
-- along with this program; if not, write to the Free Software
-- Foundation, Inc., 51 Franklin St, Fifth Floor, Boston, MA 02110-1301 USA

DROP FUNCTION IF EXISTS quote_identifier;

DELIMITER $$

-- https://dev.mysql.com/doc/refman/5.7/en/identifiers.html
-- Maximum supported length for any of the current identifiers in 5.7.5+ is 256 characters.
-- Before that, user variables could have any length.
--
-- Based on Paul Dubois' suggestion in Bug #78823/Bug #22011361.
CREATE DEFINER='mysql.sys'@'localhost' FUNCTION quote_identifier(in_identifier TEXT)
    RETURNS TEXT CHARSET UTF8MB4
    COMMENT '
Description
-----------

Takes an unquoted identifier (schema name, table name, etc.) and
returns the identifier quoted with backticks.

Parameters
-----------

in_identifier (TEXT):
  The identifier to quote.

Returns
-----------

TEXT CHARSET UTF8MB4

Example
-----------

mysql> SELECT sys.quote_identifier(''my_identifier'') AS Identifier;
+-----------------+
| Identifier      |
+-----------------+
| `my_identifier` |
+-----------------+
1 row in set (0.00 sec)

mysql> SELECT sys.quote_identifier(''my`idenfier'') AS Identifier;
+----------------+
| Identifier     |
+----------------+
| `my``idenfier` |
+----------------+
1 row in set (0.00 sec)
'
    SQL SECURITY INVOKER
    DETERMINISTIC
    NO SQL
BEGIN
    RETURN CONCAT('`', REPLACE(in_identifier, '`', '``'), '`');
END$$

DELIMITER ;
-- Copyright (c) 2014, 2024, Oracle and/or its affiliates.
--
-- This program is free software; you can redistribute it and/or modify
-- it under the terms of the GNU General Public License as published by
-- the Free Software Foundation; version 2 of the License.
--
-- This program is distributed in the hope that it will be useful,
-- but WITHOUT ANY WARRANTY; without even the implied warranty of
-- MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
-- GNU General Public License for more details.
--
-- You should have received a copy of the GNU General Public License
-- along with this program; if not, write to the Free Software
-- Foundation, Inc., 51 Franklin St, Fifth Floor, Boston, MA 02110-1301 USA

DROP FUNCTION IF EXISTS sys_get_config;

DELIMITER $$

CREATE DEFINER='mysql.sys'@'localhost' FUNCTION sys_get_config (
        in_variable_name VARCHAR(128),
        in_default_value VARCHAR(128)
    )
    RETURNS VARCHAR(128)
    COMMENT '
Description
-----------

Returns the value for the requested variable using the following logic:

   1. If the option exists in sys.sys_config return the value from there.
   2. Else fall back on the provided default value.

Notes for using sys_get_config():

   * If the default value argument to sys_get_config() is NULL and case 2. is reached, NULL is returned.
     It is then expected that the caller is able to handle NULL for the given configuration option.
   * The convention is to name the user variables @sys.<name of variable>. It is <name of variable> that
     is stored in the sys_config table and is what is expected as the argument to sys_get_config().
   * If you want to check whether the configuration option has already been set and if not assign with
     the return value of sys_get_config() you can use IFNULL(...) (see example below). However this should
     not be done inside a loop (e.g. for each row in a result set) as for repeated calls where assignment
     is only needed in the first iteration using IFNULL(...) is expected to be significantly slower than
     using an IF (...) THEN ... END IF; block (see example below).

Parameters
-----------

in_variable_name (VARCHAR(128)):
  The name of the config option to return the value for.

in_default_value (VARCHAR(128)):
  The default value to return if the variable does not exist in sys.sys_config.

Returns
-----------

VARCHAR(128)

Example
-----------

-- Get the configuration value from sys.sys_config falling back on 128 if the option is not present in the table.
mysql> SELECT sys.sys_get_config(''statement_truncate_len'', 128) AS Value;
+-------+
| Value |
+-------+
| 64    |
+-------+
1 row in set (0.00 sec)

-- Check whether the option is already set, if not assign - IFNULL(...) one liner example.
mysql> SET @sys.statement_truncate_len = IFNULL(@sys.statement_truncate_len, sys.sys_get_config(''statement_truncate_len'', 64));
Query OK, 0 rows affected (0.00 sec)

-- Check whether the option is already set, if not assign - IF ... THEN ... END IF example.
IF (@sys.statement_truncate_len IS NULL) THEN
    SET @sys.statement_truncate_len = sys.sys_get_config(''statement_truncate_len'', 64);
END IF;
'
    SQL SECURITY INVOKER
    DETERMINISTIC
    READS SQL DATA
BEGIN
    DECLARE v_value VARCHAR(128) DEFAULT NULL;

    -- Check if we have the variable in the sys.sys_config table
    SET v_value = (SELECT value FROM sys.sys_config WHERE variable = in_variable_name);
  
    -- Protection against the variable not existing in sys_config
    IF (v_value IS NULL) THEN
        SET v_value = in_default_value;
    END IF;

    RETURN v_value;
END $$

DELIMITER ;
-- Copyright (c) 2014, 2024, Oracle and/or its affiliates.
--
-- This program is free software; you can redistribute it and/or modify
-- it under the terms of the GNU General Public License as published by
-- the Free Software Foundation; version 2 of the License.
--
-- This program is distributed in the hope that it will be useful,
-- but WITHOUT ANY WARRANTY; without even the implied warranty of
-- MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
-- GNU General Public License for more details.
--
-- You should have received a copy of the GNU General Public License
-- along with this program; if not, write to the Free Software
-- Foundation, Inc., 51 Franklin St, Fifth Floor, Boston, MA 02110-1301 USA

DROP FUNCTION IF EXISTS version_major;

DELIMITER $$

CREATE DEFINER='mysql.sys'@'localhost' FUNCTION version_major ()
    RETURNS TINYINT UNSIGNED
    COMMENT '
Description
-----------

Returns the major version of MySQL Server.

Returns
-----------

TINYINT UNSIGNED

Example
-----------

mysql> SELECT VERSION(), sys.version_major();
+--------------------------------------+---------------------+
| VERSION()                            | sys.version_major() |
+--------------------------------------+---------------------+
| 5.7.9-enterprise-commercial-advanced | 5                   |
+--------------------------------------+---------------------+
1 row in set (0.00 sec)
'
    SQL SECURITY INVOKER
    NOT DETERMINISTIC
    NO SQL
BEGIN
    RETURN SUBSTRING_INDEX(SUBSTRING_INDEX(VERSION(), '-', 1), '.', 1);
END$$

DELIMITER ;
-- Copyright (c) 2014, 2024, Oracle and/or its affiliates.
--
-- This program is free software; you can redistribute it and/or modify
-- it under the terms of the GNU General Public License as published by
-- the Free Software Foundation; version 2 of the License.
--
-- This program is distributed in the hope that it will be useful,
-- but WITHOUT ANY WARRANTY; without even the implied warranty of
-- MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
-- GNU General Public License for more details.
--
-- You should have received a copy of the GNU General Public License
-- along with this program; if not, write to the Free Software
-- Foundation, Inc., 51 Franklin St, Fifth Floor, Boston, MA 02110-1301 USA

DROP FUNCTION IF EXISTS version_minor;

DELIMITER $$

CREATE DEFINER='mysql.sys'@'localhost' FUNCTION version_minor ()
    RETURNS TINYINT UNSIGNED
    COMMENT '
Description
-----------

Returns the minor (release series) version of MySQL Server.

Returns
-----------

TINYINT UNSIGNED

Example
-----------

mysql> SELECT VERSION(), sys.server_minor();
+--------------------------------------+---------------------+
| VERSION()                            | sys.version_minor() |
+--------------------------------------+---------------------+
| 5.7.9-enterprise-commercial-advanced | 7                   |
+--------------------------------------+---------------------+
1 row in set (0.00 sec)
'
    SQL SECURITY INVOKER
    NOT DETERMINISTIC
    NO SQL
BEGIN
    RETURN SUBSTRING_INDEX(SUBSTRING_INDEX(SUBSTRING_INDEX(VERSION(), '-', 1), '.', 2), '.', -1);
END$$

DELIMITER ;
-- Copyright (c) 2014, 2024, Oracle and/or its affiliates.
--
-- This program is free software; you can redistribute it and/or modify
-- it under the terms of the GNU General Public License as published by
-- the Free Software Foundation; version 2 of the License.
--
-- This program is distributed in the hope that it will be useful,
-- but WITHOUT ANY WARRANTY; without even the implied warranty of
-- MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
-- GNU General Public License for more details.
--
-- You should have received a copy of the GNU General Public License
-- along with this program; if not, write to the Free Software
-- Foundation, Inc., 51 Franklin St, Fifth Floor, Boston, MA 02110-1301 USA

DROP FUNCTION IF EXISTS version_patch;

DELIMITER $$

CREATE DEFINER='mysql.sys'@'localhost' FUNCTION version_patch ()
    RETURNS TINYINT UNSIGNED
    COMMENT '
Description
-----------

Returns the patch release version of MySQL Server.

Returns
-----------

TINYINT UNSIGNED

Example
-----------

mysql> SELECT VERSION(), sys.version_patch();
+--------------------------------------+---------------------+
| VERSION()                            | sys.version_patch() |
+--------------------------------------+---------------------+
| 5.7.9-enterprise-commercial-advanced | 9                   |
+--------------------------------------+---------------------+
1 row in set (0.00 sec)
'
    SQL SECURITY INVOKER
    NOT DETERMINISTIC
    NO SQL
BEGIN
    RETURN SUBSTRING_INDEX(SUBSTRING_INDEX(VERSION(), '-', 1), '.', -1);
END$$

DELIMITER ;
-- Copyright (c) 2014, 2023, Oracle and/or its affiliates.
--
-- This program is free software; you can redistribute it and/or modify
-- it under the terms of the GNU General Public License as published by
-- the Free Software Foundation; version 2 of the License.
--
-- This program is distributed in the hope that it will be useful,
-- but WITHOUT ANY WARRANTY; without even the implied warranty of
-- MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
-- GNU General Public License for more details.
--
-- You should have received a copy of the GNU General Public License
-- along with this program; if not, write to the Free Software
-- Foundation, Inc., 51 Franklin St, Fifth Floor, Boston, MA 02110-1301 USA
-- Copyright (c) 2023, Shannon Data AI and/or its affiliates.

DROP FUNCTION IF EXISTS ml_predict_row;

DELIMITER $$

CREATE DEFINER='mysql.sys'@'localhost' FUNCTION ml_predict_row (
        in_predict_data JSON,
        in_model_handle_name VARCHAR(64),
        in_model_option JSON
    )
    RETURNS JSON
    COMMENT '
Description
-----------

Run the ml_predict_row routine on a labeled training dataset to produce a trained machine learning model.

Parameters
-----------

in_input_data JSON:
  the data to be predicted.
in_model_handle_name (VARCHAR(64)):
  user-defined session variable storing the ML model handle for the duration of the connection.
in_model_option JSON:
  This parameter only supports the recommendation and anomaly_detection tasks.
  For all other tasks, set this parameter to NULL.
Example
-----------
mysql> SELECT sys.ML_PREDICT_ROW(JSON_OBJECT(\'column_name\', value,
          \'column_name\', value, ...),
          model_handle, options);
'
    SQL SECURITY INVOKER
    DETERMINISTIC
    CONTAINS SQL
BEGIN

  DECLARE v_db_err_msg TEXT;
  DECLARE v_model_id INT;
  DECLARE v_pred_row_res JSON;

  SELECT ML_MODEL_PREDICT_ROW(in_predict_data, in_model_handle_name, in_model_option) INTO v_pred_row_res;
  RETURN v_pred_row_res;
END$$

DELIMITER ;
-- Copyright (c) 2014, 2023, Oracle and/or its affiliates.
--
-- This program is free software; you can redistribute it and/or modify
-- it under the terms of the GNU General Public License as published by
-- the Free Software Foundation; version 2 of the License.
--
-- This program is distributed in the hope that it will be useful,
-- but WITHOUT ANY WARRANTY; without even the implied warranty of
-- MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
-- GNU General Public License for more details.
--
-- You should have received a copy of the GNU General Public License
-- along with this program; if not, write to the Free Software
-- Foundation, Inc., 51 Franklin St, Fifth Floor, Boston, MA 02110-1301 USA
-- Copyright (c) 2023, Shannon Data AI and/or its affiliates.

DROP FUNCTION IF EXISTS ml_embed_row;

DELIMITER $$

CREATE DEFINER='mysql.sys'@'localhost' FUNCTION ml_embed_row (
        in_text TEXT,
        in_model_option JSON
    )
    RETURNS BLOB
    COMMENT '
Description
-----------

The ML_EMBED_ROW routine uses the specified embedding model to encode the specified text or query into a vector embedding. 

Parameters
-----------

in_text (TEXT):
  user-defined session variable storing the ML model handle for the duration of the connection.
in_model_option JSON:
  specifies optional parameters as key-value pairs in JSON format
Example
-----------
mysql> SELECT sys.ML_EMBED_ROW("What is artificial intelligence?", JSON_OBJECT("model_id", "all_minilm_l12_v2")) into @text_embedding;
'
    SQL SECURITY INVOKER
    DETERMINISTIC
    CONTAINS SQL
BEGIN

  DECLARE v_embed_row_res BLOB;

  SELECT ML_MODEL_EMBED_ROW(in_text, in_model_option) INTO v_embed_row_res;
  RETURN v_embed_row_res;
END$$

DELIMITER ;
-- Copyright (c) 2014, 2023, Oracle and/or its affiliates.
--
-- This program is free software; you can redistribute it and/or modify
-- it under the terms of the GNU General Public License as published by
-- the Free Software Foundation; version 2 of the License.
--
-- This program is distributed in the hope that it will be useful,
-- but WITHOUT ANY WARRANTY; without even the implied warranty of
-- MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
-- GNU General Public License for more details.
--
-- You should have received a copy of the GNU General Public License
-- along with this program; if not, write to the Free Software
-- Foundation, Inc., 51 Franklin St, Fifth Floor, Boston, MA 02110-1301 USA
-- Copyright (c) 2023, Shannon Data AI and/or its affiliates.

DROP FUNCTION IF EXISTS ml_generate;

DELIMITER $$

CREATE DEFINER='mysql.sys'@'localhost' FUNCTION ml_generate (
        in_text TEXT,
        in_model_option JSON
    )
    RETURNS TEXT
    COMMENT '
Description
-----------

The ML_GENERATE routine uses the specified large language model (LLM) to generate text-based content as a response for the given natural-language query.

Parameters
-----------

in_text (TEXT):
  : specifies the natural-language query that is passed to the large language model (LLM) handle.
in_model_option JSON:
  specifies optional parameters as key-value pairs in JSON format. It can include the following parameters:
Example
-----------
mysql> SELECT sys.ML_GENERATE("What is AI?", JSON_OBJECT("task", "generation", "model_id", "mistral-7b-instruct-v3", "language", "en"));
'
    SQL SECURITY INVOKER
    DETERMINISTIC
    CONTAINS SQL
BEGIN

  DECLARE v_generate_res TEXT;

  SELECT ML_MODEL_GENERATE(in_text, in_model_option) INTO v_generate_res;
  RETURN v_generate_res;
END$$

DELIMITER ;
-- Copyright (c) 2014, 2024, Oracle and/or its affiliates.
--
-- This program is free software; you can redistribute it and/or modify
-- it under the terms of the GNU General Public License as published by
-- the Free Software Foundation; version 2 of the License.
--
-- This program is distributed in the hope that it will be useful,
-- but WITHOUT ANY WARRANTY; without even the implied warranty of
-- MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
-- GNU General Public License for more details.
--
-- You should have received a copy of the GNU General Public License
-- along with this program; if not, write to the Free Software
-- Foundation, Inc., 51 Franklin St, Fifth Floor, Boston, MA 02110-1301 USA

--
-- View: innodb_buffer_stats_by_schema
-- 
-- Summarizes the output of the INFORMATION_SCHEMA.INNODB_BUFFER_PAGE 
-- table, aggregating by schema
--
-- 
-- mysql> select * from innodb_buffer_stats_by_schema;
-- +--------------------------+------------+------------+-------+--------------+-----------+-------------+
-- | object_schema            | allocated  | data       | pages | pages_hashed | pages_old | rows_cached |
-- +--------------------------+------------+------------+-------+--------------+-----------+-------------+
-- | mem30_trunk__instruments | 1.69 MiB   | 510.03 KiB |   108 |          108 |       108 |        3885 |
-- | InnoDB System            | 688.00 KiB | 351.62 KiB |    43 |           43 |        43 |         862 |
-- | mem30_trunk__events      | 80.00 KiB  | 21.61 KiB  |     5 |            5 |         5 |         229 |
-- +--------------------------+------------+------------+-------+--------------+-----------+-------------+
--

CREATE OR REPLACE
  ALGORITHM = TEMPTABLE
  DEFINER = 'mysql.sys'@'localhost'
  SQL SECURITY INVOKER 
VIEW innodb_buffer_stats_by_schema (
  object_schema,
  allocated,
  data,
  pages,
  pages_hashed,
  pages_old,
  rows_cached
) AS
SELECT IF(LOCATE('.', ibp.table_name) = 0, 'InnoDB System', REPLACE(SUBSTRING_INDEX(ibp.table_name, '.', 1), '`', '')) AS object_schema,
       format_bytes(SUM(IF(ibp.compressed_size = 0, 16384, compressed_size))) AS allocated,
       format_bytes(SUM(ibp.data_size)) AS data,
       COUNT(ibp.page_number) AS pages,
       COUNT(IF(ibp.is_hashed = 'YES', 1, NULL)) AS pages_hashed,
       COUNT(IF(ibp.is_old = 'YES', 1, NULL)) AS pages_old,
       ROUND(SUM(ibp.number_records)/COUNT(DISTINCT ibp.index_name)) AS rows_cached 
  FROM information_schema.innodb_buffer_page ibp 
 WHERE table_name IS NOT NULL
 GROUP BY object_schema
 ORDER BY SUM(IF(ibp.compressed_size = 0, 16384, compressed_size)) DESC;
-- Copyright (c) 2014, 2024, Oracle and/or its affiliates.
--
-- This program is free software; you can redistribute it and/or modify
-- it under the terms of the GNU General Public License as published by
-- the Free Software Foundation; version 2 of the License.
--
-- This program is distributed in the hope that it will be useful,
-- but WITHOUT ANY WARRANTY; without even the implied warranty of
-- MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
-- GNU General Public License for more details.
--
-- You should have received a copy of the GNU General Public License
-- along with this program; if not, write to the Free Software
-- Foundation, Inc., 51 Franklin St, Fifth Floor, Boston, MA 02110-1301 USA

--
-- View: x$innodb_buffer_stats_by_schema
-- 
-- Summarizes the output of the INFORMATION_SCHEMA.INNODB_BUFFER_PAGE 
-- table, aggregating by schema
--
-- mysql> select * from x$innodb_buffer_stats_by_schema;
-- +--------------------------+-----------+--------+-------+--------------+-----------+-------------+
-- | object_schema            | allocated | data   | pages | pages_hashed | pages_old | rows_cached |
-- +--------------------------+-----------+--------+-------+--------------+-----------+-------------+
-- | mem30_trunk__instruments |   1769472 | 522272 |   108 |          108 |       108 |        3885 |
-- | InnoDB System            |    704512 | 360054 |    43 |           43 |        43 |         862 |
-- | mem30_trunk__events      |     81920 |  22125 |     5 |            5 |         5 |         229 |
-- +--------------------------+-----------+--------+-------+--------------+-----------+-------------+
--

CREATE OR REPLACE
  ALGORITHM = TEMPTABLE
  DEFINER = 'mysql.sys'@'localhost'
  SQL SECURITY INVOKER 
VIEW x$innodb_buffer_stats_by_schema (
  object_schema,
  allocated,
  data,
  pages,
  pages_hashed,
  pages_old,
  rows_cached
) AS
SELECT IF(LOCATE('.', ibp.table_name) = 0, 'InnoDB System', REPLACE(SUBSTRING_INDEX(ibp.table_name, '.', 1), '`', '')) AS object_schema,
       SUM(IF(ibp.compressed_size = 0, 16384, compressed_size)) AS allocated,
       SUM(ibp.data_size) AS data,
       COUNT(ibp.page_number) AS pages,
       COUNT(IF(ibp.is_hashed = 'YES', 1, NULL)) AS pages_hashed,
       COUNT(IF(ibp.is_old = 'YES', 1, NULL)) AS pages_old,
       ROUND(IFNULL(SUM(ibp.number_records)/NULLIF(COUNT(DISTINCT ibp.index_name), 0), 0)) AS rows_cached 
  FROM information_schema.innodb_buffer_page ibp 
 WHERE table_name IS NOT NULL
 GROUP BY object_schema
 ORDER BY SUM(IF(ibp.compressed_size = 0, 16384, compressed_size)) DESC;
-- Copyright (c) 2014, 2024, Oracle and/or its affiliates.
--
-- This program is free software; you can redistribute it and/or modify
-- it under the terms of the GNU General Public License as published by
-- the Free Software Foundation; version 2 of the License.
--
-- This program is distributed in the hope that it will be useful,
-- but WITHOUT ANY WARRANTY; without even the implied warranty of
-- MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
-- GNU General Public License for more details.
--
-- You should have received a copy of the GNU General Public License
-- along with this program; if not, write to the Free Software
-- Foundation, Inc., 51 Franklin St, Fifth Floor, Boston, MA 02110-1301 USA

--
-- View: innodb_buffer_stats_by_table
-- 
-- Summarizes the output of the INFORMATION_SCHEMA.INNODB_BUFFER_PAGE 
-- table, aggregating by schema and table name
--
-- mysql> select * from innodb_buffer_stats_by_table;
-- +--------------------------+------------------------------------+------------+-----------+-------+--------------+-----------+-------------+
-- | object_schema            | object_name                        | allocated  | data      | pages | pages_hashed | pages_old | rows_cached |
-- +--------------------------+------------------------------------+------------+-----------+-------+--------------+-----------+-------------+
-- | InnoDB System            | SYS_COLUMNS                        | 128.00 KiB | 98.97 KiB |     8 |            8 |         8 |        1532 |
-- | InnoDB System            | SYS_FOREIGN                        | 128.00 KiB | 55.48 KiB |     8 |            8 |         8 |         172 |
-- | InnoDB System            | SYS_TABLES                         | 128.00 KiB | 56.18 KiB |     8 |            8 |         8 |         365 |
-- | InnoDB System            | SYS_INDEXES                        | 112.00 KiB | 76.16 KiB |     7 |            7 |         7 |        1046 |
-- | mem30_trunk__instruments | agentlatencytime                   | 96.00 KiB  | 28.83 KiB |     6 |            6 |         6 |         252 |
-- | mem30_trunk__instruments | binlogspaceusagedata               | 96.00 KiB  | 22.54 KiB |     6 |            6 |         6 |         196 |
-- | mem30_trunk__instruments | connectionsdata                    | 96.00 KiB  | 36.68 KiB |     6 |            6 |         6 |         276 |
-- ...
-- +--------------------------+------------------------------------+------------+-----------+-------+--------------+-----------+-------------+
--

CREATE OR REPLACE
  ALGORITHM = TEMPTABLE
  DEFINER = 'mysql.sys'@'localhost'
  SQL SECURITY INVOKER 
VIEW innodb_buffer_stats_by_table (
  object_schema,
  object_name,
  allocated,
  data,
  pages,
  pages_hashed,
  pages_old,
  rows_cached
) AS
SELECT IF(LOCATE('.', ibp.table_name) = 0, 'InnoDB System', REPLACE(SUBSTRING_INDEX(ibp.table_name, '.', 1), '`', '')) AS object_schema,
       REPLACE(SUBSTRING_INDEX(ibp.table_name, '.', -1), '`', '') AS object_name,
       format_bytes(SUM(IF(ibp.compressed_size = 0, 16384, compressed_size))) AS allocated,
       format_bytes(SUM(ibp.data_size)) AS data,
       COUNT(ibp.page_number) AS pages,
       COUNT(IF(ibp.is_hashed = 'YES', 1, NULL)) AS pages_hashed,
       COUNT(IF(ibp.is_old = 'YES', 1, NULL)) AS pages_old,
       ROUND(SUM(ibp.number_records)/COUNT(DISTINCT ibp.index_name)) AS rows_cached 
  FROM information_schema.innodb_buffer_page ibp 
 WHERE table_name IS NOT NULL
 GROUP BY object_schema, object_name
 ORDER BY SUM(IF(ibp.compressed_size = 0, 16384, compressed_size)) DESC;
-- Copyright (c) 2014, 2024, Oracle and/or its affiliates.
--
-- This program is free software; you can redistribute it and/or modify
-- it under the terms of the GNU General Public License as published by
-- the Free Software Foundation; version 2 of the License.
--
-- This program is distributed in the hope that it will be useful,
-- but WITHOUT ANY WARRANTY; without even the implied warranty of
-- MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
-- GNU General Public License for more details.
--
-- You should have received a copy of the GNU General Public License
-- along with this program; if not, write to the Free Software
-- Foundation, Inc., 51 Franklin St, Fifth Floor, Boston, MA 02110-1301 USA

--
-- View: x$innodb_buffer_stats_by_table
-- 
-- Summarizes the output of the INFORMATION_SCHEMA.INNODB_BUFFER_PAGE 
-- table, aggregating by schema and table name
--
-- mysql> select * from x$innodb_buffer_stats_by_table;
-- +--------------------------+------------------------------------+-----------+--------+-------+--------------+-----------+-------------+
-- | object_schema            | object_name                        | allocated | data   | pages | pages_hashed | pages_old | rows_cached |
-- +--------------------------+------------------------------------+-----------+--------+-------+--------------+-----------+-------------+
-- | InnoDB System            | SYS_COLUMNS                        |    131072 | 101350 |     8 |            8 |         8 |        1532 |
-- | InnoDB System            | SYS_FOREIGN                        |    131072 |  56808 |     8 |            8 |         8 |         172 |
-- | InnoDB System            | SYS_TABLES                         |    131072 |  57529 |     8 |            8 |         8 |         365 |
-- | InnoDB System            | SYS_INDEXES                        |    114688 |  77984 |     7 |            7 |         7 |        1046 |
-- | mem30_trunk__instruments | agentlatencytime                   |     98304 |  29517 |     6 |            6 |         6 |         252 |
-- | mem30_trunk__instruments | binlogspaceusagedata               |     98304 |  23076 |     6 |            6 |         6 |         196 |
-- | mem30_trunk__instruments | connectionsdata                    |     98304 |  37563 |     6 |            6 |         6 |         276 |
-- ...
-- +--------------------------+------------------------------------+-----------+--------+-------+--------------+-----------+-------------+
--

CREATE OR REPLACE
  ALGORITHM = TEMPTABLE
  DEFINER = 'mysql.sys'@'localhost'
  SQL SECURITY INVOKER 
VIEW x$innodb_buffer_stats_by_table (
  object_schema,
  object_name,
  allocated,
  data,
  pages,
  pages_hashed,
  pages_old,
  rows_cached
) AS
SELECT IF(LOCATE('.', ibp.table_name) = 0, 'InnoDB System', REPLACE(SUBSTRING_INDEX(ibp.table_name, '.', 1), '`', '')) AS object_schema,
       REPLACE(SUBSTRING_INDEX(ibp.table_name, '.', -1), '`', '') AS object_name,
       SUM(IF(ibp.compressed_size = 0, 16384, compressed_size)) AS allocated,
       SUM(ibp.data_size) AS data,
       COUNT(ibp.page_number) AS pages,
       COUNT(IF(ibp.is_hashed = 'YES', 1, NULL)) AS pages_hashed,
       COUNT(IF(ibp.is_old = 'YES', 1, NULL)) AS pages_old,
       ROUND(IFNULL(SUM(ibp.number_records)/NULLIF(COUNT(DISTINCT ibp.index_name), 0), 0)) AS rows_cached 
  FROM information_schema.innodb_buffer_page ibp 
 WHERE table_name IS NOT NULL
 GROUP BY object_schema, object_name
 ORDER BY SUM(IF(ibp.compressed_size = 0, 16384, compressed_size)) DESC;
-- Copyright (c) 2014, 2024, Oracle and/or its affiliates.
--
-- This program is free software; you can redistribute it and/or modify
-- it under the terms of the GNU General Public License as published by
-- the Free Software Foundation; version 2 of the License.
--
-- This program is distributed in the hope that it will be useful,
-- but WITHOUT ANY WARRANTY; without even the implied warranty of
-- MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
-- GNU General Public License for more details.
--
-- You should have received a copy of the GNU General Public License
-- along with this program; if not, write to the Free Software
-- Foundation, Inc., 51 Franklin St, Fifth Floor, Boston, MA 02110-1301 USA

--
-- View: schema_object_overview
-- 
-- Shows an overview of the types of objects within each schema
--
-- Note: On instances with a large number of objects, this could take
--       some time to execute, and is not recommended.
--
-- mysql> select * from schema_object_overview;
-- +---------------------------------+---------------+-------+
-- | db                              | object_type   | count |
-- +---------------------------------+---------------+-------+
-- | information_schema              | SYSTEM VIEW   |    59 |
-- | mem30_test__instruments         | BASE TABLE    |     1 |
-- | mem30_test__instruments         | INDEX (BTREE) |     2 |
-- | mem30_test__test                | BASE TABLE    |     9 |
-- | mem30_test__test                | INDEX (BTREE) |    19 |
-- ...
-- | sys                             | FUNCTION      |     8 |
-- | sys                             | PROCEDURE     |    16 |
-- | sys                             | VIEW          |    59 |
-- +---------------------------------+---------------+-------+
--

CREATE OR REPLACE
  ALGORITHM = TEMPTABLE
  DEFINER = 'mysql.sys'@'localhost'
  SQL SECURITY INVOKER 
VIEW schema_object_overview (
  db,
  object_type,
  count
) AS
SELECT ROUTINE_SCHEMA AS db, ROUTINE_TYPE AS object_type, COUNT(*) AS count FROM information_schema.routines GROUP BY ROUTINE_SCHEMA, ROUTINE_TYPE
 UNION 
SELECT TABLE_SCHEMA, TABLE_TYPE, COUNT(*) FROM information_schema.tables GROUP BY TABLE_SCHEMA, TABLE_TYPE
 UNION
SELECT TABLE_SCHEMA, CONCAT('INDEX (', INDEX_TYPE, ')'), COUNT(*) FROM information_schema.statistics GROUP BY TABLE_SCHEMA, INDEX_TYPE
 UNION
SELECT TRIGGER_SCHEMA, 'TRIGGER', COUNT(*) FROM information_schema.triggers GROUP BY TRIGGER_SCHEMA
 UNION
SELECT EVENT_SCHEMA, 'EVENT', COUNT(*) FROM information_schema.events GROUP BY EVENT_SCHEMA
ORDER BY DB, OBJECT_TYPE;
-- Copyright (c) 2015, 2024, Oracle and/or its affiliates.
--
-- This program is free software; you can redistribute it and/or modify
-- it under the terms of the GNU General Public License as published by
-- the Free Software Foundation; version 2 of the License.
--
-- This program is distributed in the hope that it will be useful,
-- but WITHOUT ANY WARRANTY; without even the implied warranty of
-- MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
-- GNU General Public License for more details.
--
-- You should have received a copy of the GNU General Public License
-- along with this program; if not, write to the Free Software
-- Foundation, Inc., 51 Franklin St, Fifth Floor, Boston, MA 02110-1301 USA

--
-- View: schema_auto_increment_columns
--
-- Present current auto_increment usage/capacity in all tables.
--
-- mysql> select * from schema_auto_increment_columns limit 5;
-- +-------------------+-------------------+-------------+-----------+-------------+-----------+-------------+---------------------+----------------+----------------------+
-- | table_schema      | table_name        | column_name | data_type | column_type | is_signed | is_unsigned | max_value           | auto_increment | auto_increment_ratio |
-- +-------------------+-------------------+-------------+-----------+-------------+-----------+-------------+---------------------+----------------+----------------------+
-- | test              | t1                | i           | tinyint   | tinyint     |         1 |           0 |                 127 |             34 |               0.2677 |
-- | mem__advisor_text | template_meta     | hib_id      | int       | int         |         1 |           0 |          2147483647 |            516 |               0.0000 |
-- | mem__advisors     | advisor_schedules | schedule_id | int       | int         |         1 |           0 |          2147483647 |            249 |               0.0000 |
-- | mem__advisors     | app_identity_path | hib_id      | int       | int         |         1 |           0 |          2147483647 |            251 |               0.0000 |
-- | mem__bean_config  | plists            | id          | bigint    | bigint      |         1 |           0 | 9223372036854775807 |              1 |               0.0000 |
-- +-------------------+-------------------+-------------+-----------+-------------+-----------+-------------+---------------------+----------------+----------------------+
--

CREATE OR REPLACE
  ALGORITHM = MERGE
  DEFINER = 'mysql.sys'@'localhost'
  SQL SECURITY INVOKER
VIEW schema_auto_increment_columns (
  table_schema,
  table_name,
  column_name,
  data_type,
  column_type,
  is_signed,
  is_unsigned,
  max_value,
  auto_increment,
  auto_increment_ratio
) AS
SELECT TABLE_SCHEMA,
       TABLE_NAME,
       COLUMN_NAME,
       DATA_TYPE,
       COLUMN_TYPE,
       (LOCATE('unsigned', COLUMN_TYPE) = 0) AS is_signed,
       (LOCATE('unsigned', COLUMN_TYPE) > 0) AS is_unsigned,
       (
          CASE DATA_TYPE
            WHEN 'tinyint' THEN 255
            WHEN 'smallint' THEN 65535
            WHEN 'mediumint' THEN 16777215
            WHEN 'int' THEN 4294967295
            WHEN 'bigint' THEN 18446744073709551615
          END >> IF(LOCATE('unsigned', COLUMN_TYPE) > 0, 0, 1)
       ) AS max_value,
       AUTO_INCREMENT,
       AUTO_INCREMENT / (
         CASE DATA_TYPE
           WHEN 'tinyint' THEN 255
           WHEN 'smallint' THEN 65535
           WHEN 'mediumint' THEN 16777215
           WHEN 'int' THEN 4294967295
           WHEN 'bigint' THEN 18446744073709551615
         END >> IF(LOCATE('unsigned', COLUMN_TYPE) > 0, 0, 1)
       ) AS auto_increment_ratio
  FROM INFORMATION_SCHEMA.COLUMNS
 INNER JOIN INFORMATION_SCHEMA.TABLES USING (TABLE_SCHEMA, TABLE_NAME)
 WHERE TABLE_SCHEMA NOT IN ('mysql', 'sys', 'INFORMATION_SCHEMA', 'performance_schema')
   AND TABLE_TYPE='BASE TABLE'
   AND EXTRA='auto_increment'
 ORDER BY auto_increment_ratio DESC, max_value;
-- Copyright (c) 2015, 2024, Oracle and/or its affiliates.
--
-- This program is free software; you can redistribute it and/or modify
-- it under the terms of the GNU General Public License as published by
-- the Free Software Foundation; version 2 of the License.
--
-- This program is distributed in the hope that it will be useful,
-- but WITHOUT ANY WARRANTY; without even the implied warranty of
-- MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
-- GNU General Public License for more details.
--
-- You should have received a copy of the GNU General Public License
-- along with this program; if not, write to the Free Software
-- Foundation, Inc., 51 Franklin St, Fifth Floor, Boston, MA 02110-1301 USA

--
-- View: x$schema_flattened_keys
--
-- Helper view for the schema_redundant_keys view.
--
-- mysql> select * from sys.x$schema_flattened_keys;
-- +---------------+---------------------+------------------------------+------------+----------------+-----------------+
-- | table_schema  | table_name          | index_name                   | non_unique | subpart_exists | index_columns   |
-- +---------------+---------------------+------------------------------+------------+----------------+-----------------+
-- | mem__advisors | advisor_initialized | PRIMARY                      |          0 |              0 | advisorClassId  |
-- | mem__advisors | advisor_schedules   | advisorClassIdIdx            |          1 |              0 | advisorClassId  |
-- | mem__advisors | advisor_schedules   | PRIMARY                      |          0 |              0 | schedule_id     |
-- | mem__advisors | app_identity_path   | FK_7xbq2i81hgo0xlvnb6rr77s21 |          1 |              0 | for_schedule_id |
-- | mem__advisors | app_identity_path   | PRIMARY                      |          0 |              0 | hib_id          |
-- ...
--

CREATE OR REPLACE
  ALGORITHM = TEMPTABLE
  DEFINER = 'mysql.sys'@'localhost'
  SQL SECURITY INVOKER
VIEW x$schema_flattened_keys (
  table_schema,
  table_name,
  index_name,
  non_unique,
  subpart_exists,
  index_columns
) AS
  SELECT
    TABLE_SCHEMA,
    TABLE_NAME,
    INDEX_NAME,
    MAX(NON_UNIQUE) AS non_unique,
    MAX(IF(SUB_PART IS NULL, 0, 1)) AS subpart_exists,
    GROUP_CONCAT(COLUMN_NAME ORDER BY SEQ_IN_INDEX) AS index_columns
  FROM INFORMATION_SCHEMA.STATISTICS
  WHERE
    INDEX_TYPE='BTREE'
    AND TABLE_SCHEMA NOT IN ('mysql', 'sys', 'INFORMATION_SCHEMA', 'PERFORMANCE_SCHEMA')
  GROUP BY
    TABLE_SCHEMA, TABLE_NAME, INDEX_NAME;
-- Copyright (c) 2015, 2024, Oracle and/or its affiliates.
--
-- This program is free software; you can redistribute it and/or modify
-- it under the terms of the GNU General Public License as published by
-- the Free Software Foundation; version 2 of the License.
--
-- This program is distributed in the hope that it will be useful,
-- but WITHOUT ANY WARRANTY; without even the implied warranty of
-- MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
-- GNU General Public License for more details.
--
-- You should have received a copy of the GNU General Public License
-- along with this program; if not, write to the Free Software
-- Foundation, Inc., 51 Franklin St, Fifth Floor, Boston, MA 02110-1301 USA

--
-- View: schema_redundant_keys
--
-- Shows indexes which are made redundant (or duplicate) by other (dominant) keys.
--
-- mysql> select * from sys.schema_redundant_indexes\G
-- *************************** 1. row ***************************
--               table_schema: test
--                 table_name: rkey
--       redundant_index_name: j
--    redundant_index_columns: j
-- redundant_index_non_unique: 1
--        dominant_index_name: j_2
--     dominant_index_columns: j,k
--  dominant_index_non_unique: 1
--             subpart_exists: 0
--             sql_drop_index: ALTER TABLE `test`.`rkey` DROP INDEX `j`
-- 1 row in set (0.20 sec)
-- 
-- mysql> SHOW CREATE TABLE test.rkey\G
-- *************************** 1. row ***************************
--        Table: rkey
-- Create Table: CREATE TABLE `rkey` (
--   `i` int NOT NULL,
--   `j` int DEFAULT NULL,
--   `k` int DEFAULT NULL,
--   PRIMARY KEY (`i`),
--   KEY `j` (`j`),
--   KEY `j_2` (`j`,`k`)
-- ) ENGINE=InnoDB DEFAULT CHARSET=latin1
-- 1 row in set (0.06 sec)
-- 

CREATE OR REPLACE
  ALGORITHM = TEMPTABLE
  DEFINER = 'mysql.sys'@'localhost'
  SQL SECURITY INVOKER
VIEW schema_redundant_indexes (
  table_schema,
  table_name,
  redundant_index_name,
  redundant_index_columns,
  redundant_index_non_unique,
  dominant_index_name,
  dominant_index_columns,
  dominant_index_non_unique,
  subpart_exists,
  sql_drop_index
) AS
  SELECT
    redundant_keys.table_schema,
    redundant_keys.table_name,
    redundant_keys.index_name AS redundant_index_name,
    redundant_keys.index_columns AS redundant_index_columns,
    redundant_keys.non_unique AS redundant_index_non_unique,
    dominant_keys.index_name AS dominant_index_name,
    dominant_keys.index_columns AS dominant_index_columns,
    dominant_keys.non_unique AS dominant_index_non_unique,
    IF(redundant_keys.subpart_exists OR dominant_keys.subpart_exists, 1 ,0) AS subpart_exists,
    CONCAT(
      'ALTER TABLE `', redundant_keys.table_schema, '`.`', redundant_keys.table_name, '` DROP INDEX `', redundant_keys.index_name, '`'
      ) AS sql_drop_index
  FROM
    x$schema_flattened_keys AS redundant_keys
    INNER JOIN x$schema_flattened_keys AS dominant_keys
    USING (TABLE_SCHEMA, TABLE_NAME)
  WHERE
    redundant_keys.index_name != dominant_keys.index_name
    AND (
      ( 
        /* Identical columns */
        (redundant_keys.index_columns = dominant_keys.index_columns)
        AND (
          (redundant_keys.non_unique > dominant_keys.non_unique)
          OR (redundant_keys.non_unique = dominant_keys.non_unique 
          	AND IF(redundant_keys.index_name='PRIMARY', '', redundant_keys.index_name) > IF(dominant_keys.index_name='PRIMARY', '', dominant_keys.index_name)
          )
        )
      )
      OR
      ( 
        /* Non-unique prefix columns */
        LOCATE(CONCAT(redundant_keys.index_columns, ','), dominant_keys.index_columns) = 1
        AND redundant_keys.non_unique = 1
      )
      OR
      ( 
        /* Unique prefix columns */
        LOCATE(CONCAT(dominant_keys.index_columns, ','), redundant_keys.index_columns) = 1
        AND dominant_keys.non_unique = 0
      )
    );
-- Copyright (c) 2014, 2024, Oracle and/or its affiliates.
--
-- This program is free software; you can redistribute it and/or modify
-- it under the terms of the GNU General Public License as published by
-- the Free Software Foundation; version 2 of the License.
--
-- This program is distributed in the hope that it will be useful,
-- but WITHOUT ANY WARRANTY; without even the implied warranty of
-- MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
-- GNU General Public License for more details.
--
-- You should have received a copy of the GNU General Public License
-- along with this program; if not, write to the Free Software
-- Foundation, Inc., 51 Franklin St, Fifth Floor, Boston, MA 02110-1301 USA

--
-- View: ps_check_lost_instrumentation
-- 
-- Used to check whether Performance Schema is not able to monitor
-- all runtime data - only returns variables that have lost instruments
--
-- mysql> select * from ps_check_lost_instrumentation;
-- +----------------------------------------+----------------+
-- | variable_name                          | variable_value |
-- +----------------------------------------+----------------+
-- | Performance_schema_file_handles_lost   | 101223         |
-- | Performance_schema_file_instances_lost | 1231           |
-- +----------------------------------------+----------------+
--

CREATE OR REPLACE
  ALGORITHM = MERGE
  DEFINER = 'mysql.sys'@'localhost'
  SQL SECURITY INVOKER 
VIEW ps_check_lost_instrumentation (
  variable_name,
  variable_value
)
AS
SELECT variable_name, variable_value
  FROM performance_schema.global_status
 WHERE variable_name LIKE 'perf%lost'
   AND variable_value > 0;
-- Copyright (c) 2014, 2024, Oracle and/or its affiliates.
--
-- This program is free software; you can redistribute it and/or modify
-- it under the terms of the GNU General Public License as published by
-- the Free Software Foundation; version 2 of the License.
--
-- This program is distributed in the hope that it will be useful,
-- but WITHOUT ANY WARRANTY; without even the implied warranty of
-- MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
-- GNU General Public License for more details.
--
-- You should have received a copy of the GNU General Public License
-- along with this program; if not, write to the Free Software
-- Foundation, Inc., 51 Franklin St, Fifth Floor, Boston, MA 02110-1301 USA

--
-- View: latest_file_io
--
-- Shows the latest file IO, by file / thread.
--
-- mysql> select * from latest_file_io limit 5;
-- +----------------------+----------------------------------------+------------+-----------+-----------+
-- | thread               | file                                   | latency    | operation | requested |
-- +----------------------+----------------------------------------+------------+-----------+-----------+
-- | msandbox@localhost:1 | @@tmpdir/#sqlcf28_1_4e.MYI             | 9.26 us    | write     | 124 bytes |
-- | msandbox@localhost:1 | @@tmpdir/#sqlcf28_1_4e.MYI             | 4.00 us    | write     | 2 bytes   |
-- | msandbox@localhost:1 | @@tmpdir/#sqlcf28_1_4e.MYI             | 56.34 us   | close     | NULL      |
-- | msandbox@localhost:1 | @@tmpdir/#sqlcf28_1_4e.MYD             | 53.93 us   | close     | NULL      |
-- | msandbox@localhost:1 | @@tmpdir/#sqlcf28_1_4e.MYI             | 104.05 ms  | delete    | NULL      |
-- +----------------------+----------------------------------------+------------+-----------+-----------+
--

CREATE OR REPLACE
  ALGORITHM = MERGE
  DEFINER = 'mysql.sys'@'localhost'
  SQL SECURITY INVOKER 
VIEW latest_file_io (
  thread,
  file,
  latency,
  operation,
  requested
) AS
SELECT IF(id IS NULL, 
             CONCAT(SUBSTRING_INDEX(name, '/', -1), ':', thread_id), 
             CONCAT(user, '@', host, ':', id)
          ) thread, 
       sys.format_path(object_name) file, 
       format_pico_time(timer_wait) AS latency, 
       operation, 
       format_bytes(number_of_bytes) AS requested
  FROM performance_schema.events_waits_history_long 
  JOIN performance_schema.threads USING (thread_id)
  LEFT JOIN information_schema.processlist ON processlist_id = id
 WHERE object_name IS NOT NULL
   AND event_name LIKE 'wait/io/file/%'
 ORDER BY timer_start;
-- Copyright (c) 2014, 2024, Oracle and/or its affiliates.
--
-- This program is free software; you can redistribute it and/or modify
-- it under the terms of the GNU General Public License as published by
-- the Free Software Foundation; version 2 of the License.
--
-- This program is distributed in the hope that it will be useful,
-- but WITHOUT ANY WARRANTY; without even the implied warranty of
-- MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
-- GNU General Public License for more details.
--
-- You should have received a copy of the GNU General Public License
-- along with this program; if not, write to the Free Software
-- Foundation, Inc., 51 Franklin St, Fifth Floor, Boston, MA 02110-1301 USA

--
-- View: x$latest_file_io
--
-- Shows the latest file IO, by file / thread.
--
-- mysql> SELECT * FROM x$latest_file_io LIMIT 5;
-- +------------------+------------------------------------------------------------------------------------+-------------+-----------+-----------+
-- | thread           | file                                                                               | latency     | operation | requested |
-- +------------------+------------------------------------------------------------------------------------+-------------+-----------+-----------+
-- | root@localhost:6 | /Users/mark/sandboxes/msb_5_7_2/data/ps_helper/user_summary_by_statement_type.frm~ |    26152490 | write     |      4210 |
-- | root@localhost:6 | /Users/mark/sandboxes/msb_5_7_2/data/ps_helper/user_summary_by_statement_type.frm~ | 30062722690 | sync      |      NULL |
-- | root@localhost:6 | /Users/mark/sandboxes/msb_5_7_2/data/ps_helper/user_summary_by_statement_type.frm~ |    34144890 | close     |      NULL |
-- | root@localhost:6 | /Users/mark/sandboxes/msb_5_7_2/data/ps_helper/check_lost_instrumentation.frm      |   113001980 | open      |      NULL |
-- | root@localhost:6 | /Users/mark/sandboxes/msb_5_7_2/data/ps_helper/check_lost_instrumentation.frm      |     9553180 | read      |        10 |
-- +------------------+------------------------------------------------------------------------------------+-------------+-----------+-----------+
--

CREATE OR REPLACE
  ALGORITHM = MERGE
  DEFINER = 'mysql.sys'@'localhost'
  SQL SECURITY INVOKER 
VIEW x$latest_file_io (
  thread,
  file,
  latency,
  operation,
  requested
) AS
SELECT IF(id IS NULL, 
             CONCAT(SUBSTRING_INDEX(name, '/', -1), ':', thread_id), 
             CONCAT(user, '@', host, ':', id)
          ) thread, 
       object_name file, 
       timer_wait AS latency, 
       operation, 
       number_of_bytes AS requested
  FROM performance_schema.events_waits_history_long 
  JOIN performance_schema.threads USING (thread_id)
  LEFT JOIN information_schema.processlist ON processlist_id = id
 WHERE object_name IS NOT NULL
   AND event_name LIKE 'wait/io/file/%'
 ORDER BY timer_start;
-- Copyright (c) 2014, 2024, Oracle and/or its affiliates.
--
-- This program is free software; you can redistribute it and/or modify
-- it under the terms of the GNU General Public License as published by
-- the Free Software Foundation; version 2 of the License.
--
-- This program is distributed in the hope that it will be useful,
-- but WITHOUT ANY WARRANTY; without even the implied warranty of
-- MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
-- GNU General Public License for more details.
--
-- You should have received a copy of the GNU General Public License
-- along with this program; if not, write to the Free Software
-- Foundation, Inc., 51 Franklin St, Fifth Floor, Boston, MA 02110-1301 USA

--
-- View: io_by_thread_by_latency
--
-- Show the top IO consumers by thread, ordered by total latency
--
-- mysql> select * from io_by_thread_by_latency;
-- +---------------------+-------+---------------+-------------+-------------+-------------+-----------+----------------+
-- | user                | total | total_latency | min_latency | avg_latency | max_latency | thread_id | processlist_id |
-- +---------------------+-------+---------------+-------------+-------------+-------------+-----------+----------------+
-- | root@localhost      | 11580 | 18.01 s       | 429.78 ns   | 1.12 ms     | 181.07 ms   |        25 |              6 |
-- | main                |  1358 | 1.31 s        | 475.02 ns   | 2.27 ms     | 350.70 ms   |         1 |           NULL |
-- | page_cleaner_thread |   654 | 147.44 ms     | 588.12 ns   | 225.44 us   | 46.41 ms    |        18 |           NULL |
-- | io_write_thread     |   131 | 107.75 ms     | 8.60 us     | 822.55 us   | 27.69 ms    |         8 |           NULL |
-- | io_write_thread     |    46 | 47.07 ms      | 10.64 us    | 1.02 ms     | 16.90 ms    |         9 |           NULL |
-- | io_write_thread     |    71 | 46.99 ms      | 9.11 us     | 661.81 us   | 17.04 ms    |        11 |           NULL |
-- | io_log_thread       |    20 | 21.01 ms      | 14.25 us    | 1.05 ms     | 7.08 ms     |         3 |           NULL |
-- | srv_master_thread   |    13 | 17.60 ms      | 8.49 us     | 1.35 ms     | 9.99 ms     |        16 |           NULL |
-- | srv_purge_thread    |     4 | 1.81 ms       | 34.31 us    | 452.45 us   | 1.02 ms     |        17 |           NULL |
-- | io_write_thread     |    19 | 951.39 us     | 9.75 us     | 50.07 us    | 297.47 us   |        10 |           NULL |
-- | signal_handler      |     3 | 218.03 us     | 21.64 us    | 72.68 us    | 154.84 us   |        19 |           NULL |
-- +---------------------+-------+---------------+-------------+-------------+-------------+-----------+----------------+
--

CREATE OR REPLACE
  ALGORITHM = TEMPTABLE
  DEFINER = 'mysql.sys'@'localhost'
  SQL SECURITY INVOKER 
VIEW io_by_thread_by_latency (
  user,
  total,
  total_latency,
  min_latency,
  avg_latency,
  max_latency,
  thread_id,
  processlist_id
)
AS
SELECT IF(processlist_id IS NULL, 
             SUBSTRING_INDEX(name, '/', -1), 
             CONCAT(processlist_user, '@', processlist_host)
          ) user, 
       SUM(count_star) total,
       format_pico_time(SUM(sum_timer_wait)) total_latency,
       format_pico_time(MIN(min_timer_wait)) min_latency,
       format_pico_time(AVG(avg_timer_wait)) avg_latency,
       format_pico_time(MAX(max_timer_wait)) max_latency,
       thread_id,
       processlist_id
  FROM performance_schema.events_waits_summary_by_thread_by_event_name 
  LEFT JOIN performance_schema.threads USING (thread_id)
 WHERE event_name LIKE 'wait/io/file/%'
   AND sum_timer_wait > 0
 GROUP BY thread_id, processlist_id, user
 ORDER BY SUM(sum_timer_wait) DESC;
-- Copyright (c) 2014, 2024, Oracle and/or its affiliates.
--
-- This program is free software; you can redistribute it and/or modify
-- it under the terms of the GNU General Public License as published by
-- the Free Software Foundation; version 2 of the License.
--
-- This program is distributed in the hope that it will be useful,
-- but WITHOUT ANY WARRANTY; without even the implied warranty of
-- MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
-- GNU General Public License for more details.
--
-- You should have received a copy of the GNU General Public License
-- along with this program; if not, write to the Free Software
-- Foundation, Inc., 51 Franklin St, Fifth Floor, Boston, MA 02110-1301 USA

--
-- View: x$io_by_thread_by_latency
--
-- Show the top IO consumers by thread, ordered by total latency
--
-- mysql> select * from x$io_by_thread_by_latency;
-- +---------------------+-------+----------------+-------------+-----------------+--------------+-----------+----------------+
-- | user                | total | total_latency  | min_latency | avg_latency     | max_latency  | thread_id | processlist_id |
-- +---------------------+-------+----------------+-------------+-----------------+--------------+-----------+----------------+
-- | root@localhost      | 11587 | 18007539905680 |      429780 | 1120831681.6667 | 181065665560 |        25 |              6 |
-- | main                |  1358 |  1309001741320 |      475020 | 2269581997.8000 | 350700491310 |         1 |           NULL |
-- | page_cleaner_thread |   654 |   147435455960 |      588120 |  225436198.0000 |  46412043990 |        18 |           NULL |
-- | io_write_thread     |   131 |   107754483070 |     8603140 |  822553303.0000 |  27691592500 |         8 |           NULL |
-- | io_write_thread     |    46 |    47074926860 |    10642710 | 1023367631.0000 |  16899745070 |         9 |           NULL |
-- | io_write_thread     |    71 |    46988801210 |     9108320 |  661814075.0000 |  17042760020 |        11 |           NULL |
-- | io_log_thread       |    20 |    21007710490 |    14250600 | 1050385336.0000 |   7081255090 |         3 |           NULL |
-- | srv_master_thread   |    13 |    17601511720 |     8486270 | 1353962324.0000 |   9990100380 |        16 |           NULL |
-- | srv_purge_thread    |     4 |     1809792270 |    34307000 |  452447879.0000 |   1018887740 |        17 |           NULL |
-- | io_write_thread     |    19 |      951385890 |     9745450 |   50072763.0000 |    297468080 |        10 |           NULL |
-- | signal_handler      |     3 |      218026640 |    21639800 |   72675421.0000 |    154841440 |        19 |           NULL |
-- +---------------------+-------+----------------+-------------+-----------------+--------------+-----------+----------------+
--

CREATE OR REPLACE
  ALGORITHM = TEMPTABLE
  DEFINER = 'mysql.sys'@'localhost'
  SQL SECURITY INVOKER 
VIEW x$io_by_thread_by_latency (
  user,
  total,
  total_latency,
  min_latency,
  avg_latency,
  max_latency,
  thread_id,
  processlist_id
)
AS
SELECT IF(processlist_id IS NULL, 
             SUBSTRING_INDEX(name, '/', -1), 
             CONCAT(processlist_user, '@', processlist_host)
          ) user, 
       SUM(count_star) total,
       SUM(sum_timer_wait) total_latency,
       MIN(min_timer_wait) min_latency,
       AVG(avg_timer_wait) avg_latency,
       MAX(max_timer_wait) max_latency,
       thread_id,
       processlist_id
  FROM performance_schema.events_waits_summary_by_thread_by_event_name 
  LEFT JOIN performance_schema.threads USING (thread_id)
 WHERE event_name LIKE 'wait/io/file/%'
   AND sum_timer_wait > 0
 GROUP BY thread_id, processlist_id, user
 ORDER BY SUM(sum_timer_wait) DESC;
-- Copyright (c) 2014, 2024, Oracle and/or its affiliates.
--
-- This program is free software; you can redistribute it and/or modify
-- it under the terms of the GNU General Public License as published by
-- the Free Software Foundation; version 2 of the License.
--
-- This program is distributed in the hope that it will be useful,
-- but WITHOUT ANY WARRANTY; without even the implied warranty of
-- MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
-- GNU General Public License for more details.
--
-- You should have received a copy of the GNU General Public License
-- along with this program; if not, write to the Free Software
-- Foundation, Inc., 51 Franklin St, Fifth Floor, Boston, MA 02110-1301 USA

--
-- View: io_global_by_file_by_bytes
--
-- Shows the top global IO consumers by bytes usage by file.
--
-- mysql> SELECT * FROM io_global_by_file_by_bytes LIMIT 5;
-- +--------------------------------------------+------------+------------+-----------+-------------+---------------+-----------+------------+-----------+
-- | file                                       | count_read | total_read | avg_read  | count_write | total_written | avg_write | total      | write_pct |
-- +--------------------------------------------+------------+------------+-----------+-------------+---------------+-----------+------------+-----------+
-- | @@datadir/ibdata1                          |        147 | 4.27 MiB   | 29.71 KiB |           3 | 48.00 KiB     | 16.00 KiB | 4.31 MiB   |      1.09 |
-- | @@datadir/mysql/proc.MYD                   |        347 | 85.35 KiB  | 252 bytes |         111 | 19.08 KiB     | 176 bytes | 104.43 KiB |     18.27 |
-- | @@datadir/#innodb_redo/#ib_redo0           |          6 | 68.00 KiB  | 11.33 KiB |           8 | 4.00 KiB      | 512 bytes | 72.00 KiB  |      5.56 |
-- | /opt/mysql/5.5.33/share/english/errmsg.sys |          3 | 43.68 KiB  | 14.56 KiB |           0 | 0 bytes       | 0 bytes   | 43.68 KiB  |      0.00 |
-- | /opt/mysql/5.5.33/share/charsets/Index.xml |          1 | 17.89 KiB  | 17.89 KiB |           0 | 0 bytes       | 0 bytes   | 17.89 KiB  |      0.00 |
-- +--------------------------------------------+------------+------------+-----------+-------------+---------------+-----------+------------+-----------+
--

CREATE OR REPLACE
  ALGORITHM = MERGE
  DEFINER = 'mysql.sys'@'localhost'
  SQL SECURITY INVOKER 
VIEW io_global_by_file_by_bytes (
  file,
  count_read,
  total_read,
  avg_read,
  count_write,
  total_written,
  avg_write,
  total,
  write_pct
) AS
SELECT sys.format_path(file_name) AS file, 
       count_read, 
       format_bytes(sum_number_of_bytes_read) AS total_read,
       format_bytes(IFNULL(sum_number_of_bytes_read / NULLIF(count_read, 0), 0)) AS avg_read,
       count_write, 
       format_bytes(sum_number_of_bytes_write) AS total_written,
       format_bytes(IFNULL(sum_number_of_bytes_write / NULLIF(count_write, 0), 0.00)) AS avg_write,
       format_bytes(sum_number_of_bytes_read + sum_number_of_bytes_write) AS total, 
       IFNULL(ROUND(100-((sum_number_of_bytes_read/ NULLIF((sum_number_of_bytes_read+sum_number_of_bytes_write), 0))*100), 2), 0.00) AS write_pct 
  FROM performance_schema.file_summary_by_instance
 ORDER BY sum_number_of_bytes_read + sum_number_of_bytes_write DESC;
-- Copyright (c) 2014, 2024, Oracle and/or its affiliates.
--
-- This program is free software; you can redistribute it and/or modify
-- it under the terms of the GNU General Public License as published by
-- the Free Software Foundation; version 2 of the License.
--
-- This program is distributed in the hope that it will be useful,
-- but WITHOUT ANY WARRANTY; without even the implied warranty of
-- MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
-- GNU General Public License for more details.
--
-- You should have received a copy of the GNU General Public License
-- along with this program; if not, write to the Free Software
-- Foundation, Inc., 51 Franklin St, Fifth Floor, Boston, MA 02110-1301 USA

--
-- View: x$io_global_by_file_by_bytes
--
-- Shows the top global IO consumers by bytes usage by file.
--
-- mysql> SELECT * FROM x$io_global_by_file_by_bytes LIMIT 5;
-- +--------------------------------------------------------------+------------+------------+------------+-------------+---------------+------------+---------+-----------+
-- | file                                                         | count_read | total_read | avg_read   | count_write | total_written | avg_write  | total   | write_pct |
-- +--------------------------------------------------------------+------------+------------+------------+-------------+---------------+------------+---------+-----------+
-- | /Users/mark/sandboxes/msb_5_5_33/data/ibdata1                |        147 |    4472832 | 30427.4286 |           3 |         49152 | 16384.0000 | 4521984 |      1.09 |
-- | /Users/mark/sandboxes/msb_5_5_33/data/mysql/proc.MYD         |        347 |      87397 |   251.8646 |         111 |         19536 |   176.0000 |  106933 |     18.27 |
-- | /Users/mark/sandboxes/msb_5_5_33/data/#innodb_redo/#ib_redo0 |          6 |      69632 | 11605.3333 |           8 |          4096 |   512.0000 |   73728 |      5.56 |
-- | /opt/mysql/5.5.33/share/english/errmsg.sys                   |          3 |      44724 | 14908.0000 |           0 |             0 |     0.0000 |   44724 |      0.00 |
-- | /opt/mysql/5.5.33/share/charsets/Index.xml                   |          1 |      18317 | 18317.0000 |           0 |             0 |     0.0000 |   18317 |      0.00 |
-- +--------------------------------------------------------------+------------+------------+------------+-------------+---------------+------------+---------+-----------+
--

CREATE OR REPLACE
  ALGORITHM = MERGE
  DEFINER = 'mysql.sys'@'localhost'
  SQL SECURITY INVOKER 
VIEW x$io_global_by_file_by_bytes (
  file,
  count_read,
  total_read,
  avg_read,
  count_write,
  total_written,
  avg_write,
  total,
  write_pct
) AS
SELECT file_name AS file, 
       count_read, 
       sum_number_of_bytes_read AS total_read,
       IFNULL(sum_number_of_bytes_read / NULLIF(count_read, 0), 0) AS avg_read,
       count_write, 
       sum_number_of_bytes_write AS total_written,
       IFNULL(sum_number_of_bytes_write / NULLIF(count_write, 0), 0.00) AS avg_write,
       sum_number_of_bytes_read + sum_number_of_bytes_write AS total, 
       IFNULL(ROUND(100-((sum_number_of_bytes_read/ NULLIF((sum_number_of_bytes_read+sum_number_of_bytes_write), 0))*100), 2), 0.00) AS write_pct 
  FROM performance_schema.file_summary_by_instance
 ORDER BY sum_number_of_bytes_read + sum_number_of_bytes_write DESC;
-- Copyright (c) 2014, 2024, Oracle and/or its affiliates.
--
-- This program is free software; you can redistribute it and/or modify
-- it under the terms of the GNU General Public License as published by
-- the Free Software Foundation; version 2 of the License.
--
-- This program is distributed in the hope that it will be useful,
-- but WITHOUT ANY WARRANTY; without even the implied warranty of
-- MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
-- GNU General Public License for more details.
--
-- You should have received a copy of the GNU General Public License
-- along with this program; if not, write to the Free Software
-- Foundation, Inc., 51 Franklin St, Fifth Floor, Boston, MA 02110-1301 USA

--
-- View: io_global_by_file_by_latency
--
-- Shows the top global IO consumers by latency by file.
--
-- mysql> select * from io_global_by_file_by_latency limit 5;
-- +-----------------------------------------------------------+-------+---------------+------------+--------------+-------------+---------------+------------+--------------+
-- | file                                                      | total | total_latency | count_read | read_latency | count_write | write_latency | count_misc | misc_latency |
-- +-----------------------------------------------------------+-------+---------------+------------+--------------+-------------+---------------+------------+--------------+
-- | @@datadir/sys/wait_classes_global_by_avg_latency_raw.frm~ |    24 | 451.99 ms     |          0 | 0 ps         |           4 | 108.07 us     |         20 | 451.88 ms    |
-- | @@datadir/sys/innodb_buffer_stats_by_schema_raw.frm~      |    24 | 379.84 ms     |          0 | 0 ps         |           4 | 108.88 us     |         20 | 379.73 ms    |
-- | @@datadir/sys/io_by_thread_by_latency_raw.frm~            |    24 | 379.46 ms     |          0 | 0 ps         |           4 | 101.37 us     |         20 | 379.36 ms    |
-- | @@datadir/ibtmp1                                          |    53 | 373.45 ms     |          0 | 0 ps         |          48 | 246.08 ms     |          5 | 127.37 ms    |
-- | @@datadir/sys/statement_analysis_raw.frm~                 |    24 | 353.14 ms     |          0 | 0 ps         |           4 | 94.96 us      |         20 | 353.04 ms    |
-- +-----------------------------------------------------------+-------+---------------+------------+--------------+-------------+---------------+------------+--------------+
--

CREATE OR REPLACE
  ALGORITHM = MERGE
  DEFINER = 'mysql.sys'@'localhost'
  SQL SECURITY INVOKER 
VIEW io_global_by_file_by_latency (
  file,
  total,
  total_latency,
  count_read,
  read_latency,
  count_write,
  write_latency,
  count_misc,
  misc_latency
) AS
SELECT sys.format_path(file_name) AS file, 
       count_star AS total, 
       format_pico_time(sum_timer_wait) AS total_latency,
       count_read,
       format_pico_time(sum_timer_read) AS read_latency,
       count_write,
       format_pico_time(sum_timer_write) AS write_latency,
       count_misc,
       format_pico_time(sum_timer_misc) AS misc_latency
  FROM performance_schema.file_summary_by_instance
 ORDER BY sum_timer_wait DESC;
-- Copyright (c) 2014, 2024, Oracle and/or its affiliates.
--
-- This program is free software; you can redistribute it and/or modify
-- it under the terms of the GNU General Public License as published by
-- the Free Software Foundation; version 2 of the License.
--
-- This program is distributed in the hope that it will be useful,
-- but WITHOUT ANY WARRANTY; without even the implied warranty of
-- MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
-- GNU General Public License for more details.
--
-- You should have received a copy of the GNU General Public License
-- along with this program; if not, write to the Free Software
-- Foundation, Inc., 51 Franklin St, Fifth Floor, Boston, MA 02110-1301 USA

--
-- View: x$io_global_by_file_by_latency
--
-- Shows the top global IO consumers by latency by file.
--
-- mysql> select * from x$io_global_by_file_by_latency limit 5;
-- +--------------------------------------------------------------------------------------+-------+---------------+------------+--------------+-------------+---------------+------------+--------------+
-- | file                                                                                 | total | total_latency | count_read | read_latency | count_write | write_latency | count_misc | misc_latency |
-- +--------------------------------------------------------------------------------------+-------+---------------+------------+--------------+-------------+---------------+------------+--------------+
-- | /Users/mark/sandboxes/msb_5_7_2/data/sys/wait_classes_global_by_avg_latency_raw.frm~ |    30 |  513959738110 |          0 |            0 |           5 |     132130960 |         25 | 513827607150 |
-- | /Users/mark/sandboxes/msb_5_7_2/data/sys/innodb_buffer_stats_by_schema_raw.frm~      |    30 |  490149888410 |          0 |            0 |           5 |     483887040 |         25 | 489666001370 |
-- | /Users/mark/sandboxes/msb_5_7_2/data/sys/io_by_thread_by_latency_raw.frm~            |    30 |  427724241620 |          0 |            0 |           5 |     131399580 |         25 | 427592842040 |
-- | /Users/mark/sandboxes/msb_5_7_2/data/sys/innodb_buffer_stats_by_schema.frm~          |    30 |  406392559950 |          0 |            0 |           5 |     104082160 |         25 | 406288477790 |
-- | /Users/mark/sandboxes/msb_5_7_2/data/sys/statement_analysis_raw.frm~                 |    30 |  395527510430 |          0 |            0 |           5 |     118724840 |         25 | 395408785590 |
-- +--------------------------------------------------------------------------------------+-------+---------------+------------+--------------+-------------+---------------+------------+--------------+
--

CREATE OR REPLACE
  ALGORITHM = MERGE
  DEFINER = 'mysql.sys'@'localhost'
  SQL SECURITY INVOKER 
VIEW x$io_global_by_file_by_latency (
  file,
  total,
  total_latency,
  count_read,
  read_latency,
  count_write,
  write_latency,
  count_misc,
  misc_latency
) AS
SELECT file_name AS file, 
       count_star AS total, 
       sum_timer_wait AS total_latency,
       count_read,
       sum_timer_read AS read_latency,
       count_write,
       sum_timer_write AS write_latency,
       count_misc,
       sum_timer_misc AS misc_latency
  FROM performance_schema.file_summary_by_instance
 ORDER BY sum_timer_wait DESC;
-- Copyright (c) 2014, 2024, Oracle and/or its affiliates.
--
-- This program is free software; you can redistribute it and/or modify
-- it under the terms of the GNU General Public License as published by
-- the Free Software Foundation; version 2 of the License.
--
-- This program is distributed in the hope that it will be useful,
-- but WITHOUT ANY WARRANTY; without even the implied warranty of
-- MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
-- GNU General Public License for more details.
--
-- You should have received a copy of the GNU General Public License
-- along with this program; if not, write to the Free Software
-- Foundation, Inc., 51 Franklin St, Fifth Floor, Boston, MA 02110-1301 USA

--
-- View: io_global_by_wait_by_bytes
--
-- Shows the top global IO consumer classes by bytes usage.
--
-- mysql> select * from io_global_by_wait_by_bytes;
-- +--------------------+--------+---------------+-------------+-------------+-------------+------------+------------+-----------+-------------+---------------+-------------+-----------------+
-- | event_name         | total  | total_latency | min_latency | avg_latency | max_latency | count_read | total_read | avg_read  | count_write | total_written | avg_written | total_requested |
-- +--------------------+--------+---------------+-------------+-------------+-------------+------------+------------+-----------+-------------+---------------+-------------+-----------------+
-- | myisam/dfile       | 163681 | 983.13 ms     | 379.08 ns   | 6.01 us     | 22.06 ms    |      68737 | 127.31 MiB | 1.90 KiB  |     1012221 | 121.52 MiB    | 126 bytes   | 248.83 MiB      |
-- | myisam/kfile       |   1775 | 375.13 ms     | 1.02 us     | 211.34 us   | 35.15 ms    |      54066 | 9.97 MiB   | 193 bytes |      428257 | 12.40 MiB     | 30 bytes    | 22.37 MiB       |
-- | sql/FRM            |  57889 | 8.40 s        | 19.44 ns    | 145.05 us   | 336.71 ms   |       8009 | 2.60 MiB   | 341 bytes |       14675 | 2.91 MiB      | 208 bytes   | 5.51 MiB        |
-- | sql/global_ddl_log |    164 | 75.96 ms      | 5.72 us     | 463.19 us   | 7.43 ms     |         20 | 80.00 KiB  | 4.00 KiB  |          76 | 304.00 KiB    | 4.00 KiB    | 384.00 KiB      |
-- | sql/file_parser    |    419 | 601.37 ms     | 1.96 us     | 1.44 ms     | 37.14 ms    |         66 | 42.01 KiB  | 652 bytes |          64 | 226.98 KiB    | 3.55 KiB    | 268.99 KiB      |
-- | sql/binlog         |    190 | 6.79 s        | 1.56 us     | 35.76 ms    | 4.21 s      |         52 | 60.54 KiB  | 1.16 KiB  |           0 | 0 bytes       | 0 bytes     | 60.54 KiB       |
-- | sql/ERRMSG         |      5 | 2.03 s        | 8.61 us     | 405.40 ms   | 2.03 s      |          3 | 51.82 KiB  | 17.27 KiB |           0 | 0 bytes       | 0 bytes     | 51.82 KiB       |
-- | mysys/charset      |      3 | 196.52 us     | 17.61 us    | 65.51 us    | 137.33 us   |          1 | 17.83 KiB  | 17.83 KiB |           0 | 0 bytes       | 0 bytes     | 17.83 KiB       |
-- | sql/partition      |     81 | 18.87 ms      | 888.08 ns   | 232.92 us   | 4.67 ms     |         66 | 2.75 KiB   | 43 bytes  |           8 | 288 bytes     | 36 bytes    | 3.04 KiB        |
-- | sql/dbopt          | 329166 | 26.95 s       | 2.06 us     | 81.89 us    | 178.71 ms   |          0 | 0 bytes    | 0 bytes   |           9 | 585 bytes     | 65 bytes    | 585 bytes       |
-- | sql/relaylog       |      7 | 1.18 ms       | 838.84 ns   | 168.30 us   | 892.70 us   |          0 | 0 bytes    | 0 bytes   |           1 | 120 bytes     | 120 bytes   | 120 bytes       |
-- | mysys/cnf          |      5 | 171.61 us     | 303.26 ns   | 34.32 us    | 115.21 us   |          3 | 56 bytes   | 19 bytes  |           0 | 0 bytes       | 0 bytes     | 56 bytes        |
-- | sql/pid            |      3 | 220.55 us     | 29.29 us    | 73.52 us    | 143.11 us   |          0 | 0 bytes    | 0 bytes   |           1 | 5 bytes       | 5 bytes     | 5 bytes         |
-- | sql/casetest       |      1 | 121.19 us     | 121.19 us   | 121.19 us   | 121.19 us   |          0 | 0 bytes    | 0 bytes   |           0 | 0 bytes       | 0 bytes     | 0 bytes         |
-- | sql/binlog_index   |      5 | 593.47 us     | 1.07 us     | 118.69 us   | 535.90 us   |          0 | 0 bytes    | 0 bytes   |           0 | 0 bytes       | 0 bytes     | 0 bytes         |
-- | sql/misc           |     23 | 2.73 ms       | 65.14 us    | 118.50 us   | 255.31 us   |          0 | 0 bytes    | 0 bytes   |           0 | 0 bytes       | 0 bytes     | 0 bytes         |
-- +--------------------+--------+---------------+-------------+-------------+-------------+------------+------------+-----------+-------------+---------------+-------------+-----------------+
--

CREATE OR REPLACE
  ALGORITHM = MERGE
  DEFINER = 'mysql.sys'@'localhost'
  SQL SECURITY INVOKER 
VIEW io_global_by_wait_by_bytes (
  event_name,
  total,
  total_latency,
  min_latency,
  avg_latency,
  max_latency,
  count_read,
  total_read,
  avg_read,
  count_write,
  total_written,
  avg_written,
  total_requested
) AS
SELECT SUBSTRING_INDEX(event_name, '/', -2) event_name,
       count_star AS total,
       format_pico_time(sum_timer_wait) AS total_latency,
       format_pico_time(min_timer_wait) AS min_latency,
       format_pico_time(avg_timer_wait) AS avg_latency,
       format_pico_time(max_timer_wait) AS max_latency,
       count_read,
       format_bytes(sum_number_of_bytes_read) AS total_read,
       format_bytes(IFNULL(sum_number_of_bytes_read / NULLIF(count_read, 0), 0)) AS avg_read,
       count_write,
       format_bytes(sum_number_of_bytes_write) AS total_written,
       format_bytes(IFNULL(sum_number_of_bytes_write / NULLIF(count_write, 0), 0)) AS avg_written,
       format_bytes(sum_number_of_bytes_write + sum_number_of_bytes_read) AS total_requested
  FROM performance_schema.file_summary_by_event_name
 WHERE event_name LIKE 'wait/io/file/%' 
   AND count_star > 0
 ORDER BY sum_number_of_bytes_write + sum_number_of_bytes_read DESC;
-- Copyright (c) 2014, 2024, Oracle and/or its affiliates.
--
-- This program is free software; you can redistribute it and/or modify
-- it under the terms of the GNU General Public License as published by
-- the Free Software Foundation; version 2 of the License.
--
-- This program is distributed in the hope that it will be useful,
-- but WITHOUT ANY WARRANTY; without even the implied warranty of
-- MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
-- GNU General Public License for more details.
--
-- You should have received a copy of the GNU General Public License
-- along with this program; if not, write to the Free Software
-- Foundation, Inc., 51 Franklin St, Fifth Floor, Boston, MA 02110-1301 USA

--
-- View: x$io_global_by_wait_by_bytes
--
-- Shows the top global IO consumer classes by bytes usage.
--
-- mysql> select * from x$io_global_by_wait_by_bytes;
-- +-------------------------+-------+---------------+-------------+-------------+--------------+------------+------------+------------+-------------+---------------+-------------+-----------------+
-- | event_name              | total | total_latency | min_latency | avg_latency | max_latency  | count_read | total_read | avg_read   | count_write | total_written | avg_written | total_requested |
-- +-------------------------+-------+---------------+-------------+-------------+--------------+------------+------------+------------+-------------+---------------+-------------+-----------------+
-- | innodb/innodb_data_file |   151 |  334405721910 |     8399560 |  2214607429 | 107444600380 |        147 |    4472832 | 30427.4286 |           0 |             0 |      0.0000 |         4472832 |
-- | sql/FRM                 |   555 |  147752034170 |      674830 |   266219881 |  57705900850 |        270 |     112174 |   415.4593 |           0 |             0 |      0.0000 |          112174 |
-- | innodb/innodb_log_file  |    22 |   56776429970 |     2476890 |  2580746816 |  18883021430 |          6 |      69632 | 11605.3333 |           5 |          2560 |    512.0000 |           72192 |
-- | sql/ERRMSG              |     5 |   11862056180 |    14883960 |  2372411236 |  11109473700 |          3 |      44724 | 14908.0000 |           0 |             0 |      0.0000 |           44724 |
-- | mysys/charset           |     3 |    7256869230 |    19796270 |  2418956410 |   7198498320 |          1 |      18317 | 18317.0000 |           0 |             0 |      0.0000 |           18317 |
-- | myisam/kfile            |   135 |   10194698280 |      784160 |    75516283 |   2593514950 |         40 |       9216 |   230.4000 |          33 |          1017 |     30.8182 |           10233 |
-- | myisam/dfile            |    68 |   10527909730 |      772850 |   154822201 |   7600014630 |          9 |       6667 |   740.7778 |           0 |             0 |      0.0000 |            6667 |
-- | sql/pid                 |     3 |     216507330 |    41296580 |    72169110 |    100617530 |          0 |          0 |     0.0000 |           1 |             6 |      6.0000 |               6 |
-- | sql/casetest            |     5 |     185261570 |     4105530 |    37052314 |    113488310 |          0 |          0 |     0.0000 |           0 |             0 |      0.0000 |               0 |
-- | sql/global_ddl_log      |     2 |      21538010 |     3121560 |    10769005 |     18416450 |          0 |          0 |     0.0000 |           0 |             0 |      0.0000 |               0 |
-- | sql/dbopt               |    10 |    1004267680 |     1164930 |   100426768 |    939894930 |          0 |          0 |     0.0000 |           0 |             0 |      0.0000 |               0 |
-- +-------------------------+-------+---------------+-------------+-------------+--------------+------------+------------+------------+-------------+---------------+-------------+-----------------+
--

CREATE OR REPLACE
  ALGORITHM = MERGE
  DEFINER = 'mysql.sys'@'localhost'
  SQL SECURITY INVOKER 
VIEW x$io_global_by_wait_by_bytes (
  event_name,
  total,
  total_latency,
  min_latency,
  avg_latency,
  max_latency,
  count_read,
  total_read,
  avg_read,
  count_write,
  total_written,
  avg_written,
  total_requested
) AS
SELECT SUBSTRING_INDEX(event_name, '/', -2) AS event_name,
       count_star AS total,
       sum_timer_wait AS total_latency,
       min_timer_wait AS min_latency,
       avg_timer_wait AS avg_latency,
       max_timer_wait AS max_latency,
       count_read,
       sum_number_of_bytes_read AS total_read,
       IFNULL(sum_number_of_bytes_read / NULLIF(count_read, 0), 0) AS avg_read,
       count_write,
       sum_number_of_bytes_write AS total_written,
       IFNULL(sum_number_of_bytes_write / NULLIF(count_write, 0), 0) AS avg_written,
       sum_number_of_bytes_write + sum_number_of_bytes_read AS total_requested
  FROM performance_schema.file_summary_by_event_name
 WHERE event_name LIKE 'wait/io/file/%' 
   AND count_star > 0
 ORDER BY sum_number_of_bytes_write + sum_number_of_bytes_read DESC;
-- Copyright (c) 2014, 2024, Oracle and/or its affiliates.
--
-- This program is free software; you can redistribute it and/or modify
-- it under the terms of the GNU General Public License as published by
-- the Free Software Foundation; version 2 of the License.
--
-- This program is distributed in the hope that it will be useful,
-- but WITHOUT ANY WARRANTY; without even the implied warranty of
-- MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
-- GNU General Public License for more details.
--
-- You should have received a copy of the GNU General Public License
-- along with this program; if not, write to the Free Software
-- Foundation, Inc., 51 Franklin St, Fifth Floor, Boston, MA 02110-1301 USA

--
-- View: io_global_by_wait_by_latency
--
-- Shows the top global IO consumers by latency.
--
-- mysql> SELECT * FROM io_global_by_wait_by_latency;
-- +-------------------------+-------+---------------+-------------+-------------+--------------+---------------+--------------+------------+------------+-----------+-------------+---------------+-------------+
-- | event_name              | total | total_latency | avg_latency | max_latency | read_latency | write_latency | misc_latency | count_read | total_read | avg_read  | count_write | total_written | avg_written |
-- +-------------------------+-------+---------------+-------------+-------------+--------------+---------------+--------------+------------+------------+-----------+-------------+---------------+-------------+
-- | sql/file_parser         |  5433 | 30.20 s       | 5.56 ms     | 203.65 ms   | 22.08 ms     | 24.89 ms      | 30.16 s      |         24 | 6.18 KiB   | 264 bytes |         737 | 2.15 MiB      | 2.99 KiB    |
-- | innodb/innodb_data_file |  1344 | 1.52 s        | 1.13 ms     | 350.70 ms   | 203.82 ms    | 450.96 ms     | 868.21 ms    |        147 | 2.30 MiB   | 16.00 KiB |        1001 | 53.61 MiB     | 54.84 KiB   |
-- | innodb/innodb_log_file  |   828 | 893.48 ms     | 1.08 ms     | 30.11 ms    | 16.32 ms     | 705.89 ms     | 171.27 ms    |          6 | 68.00 KiB  | 11.33 KiB |         413 | 2.19 MiB      | 5.42 KiB    |
-- | myisam/kfile            |  7642 | 242.34 ms     | 31.71 us    | 19.27 ms    | 73.60 ms     | 23.48 ms      | 145.26 ms    |        758 | 135.63 KiB | 183 bytes |        4386 | 232.52 KiB    | 54 bytes    |
-- | myisam/dfile            | 12540 | 223.47 ms     | 17.82 us    | 32.50 ms    | 87.76 ms     | 16.97 ms      | 118.74 ms    |       5390 | 4.49 MiB   | 873 bytes |        1448 | 2.65 MiB      | 1.88 KiB    |
-- | csv/metadata            |     8 | 28.98 ms      | 3.62 ms     | 20.15 ms    | 399.27 us    | 0 ps          | 28.58 ms     |          2 | 70 bytes   | 35 bytes  |           0 | 0 bytes       | 0 bytes     |
-- | mysys/charset           |     3 | 24.24 ms      | 8.08 ms     | 24.15 ms    | 24.15 ms     | 0 ps          | 93.18 us     |          1 | 17.31 KiB  | 17.31 KiB |           0 | 0 bytes       | 0 bytes     |
-- | sql/ERRMSG              |     5 | 20.43 ms      | 4.09 ms     | 19.31 ms    | 20.32 ms     | 0 ps          | 103.20 us    |          3 | 58.97 KiB  | 19.66 KiB |           0 | 0 bytes       | 0 bytes     |
-- | mysys/cnf               |     5 | 11.37 ms      | 2.27 ms     | 11.28 ms    | 11.29 ms     | 0 ps          | 78.22 us     |          3 | 56 bytes   | 19 bytes  |           0 | 0 bytes       | 0 bytes     |
-- | sql/dbopt               |    57 | 4.04 ms       | 70.92 us    | 843.70 us   | 0 ps         | 186.43 us     | 3.86 ms      |          0 | 0 bytes    | 0 bytes   |           7 | 431 bytes     | 62 bytes    |
-- | csv/data                |     4 | 411.55 us     | 102.89 us   | 234.89 us   | 0 ps         | 0 ps          | 411.55 us    |          0 | 0 bytes    | 0 bytes   |           0 | 0 bytes       | 0 bytes     |
-- | sql/misc                |    22 | 340.38 us     | 15.47 us    | 33.77 us    | 0 ps         | 0 ps          | 340.38 us    |          0 | 0 bytes    | 0 bytes   |           0 | 0 bytes       | 0 bytes     |
-- | archive/data            |    39 | 277.86 us     | 7.12 us     | 16.18 us    | 0 ps         | 0 ps          | 277.86 us    |          0 | 0 bytes    | 0 bytes   |           0 | 0 bytes       | 0 bytes     |
-- | sql/pid                 |     3 | 218.03 us     | 72.68 us    | 154.84 us   | 0 ps         | 21.64 us      | 196.39 us    |          0 | 0 bytes    | 0 bytes   |           1 | 6 bytes       | 6 bytes     |
-- | sql/casetest            |     5 | 197.15 us     | 39.43 us    | 126.31 us   | 0 ps         | 0 ps          | 197.15 us    |          0 | 0 bytes    | 0 bytes   |           0 | 0 bytes       | 0 bytes     |
-- | sql/global_ddl_log      |     2 | 14.60 us      | 7.30 us     | 12.12 us    | 0 ps         | 0 ps          | 14.60 us     |          0 | 0 bytes    | 0 bytes   |           0 | 0 bytes       | 0 bytes     |
-- +-------------------------+-------+---------------+-------------+-------------+--------------+---------------+--------------+------------+------------+-----------+-------------+---------------+-------------+
--

CREATE OR REPLACE
  ALGORITHM = MERGE
  DEFINER = 'mysql.sys'@'localhost'
  SQL SECURITY INVOKER 
VIEW io_global_by_wait_by_latency (
  event_name,
  total,
  total_latency,
  avg_latency,
  max_latency,
  read_latency,
  write_latency,
  misc_latency,
  count_read,
  total_read,
  avg_read,
  count_write,
  total_written,
  avg_written
) AS
SELECT SUBSTRING_INDEX(event_name, '/', -2) AS event_name,
       count_star AS total,
       format_pico_time(sum_timer_wait) AS total_latency,
       format_pico_time(avg_timer_wait) AS avg_latency,
       format_pico_time(max_timer_wait) AS max_latency,
       format_pico_time(sum_timer_read) AS read_latency,
       format_pico_time(sum_timer_write) AS write_latency,
       format_pico_time(sum_timer_misc) AS misc_latency,
       count_read,
       format_bytes(sum_number_of_bytes_read) AS total_read,
       format_bytes(IFNULL(sum_number_of_bytes_read / NULLIF(count_read, 0), 0)) AS avg_read,
       count_write,
       format_bytes(sum_number_of_bytes_write) AS total_written,
       format_bytes(IFNULL(sum_number_of_bytes_write / NULLIF(count_write, 0), 0)) AS avg_written
  FROM performance_schema.file_summary_by_event_name 
 WHERE event_name LIKE 'wait/io/file/%'
   AND count_star > 0
 ORDER BY sum_timer_wait DESC;
-- Copyright (c) 2014, 2024, Oracle and/or its affiliates.
--
-- This program is free software; you can redistribute it and/or modify
-- it under the terms of the GNU General Public License as published by
-- the Free Software Foundation; version 2 of the License.
--
-- This program is distributed in the hope that it will be useful,
-- but WITHOUT ANY WARRANTY; without even the implied warranty of
-- MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
-- GNU General Public License for more details.
--
-- You should have received a copy of the GNU General Public License
-- along with this program; if not, write to the Free Software
-- Foundation, Inc., 51 Franklin St, Fifth Floor, Boston, MA 02110-1301 USA

--
-- View: x$io_global_by_wait_by_latency
--
-- Shows the top global IO consumers by latency.
--
-- mysql> select * from x$io_global_by_wait_by_latency;
-- +-------------------------+-------+----------------+-------------+--------------+--------------+---------------+----------------+------------+------------+------------+-------------+---------------+-------------+
-- | event_name              | total | total_latency  | avg_latency | max_latency  | read_latency | write_latency | misc_latency   | count_read | total_read | avg_read   | count_write | total_written | avg_written |
-- +-------------------------+-------+----------------+-------------+--------------+--------------+---------------+----------------+------------+------------+------------+-------------+---------------+-------------+
-- | sql/file_parser         |  5945 | 33615441247050 |  5654405471 | 203652881640 |  22093704230 |   27389668280 | 33565957874540 |         26 |       7008 |   269.5385 |         808 |       2479209 |   3068.3280 |
-- | sql/FRM                 |  6332 |  1755386796800 |   277224688 | 145624702340 | 519139578620 |    1677016640 |  1234570201540 |       2040 |     865905 |   424.4632 |         439 |        103445 |    235.6378 |
-- | innodb/innodb_data_file |  1344 |  1522989889460 |  1133176798 | 350700491310 | 203817502460 |  450959403830 |   868212983170 |        147 |    2408448 | 16384.0000 |        1001 |      56213504 |  56157.3467 |
-- | innodb/innodb_log_file  |   828 |   893475794640 |  1079076921 |  30108124800 |  16315236730 |  705886928240 |   171273629670 |          6 |      69632 | 11605.3333 |         413 |       2294272 |   5555.1380 |
-- | myisam/kfile            |  7826 |   246001992860 |    31433883 |  19265276810 |  74419162870 |   23923730090 |   147659099900 |        770 |     141058 |   183.1922 |        4516 |        249602 |     55.2706 |
-- | myisam/dfile            | 13431 |   228191713620 |    16989882 |  32500163410 |  89162969350 |   17341973610 |   121686770660 |       5819 |    4873176 |   837.4594 |        1577 |       2853444 |   1809.4128 |
-- | csv/metadata            |     8 |    28975194560 |  3621899320 |  20148109020 |    399265620 |             0 |    28575928940 |          2 |         70 |    35.0000 |           0 |             0 |      0.0000 |
-- | mysys/charset           |     3 |    24244722970 |  8081574072 |  24151547420 |  24151547420 |             0 |       93175550 |          1 |      17722 | 17722.0000 |           0 |             0 |      0.0000 |
-- | sql/ERRMSG              |     5 |    20427386850 |  4085477370 |  19312386730 |  20324183100 |             0 |      103203750 |          3 |      60390 | 20130.0000 |           0 |             0 |      0.0000 |
-- | mysys/cnf               |     5 |    11366169230 |  2273233846 |  11283602460 |  11287953040 |             0 |       78216190 |          3 |         56 |    18.6667 |           0 |             0 |      0.0000 |
-- | sql/dbopt               |    57 |     4042348570 |    70918224 |    843703380 |            0 |     186430270 |     3855918300 |          0 |          0 |     0.0000 |           7 |           431 |     61.5714 |
-- | csv/data                |     4 |      411548280 |   102887070 |    234886080 |            0 |             0 |      411548280 |          0 |          0 |     0.0000 |           0 |             0 |      0.0000 |
-- | sql/misc                |    24 |      369128240 |    15380092 |     33771660 |            0 |             0 |      369128240 |          0 |          0 |     0.0000 |           0 |             0 |      0.0000 |
-- | archive/data            |    39 |      277856540 |     7124169 |     16180840 |            0 |             0 |      277856540 |          0 |          0 |     0.0000 |           0 |             0 |      0.0000 |
-- | sql/pid                 |     3 |      218026640 |    72675421 |    154841440 |            0 |      21639800 |      196386840 |          0 |          0 |     0.0000 |           1 |             6 |      6.0000 |
-- | sql/casetest            |     5 |      197152150 |    39430430 |    126310080 |            0 |             0 |      197152150 |          0 |          0 |     0.0000 |           0 |             0 |      0.0000 |
-- | sql/global_ddl_log      |     2 |       14604980 |     7302490 |     12120550 |            0 |             0 |       14604980 |          0 |          0 |     0.0000 |           0 |             0 |      0.0000 |
-- +-------------------------+-------+----------------+-------------+--------------+--------------+---------------+----------------+------------+------------+------------+-------------+---------------+-------------+
--

CREATE OR REPLACE
  ALGORITHM = MERGE
  DEFINER = 'mysql.sys'@'localhost'
  SQL SECURITY INVOKER 
VIEW x$io_global_by_wait_by_latency (
  event_name,
  total,
  total_latency,
  avg_latency,
  max_latency,
  read_latency,
  write_latency,
  misc_latency,
  count_read,
  total_read,
  avg_read,
  count_write,
  total_written,
  avg_written
) AS
SELECT SUBSTRING_INDEX(event_name, '/', -2) AS event_name,
       count_star AS total,
       sum_timer_wait AS total_latency,
       avg_timer_wait AS avg_latency,
       max_timer_wait AS max_latency,
       sum_timer_read AS read_latency,
       sum_timer_write AS write_latency,
       sum_timer_misc AS misc_latency,
       count_read,
       sum_number_of_bytes_read AS total_read,
       IFNULL(sum_number_of_bytes_read / NULLIF(count_read, 0), 0) AS avg_read,
       count_write,
       sum_number_of_bytes_write AS total_written,
       IFNULL(sum_number_of_bytes_write / NULLIF(count_write, 0), 0) AS avg_written
  FROM performance_schema.file_summary_by_event_name 
 WHERE event_name LIKE 'wait/io/file/%'
   AND count_star > 0
 ORDER BY sum_timer_wait DESC;
-- Copyright (c) 2017, 2024, Oracle and/or its affiliates.
--
-- This program is free software; you can redistribute it and/or modify
-- it under the terms of the GNU General Public License as published by
-- the Free Software Foundation; version 2 of the License.
--
-- This program is distributed in the hope that it will be useful,
-- but WITHOUT ANY WARRANTY; without even the implied warranty of
-- MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
-- GNU General Public License for more details.
--
-- You should have received a copy of the GNU General Public License
-- along with this program; if not, write to the Free Software
-- Foundation, Inc., 51 Franklin St, Fifth Floor, Boston, MA 02110-1301 USA

--
-- View: innodb_lock_waits
--
-- Give a snapshot of which InnoDB locks transactions are waiting for.
-- The lock waits are ordered by the age of the lock descending.
--
-- Versions: 8.0+
--
-- mysql> select * from sys.innodb_lock_waits\G
-- *************************** 1. row ***************************
--                 wait_started: 2017-01-24 14:25:39
--                     wait_age: 00:00:02
--                wait_age_secs: 2
--                 locked_table: `test`.`t1`
--          locked_table_schema: test
--            locked_table_name: t1
--       locked_table_partition: NULL
--    locked_table_subpartition: NULL
--                 locked_index: GEN_CLUST_INDEX
--                  locked_type: RECORD
--               waiting_trx_id: 2063
--          waiting_trx_started: 2017-01-24 14:25:39
--              waiting_trx_age: 00:00:02
--      waiting_trx_rows_locked: 1
--    waiting_trx_rows_modified: 0
--                  waiting_pid: 6
--                waiting_query: update test.t1 set j = j + sleep(100) where i = 1
--              waiting_lock_id: 2063:61:5:2
--            waiting_lock_mode: X
--              blocking_trx_id: 2060
--                 blocking_pid: 5
--               blocking_query: update test.t1 set j = j + sleep(100) where i = 1
--             blocking_lock_id: 2060:61:5:2
--           blocking_lock_mode: X
--         blocking_trx_started: 2017-01-24 14:24:19
--             blocking_trx_age: 00:01:22
--     blocking_trx_rows_locked: 1
--   blocking_trx_rows_modified: 0
--      sql_kill_blocking_query: KILL QUERY 5
-- sql_kill_blocking_connection: KILL 5
--

CREATE OR REPLACE
  ALGORITHM = TEMPTABLE
  DEFINER = 'mysql.sys'@'localhost'
  SQL SECURITY INVOKER
VIEW innodb_lock_waits (
  wait_started,
  wait_age,
  wait_age_secs,
  locked_table,
  locked_table_schema,
  locked_table_name,
  locked_table_partition,
  locked_table_subpartition,
  locked_index,
  locked_type,
  waiting_trx_id,
  waiting_trx_started,
  waiting_trx_age,
  waiting_trx_rows_locked,
  waiting_trx_rows_modified,
  waiting_pid,
  waiting_query,
  waiting_lock_id,
  waiting_lock_mode,
  blocking_trx_id,
  blocking_pid,
  blocking_query,
  blocking_lock_id,
  blocking_lock_mode,
  blocking_trx_started,
  blocking_trx_age,
  blocking_trx_rows_locked,
  blocking_trx_rows_modified,
  sql_kill_blocking_query,
  sql_kill_blocking_connection
) AS
SELECT r.trx_wait_started AS wait_started,
       TIMEDIFF(NOW(), r.trx_wait_started) AS wait_age,
       TIMESTAMPDIFF(SECOND, r.trx_wait_started, NOW()) AS wait_age_secs,
       CONCAT(sys.quote_identifier(rl.object_schema), '.', sys.quote_identifier(rl.object_name)) AS locked_table,
       rl.object_schema AS locked_table_schema,
       rl.object_name AS locked_table_name,
       rl.partition_name AS locked_table_partition,
       rl.subpartition_name AS locked_table_subpartition,
       rl.index_name AS locked_index,
       rl.lock_type AS locked_type,
       r.trx_id AS waiting_trx_id,
       r.trx_started as waiting_trx_started,
       TIMEDIFF(NOW(), r.trx_started) AS waiting_trx_age,
       r.trx_rows_locked AS waiting_trx_rows_locked,
       r.trx_rows_modified AS waiting_trx_rows_modified,
       r.trx_mysql_thread_id AS waiting_pid,
       sys.format_statement(r.trx_query) AS waiting_query,
       rl.engine_lock_id AS waiting_lock_id,
       rl.lock_mode AS waiting_lock_mode,
       b.trx_id AS blocking_trx_id,
       b.trx_mysql_thread_id AS blocking_pid,
       sys.format_statement(b.trx_query) AS blocking_query,
       bl.engine_lock_id AS blocking_lock_id,
       bl.lock_mode AS blocking_lock_mode,
       b.trx_started AS blocking_trx_started,
       TIMEDIFF(NOW(), b.trx_started) AS blocking_trx_age,
       b.trx_rows_locked AS blocking_trx_rows_locked,
       b.trx_rows_modified AS blocking_trx_rows_modified,
       CONCAT('KILL QUERY ', b.trx_mysql_thread_id) AS sql_kill_blocking_query,
       CONCAT('KILL ', b.trx_mysql_thread_id) AS sql_kill_blocking_connection
    FROM performance_schema.data_lock_waits w
 INNER JOIN information_schema.innodb_trx b  ON b.trx_id = CAST(w.blocking_engine_transaction_id AS CHAR)
 INNER JOIN information_schema.innodb_trx r  ON r.trx_id = CAST(w.requesting_engine_transaction_id AS CHAR)
 INNER JOIN performance_schema.data_locks bl
   ON ((bl.engine_lock_id = w.blocking_engine_lock_id) AND (bl.engine = w.engine))
 INNER JOIN performance_schema.data_locks rl
   ON ((rl.engine_lock_id = w.requesting_engine_lock_id) AND (rl.engine = w.engine))
 ORDER BY r.trx_wait_started;
-- Copyright (c) 2017, 2024, Oracle and/or its affiliates.
--
-- This program is free software; you can redistribute it and/or modify
-- it under the terms of the GNU General Public License as published by
-- the Free Software Foundation; version 2 of the License.
--
-- This program is distributed in the hope that it will be useful,
-- but WITHOUT ANY WARRANTY; without even the implied warranty of
-- MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
-- GNU General Public License for more details.
--
-- You should have received a copy of the GNU General Public License
-- along with this program; if not, write to the Free Software
-- Foundation, Inc., 51 Franklin St, Fifth Floor, Boston, MA 02110-1301 USA

--
-- View: x$innodb_lock_waits
--
-- Give a snapshot of which InnoDB locks transactions are waiting for.
-- The lock waits are ordered by the age of the lock descending.
--
-- Versions: 8.0+
--
-- mysql> select * from sys.x$innodb_lock_waits\G
-- *************************** 1. row ***************************
--                 wait_started: 2017-01-24 14:25:39
--                     wait_age: 00:00:08
--                wait_age_secs: 8
--                 locked_table: `test`.`t1`
--          locked_table_schema: test
--            locked_table_name: t1
--       locked_table_partition: NULL
--    locked_table_subpartition: NULL
--                 locked_index: GEN_CLUST_INDEX
--                  locked_type: RECORD
--               waiting_trx_id: 2063
--          waiting_trx_started: 2017-01-24 14:25:39
--              waiting_trx_age: 00:00:08
--      waiting_trx_rows_locked: 1
--    waiting_trx_rows_modified: 0
--                  waiting_pid: 6
--                waiting_query: update test.t1 set j = j + sleep(100) where i = 1
--              waiting_lock_id: 2063:61:5:2
--            waiting_lock_mode: X
--              blocking_trx_id: 2060
--                 blocking_pid: 5
--               blocking_query: update test.t1 set j = j + sleep(100) where i = 1
--             blocking_lock_id: 2060:61:5:2
--           blocking_lock_mode: X
--         blocking_trx_started: 2017-01-24 14:24:19
--             blocking_trx_age: 00:01:28
--     blocking_trx_rows_locked: 1
--   blocking_trx_rows_modified: 0
--      sql_kill_blocking_query: KILL QUERY 5
-- sql_kill_blocking_connection: KILL 5
--

CREATE OR REPLACE
  ALGORITHM = TEMPTABLE
  DEFINER = 'mysql.sys'@'localhost'
  SQL SECURITY INVOKER
VIEW x$innodb_lock_waits (
  wait_started,
  wait_age,
  wait_age_secs,
  locked_table,
  locked_table_schema,
  locked_table_name,
  locked_table_partition,
  locked_table_subpartition,
  locked_index,
  locked_type,
  waiting_trx_id,
  waiting_trx_started,
  waiting_trx_age,
  waiting_trx_rows_locked,
  waiting_trx_rows_modified,
  waiting_pid,
  waiting_query,
  waiting_lock_id,
  waiting_lock_mode,
  blocking_trx_id,
  blocking_pid,
  blocking_query,
  blocking_lock_id,
  blocking_lock_mode,
  blocking_trx_started,
  blocking_trx_age,
  blocking_trx_rows_locked,
  blocking_trx_rows_modified,
  sql_kill_blocking_query,
  sql_kill_blocking_connection
) AS
SELECT r.trx_wait_started AS wait_started,
       TIMEDIFF(NOW(), r.trx_wait_started) AS wait_age,
       TIMESTAMPDIFF(SECOND, r.trx_wait_started, NOW()) AS wait_age_secs,
       CONCAT(sys.quote_identifier(rl.object_schema), '.', sys.quote_identifier(rl.object_name)) AS locked_table,
       rl.object_schema AS locked_table_schema,
       rl.object_name AS locked_table_name,
       rl.partition_name AS locked_table_partition,
       rl.subpartition_name AS locked_table_subpartition,
       rl.index_name AS locked_index,
       rl.lock_type AS locked_type,
       r.trx_id AS waiting_trx_id,
       r.trx_started as waiting_trx_started,
       TIMEDIFF(NOW(), r.trx_started) AS waiting_trx_age,
       r.trx_rows_locked AS waiting_trx_rows_locked,
       r.trx_rows_modified AS waiting_trx_rows_modified,
       r.trx_mysql_thread_id AS waiting_pid,
       r.trx_query AS waiting_query,
       rl.engine_lock_id AS waiting_lock_id,
       rl.lock_mode AS waiting_lock_mode,
       b.trx_id AS blocking_trx_id,
       b.trx_mysql_thread_id AS blocking_pid,
       b.trx_query AS blocking_query,
       bl.engine_lock_id AS blocking_lock_id,
       bl.lock_mode AS blocking_lock_mode,
       b.trx_started AS blocking_trx_started,
       TIMEDIFF(NOW(), b.trx_started) AS blocking_trx_age,
       b.trx_rows_locked AS blocking_trx_rows_locked,
       b.trx_rows_modified AS blocking_trx_rows_modified,
       CONCAT('KILL QUERY ', b.trx_mysql_thread_id) AS sql_kill_blocking_query,
       CONCAT('KILL ', b.trx_mysql_thread_id) AS sql_kill_blocking_connection
  FROM performance_schema.data_lock_waits w
 INNER JOIN information_schema.innodb_trx b  ON b.trx_id = CAST(w.blocking_engine_transaction_id AS CHAR)
 INNER JOIN information_schema.innodb_trx r  ON r.trx_id = CAST(w.requesting_engine_transaction_id AS CHAR)
 INNER JOIN performance_schema.data_locks bl
   ON ((bl.engine_lock_id = w.blocking_engine_lock_id) AND (bl.engine = w.engine))
 INNER JOIN performance_schema.data_locks rl
   ON ((rl.engine_lock_id = w.requesting_engine_lock_id) AND (rl.engine = w.engine))
 ORDER BY r.trx_wait_started;
-- Copyright (c) 2014, 2024, Oracle and/or its affiliates.
--
-- This program is free software; you can redistribute it and/or modify
-- it under the terms of the GNU General Public License as published by
-- the Free Software Foundation; version 2 of the License.
--
-- This program is distributed in the hope that it will be useful,
-- but WITHOUT ANY WARRANTY; without even the implied warranty of
-- MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
-- GNU General Public License for more details.
--
-- You should have received a copy of the GNU General Public License
-- along with this program; if not, write to the Free Software
-- Foundation, Inc., 51 Franklin St, Fifth Floor, Boston, MA 02110-1301  USA

--
-- View: memory_by_user_by_current_bytes
--
-- Summarizes memory use by user using the 5.7 Performance Schema instrumentation.
-- 
-- When the user found is NULL, it is assumed to be a "background" thread.  
--
-- mysql> select * from memory_by_user_by_current_bytes;
-- +------+--------------------+-------------------+-------------------+-------------------+-----------------+
-- | user | current_count_used | current_allocated | current_avg_alloc | current_max_alloc | total_allocated |
-- +------+--------------------+-------------------+-------------------+-------------------+-----------------+
-- | root |               1401 | 1.09 MiB          | 815 bytes         | 334.97 KiB        | 42.73 MiB       |
-- | mark |                201 | 496.08 KiB        | 2.47 KiB          | 334.97 KiB        | 5.50 MiB        |
-- +------+--------------------+-------------------+-------------------+-------------------+-----------------+
--

CREATE OR REPLACE
  ALGORITHM = TEMPTABLE
  DEFINER = 'mysql.sys'@'localhost'
  SQL SECURITY INVOKER 
VIEW memory_by_user_by_current_bytes (
  user,
  current_count_used,
  current_allocated,
  current_avg_alloc,
  current_max_alloc,
  total_allocated
) AS
SELECT IF(user IS NULL, 'background', user) AS user,
       SUM(current_count_used) AS current_count_used,
       format_bytes(SUM(current_number_of_bytes_used)) AS current_allocated,
       format_bytes(IFNULL(SUM(current_number_of_bytes_used) / NULLIF(SUM(current_count_used), 0), 0)) AS current_avg_alloc,
       format_bytes(MAX(current_number_of_bytes_used)) AS current_max_alloc,
       format_bytes(SUM(sum_number_of_bytes_alloc)) AS total_allocated
  FROM performance_schema.memory_summary_by_user_by_event_name
 GROUP BY IF(user IS NULL, 'background', user)
 ORDER BY SUM(current_number_of_bytes_used) DESC;
-- Copyright (c) 2014, 2024, Oracle and/or its affiliates.
--
-- This program is free software; you can redistribute it and/or modify
-- it under the terms of the GNU General Public License as published by
-- the Free Software Foundation; version 2 of the License.
--
-- This program is distributed in the hope that it will be useful,
-- but WITHOUT ANY WARRANTY; without even the implied warranty of
-- MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
-- GNU General Public License for more details.
--
-- You should have received a copy of the GNU General Public License
-- along with this program; if not, write to the Free Software
-- Foundation, Inc., 51 Franklin St, Fifth Floor, Boston, MA 02110-1301  USA

--
-- View: x$memory_by_user_by_current_bytes
--
-- Summarizes memory use by user
-- 
-- When the user found is NULL, it is assumed to be a "background" thread.  
--
-- mysql> select * from x$memory_by_user_by_current_bytes;
-- +------+--------------------+-------------------+-------------------+-------------------+-----------------+
-- | user | current_count_used | current_allocated | current_avg_alloc | current_max_alloc | total_allocated |
-- +------+--------------------+-------------------+-------------------+-------------------+-----------------+
-- | root |               1399 |           1124553 |          803.8263 |            343008 |        45426133 |
-- | mark |                201 |            507990 |         2527.3134 |            343008 |         5769804 |
-- +------+--------------------+-------------------+-------------------+-------------------+-----------------+
--

CREATE OR REPLACE
  ALGORITHM = TEMPTABLE
  DEFINER = 'mysql.sys'@'localhost'
  SQL SECURITY INVOKER 
VIEW x$memory_by_user_by_current_bytes (
  user,
  current_count_used,
  current_allocated,
  current_avg_alloc,
  current_max_alloc,
  total_allocated
) AS
SELECT IF(user IS NULL, 'background', user) AS user,
       SUM(current_count_used) AS current_count_used,
       SUM(current_number_of_bytes_used) AS current_allocated,
       IFNULL(SUM(current_number_of_bytes_used) / NULLIF(SUM(current_count_used), 0), 0) AS current_avg_alloc,
       MAX(current_number_of_bytes_used) AS current_max_alloc,
       SUM(sum_number_of_bytes_alloc) AS total_allocated
  FROM performance_schema.memory_summary_by_user_by_event_name
 GROUP BY IF(user IS NULL, 'background', user)
 ORDER BY SUM(current_number_of_bytes_used) DESC;
-- Copyright (c) 2014, 2024, Oracle and/or its affiliates.
--
-- This program is free software; you can redistribute it and/or modify
-- it under the terms of the GNU General Public License as published by
-- the Free Software Foundation; version 2 of the License.
--
-- This program is distributed in the hope that it will be useful,
-- but WITHOUT ANY WARRANTY; without even the implied warranty of
-- MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
-- GNU General Public License for more details.
--
-- You should have received a copy of the GNU General Public License
-- along with this program; if not, write to the Free Software
-- Foundation, Inc., 51 Franklin St, Fifth Floor, Boston, MA 02110-1301  USA

--
-- View: memory_by_host_by_current_bytes
--
-- Summarizes memory use by host using the 5.7 Performance Schema instrumentation.
-- 
-- When the host found is NULL, it is assumed to be a local "background" thread.  
--
-- mysql> select * from memory_by_host_by_current_bytes;
-- +------------+--------------------+-------------------+-------------------+-------------------+-----------------+
-- | host       | current_count_used | current_allocated | current_avg_alloc | current_max_alloc | total_allocated |
-- +------------+--------------------+-------------------+-------------------+-------------------+-----------------+
-- | background |               2773 | 10.84 MiB         | 4.00 KiB          | 8.00 MiB          | 30.69 MiB       |
-- | localhost  |               1509 | 809.30 KiB        | 549 bytes         | 176.38 KiB        | 83.59 MiB       |
-- +------------+--------------------+-------------------+-------------------+-------------------+-----------------+
--

CREATE OR REPLACE
  ALGORITHM = TEMPTABLE
  DEFINER = 'mysql.sys'@'localhost'
  SQL SECURITY INVOKER 
VIEW memory_by_host_by_current_bytes (
  host,
  current_count_used,
  current_allocated,
  current_avg_alloc,
  current_max_alloc,
  total_allocated
) AS
SELECT IF(host IS NULL, 'background', host) AS host,
       SUM(current_count_used) AS current_count_used,
       format_bytes(SUM(current_number_of_bytes_used)) AS current_allocated,
       format_bytes(IFNULL(SUM(current_number_of_bytes_used) / NULLIF(SUM(current_count_used), 0), 0)) AS current_avg_alloc,
       format_bytes(MAX(current_number_of_bytes_used)) AS current_max_alloc,
       format_bytes(SUM(sum_number_of_bytes_alloc)) AS total_allocated
  FROM performance_schema.memory_summary_by_host_by_event_name
 GROUP BY IF(host IS NULL, 'background', host)
 ORDER BY SUM(current_number_of_bytes_used) DESC;
-- Copyright (c) 2014, 2024, Oracle and/or its affiliates.
--
-- This program is free software; you can redistribute it and/or modify
-- it under the terms of the GNU General Public License as published by
-- the Free Software Foundation; version 2 of the License.
--
-- This program is distributed in the hope that it will be useful,
-- but WITHOUT ANY WARRANTY; without even the implied warranty of
-- MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
-- GNU General Public License for more details.
--
-- You should have received a copy of the GNU General Public License
-- along with this program; if not, write to the Free Software
-- Foundation, Inc., 51 Franklin St, Fifth Floor, Boston, MA 02110-1301  USA

--
-- View: x$memory_by_host_by_current_bytes
--
-- Summarizes memory use by host
-- 
-- When the host found is NULL, it is assumed to be a local "background" thread.  
--
-- mysql> select * from x$memory_by_host_by_current_bytes;
-- +------------+--------------------+-------------------+-------------------+-------------------+-----------------+
-- | host       | current_count_used | current_allocated | current_avg_alloc | current_max_alloc | total_allocated |
-- +------------+--------------------+-------------------+-------------------+-------------------+-----------------+
-- | background |               2773 |          11362444 |         4097.5276 |           8390792 |        32184183 |
-- | localhost  |               1508 |            813040 |          539.1512 |            180616 |        88168182 |
-- +------------+--------------------+-------------------+-------------------+-------------------+-----------------+
--

CREATE OR REPLACE
  ALGORITHM = TEMPTABLE
  DEFINER = 'mysql.sys'@'localhost'
  SQL SECURITY INVOKER 
VIEW x$memory_by_host_by_current_bytes (
  host,
  current_count_used,
  current_allocated,
  current_avg_alloc,
  current_max_alloc,
  total_allocated
) AS
SELECT IF(host IS NULL, 'background', host) AS host,
       SUM(current_count_used) AS current_count_used,
       SUM(current_number_of_bytes_used) AS current_allocated,
       IFNULL(SUM(current_number_of_bytes_used) / NULLIF(SUM(current_count_used), 0), 0) AS current_avg_alloc,
       MAX(current_number_of_bytes_used) AS current_max_alloc,
       SUM(sum_number_of_bytes_alloc) AS total_allocated
  FROM performance_schema.memory_summary_by_host_by_event_name
 GROUP BY IF(host IS NULL, 'background', host)
 ORDER BY SUM(current_number_of_bytes_used) DESC;
-- Copyright (c) 2014, 2024, Oracle and/or its affiliates.
--
-- This program is free software; you can redistribute it and/or modify
-- it under the terms of the GNU General Public License as published by
-- the Free Software Foundation; version 2 of the License.
--
-- This program is distributed in the hope that it will be useful,
-- but WITHOUT ANY WARRANTY; without even the implied warranty of
-- MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
-- GNU General Public License for more details.
--
-- You should have received a copy of the GNU General Public License
-- along with this program; if not, write to the Free Software
-- Foundation, Inc., 51 Franklin St, Fifth Floor, Boston, MA 02110-1301  USA

--
-- View: memory_by_thread_by_current_bytes
--
-- Summarizes memory use by user using the 5.7 Performance Schema instrumentation.
-- 
-- User shows either the background or foreground user name appropriately.
--
-- mysql> select * from sys.memory_by_thread_by_current_bytes limit 5;
-- +-----------+----------------+--------------------+-------------------+-------------------+-------------------+-----------------+
-- | thread_id | user           | current_count_used | current_allocated | current_avg_alloc | current_max_alloc | total_allocated |
-- +-----------+----------------+--------------------+-------------------+-------------------+-------------------+-----------------+
-- |         1 | sql/main       |              29333 | 166.02 MiB        | 5.80 KiB          | 131.13 MiB        | 196.00 MiB      |
-- |        55 | root@localhost |                175 | 1.04 MiB          | 6.09 KiB          | 350.86 KiB        | 67.37 MiB       |
-- |        58 | root@localhost |                236 | 368.13 KiB        | 1.56 KiB          | 312.05 KiB        | 130.34 MiB      |
-- |       904 | root@localhost |                 32 | 18.00 KiB         | 576 bytes         | 16.00 KiB         | 6.68 MiB        |
-- |       970 | root@localhost |                 12 | 16.80 KiB         | 1.40 KiB          | 16.00 KiB         | 1.20 MiB        |
-- +-----------+----------------+--------------------+-------------------+-------------------+-------------------+-----------------+
--

CREATE OR REPLACE
  ALGORITHM = TEMPTABLE
  DEFINER = 'mysql.sys'@'localhost'
  SQL SECURITY INVOKER 
VIEW memory_by_thread_by_current_bytes (
  thread_id,
  user,
  current_count_used,
  current_allocated,
  current_avg_alloc,
  current_max_alloc,
  total_allocated
) AS
SELECT thread_id,
       IF(t.name = 'thread/sql/one_connection', 
          CONCAT(t.processlist_user, '@', t.processlist_host), 
          REPLACE(t.name, 'thread/', '')) user,
       SUM(mt.current_count_used) AS current_count_used,
       format_bytes(SUM(mt.current_number_of_bytes_used)) AS current_allocated,
       format_bytes(IFNULL(SUM(mt.current_number_of_bytes_used) / NULLIF(SUM(current_count_used), 0), 0)) AS current_avg_alloc,
       format_bytes(MAX(mt.current_number_of_bytes_used)) AS current_max_alloc,
       format_bytes(SUM(mt.sum_number_of_bytes_alloc)) AS total_allocated
  FROM performance_schema.memory_summary_by_thread_by_event_name AS mt
  JOIN performance_schema.threads AS t USING (thread_id)
 GROUP BY thread_id, IF(t.name = 'thread/sql/one_connection', 
          CONCAT(t.processlist_user, '@', t.processlist_host), 
          REPLACE(t.name, 'thread/', ''))
 ORDER BY SUM(current_number_of_bytes_used) DESC;
-- Copyright (c) 2014, 2024, Oracle and/or its affiliates.
--
-- This program is free software; you can redistribute it and/or modify
-- it under the terms of the GNU General Public License as published by
-- the Free Software Foundation; version 2 of the License.
--
-- This program is distributed in the hope that it will be useful,
-- but WITHOUT ANY WARRANTY; without even the implied warranty of
-- MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
-- GNU General Public License for more details.
--
-- You should have received a copy of the GNU General Public License
-- along with this program; if not, write to the Free Software
-- Foundation, Inc., 51 Franklin St, Fifth Floor, Boston, MA 02110-1301  USA

--
-- View: x$memory_by_thread_by_current_bytes
--
-- Summarizes memory use by user
-- 
-- When the user found is NULL, it is assumed to be a "background" thread.  
--
-- mysql> select * from sys.x$memory_by_thread_by_current_bytes limit 5;
-- +-----------+----------------+--------------------+-------------------+-------------------+-------------------+-----------------+
-- | thread_id | user           | current_count_used | current_allocated | current_avg_alloc | current_max_alloc | total_allocated |
-- +-----------+----------------+--------------------+-------------------+-------------------+-------------------+-----------------+
-- |         1 | sql/main       |              29333 |         174089450 |         5934.9351 |         137494528 |       205523135 |
-- |        55 | root@localhost |                173 |           1074664 |         6211.9306 |            359280 |        72248413 |
-- |        58 | root@localhost |                240 |            377099 |         1571.2458 |            319536 |       169483870 |
-- |      1152 | root@localhost |                 30 |             56949 |         1898.3000 |             16391 |         1010024 |
-- |      1154 | root@localhost |                 34 |             56369 |         1657.9118 |             16391 |         1958771 |
-- +-----------+----------------+--------------------+-------------------+-------------------+-------------------+-----------------+
--

CREATE OR REPLACE
  ALGORITHM = TEMPTABLE
  DEFINER = 'mysql.sys'@'localhost'
  SQL SECURITY INVOKER 
VIEW x$memory_by_thread_by_current_bytes (
  thread_id,
  user,
  current_count_used,
  current_allocated,
  current_avg_alloc,
  current_max_alloc,
  total_allocated
) AS
SELECT t.thread_id,
       IF(t.name = 'thread/sql/one_connection', 
          CONCAT(t.processlist_user, '@', t.processlist_host), 
          REPLACE(t.name, 'thread/', '')) user,
       SUM(mt.current_count_used) AS current_count_used,
       SUM(mt.current_number_of_bytes_used) AS current_allocated,
       IFNULL(SUM(mt.current_number_of_bytes_used) / NULLIF(SUM(current_count_used), 0), 0) AS current_avg_alloc,
       MAX(mt.current_number_of_bytes_used) AS current_max_alloc,
       SUM(mt.sum_number_of_bytes_alloc) AS total_allocated
  FROM performance_schema.memory_summary_by_thread_by_event_name AS mt
  JOIN performance_schema.threads AS t USING (thread_id)
 GROUP BY thread_id, IF(t.name = 'thread/sql/one_connection', 
          CONCAT(t.processlist_user, '@', t.processlist_host), 
          REPLACE(t.name, 'thread/', ''))
 ORDER BY SUM(mt.current_number_of_bytes_used) DESC;
-- Copyright (c) 2014, 2024, Oracle and/or its affiliates.
--
-- This program is free software; you can redistribute it and/or modify
-- it under the terms of the GNU General Public License as published by
-- the Free Software Foundation; version 2 of the License.
--
-- This program is distributed in the hope that it will be useful,
-- but WITHOUT ANY WARRANTY; without even the implied warranty of
-- MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
-- GNU General Public License for more details.
--
-- You should have received a copy of the GNU General Public License
-- along with this program; if not, write to the Free Software
-- Foundation, Inc., 51 Franklin St, Fifth Floor, Boston, MA 02110-1301  USA

--
-- View: memory_global_by_current_bytes
-- 
-- Shows the current memory usage within the server globally broken down by allocation type.
--
-- mysql> select * from memory_global_by_current_bytes;
-- +-------------------------------------------------+---------------+---------------+-------------------+------------+-------------+----------------+
-- | event_name                                      | current_count | current_alloc | current_avg_alloc | high_count | high_alloc  | high_avg_alloc |
-- +-------------------------------------------------+---------------+---------------+-------------------+------------+-------------+----------------+
-- | memory/performance_schema/internal_buffers      |            62 | 293.80 MiB    | 4.74 MiB          |         62 | 293.80 MiB  | 4.74 MiB       |
-- | memory/innodb/buf_buf_pool                      |             1 | 131.06 MiB    | 131.06 MiB        |          1 | 131.06 MiB  | 131.06 MiB     |
-- | memory/innodb/log0log                           |             9 | 8.01 MiB      | 911.15 KiB        |          9 | 8.01 MiB    | 911.15 KiB     |
-- | memory/mysys/KEY_CACHE                          |             3 | 8.00 MiB      | 2.67 MiB          |          3 | 8.00 MiB    | 2.67 MiB       |
-- | memory/innodb/hash0hash                         |            27 | 4.73 MiB      | 179.51 KiB        |         27 | 6.84 MiB    | 259.47 KiB     |
-- | memory/innodb/os0event                          |         24998 | 4.01 MiB      | 168 bytes         |      24998 | 4.01 MiB    | 168 bytes      |
-- ...
--

CREATE OR REPLACE
  ALGORITHM = MERGE
  DEFINER = 'mysql.sys'@'localhost'
  SQL SECURITY INVOKER 
VIEW memory_global_by_current_bytes (
  event_name,
  current_count,
  current_alloc,
  current_avg_alloc,
  high_count,
  high_alloc,
  high_avg_alloc
) AS
SELECT event_name,
       current_count_used AS current_count,
       format_bytes(current_number_of_bytes_used) AS current_alloc,
       format_bytes(IFNULL(current_number_of_bytes_used / NULLIF(current_count_used, 0), 0)) AS current_avg_alloc,
       high_count_used AS high_count,
       format_bytes(high_number_of_bytes_used) AS high_alloc,
       format_bytes(IFNULL(high_number_of_bytes_used / NULLIF(high_count_used, 0), 0)) AS high_avg_alloc
  FROM performance_schema.memory_summary_global_by_event_name
 WHERE current_number_of_bytes_used > 0
 ORDER BY current_number_of_bytes_used DESC;
-- Copyright (c) 2014, 2024, Oracle and/or its affiliates.
--
-- This program is free software; you can redistribute it and/or modify
-- it under the terms of the GNU General Public License as published by
-- the Free Software Foundation; version 2 of the License.
--
-- This program is distributed in the hope that it will be useful,
-- but WITHOUT ANY WARRANTY; without even the implied warranty of
-- MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
-- GNU General Public License for more details.
--
-- You should have received a copy of the GNU General Public License
-- along with this program; if not, write to the Free Software
-- Foundation, Inc., 51 Franklin St, Fifth Floor, Boston, MA 02110-1301  USA

--
-- View: x$memory_global_by_current_bytes
-- 
-- Shows the current memory usage within the server globally broken down by allocation type.
--
-- mysql> select * from x$memory_global_by_current_bytes;
-- +-------------------------------------------------+---------------+---------------+-------------------+------------+------------+----------------+
-- | event_name                                      | current_count | current_alloc | current_avg_alloc | high_count | high_alloc | high_avg_alloc |
-- +-------------------------------------------------+---------------+---------------+-------------------+------------+------------+----------------+
-- | memory/performance_schema/internal_buffers      |            62 |     308073712 |      4968930.8387 |         62 |  308073712 |   4968930.8387 |
-- | memory/innodb/buf_buf_pool                      |             1 |     137428992 |    137428992.0000 |          1 |  137428992 | 137428992.0000 |
-- | memory/innodb/log0log                           |             9 |       8397152 |       933016.8889 |          9 |    8397152 |    933016.8889 |
-- | memory/mysys/KEY_CACHE                          |             3 |       8390792 |      2796930.6667 |          3 |    8390792 |   2796930.6667 |
-- | memory/innodb/hash0hash                         |            27 |       4962992 |       183814.5185 |         27 |    7173904 |    265700.1481 |
-- | memory/innodb/os0event                          |         24998 |       4199664 |          168.0000 |      24998 |    4199664 |       168.0000 |
-- ...
--

CREATE OR REPLACE
  ALGORITHM = MERGE
  DEFINER = 'mysql.sys'@'localhost'
  SQL SECURITY INVOKER 
VIEW x$memory_global_by_current_bytes (
  event_name,
  current_count,
  current_alloc,
  current_avg_alloc,
  high_count,
  high_alloc,
  high_avg_alloc
) AS
SELECT event_name,
       current_count_used AS current_count,
       current_number_of_bytes_used AS current_alloc,
       IFNULL(current_number_of_bytes_used / NULLIF(current_count_used, 0), 0) AS current_avg_alloc,
       high_count_used AS high_count,
       high_number_of_bytes_used AS high_alloc,
       IFNULL(high_number_of_bytes_used / NULLIF(high_count_used, 0), 0) AS high_avg_alloc
  FROM performance_schema.memory_summary_global_by_event_name
 WHERE current_number_of_bytes_used > 0
 ORDER BY current_number_of_bytes_used DESC;
-- Copyright (c) 2014, 2024, Oracle and/or its affiliates.
--
-- This program is free software; you can redistribute it and/or modify
-- it under the terms of the GNU General Public License as published by
-- the Free Software Foundation; version 2 of the License.
--
-- This program is distributed in the hope that it will be useful,
-- but WITHOUT ANY WARRANTY; without even the implied warranty of
-- MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
-- GNU General Public License for more details.
--
-- You should have received a copy of the GNU General Public License
-- along with this program; if not, write to the Free Software
-- Foundation, Inc., 51 Franklin St, Fifth Floor, Boston, MA 02110-1301  USA

--
-- View: memory_global_total
-- 
-- Shows the total memory usage within the server globally.
--
-- mysql> select * from memory_global_total;
-- +-----------------+
-- | total_allocated |
-- +-----------------+
-- | 123.35 MiB      |
-- +-----------------+
--

CREATE OR REPLACE
  ALGORITHM = TEMPTABLE
  DEFINER = 'mysql.sys'@'localhost'
  SQL SECURITY INVOKER 
VIEW memory_global_total (
  total_allocated
) AS
SELECT format_bytes(SUM(CURRENT_NUMBER_OF_BYTES_USED)) total_allocated
  FROM performance_schema.memory_summary_global_by_event_name;
-- Copyright (c) 2014, 2024, Oracle and/or its affiliates.
--
-- This program is free software; you can redistribute it and/or modify
-- it under the terms of the GNU General Public License as published by
-- the Free Software Foundation; version 2 of the License.
--
-- This program is distributed in the hope that it will be useful,
-- but WITHOUT ANY WARRANTY; without even the implied warranty of
-- MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
-- GNU General Public License for more details.
--
-- You should have received a copy of the GNU General Public License
-- along with this program; if not, write to the Free Software
-- Foundation, Inc., 51 Franklin St, Fifth Floor, Boston, MA 02110-1301  USA

--
-- View: x$memory_global_total
-- 
-- Shows the total memory usage within the server globally
--
-- mysql> select * from x$memory_global_total;
-- +-----------------+
-- | total_allocated |
-- +-----------------+
-- |         1420023 |
-- +-----------------+
--

CREATE OR REPLACE
  ALGORITHM = TEMPTABLE
  DEFINER = 'mysql.sys'@'localhost'
  SQL SECURITY INVOKER 
VIEW x$memory_global_total (
  total_allocated
) AS
SELECT SUM(CURRENT_NUMBER_OF_BYTES_USED) total_allocated
  FROM performance_schema.memory_summary_global_by_event_name;
-- Copyright (c) 2014, 2024, Oracle and/or its affiliates.
--
-- This program is free software; you can redistribute it and/or modify
-- it under the terms of the GNU General Public License as published by
-- the Free Software Foundation; version 2 of the License.
--
-- This program is distributed in the hope that it will be useful,
-- but WITHOUT ANY WARRANTY; without even the implied warranty of
-- MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
-- GNU General Public License for more details.
--
-- You should have received a copy of the GNU General Public License
-- along with this program; if not, write to the Free Software
-- Foundation, Inc., 51 Franklin St, Fifth Floor, Boston, MA 02110-1301  USA

--
-- View: schema_index_statistics
--
-- Statistics around indexes.
--
-- Ordered by the total wait time descending - top indexes are most contended.
--
-- mysql> select * from schema_index_statistics limit 5;
-- +------------------+-------------+------------+---------------+----------------+---------------+----------------+--------------+----------------+--------------+----------------+
-- | table_schema     | table_name  | index_name | rows_selected | select_latency | rows_inserted | insert_latency | rows_updated | update_latency | rows_deleted | delete_latency |
-- +------------------+-------------+------------+---------------+----------------+---------------+----------------+--------------+----------------+--------------+----------------+
-- | mem              | mysqlserver | PRIMARY    |          6208 | 108.27 ms      |             0 | 0 ps           |         5470 | 1.47 s         |            0 | 0 ps           |
-- | mem              | innodb      | PRIMARY    |          4666 | 76.27 ms       |             0 | 0 ps           |         4454 | 571.47 ms      |            0 | 0 ps           |
-- | mem              | connection  | PRIMARY    |          1064 | 20.98 ms       |             0 | 0 ps           |         1064 | 457.30 ms      |            0 | 0 ps           |
-- | mem              | environment | PRIMARY    |          5566 | 151.17 ms      |             0 | 0 ps           |          694 | 252.57 ms      |            0 | 0 ps           |
-- | mem              | querycache  | PRIMARY    |          1698 | 27.99 ms       |             0 | 0 ps           |         1698 | 371.72 ms      |            0 | 0 ps           |
-- +------------------+-------------+------------+---------------+----------------+---------------+----------------+--------------+----------------+--------------+----------------+
--

CREATE OR REPLACE
  ALGORITHM = MERGE
  DEFINER = 'mysql.sys'@'localhost'
  SQL SECURITY INVOKER 
VIEW schema_index_statistics (
  table_schema,
  table_name,
  index_name,
  rows_selected,
  select_latency,
  rows_inserted,
  insert_latency,
  rows_updated,
  update_latency,
  rows_deleted,
  delete_latency
) AS
SELECT OBJECT_SCHEMA AS table_schema,
       OBJECT_NAME AS table_name,
       INDEX_NAME as index_name,
       COUNT_FETCH AS rows_selected,
       format_pico_time(SUM_TIMER_FETCH) AS select_latency,
       COUNT_INSERT AS rows_inserted,
       format_pico_time(SUM_TIMER_INSERT) AS insert_latency,
       COUNT_UPDATE AS rows_updated,
       format_pico_time(SUM_TIMER_UPDATE) AS update_latency,
       COUNT_DELETE AS rows_deleted,
       format_pico_time(SUM_TIMER_DELETE) AS delete_latency
  FROM performance_schema.table_io_waits_summary_by_index_usage
 WHERE index_name IS NOT NULL
 ORDER BY sum_timer_wait DESC;
-- Copyright (c) 2014, 2024, Oracle and/or its affiliates.
--
-- This program is free software; you can redistribute it and/or modify
-- it under the terms of the GNU General Public License as published by
-- the Free Software Foundation; version 2 of the License.
--
-- This program is distributed in the hope that it will be useful,
-- but WITHOUT ANY WARRANTY; without even the implied warranty of
-- MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
-- GNU General Public License for more details.
--
-- You should have received a copy of the GNU General Public License
-- along with this program; if not, write to the Free Software
-- Foundation, Inc., 51 Franklin St, Fifth Floor, Boston, MA 02110-1301  USA

--
-- View: x$schema_index_statistics
--
-- Statistics around indexes.
--
-- Ordered by the total wait time descending - top indexes are most contended.
--
-- mysql> SELECT * FROM x$schema_index_statistics LIMIT 5;
-- +---------------+----------------------+-------------------+---------------+----------------+---------------+----------------+--------------+----------------+--------------+----------------+
-- | table_schema  | table_name           | index_name        | rows_selected | select_latency | rows_inserted | insert_latency | rows_updated | update_latency | rows_deleted | delete_latency |
-- +---------------+----------------------+-------------------+---------------+----------------+---------------+----------------+--------------+----------------+--------------+----------------+
-- | common_schema | _global_sql_tokens   | PRIMARY           |          1886 |     1129676730 |             0 |              0 |            0 |              0 |         1878 |              0 |
-- | common_schema | _script_statements   | PRIMARY           |          4606 |     4212160680 |             0 |              0 |            0 |              0 |            0 |              0 |
-- | common_schema | _global_qs_variables | declaration_depth |           256 |     1650193090 |             0 |              0 |           32 |     1372148050 |            0 |              0 |
-- | common_schema | _global_qs_variables | PRIMARY           |             0 |              0 |             0 |              0 |            0 |              0 |           16 |              0 |
-- | common_schema | metadata             | PRIMARY           |             5 |       76730810 |             0 |              0 |            4 |      114310170 |            0 |              0 |
-- +---------------+----------------------+-------------------+---------------+----------------+---------------+----------------+--------------+----------------+--------------+----------------+
--

CREATE OR REPLACE
  ALGORITHM = MERGE
  DEFINER = 'mysql.sys'@'localhost'
  SQL SECURITY INVOKER 
VIEW x$schema_index_statistics (
  table_schema,
  table_name,
  index_name,
  rows_selected,
  select_latency,
  rows_inserted,
  insert_latency,
  rows_updated,
  update_latency,
  rows_deleted,
  delete_latency
) AS
SELECT OBJECT_SCHEMA AS table_schema,
       OBJECT_NAME AS table_name,
       INDEX_NAME as index_name,
       COUNT_FETCH AS rows_selected,
       SUM_TIMER_FETCH AS select_latency,
       COUNT_INSERT AS rows_inserted,
       SUM_TIMER_INSERT AS insert_latency,
       COUNT_UPDATE AS rows_updated,
       SUM_TIMER_UPDATE AS update_latency,
       COUNT_DELETE AS rows_deleted,
       SUM_TIMER_DELETE AS delete_latency
  FROM performance_schema.table_io_waits_summary_by_index_usage
 WHERE index_name IS NOT NULL
 ORDER BY sum_timer_wait DESC;
-- Copyright (c) 2014, 2024, Oracle and/or its affiliates.
--
-- This program is free software; you can redistribute it and/or modify
-- it under the terms of the GNU General Public License as published by
-- the Free Software Foundation; version 2 of the License.
--
-- This program is distributed in the hope that it will be useful,
-- but WITHOUT ANY WARRANTY; without even the implied warranty of
-- MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
-- GNU General Public License for more details.
--
-- You should have received a copy of the GNU General Public License
-- along with this program; if not, write to the Free Software
-- Foundation, Inc., 51 Franklin St, Fifth Floor, Boston, MA 02110-1301  USA

--
-- View: x$ps_schema_table_statistics_io
--
-- Helper view for schema_table_statistics
-- Having this view with ALGORITHM = TEMPTABLE means MySQL can use the optimizations for
-- materialized views to improve the overall performance.
--
-- mysql> SELECT * FROM x$ps_schema_table_statistics_io LIMIT 1\G
-- *************************** 1. row ***************************
--              table_schema: charsets
--                table_name: Index
--                count_read: 1
--  sum_number_of_bytes_read: 18710
--            sum_timer_read: 20229409070
--               count_write: 0
-- sum_number_of_bytes_write: 0
--           sum_timer_write: 0
--                count_misc: 2
--            sum_timer_misc: 80768480
--

CREATE OR REPLACE
  ALGORITHM = TEMPTABLE
  DEFINER = 'mysql.sys'@'localhost'
  SQL SECURITY INVOKER 
VIEW x$ps_schema_table_statistics_io (
  table_schema,
  table_name,
  count_read,
  sum_number_of_bytes_read,
  sum_timer_read,
  count_write,
  sum_number_of_bytes_write,
  sum_timer_write,
  count_misc,
  sum_timer_misc
) AS
SELECT extract_schema_from_file_name(file_name) AS table_schema,
       extract_table_from_file_name(file_name) AS table_name,
       SUM(count_read) AS count_read,
       SUM(sum_number_of_bytes_read) AS sum_number_of_bytes_read,
       SUM(sum_timer_read) AS sum_timer_read,
       SUM(count_write) AS count_write,
       SUM(sum_number_of_bytes_write) AS sum_number_of_bytes_write,
       SUM(sum_timer_write) AS sum_timer_write,
       SUM(count_misc) AS count_misc,
       SUM(sum_timer_misc) AS sum_timer_misc
  FROM performance_schema.file_summary_by_instance
 GROUP BY table_schema, table_name;
-- Copyright (c) 2014, 2024, Oracle and/or its affiliates.
--
-- This program is free software; you can redistribute it and/or modify
-- it under the terms of the GNU General Public License as published by
-- the Free Software Foundation; version 2 of the License.
--
-- This program is distributed in the hope that it will be useful,
-- but WITHOUT ANY WARRANTY; without even the implied warranty of
-- MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
-- GNU General Public License for more details.
--
-- You should have received a copy of the GNU General Public License
-- along with this program; if not, write to the Free Software
-- Foundation, Inc., 51 Franklin St, Fifth Floor, Boston, MA 02110-1301  USA

--
-- View: schema_table_statistics
--
-- Statistics around tables.
--
-- Ordered by the total wait time descending - top tables are most contended.
-- 
-- mysql> SELECT * FROM schema_table_statistics\G
-- *************************** 1. row ***************************
--      table_schema: sys
--        table_name: sys_config
--     total_latency: 0 ps
--      rows_fetched: 0
--     fetch_latency: 0 ps
--     rows_inserted: 0
--    insert_latency: 0 ps
--      rows_updated: 0
--    update_latency: 0 ps
--      rows_deleted: 0
--    delete_latency: 0 ps
--  io_read_requests: 8
--           io_read: 2.28 KiB
--   io_read_latency: 727.32 us
-- io_write_requests: 0
--          io_write: 0 bytes
--  io_write_latency: 0 ps
--  io_misc_requests: 10
--   io_misc_latency: 126.88 us
--

CREATE OR REPLACE
  ALGORITHM = TEMPTABLE
  DEFINER = 'mysql.sys'@'localhost'
  SQL SECURITY INVOKER 
VIEW schema_table_statistics (
  table_schema,
  table_name,
  total_latency,
  rows_fetched,
  fetch_latency,
  rows_inserted,
  insert_latency,
  rows_updated,
  update_latency,
  rows_deleted,
  delete_latency,
  io_read_requests,
  io_read,
  io_read_latency,
  io_write_requests,
  io_write,
  io_write_latency,
  io_misc_requests,
  io_misc_latency
) AS
SELECT pst.object_schema AS table_schema,
       pst.object_name AS table_name,
       format_pico_time(pst.sum_timer_wait) AS total_latency,
       pst.count_fetch AS rows_fetched,
       format_pico_time(pst.sum_timer_fetch) AS fetch_latency,
       pst.count_insert AS rows_inserted,
       format_pico_time(pst.sum_timer_insert) AS insert_latency,
       pst.count_update AS rows_updated,
       format_pico_time(pst.sum_timer_update) AS update_latency,
       pst.count_delete AS rows_deleted,
       format_pico_time(pst.sum_timer_delete) AS delete_latency,
       fsbi.count_read AS io_read_requests,
       format_bytes(fsbi.sum_number_of_bytes_read) AS io_read,
       format_pico_time(fsbi.sum_timer_read) AS io_read_latency,
       fsbi.count_write AS io_write_requests,
       format_bytes(fsbi.sum_number_of_bytes_write) AS io_write,
       format_pico_time(fsbi.sum_timer_write) AS io_write_latency,
       fsbi.count_misc AS io_misc_requests,
       format_pico_time(fsbi.sum_timer_misc) AS io_misc_latency
  FROM performance_schema.table_io_waits_summary_by_table AS pst
  LEFT JOIN x$ps_schema_table_statistics_io AS fsbi
    ON pst.object_schema = fsbi.table_schema
   AND pst.object_name = fsbi.table_name
 ORDER BY pst.sum_timer_wait DESC;
-- Copyright (c) 2014, 2024, Oracle and/or its affiliates.
--
-- This program is free software; you can redistribute it and/or modify
-- it under the terms of the GNU General Public License as published by
-- the Free Software Foundation; version 2 of the License.
--
-- This program is distributed in the hope that it will be useful,
-- but WITHOUT ANY WARRANTY; without even the implied warranty of
-- MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
-- GNU General Public License for more details.
--
-- You should have received a copy of the GNU General Public License
-- along with this program; if not, write to the Free Software
-- Foundation, Inc., 51 Franklin St, Fifth Floor, Boston, MA 02110-1301  USA

--
-- View: x$schema_table_statistics
--
-- Statistics around tables.
--
-- Ordered by the total wait time descending - top tables are most contended.
-- 
-- mysql> select * from x$schema_table_statistics\G
-- *************************** 1. row ***************************
--      table_schema: sys
--        table_name: sys_config
--     total_latency: 0
--      rows_fetched: 0
--     fetch_latency: 0
--     rows_inserted: 0
--    insert_latency: 0
--      rows_updated: 0
--    update_latency: 0
--      rows_deleted: 0
--    delete_latency: 0
--  io_read_requests: 8
--           io_read: 2336
--   io_read_latency: 727319710
-- io_write_requests: 0
--          io_write: 0
--  io_write_latency: 0
--  io_misc_requests: 10
--   io_misc_latency: 126879350
--
 
CREATE OR REPLACE
  ALGORITHM = TEMPTABLE
  DEFINER = 'mysql.sys'@'localhost'
  SQL SECURITY INVOKER 
VIEW x$schema_table_statistics (
  table_schema,
  table_name,
  total_latency,
  rows_fetched,
  fetch_latency,
  rows_inserted,
  insert_latency,
  rows_updated,
  update_latency,
  rows_deleted,
  delete_latency,
  io_read_requests,
  io_read,
  io_read_latency,
  io_write_requests,
  io_write,
  io_write_latency,
  io_misc_requests,
  io_misc_latency
) AS
SELECT pst.object_schema AS table_schema,
       pst.object_name AS table_name,
       pst.sum_timer_wait AS total_latency,
       pst.count_fetch AS rows_fetched,
       pst.sum_timer_fetch AS fetch_latency,
       pst.count_insert AS rows_inserted,
       pst.sum_timer_insert AS insert_latency,
       pst.count_update AS rows_updated,
       pst.sum_timer_update AS update_latency,
       pst.count_delete AS rows_deleted,
       pst.sum_timer_delete AS delete_latency,
       fsbi.count_read AS io_read_requests,
       fsbi.sum_number_of_bytes_read AS io_read,
       fsbi.sum_timer_read AS io_read_latency,
       fsbi.count_write AS io_write_requests,
       fsbi.sum_number_of_bytes_write AS io_write,
       fsbi.sum_timer_write AS io_write_latency,
       fsbi.count_misc AS io_misc_requests,
       fsbi.sum_timer_misc AS io_misc_latency
  FROM performance_schema.table_io_waits_summary_by_table AS pst
  LEFT JOIN x$ps_schema_table_statistics_io AS fsbi
    ON pst.object_schema = fsbi.table_schema
   AND pst.object_name = fsbi.table_name
 ORDER BY pst.sum_timer_wait DESC;
-- Copyright (c) 2014, 2024, Oracle and/or its affiliates.
--
-- This program is free software; you can redistribute it and/or modify
-- it under the terms of the GNU General Public License as published by
-- the Free Software Foundation; version 2 of the License.
--
-- This program is distributed in the hope that it will be useful,
-- but WITHOUT ANY WARRANTY; without even the implied warranty of
-- MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
-- GNU General Public License for more details.
--
-- You should have received a copy of the GNU General Public License
-- along with this program; if not, write to the Free Software
-- Foundation, Inc., 51 Franklin St, Fifth Floor, Boston, MA 02110-1301  USA

--
-- View: schema_table_statistics_with_buffer
--
-- Statistics around tables.
--
-- Ordered by the total wait time descending - top tables are most contended.
--
-- More statistics such as caching stats for the InnoDB buffer pool with InnoDB tables
--
-- mysql> select * from schema_table_statistics_with_buffer limit 1\G
-- *************************** 1. row ***************************
--                  table_schema: mem
--                    table_name: mysqlserver
--                  rows_fetched: 27087
--                 fetch_latency: 442.72 ms
--                 rows_inserted: 2
--                insert_latency: 185.04 us 
--                  rows_updated: 5096
--                update_latency: 1.39 s
--                  rows_deleted: 0
--                delete_latency: 0 ps
--              io_read_requests: 2565
--                 io_read_bytes: 1121627
--               io_read_latency: 10.07 ms
--             io_write_requests: 1691
--                io_write_bytes: 128383
--              io_write_latency: 14.17 ms
--              io_misc_requests: 2698
--               io_misc_latency: 433.66 ms
--           innodb_buffer_pages: 19
--    innodb_buffer_pages_hashed: 19
--       innodb_buffer_pages_old: 19
-- innodb_buffer_bytes_allocated: 311296
--      innodb_buffer_bytes_data: 1924
--     innodb_buffer_rows_cached: 2
--
 
CREATE OR REPLACE
  ALGORITHM = TEMPTABLE
  DEFINER = 'mysql.sys'@'localhost'
  SQL SECURITY INVOKER 
VIEW schema_table_statistics_with_buffer (
  table_schema,
  table_name,
  rows_fetched,
  fetch_latency,
  rows_inserted,
  insert_latency,
  rows_updated,
  update_latency,
  rows_deleted,
  delete_latency,
  io_read_requests,
  io_read,
  io_read_latency,
  io_write_requests,
  io_write,
  io_write_latency,
  io_misc_requests,
  io_misc_latency,
  innodb_buffer_allocated,
  innodb_buffer_data,
  innodb_buffer_free,
  innodb_buffer_pages,
  innodb_buffer_pages_hashed,
  innodb_buffer_pages_old,
  innodb_buffer_rows_cached
) AS
SELECT pst.object_schema AS table_schema,
       pst.object_name AS table_name,
       pst.count_fetch AS rows_fetched,
       format_pico_time(pst.sum_timer_fetch) AS fetch_latency,
       pst.count_insert AS rows_inserted,
       format_pico_time(pst.sum_timer_insert) AS insert_latency,
       pst.count_update AS rows_updated,
       format_pico_time(pst.sum_timer_update) AS update_latency,
       pst.count_delete AS rows_deleted,
       format_pico_time(pst.sum_timer_delete) AS delete_latency,
       fsbi.count_read AS io_read_requests,
       format_bytes(fsbi.sum_number_of_bytes_read) AS io_read,
       format_pico_time(fsbi.sum_timer_read) AS io_read_latency,
       fsbi.count_write AS io_write_requests,
       format_bytes(fsbi.sum_number_of_bytes_write) AS io_write,
       format_pico_time(fsbi.sum_timer_write) AS io_write_latency,
       fsbi.count_misc AS io_misc_requests,
       format_pico_time(fsbi.sum_timer_misc) AS io_misc_latency,
       format_bytes(ibp.allocated) AS innodb_buffer_allocated,
       format_bytes(ibp.data) AS innodb_buffer_data,
       format_bytes(ibp.allocated - ibp.data) AS innodb_buffer_free,
       ibp.pages AS innodb_buffer_pages,
       ibp.pages_hashed AS innodb_buffer_pages_hashed,
       ibp.pages_old AS innodb_buffer_pages_old,
       ibp.rows_cached AS innodb_buffer_rows_cached
  FROM performance_schema.table_io_waits_summary_by_table AS pst
  LEFT JOIN x$ps_schema_table_statistics_io AS fsbi
    ON pst.object_schema = fsbi.table_schema
   AND pst.object_name = fsbi.table_name
  LEFT JOIN sys.x$innodb_buffer_stats_by_table AS ibp
    ON pst.object_schema = ibp.object_schema
   AND pst.object_name = ibp.object_name
 ORDER BY pst.sum_timer_wait DESC;
-- Copyright (c) 2014, 2024, Oracle and/or its affiliates.
--
-- This program is free software; you can redistribute it and/or modify
-- it under the terms of the GNU General Public License as published by
-- the Free Software Foundation; version 2 of the License.
--
-- This program is distributed in the hope that it will be useful,
-- but WITHOUT ANY WARRANTY; without even the implied warranty of
-- MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
-- GNU General Public License for more details.
--
-- You should have received a copy of the GNU General Public License
-- along with this program; if not, write to the Free Software
-- Foundation, Inc., 51 Franklin St, Fifth Floor, Boston, MA 02110-1301  USA

--
-- View: x$schema_table_statistics_with_buffer
--
-- Statistics around tables.
--
-- Ordered by the total wait time descending - top tables are most contended.
--
-- More statistics such as caching stats for the InnoDB buffer pool with InnoDB tables
--
-- mysql> SELECT * FROM x$schema_table_statistics_with_buffer LIMIT 1\G
-- *************************** 1. row ***************************
--               table_schema: common_schema
--                 table_name: help_content
--               rows_fetched: 0
--              fetch_latency: 0
--              rows_inserted: 169
--             insert_latency: 409815527680
--               rows_updated: 0
--             update_latency: 0
--               rows_deleted: 0
--             delete_latency: 0
--           io_read_requests: 14
--                    io_read: 1180
--            io_read_latency: 52406770
--          io_write_requests: 131
--                   io_write: 11719246
--           io_write_latency: 133726902790
--           io_misc_requests: 61
--            io_misc_latency: 209081089750
--    innodb_buffer_allocated: 688128
--         innodb_buffer_data: 423667
--        innodb_buffer_pages: 42
-- innodb_buffer_pages_hashed: 42
--    innodb_buffer_pages_old: 42
--  innodb_buffer_rows_cached: 210
--
 
CREATE OR REPLACE
  ALGORITHM = TEMPTABLE
  DEFINER = 'mysql.sys'@'localhost'
  SQL SECURITY INVOKER 
VIEW x$schema_table_statistics_with_buffer (
  table_schema,
  table_name,
  rows_fetched,
  fetch_latency,
  rows_inserted,
  insert_latency,
  rows_updated,
  update_latency,
  rows_deleted,
  delete_latency,
  io_read_requests,
  io_read,
  io_read_latency,
  io_write_requests,
  io_write,
  io_write_latency,
  io_misc_requests,
  io_misc_latency,
  innodb_buffer_allocated,
  innodb_buffer_data,
  innodb_buffer_free,
  innodb_buffer_pages,
  innodb_buffer_pages_hashed,
  innodb_buffer_pages_old,
  innodb_buffer_rows_cached
) AS
SELECT pst.object_schema AS table_schema,
       pst.object_name AS table_name,
       pst.count_fetch AS rows_fetched,
       pst.sum_timer_fetch AS fetch_latency,
       pst.count_insert AS rows_inserted,
       pst.sum_timer_insert AS insert_latency,
       pst.count_update AS rows_updated,
       pst.sum_timer_update AS update_latency,
       pst.count_delete AS rows_deleted,
       pst.sum_timer_delete AS delete_latency,
       fsbi.count_read AS io_read_requests,
       fsbi.sum_number_of_bytes_read AS io_read,
       fsbi.sum_timer_read AS io_read_latency,
       fsbi.count_write AS io_write_requests,
       fsbi.sum_number_of_bytes_write AS io_write,
       fsbi.sum_timer_write AS io_write_latency,
       fsbi.count_misc AS io_misc_requests,
       fsbi.sum_timer_misc AS io_misc_latency,
       ibp.allocated AS innodb_buffer_allocated,
       ibp.data AS innodb_buffer_data,
       (ibp.allocated - ibp.data) AS innodb_buffer_free,
       ibp.pages AS innodb_buffer_pages,
       ibp.pages_hashed AS innodb_buffer_pages_hashed,
       ibp.pages_old AS innodb_buffer_pages_old,
       ibp.rows_cached AS innodb_buffer_rows_cached
  FROM performance_schema.table_io_waits_summary_by_table AS pst
  LEFT JOIN x$ps_schema_table_statistics_io AS fsbi
    ON pst.object_schema = fsbi.table_schema
   AND pst.object_name = fsbi.table_name
  LEFT JOIN sys.x$innodb_buffer_stats_by_table AS ibp
    ON pst.object_schema = ibp.object_schema
   AND pst.object_name = ibp.object_name
 ORDER BY pst.sum_timer_wait DESC;
-- Copyright (c) 2014, 2024, Oracle and/or its affiliates.
--
-- This program is free software; you can redistribute it and/or modify
-- it under the terms of the GNU General Public License as published by
-- the Free Software Foundation; version 2 of the License.
--
-- This program is distributed in the hope that it will be useful,
-- but WITHOUT ANY WARRANTY; without even the implied warranty of
-- MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
-- GNU General Public License for more details.
--
-- You should have received a copy of the GNU General Public License
-- along with this program; if not, write to the Free Software
-- Foundation, Inc., 51 Franklin St, Fifth Floor, Boston, MA 02110-1301  USA

--
-- View: schema_tables_with_full_table_scans
--
-- Find tables that are being accessed by full table scans
-- ordering by the number of rows scanned descending.
--
-- mysql> select * from schema_tables_with_full_table_scans limit 5;
-- +--------------------+--------------------------------+-------------------+-----------+
-- | object_schema      | object_name                    | rows_full_scanned | latency   |
-- +--------------------+--------------------------------+-------------------+-----------+
-- | mem30__instruments | fsstatistics                   |          10207042 | 13.10 s   |
-- | mem30__instruments | preparedstatementapidata       |            436428 | 973.27 ms |
-- | mem30__instruments | mysqlprocessactivity           |            411702 | 282.07 ms |
-- | mem30__instruments | querycachequeriesincachedata   |            374011 | 767.15 ms |
-- | mem30__instruments | rowaccessesdata                |            322321 | 1.55 s    |
-- +--------------------+--------------------------------+-------------------+-----------+
--

CREATE OR REPLACE
  ALGORITHM = MERGE
  DEFINER = 'mysql.sys'@'localhost'
  SQL SECURITY INVOKER 
VIEW schema_tables_with_full_table_scans (
  object_schema,
  object_name,
  rows_full_scanned,
  latency
) AS
SELECT object_schema, 
       object_name,
       count_read AS rows_full_scanned,
       format_pico_time(sum_timer_wait) AS latency
  FROM performance_schema.table_io_waits_summary_by_index_usage 
 WHERE index_name IS NULL
   AND count_read > 0
 ORDER BY count_read DESC;
-- Copyright (c) 2014, 2024, Oracle and/or its affiliates.
--
-- This program is free software; you can redistribute it and/or modify
-- it under the terms of the GNU General Public License as published by
-- the Free Software Foundation; version 2 of the License.
--
-- This program is distributed in the hope that it will be useful,
-- but WITHOUT ANY WARRANTY; without even the implied warranty of
-- MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
-- GNU General Public License for more details.
--
-- You should have received a copy of the GNU General Public License
-- along with this program; if not, write to the Free Software
-- Foundation, Inc., 51 Franklin St, Fifth Floor, Boston, MA 02110-1301  USA

--
-- View: x$schema_tables_with_full_table_scans
--
-- Find tables that are being accessed by full table scans
-- ordering by the number of rows scanned descending.
--
-- mysql> select * from x$schema_tables_with_full_table_scans limit 5;
-- +--------------------+------------------------------+-------------------+----------------+
-- | object_schema      | object_name                  | rows_full_scanned | latency        |
-- +--------------------+------------------------------+-------------------+----------------+
-- | mem30__instruments | fsstatistics                 |          10207042 | 13098927688488 |
-- | mem30__instruments | preparedstatementapidata     |            436428 |   973274338980 |
-- | mem30__instruments | mysqlprocessactivity         |            411702 |   282072434940 |
-- | mem30__instruments | querycachequeriesincachedata |            374011 |   767152380564 |
-- | mem30__instruments | rowaccessesdata              |            322321 |  1547594778456 |
-- +--------------------+------------------------------+-------------------+----------------+
--

CREATE OR REPLACE
  ALGORITHM = MERGE
  DEFINER = 'mysql.sys'@'localhost'
  SQL SECURITY INVOKER 
VIEW x$schema_tables_with_full_table_scans (
  object_schema,
  object_name,
  rows_full_scanned,
  latency
) AS
SELECT object_schema, 
       object_name,
       count_read AS rows_full_scanned,
       sum_timer_wait AS latency
  FROM performance_schema.table_io_waits_summary_by_index_usage 
 WHERE index_name IS NULL
   AND count_read > 0
 ORDER BY count_read DESC;
-- Copyright (c) 2014, 2024, Oracle and/or its affiliates.
--
-- This program is free software; you can redistribute it and/or modify
-- it under the terms of the GNU General Public License as published by
-- the Free Software Foundation; version 2 of the License.
--
-- This program is distributed in the hope that it will be useful,
-- but WITHOUT ANY WARRANTY; without even the implied warranty of
-- MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
-- GNU General Public License for more details.
--
-- You should have received a copy of the GNU General Public License
-- along with this program; if not, write to the Free Software
-- Foundation, Inc., 51 Franklin St, Fifth Floor, Boston, MA 02110-1301  USA

--
-- View: schema_unused_indexes
-- 
-- Finds indexes that have had no events against them (and hence, no usage).
--
-- To trust whether the data from this view is representative of your workload,
-- you should ensure that the server has been up for a representative amount of
-- time before using it.
--
-- PRIMARY (key) indexes are ignored.
--
-- mysql> select * from schema_unused_indexes limit 5;
-- +--------------------+---------------------+--------------------+
-- | object_schema      | object_name         | index_name         |
-- +--------------------+---------------------+--------------------+
-- | mem30__bean_config | plists              | path               |
-- | mem30__config      | group_selections    | name               |
-- | mem30__config      | notification_groups | name               |
-- | mem30__config      | user_form_defaults  | FKC1AEF1F9E7EE2CFB |
-- | mem30__enterprise  | whats_new_entries   | entryId            |
-- +--------------------+---------------------+--------------------+
--

CREATE OR REPLACE
  ALGORITHM = MERGE
  DEFINER = 'mysql.sys'@'localhost'
  SQL SECURITY INVOKER 
VIEW schema_unused_indexes (
  object_schema,
  object_name,
  index_name
) AS
SELECT t.object_schema,
       t.object_name,
       t.index_name
  FROM performance_schema.table_io_waits_summary_by_index_usage t
 INNER JOIN information_schema.statistics s
    ON t.object_schema = s.table_schema
   AND t.object_name = s.table_name
   AND t.index_name = s.index_name
 WHERE t.index_name IS NOT NULL
   AND t.count_star = 0
   AND t.object_schema != 'mysql'
   AND t.index_name != 'PRIMARY'
   AND s.NON_UNIQUE = 1
   AND s.SEQ_IN_INDEX = 1
 ORDER BY object_schema, object_name;
-- Copyright (c) 2015, 2024, Oracle and/or its affiliates.
--
-- This program is free software; you can redistribute it and/or modify
-- it under the terms of the GNU General Public License as published by
-- the Free Software Foundation; version 2 of the License.
--
-- This program is distributed in the hope that it will be useful,
-- but WITHOUT ANY WARRANTY; without even the implied warranty of
-- MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
-- GNU General Public License for more details.
--
-- You should have received a copy of the GNU General Public License
-- along with this program; if not, write to the Free Software
-- Foundation, Inc., 51 Franklin St, Fifth Floor, Boston, MA 02110-1301 USA

--
-- View: schema_table_lock_waits
--
-- Shows sessions that are blocked waiting on table metadata locks, and 
-- who is blocking them.
--
-- mysql> select * from sys.schema_table_lock_waits\G
-- *************************** 1. row ***************************
--                object_schema: test
--                  object_name: t
--            waiting_thread_id: 43
--                  waiting_pid: 21
--              waiting_account: msandbox@localhost
--            waiting_lock_type: SHARED_UPGRADABLE
--        waiting_lock_duration: TRANSACTION
--                waiting_query: alter table test.t add foo int
--           waiting_query_secs: 988
--  waiting_query_rows_affected: 0
--  waiting_query_rows_examined: 0
--           blocking_thread_id: 42
--                 blocking_pid: 20
--             blocking_account: msandbox@localhost
--           blocking_lock_type: SHARED_NO_READ_WRITE
--       blocking_lock_duration: TRANSACTION
--      sql_kill_blocking_query: KILL QUERY 20
-- sql_kill_blocking_connection: KILL 20
--

CREATE OR REPLACE
  ALGORITHM = TEMPTABLE
  DEFINER = 'mysql.sys'@'localhost'
  SQL SECURITY INVOKER 
VIEW schema_table_lock_waits (
  object_schema,
  object_name,
  waiting_thread_id,
  waiting_pid,
  waiting_account,
  waiting_lock_type,
  waiting_lock_duration,
  waiting_query,
  waiting_query_secs,
  waiting_query_rows_affected,
  waiting_query_rows_examined,
  blocking_thread_id,
  blocking_pid,
  blocking_account,
  blocking_lock_type,
  blocking_lock_duration,
  sql_kill_blocking_query,
  sql_kill_blocking_connection
) AS
SELECT g.object_schema AS object_schema,
       g.object_name AS object_name,
       pt.thread_id AS waiting_thread_id,
       pt.processlist_id AS waiting_pid,
       sys.ps_thread_account(p.owner_thread_id) AS waiting_account,
       p.lock_type AS waiting_lock_type,
       p.lock_duration AS waiting_lock_duration,
       sys.format_statement(pt.processlist_info) AS waiting_query,
       pt.processlist_time AS waiting_query_secs,
       ps.rows_affected AS waiting_query_rows_affected,
       ps.rows_examined AS waiting_query_rows_examined,
       gt.thread_id AS blocking_thread_id,
       gt.processlist_id AS blocking_pid,
       sys.ps_thread_account(g.owner_thread_id) AS blocking_account,
       g.lock_type AS blocking_lock_type,
       g.lock_duration AS blocking_lock_duration,
       CONCAT('KILL QUERY ', gt.processlist_id) AS sql_kill_blocking_query,
       CONCAT('KILL ', gt.processlist_id) AS sql_kill_blocking_connection
  FROM performance_schema.metadata_locks g
 INNER JOIN performance_schema.metadata_locks p 
    ON g.object_type = p.object_type
   AND g.object_schema = p.object_schema
   AND g.object_name = p.object_name
   AND g.lock_status = 'GRANTED'
   AND p.lock_status = 'PENDING'
 INNER JOIN performance_schema.threads gt ON g.owner_thread_id = gt.thread_id
 INNER JOIN performance_schema.threads pt ON p.owner_thread_id = pt.thread_id
  LEFT JOIN performance_schema.events_statements_current gs ON g.owner_thread_id = gs.thread_id
  LEFT JOIN performance_schema.events_statements_current ps ON p.owner_thread_id = ps.thread_id
 WHERE g.object_type = 'TABLE';
-- Copyright (c) 2015, 2024, Oracle and/or its affiliates.
--
-- This program is free software; you can redistribute it and/or modify
-- it under the terms of the GNU General Public License as published by
-- the Free Software Foundation; version 2 of the License.
--
-- This program is distributed in the hope that it will be useful,
-- but WITHOUT ANY WARRANTY; without even the implied warranty of
-- MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
-- GNU General Public License for more details.
--
-- You should have received a copy of the GNU General Public License
-- along with this program; if not, write to the Free Software
-- Foundation, Inc., 51 Franklin St, Fifth Floor, Boston, MA 02110-1301 USA

--
-- View: schema_table_lock_waits
--
-- Shows sessions that are blocked waiting on table metadata locks, and 
-- who is blocking them.
--
-- mysql> select * from sys.x$schema_table_lock_waits\G
-- *************************** 1. row ***************************
--                object_schema: test
--                  object_name: t
--            waiting_thread_id: 43
--                  waiting_pid: 21
--              waiting_account: msandbox@localhost
--            waiting_lock_type: SHARED_UPGRADABLE
--        waiting_lock_duration: TRANSACTION
--                waiting_query: alter table test.t add foo int
--           waiting_query_secs: 990
--  waiting_query_rows_affected: 0
--  waiting_query_rows_examined: 0
--           blocking_thread_id: 42
--                 blocking_pid: 20
--             blocking_account: msandbox@localhost
--           blocking_lock_type: SHARED_NO_READ_WRITE
--       blocking_lock_duration: TRANSACTION
--      sql_kill_blocking_query: KILL QUERY 20
-- sql_kill_blocking_connection: KILL 20
--

CREATE OR REPLACE
  ALGORITHM = TEMPTABLE
  DEFINER = 'mysql.sys'@'localhost'
  SQL SECURITY INVOKER 
VIEW x$schema_table_lock_waits (
  object_schema,
  object_name,
  waiting_thread_id,
  waiting_pid,
  waiting_account,
  waiting_lock_type,
  waiting_lock_duration,
  waiting_query,
  waiting_query_secs,
  waiting_query_rows_affected,
  waiting_query_rows_examined,
  blocking_thread_id,
  blocking_pid,
  blocking_account,
  blocking_lock_type,
  blocking_lock_duration,
  sql_kill_blocking_query,
  sql_kill_blocking_connection
) AS
SELECT g.object_schema AS object_schema,
       g.object_name AS object_name,
       pt.thread_id AS waiting_thread_id,
       pt.processlist_id AS waiting_pid,
       sys.ps_thread_account(p.owner_thread_id) AS waiting_account,
       p.lock_type AS waiting_lock_type,
       p.lock_duration AS waiting_lock_duration,
       pt.processlist_info AS waiting_query,
       pt.processlist_time AS waiting_query_secs,
       ps.rows_affected AS waiting_query_rows_affected,
       ps.rows_examined AS waiting_query_rows_examined,
       gt.thread_id AS blocking_thread_id,
       gt.processlist_id AS blocking_pid,
       sys.ps_thread_account(g.owner_thread_id) AS blocking_account,
       g.lock_type AS blocking_lock_type,
       g.lock_duration AS blocking_lock_duration,
       CONCAT('KILL QUERY ', gt.processlist_id) AS sql_kill_blocking_query,
       CONCAT('KILL ', gt.processlist_id) AS sql_kill_blocking_connection
  FROM performance_schema.metadata_locks g
 INNER JOIN performance_schema.metadata_locks p 
    ON g.object_type = p.object_type
   AND g.object_schema = p.object_schema
   AND g.object_name = p.object_name
   AND g.lock_status = 'GRANTED'
   AND p.lock_status = 'PENDING'
 INNER JOIN performance_schema.threads gt ON g.owner_thread_id = gt.thread_id
 INNER JOIN performance_schema.threads pt ON p.owner_thread_id = pt.thread_id
  LEFT JOIN performance_schema.events_statements_current gs ON g.owner_thread_id = gs.thread_id
  LEFT JOIN performance_schema.events_statements_current ps ON p.owner_thread_id = ps.thread_id
 WHERE g.object_type = 'TABLE';
-- Copyright (c) 2014, 2024, Oracle and/or its affiliates.
--
-- This program is free software; you can redistribute it and/or modify
-- it under the terms of the GNU General Public License as published by
-- the Free Software Foundation; version 2 of the License.
--
-- This program is distributed in the hope that it will be useful,
-- but WITHOUT ANY WARRANTY; without even the implied warranty of
-- MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
-- GNU General Public License for more details.
--
-- You should have received a copy of the GNU General Public License
-- along with this program; if not, write to the Free Software
-- Foundation, Inc., 51 Franklin St, Fifth Floor, Boston, MA 02110-1301  USA

--
-- View: statement_analysis
--
-- Lists a normalized statement view with aggregated statistics,
-- mimics the MySQL Enterprise Monitor Query Analysis view,
-- ordered by the total execution time per normalized statement
-- 
-- mysql> select- * from statement_analysis limit 1\G
-- *************************** 1. row--**************************
--             query: SELECT * FROM `schema_object_o ... MA` , `information_schema` ...
--                db: sys
--         full_scan: *
--        exec_count: 2
--         err_count: 0
--        warn_count: 0
--     total_latency: 16.75 s
--       max_latency: 16.57 s
--       avg_latency: 8.38 s
--      lock_latency: 16.69 s
--         rows_sent: 84
--     rows_sent_avg: 42
--     rows_examined: 20012
--     rows_affected: 0
-- rows_affected_avg: 0
-- rows_examined_avg: 10006
--        tmp_tables: 378
--   tmp_disk_tables: 66
--       rows_sorted: 168
-- sort_merge_passes: 0
--            digest: 54f9bd520f0bbf15db0c2ed93386bec9
--        first_seen: 2014-03-07 13:13:41
--         last_seen: 2014-03-07 13:13:48
--

CREATE OR REPLACE
  ALGORITHM = MERGE
  DEFINER = 'mysql.sys'@'localhost'
  SQL SECURITY INVOKER 
VIEW statement_analysis (
  query,
  db,
  full_scan,
  exec_count,
  err_count,
  warn_count,
  total_latency,
  max_latency,
  avg_latency,
  lock_latency,
  cpu_latency,
  rows_sent,
  rows_sent_avg,
  rows_examined,
  rows_examined_avg,
  rows_affected,
  rows_affected_avg,
  tmp_tables,
  tmp_disk_tables,
  rows_sorted,
  sort_merge_passes,
  max_controlled_memory,
  max_total_memory,
  digest,
  first_seen,
  last_seen
) AS
SELECT sys.format_statement(DIGEST_TEXT) AS query,
       SCHEMA_NAME AS db,
       IF(SUM_NO_GOOD_INDEX_USED > 0 OR SUM_NO_INDEX_USED > 0, '*', '') AS full_scan,
       COUNT_STAR AS exec_count,
       SUM_ERRORS AS err_count,
       SUM_WARNINGS AS warn_count,
       format_pico_time(SUM_TIMER_WAIT) AS total_latency,
       format_pico_time(MAX_TIMER_WAIT) AS max_latency,
       format_pico_time(AVG_TIMER_WAIT) AS avg_latency,
       format_pico_time(SUM_LOCK_TIME) AS lock_latency,
       format_pico_time(SUM_CPU_TIME) AS cpu_latency,
       SUM_ROWS_SENT AS rows_sent,
       ROUND(IFNULL(SUM_ROWS_SENT / NULLIF(COUNT_STAR, 0), 0)) AS rows_sent_avg,
       SUM_ROWS_EXAMINED AS rows_examined,
       ROUND(IFNULL(SUM_ROWS_EXAMINED / NULLIF(COUNT_STAR, 0), 0))  AS rows_examined_avg,
       SUM_ROWS_AFFECTED AS rows_affected,
       ROUND(IFNULL(SUM_ROWS_AFFECTED / NULLIF(COUNT_STAR, 0), 0))  AS rows_affected_avg,
       SUM_CREATED_TMP_TABLES AS tmp_tables,
       SUM_CREATED_TMP_DISK_TABLES AS tmp_disk_tables,
       SUM_SORT_ROWS AS rows_sorted,
       SUM_SORT_MERGE_PASSES AS sort_merge_passes,
       format_bytes(MAX_CONTROLLED_MEMORY) AS max_controlled_memory,
       format_bytes(MAX_TOTAL_MEMORY) AS max_total_memory,
       DIGEST AS digest,
       FIRST_SEEN AS first_seen,
       LAST_SEEN as last_seen
  FROM performance_schema.events_statements_summary_by_digest
ORDER BY SUM_TIMER_WAIT DESC;
-- Copyright (c) 2014, 2024, Oracle and/or its affiliates.
--
-- This program is free software; you can redistribute it and/or modify
-- it under the terms of the GNU General Public License as published by
-- the Free Software Foundation; version 2 of the License.
--
-- This program is distributed in the hope that it will be useful,
-- but WITHOUT ANY WARRANTY; without even the implied warranty of
-- MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
-- GNU General Public License for more details.
--
-- You should have received a copy of the GNU General Public License
-- along with this program; if not, write to the Free Software
-- Foundation, Inc., 51 Franklin St, Fifth Floor, Boston, MA 02110-1301  USA

--
-- View: x$statement_analysis
--
-- Lists a normalized statement view with aggregated statistics,
-- mimics the MySQL Enterprise Monitor Query Analysis view,
-- ordered by the total execution time per normalized statement
-- 
-- mysql> select * from x$statement_analysis limit 1\G
-- *************************** 1. row ***************************
--                query: SELECT * FROM `schema_object_overview` SELECT `information_schema` . `routines`  -- truncated
--                   db: sys
--            full_scan: *
--           exec_count: 2
-- exec_secondary_count: 2
--            err_count: 0
--           warn_count: 0
--        total_latency: 16751388791000
--          max_latency: 16566171163000
--          avg_latency: 8375694395000
--         lock_latency: 16686483000000
--            rows_sent: 84
--        rows_sent_avg: 42
--        rows_examined: 20012
--    rows_examined_avg: 10006
--        rows_affected: 0
--    rows_affected_avg: 0
--           tmp_tables: 378
--      tmp_disk_tables: 66
--          rows_sorted: 168
--    sort_merge_passes: 0
--               digest: 54f9bd520f0bbf15db0c2ed93386bec9
--           first_seen: 2014-03-07 13:13:41
--            last_seen: 2014-03-07 13:13:48
--

CREATE OR REPLACE
  ALGORITHM = MERGE
  DEFINER = 'mysql.sys'@'localhost'
  SQL SECURITY INVOKER 
VIEW x$statement_analysis (
  query,
  db,
  full_scan,
  exec_count,
  exec_secondary_count,
  err_count,
  warn_count,
  total_latency,
  max_latency,
  avg_latency,
  lock_latency,
  cpu_latency,
  rows_sent,
  rows_sent_avg,
  rows_examined,
  rows_examined_avg,
  rows_affected,
  rows_affected_avg,
  tmp_tables,
  tmp_disk_tables,
  rows_sorted,
  sort_merge_passes,
  max_controlled_memory,
  max_total_memory,
  digest,
  first_seen,
  last_seen
) AS
SELECT DIGEST_TEXT AS query,
       SCHEMA_NAME AS db,
       IF(SUM_NO_GOOD_INDEX_USED > 0 OR SUM_NO_INDEX_USED > 0, '*', '') AS full_scan,
       COUNT_STAR AS exec_count,
       COUNT_SECONDARY AS exec_secondary_count,
       SUM_ERRORS AS err_count,
       SUM_WARNINGS AS warn_count,
       SUM_TIMER_WAIT AS total_latency,
       MAX_TIMER_WAIT AS max_latency,
       AVG_TIMER_WAIT AS avg_latency,
       SUM_LOCK_TIME AS lock_latency,
       SUM_CPU_TIME AS cpu_latency,
       SUM_ROWS_SENT AS rows_sent,
       ROUND(IFNULL(SUM_ROWS_SENT / NULLIF(COUNT_STAR, 0), 0)) AS rows_sent_avg,
       SUM_ROWS_EXAMINED AS rows_examined,
       ROUND(IFNULL(SUM_ROWS_EXAMINED / NULLIF(COUNT_STAR, 0), 0))  AS rows_examined_avg,
       SUM_ROWS_AFFECTED AS rows_affected,
       ROUND(IFNULL(SUM_ROWS_AFFECTED / NULLIF(COUNT_STAR, 0), 0))  AS rows_affected_avg,
       SUM_CREATED_TMP_TABLES AS tmp_tables,
       SUM_CREATED_TMP_DISK_TABLES AS tmp_disk_tables,
       SUM_SORT_ROWS AS rows_sorted,
       SUM_SORT_MERGE_PASSES AS sort_merge_passes,
       MAX_CONTROLLED_MEMORY AS max_controlled_memory,
       MAX_TOTAL_MEMORY AS max_total_memory,
       DIGEST AS digest,
       FIRST_SEEN AS first_seen,
       LAST_SEEN as last_seen
  FROM performance_schema.events_statements_summary_by_digest
ORDER BY SUM_TIMER_WAIT DESC;
-- Copyright (c) 2014, 2024, Oracle and/or its affiliates.
--
-- This program is free software; you can redistribute it and/or modify
-- it under the terms of the GNU General Public License as published by
-- the Free Software Foundation; version 2 of the License.
--
-- This program is distributed in the hope that it will be useful,
-- but WITHOUT ANY WARRANTY; without even the implied warranty of
-- MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
-- GNU General Public License for more details.
--
-- You should have received a copy of the GNU General Public License
-- along with this program; if not, write to the Free Software
-- Foundation, Inc., 51 Franklin St, Fifth Floor, Boston, MA 02110-1301  USA

--
-- View: statements_with_errors_or_warnings
--
-- Lists all normalized statements that have raised errors or warnings.
--
-- mysql> select * from statements_with_errors_or_warnings LIMIT 1\G
-- *************************** 1. row ***************************
--       query: CREATE OR REPLACE ALGORITHM =  ... _delete` AS `rows_deleted` ...
--          db: sys
--  exec_count: 2
--      errors: 1
--   error_pct: 50.0000
--    warnings: 0
-- warning_pct: 0.0000
--  first_seen: 2014-03-07 12:56:54
--   last_seen: 2014-03-07 13:01:01
--      digest: 943a788859e623d5f7798ba0ae0fd8a9
--

CREATE OR REPLACE
  ALGORITHM = MERGE
  DEFINER = 'mysql.sys'@'localhost'
  SQL SECURITY INVOKER 
VIEW statements_with_errors_or_warnings (
  query,
  db,
  exec_count,
  errors,
  error_pct,
  warnings,
  warning_pct,
  first_seen,
  last_seen,
  digest
) AS
SELECT sys.format_statement(DIGEST_TEXT) AS query,
       SCHEMA_NAME as db,
       COUNT_STAR AS exec_count,
       SUM_ERRORS AS errors,
       IFNULL(SUM_ERRORS / NULLIF(COUNT_STAR, 0), 0) * 100 as error_pct,
       SUM_WARNINGS AS warnings,
       IFNULL(SUM_WARNINGS / NULLIF(COUNT_STAR, 0), 0) * 100 as warning_pct,
       FIRST_SEEN as first_seen,
       LAST_SEEN as last_seen,
       DIGEST AS digest
  FROM performance_schema.events_statements_summary_by_digest
 WHERE SUM_ERRORS > 0
    OR SUM_WARNINGS > 0
ORDER BY SUM_ERRORS DESC, SUM_WARNINGS DESC;
-- Copyright (c) 2014, 2024, Oracle and/or its affiliates.
--
-- This program is free software; you can redistribute it and/or modify
-- it under the terms of the GNU General Public License as published by
-- the Free Software Foundation; version 2 of the License.
--
-- This program is distributed in the hope that it will be useful,
-- but WITHOUT ANY WARRANTY; without even the implied warranty of
-- MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
-- GNU General Public License for more details.
--
-- You should have received a copy of the GNU General Public License
-- along with this program; if not, write to the Free Software
-- Foundation, Inc., 51 Franklin St, Fifth Floor, Boston, MA 02110-1301 USA

--
-- View: x$statements_with_errors_or_warnings
--
-- Lists all normalized statements that have raised errors or warnings.
--
-- mysql> select * from x$statements_with_errors_or_warnings LIMIT 1\G
-- *************************** 1. row ***************************
--       query: CREATE OR REPLACE ALGORITHM = TEMPTABLE DEFINER = ? @ ? SQL SECURITY INVOKER VIEW ... truncated
--          db: sys
--  exec_count: 2
--      errors: 1
--   error_pct: 50.0000
--    warnings: 0
-- warning_pct: 0.0000
--  first_seen: 2014-03-07 12:56:54
--   last_seen: 2014-03-07 13:01:01
--      digest: 943a788859e623d5f7798ba0ae0fd8a9
--

CREATE OR REPLACE
  ALGORITHM = MERGE
  DEFINER = 'mysql.sys'@'localhost'
  SQL SECURITY INVOKER 
VIEW x$statements_with_errors_or_warnings (
  query,
  db,
  exec_count,
  errors,
  error_pct,
  warnings,
  warning_pct,
  first_seen,
  last_seen,
  digest
) AS
SELECT DIGEST_TEXT AS query,
       SCHEMA_NAME as db,
       COUNT_STAR AS exec_count,
       SUM_ERRORS AS errors,
       IFNULL(SUM_ERRORS / NULLIF(COUNT_STAR, 0), 0) * 100 as error_pct,
       SUM_WARNINGS AS warnings,
       IFNULL(SUM_WARNINGS / NULLIF(COUNT_STAR, 0), 0) * 100 as warning_pct,
       FIRST_SEEN as first_seen,
       LAST_SEEN as last_seen,
       DIGEST AS digest
  FROM performance_schema.events_statements_summary_by_digest
 WHERE SUM_ERRORS > 0
    OR SUM_WARNINGS > 0
ORDER BY SUM_ERRORS DESC, SUM_WARNINGS DESC;
-- Copyright (c) 2014, 2024, Oracle and/or its affiliates.
--
-- This program is free software; you can redistribute it and/or modify
-- it under the terms of the GNU General Public License as published by
-- the Free Software Foundation; version 2 of the License.
--
-- This program is distributed in the hope that it will be useful,
-- but WITHOUT ANY WARRANTY; without even the implied warranty of
-- MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
-- GNU General Public License for more details.
--
-- You should have received a copy of the GNU General Public License
-- along with this program; if not, write to the Free Software
-- Foundation, Inc., 51 Franklin St, Fifth Floor, Boston, MA 02110-1301 USA

--
-- View: statements_with_full_table_scans
--
-- Lists all normalized statements that use have done a full table scan
-- ordered by number the percentage of times a full scan was done,
-- then by the statement latency.
--
-- This view ignores SHOW statements, as these always cause a full table scan,
-- and there is nothing that can be done about this.
--
-- mysql> select * from statements_with_full_table_scans limit 1\G
-- *************************** 1. row ***************************
--                    query: SELECT * FROM `schema_tables_w ... ex_usage` . `COUNT_READ` DESC
--                       db: sys
--               exec_count: 1
--            total_latency: 88.20 ms
--      no_index_used_count: 1
-- no_good_index_used_count: 0
--        no_index_used_pct: 100
--                rows_sent: 0
--            rows_examined: 1501
--            rows_sent_avg: 0
--        rows_examined_avg: 1501
--               first_seen: 2014-03-07 13:58:20
--                last_seen: 2014-03-07 13:58:20
--                   digest: 64baecd5c1e1e1651a6b92e55442a288
--

CREATE OR REPLACE
  ALGORITHM = MERGE
  DEFINER = 'mysql.sys'@'localhost'
  SQL SECURITY INVOKER 
VIEW statements_with_full_table_scans (
  query,
  db,
  exec_count,
  total_latency,
  no_index_used_count,
  no_good_index_used_count,
  no_index_used_pct,
  rows_sent,
  rows_examined,
  rows_sent_avg,
  rows_examined_avg,
  first_seen,
  last_seen,
  digest
) AS
SELECT sys.format_statement(DIGEST_TEXT) AS query,
       SCHEMA_NAME as db,
       COUNT_STAR AS exec_count,
       format_pico_time(SUM_TIMER_WAIT) AS total_latency,
       SUM_NO_INDEX_USED AS no_index_used_count,
       SUM_NO_GOOD_INDEX_USED AS no_good_index_used_count,
       ROUND(IFNULL(SUM_NO_INDEX_USED / NULLIF(COUNT_STAR, 0), 0) * 100) AS no_index_used_pct,
       SUM_ROWS_SENT AS rows_sent,
       SUM_ROWS_EXAMINED AS rows_examined,
       ROUND(SUM_ROWS_SENT/COUNT_STAR) AS rows_sent_avg,
       ROUND(SUM_ROWS_EXAMINED/COUNT_STAR) AS rows_examined_avg,
       FIRST_SEEN as first_seen,
       LAST_SEEN as last_seen,
       DIGEST AS digest
  FROM performance_schema.events_statements_summary_by_digest
 WHERE (SUM_NO_INDEX_USED > 0
    OR SUM_NO_GOOD_INDEX_USED > 0)
   AND DIGEST_TEXT NOT LIKE 'SHOW%'
 ORDER BY no_index_used_pct DESC, total_latency DESC;
-- Copyright (c) 2014, 2024, Oracle and/or its affiliates.
--
-- This program is free software; you can redistribute it and/or modify
-- it under the terms of the GNU General Public License as published by
-- the Free Software Foundation; version 2 of the License.
--
-- This program is distributed in the hope that it will be useful,
-- but WITHOUT ANY WARRANTY; without even the implied warranty of
-- MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
-- GNU General Public License for more details.
--
-- You should have received a copy of the GNU General Public License
-- along with this program; if not, write to the Free Software
-- Foundation, Inc., 51 Franklin St, Fifth Floor, Boston, MA 02110-1301 USA

--
-- View: x$statements_with_full_table_scans
--
-- Lists all normalized statements that use have done a full table scan
-- ordered by number the percentage of times a full scan was done,
-- then by the statement latency.
--
-- This view ignores SHOW statements, as these always cause a full table scan,
-- and there is nothing that can be done about this.
--
-- mysql> select * from x$statements_with_full_table_scans limit 1\G
-- *************************** 1. row ***************************
--                    query: SELECT * FROM `schema_object_overview` SELECT `information_schema` . `routines` . `ROUTINE_SCHEMA` // truncated
--                       db: sys
--               exec_count: 2
--            total_latency: 16751388791000
--      no_index_used_count: 2
-- no_good_index_used_count: 0
--        no_index_used_pct: 100
--                rows_sent: 84
--            rows_examined: 20012
--            rows_sent_avg: 42
--        rows_examined_avg: 10006
--               first_seen: 2014-03-07 13:13:41
--                last_seen: 2014-03-07 13:13:48
--                   digest: 54f9bd520f0bbf15db0c2ed93386bec9
--

CREATE OR REPLACE
  ALGORITHM = MERGE
  DEFINER = 'mysql.sys'@'localhost'
  SQL SECURITY INVOKER 
VIEW x$statements_with_full_table_scans (
  query,
  db,
  exec_count,
  total_latency,
  no_index_used_count,
  no_good_index_used_count,
  no_index_used_pct,
  rows_sent,
  rows_examined,
  rows_sent_avg,
  rows_examined_avg,
  first_seen,
  last_seen,
  digest
) AS
SELECT DIGEST_TEXT AS query,
       SCHEMA_NAME as db,
       COUNT_STAR AS exec_count,
       SUM_TIMER_WAIT AS total_latency,
       SUM_NO_INDEX_USED AS no_index_used_count,
       SUM_NO_GOOD_INDEX_USED AS no_good_index_used_count,
       ROUND(IFNULL(SUM_NO_INDEX_USED / NULLIF(COUNT_STAR, 0), 0) * 100) AS no_index_used_pct,
       SUM_ROWS_SENT AS rows_sent,
       SUM_ROWS_EXAMINED AS rows_examined,
       ROUND(SUM_ROWS_SENT/COUNT_STAR) AS rows_sent_avg,
       ROUND(SUM_ROWS_EXAMINED/COUNT_STAR) AS rows_examined_avg,
       FIRST_SEEN as first_seen,
       LAST_SEEN as last_seen,
       DIGEST AS digest
  FROM performance_schema.events_statements_summary_by_digest
 WHERE (SUM_NO_INDEX_USED > 0
    OR SUM_NO_GOOD_INDEX_USED > 0)
   AND DIGEST_TEXT NOT LIKE 'SHOW%'
 ORDER BY no_index_used_pct DESC, total_latency DESC;
-- Copyright (c) 2014, 2024, Oracle and/or its affiliates.
--
-- This program is free software; you can redistribute it and/or modify
-- it under the terms of the GNU General Public License as published by
-- the Free Software Foundation; version 2 of the License.
--
-- This program is distributed in the hope that it will be useful,
-- but WITHOUT ANY WARRANTY; without even the implied warranty of
-- MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
-- GNU General Public License for more details.
--
-- You should have received a copy of the GNU General Public License
-- along with this program; if not, write to the Free Software
-- Foundation, Inc., 51 Franklin St, Fifth Floor, Boston, MA 02110-1301 USA

--
-- View: x$ps_digest_avg_latency_distribution
--
-- Helper view for x$ps_digest_95th_percentile_by_avg_us
--

CREATE OR REPLACE
  ALGORITHM = TEMPTABLE
  DEFINER = 'mysql.sys'@'localhost'
  SQL SECURITY INVOKER 
VIEW x$ps_digest_avg_latency_distribution (
  cnt,
  avg_us
) AS
SELECT COUNT(*) cnt, 
       ROUND(avg_timer_wait/1000000) AS avg_us
  FROM performance_schema.events_statements_summary_by_digest
 GROUP BY avg_us;
-- Copyright (c) 2014, 2024, Oracle and/or its affiliates.
--
-- This program is free software; you can redistribute it and/or modify
-- it under the terms of the GNU General Public License as published by
-- the Free Software Foundation; version 2 of the License.
--
-- This program is distributed in the hope that it will be useful,
-- but WITHOUT ANY WARRANTY; without even the implied warranty of
-- MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
-- GNU General Public License for more details.
--
-- You should have received a copy of the GNU General Public License
-- along with this program; if not, write to the Free Software
-- Foundation, Inc., 51 Franklin St, Fifth Floor, Boston, MA 02110-1301 USA

--
-- View: x$ps_digest_95th_percentile_by_avg_us
--
-- Helper view for statements_with_runtimes_in_95th_percentile.
-- Lists the 95th percentile runtime, for all statements
--
-- mysql> select * from x$ps_digest_95th_percentile_by_avg_us;
-- +--------+------------+
-- | avg_us | percentile |
-- +--------+------------+
-- |    964 |     0.9525 |
-- +--------+------------+
--

CREATE OR REPLACE
  ALGORITHM = TEMPTABLE
  DEFINER = 'mysql.sys'@'localhost'
  SQL SECURITY INVOKER 
VIEW x$ps_digest_95th_percentile_by_avg_us (
  avg_us,
  percentile
) AS
SELECT s2.avg_us avg_us,
       IFNULL(SUM(s1.cnt)/NULLIF((SELECT COUNT(*) FROM performance_schema.events_statements_summary_by_digest), 0), 0) percentile
  FROM sys.x$ps_digest_avg_latency_distribution AS s1
  JOIN sys.x$ps_digest_avg_latency_distribution AS s2
    ON s1.avg_us <= s2.avg_us
 GROUP BY s2.avg_us
HAVING IFNULL(SUM(s1.cnt)/NULLIF((SELECT COUNT(*) FROM performance_schema.events_statements_summary_by_digest), 0), 0) > 0.95
 ORDER BY percentile
 LIMIT 1;
-- Copyright (c) 2014, 2024, Oracle and/or its affiliates.
--
-- This program is free software; you can redistribute it and/or modify
-- it under the terms of the GNU General Public License as published by
-- the Free Software Foundation; version 2 of the License.
--
-- This program is distributed in the hope that it will be useful,
-- but WITHOUT ANY WARRANTY; without even the implied warranty of
-- MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
-- GNU General Public License for more details.
--
-- You should have received a copy of the GNU General Public License
-- along with this program; if not, write to the Free Software
-- Foundation, Inc., 51 Franklin St, Fifth Floor, Boston, MA 02110-1301 USA

--
-- View: statements_with_runtimes_in_95th_percentile
--
-- List all statements whose average runtime, in microseconds, is in the top 95th percentile.
-- 
-- mysql> select * from statements_with_runtimes_in_95th_percentile limit 5;
-- +-------------------------------------------------------------------+------+-----------+------------+-----------+------------+---------------+-------------+-------------+-----------+---------------+---------------+-------------------+---------------------+---------------------+----------------------------------+
-- | query                                                             | db   | full_scan | exec_count | err_count | warn_count | total_latency | max_latency | avg_latency | rows_sent | rows_sent_avg | rows_examined | rows_examined_avg | FIRST_SEEN          | LAST_SEEN           | digest                           |
-- +-------------------------------------------------------------------+------+-----------+------------+-----------+------------+---------------+-------------+-------------+-----------+---------------+---------------+-------------------+---------------------+---------------------+----------------------------------+
-- | SELECT `e` . `round_robin_bin` ...  `timestamp` = `maxes` . `ts`  | mem  | *         |         14 |         0 |          0 | 43.96 s       | 6.69 s      | 3.14 s      |        11 |             1 |        253170 |             18084 | 2013-12-04 20:05:01 | 2013-12-04 20:06:34 | 29ba002bf039bb6439357a10134407de |
-- | SELECT `e` . `round_robin_bin` ...  `timestamp` = `maxes` . `ts`  | mem  | *         |          8 |         0 |          0 | 17.89 s       | 4.12 s      | 2.24 s      |         7 |             1 |        169534 |             21192 | 2013-12-04 20:04:54 | 2013-12-04 20:05:05 | 0b1c1f91e7e9e0ff91aa49d15f540793 |
-- | SELECT `e` . `round_robin_bin` ...  `timestamp` = `maxes` . `ts`  | mem  | *         |          1 |         0 |          0 | 2.22 s        | 2.22 s      | 2.22 s      |         1 |             1 |         40322 |             40322 | 2013-12-04 20:05:39 | 2013-12-04 20:05:39 | 07b27145c8f8a3779737df5032374833 |
-- | SELECT `e` . `round_robin_bin` ...  `timestamp` = `maxes` . `ts`  | mem  | *         |          1 |         0 |          0 | 1.97 s        | 1.97 s      | 1.97 s      |         1 |             1 |         40322 |             40322 | 2013-12-04 20:05:39 | 2013-12-04 20:05:39 | a07488137ea5c1bccf3e291c50bfd21f |
-- | SELECT `e` . `round_robin_bin` ...  `timestamp` = `maxes` . `ts`  | mem  | *         |          2 |         0 |          0 | 3.91 s        | 3.91 s      | 1.96 s      |         1 |             1 |         13126 |              6563 | 2013-12-04 20:05:04 | 2013-12-04 20:06:34 | b8bddc6566366dafc7e474f67096a93b |
-- +-------------------------------------------------------------------+------+-----------+------------+-----------+------------+---------------+-------------+-------------+-----------+---------------+---------------+-------------------+---------------------+---------------------+----------------------------------+
--

CREATE OR REPLACE
  ALGORITHM = MERGE
  DEFINER = 'mysql.sys'@'localhost'
  SQL SECURITY INVOKER 
VIEW statements_with_runtimes_in_95th_percentile (
  query,
  db,
  full_scan,
  exec_count,
  err_count,
  warn_count,
  total_latency,
  max_latency,
  avg_latency,
  rows_sent,
  rows_sent_avg,
  rows_examined,
  rows_examined_avg,
  first_seen,
  last_seen,
  digest
) AS
SELECT sys.format_statement(DIGEST_TEXT) AS query,
       SCHEMA_NAME as db,
       IF(SUM_NO_GOOD_INDEX_USED > 0 OR SUM_NO_INDEX_USED > 0, '*', '') AS full_scan,
       COUNT_STAR AS exec_count,
       SUM_ERRORS AS err_count,
       SUM_WARNINGS AS warn_count,
       format_pico_time(SUM_TIMER_WAIT) AS total_latency,
       format_pico_time(MAX_TIMER_WAIT) AS max_latency,
       format_pico_time(AVG_TIMER_WAIT) AS avg_latency,
       SUM_ROWS_SENT AS rows_sent,
       ROUND(IFNULL(SUM_ROWS_SENT / NULLIF(COUNT_STAR, 0), 0)) AS rows_sent_avg,
       SUM_ROWS_EXAMINED AS rows_examined,
       ROUND(IFNULL(SUM_ROWS_EXAMINED / NULLIF(COUNT_STAR, 0), 0)) AS rows_examined_avg,
       FIRST_SEEN AS first_seen,
       LAST_SEEN AS last_seen,
       DIGEST AS digest
  FROM performance_schema.events_statements_summary_by_digest stmts
  JOIN sys.x$ps_digest_95th_percentile_by_avg_us AS top_percentile
    ON ROUND(stmts.avg_timer_wait/1000000) >= top_percentile.avg_us
 ORDER BY AVG_TIMER_WAIT DESC;
-- Copyright (c) 2014, 2024, Oracle and/or its affiliates.
--
-- This program is free software; you can redistribute it and/or modify
-- it under the terms of the GNU General Public License as published by
-- the Free Software Foundation; version 2 of the License.
--
-- This program is distributed in the hope that it will be useful,
-- but WITHOUT ANY WARRANTY; without even the implied warranty of
-- MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
-- GNU General Public License for more details.
--
-- You should have received a copy of the GNU General Public License
-- along with this program; if not, write to the Free Software
-- Foundation, Inc., 51 Franklin St, Fifth Floor, Boston, MA 02110-1301 USA

--
-- View: x$statements_with_runtimes_in_95th_percentile
--
-- List all statements whose average runtime, in microseconds, is in the top 95th percentile.
-- 
-- mysql> SELECT * FROM x$statements_with_runtimes_in_95th_percentile LIMIT 1\G
-- *************************** 1. row ***************************
--             query: SELECT `e` . `round_robin_bin` AS `round1_1706_0_` , `e` . `id` AS `id1706_0_` , `e` . `timestamp` AS `timestamp1706_0_` , ... truncated
--                db: mem
--         full_scan: *
--        exec_count: 14
--         err_count: 0
--        warn_count: 0
--     total_latency: 43961670267000
--       max_latency: 6686877140000
--       avg_latency: 3140119304000
--         rows_sent: 11
--     rows_sent_avg: 1
--     rows_examined: 253170
-- rows_examined_avg: 18084
--        first_seen: 2013-12-04 20:05:01
--         last_seen: 2013-12-04 20:06:34
--            digest: 29ba002bf039bb6439357a10134407de
--

CREATE OR REPLACE
  ALGORITHM = MERGE
  DEFINER = 'mysql.sys'@'localhost'
  SQL SECURITY INVOKER 
VIEW x$statements_with_runtimes_in_95th_percentile (
  query,
  db,
  full_scan,
  exec_count,
  err_count,
  warn_count,
  total_latency,
  max_latency,
  avg_latency,
  rows_sent,
  rows_sent_avg,
  rows_examined,
  rows_examined_avg,
  first_seen,
  last_seen,
  digest
) AS
SELECT DIGEST_TEXT AS query,
       SCHEMA_NAME AS db,
       IF(SUM_NO_GOOD_INDEX_USED > 0 OR SUM_NO_INDEX_USED > 0, '*', '') AS full_scan,
       COUNT_STAR AS exec_count,
       SUM_ERRORS AS err_count,
       SUM_WARNINGS AS warn_count,
       SUM_TIMER_WAIT AS total_latency,
       MAX_TIMER_WAIT AS max_latency,
       AVG_TIMER_WAIT AS avg_latency,
       SUM_ROWS_SENT AS rows_sent,
       ROUND(IFNULL(SUM_ROWS_SENT / NULLIF(COUNT_STAR, 0), 0)) AS rows_sent_avg,
       SUM_ROWS_EXAMINED AS rows_examined,
       ROUND(IFNULL(SUM_ROWS_EXAMINED / NULLIF(COUNT_STAR, 0), 0)) AS rows_examined_avg,
       FIRST_SEEN as first_seen,
       LAST_SEEN as last_seen,
       DIGEST AS digest
  FROM performance_schema.events_statements_summary_by_digest stmts
  JOIN sys.x$ps_digest_95th_percentile_by_avg_us AS top_percentile
    ON ROUND(stmts.avg_timer_wait/1000000) >= top_percentile.avg_us
 ORDER BY AVG_TIMER_WAIT DESC;
-- Copyright (c) 2014, 2024, Oracle and/or its affiliates.
--
-- This program is free software; you can redistribute it and/or modify
-- it under the terms of the GNU General Public License as published by
-- the Free Software Foundation; version 2 of the License.
--
-- This program is distributed in the hope that it will be useful,
-- but WITHOUT ANY WARRANTY; without even the implied warranty of
-- MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
-- GNU General Public License for more details.
--
-- You should have received a copy of the GNU General Public License
-- along with this program; if not, write to the Free Software
-- Foundation, Inc., 51 Franklin St, Fifth Floor, Boston, MA 02110-1301 USA

--
-- View: statements_with_sorting
--
-- Lists all normalized statements that have done sorts,
-- ordered by total_latency descending.
--
-- mysql> select * from statements_with_sorting limit 1\G
-- *************************** 1. row ***************************
--             query: SELECT * FROM `schema_object_o ... MA` , `information_schema` ...
--                db: sys
--        exec_count: 2
--     total_latency: 16.75 s
-- sort_merge_passes: 0
--   avg_sort_merges: 0
-- sorts_using_scans: 12
--  sort_using_range: 0
--       rows_sorted: 168
--   avg_rows_sorted: 84
--        first_seen: 2014-03-07 13:13:41
--         last_seen: 2014-03-07 13:13:48
--            digest: 54f9bd520f0bbf15db0c2ed93386bec9
--

CREATE OR REPLACE
  ALGORITHM = MERGE
  DEFINER = 'mysql.sys'@'localhost'
  SQL SECURITY INVOKER 
VIEW statements_with_sorting (
  query,
  db,
  exec_count,
  total_latency,
  sort_merge_passes,
  avg_sort_merges,
  sorts_using_scans,
  sort_using_range,
  rows_sorted,
  avg_rows_sorted,
  first_seen,
  last_seen,
  digest
) AS
SELECT sys.format_statement(DIGEST_TEXT) AS query,
       SCHEMA_NAME db,
       COUNT_STAR AS exec_count,
       format_pico_time(SUM_TIMER_WAIT) AS total_latency,
       SUM_SORT_MERGE_PASSES AS sort_merge_passes,
       ROUND(IFNULL(SUM_SORT_MERGE_PASSES / NULLIF(COUNT_STAR, 0), 0)) AS avg_sort_merges,
       SUM_SORT_SCAN AS sorts_using_scans,
       SUM_SORT_RANGE AS sort_using_range,
       SUM_SORT_ROWS AS rows_sorted,
       ROUND(IFNULL(SUM_SORT_ROWS / NULLIF(COUNT_STAR, 0), 0)) AS avg_rows_sorted,
       FIRST_SEEN as first_seen,
       LAST_SEEN as last_seen,
       DIGEST AS digest
  FROM performance_schema.events_statements_summary_by_digest
 WHERE SUM_SORT_ROWS > 0
 ORDER BY SUM_TIMER_WAIT DESC;
-- Copyright (c) 2014, 2024, Oracle and/or its affiliates.
--
-- This program is free software; you can redistribute it and/or modify
-- it under the terms of the GNU General Public License as published by
-- the Free Software Foundation; version 2 of the License.
--
-- This program is distributed in the hope that it will be useful,
-- but WITHOUT ANY WARRANTY; without even the implied warranty of
-- MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
-- GNU General Public License for more details.
--
-- You should have received a copy of the GNU General Public License
-- along with this program; if not, write to the Free Software
-- Foundation, Inc., 51 Franklin St, Fifth Floor, Boston, MA 02110-1301 USA

--
-- View: x$statements_with_sorting
--
-- Lists all normalized statements that have done sorts,
-- ordered by total_latency descending.
--
-- mysql> select * from x$statements_with_sorting\G
-- *************************** 1. row ***************************
--             query: SELECT * FROM `schema_object_overview` SELECT `information_schema` . `routines` . `ROUTINE_SCHEMA` AS ... truncated
--                db: sys
--        exec_count: 2
--     total_latency: 16751388791000
-- sort_merge_passes: 0
--   avg_sort_merges: 0
-- sorts_using_scans: 12
--  sort_using_range: 0
--       rows_sorted: 168
--   avg_rows_sorted: 84
--        first_seen: 2014-03-07 13:13:41
--         last_seen: 2014-03-07 13:13:48
--            digest: 54f9bd520f0bbf15db0c2ed93386bec9
--

CREATE OR REPLACE
  ALGORITHM = MERGE
  DEFINER = 'mysql.sys'@'localhost'
  SQL SECURITY INVOKER 
VIEW x$statements_with_sorting (
  query,
  db,
  exec_count,
  total_latency,
  sort_merge_passes,
  avg_sort_merges,
  sorts_using_scans,
  sort_using_range,
  rows_sorted,
  avg_rows_sorted,
  first_seen,
  last_seen,
  digest
) AS
SELECT DIGEST_TEXT AS query,
       SCHEMA_NAME db,
       COUNT_STAR AS exec_count,
       SUM_TIMER_WAIT AS total_latency,
       SUM_SORT_MERGE_PASSES AS sort_merge_passes,
       ROUND(IFNULL(SUM_SORT_MERGE_PASSES / NULLIF(COUNT_STAR, 0), 0)) AS avg_sort_merges,
       SUM_SORT_SCAN AS sorts_using_scans,
       SUM_SORT_RANGE AS sort_using_range,
       SUM_SORT_ROWS AS rows_sorted,
       ROUND(IFNULL(SUM_SORT_ROWS / NULLIF(COUNT_STAR, 0), 0)) AS avg_rows_sorted,
       FIRST_SEEN as first_seen,
       LAST_SEEN as last_seen,
       DIGEST AS digest
  FROM performance_schema.events_statements_summary_by_digest
 WHERE SUM_SORT_ROWS > 0
 ORDER BY SUM_TIMER_WAIT DESC;
-- Copyright (c) 2014, 2024, Oracle and/or its affiliates.
--
-- This program is free software; you can redistribute it and/or modify
-- it under the terms of the GNU General Public License as published by
-- the Free Software Foundation; version 2 of the License.
--
-- This program is distributed in the hope that it will be useful,
-- but WITHOUT ANY WARRANTY; without even the implied warranty of
-- MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
-- GNU General Public License for more details.
--
-- You should have received a copy of the GNU General Public License
-- along with this program; if not, write to the Free Software
-- Foundation, Inc., 51 Franklin St, Fifth Floor, Boston, MA 02110-1301 USA

--
-- View: statements_with_temp_tables
--
-- Lists all normalized statements that use temporary tables
-- ordered by number of on disk temporary tables descending first, 
-- then by the number of memory tables.
--
-- mysql> select * from statements_with_temp_tables limit 1\G
-- *************************** 1. row ***************************
--                    query: SELECT * FROM `schema_object_o ... MA` , `information_schema` ...
--                       db: sys
--               exec_count: 2
--            total_latency: 16.75 s
--        memory_tmp_tables: 378
--          disk_tmp_tables: 66
-- avg_tmp_tables_per_query: 189
--   tmp_tables_to_disk_pct: 17
--               first_seen: 2014-03-07 13:13:41
--                last_seen: 2014-03-07 13:13:48
--                   digest: 54f9bd520f0bbf15db0c2ed93386bec9
--

CREATE OR REPLACE
  ALGORITHM = MERGE
  DEFINER = 'mysql.sys'@'localhost'
  SQL SECURITY INVOKER 
VIEW statements_with_temp_tables (
  query,
  db,
  exec_count,
  total_latency,
  memory_tmp_tables,
  disk_tmp_tables,
  avg_tmp_tables_per_query,
  tmp_tables_to_disk_pct,
  first_seen,
  last_seen,
  digest
) AS
SELECT sys.format_statement(DIGEST_TEXT) AS query,
       SCHEMA_NAME as db,
       COUNT_STAR AS exec_count,
       format_pico_time(SUM_TIMER_WAIT) as total_latency,
       SUM_CREATED_TMP_TABLES AS memory_tmp_tables,
       SUM_CREATED_TMP_DISK_TABLES AS disk_tmp_tables,
       ROUND(IFNULL(SUM_CREATED_TMP_TABLES / NULLIF(COUNT_STAR, 0), 0)) AS avg_tmp_tables_per_query,
       ROUND(IFNULL(SUM_CREATED_TMP_DISK_TABLES / NULLIF(SUM_CREATED_TMP_TABLES, 0), 0) * 100) AS tmp_tables_to_disk_pct,
       FIRST_SEEN as first_seen,
       LAST_SEEN as last_seen,
       DIGEST AS digest
  FROM performance_schema.events_statements_summary_by_digest
 WHERE SUM_CREATED_TMP_TABLES > 0
ORDER BY SUM_CREATED_TMP_DISK_TABLES DESC, SUM_CREATED_TMP_TABLES DESC;
-- Copyright (c) 2014, 2024, Oracle and/or its affiliates.
--
-- This program is free software; you can redistribute it and/or modify
-- it under the terms of the GNU General Public License as published by
-- the Free Software Foundation; version 2 of the License.
--
-- This program is distributed in the hope that it will be useful,
-- but WITHOUT ANY WARRANTY; without even the implied warranty of
-- MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
-- GNU General Public License for more details.
--
-- You should have received a copy of the GNU General Public License
-- along with this program; if not, write to the Free Software
-- Foundation, Inc., 51 Franklin St, Fifth Floor, Boston, MA 02110-1301 USA

--
-- View: x$statements_with_temp_tables
--
-- Lists all normalized statements that use temporary tables
-- ordered by number of on disk temporary tables descending first, 
-- then by the number of memory tables.
--
-- mysql> select * from x$statements_with_temp_tables limit 1\G
-- *************************** 1. row ***************************
--                    query: SELECT * FROM `schema_object_overview` SELECT `information_schema` . `routines` . `ROUTINE_SCHEMA` AS `db` , ... truncated
--                       db: sys
--               exec_count: 2
--            total_latency: 16751388791000
--        memory_tmp_tables: 378
--          disk_tmp_tables: 66
-- avg_tmp_tables_per_query: 189
--   tmp_tables_to_disk_pct: 17
--               first_seen: 2014-03-07 13:13:41
--                last_seen: 2014-03-07 13:13:48
--                   digest: 54f9bd520f0bbf15db0c2ed93386bec9
--

CREATE OR REPLACE
  ALGORITHM = MERGE
  DEFINER = 'mysql.sys'@'localhost'
  SQL SECURITY INVOKER 
VIEW x$statements_with_temp_tables (
  query,
  db,
  exec_count,
  total_latency,
  memory_tmp_tables,
  disk_tmp_tables,
  avg_tmp_tables_per_query,
  tmp_tables_to_disk_pct,
  first_seen,
  last_seen,
  digest
) AS
SELECT DIGEST_TEXT AS query,
       SCHEMA_NAME as db,
       COUNT_STAR AS exec_count,
       SUM_TIMER_WAIT as total_latency,
       SUM_CREATED_TMP_TABLES AS memory_tmp_tables,
       SUM_CREATED_TMP_DISK_TABLES AS disk_tmp_tables,
       ROUND(IFNULL(SUM_CREATED_TMP_TABLES / NULLIF(COUNT_STAR, 0), 0)) AS avg_tmp_tables_per_query,
       ROUND(IFNULL(SUM_CREATED_TMP_DISK_TABLES / NULLIF(SUM_CREATED_TMP_TABLES, 0), 0) * 100) AS tmp_tables_to_disk_pct,
       FIRST_SEEN as first_seen,
       LAST_SEEN as last_seen,
       DIGEST AS digest
  FROM performance_schema.events_statements_summary_by_digest
 WHERE SUM_CREATED_TMP_TABLES > 0
ORDER BY SUM_CREATED_TMP_DISK_TABLES DESC, SUM_CREATED_TMP_TABLES DESC;
-- Copyright (c) 2014, 2024, Oracle and/or its affiliates.
--
-- This program is free software; you can redistribute it and/or modify
-- it under the terms of the GNU General Public License as published by
-- the Free Software Foundation; version 2 of the License.
--
-- This program is distributed in the hope that it will be useful,
-- but WITHOUT ANY WARRANTY; without even the implied warranty of
-- MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
-- GNU General Public License for more details.
--
-- You should have received a copy of the GNU General Public License
-- along with this program; if not, write to the Free Software
-- Foundation, Inc., 51 Franklin St, Fifth Floor, Boston, MA 02110-1301 USA

--
-- View: user_summary_by_file_io_type
--
-- Summarizes file IO by event type per user.
--
-- When the user found is NULL, it is assumed to be a "background" thread.
--
-- mysql> select * from user_summary_by_file_io_type;
-- +------------+--------------------------------------+-------+-----------+-------------+
-- | user       | event_name                           | total | latency   | max_latency |
-- +------------+--------------------------------------+-------+-----------+-------------+
-- | background | wait/io/file/sql/FRM                 |   871 | 168.15 ms | 18.48 ms    |
-- | background | wait/io/file/innodb/innodb_data_file |   173 | 129.56 ms | 34.09 ms    |
-- | background | wait/io/file/innodb/innodb_log_file  |    20 | 77.53 ms  | 60.66 ms    |
-- | background | wait/io/file/myisam/dfile            |    40 | 6.54 ms   | 4.58 ms     |
-- | background | wait/io/file/mysys/charset           |     3 | 4.79 ms   | 4.71 ms     |
-- | background | wait/io/file/myisam/kfile            |    67 | 4.38 ms   | 300.04 us   |
-- | background | wait/io/file/sql/ERRMSG              |     5 | 2.72 ms   | 1.69 ms     |
-- | background | wait/io/file/sql/pid                 |     3 | 266.30 us | 185.47 us   |
-- | background | wait/io/file/sql/casetest            |     5 | 246.81 us | 150.19 us   |
-- | background | wait/io/file/sql/global_ddl_log      |     2 | 21.24 us  | 18.59 us    |
-- | root       | wait/io/file/sql/file_parser         |  1422 | 4.80 s    | 135.14 ms   |
-- | root       | wait/io/file/sql/FRM                 |   865 | 85.82 ms  | 9.81 ms     |
-- | root       | wait/io/file/myisam/kfile            |  1073 | 37.14 ms  | 15.79 ms    |
-- | root       | wait/io/file/myisam/dfile            |  2991 | 25.53 ms  | 5.25 ms     |
-- | root       | wait/io/file/sql/dbopt               |    20 | 1.07 ms   | 153.07 us   |
-- | root       | wait/io/file/sql/misc                |     4 | 59.71 us  | 33.75 us    |
-- | root       | wait/io/file/archive/data            |     1 | 13.91 us  | 13.91 us    |
-- +------------+--------------------------------------+-------+-----------+-------------+
--

CREATE OR REPLACE
  ALGORITHM = MERGE
  DEFINER = 'mysql.sys'@'localhost'
  SQL SECURITY INVOKER 
VIEW user_summary_by_file_io_type (
  user,
  event_name,
  total,
  latency,
  max_latency
) AS
SELECT IF(user IS NULL, 'background', user) AS user,
       event_name,
       count_star AS total,
       format_pico_time(sum_timer_wait) AS latency,
       format_pico_time(max_timer_wait) AS max_latency
  FROM performance_schema.events_waits_summary_by_user_by_event_name
 WHERE event_name LIKE 'wait/io/file%'
   AND count_star > 0
 ORDER BY user, sum_timer_wait DESC;
-- Copyright (c) 2014, 2024, Oracle and/or its affiliates.
--
-- This program is free software; you can redistribute it and/or modify
-- it under the terms of the GNU General Public License as published by
-- the Free Software Foundation; version 2 of the License.
--
-- This program is distributed in the hope that it will be useful,
-- but WITHOUT ANY WARRANTY; without even the implied warranty of
-- MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
-- GNU General Public License for more details.
--
-- You should have received a copy of the GNU General Public License
-- along with this program; if not, write to the Free Software
-- Foundation, Inc., 51 Franklin St, Fifth Floor, Boston, MA 02110-1301 USA

--
-- View: x$user_summary_by_file_io_type
--
-- Summarizes file IO by event type per user.
--
-- When the user found is NULL, it is assumed to be a "background" thread.
--
-- mysql> select * from x$user_summary_by_file_io_type;
-- +------------+--------------------------------------+-------+---------------+--------------+
-- | user       | event_name                           | total | latency       | max_latency  |
-- +------------+--------------------------------------+-------+---------------+--------------+
-- | background | wait/io/file/sql/FRM                 |   871 |  168148450470 |  18482624810 |
-- | background | wait/io/file/innodb/innodb_data_file |   173 |  129564287450 |  34087423890 |
-- | background | wait/io/file/innodb/innodb_log_file  |    20 |   77525706960 |  60657475320 |
-- | background | wait/io/file/myisam/dfile            |    40 |    6544493800 |   4580546230 |
-- | background | wait/io/file/mysys/charset           |     3 |    4793558770 |   4713476430 |
-- | background | wait/io/file/myisam/kfile            |    67 |    4384332810 |    300035450 |
-- | background | wait/io/file/sql/ERRMSG              |     5 |    2717434850 |   1687316280 |
-- | background | wait/io/file/sql/pid                 |     3 |     266301490 |    185468920 |
-- | background | wait/io/file/sql/casetest            |     5 |     246814360 |    150193030 |
-- | background | wait/io/file/sql/global_ddl_log      |     2 |      21236410 |     18593640 |
-- | root       | wait/io/file/sql/file_parser         |  1422 | 4801104756760 | 135138518970 |
-- | root       | wait/io/file/sql/FRM                 |   865 |   85818594810 |   9812303410 |
-- | root       | wait/io/file/myisam/kfile            |  1073 |   37143664870 |  15793838190 |
-- | root       | wait/io/file/myisam/dfile            |  2991 |   25528215700 |   5252232050 |
-- | root       | wait/io/file/sql/dbopt               |    20 |    1067339780 |    153073310 |
-- | root       | wait/io/file/sql/misc                |     4 |      59713030 |     33752810 |
-- | root       | wait/io/file/archive/data            |     1 |      13907530 |     13907530 |
-- +------------+--------------------------------------+-------+---------------+--------------+
--

CREATE OR REPLACE
  ALGORITHM = MERGE
  DEFINER = 'mysql.sys'@'localhost'
  SQL SECURITY INVOKER 
VIEW x$user_summary_by_file_io_type (
  user,
  event_name,
  total,
  latency,
  max_latency
) AS
SELECT IF(user IS NULL, 'background', user) AS user,
       event_name,
       count_star AS total,
       sum_timer_wait AS latency,
       max_timer_wait AS max_latency
  FROM performance_schema.events_waits_summary_by_user_by_event_name
 WHERE event_name LIKE 'wait/io/file%'
   AND count_star > 0
 ORDER BY user, sum_timer_wait DESC;
-- Copyright (c) 2014, 2024, Oracle and/or its affiliates.
--
-- This program is free software; you can redistribute it and/or modify
-- it under the terms of the GNU General Public License as published by
-- the Free Software Foundation; version 2 of the License.
--
-- This program is distributed in the hope that it will be useful,
-- but WITHOUT ANY WARRANTY; without even the implied warranty of
-- MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
-- GNU General Public License for more details.
--
-- You should have received a copy of the GNU General Public License
-- along with this program; if not, write to the Free Software
-- Foundation, Inc., 51 Franklin St, Fifth Floor, Boston, MA 02110-1301 USA

--
-- View: user_summary_by_file_io
--
-- Summarizes file IO totals per user.
--
-- When the user found is NULL, it is assumed to be a "background" thread.
--
-- mysql> select * from user_summary_by_file_io;
-- +------------+-------+------------+
-- | user       | ios   | io_latency |
-- +------------+-------+------------+
-- | root       | 26457 | 21.58 s    |
-- | background |  1189 | 394.21 ms  |
-- +------------+-------+------------+
--

CREATE OR REPLACE
  ALGORITHM = TEMPTABLE
  DEFINER = 'mysql.sys'@'localhost'
  SQL SECURITY INVOKER 
VIEW user_summary_by_file_io (
  user,
  ios,
  io_latency
) AS
SELECT IF(user IS NULL, 'background', user) AS user,
       SUM(count_star) AS ios,
       format_pico_time(SUM(sum_timer_wait)) AS io_latency 
  FROM performance_schema.events_waits_summary_by_user_by_event_name
 WHERE event_name LIKE 'wait/io/file/%'
 GROUP BY IF(user IS NULL, 'background', user)
 ORDER BY SUM(sum_timer_wait) DESC;
-- Copyright (c) 2014, 2024, Oracle and/or its affiliates.
--
-- This program is free software; you can redistribute it and/or modify
-- it under the terms of the GNU General Public License as published by
-- the Free Software Foundation; version 2 of the License.
--
-- This program is distributed in the hope that it will be useful,
-- but WITHOUT ANY WARRANTY; without even the implied warranty of
-- MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
-- GNU General Public License for more details.
--
-- You should have received a copy of the GNU General Public License
-- along with this program; if not, write to the Free Software
-- Foundation, Inc., 51 Franklin St, Fifth Floor, Boston, MA 02110-1301 USA

--
-- View: x$user_summary_by_file_io
--
-- Summarizes file IO totals per user.
--
-- When the user found is NULL, it is assumed to be a "background" thread.
--
-- mysql> select * from x$user_summary_by_file_io;
-- +------------+-------+----------------+
-- | user       | ios   | io_latency     |
-- +------------+-------+----------------+
-- | root       | 26457 | 21579585586390 |
-- | background |  1189 |   394212617370 |
-- +------------+-------+----------------+
--

CREATE OR REPLACE
  ALGORITHM = TEMPTABLE
  DEFINER = 'mysql.sys'@'localhost'
  SQL SECURITY INVOKER 
VIEW x$user_summary_by_file_io (
  user,
  ios,
  io_latency
) AS
SELECT IF(user IS NULL, 'background', user) AS user,
       SUM(count_star) AS ios,
       SUM(sum_timer_wait) AS io_latency 
  FROM performance_schema.events_waits_summary_by_user_by_event_name
 WHERE event_name LIKE 'wait/io/file/%'
 GROUP BY IF(user IS NULL, 'background', user)
 ORDER BY SUM(sum_timer_wait) DESC;
-- Copyright (c) 2014, 2024, Oracle and/or its affiliates.
--
-- This program is free software; you can redistribute it and/or modify
-- it under the terms of the GNU General Public License as published by
-- the Free Software Foundation; version 2 of the License.
--
-- This program is distributed in the hope that it will be useful,
-- but WITHOUT ANY WARRANTY; without even the implied warranty of
-- MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
-- GNU General Public License for more details.
--
-- You should have received a copy of the GNU General Public License
-- along with this program; if not, write to the Free Software
-- Foundation, Inc., 51 Franklin St, Fifth Floor, Boston, MA 02110-1301 USA

--
-- View: user_summary_by_statement_type
--
-- Summarizes the types of statements executed by each user.
-- 
-- When the user found is NULL, it is assumed to be a "background" thread.
--
-- mysql> select * from user_summary_by_statement_type;
-- +------+----------------------+--------+---------------+-------------+--------------+-----------+---------------+---------------+------------+
-- | user | statement            | total  | total_latency | max_latency | lock_latency | rows_sent | rows_examined | rows_affected | full_scans |
-- +------+----------------------+--------+---------------+-------------+--------------+-----------+---------------+---------------+------------+
-- | root | create_view          |   2063 | 00:05:04.20   | 463.58 ms   | 1.42 s       |         0 |             0 |             0 |          0 |
-- | root | select               |    174 | 40.87 s       | 28.83 s     | 858.13 ms    |      5212 |        157022 |             0 |         82 |
-- | root | stmt                 |   6645 | 15.31 s       | 491.78 ms   | 0 ps         |         0 |             0 |          7951 |          0 |
-- | root | call_procedure       |     17 | 4.78 s        | 1.02 s      | 37.94 ms     |         0 |             0 |            19 |          0 |
-- | root | create_table         |     19 | 3.04 s        | 431.71 ms   | 0 ps         |         0 |             0 |             0 |          0 |
-- ...
-- +------+----------------------+--------+---------------+-------------+--------------+-----------+---------------+---------------+------------+
--

CREATE OR REPLACE
  ALGORITHM = MERGE
  DEFINER = 'mysql.sys'@'localhost'
  SQL SECURITY INVOKER 
VIEW user_summary_by_statement_type (
  user,
  statement,
  total,
  total_latency,
  max_latency,
  lock_latency,
  cpu_latency,
  rows_sent,
  rows_examined,
  rows_affected,
  full_scans
) AS
SELECT IF(user IS NULL, 'background', user) AS user,
       SUBSTRING_INDEX(event_name, '/', -1) AS statement,
       count_star AS total,
       format_pico_time(sum_timer_wait) AS total_latency,
       format_pico_time(max_timer_wait) AS max_latency,
       format_pico_time(sum_lock_time) AS lock_latency,
       format_pico_time(sum_cpu_time) AS cpu_latency,
       sum_rows_sent AS rows_sent,
       sum_rows_examined AS rows_examined,
       sum_rows_affected AS rows_affected,
       sum_no_index_used + sum_no_good_index_used AS full_scans
  FROM performance_schema.events_statements_summary_by_user_by_event_name
 WHERE sum_timer_wait != 0
 ORDER BY user, sum_timer_wait DESC;
-- Copyright (c) 2014, 2024, Oracle and/or its affiliates.
--
-- This program is free software; you can redistribute it and/or modify
-- it under the terms of the GNU General Public License as published by
-- the Free Software Foundation; version 2 of the License.
--
-- This program is distributed in the hope that it will be useful,
-- but WITHOUT ANY WARRANTY; without even the implied warranty of
-- MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
-- GNU General Public License for more details.
--
-- You should have received a copy of the GNU General Public License
-- along with this program; if not, write to the Free Software
-- Foundation, Inc., 51 Franklin St, Fifth Floor, Boston, MA 02110-1301 USA

--
-- View: x$user_summary_by_statement_type
--
-- Summarizes the types of statements executed by each user.
-- 
-- When the user found is NULL, it is assumed to be a "background" thread.
--
-- mysql> select * from x$user_summary_by_statement_type;
-- +------+----------------------+--------+-----------------+----------------+----------------+-----------+---------------+---------------+------------+
-- | user | statement            | total  | total_latency   | max_latency    | lock_latency   | rows_sent | rows_examined | rows_affected | full_scans |
-- +------+----------------------+--------+-----------------+----------------+----------------+-----------+---------------+---------------+------------+
-- | root | create_view          |   2110 | 312717366332000 |   463578029000 |  1432355000000 |         0 |             0 |             0 |          0 |
-- | root | select               |    177 |  41115690428000 | 28827579292000 |   858709000000 |      5254 |        157437 |             0 |         83 |
-- | root | stmt                 |   6645 |  15305389969000 |   491780297000 |              0 |         0 |             0 |          7951 |          0 |
-- | root | call_procedure       |     17 |   4783806053000 |  1016083397000 |    37936000000 |         0 |             0 |            19 |          0 |
-- | root | create_table         |     19 |   3035120946000 |   431706815000 |              0 |         0 |             0 |             0 |          0 |
-- ...
-- +------+----------------------+--------+-----------------+----------------+----------------+-----------+---------------+---------------+------------+
--

CREATE OR REPLACE
  ALGORITHM = MERGE
  DEFINER = 'mysql.sys'@'localhost'
  SQL SECURITY INVOKER 
VIEW x$user_summary_by_statement_type (
  user,
  statement,
  total,
  total_latency,
  max_latency,
  lock_latency,
  cpu_latency,
  rows_sent,
  rows_examined,
  rows_affected,
  full_scans
) AS
SELECT IF(user IS NULL, 'background', user) AS user,
       SUBSTRING_INDEX(event_name, '/', -1) AS statement,
       count_star AS total,
       sum_timer_wait AS total_latency,
       max_timer_wait AS max_latency,
       sum_lock_time AS lock_latency,
       sum_cpu_time AS cpu_latency,
       sum_rows_sent AS rows_sent,
       sum_rows_examined AS rows_examined,
       sum_rows_affected AS rows_affected,
       sum_no_index_used + sum_no_good_index_used AS full_scans
  FROM performance_schema.events_statements_summary_by_user_by_event_name
 WHERE sum_timer_wait != 0
 ORDER BY user, sum_timer_wait DESC;
-- Copyright (c) 2014, 2024, Oracle and/or its affiliates.
--
-- This program is free software; you can redistribute it and/or modify
-- it under the terms of the GNU General Public License as published by
-- the Free Software Foundation; version 2 of the License.
--
-- This program is distributed in the hope that it will be useful,
-- but WITHOUT ANY WARRANTY; without even the implied warranty of
-- MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
-- GNU General Public License for more details.
--
-- You should have received a copy of the GNU General Public License
-- along with this program; if not, write to the Free Software
-- Foundation, Inc., 51 Franklin St, Fifth Floor, Boston, MA 02110-1301 USA

--
-- View: user_summary_by_statement_latency
--
-- Summarizes overall statement statistics by user.
-- 
-- When the user found is NULL, it is assumed to be a "background" thread.
--
-- mysql> select * from user_summary_by_statement_latency;
-- +------+-------+---------------+-------------+--------------+-----------+---------------+---------------+------------+
-- | user | total | total_latency | max_latency | lock_latency | rows_sent | rows_examined | rows_affected | full_scans |
-- +------+-------+---------------+-------------+--------------+-----------+---------------+---------------+------------+
-- | root |  3381 | 00:02:09.13   | 1.48 s      | 1.07 s       |      1151 |         93947 |           150 |         91 |
-- +------+-------+---------------+-------------+--------------+-----------+---------------+---------------+------------+
--

CREATE OR REPLACE
  ALGORITHM = TEMPTABLE
  DEFINER = 'mysql.sys'@'localhost'
  SQL SECURITY INVOKER 
VIEW user_summary_by_statement_latency (
  user,
  total,
  total_latency,
  max_latency,
  lock_latency,
  cpu_latency,
  rows_sent,
  rows_examined,
  rows_affected,
  full_scans
) AS
SELECT IF(user IS NULL, 'background', user) AS user,
       SUM(count_star) AS total,
       format_pico_time(SUM(sum_timer_wait)) AS total_latency,
       format_pico_time(SUM(max_timer_wait)) AS max_latency,
       format_pico_time(SUM(sum_lock_time)) AS lock_latency,
       format_pico_time(SUM(sum_cpu_time)) AS cpu_latency,
       SUM(sum_rows_sent) AS rows_sent,
       SUM(sum_rows_examined) AS rows_examined,
       SUM(sum_rows_affected) AS rows_affected,
       SUM(sum_no_index_used) + SUM(sum_no_good_index_used) AS full_scans
  FROM performance_schema.events_statements_summary_by_user_by_event_name
 GROUP BY IF(user IS NULL, 'background', user)
 ORDER BY SUM(sum_timer_wait) DESC;
-- Copyright (c) 2014, 2024, Oracle and/or its affiliates.
--
-- This program is free software; you can redistribute it and/or modify
-- it under the terms of the GNU General Public License as published by
-- the Free Software Foundation; version 2 of the License.
--
-- This program is distributed in the hope that it will be useful,
-- but WITHOUT ANY WARRANTY; without even the implied warranty of
-- MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
-- GNU General Public License for more details.
--
-- You should have received a copy of the GNU General Public License
-- along with this program; if not, write to the Free Software
-- Foundation, Inc., 51 Franklin St, Fifth Floor, Boston, MA 02110-1301 USA

--
-- View: x$user_summary_by_statement_latency
--
-- Summarizes overall statement statistics by user.
-- 
-- When the user found is NULL, it is assumed to be a "background" thread.
--
-- mysql> select * from x$user_summary_by_statement_latency;
-- +------+-------+-----------------+---------------+---------------+-----------+---------------+---------------+------------+
-- | user | total | total_latency   | max_latency   | lock_latency  | rows_sent | rows_examined | rows_affected | full_scans |
-- +------+-------+-----------------+---------------+---------------+-----------+---------------+---------------+------------+
-- | root |  3382 | 129134039432000 | 1483246743000 | 1069831000000 |      1152 |         94286 |           150 |         92 |
-- +------+-------+-----------------+---------------+---------------+-----------+---------------+---------------+------------+
--

CREATE OR REPLACE
  ALGORITHM = TEMPTABLE
  DEFINER = 'mysql.sys'@'localhost'
  SQL SECURITY INVOKER 
VIEW x$user_summary_by_statement_latency (
  user,
  total,
  total_latency,
  max_latency,
  lock_latency,
  cpu_latency,
  rows_sent,
  rows_examined,
  rows_affected,
  full_scans
) AS
SELECT IF(user IS NULL, 'background', user) AS user,
       SUM(count_star) AS total,
       SUM(sum_timer_wait) AS total_latency,
       SUM(max_timer_wait) AS max_latency,
       SUM(sum_lock_time) AS lock_latency,
       SUM(sum_cpu_time) AS cpu_latency,
       SUM(sum_rows_sent) AS rows_sent,
       SUM(sum_rows_examined) AS rows_examined,
       SUM(sum_rows_affected) AS rows_affected,
       SUM(sum_no_index_used) + SUM(sum_no_good_index_used) AS full_scans
  FROM performance_schema.events_statements_summary_by_user_by_event_name
 GROUP BY IF(user IS NULL, 'background', user)
 ORDER BY SUM(sum_timer_wait) DESC;
-- Copyright (c) 2014, 2024, Oracle and/or its affiliates.
--
-- This program is free software; you can redistribute it and/or modify
-- it under the terms of the GNU General Public License as published by
-- the Free Software Foundation; version 2 of the License.
--
-- This program is distributed in the hope that it will be useful,
-- but WITHOUT ANY WARRANTY; without even the implied warranty of
-- MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
-- GNU General Public License for more details.
--
-- You should have received a copy of the GNU General Public License
-- along with this program; if not, write to the Free Software
-- Foundation, Inc., 51 Franklin St, Fifth Floor, Boston, MA 02110-1301 USA

--
-- View: user_summary_by_stages
--
-- Summarizes stages by user, ordered by user and total latency per stage.
-- 
-- When the user found is NULL, it is assumed to be a "background" thread.  
-- 
-- mysql> select * from user_summary_by_stages;
-- +------+--------------------------------+-------+---------------+-------------+
-- | user | event_name                     | total | total_latency | avg_latency |
-- +------+--------------------------------+-------+---------------+-------------+
-- | root | stage/sql/Opening tables       |   889 | 1.97 ms       | 2.22 us     |
-- | root | stage/sql/Creating sort index  |     4 | 1.79 ms       | 446.30 us   |
-- | root | stage/sql/init                 |    10 | 312.27 us     | 31.23 us    |
-- | root | stage/sql/checking permissions |    10 | 300.62 us     | 30.06 us    |
-- | root | stage/sql/freeing items        |     5 | 85.89 us      | 17.18 us    |
-- | root | stage/sql/statistics           |     5 | 79.15 us      | 15.83 us    |
-- | root | stage/sql/preparing            |     5 | 69.12 us      | 13.82 us    |
-- | root | stage/sql/optimizing           |     5 | 53.11 us      | 10.62 us    |
-- | root | stage/sql/Sending data         |     5 | 44.66 us      | 8.93 us     |
-- | root | stage/sql/closing tables       |     5 | 37.54 us      | 7.51 us     |
-- | root | stage/sql/System lock          |     5 | 34.28 us      | 6.86 us     |
-- | root | stage/sql/query end            |     5 | 24.37 us      | 4.87 us     |
-- | root | stage/sql/end                  |     5 | 8.60 us       | 1.72 us     |
-- | root | stage/sql/Sorting result       |     5 | 8.33 us       | 1.67 us     |
-- | root | stage/sql/executing            |     5 | 5.37 us       | 1.07 us     |
-- | root | stage/sql/cleaning up          |     5 | 4.60 us       | 919.00 ns   |
-- +------+--------------------------------+-------+---------------+-------------+
--

CREATE OR REPLACE
  ALGORITHM = MERGE
  DEFINER = 'mysql.sys'@'localhost'
  SQL SECURITY INVOKER 
VIEW user_summary_by_stages (
  user,
  event_name,
  total,
  total_latency,
  avg_latency
) AS
SELECT IF(user IS NULL, 'background', user) AS user,
       event_name,
       count_star AS total,
       format_pico_time(sum_timer_wait) AS total_latency, 
       format_pico_time(avg_timer_wait) AS avg_latency 
  FROM performance_schema.events_stages_summary_by_user_by_event_name
 WHERE sum_timer_wait != 0 
 ORDER BY user, sum_timer_wait DESC;
-- Copyright (c) 2014, 2024, Oracle and/or its affiliates.
--
-- This program is free software; you can redistribute it and/or modify
-- it under the terms of the GNU General Public License as published by
-- the Free Software Foundation; version 2 of the License.
--
-- This program is distributed in the hope that it will be useful,
-- but WITHOUT ANY WARRANTY; without even the implied warranty of
-- MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
-- GNU General Public License for more details.
--
-- You should have received a copy of the GNU General Public License
-- along with this program; if not, write to the Free Software
-- Foundation, Inc., 51 Franklin St, Fifth Floor, Boston, MA 02110-1301 USA

--
-- View: x$user_summary_by_stages
--
-- Summarizes stages by user, ordered by user and total latency per stage.
-- 
-- When the user found is NULL, it is assumed to be a "background" thread.  
-- 
-- mysql> select * from x$user_summary_by_stages;
-- +------+--------------------------------+-------+---------------+-------------+
-- | user | event_name                     | total | total_latency | avg_latency |
-- +------+--------------------------------+-------+---------------+-------------+
-- | root | stage/sql/Opening tables       |  1114 |   71919037000 |    64559000 |
-- | root | stage/sql/Creating sort index  |     5 |    2245762000 |   449152000 |
-- | root | stage/sql/init                 |    13 |     428798000 |    32984000 |
-- | root | stage/sql/checking permissions |    13 |     363231000 |    27940000 |
-- | root | stage/sql/freeing items        |     7 |     137728000 |    19675000 |
-- | root | stage/sql/statistics           |     6 |      93955000 |    15659000 |
-- | root | stage/sql/preparing            |     6 |      82571000 |    13761000 |
-- | root | stage/sql/optimizing           |     6 |      63338000 |    10556000 |
-- | root | stage/sql/Sending data         |     6 |      53400000 |     8900000 |
-- | root | stage/sql/closing tables       |     7 |      46922000 |     6703000 |
-- | root | stage/sql/System lock          |     6 |      40175000 |     6695000 |
-- | root | stage/sql/query end            |     7 |      31723000 |     4531000 |
-- | root | stage/sql/Sorting result       |     6 |       9855000 |     1642000 |
-- | root | stage/sql/end                  |     6 |       9556000 |     1592000 |
-- | root | stage/sql/cleaning up          |     7 |       7312000 |     1044000 |
-- | root | stage/sql/executing            |     6 |       6487000 |     1081000 |
-- +------+--------------------------------+-------+---------------+-------------+
--

CREATE OR REPLACE
  ALGORITHM = MERGE
  DEFINER = 'mysql.sys'@'localhost'
  SQL SECURITY INVOKER 
VIEW x$user_summary_by_stages (
  user,
  event_name,
  total,
  total_latency,
  avg_latency
) AS
SELECT IF(user IS NULL, 'background', user) AS user,
       event_name,
       count_star AS total,
       sum_timer_wait AS total_latency, 
       avg_timer_wait AS avg_latency 
  FROM performance_schema.events_stages_summary_by_user_by_event_name
 WHERE sum_timer_wait != 0 
 ORDER BY user, sum_timer_wait DESC;
-- Copyright (c) 2014, 2024, Oracle and/or its affiliates.
--
-- This program is free software; you can redistribute it and/or modify
-- it under the terms of the GNU General Public License as published by
-- the Free Software Foundation; version 2 of the License.
--
-- This program is distributed in the hope that it will be useful,
-- but WITHOUT ANY WARRANTY; without even the implied warranty of
-- MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
-- GNU General Public License for more details.
--
-- You should have received a copy of the GNU General Public License
-- along with this program; if not, write to the Free Software
-- Foundation, Inc., 51 Franklin St, Fifth Floor, Boston, MA 02110-1301 USA

--
-- View: user_summary
--
-- Summarizes statement activity and connections by user
-- 
-- When the user found is NULL, it is assumed to be a "background" thread.  
--
-- mysql> select * from user_summary;
-- +------+------------+---------------+-------------+---------------------+-------------------+--------------+----------------+------------------------+
-- | user | statements | total_latency | avg_latency | current_connections | total_connections | unique_hosts | current_memory | total_memory_allocated |
-- +------+------------+---------------+-------------+---------------------+-------------------+--------------+----------------+------------------------+
-- | root |       5663 | 00:01:47.14   | 18.92 ms    |                   1 |                 1 |            1 | 1.41 MiB       | 543.55 MiB             |
-- | mark |        225 | 14.49 s       | 64.40 ms    |                   1 |                 1 |            1 | 707.60 KiB     | 81.02 MiB              |
-- +------+------------+---------------+-------------+---------------------+-------------------+--------------+----------------+------------------------+
--

CREATE OR REPLACE
  ALGORITHM = TEMPTABLE
  DEFINER = 'mysql.sys'@'localhost'
  SQL SECURITY INVOKER 
VIEW user_summary (
  user,
  statements,
  statement_latency,
  statement_avg_latency,
  table_scans,
  file_ios,
  file_io_latency,
  current_connections,
  total_connections,
  unique_hosts,
  current_memory,
  total_memory_allocated
) AS
SELECT IF(accounts.user IS NULL, 'background', accounts.user) AS user,
       SUM(stmt.total) AS statements,
       format_pico_time(SUM(stmt.total_latency)) AS statement_latency,
       format_pico_time(IFNULL(SUM(stmt.total_latency) / NULLIF(SUM(stmt.total), 0), 0)) AS statement_avg_latency,
       SUM(stmt.full_scans) AS table_scans,
       SUM(io.ios) AS file_ios,
       format_pico_time(SUM(io.io_latency)) AS file_io_latency,
       SUM(accounts.current_connections) AS current_connections,
       SUM(accounts.total_connections) AS total_connections,
       COUNT(DISTINCT host) AS unique_hosts,
       format_bytes(SUM(mem.current_allocated)) AS current_memory,
       format_bytes(SUM(mem.total_allocated)) AS total_memory_allocated
  FROM performance_schema.accounts
  LEFT JOIN sys.x$user_summary_by_statement_latency AS stmt ON IF(accounts.user IS NULL, 'background', accounts.user) = stmt.user
  LEFT JOIN sys.x$user_summary_by_file_io AS io ON IF(accounts.user IS NULL, 'background', accounts.user) = io.user
  LEFT JOIN sys.x$memory_by_user_by_current_bytes mem ON IF(accounts.user IS NULL, 'background', accounts.user) = mem.user
 GROUP BY IF(accounts.user IS NULL, 'background', accounts.user)
 ORDER BY SUM(stmt.total_latency) DESC;
-- Copyright (c) 2014, 2024, Oracle and/or its affiliates.
--
-- This program is free software; you can redistribute it and/or modify
-- it under the terms of the GNU General Public License as published by
-- the Free Software Foundation; version 2 of the License.
--
-- This program is distributed in the hope that it will be useful,
-- but WITHOUT ANY WARRANTY; without even the implied warranty of
-- MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
-- GNU General Public License for more details.
--
-- You should have received a copy of the GNU General Public License
-- along with this program; if not, write to the Free Software
-- Foundation, Inc., 51 Franklin St, Fifth Floor, Boston, MA 02110-1301 USA

--
-- View: x$user_summary
--
-- Summarizes statement activity and connections by user
-- 
-- When the user found is NULL, it is assumed to be a "background" thread.  
--
-- mysql> select * from x$user_summary;
-- +------+------------+-----------------+------------------+---------------------+-------------------+--------------+----------------+------------------------+
-- | user | statements | total_latency   | avg_latency      | current_connections | total_connections | unique_hosts | current_memory | total_memory_allocated |
-- +------+------------+-----------------+------------------+---------------------+-------------------+--------------+----------------+------------------------+
-- | root |       5685 | 107175100271000 | 18852260381.8821 |                   1 |                 1 |            1 |        1459022 |              572855680 |
-- | mark |        225 |  14489223428000 | 64396548568.8889 |                   1 |                 1 |            1 |         724578 |               84958286 |
-- +------+------------+-----------------+------------------+---------------------+-------------------+--------------+----------------+------------------------+
--

CREATE OR REPLACE
  ALGORITHM = TEMPTABLE
  DEFINER = 'mysql.sys'@'localhost'
  SQL SECURITY INVOKER 
VIEW x$user_summary (
  user,
  statements,
  statement_latency,
  statement_avg_latency,
  table_scans,
  file_ios,
  file_io_latency,
  current_connections,
  total_connections,
  unique_hosts,
  current_memory,
  total_memory_allocated
) AS
SELECT IF(accounts.user IS NULL, 'background', accounts.user) AS user,
       SUM(stmt.total) AS statements,
       SUM(stmt.total_latency) AS statement_latency,
       IFNULL(SUM(stmt.total_latency) / NULLIF(SUM(stmt.total), 0), 0) AS statement_avg_latency,
       SUM(stmt.full_scans) AS table_scans,
       SUM(io.ios) AS file_ios,
       SUM(io.io_latency) AS file_io_latency,
       SUM(accounts.current_connections) AS current_connections,
       SUM(accounts.total_connections) AS total_connections,
       COUNT(DISTINCT host) AS unique_hosts,
       SUM(mem.current_allocated) AS current_memory,
       SUM(mem.total_allocated) AS total_memory_allocated
  FROM performance_schema.accounts
  LEFT JOIN sys.x$user_summary_by_statement_latency AS stmt ON IF(accounts.user IS NULL, 'background', accounts.user) = stmt.user
  LEFT JOIN sys.x$user_summary_by_file_io AS io ON IF(accounts.user IS NULL, 'background', accounts.user) = io.user
  LEFT JOIN sys.x$memory_by_user_by_current_bytes mem ON IF(accounts.user IS NULL, 'background', accounts.user) = mem.user
 GROUP BY IF(accounts.user IS NULL, 'background', accounts.user)
 ORDER BY SUM(stmt.total_latency) DESC;
-- Copyright (c) 2014, 2024, Oracle and/or its affiliates.
--
-- This program is free software; you can redistribute it and/or modify
-- it under the terms of the GNU General Public License as published by
-- the Free Software Foundation; version 2 of the License.
--
-- This program is distributed in the hope that it will be useful,
-- but WITHOUT ANY WARRANTY; without even the implied warranty of
-- MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
-- GNU General Public License for more details.
--
-- You should have received a copy of the GNU General Public License
-- along with this program; if not, write to the Free Software
-- Foundation, Inc., 51 Franklin St, Fifth Floor, Boston, MA 02110-1301 USA

--
-- View: host_summary_by_file_io_type
--
-- Summarizes file IO by event type per host.
--
-- When the host found is NULL, it is assumed to be a "background" thread.
--
-- mysql> select * from host_summary_by_file_io_type;
-- +------------+--------------------------------------+-------+---------------+-------------+
-- | host       | event_name                           | total | total_latency | max_latency |
-- +------------+--------------------------------------+-------+---------------+-------------+
-- | hal1       | wait/io/file/sql/FRM                 |   871 | 168.15 ms     | 18.48 ms    |
-- | hal1       | wait/io/file/innodb/innodb_data_file |   173 | 129.56 ms     | 34.09 ms    |
-- | hal1       | wait/io/file/innodb/innodb_log_file  |    20 | 77.53 ms      | 60.66 ms    |
-- | hal1       | wait/io/file/myisam/dfile            |    40 | 6.54 ms       | 4.58 ms     |
-- | hal1       | wait/io/file/mysys/charset           |     3 | 4.79 ms       | 4.71 ms     |
-- | hal1       | wait/io/file/myisam/kfile            |    67 | 4.38 ms       | 300.04 us   |
-- | hal1       | wait/io/file/sql/ERRMSG              |     5 | 2.72 ms       | 1.69 ms     |
-- | hal1       | wait/io/file/sql/pid                 |     3 | 266.30 us     | 185.47 us   |
-- | hal1       | wait/io/file/sql/casetest            |     5 | 246.81 us     | 150.19 us   |
-- | hal1       | wait/io/file/sql/global_ddl_log      |     2 | 21.24 us      | 18.59 us    |
-- | hal2       | wait/io/file/sql/file_parser         |  1422 | 4.80 s        | 135.14 ms   |
-- | hal2       | wait/io/file/sql/FRM                 |   865 | 85.82 ms      | 9.81 ms     |
-- | hal2       | wait/io/file/myisam/kfile            |  1073 | 37.14 ms      | 15.79 ms    |
-- | hal2       | wait/io/file/myisam/dfile            |  2991 | 25.53 ms      | 5.25 ms     |
-- | hal2       | wait/io/file/sql/dbopt               |    20 | 1.07 ms       | 153.07 us   |
-- | hal2       | wait/io/file/sql/misc                |     4 | 59.71 us      | 33.75 us    |
-- | hal2       | wait/io/file/archive/data            |     1 | 13.91 us      | 13.91 us    |
-- +------------+--------------------------------------+-------+---------------+-------------+
--

CREATE OR REPLACE
  ALGORITHM = MERGE
  DEFINER = 'mysql.sys'@'localhost'
  SQL SECURITY INVOKER 
VIEW host_summary_by_file_io_type (
  host,
  event_name,
  total,
  total_latency,
  max_latency
) AS
SELECT IF(host IS NULL, 'background', host) AS host,
       event_name,
       count_star AS total,
       format_pico_time(sum_timer_wait) AS total_latency,
       format_pico_time(max_timer_wait) AS max_latency
  FROM performance_schema.events_waits_summary_by_host_by_event_name
 WHERE event_name LIKE 'wait/io/file%'
   AND count_star > 0
 ORDER BY IF(host IS NULL, 'background', host), sum_timer_wait DESC;
-- Copyright (c) 2014, 2024, Oracle and/or its affiliates.
--
-- This program is free software; you can redistribute it and/or modify
-- it under the terms of the GNU General Public License as published by
-- the Free Software Foundation; version 2 of the License.
--
-- This program is distributed in the hope that it will be useful,
-- but WITHOUT ANY WARRANTY; without even the implied warranty of
-- MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
-- GNU General Public License for more details.
--
-- You should have received a copy of the GNU General Public License
-- along with this program; if not, write to the Free Software
-- Foundation, Inc., 51 Franklin St, Fifth Floor, Boston, MA 02110-1301 USA

--
-- View: x$host_summary_by_file_io_type
--
-- Summarizes file IO by event type per host.
--
-- When the host found is NULL, it is assumed to be a "background" thread.
--
-- mysql> select * from x$host_summary_by_file_io_type;
-- +------------+--------------------------------------+-------+---------------+--------------+
-- | host       | event_name                           | total | total_latency | max_latency  |
-- +------------+--------------------------------------+-------+---------------+--------------+
-- | hal1       | wait/io/file/sql/FRM                 |   871 |  168148450470 |  18482624810 |
-- | hal1       | wait/io/file/innodb/innodb_data_file |   173 |  129564287450 |  34087423890 |
-- | hal1       | wait/io/file/innodb/innodb_log_file  |    20 |   77525706960 |  60657475320 |
-- | hal1       | wait/io/file/myisam/dfile            |    40 |    6544493800 |   4580546230 |
-- | hal1       | wait/io/file/mysys/charset           |     3 |    4793558770 |   4713476430 |
-- | hal1       | wait/io/file/myisam/kfile            |    67 |    4384332810 |    300035450 |
-- | hal1       | wait/io/file/sql/ERRMSG              |     5 |    2717434850 |   1687316280 |
-- | hal1       | wait/io/file/sql/pid                 |     3 |     266301490 |    185468920 |
-- | hal1       | wait/io/file/sql/casetest            |     5 |     246814360 |    150193030 |
-- | hal1       | wait/io/file/sql/global_ddl_log      |     2 |      21236410 |     18593640 |
-- | hal2       | wait/io/file/sql/file_parser         |  1422 | 4801104756760 | 135138518970 |
-- | hal2       | wait/io/file/sql/FRM                 |   865 |   85818594810 |   9812303410 |
-- | hal2       | wait/io/file/myisam/kfile            |  1073 |   37143664870 |  15793838190 |
-- | hal2       | wait/io/file/myisam/dfile            |  2991 |   25528215700 |   5252232050 |
-- | hal2       | wait/io/file/sql/dbopt               |    20 |    1067339780 |    153073310 |
-- | hal2       | wait/io/file/sql/misc                |     4 |      59713030 |     33752810 |
-- | hal2       | wait/io/file/archive/data            |     1 |      13907530 |     13907530 |
-- +------------+--------------------------------------+-------+---------------+--------------+
--

CREATE OR REPLACE
  ALGORITHM = MERGE
  DEFINER = 'mysql.sys'@'localhost'
  SQL SECURITY INVOKER 
VIEW x$host_summary_by_file_io_type (
  host,
  event_name,
  total,
  total_latency,
  max_latency
) AS
SELECT IF(host IS NULL, 'background', host) AS host,
       event_name,
       count_star AS total,
       sum_timer_wait AS total_latency,
       max_timer_wait AS max_latency
  FROM performance_schema.events_waits_summary_by_host_by_event_name
 WHERE event_name LIKE 'wait/io/file%'
   AND count_star > 0
 ORDER BY IF(host IS NULL, 'background', host), sum_timer_wait DESC;
-- Copyright (c) 2014, 2024, Oracle and/or its affiliates.
--
-- This program is free software; you can redistribute it and/or modify
-- it under the terms of the GNU General Public License as published by
-- the Free Software Foundation; version 2 of the License.
--
-- This program is distributed in the hope that it will be useful,
-- but WITHOUT ANY WARRANTY; without even the implied warranty of
-- MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
-- GNU General Public License for more details.
--
-- You should have received a copy of the GNU General Public License
-- along with this program; if not, write to the Free Software
-- Foundation, Inc., 51 Franklin St, Fifth Floor, Boston, MA 02110-1301 USA

--
-- View: host_summary_by_file_io
--
-- Summarizes file IO totals per host.
--
-- When the host found is NULL, it is assumed to be a "background" thread.
--
-- mysql> select * from host_summary_by_file_io;
-- +------------+-------+------------+
-- | host       | ios   | io_latency |
-- +------------+-------+------------+
-- | hal1       | 26457 | 21.58 s    |
-- | hal2       |  1189 | 394.21 ms  |
-- +------------+-------+------------+
--

CREATE OR REPLACE
  ALGORITHM = TEMPTABLE
  DEFINER = 'mysql.sys'@'localhost'
  SQL SECURITY INVOKER 
VIEW host_summary_by_file_io (
  host,
  ios,
  io_latency
) AS
SELECT IF(host IS NULL, 'background', host) AS host,
       SUM(count_star) AS ios,
       format_pico_time(SUM(sum_timer_wait)) AS io_latency 
  FROM performance_schema.events_waits_summary_by_host_by_event_name
 WHERE event_name LIKE 'wait/io/file/%'
 GROUP BY IF(host IS NULL, 'background', host)
 ORDER BY SUM(sum_timer_wait) DESC;
-- Copyright (c) 2014, 2024, Oracle and/or its affiliates.
--
-- This program is free software; you can redistribute it and/or modify
-- it under the terms of the GNU General Public License as published by
-- the Free Software Foundation; version 2 of the License.
--
-- This program is distributed in the hope that it will be useful,
-- but WITHOUT ANY WARRANTY; without even the implied warranty of
-- MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
-- GNU General Public License for more details.
--
-- You should have received a copy of the GNU General Public License
-- along with this program; if not, write to the Free Software
-- Foundation, Inc., 51 Franklin St, Fifth Floor, Boston, MA 02110-1301 USA

--
-- View: x$host_summary_by_file_io
--
-- Summarizes file IO totals per host.
--
-- When the host found is NULL, it is assumed to be a "background" thread.
--
-- mysql> select * from x$host_summary_by_file_io;
-- +------------+-------+----------------+
-- | host       | ios   | io_latency     |
-- +------------+-------+----------------+
-- | hal1       | 26457 | 21579585586390 |
-- | hal2       |  1189 |   394212617370 |
-- +------------+-------+----------------+
--

CREATE OR REPLACE
  ALGORITHM = TEMPTABLE
  DEFINER = 'mysql.sys'@'localhost'
  SQL SECURITY INVOKER 
VIEW x$host_summary_by_file_io (
  host,
  ios,
  io_latency
) AS
SELECT IF(host IS NULL, 'background', host) AS host,
       SUM(count_star) AS ios,
       SUM(sum_timer_wait) AS io_latency 
  FROM performance_schema.events_waits_summary_by_host_by_event_name
 WHERE event_name LIKE 'wait/io/file/%'
 GROUP BY IF(host IS NULL, 'background', host)
 ORDER BY SUM(sum_timer_wait) DESC;
-- Copyright (c) 2014, 2024, Oracle and/or its affiliates.
--
-- This program is free software; you can redistribute it and/or modify
-- it under the terms of the GNU General Public License as published by
-- the Free Software Foundation; version 2 of the License.
--
-- This program is distributed in the hope that it will be useful,
-- but WITHOUT ANY WARRANTY; without even the implied warranty of
-- MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
-- GNU General Public License for more details.
--
-- You should have received a copy of the GNU General Public License
-- along with this program; if not, write to the Free Software
-- Foundation, Inc., 51 Franklin St, Fifth Floor, Boston, MA 02110-1301 USA

--
-- View: host_summary_by_statement_type
--
-- Summarizes the types of statements executed by each host.
--
-- When the host found is NULL, it is assumed to be a "background" thread.
--
-- mysql> select * from host_summary_by_statement_type;
-- +------+----------------------+--------+---------------+-------------+--------------+-----------+---------------+---------------+------------+
-- | host | statement            | total  | total_latency | max_latency | lock_latency | rows_sent | rows_examined | rows_affected | full_scans |
-- +------+----------------------+--------+---------------+-------------+--------------+-----------+---------------+---------------+------------+
-- | hal  | create_view          |   2063 | 00:05:04.20   | 463.58 ms   | 1.42 s       |         0 |             0 |             0 |          0 |
-- | hal  | select               |    174 | 40.87 s       | 28.83 s     | 858.13 ms    |      5212 |        157022 |             0 |         82 |
-- | hal  | stmt                 |   6645 | 15.31 s       | 491.78 ms   | 0 ps         |         0 |             0 |          7951 |          0 |
-- | hal  | call_procedure       |     17 | 4.78 s        | 1.02 s      | 37.94 ms     |         0 |             0 |            19 |          0 |
-- | hal  | create_table         |     19 | 3.04 s        | 431.71 ms   | 0 ps         |         0 |             0 |             0 |          0 |
-- ...
-- +------+----------------------+--------+---------------+-------------+--------------+-----------+---------------+---------------+------------+
--

CREATE OR REPLACE
  ALGORITHM = MERGE
  DEFINER = 'mysql.sys'@'localhost'
  SQL SECURITY INVOKER 
VIEW host_summary_by_statement_type (
  host,
  statement,
  total,
  total_latency,
  max_latency,
  lock_latency,
  cpu_latency,
  rows_sent,
  rows_examined,
  rows_affected,
  full_scans
) AS
SELECT IF(host IS NULL, 'background', host) AS host,
       SUBSTRING_INDEX(event_name, '/', -1) AS statement,
       count_star AS total,
       format_pico_time(sum_timer_wait) AS total_latency,
       format_pico_time(max_timer_wait) AS max_latency,
       format_pico_time(sum_lock_time) AS lock_latency,
       format_pico_time(sum_cpu_time) AS cpu_latency,
       sum_rows_sent AS rows_sent,
       sum_rows_examined AS rows_examined,
       sum_rows_affected AS rows_affected,
       sum_no_index_used + sum_no_good_index_used AS full_scans
  FROM performance_schema.events_statements_summary_by_host_by_event_name
 WHERE sum_timer_wait != 0
 ORDER BY IF(host IS NULL, 'background', host), sum_timer_wait DESC;
-- Copyright (c) 2014, 2024, Oracle and/or its affiliates.
--
-- This program is free software; you can redistribute it and/or modify
-- it under the terms of the GNU General Public License as published by
-- the Free Software Foundation; version 2 of the License.
--
-- This program is distributed in the hope that it will be useful,
-- but WITHOUT ANY WARRANTY; without even the implied warranty of
-- MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
-- GNU General Public License for more details.
--
-- You should have received a copy of the GNU General Public License
-- along with this program; if not, write to the Free Software
-- Foundation, Inc., 51 Franklin St, Fifth Floor, Boston, MA 02110-1301 USA

--
-- View: x$host_summary_by_statement_type
--
-- Summarizes the types of statements executed by each host.
--
-- When the host found is NULL, it is assumed to be a "background" thread.
--
-- mysql> select * from x$host_summary_by_statement_type;
-- +------+----------------------+--------+-----------------+----------------+----------------+-----------+---------------+---------------+------------+
-- | host | statement            | total  | total_latency   | max_latency    | lock_latency   | rows_sent | rows_examined | rows_affected | full_scans |
-- +------+----------------------+--------+-----------------+----------------+----------------+-----------+---------------+---------------+------------+
-- | hal  | create_view          |   2110 | 312717366332000 |   463578029000 |  1432355000000 |         0 |             0 |             0 |          0 |
-- | hal  | select               |    177 |  41115690428000 | 28827579292000 |   858709000000 |      5254 |        157437 |             0 |         83 |
-- | hal  | stmt                 |   6645 |  15305389969000 |   491780297000 |              0 |         0 |             0 |          7951 |          0 |
-- | hal  | call_procedure       |     17 |   4783806053000 |  1016083397000 |    37936000000 |         0 |             0 |            19 |          0 |
-- | hal  | create_table         |     19 |   3035120946000 |   431706815000 |              0 |         0 |             0 |             0 |          0 |
-- ...
-- +------+----------------------+--------+-----------------+----------------+----------------+-----------+---------------+---------------+------------+
--

CREATE OR REPLACE
  ALGORITHM = MERGE
  DEFINER = 'mysql.sys'@'localhost'
  SQL SECURITY INVOKER 
VIEW x$host_summary_by_statement_type (
  host,
  statement,
  total,
  total_latency,
  max_latency,
  lock_latency,
  cpu_latency,
  rows_sent,
  rows_examined,
  rows_affected,
  full_scans
) AS
SELECT IF(host IS NULL, 'background', host) AS host,
       SUBSTRING_INDEX(event_name, '/', -1) AS statement,
       count_star AS total,
       sum_timer_wait AS total_latency,
       max_timer_wait AS max_latency,
       sum_lock_time AS lock_latency,
       sum_cpu_time AS cpu_latency,
       sum_rows_sent AS rows_sent,
       sum_rows_examined AS rows_examined,
       sum_rows_affected AS rows_affected,
       sum_no_index_used + sum_no_good_index_used AS full_scans
  FROM performance_schema.events_statements_summary_by_host_by_event_name
 WHERE sum_timer_wait != 0
 ORDER BY IF(host IS NULL, 'background', host), sum_timer_wait DESC;
-- Copyright (c) 2014, 2024, Oracle and/or its affiliates.
--
-- This program is free software; you can redistribute it and/or modify
-- it under the terms of the GNU General Public License as published by
-- the Free Software Foundation; version 2 of the License.
--
-- This program is distributed in the hope that it will be useful,
-- but WITHOUT ANY WARRANTY; without even the implied warranty of
-- MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
-- GNU General Public License for more details.
--
-- You should have received a copy of the GNU General Public License
-- along with this program; if not, write to the Free Software
-- Foundation, Inc., 51 Franklin St, Fifth Floor, Boston, MA 02110-1301 USA

--
-- View: host_summary_by_statement_latency
--
-- Summarizes overall statement statistics by host.
--
-- When the host found is NULL, it is assumed to be a "background" thread.
--
-- mysql> select-- from host_summary_by_statement_latency;
-- +------+-------+---------------+-------------+--------------+-----------+---------------+---------------+------------+
-- | host | total | total_latency | max_latency | lock_latency | rows_sent | rows_examined | rows_affected | full_scans |
-- +------+-------+---------------+-------------+--------------+-----------+---------------+---------------+------------+
-- | hal  |  3381 | 00:02:09.13   | 1.48 s      | 1.07 s       |      1151 |         93947 |           150 |         91 |
-- +------+-------+---------------+-------------+--------------+-----------+---------------+---------------+------------+
--

CREATE OR REPLACE
  ALGORITHM = TEMPTABLE
  DEFINER = 'mysql.sys'@'localhost'
  SQL SECURITY INVOKER 
VIEW host_summary_by_statement_latency (
  host,
  total,
  total_latency,
  max_latency,
  lock_latency,
  cpu_latency,
  rows_sent,
  rows_examined,
  rows_affected,
  full_scans
) AS
SELECT IF(host IS NULL, 'background', host) AS host,
       SUM(count_star) AS total,
       format_pico_time(SUM(sum_timer_wait)) AS total_latency,
       format_pico_time(MAX(max_timer_wait)) AS max_latency,
       format_pico_time(SUM(sum_lock_time)) AS lock_latency,
       format_pico_time(SUM(sum_cpu_time)) AS cpu_latency,
       SUM(sum_rows_sent) AS rows_sent,
       SUM(sum_rows_examined) AS rows_examined,
       SUM(sum_rows_affected) AS rows_affected,
       SUM(sum_no_index_used) + SUM(sum_no_good_index_used) AS full_scans
  FROM performance_schema.events_statements_summary_by_host_by_event_name
 GROUP BY IF(host IS NULL, 'background', host)
 ORDER BY SUM(sum_timer_wait) DESC;
-- Copyright (c) 2014, 2024, Oracle and/or its affiliates.
--
-- This program is free software; you can redistribute it and/or modify
-- it under the terms of the GNU General Public License as published by
-- the Free Software Foundation; version 2 of the License.
--
-- This program is distributed in the hope that it will be useful,
-- but WITHOUT ANY WARRANTY; without even the implied warranty of
-- MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
-- GNU General Public License for more details.
--
-- You should have received a copy of the GNU General Public License
-- along with this program; if not, write to the Free Software
-- Foundation, Inc., 51 Franklin St, Fifth Floor, Boston, MA 02110-1301 USA

--
-- View: x$host_summary_by_statement_latency
--
-- Summarizes overall statement statistics by host.
--
-- When the host found is NULL, it is assumed to be a "background" thread.
--
-- mysql> select * from x$host_summary_by_statement_latency;
-- +------+-------+-----------------+---------------+---------------+-----------+---------------+---------------+------------+
-- | host | total | total_latency   | max_latency   | lock_latency  | rows_sent | rows_examined | rows_affected | full_scans |
-- +------+-------+-----------------+---------------+---------------+-----------+---------------+---------------+------------+
-- | hal  |  3382 | 129134039432000 | 1483246743000 | 1069831000000 |      1152 |         94286 |           150 |         92 |
-- +------+-------+-----------------+---------------+---------------+-----------+---------------+---------------+------------+
--

CREATE OR REPLACE
  ALGORITHM = TEMPTABLE
  DEFINER = 'mysql.sys'@'localhost'
  SQL SECURITY INVOKER 
VIEW x$host_summary_by_statement_latency (
  host,
  total,
  total_latency,
  max_latency,
  lock_latency,
  cpu_latency,
  rows_sent,
  rows_examined,
  rows_affected,
  full_scans
) AS
SELECT IF(host IS NULL, 'background', host) AS host,
       SUM(count_star) AS total,
       SUM(sum_timer_wait) AS total_latency,
       MAX(max_timer_wait) AS max_latency,
       SUM(sum_lock_time) AS lock_latency,
       SUM(sum_cpu_time) AS cpu_latency,
       SUM(sum_rows_sent) AS rows_sent,
       SUM(sum_rows_examined) AS rows_examined,
       SUM(sum_rows_affected) AS rows_affected,
       SUM(sum_no_index_used) + SUM(sum_no_good_index_used) AS full_scans
  FROM performance_schema.events_statements_summary_by_host_by_event_name
 GROUP BY IF(host IS NULL, 'background', host)
 ORDER BY SUM(sum_timer_wait) DESC;
-- Copyright (c) 2014, 2024, Oracle and/or its affiliates.
--
-- This program is free software; you can redistribute it and/or modify
-- it under the terms of the GNU General Public License as published by
-- the Free Software Foundation; version 2 of the License.
--
-- This program is distributed in the hope that it will be useful,
-- but WITHOUT ANY WARRANTY; without even the implied warranty of
-- MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
-- GNU General Public License for more details.
--
-- You should have received a copy of the GNU General Public License
-- along with this program; if not, write to the Free Software
-- Foundation, Inc., 51 Franklin St, Fifth Floor, Boston, MA 02110-1301 USA

--
-- View: host_summary_by_stages
--
-- Summarizes stages by host, ordered by host and total latency per stage.
--
-- When the host found is NULL, it is assumed to be a "background" thread.
--
-- mysql> select * from host_summary_by_stages;
-- +------+--------------------------------+-------+---------------+-------------+
-- | host | event_name                     | total | total_latency | avg_latency |
-- +------+--------------------------------+-------+---------------+-------------+
-- | hal  | stage/sql/Opening tables       |   889 | 1.97 ms       | 2.22 us     |
-- | hal  | stage/sql/Creating sort index  |     4 | 1.79 ms       | 446.30 us   |
-- | hal  | stage/sql/init                 |    10 | 312.27 us     | 31.23 us    |
-- | hal  | stage/sql/checking permissions |    10 | 300.62 us     | 30.06 us    |
-- | hal  | stage/sql/freeing items        |     5 | 85.89 us      | 17.18 us    |
-- | hal  | stage/sql/statistics           |     5 | 79.15 us      | 15.83 us    |
-- | hal  | stage/sql/preparing            |     5 | 69.12 us      | 13.82 us    |
-- | hal  | stage/sql/optimizing           |     5 | 53.11 us      | 10.62 us    |
-- | hal  | stage/sql/Sending data         |     5 | 44.66 us      | 8.93 us     |
-- | hal  | stage/sql/closing tables       |     5 | 37.54 us      | 7.51 us     |
-- | hal  | stage/sql/System lock          |     5 | 34.28 us      | 6.86 us     |
-- | hal  | stage/sql/query end            |     5 | 24.37 us      | 4.87 us     |
-- | hal  | stage/sql/end                  |     5 | 8.60 us       | 1.72 us     |
-- | hal  | stage/sql/Sorting result       |     5 | 8.33 us       | 1.67 us     |
-- | hal  | stage/sql/executing            |     5 | 5.37 us       | 1.07 us     |
-- | hal  | stage/sql/cleaning up          |     5 | 4.60 us       | 919.00 ns   |
-- +------+--------------------------------+-------+---------------+-------------+
--

CREATE OR REPLACE
  ALGORITHM = MERGE
  DEFINER = 'mysql.sys'@'localhost'
  SQL SECURITY INVOKER 
VIEW host_summary_by_stages (
  host,
  event_name,
  total,
  total_latency,
  avg_latency
) AS
SELECT IF(host IS NULL, 'background', host) AS host,
       event_name,
       count_star AS total,
       format_pico_time(sum_timer_wait) AS total_latency, 
       format_pico_time(avg_timer_wait) AS avg_latency 
  FROM performance_schema.events_stages_summary_by_host_by_event_name
 WHERE sum_timer_wait != 0
 ORDER BY IF(host IS NULL, 'background', host), sum_timer_wait DESC;
-- Copyright (c) 2014, 2024, Oracle and/or its affiliates.
--
-- This program is free software; you can redistribute it and/or modify
-- it under the terms of the GNU General Public License as published by
-- the Free Software Foundation; version 2 of the License.
--
-- This program is distributed in the hope that it will be useful,
-- but WITHOUT ANY WARRANTY; without even the implied warranty of
-- MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
-- GNU General Public License for more details.
--
-- You should have received a copy of the GNU General Public License
-- along with this program; if not, write to the Free Software
-- Foundation, Inc., 51 Franklin St, Fifth Floor, Boston, MA 02110-1301 USA

--
-- View: x$host_summary_by_stages
--
-- Summarizes stages by host, ordered by host and total latency per stage.
--
-- When the host found is NULL, it is assumed to be a "background" thread.
--
-- mysql> select * from x$host_summary_by_stages;
-- +------+--------------------------------+-------+---------------+-------------+
-- | host | event_name                     | total | total_latency | avg_latency |
-- +------+--------------------------------+-------+---------------+-------------+
-- | hal  | stage/sql/Opening tables       |  1114 |   71919037000 |    64559000 |
-- | hal  | stage/sql/Creating sort index  |     5 |    2245762000 |   449152000 |
-- | hal  | stage/sql/init                 |    13 |     428798000 |    32984000 |
-- | hal  | stage/sql/checking permissions |    13 |     363231000 |    27940000 |
-- | hal  | stage/sql/freeing items        |     7 |     137728000 |    19675000 |
-- | hal  | stage/sql/statistics           |     6 |      93955000 |    15659000 |
-- | hal  | stage/sql/preparing            |     6 |      82571000 |    13761000 |
-- | hal  | stage/sql/optimizing           |     6 |      63338000 |    10556000 |
-- | hal  | stage/sql/Sending data         |     6 |      53400000 |     8900000 |
-- | hal  | stage/sql/closing tables       |     7 |      46922000 |     6703000 |
-- | hal  | stage/sql/System lock          |     6 |      40175000 |     6695000 |
-- | hal  | stage/sql/query end            |     7 |      31723000 |     4531000 |
-- | hal  | stage/sql/Sorting result       |     6 |       9855000 |     1642000 |
-- | hal  | stage/sql/end                  |     6 |       9556000 |     1592000 |
-- | hal  | stage/sql/cleaning up          |     7 |       7312000 |     1044000 |
-- | hal  | stage/sql/executing            |     6 |       6487000 |     1081000 |
-- +------+--------------------------------+-------+---------------+-------------+
--

CREATE OR REPLACE
  ALGORITHM = MERGE
  DEFINER = 'mysql.sys'@'localhost'
  SQL SECURITY INVOKER 
VIEW x$host_summary_by_stages (
  host,
  event_name,
  total,
  total_latency,
  avg_latency
) AS
SELECT IF(host IS NULL, 'background', host) AS host,
       event_name,
       count_star AS total,
       sum_timer_wait AS total_latency, 
       avg_timer_wait AS avg_latency 
  FROM performance_schema.events_stages_summary_by_host_by_event_name
 WHERE sum_timer_wait != 0
 ORDER BY IF(host IS NULL, 'background', host), sum_timer_wait DESC;
-- Copyright (c) 2014, 2024, Oracle and/or its affiliates.
--
-- This program is free software; you can redistribute it and/or modify
-- it under the terms of the GNU General Public License as published by
-- the Free Software Foundation; version 2 of the License.
--
-- This program is distributed in the hope that it will be useful,
-- but WITHOUT ANY WARRANTY; without even the implied warranty of
-- MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
-- GNU General Public License for more details.
--
-- You should have received a copy of the GNU General Public License
-- along with this program; if not, write to the Free Software
-- Foundation, Inc., 51 Franklin St, Fifth Floor, Boston, MA 02110-1301 USA

--
-- View: host_summary
--
-- Summarizes statement activity and connections by host
--
-- When the host found is NULL, it is assumed to be a "background" thread.
--
-- mysql> select * from host_summary;
-- +------+------------+---------------+-------------+---------------------+-------------------+--------------+----------------+------------------------+
-- | host | statements | total_latency | avg_latency | current_connections | total_connections | unique_users | current_memory | total_memory_allocated |
-- +------+------------+---------------+-------------+---------------------+-------------------+--------------+----------------+------------------------+
-- | hal1 |       5663 | 00:01:47.14   | 18.92 ms    |                   1 |                 1 |            1 | 1.41 MiB       | 543.55 MiB             |
-- | hal2 |        225 | 14.49 s       | 64.40 ms    |                   1 |                 1 |            1 | 707.60 KiB     | 81.02 MiB              |
-- +------+------------+---------------+-------------+---------------------+-------------------+--------------+----------------+------------------------+
--

CREATE OR REPLACE
  ALGORITHM = TEMPTABLE
  DEFINER = 'mysql.sys'@'localhost'
  SQL SECURITY INVOKER 
VIEW host_summary (
  host,
  statements,
  statement_latency,
  statement_avg_latency,
  table_scans,
  file_ios,
  file_io_latency,
  current_connections,
  total_connections,
  unique_users,
  current_memory,
  total_memory_allocated
) AS
SELECT IF(accounts.host IS NULL, 'background', accounts.host) AS host,
       SUM(stmt.total) AS statements,
       format_pico_time(SUM(stmt.total_latency)) AS statement_latency,
       format_pico_time(IFNULL(SUM(stmt.total_latency) / NULLIF(SUM(stmt.total), 0), 0)) AS statement_avg_latency,
       SUM(stmt.full_scans) AS table_scans,
       SUM(io.ios) AS file_ios,
       format_pico_time(SUM(io.io_latency)) AS file_io_latency,
       SUM(accounts.current_connections) AS current_connections,
       SUM(accounts.total_connections) AS total_connections,
       COUNT(DISTINCT user) AS unique_users,
       format_bytes(SUM(mem.current_allocated)) AS current_memory,
       format_bytes(SUM(mem.total_allocated)) AS total_memory_allocated
  FROM performance_schema.accounts
  JOIN sys.x$host_summary_by_statement_latency AS stmt ON accounts.host = stmt.host
  JOIN sys.x$host_summary_by_file_io AS io ON accounts.host = io.host
  JOIN sys.x$memory_by_host_by_current_bytes mem ON accounts.host = mem.host
 GROUP BY IF(accounts.host IS NULL, 'background', accounts.host);
-- Copyright (c) 2014, 2024, Oracle and/or its affiliates.
--
-- This program is free software; you can redistribute it and/or modify
-- it under the terms of the GNU General Public License as published by
-- the Free Software Foundation; version 2 of the License.
--
-- This program is distributed in the hope that it will be useful,
-- but WITHOUT ANY WARRANTY; without even the implied warranty of
-- MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
-- GNU General Public License for more details.
--
-- You should have received a copy of the GNU General Public License
-- along with this program; if not, write to the Free Software
-- Foundation, Inc., 51 Franklin St, Fifth Floor, Boston, MA 02110-1301 USA

--
-- View: x$host_summary
--
-- Summarizes statement activity and connections by host
--
-- When the host found is NULL, it is assumed to be a "background" thread.
--
-- mysql> select * from x$host_summary;
-- +------+------------+-----------------+------------------+---------------------+-------------------+--------------+----------------+------------------------+
-- | host | statements | total_latency   | avg_latency      | current_connections | total_connections | unique_users | current_memory | total_memory_allocated |
-- +------+------------+-----------------+------------------+---------------------+-------------------+--------------+----------------+------------------------+
-- | hal1 |       5685 | 107175100271000 | 18852260381.8821 |                   1 |                 1 |            1 |        1459022 |              572855680 |
-- | hal2 |        225 |  14489223428000 | 64396548568.8889 |                   1 |                 1 |            1 |         724578 |               84958286 |
-- +------+------------+-----------------+------------------+---------------------+-------------------+--------------+----------------+------------------------+
--

CREATE OR REPLACE
  ALGORITHM = TEMPTABLE
  DEFINER = 'mysql.sys'@'localhost'
  SQL SECURITY INVOKER 
VIEW x$host_summary (
  host,
  statements,
  statement_latency,
  statement_avg_latency,
  table_scans,
  file_ios,
  file_io_latency,
  current_connections,
  total_connections,
  unique_users,
  current_memory,
  total_memory_allocated
) AS
SELECT IF(accounts.host IS NULL, 'background', accounts.host) AS host,
       SUM(stmt.total) AS statements,
       SUM(stmt.total_latency) AS statement_latency,
       SUM(stmt.total_latency) / SUM(stmt.total) AS statement_avg_latency,
       SUM(stmt.full_scans) AS table_scans,
       SUM(io.ios) AS file_ios,
       SUM(io.io_latency) AS file_io_latency,
       SUM(accounts.current_connections) AS current_connections,
       SUM(accounts.total_connections) AS total_connections,
       COUNT(DISTINCT accounts.user) AS unique_users,
       SUM(mem.current_allocated) AS current_memory,
       SUM(mem.total_allocated) AS total_memory_allocated
  FROM performance_schema.accounts
  JOIN sys.x$host_summary_by_statement_latency AS stmt ON accounts.host = stmt.host
  JOIN sys.x$host_summary_by_file_io AS io ON accounts.host = io.host
  JOIN sys.x$memory_by_host_by_current_bytes mem ON accounts.host = mem.host
 GROUP BY IF(accounts.host IS NULL, 'background', accounts.host);
-- Copyright (c) 2014, 2024, Oracle and/or its affiliates.
--
-- This program is free software; you can redistribute it and/or modify
-- it under the terms of the GNU General Public License as published by
-- the Free Software Foundation; version 2 of the License.
--
-- This program is distributed in the hope that it will be useful,
-- but WITHOUT ANY WARRANTY; without even the implied warranty of
-- MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
-- GNU General Public License for more details.
--
-- You should have received a copy of the GNU General Public License
-- along with this program; if not, write to the Free Software
-- Foundation, Inc., 51 Franklin St, Fifth Floor, Boston, MA 02110-1301 USA

--
-- View: wait_classes_global_by_avg_latency
-- 
-- Lists the top wait classes by average latency, ignoring idle (this may be very large).
--
-- mysql> select * from wait_classes_global_by_avg_latency where event_class != 'idle';
-- +-------------------+--------+---------------+-------------+-------------+-------------+
-- | event_class       | total  | total_latency | min_latency | avg_latency | max_latency |
-- +-------------------+--------+---------------+-------------+-------------+-------------+
-- | wait/io/file      | 543123 | 44.60 s       | 19.44 ns    | 82.11 us    | 4.21 s      |
-- | wait/io/table     |  22002 | 766.60 ms     | 148.72 ns   | 34.84 us    | 44.97 ms    |
-- | wait/io/socket    |  79613 | 967.17 ms     | 0 ps        | 12.15 us    | 27.10 ms    |
-- | wait/lock/table   |  35409 | 18.68 ms      | 65.45 ns    | 527.51 ns   | 969.88 us   |
-- | wait/synch/rwlock |  37935 | 4.61 ms       | 21.38 ns    | 121.61 ns   | 34.65 us    |
-- | wait/synch/mutex  | 390622 | 18.60 ms      | 19.44 ns    | 47.61 ns    | 10.32 us    |
-- +-------------------+--------+---------------+-------------+-------------+-------------+
--

CREATE OR REPLACE
  ALGORITHM = TEMPTABLE
  DEFINER = 'mysql.sys'@'localhost'
  SQL SECURITY INVOKER 
VIEW wait_classes_global_by_avg_latency (
  event_class,
  total,
  total_latency,
  min_latency,
  avg_latency,
  max_latency
) AS
SELECT SUBSTRING_INDEX(event_name,'/', 3) AS event_class,
       SUM(COUNT_STAR) AS total,
       format_pico_time(CAST(SUM(sum_timer_wait) AS UNSIGNED)) AS total_latency,
       format_pico_time(MIN(min_timer_wait)) AS min_latency,
       format_pico_time(IFNULL(SUM(sum_timer_wait) / NULLIF(SUM(COUNT_STAR), 0), 0)) AS avg_latency,
       format_pico_time(CAST(MAX(max_timer_wait) AS UNSIGNED)) AS max_latency
  FROM performance_schema.events_waits_summary_global_by_event_name
 WHERE sum_timer_wait > 0
   AND event_name != 'idle'
 GROUP BY event_class
 ORDER BY IFNULL(SUM(sum_timer_wait) / NULLIF(SUM(COUNT_STAR), 0), 0) DESC;
-- Copyright (c) 2014, 2024, Oracle and/or its affiliates.
--
-- This program is free software; you can redistribute it and/or modify
-- it under the terms of the GNU General Public License as published by
-- the Free Software Foundation; version 2 of the License.
--
-- This program is distributed in the hope that it will be useful,
-- but WITHOUT ANY WARRANTY; without even the implied warranty of
-- MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
-- GNU General Public License for more details.
--
-- You should have received a copy of the GNU General Public License
-- along with this program; if not, write to the Free Software
-- Foundation, Inc., 51 Franklin St, Fifth Floor, Boston, MA 02110-1301 USA

--
-- View: x$wait_classes_global_by_avg_latency
-- 
-- Lists the top wait classes by average latency, ignoring idle (this may be very large).
--
-- mysql> select * from x$wait_classes_global_by_avg_latency;
-- +-------------------+---------+-------------------+-------------+--------------------+------------------+
-- | event_class       | total   | total_latency     | min_latency | avg_latency        | max_latency      |
-- +-------------------+---------+-------------------+-------------+--------------------+------------------+
-- | idle              |    4331 | 16044682716000000 |     2000000 | 3704613880397.1369 | 1593550454000000 |
-- | wait/io/file      |   23037 |    20856702551880 |           0 |     905356711.0249 |     350700491310 |
-- | wait/io/table     |  224924 |      719670285750 |      116870 |       3199615.3623 |     208579012460 |
-- | wait/lock/table   |    6972 |        3674766030 |      109330 |        527074.8752 |          8855730 |
-- | wait/synch/rwlock |   11916 |        1273279800 |       37700 |        106854.6324 |          6838780 |
-- | wait/synch/mutex  | 1031881 |       80464286240 |       56550 |         77978.2613 |       2590408470 |
-- +-------------------+---------+-------------------+-------------+--------------------+------------------+
--

CREATE OR REPLACE
  ALGORITHM = TEMPTABLE
  DEFINER = 'mysql.sys'@'localhost'
  SQL SECURITY INVOKER 
VIEW x$wait_classes_global_by_avg_latency (
  event_class,
  total,
  total_latency,
  min_latency,
  avg_latency,
  max_latency
) AS
SELECT SUBSTRING_INDEX(event_name,'/', 3) AS event_class,
       SUM(COUNT_STAR) AS total,
       SUM(sum_timer_wait) AS total_latency,
       MIN(min_timer_wait) AS min_latency,
       IFNULL(SUM(sum_timer_wait) / NULLIF(SUM(COUNT_STAR), 0), 0) AS avg_latency,
       MAX(max_timer_wait) AS max_latency
  FROM performance_schema.events_waits_summary_global_by_event_name
 WHERE sum_timer_wait > 0
   AND event_name != 'idle'
 GROUP BY event_class
 ORDER BY IFNULL(SUM(sum_timer_wait) / NULLIF(SUM(COUNT_STAR), 0), 0) DESC;

-- Copyright (c) 2014, 2024, Oracle and/or its affiliates.
--
-- This program is free software; you can redistribute it and/or modify
-- it under the terms of the GNU General Public License as published by
-- the Free Software Foundation; version 2 of the License.
--
-- This program is distributed in the hope that it will be useful,
-- but WITHOUT ANY WARRANTY; without even the implied warranty of
-- MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
-- GNU General Public License for more details.
--
-- You should have received a copy of the GNU General Public License
-- along with this program; if not, write to the Free Software
-- Foundation, Inc., 51 Franklin St, Fifth Floor, Boston, MA 02110-1301 USA

--
-- View: wait_classes_global_by_latency
-- 
-- Lists the top wait classes by total latency, ignoring idle (this may be very large).
--
-- mysql> select * from wait_classes_global_by_latency;
-- +-------------------+--------+---------------+-------------+-------------+-------------+
-- | event_class       | total  | total_latency | min_latency | avg_latency | max_latency |
-- +-------------------+--------+---------------+-------------+-------------+-------------+
-- | wait/io/file      | 550470 | 46.01 s       | 19.44 ns    | 83.58 us    | 4.21 s      |
-- | wait/io/socket    | 228833 | 2.71 s        | 0 ps        | 11.86 us    | 29.93 ms    |
-- | wait/io/table     |  64063 | 1.89 s        | 99.79 ns    | 29.43 us    | 68.07 ms    |
-- | wait/lock/table   |  76029 | 47.19 ms      | 65.45 ns    | 620.74 ns   | 969.88 us   |
-- | wait/synch/mutex  | 635925 | 34.93 ms      | 19.44 ns    | 54.93 ns    | 107.70 us   |
-- | wait/synch/rwlock |  61287 | 7.62 ms       | 21.38 ns    | 124.37 ns   | 34.65 us    |
-- +-------------------+--------+---------------+-------------+-------------+-------------+
--

CREATE OR REPLACE
  ALGORITHM = TEMPTABLE
  DEFINER = 'mysql.sys'@'localhost'
  SQL SECURITY INVOKER 
VIEW wait_classes_global_by_latency (
  event_class,
  total,
  total_latency,
  min_latency,
  avg_latency,
  max_latency
) AS
SELECT SUBSTRING_INDEX(event_name,'/', 3) AS event_class, 
       SUM(COUNT_STAR) AS total,
       format_pico_time(SUM(sum_timer_wait)) AS total_latency,
       format_pico_time(MIN(min_timer_wait)) min_latency,
       format_pico_time(IFNULL(SUM(sum_timer_wait) / NULLIF(SUM(COUNT_STAR), 0), 0)) AS avg_latency,
       format_pico_time(MAX(max_timer_wait)) AS max_latency
  FROM performance_schema.events_waits_summary_global_by_event_name
 WHERE sum_timer_wait > 0
   AND event_name != 'idle'
 GROUP BY SUBSTRING_INDEX(event_name,'/', 3) 
 ORDER BY SUM(sum_timer_wait) DESC;
-- Copyright (c) 2014, 2024, Oracle and/or its affiliates.
--
-- This program is free software; you can redistribute it and/or modify
-- it under the terms of the GNU General Public License as published by
-- the Free Software Foundation; version 2 of the License.
--
-- This program is distributed in the hope that it will be useful,
-- but WITHOUT ANY WARRANTY; without even the implied warranty of
-- MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
-- GNU General Public License for more details.
--
-- You should have received a copy of the GNU General Public License
-- along with this program; if not, write to the Free Software
-- Foundation, Inc., 51 Franklin St, Fifth Floor, Boston, MA 02110-1301 USA

--
-- View: x$wait_classes_global_by_latency
-- 
-- Lists the top wait classes by total latency, ignoring idle (this may be very large).
--
-- mysql> SELECT * FROM x$wait_classes_global_by_latency;
-- +-------------------+---------+----------------+-------------+----------------+--------------+
-- | event_class       | total   | total_latency  | min_latency | avg_latency    | max_latency  |
-- +-------------------+---------+----------------+-------------+----------------+--------------+
-- | wait/io/file      |   29468 | 27100905420290 |           0 | 919672370.7170 | 350700491310 |
-- | wait/io/table     |  224924 |   719670285750 |      116870 |   3199615.3623 | 208579012460 |
-- | wait/synch/mutex  | 1532036 |   118515948070 |       56550 |     77358.4616 |   2590408470 |
-- | wait/io/socket    |    1193 |    10677541030 |           0 |   8950160.1257 |    287760330 |
-- | wait/lock/table   |    6972 |     3674766030 |      109330 |    527074.8752 |      8855730 |
-- | wait/synch/rwlock |   13646 |     1579833580 |       37700 |    115772.6499 |     28293850 |
-- +-------------------+---------+----------------+-------------+----------------+--------------+
--

CREATE OR REPLACE
  ALGORITHM = TEMPTABLE
  DEFINER = 'mysql.sys'@'localhost'
  SQL SECURITY INVOKER 
VIEW x$wait_classes_global_by_latency (
  event_class,
  total,
  total_latency,
  min_latency,
  avg_latency,
  max_latency
) AS
SELECT SUBSTRING_INDEX(event_name,'/', 3) AS event_class, 
       SUM(COUNT_STAR) AS total,
       SUM(sum_timer_wait) AS total_latency,
       MIN(min_timer_wait) AS min_latency,
       IFNULL(SUM(sum_timer_wait) / NULLIF(SUM(COUNT_STAR), 0), 0) AS avg_latency,
       MAX(max_timer_wait) AS max_latency
  FROM performance_schema.events_waits_summary_global_by_event_name
 WHERE sum_timer_wait > 0
   AND event_name != 'idle'
 GROUP BY SUBSTRING_INDEX(event_name,'/', 3) 
 ORDER BY SUM(sum_timer_wait) DESC;
-- Copyright (c) 2014, 2024, Oracle and/or its affiliates.
--
-- This program is free software; you can redistribute it and/or modify
-- it under the terms of the GNU General Public License as published by
-- the Free Software Foundation; version 2 of the License.
--
-- This program is distributed in the hope that it will be useful,
-- but WITHOUT ANY WARRANTY; without even the implied warranty of
-- MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
-- GNU General Public License for more details.
--
-- You should have received a copy of the GNU General Public License
-- along with this program; if not, write to the Free Software
-- Foundation, Inc., 51 Franklin St, Fifth Floor, Boston, MA 02110-1301 USA

--
-- View: waits_by_user_by_latency
--
-- Lists the top wait events per user by their total latency, ignoring idle (this may be very large).
--
-- mysql> select * from waits_by_user_by_latency;
-- +------+-----------------------------------------------------+--------+---------------+-------------+-------------+
-- | user | event                                               | total  | total_latency | avg_latency | max_latency |
-- +------+-----------------------------------------------------+--------+---------------+-------------+-------------+
-- | root | wait/io/file/sql/file_parser                        |  13743 | 00:01:00.46   | 4.40 ms     | 231.88 ms   |
-- | root | wait/io/file/innodb/innodb_data_file                |   4699 | 3.02 s        | 643.38 us   | 46.93 ms    |
-- | root | wait/io/file/sql/FRM                                |  11462 | 2.60 s        | 226.83 us   | 61.72 ms    |
-- | root | wait/io/file/myisam/dfile                           |  26776 | 746.70 ms     | 27.89 us    | 308.79 ms   |
-- | root | wait/io/file/myisam/kfile                           |   7126 | 462.66 ms     | 64.93 us    | 88.76 ms    |
-- | root | wait/io/file/sql/dbopt                              |    179 | 137.58 ms     | 768.59 us   | 15.46 ms    |
-- | root | wait/io/file/csv/metadata                           |      8 | 86.60 ms      | 10.82 ms    | 50.32 ms    |
-- | root | wait/synch/mutex/mysys/IO_CACHE::append_buffer_lock | 798080 | 66.46 ms      | 82.94 ns    | 161.03 us   |
-- | root | wait/io/file/sql/binlog                             |     19 | 49.11 ms      | 2.58 ms     | 9.40 ms     |
-- | root | wait/io/file/sql/misc                               |     26 | 22.38 ms      | 860.80 us   | 15.30 ms    |
-- | root | wait/io/file/csv/data                               |      4 | 297.46 us     | 74.37 us    | 111.93 us   |
-- | root | wait/synch/rwlock/sql/MDL_lock::rwlock              |    944 | 287.86 us     | 304.62 ns   | 874.64 ns   |
-- | root | wait/io/file/archive/data                           |      4 | 82.71 us      | 20.68 us    | 40.74 us    |
-- | root | wait/synch/mutex/myisam/MYISAM_SHARE::intern_lock   |     60 | 12.21 us      | 203.20 ns   | 512.72 ns   |
-- | root | wait/synch/mutex/innodb/trx_mutex                   |     81 | 5.93 us       | 73.14 ns    | 252.59 ns   |
-- +------+-----------------------------------------------------+--------+---------------+-------------+-------------+
--

CREATE OR REPLACE
  ALGORITHM = MERGE
  DEFINER = 'mysql.sys'@'localhost'
  SQL SECURITY INVOKER 
VIEW waits_by_user_by_latency (
  user,
  event,
  total,
  total_latency,
  avg_latency,
  max_latency
) AS
SELECT IF(user IS NULL, 'background', user) AS user,
       event_name AS event,
       count_star AS total,
       format_pico_time(sum_timer_wait) AS total_latency,
       format_pico_time(avg_timer_wait) AS avg_latency,
       format_pico_time(max_timer_wait) AS max_latency
  FROM performance_schema.events_waits_summary_by_user_by_event_name
 WHERE event_name != 'idle'
   AND user IS NOT NULL
   AND sum_timer_wait > 0
 ORDER BY user, sum_timer_wait DESC;
-- Copyright (c) 2014, 2024, Oracle and/or its affiliates.
--
-- This program is free software; you can redistribute it and/or modify
-- it under the terms of the GNU General Public License as published by
-- the Free Software Foundation; version 2 of the License.
--
-- This program is distributed in the hope that it will be useful,
-- but WITHOUT ANY WARRANTY; without even the implied warranty of
-- MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
-- GNU General Public License for more details.
--
-- You should have received a copy of the GNU General Public License
-- along with this program; if not, write to the Free Software
-- Foundation, Inc., 51 Franklin St, Fifth Floor, Boston, MA 02110-1301 USA

--
-- View: x$waits_by_user_by_latency
--
-- Lists the top wait events per user by their total latency, ignoring idle (this may be very large).
--
-- mysql> select * from x$waits_by_user_by_latency;
-- +------+-----------------------------------------------------+--------+----------------+-------------+--------------+
-- | user | event                                               | total  | total_latency  | avg_latency | max_latency  |
-- +------+-----------------------------------------------------+--------+----------------+-------------+--------------+
-- | root | wait/io/file/sql/file_parser                        |  13745 | 60462025415480 |  4398837508 | 231881092170 |
-- | root | wait/io/file/innodb/innodb_data_file                |   4699 |  3023248450820 |   643381037 |  46928334180 |
-- | root | wait/io/file/sql/FRM                                |  11467 |  2600067790580 |   226743257 |  61718277920 |
-- | root | wait/io/file/myisam/dfile                           |  26776 |   746701506200 |    27886690 | 308785046960 |
-- | root | wait/io/file/myisam/kfile                           |   7126 |   462661061590 |    64925432 |  88756408780 |
-- | root | wait/io/file/sql/dbopt                              |    179 |   137577467690 |   768589146 |  15457199810 |
-- | root | wait/io/file/csv/metadata                           |      8 |    86599791590 | 10824973666 |  50322529270 |
-- | root | wait/synch/mutex/mysys/IO_CACHE::append_buffer_lock | 798080 |    66461175430 |       82940 |    161028010 |
-- | root | wait/io/file/sql/binlog                             |     19 |    49110632610 |  2584770058 |   9400449760 |
-- | root | wait/io/file/sql/misc                               |     26 |    22380676630 |   860795052 |  15298475270 |
-- | root | wait/io/file/csv/data                               |      4 |      297460540 |    74365135 |    111931300 |
-- | root | wait/synch/rwlock/sql/MDL_lock::rwlock              |    944 |      287862120 |      304616 |       874640 |
-- | root | wait/io/file/archive/data                           |      4 |       82713800 |    20678450 |     40738620 |
-- | root | wait/synch/mutex/myisam/MYISAM_SHARE::intern_lock   |     60 |       12211030 |      203203 |       512720 |
-- | root | wait/synch/mutex/innodb/trx_mutex                   |     81 |        5926440 |       73138 |       252590 |
-- +------+-----------------------------------------------------+--------+----------------+-------------+--------------+
--

CREATE OR REPLACE
  ALGORITHM = MERGE
  DEFINER = 'mysql.sys'@'localhost'
  SQL SECURITY INVOKER 
VIEW x$waits_by_user_by_latency (
  user,
  event,
  total,
  total_latency,
  avg_latency,
  max_latency
) AS
SELECT IF(user IS NULL, 'background', user) AS user,
       event_name AS event,
       count_star AS total,
       sum_timer_wait AS total_latency,
       avg_timer_wait AS avg_latency,
       max_timer_wait AS max_latency
  FROM performance_schema.events_waits_summary_by_user_by_event_name
 WHERE event_name != 'idle'
   AND user IS NOT NULL
   AND sum_timer_wait > 0
 ORDER BY user, sum_timer_wait DESC;
-- Copyright (c) 2014, 2024, Oracle and/or its affiliates.
--
-- This program is free software; you can redistribute it and/or modify
-- it under the terms of the GNU General Public License as published by
-- the Free Software Foundation; version 2 of the License.
--
-- This program is distributed in the hope that it will be useful,
-- but WITHOUT ANY WARRANTY; without even the implied warranty of
-- MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
-- GNU General Public License for more details.
--
-- You should have received a copy of the GNU General Public License
-- along with this program; if not, write to the Free Software
-- Foundation, Inc., 51 Franklin St, Fifth Floor, Boston, MA 02110-1301 USA

--
-- View: waits_by_host_by_latency
--
-- Lists the top wait events per host by their total latency, ignoring idle (this may be very large).
--
-- mysql> select * from sys.waits_by_host_by_latency where host != 'background' limit 5;
-- +-----------+------------------------------+-------+---------------+-------------+-------------+
-- | host      | event                        | total | total_latency | avg_latency | max_latency |
-- +-----------+------------------------------+-------+---------------+-------------+-------------+
-- | localhost | wait/io/file/sql/file_parser |  1386 | 14.50 s       | 10.46 ms    | 357.36 ms   |
-- | localhost | wait/io/file/sql/FRM         |   162 | 356.08 ms     | 2.20 ms     | 75.33 ms    |
-- | localhost | wait/io/file/myisam/kfile    |   410 | 322.29 ms     | 786.08 us   | 65.98 ms    |
-- | localhost | wait/io/file/myisam/dfile    |  1327 | 307.44 ms     | 231.68 us   | 37.16 ms    |
-- | localhost | wait/io/file/sql/dbopt       |    89 | 180.34 ms     | 2.03 ms     | 63.41 ms    |
-- +-----------+------------------------------+-------+---------------+-------------+-------------+
--

CREATE OR REPLACE
  ALGORITHM = MERGE
  DEFINER = 'mysql.sys'@'localhost'
  SQL SECURITY INVOKER 
VIEW waits_by_host_by_latency (
  host,
  event,
  total,
  total_latency,
  avg_latency,
  max_latency
) AS
SELECT IF(host IS NULL, 'background', host) AS host,
       event_name AS event,
       count_star AS total,
       format_pico_time(sum_timer_wait) AS total_latency,
       format_pico_time(avg_timer_wait) AS avg_latency,
       format_pico_time(max_timer_wait) AS max_latency
  FROM performance_schema.events_waits_summary_by_host_by_event_name
 WHERE event_name != 'idle'
   AND sum_timer_wait > 0
 ORDER BY host, sum_timer_wait DESC;
-- Copyright (c) 2014, 2024, Oracle and/or its affiliates.
--
-- This program is free software; you can redistribute it and/or modify
-- it under the terms of the GNU General Public License as published by
-- the Free Software Foundation; version 2 of the License.
--
-- This program is distributed in the hope that it will be useful,
-- but WITHOUT ANY WARRANTY; without even the implied warranty of
-- MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
-- GNU General Public License for more details.
--
-- You should have received a copy of the GNU General Public License
-- along with this program; if not, write to the Free Software
-- Foundation, Inc., 51 Franklin St, Fifth Floor, Boston, MA 02110-1301 USA

--
-- View: waits_by_host_by_latency
--
-- Lists the top wait events per host by their total latency, ignoring idle (this may be very large).
--
-- mysql> select * from sys.x$waits_by_host_by_latency where host != 'background' limit 5;
-- +-----------+------------------------------+-------+----------------+-------------+--------------+
-- | host      | event                        | total | total_latency  | avg_latency | max_latency  |
-- +-----------+------------------------------+-------+----------------+-------------+--------------+
-- | localhost | wait/io/file/sql/file_parser |  1388 | 14502657551590 | 10448600240 | 357364034170 |
-- | localhost | wait/io/file/sql/FRM         |   167 |   361060236420 |  2162037319 |  75331088170 |
-- | localhost | wait/io/file/myisam/kfile    |   410 |   322294755250 |   786084585 |  65978227120 |
-- | localhost | wait/io/file/myisam/dfile    |  1327 |   307435262550 |   231676679 |  37162925800 |
-- | localhost | wait/io/file/sql/dbopt       |    89 |   180341976360 |  2026314303 |  63405386850 |
-- +-----------+------------------------------+-------+----------------+-------------+--------------+
--

CREATE OR REPLACE
  ALGORITHM = MERGE
  DEFINER = 'mysql.sys'@'localhost'
  SQL SECURITY INVOKER 
VIEW x$waits_by_host_by_latency (
  host,
  event,
  total,
  total_latency,
  avg_latency,
  max_latency
) AS
SELECT IF(host IS NULL, 'background', host) AS host,
       event_name AS event,
       count_star AS total,
       sum_timer_wait AS total_latency,
       avg_timer_wait AS avg_latency,
       max_timer_wait AS max_latency
  FROM performance_schema.events_waits_summary_by_host_by_event_name
 WHERE event_name != 'idle'
   AND sum_timer_wait > 0
 ORDER BY host, sum_timer_wait DESC;
-- Copyright (c) 2014, 2024, Oracle and/or its affiliates.
--
-- This program is free software; you can redistribute it and/or modify
-- it under the terms of the GNU General Public License as published by
-- the Free Software Foundation; version 2 of the License.
--
-- This program is distributed in the hope that it will be useful,
-- but WITHOUT ANY WARRANTY; without even the implied warranty of
-- MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
-- GNU General Public License for more details.
--
-- You should have received a copy of the GNU General Public License
-- along with this program; if not, write to the Free Software
-- Foundation, Inc., 51 Franklin St, Fifth Floor, Boston, MA 02110-1301 USA

--
-- View: waits_global_by_latency
--
-- Lists the top wait events by their total latency, ignoring idle (this may be very large).
--
-- mysql> select * from waits_global_by_latency limit 5;
-- +--------------------------------------+------------+---------------+-------------+-------------+
-- | event                                | total      | total_latency | avg_latency | max_latency |
-- +--------------------------------------+------------+---------------+-------------+-------------+
-- | wait/io/file/myisam/dfile            | 3623719744 | 00:47:49.09   | 791.70 ns   | 312.96 ms   |
-- | wait/io/table/sql/handler            |   69114944 | 00:44:30.74   | 38.64 us    | 879.49 ms   |
-- | wait/io/file/innodb/innodb_log_file  |   28100261 | 00:37:42.12   | 80.50 us    | 476.00 ms   |
-- | wait/io/socket/sql/client_connection |  200704863 | 00:18:37.81   | 5.57 us     | 1.27 s      |
-- | wait/io/file/innodb/innodb_data_file |    2829403 | 00:08:12.89   | 174.20 us   | 455.22 ms   |
-- +--------------------------------------+------------+---------------+-------------+-------------+
--

CREATE OR REPLACE
  ALGORITHM = MERGE
  DEFINER = 'mysql.sys'@'localhost'
  SQL SECURITY INVOKER 
VIEW waits_global_by_latency (
  events,
  total,
  total_latency,
  avg_latency,
  max_latency
) AS
SELECT event_name AS event,
       count_star AS total,
       format_pico_time(sum_timer_wait) AS total_latency,
       format_pico_time(avg_timer_wait) AS avg_latency,
       format_pico_time(max_timer_wait) AS max_latency
  FROM performance_schema.events_waits_summary_global_by_event_name
 WHERE event_name != 'idle'
   AND sum_timer_wait > 0
 ORDER BY sum_timer_wait DESC;
-- Copyright (c) 2014, 2024, Oracle and/or its affiliates.
--
-- This program is free software; you can redistribute it and/or modify
-- it under the terms of the GNU General Public License as published by
-- the Free Software Foundation; version 2 of the License.
--
-- This program is distributed in the hope that it will be useful,
-- but WITHOUT ANY WARRANTY; without even the implied warranty of
-- MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
-- GNU General Public License for more details.
--
-- You should have received a copy of the GNU General Public License
-- along with this program; if not, write to the Free Software
-- Foundation, Inc., 51 Franklin St, Fifth Floor, Boston, MA 02110-1301 USA

--
-- View: x$waits_global_by_latency
--
-- Lists the top wait events by their total latency, ignoring idle (this may be very large).
--
-- mysql> select * from x$waits_global_by_latency limit 5;
-- +--------------------------------------+-------+---------------+-------------+--------------+
-- | event                                | total | total_latency | avg_latency | max_latency  |
-- +--------------------------------------+-------+---------------+-------------+--------------+
-- | wait/io/file/sql/file_parser         |   679 | 3536136351540 |  5207858773 | 129860439800 |
-- | wait/io/file/innodb/innodb_data_file |   195 |  848170566100 |  4349592637 | 350700491310 |
-- | wait/io/file/sql/FRM                 |  1355 |  400428476500 |   295518990 |  44823120940 |
-- | wait/io/file/innodb/innodb_log_file  |    20 |   54298899070 |  2714944765 |  30108124800 |
-- | wait/io/file/mysys/charset           |     3 |   24244722970 |  8081574072 |  24151547420 |
-- +--------------------------------------+-------+---------------+-------------+--------------+
--

CREATE OR REPLACE
  ALGORITHM = MERGE
  DEFINER = 'mysql.sys'@'localhost'
  SQL SECURITY INVOKER 
VIEW x$waits_global_by_latency (
  events,
  total,
  total_latency,
  avg_latency,
  max_latency
) AS
SELECT event_name AS event,
       count_star AS total,
       sum_timer_wait AS total_latency,
       avg_timer_wait AS avg_latency,
       max_timer_wait AS max_latency
  FROM performance_schema.events_waits_summary_global_by_event_name
 WHERE event_name != 'idle'
   AND sum_timer_wait > 0
 ORDER BY sum_timer_wait DESC;
-- Copyright (c) 2015, 2024, Oracle and/or its affiliates.
--
--   This program is free software; you can redistribute it and/or modify
--   it under the terms of the GNU General Public License as published by
--   the Free Software Foundation; version 2 of the License.
--
--   This program is distributed in the hope that it will be useful,
--   but WITHOUT ANY WARRANTY; without even the implied warranty of
--   MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
--   GNU General Public License for more details.
--
--   You should have received a copy of the GNU General Public License
--   along with this program; if not, write to the Free Software
--   Foundation, Inc., 51 Franklin St, Fifth Floor, Boston, MA 02110-1301 USA 

-- IMPORTANT
-- If you update this view, also update the "5.7+ and the Performance Schema disabled"
-- query in procedures/diagnostics.sql

-- View: metrics
-- 
-- Creates a union of the following information:
--
--    *  performance_schema.global_status
--    *  information_schema.INNODB_METRICS
--    *  Performance Schema global memory usage information
--    *  Current time
--
-- For view has the following columns:
-- 
--    * Variable_name: The name of the variable
--    * Variable_value: The value of the variable
--    * Type: The type of the variable. This will depend on the source, e.g. Global Status, InnoDB Metrics - ..., etc.
--    * Enabled: Whether the variable is enabled or not. Possible values are 'YES', 'NO', 'PARTIAL'.
--      PARTIAL is currently only supported for the memory usage variables and means some but not all of the memory/% instruments
--      are enabled.
--
-- mysql> SELECT * FROM metrics;
-- +-----------------------------------------------+-------------------------...+--------------------------------------+---------+
-- | Variable_name                                 | Variable_value          ...| Type                                 | Enabled |
-- +-----------------------------------------------+-------------------------...+--------------------------------------+---------+
-- | aborted_clients                               | 0                       ...| Global Status                        | YES     |
-- | aborted_connects                              | 0                       ...| Global Status                        | YES     |
-- | binlog_cache_disk_use                         | 0                       ...| Global Status                        | YES     |
-- | binlog_cache_use                              | 0                       ...| Global Status                        | YES     |
-- | binlog_stmt_cache_disk_use                    | 0                       ...| Global Status                        | YES     |
-- | binlog_stmt_cache_use                         | 0                       ...| Global Status                        | YES     |
-- | bytes_received                                | 217081                  ...| Global Status                        | YES     |
-- | bytes_sent                                    | 27257                   ...| Global Status                        | YES     |
-- ...
-- | innodb_rwlock_x_os_waits                      | 0                       ...| InnoDB Metrics - server              | YES     |
-- | innodb_rwlock_x_spin_rounds                   | 2723                    ...| InnoDB Metrics - server              | YES     |
-- | innodb_rwlock_x_spin_waits                    | 1                       ...| InnoDB Metrics - server              | YES     |
-- | trx_active_transactions                       | 0                       ...| InnoDB Metrics - transaction         | NO      |
-- ...
-- | trx_rseg_current_size                         | 0                       ...| InnoDB Metrics - transaction         | NO      |
-- | trx_rseg_history_len                          | 4                       ...| InnoDB Metrics - transaction         | YES     |
-- | trx_rw_commits                                | 0                       ...| InnoDB Metrics - transaction         | NO      |
-- | trx_undo_slots_cached                         | 0                       ...| InnoDB Metrics - transaction         | NO      |
-- | trx_undo_slots_used                           | 0                       ...| InnoDB Metrics - transaction         | NO      |
-- | memory_current_allocated                      | 138244216               ...| Performance Schema                   | PARTIAL |
-- | memory_total_allocated                        | 138244216               ...| Performance Schema                   | PARTIAL |
-- | NOW()                                         | 2015-05-31 13:27:50.382 ...| System Time                          | YES     |
-- | UNIX_TIMESTAMP()                              | 1433042870.382          ...| System Time                          | YES     |
-- +-----------------------------------------------+-------------------------...+--------------------------------------+---------+
-- 412 rows in set (0.02 sec)

CREATE OR REPLACE
  ALGORITHM = TEMPTABLE
  DEFINER = 'mysql.sys'@'localhost'
  SQL SECURITY INVOKER 
VIEW metrics (
  Variable_name,
  Variable_value,
  Type,
  Enabled
) AS
(
SELECT LOWER(VARIABLE_NAME) AS Variable_name, VARIABLE_VALUE AS Variable_value, 'Global Status' AS Type, 'YES' AS Enabled
  FROM performance_schema.global_status
) UNION ALL (
SELECT NAME AS Variable_name, COUNT AS Variable_value,
       CONCAT('InnoDB Metrics - ', SUBSYSTEM) AS Type,
       IF(STATUS = 'enabled', 'YES', 'NO') AS Enabled
  FROM information_schema.INNODB_METRICS
  -- De duplication - some variables exists both in GLOBAL_STATUS and INNODB_METRICS
  -- Keep the one from GLOBAL_STATUS as it is always enabled and it's more likely to be used for existing tools.
 WHERE NAME NOT IN (
     'lock_row_lock_time', 'lock_row_lock_time_avg', 'lock_row_lock_time_max', 'lock_row_lock_waits',
     'buffer_pool_reads', 'buffer_pool_read_requests', 'buffer_pool_write_requests', 'buffer_pool_wait_free',
     'buffer_pool_read_ahead', 'buffer_pool_read_ahead_evicted', 'buffer_pool_pages_total', 'buffer_pool_pages_misc',
     'buffer_pool_pages_data', 'buffer_pool_bytes_data', 'buffer_pool_pages_dirty', 'buffer_pool_bytes_dirty',
     'buffer_pool_pages_free', 'buffer_pages_created', 'buffer_pages_written', 'buffer_pages_read',
     'buffer_data_reads', 'buffer_data_written', 'file_num_open_files',
     'os_log_bytes_written', 'os_log_fsyncs', 'os_log_pending_fsyncs', 'os_log_pending_writes',
     'log_waits', 'log_write_requests', 'log_writes', 'innodb_dblwr_writes', 'innodb_dblwr_pages_written', 'innodb_page_size')
) UNION ALL (
SELECT 'memory_current_allocated' AS Variable_name, SUM(CURRENT_NUMBER_OF_BYTES_USED) AS Variable_value, 'Performance Schema' AS Type,
        IF((SELECT COUNT(*) FROM performance_schema.setup_instruments WHERE NAME LIKE 'memory/%' AND ENABLED = 'YES') = 0, 'NO',
        IF((SELECT COUNT(*) FROM performance_schema.setup_instruments WHERE NAME LIKE 'memory/%' AND ENABLED = 'NO') = 0, 'YES',
            'PARTIAL')) AS Enabled
  FROM performance_schema.memory_summary_global_by_event_name
) UNION ALL (
SELECT 'memory_total_allocated' AS Variable_name, SUM(SUM_NUMBER_OF_BYTES_ALLOC) AS Variable_value, 'Performance Schema' AS Type,
        IF((SELECT COUNT(*) FROM performance_schema.setup_instruments WHERE NAME LIKE 'memory/%' AND ENABLED = 'YES') = 0, 'NO',
        IF((SELECT COUNT(*) FROM performance_schema.setup_instruments WHERE NAME LIKE 'memory/%' AND ENABLED = 'NO') = 0, 'YES',
            'PARTIAL')) AS Enabled
  FROM performance_schema.memory_summary_global_by_event_name
) UNION ALL (
SELECT 'NOW()' AS Variable_name, NOW(3) AS Variable_value, 'System Time' AS Type, 'YES' AS Enabled
) UNION ALL (
SELECT 'UNIX_TIMESTAMP()' AS Variable_name, ROUND(UNIX_TIMESTAMP(NOW(3)), 3) AS Variable_value, 'System Time' AS Type, 'YES' AS Enabled
)
 ORDER BY Type, Variable_name;
-- Copyright (c) 2014, 2024, Oracle and/or its affiliates.
--
-- This program is free software; you can redistribute it and/or modify
-- it under the terms of the GNU General Public License as published by
-- the Free Software Foundation; version 2 of the License.
--
-- This program is distributed in the hope that it will be useful,
-- but WITHOUT ANY WARRANTY; without even the implied warranty of
-- MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
-- GNU General Public License for more details.
--
-- You should have received a copy of the GNU General Public License
-- along with this program; if not, write to the Free Software
-- Foundation, Inc., 51 Franklin St, Fifth Floor, Boston, MA 02110-1301 USA

--
-- View: processlist
--
-- A detailed non-blocking processlist view to replace 
-- [INFORMATION_SCHEMA. | SHOW FULL] PROCESSLIST
-- 
-- Performs less locking than the legacy sources, whilst giving extra information.
--
-- mysql> select * from sys.processlist where conn_id is not null and command != 'daemon' and conn_id != connection_id()\G
-- *************************** 1. row ***************************
--                 thd_id: 44524
--                conn_id: 44502
--                   user: msandbox@localhost
--                     db: test
--                command: Query
--                  state: alter table (flush)
--                   time: 18
--      current_statement: alter table t1 add column g int
--       execution_engine: PRIMARY
--      statement_latency: 18.45 s
--               progress: 98.84
--           lock_latency: 265.43 ms
--          rows_examined: 0
--              rows_sent: 0
--          rows_affected: 0
--             tmp_tables: 0
--        tmp_disk_tables: 0
--              full_scan: NO
--         last_statement: NULL
-- last_statement_latency: NULL
--         current_memory: 664.06 KiB
--              last_wait: wait/io/file/innodb/innodb_data_file
--      last_wait_latency: 1.07 us
--                 source: fil0fil.cc:5146
--            trx_latency: NULL
--              trx_state: NULL
--         trx_autocommit: NULL
--                    pid: 4212
--           program_name: mysql
--

CREATE OR REPLACE
  ALGORITHM = TEMPTABLE
  DEFINER = 'mysql.sys'@'localhost'
  SQL SECURITY INVOKER
VIEW processlist (
  thd_id,
  conn_id,
  user,
  db,
  command,
  state,
  time,
  current_statement,
  execution_engine,
  statement_latency,
  progress,
  lock_latency,
  cpu_latency,
  rows_examined,
  rows_sent,
  rows_affected,
  tmp_tables,
  tmp_disk_tables,
  full_scan,
  last_statement,
  last_statement_latency,
  current_memory,
  last_wait,
  last_wait_latency,
  source,
  trx_latency,
  trx_state,
  trx_autocommit,
  pid,
  program_name
) AS
SELECT pps.thread_id AS thd_id,
       pps.processlist_id AS conn_id,
       IF(pps.name IN ('thread/sql/one_connection', 'thread/thread_pool/tp_one_connection'),
          CONCAT(pps.processlist_user, '@', pps.processlist_host),
          REPLACE(pps.name, 'thread/', '')) user,
       pps.processlist_db AS db,
       pps.processlist_command AS command,
       pps.processlist_state AS state,
       pps.processlist_time AS time,
       sys.format_statement(pps.processlist_info) AS current_statement,
       pps.execution_engine AS execution_engine,
       IF(esc.end_event_id IS NULL,
          format_pico_time(esc.timer_wait),
          NULL) AS statement_latency,
       IF(esc.end_event_id IS NULL,
          ROUND(100 * (estc.work_completed / estc.work_estimated), 2),
          NULL) AS progress,
       format_pico_time(esc.lock_time) AS lock_latency,
       format_pico_time(esc.cpu_time) AS cpu_latency,
       esc.rows_examined AS rows_examined,
       esc.rows_sent AS rows_sent,
       esc.rows_affected AS rows_affected,
       esc.created_tmp_tables AS tmp_tables,
       esc.created_tmp_disk_tables AS tmp_disk_tables,
       IF(esc.no_good_index_used > 0 OR esc.no_index_used > 0, 'YES', 'NO') AS full_scan,
       IF(esc.end_event_id IS NOT NULL,
          sys.format_statement(esc.sql_text),
          NULL) AS last_statement,
       IF(esc.end_event_id IS NOT NULL,
          format_pico_time(esc.timer_wait),
          NULL) AS last_statement_latency,
       format_bytes(mem.current_allocated) AS current_memory,
       ewc.event_name AS last_wait,
       IF(ewc.end_event_id IS NULL AND ewc.event_name IS NOT NULL,
          'Still Waiting',
          format_pico_time(ewc.timer_wait)) last_wait_latency,
       ewc.source,
       format_pico_time(etc.timer_wait) AS trx_latency,
       etc.state AS trx_state,
       etc.autocommit AS trx_autocommit,
       conattr_pid.attr_value as pid,
       conattr_progname.attr_value as program_name
  FROM performance_schema.threads AS pps
  LEFT JOIN performance_schema.events_waits_current AS ewc USING (thread_id)
  LEFT JOIN performance_schema.events_stages_current AS estc USING (thread_id)
  LEFT JOIN performance_schema.events_statements_current AS esc USING (thread_id)
  LEFT JOIN performance_schema.events_transactions_current AS etc USING (thread_id)
  LEFT JOIN sys.x$memory_by_thread_by_current_bytes AS mem USING (thread_id)
  LEFT JOIN performance_schema.session_connect_attrs AS conattr_pid
    ON conattr_pid.processlist_id=pps.processlist_id and conattr_pid.attr_name='_pid'
  LEFT JOIN performance_schema.session_connect_attrs AS conattr_progname
    ON conattr_progname.processlist_id=pps.processlist_id and conattr_progname.attr_name='program_name'
 ORDER BY pps.processlist_time DESC, last_wait_latency DESC;
-- Copyright (c) 2014, 2024, Oracle and/or its affiliates.
--
-- This program is free software; you can redistribute it and/or modify
-- it under the terms of the GNU General Public License as published by
-- the Free Software Foundation; version 2 of the License.
--
-- This program is distributed in the hope that it will be useful,
-- but WITHOUT ANY WARRANTY; without even the implied warranty of
-- MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
-- GNU General Public License for more details.
--
-- You should have received a copy of the GNU General Public License
-- along with this program; if not, write to the Free Software
-- Foundation, Inc., 51 Franklin St, Fifth Floor, Boston, MA 02110-1301 USA

--
-- View: x$processlist
--
-- A detailed non-blocking processlist view to replace 
-- [INFORMATION_SCHEMA. | SHOW FULL] PROCESSLIST
-- 
-- Performs less locking than the legacy sources, whilst giving extra information.
--
-- mysql> select * from sys.x$processlist where conn_id is not null and command != 'daemon' and conn_id != connection_id()\G
-- ...
-- *************************** 2. row ***************************
--                 thd_id: 720
--                conn_id: 698
--                   user: msandbox@localhost
--                     db: test
--                command: Query
--                  state: alter table (read PK and internal sort)
--                   time: 2
--      current_statement: alter table t1 add column l int
--       execution_engine: PRIMARY
--      statement_latency: 2349834276374
--               progress: 60.00
--           lock_latency: 339707000000
--          rows_examined: 0
--              rows_sent: 0
--          rows_affected: 0
--             tmp_tables: 0
--        tmp_disk_tables: 0
--              full_scan: NO
--         last_statement: NULL
-- last_statement_latency: NULL
--         current_memory: 10186821
--              last_wait: wait/io/file/innodb/innodb_data_file
--      last_wait_latency: Still Waiting
--                 source: fil0fil.cc:5351
--            trx_latency: NULL
--              trx_state: NULL
--         trx_autocommit: NULL
--                    pid: 5559
--           program_name: mysql
--

CREATE OR REPLACE
  ALGORITHM = TEMPTABLE
  DEFINER = 'mysql.sys'@'localhost'
  SQL SECURITY INVOKER
VIEW x$processlist (
  thd_id,
  conn_id,
  user,
  db,
  command,
  state,
  time,
  current_statement,
  execution_engine,
  statement_latency,
  progress,
  lock_latency,
  cpu_latency,
  rows_examined,
  rows_sent,
  rows_affected,
  tmp_tables,
  tmp_disk_tables,
  full_scan,
  last_statement,
  last_statement_latency,
  current_memory,
  last_wait,
  last_wait_latency,
  source,
  trx_latency,
  trx_state,
  trx_autocommit,
  pid,
  program_name
) AS
SELECT pps.thread_id AS thd_id,
       pps.processlist_id AS conn_id,
       IF(pps.name IN ('thread/sql/one_connection', 'thread/thread_pool/tp_one_connection'),
          CONCAT(pps.processlist_user, '@', pps.processlist_host),
          REPLACE(pps.name, 'thread/', '')) user,
       pps.processlist_db AS db,
       pps.processlist_command AS command,
       pps.processlist_state AS state,
       pps.processlist_time AS time,
       pps.processlist_info AS current_statement,
       pps.execution_engine AS execution_engine,
       IF(esc.end_event_id IS NULL,
          esc.timer_wait,
          NULL) AS statement_latency,
       IF(esc.end_event_id IS NULL,
          ROUND(100 * (estc.work_completed / estc.work_estimated), 2),
          NULL) AS progress,
       esc.lock_time AS lock_latency,
       esc.cpu_time AS cpu_latency,
       esc.rows_examined AS rows_examined,
       esc.rows_sent AS rows_sent,
       esc.rows_affected AS rows_affected,
       esc.created_tmp_tables AS tmp_tables,
       esc.created_tmp_disk_tables AS tmp_disk_tables,
       IF(esc.no_good_index_used > 0 OR esc.no_index_used > 0, 'YES', 'NO') AS full_scan,
       IF(esc.end_event_id IS NOT NULL,
          esc.sql_text,
          NULL) AS last_statement,
       IF(esc.end_event_id IS NOT NULL,
          esc.timer_wait,
          NULL) AS last_statement_latency,
       mem.current_allocated AS current_memory,
       ewc.event_name AS last_wait,
       IF(ewc.end_event_id IS NULL AND ewc.event_name IS NOT NULL,
          'Still Waiting', 
          ewc.timer_wait) last_wait_latency,
       ewc.source,
       etc.timer_wait AS trx_latency,
       etc.state AS trx_state,
       etc.autocommit AS trx_autocommit,
       conattr_pid.attr_value as pid,
       conattr_progname.attr_value as program_name
  FROM performance_schema.threads AS pps
  LEFT JOIN performance_schema.events_waits_current AS ewc USING (thread_id)
  LEFT JOIN performance_schema.events_stages_current AS estc USING (thread_id)
  LEFT JOIN performance_schema.events_statements_current AS esc USING (thread_id)
  LEFT JOIN performance_schema.events_transactions_current AS etc USING (thread_id)
  LEFT JOIN sys.x$memory_by_thread_by_current_bytes AS mem USING (thread_id)
  LEFT JOIN performance_schema.session_connect_attrs AS conattr_pid
    ON conattr_pid.processlist_id=pps.processlist_id and conattr_pid.attr_name='_pid'
  LEFT JOIN performance_schema.session_connect_attrs AS conattr_progname
    ON conattr_progname.processlist_id=pps.processlist_id and conattr_progname.attr_name='program_name'
 ORDER BY pps.processlist_time DESC, last_wait_latency DESC;
-- Copyright (c) 2014, 2024, Oracle and/or its affiliates.
--
-- This program is free software; you can redistribute it and/or modify
-- it under the terms of the GNU General Public License as published by
-- the Free Software Foundation; version 2 of the License.
--
-- This program is distributed in the hope that it will be useful,
-- but WITHOUT ANY WARRANTY; without even the implied warranty of
-- MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
-- GNU General Public License for more details.
--
-- You should have received a copy of the GNU General Public License
-- along with this program; if not, write to the Free Software
-- Foundation, Inc., 51 Franklin St, Fifth Floor, Boston, MA 02110-1301 USA

--
-- View: session
--
-- Filter sys.processlist to only show user sessions and not background threads.
-- This is a non-blocking closer replacement to
-- [INFORMATION_SCHEMA. | SHOW FULL] PROCESSLIST
-- 
-- Performs less locking than the legacy sources, whilst giving extra information.
--
-- mysql> select * from sys.session\G
-- *************************** 1. row ***************************
--                 thd_id: 24
--                conn_id: 2
--                   user: root@localhost
--                     db: sys
--                command: Query
--                  state: Sending data
--                   time: 0
--      current_statement: select * from sys.session
--       execution_engine: PRIMARY
--      statement_latency: 137.22 ms
--               progress: NULL
--           lock_latency: 33.75 ms
--          rows_examined: 0
--              rows_sent: 0
--          rows_affected: 0
--             tmp_tables: 4
--        tmp_disk_tables: 1
--              full_scan: YES
--         last_statement: NULL
-- last_statement_latency: NULL
--         current_memory: 3.26 MiB
--              last_wait: wait/synch/mutex/innodb/file_format_max_mutex
--      last_wait_latency: 64.09 ns
--                 source: trx0sys.cc:778
--            trx_latency: 7.88 s
--              trx_state: ACTIVE
--         trx_autocommit: NO
--                    pid: 4212
--           program_name: mysql
--

CREATE OR REPLACE
  DEFINER = 'mysql.sys'@'localhost'
  SQL SECURITY INVOKER 
VIEW session
 AS
SELECT * FROM sys.processlist
WHERE conn_id IS NOT NULL AND command != 'Daemon';

-- Copyright (c) 2014, 2024, Oracle and/or its affiliates.
--
-- This program is free software; you can redistribute it and/or modify
-- it under the terms of the GNU General Public License as published by
-- the Free Software Foundation; version 2 of the License.
--
-- This program is distributed in the hope that it will be useful,
-- but WITHOUT ANY WARRANTY; without even the implied warranty of
-- MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
-- GNU General Public License for more details.
--
-- You should have received a copy of the GNU General Public License
-- along with this program; if not, write to the Free Software
-- Foundation, Inc., 51 Franklin St, Fifth Floor, Boston, MA 02110-1301 USA

--
-- View: x$session
--
-- Filter sys.processlist to only show user sessions and not background threads.
-- This is a non-blocking closer replacement to
-- [INFORMATION_SCHEMA. | SHOW FULL] PROCESSLIST
-- 
-- Performs less locking than the legacy sources, whilst giving extra information.
--
-- mysql> select * from sys.x$session\G
-- *************************** 1. row ***************************
--                 thd_id: 24
--                conn_id: 2
--                   user: root@localhost
--                     db: sys
--                command: Query
--                  state: Sending data
--                   time: 0
--      current_statement: select * from sys.x$session
--       execution_engine: PRIMARY
--      statement_latency: 16285980000
--               progress: NULL
--           lock_latency: 15450000000
--          rows_examined: 0
--              rows_sent: 0
--          rows_affected: 0
--             tmp_tables: 4
--        tmp_disk_tables: 1
--              full_scan: YES
--         last_statement: NULL
-- last_statement_latency: NULL
--         current_memory: 3383772
--              last_wait: wait/synch/mutex/innodb/trx_mutex
--      last_wait_latency: 56550
--                 source: trx0trx.h:1520
--            trx_latency: 17893350207000
--              trx_state: ACTIVE
--         trx_autocommit: NO
--                    pid: 5559
--           program_name: mysql
--

CREATE OR REPLACE
  DEFINER = 'mysql.sys'@'localhost'
  SQL SECURITY INVOKER 
VIEW x$session
 AS
SELECT * FROM sys.x$processlist
WHERE conn_id IS NOT NULL AND command != 'Daemon';
-- Copyright (c) 2015, 2024, Oracle and/or its affiliates.
--
-- This program is free software; you can redistribute it and/or modify
-- it under the terms of the GNU General Public License as published by
-- the Free Software Foundation; version 2 of the License.
--
-- This program is distributed in the hope that it will be useful,
-- but WITHOUT ANY WARRANTY; without even the implied warranty of
-- MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
-- GNU General Public License for more details.
--
-- You should have received a copy of the GNU General Public License
-- along with this program; if not, write to the Free Software
-- Foundation, Inc., 51 Franklin St, Fifth Floor, Boston, MA 02110-1301 USA

--
-- View: session_ssl_status
--
-- Shows SSL version, cipher and the count of re-used SSL sessions per connection
--
-- mysql> select * from session_ssl_status;
-- +-----------+-------------+--------------------+---------------------+
-- | thread_id | ssl_version | ssl_cipher         | ssl_sessions_reused |
-- +-----------+-------------+--------------------+---------------------+
-- |        26 | TLSv1       | DHE-RSA-AES256-SHA | 0                   |
-- |        27 | TLSv1       | DHE-RSA-AES256-SHA | 0                   |
-- |        28 | TLSv1       | DHE-RSA-AES256-SHA | 0                   |
-- +-----------+-------------+--------------------+---------------------+
-- 3 rows in set (0.00 sec)
--

CREATE OR REPLACE
  ALGORITHM = MERGE
  DEFINER = 'mysql.sys'@'localhost'
  SQL SECURITY INVOKER
VIEW session_ssl_status (
  thread_id,
  ssl_version,
  ssl_cipher,
  ssl_sessions_reused
) AS
SELECT sslver.thread_id, 
       sslver.variable_value ssl_version, 
       sslcip.variable_value ssl_cipher,
       sslreuse.variable_value ssl_sessions_reused
  FROM performance_schema.status_by_thread sslver 
  LEFT JOIN performance_schema.status_by_thread sslcip 
    ON (sslcip.thread_id=sslver.thread_id and sslcip.variable_name='Ssl_cipher')
  LEFT JOIN performance_schema.status_by_thread sslreuse 
    ON (sslreuse.thread_id=sslver.thread_id and sslreuse.variable_name='Ssl_sessions_reused') 
 WHERE sslver.variable_name='Ssl_version';
-- Copyright (c) 2014, 2024, Oracle and/or its affiliates.
--
-- This program is free software; you can redistribute it and/or modify
-- it under the terms of the GNU General Public License as published by
-- the Free Software Foundation; version 2 of the License.
--
-- This program is distributed in the hope that it will be useful,
-- but WITHOUT ANY WARRANTY; without even the implied warranty of
-- MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
-- GNU General Public License for more details.
--
-- You should have received a copy of the GNU General Public License
-- along with this program; if not, write to the Free Software
-- Foundation, Inc., 51 Franklin St, Fifth Floor, Boston, MA 02110-1301 USA

DROP PROCEDURE IF EXISTS create_synonym_db;

DELIMITER $$

CREATE DEFINER='mysql.sys'@'localhost' PROCEDURE create_synonym_db (
        IN in_db_name VARCHAR(64), 
        IN in_synonym VARCHAR(64)
    )
    COMMENT '
Description
-----------

Takes a source database name and synonym name, and then creates the 
synonym database with views that point to all of the tables within
the source database.

Useful for creating a "ps" synonym for "performance_schema",
or "is" instead of "information_schema", for example.

Parameters
-----------

in_db_name (VARCHAR(64)):
  The database name that you would like to create a synonym for.
in_synonym (VARCHAR(64)):
  The database synonym name.

Example
-----------

mysql> SHOW DATABASES;
+--------------------+
| Database           |
+--------------------+
| information_schema |
| mysql              |
| performance_schema |
| sys                |
| test               |
+--------------------+
5 rows in set (0.00 sec)

mysql> CALL sys.create_synonym_db(\'performance_schema\', \'ps\');
+---------------------------------------+
| summary                               |
+---------------------------------------+
| Created 74 views in the `ps` database |
+---------------------------------------+
1 row in set (8.57 sec)

Query OK, 0 rows affected (8.57 sec)

mysql> SHOW DATABASES;
+--------------------+
| Database           |
+--------------------+
| information_schema |
| mysql              |
| performance_schema |
| ps                 |
| sys                |
| test               |
+--------------------+
6 rows in set (0.00 sec)

mysql> SHOW FULL TABLES FROM ps;
+------------------------------------------------------+------------+
| Tables_in_ps                                         | Table_type |
+------------------------------------------------------+------------+
| accounts                                             | VIEW       |
| cond_instances                                       | VIEW       |
| events_stages_current                                | VIEW       |
| events_stages_history                                | VIEW       |
...
'
    SQL SECURITY INVOKER
    NOT DETERMINISTIC
    MODIFIES SQL DATA
BEGIN
    DECLARE v_done bool DEFAULT FALSE;
    DECLARE v_db_name_check VARCHAR(64);
    DECLARE v_db_err_msg TEXT;
    DECLARE v_table VARCHAR(64);
    DECLARE v_views_created INT DEFAULT 0;

    DECLARE db_doesnt_exist CONDITION FOR SQLSTATE '42000';
    DECLARE db_name_exists CONDITION FOR SQLSTATE 'HY000';

    DECLARE c_table_names CURSOR FOR 
        SELECT TABLE_NAME 
          FROM INFORMATION_SCHEMA.TABLES 
         WHERE TABLE_SCHEMA = in_db_name;

    DECLARE CONTINUE HANDLER FOR NOT FOUND SET v_done = TRUE;

    -- Check if the source database exists
    SELECT SCHEMA_NAME INTO v_db_name_check
      FROM INFORMATION_SCHEMA.SCHEMATA
     WHERE SCHEMA_NAME = in_db_name;

    IF v_db_name_check IS NULL THEN
        SET v_db_err_msg = CONCAT('Unknown database ', in_db_name);
        SIGNAL SQLSTATE 'HY000'
            SET MESSAGE_TEXT = v_db_err_msg;
    END IF;

    -- Check if a database of the synonym name already exists
    SELECT SCHEMA_NAME INTO v_db_name_check
      FROM INFORMATION_SCHEMA.SCHEMATA
     WHERE SCHEMA_NAME = in_synonym;

    IF v_db_name_check = in_synonym THEN
        SET v_db_err_msg = CONCAT('Can\'t create database ', in_synonym, '; database exists');
        SIGNAL SQLSTATE 'HY000'
            SET MESSAGE_TEXT = v_db_err_msg;
    END IF;

    -- All good, create the database and views
    SET @create_db_stmt := CONCAT('CREATE DATABASE ', sys.quote_identifier(in_synonym));
    PREPARE create_db_stmt FROM @create_db_stmt;
    EXECUTE create_db_stmt;
    DEALLOCATE PREPARE create_db_stmt;

    SET v_done = FALSE;
    OPEN c_table_names;
    c_table_names: LOOP
        FETCH c_table_names INTO v_table;
        IF v_done THEN
            LEAVE c_table_names;
        END IF;

        SET @create_view_stmt = CONCAT(
            'CREATE SQL SECURITY INVOKER VIEW ',
            sys.quote_identifier(in_synonym),
            '.',
            sys.quote_identifier(v_table),
            ' AS SELECT * FROM ',
            sys.quote_identifier(in_db_name),
            '.',
            sys.quote_identifier(v_table)
        );
        PREPARE create_view_stmt FROM @create_view_stmt;
        EXECUTE create_view_stmt;
        DEALLOCATE PREPARE create_view_stmt;

        SET v_views_created = v_views_created + 1;
    END LOOP;
    CLOSE c_table_names;

    SELECT CONCAT(
        'Created ', v_views_created, ' view',
        IF(v_views_created != 1, 's', ''), ' in the ',
        sys.quote_identifier(in_synonym), ' database'
    ) AS summary;

END$$

DELIMITER ;
--  Copyright (c) 2015, 2024, Oracle and/or its affiliates.
--
--  This program is free software; you can redistribute it and/or modify
--  it under the terms of the GNU General Public License as published by
--  the Free Software Foundation; version 2 of the License.
--
--  This program is distributed in the hope that it will be useful,
--  but WITHOUT ANY WARRANTY; without even the implied warranty of
--  MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
--  GNU General Public License for more details.
--
--  You should have received a copy of the GNU General Public License
--  along with this program; if not, write to the Free Software
--  Foundation, Inc., 51 Franklin St, Fifth Floor, Boston, MA 02110-1301 USA

DROP PROCEDURE IF EXISTS execute_prepared_stmt;

DELIMITER $$

CREATE DEFINER='mysql.sys'@'localhost' PROCEDURE execute_prepared_stmt (
        IN in_query longtext CHARACTER SET UTF8MB4
    )
    COMMENT '
Description
-----------

Takes the query in the argument and executes it using a prepared statement. The prepared statement is deallocated,
so the procedure is mainly useful for executing one off dynamically created queries.

The sys_execute_prepared_stmt prepared statement name is used for the query and is required not to exist.


Parameters
-----------

in_query (longtext CHARACTER SET UTF8MB4):
  The query to execute.


Configuration Options
----------------------

sys.debug
  Whether to provide debugging output.
  Default is ''OFF''. Set to ''ON'' to include.


Example
--------

mysql> CALL sys.execute_prepared_stmt(''SELECT * FROM sys.sys_config'');
+------------------------+-------+---------------------+--------+
| variable               | value | set_time            | set_by |
+------------------------+-------+---------------------+--------+
| statement_truncate_len | 64    | 2015-06-30 13:06:00 | NULL   |
+------------------------+-------+---------------------+--------+
1 row in set (0.00 sec)

Query OK, 0 rows affected (0.00 sec)
'
    SQL SECURITY INVOKER
    NOT DETERMINISTIC
    READS SQL DATA
BEGIN
    -- Set configuration options
    IF (@sys.debug IS NULL) THEN
        SET @sys.debug = sys.sys_get_config('debug', 'OFF');
    END IF;

    -- Verify the query exists
    -- The shortest possible query is "DO 1"
    IF (in_query IS NULL OR LENGTH(in_query) < 4) THEN
       SIGNAL SQLSTATE '45000'
          SET MESSAGE_TEXT = "The @sys.execute_prepared_stmt.sql must contain a query";
    END IF;

    SET @sys.execute_prepared_stmt.sql = in_query;

    IF (@sys.debug = 'ON') THEN
        SELECT @sys.execute_prepared_stmt.sql AS 'Debug';
    END IF;
    PREPARE sys_execute_prepared_stmt FROM @sys.execute_prepared_stmt.sql;
    EXECUTE sys_execute_prepared_stmt;
    DEALLOCATE PREPARE sys_execute_prepared_stmt;

    SET @sys.execute_prepared_stmt.sql = NULL;
END$$

DELIMITER ;
--  Copyright (c) 2015, 2024, Oracle and/or its affiliates.
-- 
--  This program is free software; you can redistribute it and/or modify
--  it under the terms of the GNU General Public License as published by
--  the Free Software Foundation; version 2 of the License.
-- 
--  This program is distributed in the hope that it will be useful,
--  but WITHOUT ANY WARRANTY; without even the implied warranty of
--  MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
--  GNU General Public License for more details.
-- 
--  You should have received a copy of the GNU General Public License
--  along with this program; if not, write to the Free Software
--  Foundation, Inc., 51 Franklin St, Fifth Floor, Boston, MA 02110-1301 USA 

DROP PROCEDURE IF EXISTS diagnostics;

DELIMITER $$

CREATE DEFINER='mysql.sys'@'localhost' PROCEDURE diagnostics (
        IN in_max_runtime int unsigned, IN in_interval int unsigned,
        IN in_auto_config enum ('current', 'medium', 'full')
    )
    COMMENT '
Description
-----------

Create a report of the current status of the server for diagnostics purposes. Data collected includes (some items depends on versions and settings):

   * The GLOBAL VARIABLES
   * Several sys schema views including metrics or equivalent (depending on version and settings)
   * Queries in the 95th percentile
   * Several ndbinfo views for MySQL Cluster
   * Replication (both master and slave) information.

Some of the sys schema views are calculated as initial (optional), overall, delta:

   * The initial view is the content of the view at the start of this procedure.
     This output will be the same as the the start values used for the delta view.
     The initial view is included if @sys.diagnostics.include_raw = ''ON''.
   * The overall view is the content of the view at the end of this procedure.
     This output is the same as the end values used for the delta view.
     The overall view is always included.
   * The delta view is the difference from the beginning to the end. Note that for min and max values
     they are simply the min or max value from the end view respectively, so does not necessarily reflect
     the minimum/maximum value in the monitored period.
     Note: except for the metrics views the delta is only calculation between the first and last outputs.

Requires the SUPER privilege for "SET sql_log_bin = 0;".

Parameters
-----------

in_max_runtime (INT UNSIGNED):
  The maximum time to keep collecting data.
  Use NULL to get the default which is 60 seconds, otherwise enter a value greater than 0.
in_interval (INT UNSIGNED):
  How long to sleep between data collections.
  Use NULL to get the default which is 30 seconds, otherwise enter a value greater than 0.
in_auto_config (ENUM(''current'', ''medium'', ''full''))
  Automatically enable Performance Schema instruments and consumers.
  NOTE: The more that are enabled, the more impact on the performance.
  Supported values are:
     * current - use the current settings.
     * medium - enable some settings. This requires the SUPER privilege.
     * full - enables all settings. This will have a big impact on the
              performance - be careful using this option. This requires
              the SUPER privilege.
  If another setting the ''current'' is chosen, the current settings
  are restored at the end of the procedure.


Configuration Options
----------------------

sys.diagnostics.allow_i_s_tables
  Specifies whether it is allowed to do table scan queries on information_schema.TABLES. This can be expensive if there
  are many tables. Set to ''ON'' to allow, ''OFF'' to not allow.
  Default is ''OFF''.

sys.diagnostics.include_raw
  Set to ''ON'' to include the raw data (e.g. the original output of "SELECT * FROM sys.metrics").
  Use this to get the initial values of the various views.
  Default is ''OFF''.

sys.statement_truncate_len
  How much of queries in the process list output to include.
  Default is 64.

sys.debug
  Whether to provide debugging output.
  Default is ''OFF''. Set to ''ON'' to include.


Example
--------

To create a report and append it to the file diag.out:

mysql> TEE diag.out;
mysql> CALL sys.diagnostics(120, 30, ''current'');
...
mysql> NOTEE;
'
    SQL SECURITY INVOKER
    NOT DETERMINISTIC
    READS SQL DATA
BEGIN
    DECLARE v_start, v_runtime, v_iter_start, v_sleep DECIMAL(20,2) DEFAULT 0.0;
    DECLARE v_has_innodb, v_has_ndb, v_has_ps, v_has_replication, v_has_ps_replication VARCHAR(8) CHARSET utf8mb4 DEFAULT 'NO';
    DECLARE v_this_thread_enabled  ENUM('YES', 'NO');
    DECLARE v_table_name, v_banner VARCHAR(64) CHARSET utf8mb4;
    DECLARE v_sql_status_summary_select, v_sql_status_summary_delta, v_sql_status_summary_from, v_no_delta_names TEXT;
    DECLARE v_output_time, v_output_time_prev DECIMAL(20,3);
    DECLARE v_output_count, v_count, v_old_group_concat_max_len INT UNSIGNED DEFAULT 0;
    -- The width of each of the status outputs in the summery
    DECLARE v_status_summary_width TINYINT UNSIGNED DEFAULT 50;
    DECLARE v_done BOOLEAN DEFAULT FALSE;
    -- Do not include the following ndbinfo views:
    --    'blocks'                    Static
    --    'config_params'             Static
    --    'dict_obj_types'            Static
    --    'disk_write_speed_base'     Can generate lots of output - only include aggregate views here
    --    'memory_per_fragment'       Can generate lots of output
    --    'memoryusage'               Handled separately
    --    'operations_per_fragment'   Can generate lots of output
    --    'threadblocks'              Only needed once
    DECLARE c_ndbinfo CURSOR FOR
        SELECT TABLE_NAME
          FROM information_schema.TABLES
         WHERE TABLE_SCHEMA = 'ndbinfo'
               AND TABLE_NAME NOT IN (
                  'blocks',
                  'config_params',
                  'dict_obj_types',
                  'disk_write_speed_base',
                  'memory_per_fragment',
                  'memoryusage',
                  'operations_per_fragment',
                  'threadblocks'
               );
    DECLARE c_sysviews_w_delta CURSOR FOR
        SELECT table_name
          FROM tmp_sys_views_delta
         ORDER BY table_name;
    DECLARE CONTINUE HANDLER FOR NOT FOUND SET v_done = TRUE;

    -- Do not track the current thread - no reason to clutter the output
    SELECT INSTRUMENTED INTO v_this_thread_enabled FROM performance_schema.threads WHERE PROCESSLIST_ID = CONNECTION_ID();
    IF (v_this_thread_enabled = 'YES') THEN
        CALL sys.ps_setup_disable_thread(CONNECTION_ID());
    END IF;

    -- Check options are sane
    IF (in_max_runtime < in_interval) THEN
        SIGNAL SQLSTATE '45000'
           SET MESSAGE_TEXT = 'in_max_runtime must be greater than or equal to in_interval';
    END IF;
    IF (in_max_runtime = 0) THEN
        SIGNAL SQLSTATE '45000'
           SET MESSAGE_TEXT = 'in_max_runtime must be greater than 0';
    END IF;
    IF (in_interval = 0) THEN
        SIGNAL SQLSTATE '45000'
           SET MESSAGE_TEXT = 'in_interval must be greater than 0';
    END IF;

    -- Set configuration options
    IF (@sys.diagnostics.allow_i_s_tables IS NULL) THEN
        SET @sys.diagnostics.allow_i_s_tables = sys.sys_get_config('diagnostics.allow_i_s_tables', 'OFF');
    END IF;
    IF (@sys.diagnostics.include_raw IS NULL) THEN
        SET @sys.diagnostics.include_raw      = sys.sys_get_config('diagnostics.include_raw'     , 'OFF');
    END IF;
    IF (@sys.debug IS NULL) THEN
        SET @sys.debug                        = sys.sys_get_config('debug'                       , 'OFF');
    END IF;
    IF (@sys.statement_truncate_len IS NULL) THEN
        SET @sys.statement_truncate_len       = sys.sys_get_config('statement_truncate_len'      , '64' );
    END IF;

    -- Temporary table are used - disable sql_log_bin if necessary to prevent them replicating
    SET @log_bin := @@sql_log_bin;
    IF ((@log_bin = 1) AND (@@binlog_format = 'STATEMENT')) THEN
        SET sql_log_bin = 0;
    END IF;

    -- Some metrics variables doesn't make sense in delta and rate calculations even if they are numeric
    -- as they really are more like settings or "current" status.
    SET v_no_delta_names = CONCAT('s%{COUNT}.Variable_name NOT IN (',
        '''innodb_buffer_pool_pages_total'', ',
        '''innodb_page_size'', ',
        '''last_query_cost'', ',
        '''last_query_partial_plans'', ',
        '''qcache_total_blocks'', ',
        '''slave_last_heartbeat'', ',
        '''ssl_ctx_verify_depth'', ',
        '''ssl_ctx_verify_mode'', ',
        '''ssl_session_cache_size'', ',
        '''ssl_verify_depth'', ',
        '''ssl_verify_mode'', ',
        '''ssl_version'', ',
        '''buffer_flush_lsn_avg_rate'', ',
        '''buffer_flush_pct_for_dirty'', ',
        '''buffer_flush_pct_for_lsn'', ',
        '''buffer_pool_pages_total'', ',
        '''lock_row_lock_time_avg'', ',
        '''lock_row_lock_time_max'', ',
        '''innodb_page_size''',
    ')');

    IF (in_auto_config <> 'current') THEN
        IF (@sys.debug = 'ON') THEN
            SELECT CONCAT('Updating Performance Schema configuration to ', in_auto_config) AS 'Debug';
        END IF;
        CALL sys.ps_setup_save(0);

        IF (in_auto_config = 'medium') THEN
            -- Enable all consumers except %history and %history_long
            UPDATE performance_schema.setup_consumers
                SET ENABLED = 'YES'
            WHERE NAME NOT LIKE '%\_history%';

            -- Enable all instruments except wait/synch/%
            UPDATE performance_schema.setup_instruments
                SET ENABLED = 'YES',
                    TIMED   = 'YES'
            WHERE NAME NOT LIKE 'wait/synch/%';
        ELSEIF (in_auto_config = 'full') THEN
            UPDATE performance_schema.setup_consumers
                SET ENABLED = 'YES';

            UPDATE performance_schema.setup_instruments
                SET ENABLED = 'YES',
                    TIMED   = 'YES';
        END IF;

        -- Enable all threads except this one
        UPDATE performance_schema.threads
           SET INSTRUMENTED = 'YES'
         WHERE PROCESSLIST_ID <> CONNECTION_ID();
    END IF;

    SET v_start        = UNIX_TIMESTAMP(NOW(2)),
        in_interval    = IFNULL(in_interval, 30),
        in_max_runtime = IFNULL(in_max_runtime, 60);

    -- Get a quick ref with hostname, server UUID, and the time for the report.
    SET v_banner = REPEAT(
                      '-',
                      LEAST(
                         GREATEST(
                            36,
                            CHAR_LENGTH(VERSION()),
                            CHAR_LENGTH(@@global.version_comment),
                            CHAR_LENGTH(@@global.version_compile_os),
                            CHAR_LENGTH(@@global.version_compile_machine),
                            CHAR_LENGTH(@@global.socket),
                            CHAR_LENGTH(@@global.datadir)
                         ),
                         64
                      )
                   );
    SELECT 'Hostname' AS 'Name', @@global.hostname AS 'Value'
    UNION ALL
    SELECT 'Port' AS 'Name', @@global.port AS 'Value'
    UNION ALL
    SELECT 'Socket' AS 'Name', @@global.socket AS 'Value'
    UNION ALL
    SELECT 'Datadir' AS 'Name', @@global.datadir AS 'Value'
    UNION ALL
    SELECT 'Server UUID' AS 'Name', @@global.server_uuid AS 'Value'
    UNION ALL
    SELECT REPEAT('-', 23) AS 'Name', v_banner AS 'Value'
    UNION ALL
    SELECT 'MySQL Version' AS 'Name', VERSION() AS 'Value'
    UNION ALL
    SELECT 'Sys Schema Version' AS 'Name', (SELECT sys_version FROM sys.version) AS 'Value'
    UNION ALL
    SELECT 'Version Comment' AS 'Name', @@global.version_comment AS 'Value'
    UNION ALL
    SELECT 'Version Compile OS' AS 'Name', @@global.version_compile_os AS 'Value'
    UNION ALL
    SELECT 'Version Compile Machine' AS 'Name', @@global.version_compile_machine AS 'Value'
    UNION ALL
    SELECT REPEAT('-', 23) AS 'Name', v_banner AS 'Value'
    UNION ALL
    SELECT 'UTC Time' AS 'Name', UTC_TIMESTAMP() AS 'Value'
    UNION ALL
    SELECT 'Local Time' AS 'Name', NOW() AS 'Value'
    UNION ALL
    SELECT 'Time Zone' AS 'Name', @@global.time_zone AS 'Value'
    UNION ALL
    SELECT 'System Time Zone' AS 'Name', @@global.system_time_zone AS 'Value'
    UNION ALL
    SELECT 'Time Zone Offset' AS 'Name', TIMEDIFF(NOW(), UTC_TIMESTAMP()) AS 'Value';

    -- Are the InnoDB, NDBCluster, and Performance Schema storage engines present?
    SET v_has_innodb         = IFNULL((SELECT SUPPORT FROM information_schema.ENGINES WHERE ENGINE = 'InnoDB'), 'NO'),
        v_has_ndb            = IFNULL((SELECT SUPPORT FROM information_schema.ENGINES WHERE ENGINE = 'NDBCluster'), 'NO'),
        v_has_ps             = IFNULL((SELECT SUPPORT FROM information_schema.ENGINES WHERE ENGINE = 'PERFORMANCE_SCHEMA'), 'NO'),
        v_has_ps_replication = v_has_ps,
        v_has_replication    = IF(v_has_ps_replication = 'YES', IF((SELECT COUNT(*) FROM performance_schema.replication_connection_status) > 0, 'YES', 'NO'), 'MAYBE');

    IF (@sys.debug = 'ON') THEN
       SELECT v_has_innodb AS 'Has_InnoDB', v_has_ndb AS 'Has_NDBCluster',
              v_has_ps AS 'Has_Performance_Schema',
              v_has_ps_replication 'AS Has_P_S_Replication', v_has_replication AS 'Has_Replication';
    END IF;

    IF (v_has_innodb IN ('DEFAULT', 'YES')) THEN
        -- Need to use prepared statement as just having the query as a plain command
        -- will generate an error if the InnoDB storage engine is not present
        SET @sys.diagnostics.sql = 'SHOW ENGINE InnoDB STATUS';
        PREPARE stmt_innodb_status FROM @sys.diagnostics.sql;
    END IF;

    IF (v_has_ps = 'YES') THEN
        -- Need to use prepared statement as just having the query as a plain command
        -- will generate an error if the InnoDB storage engine is not present
        SET @sys.diagnostics.sql = 'SHOW ENGINE PERFORMANCE_SCHEMA STATUS';
        PREPARE stmt_ps_status FROM @sys.diagnostics.sql;
    END IF;

    IF (v_has_ndb IN ('DEFAULT', 'YES')) THEN
        -- Need to use prepared statement as just having the query as a plain command
        -- will generate an error if the NDBCluster storage engine is not present
        SET @sys.diagnostics.sql = 'SHOW ENGINE NDBCLUSTER STATUS';
        PREPARE stmt_ndbcluster_status FROM @sys.diagnostics.sql;
    END IF;

    SET @sys.diagnostics.sql_gen_query_template = 'SELECT CONCAT(
           ''SELECT '',
           GROUP_CONCAT(
               CASE WHEN (SUBSTRING(TABLE_NAME, 3), COLUMN_NAME) IN (
                                (''io_global_by_file_by_bytes'', ''total''),
                                (''io_global_by_wait_by_bytes'', ''total_requested'')
                         )
                         THEN CONCAT(''format_bytes('', COLUMN_NAME, '') AS '', COLUMN_NAME)
                    WHEN COLUMN_NAME LIKE ''%latency''
                         THEN CONCAT(''format_pico_time('', COLUMN_NAME, '') AS '', COLUMN_NAME)
                    WHEN SUBSTRING(COLUMN_NAME, -7) = ''_memory'' OR SUBSTRING(COLUMN_NAME, -17) = ''_memory_allocated''
                         OR ((SUBSTRING(COLUMN_NAME, -5) = ''_read'' OR SUBSTRING(COLUMN_NAME, -8) = ''_written'' OR SUBSTRING(COLUMN_NAME, -6) = ''_write'') AND SUBSTRING(COLUMN_NAME, 1, 6) <> ''COUNT_'')
                         THEN CONCAT(''format_bytes('', COLUMN_NAME, '') AS '', COLUMN_NAME)
                    ELSE COLUMN_NAME
               END
               ORDER BY ORDINAL_POSITION
               SEPARATOR '',\n       ''
           ),
           ''\n  FROM tmp_'', SUBSTRING(TABLE_NAME FROM 3), ''_%{OUTPUT}''
       ) AS Query INTO @sys.diagnostics.sql_select
  FROM information_schema.COLUMNS
 WHERE TABLE_SCHEMA = ''sys'' AND TABLE_NAME = ?
 GROUP BY TABLE_NAME';

    SET @sys.diagnostics.sql_gen_query_delta = 'SELECT CONCAT(
           ''SELECT '',
           GROUP_CONCAT(
               CASE WHEN FIND_IN_SET(COLUMN_NAME COLLATE utf8mb3_general_ci, diag.pk)
                         THEN COLUMN_NAME
                    WHEN diag.TABLE_NAME = ''io_global_by_file_by_bytes'' AND COLUMN_NAME COLLATE utf8mb3_general_ci = ''write_pct''
                         THEN CONCAT(''IFNULL(ROUND(100-(((e.total_read-IFNULL(s.total_read, 0))'',
                                     ''/NULLIF(((e.total_read-IFNULL(s.total_read, 0))+(e.total_written-IFNULL(s.total_written, 0))), 0))*100), 2), 0.00) AS '',
                                     COLUMN_NAME)
                    WHEN (diag.TABLE_NAME, COLUMN_NAME) IN (
                                (''io_global_by_file_by_bytes'', ''total''),
                                (''io_global_by_wait_by_bytes'', ''total_requested'')
                         )
                         THEN CONCAT(''format_bytes(e.'', COLUMN_NAME, ''-IFNULL(s.'', COLUMN_NAME, '', 0)) AS '', COLUMN_NAME)
                    WHEN SUBSTRING(COLUMN_NAME, 1, 4) IN (''max_'', ''min_'') AND SUBSTRING(COLUMN_NAME, -8) = ''_latency''
                         THEN CONCAT(''format_pico_time(e.'', COLUMN_NAME, '') AS '', COLUMN_NAME)
                    WHEN COLUMN_NAME COLLATE utf8mb3_general_ci = ''avg_latency''
                         THEN CONCAT(''format_pico_time((e.total_latency - IFNULL(s.total_latency, 0))'',
                                     ''/NULLIF(e.total - IFNULL(s.total, 0), 0)) AS '', COLUMN_NAME)
                    WHEN SUBSTRING(COLUMN_NAME, -12) = ''_avg_latency''
                         THEN CONCAT(''format_pico_time((e.'', SUBSTRING(COLUMN_NAME FROM 1 FOR CHAR_LENGTH(COLUMN_NAME)-12), ''_latency - IFNULL(s.'', SUBSTRING(COLUMN_NAME FROM 1 FOR CHAR_LENGTH(COLUMN_NAME)-12), ''_latency, 0))'',
                                     ''/NULLIF(e.'', SUBSTRING(COLUMN_NAME FROM 1 FOR CHAR_LENGTH(COLUMN_NAME)-12), ''s - IFNULL(s.'', SUBSTRING(COLUMN_NAME FROM 1 FOR CHAR_LENGTH(COLUMN_NAME)-12), ''s, 0), 0)) AS '', COLUMN_NAME)
                    WHEN COLUMN_NAME LIKE ''%latency''
                         THEN CONCAT(''format_pico_time(e.'', COLUMN_NAME, '' - IFNULL(s.'', COLUMN_NAME, '', 0)) AS '', COLUMN_NAME)
                    WHEN COLUMN_NAME IN (''avg_read'', ''avg_write'', ''avg_written'')
                         THEN CONCAT(''format_bytes(IFNULL((e.total_'', IF(COLUMN_NAME = ''avg_read'', ''read'', ''written''), ''-IFNULL(s.total_'', IF(COLUMN_NAME = ''avg_read'', ''read'', ''written''), '', 0))'',
                                     ''/NULLIF(e.count_'', IF(COLUMN_NAME = ''avg_read'', ''read'', ''write''), ''-IFNULL(s.count_'', IF(COLUMN_NAME = ''avg_read'', ''read'', ''write''), '', 0), 0), 0)) AS '',
                                     COLUMN_NAME)
                    WHEN SUBSTRING(COLUMN_NAME, -7) = ''_memory'' OR SUBSTRING(COLUMN_NAME, -17) = ''_memory_allocated''
                         OR ((SUBSTRING(COLUMN_NAME, -5) = ''_read'' OR SUBSTRING(COLUMN_NAME, -8) = ''_written'' OR SUBSTRING(COLUMN_NAME, -6) = ''_write'') AND SUBSTRING(COLUMN_NAME, 1, 6) <> ''COUNT_'')
                         THEN CONCAT(''format_bytes(e.'', COLUMN_NAME, '' - IFNULL(s.'', COLUMN_NAME, '', 0)) AS '', COLUMN_NAME)
                    ELSE CONCAT(''(e.'', COLUMN_NAME, '' - IFNULL(s.'', COLUMN_NAME, '', 0)) AS '', COLUMN_NAME)
               END
               ORDER BY ORDINAL_POSITION
               SEPARATOR '',\n       ''
           ),
           ''\n  FROM tmp_'', diag.TABLE_NAME, ''_end e
       LEFT OUTER JOIN tmp_'', diag.TABLE_NAME, ''_start s USING ('', diag.pk, '')''
       ) AS Query INTO @sys.diagnostics.sql_select
  FROM tmp_sys_views_delta diag
       INNER JOIN information_schema.COLUMNS c ON c.TABLE_NAME COLLATE utf8mb3_general_ci = CONCAT(''x$'', diag.TABLE_NAME)
 WHERE c.TABLE_SCHEMA = ''sys'' AND diag.TABLE_NAME = ?
 GROUP BY diag.TABLE_NAME';

    IF (v_has_ps = 'YES') THEN
        -- Create temporary table with the ORDER BY clauses. Will be required both for the initial (if included) and end queries
        DROP TEMPORARY TABLE IF EXISTS tmp_sys_views_delta;
        CREATE TEMPORARY TABLE tmp_sys_views_delta (
            TABLE_NAME varchar(64) NOT NULL,
            order_by text COMMENT 'ORDER BY clause for the initial and overall views',
            order_by_delta text COMMENT 'ORDER BY clause for the delta views',
            where_delta text COMMENT 'WHERE clause to use for delta views to only include rows with a "count" > 0',
            limit_rows int unsigned COMMENT 'The maximum number of rows to include for the view',
            pk varchar(128) COMMENT 'Used with the FIND_IN_SET() function so use comma separated list without whitespace',
            PRIMARY KEY (TABLE_NAME)
        );

        -- %{OUTPUT} will be replace by the suffix used for the output.
        IF (@sys.debug = 'ON') THEN
            SELECT 'Populating tmp_sys_views_delta' AS 'Debug';
        END IF;
        INSERT INTO tmp_sys_views_delta
        VALUES ('host_summary'                       , '%{TABLE}.statement_latency DESC',
                                                       '(e.statement_latency-IFNULL(s.statement_latency, 0)) DESC',
                                                       '(e.statements - IFNULL(s.statements, 0)) > 0', NULL, 'host'),
               ('host_summary_by_file_io'            , '%{TABLE}.io_latency DESC',
                                                       '(e.io_latency-IFNULL(s.io_latency, 0)) DESC',
                                                       '(e.ios - IFNULL(s.ios, 0)) > 0', NULL, 'host'),
               ('host_summary_by_file_io_type'       , '%{TABLE}.host, %{TABLE}.total_latency DESC',
                                                       'e.host, (e.total_latency-IFNULL(s.total_latency, 0)) DESC',
                                                       '(e.total - IFNULL(s.total, 0)) > 0', NULL, 'host,event_name'),
               ('host_summary_by_stages'             , '%{TABLE}.host, %{TABLE}.total_latency DESC',
                                                       'e.host, (e.total_latency-IFNULL(s.total_latency, 0)) DESC',
                                                       '(e.total - IFNULL(s.total, 0)) > 0', NULL, 'host,event_name'),
               ('host_summary_by_statement_latency'  , '%{TABLE}.total_latency DESC',
                                                       '(e.total_latency-IFNULL(s.total_latency, 0)) DESC',
                                                       '(e.total - IFNULL(s.total, 0)) > 0', NULL, 'host'),
               ('host_summary_by_statement_type'     , '%{TABLE}.host, %{TABLE}.total_latency DESC',
                                                       'e.host, (e.total_latency-IFNULL(s.total_latency, 0)) DESC',
                                                       '(e.total - IFNULL(s.total, 0)) > 0', NULL, 'host,statement'),
               ('io_by_thread_by_latency'            , '%{TABLE}.total_latency DESC',
                                                       '(e.total_latency-IFNULL(s.total_latency, 0)) DESC',
                                                       '(e.total - IFNULL(s.total, 0)) > 0', NULL, 'user,thread_id,processlist_id'),
               ('io_global_by_file_by_bytes'         , '%{TABLE}.total DESC',
                                                       '(e.total-IFNULL(s.total, 0)) DESC',
                                                       '(e.total - IFNULL(s.total, 0)) > 0', 100, 'file'),
               ('io_global_by_file_by_latency'       , '%{TABLE}.total_latency DESC',
                                                       '(e.total_latency-IFNULL(s.total_latency, 0)) DESC',
                                                       '(e.total - IFNULL(s.total, 0)) > 0', 100, 'file'),
               ('io_global_by_wait_by_bytes'         , '%{TABLE}.total_requested DESC',
                                                       '(e.total_requested-IFNULL(s.total_requested, 0)) DESC',
                                                       '(e.total - IFNULL(s.total, 0)) > 0', NULL, 'event_name'),
               ('io_global_by_wait_by_latency'       , '%{TABLE}.total_latency DESC',
                                                       '(e.total_latency-IFNULL(s.total_latency, 0)) DESC',
                                                       '(e.total - IFNULL(s.total, 0)) > 0', NULL, 'event_name'),
               ('schema_index_statistics'            , '(%{TABLE}.select_latency+%{TABLE}.insert_latency+%{TABLE}.update_latency+%{TABLE}.delete_latency) DESC',
                                                       '((e.select_latency+e.insert_latency+e.update_latency+e.delete_latency)-IFNULL(s.select_latency+s.insert_latency+s.update_latency+s.delete_latency, 0)) DESC',
                                                       '((e.rows_selected+e.insert_latency+e.rows_updated+e.rows_deleted)-IFNULL(s.rows_selected+s.rows_inserted+s.rows_updated+s.rows_deleted, 0)) > 0',
                                                       100, 'table_schema,table_name,index_name'),
               ('schema_table_statistics'            , '%{TABLE}.total_latency DESC',
                                                       '(e.total_latency-IFNULL(s.total_latency, 0)) DESC',
                                                       '(e.total_latency-IFNULL(s.total_latency, 0)) > 0', 100, 'table_schema,table_name'),
               ('schema_tables_with_full_table_scans', '%{TABLE}.rows_full_scanned DESC',
                                                       '(e.rows_full_scanned-IFNULL(s.rows_full_scanned, 0)) DESC',
                                                       '(e.rows_full_scanned-IFNULL(s.rows_full_scanned, 0)) > 0', 100, 'object_schema,object_name'),
               ('user_summary'                       , '%{TABLE}.statement_latency DESC',
                                                       '(e.statement_latency-IFNULL(s.statement_latency, 0)) DESC',
                                                       '(e.statements - IFNULL(s.statements, 0)) > 0', NULL, 'user'),
               ('user_summary_by_file_io'            , '%{TABLE}.io_latency DESC',
                                                       '(e.io_latency-IFNULL(s.io_latency, 0)) DESC',
                                                       '(e.ios - IFNULL(s.ios, 0)) > 0', NULL, 'user'),
               ('user_summary_by_file_io_type'       , '%{TABLE}.user, %{TABLE}.latency DESC',
                                                       'e.user, (e.latency-IFNULL(s.latency, 0)) DESC',
                                                       '(e.total - IFNULL(s.total, 0)) > 0', NULL, 'user,event_name'),
               ('user_summary_by_stages'             , '%{TABLE}.user, %{TABLE}.total_latency DESC',
                                                       'e.user, (e.total_latency-IFNULL(s.total_latency, 0)) DESC',
                                                       '(e.total - IFNULL(s.total, 0)) > 0', NULL, 'user,event_name'),
               ('user_summary_by_statement_latency'  , '%{TABLE}.total_latency DESC',
                                                       '(e.total_latency-IFNULL(s.total_latency, 0)) DESC',
                                                       '(e.total - IFNULL(s.total, 0)) > 0', NULL, 'user'),
               ('user_summary_by_statement_type'     , '%{TABLE}.user, %{TABLE}.total_latency DESC',
                                                       'e.user, (e.total_latency-IFNULL(s.total_latency, 0)) DESC',
                                                       '(e.total - IFNULL(s.total, 0)) > 0', NULL, 'user,statement'),
               ('wait_classes_global_by_avg_latency' , 'IFNULL(%{TABLE}.total_latency / NULLIF(%{TABLE}.total, 0), 0) DESC',
                                                       'IFNULL((e.total_latency-IFNULL(s.total_latency, 0)) / NULLIF((e.total - IFNULL(s.total, 0)), 0), 0) DESC',
                                                       '(e.total - IFNULL(s.total, 0)) > 0', NULL, 'event_class'),
               ('wait_classes_global_by_latency'     , '%{TABLE}.total_latency DESC',
                                                       '(e.total_latency-IFNULL(s.total_latency, 0)) DESC',
                                                       '(e.total - IFNULL(s.total, 0)) > 0', NULL, 'event_class'),
               ('waits_by_host_by_latency'           , '%{TABLE}.host, %{TABLE}.total_latency DESC',
                                                       'e.host, (e.total_latency-IFNULL(s.total_latency, 0)) DESC',
                                                       '(e.total - IFNULL(s.total, 0)) > 0', NULL, 'host,event'),
               ('waits_by_user_by_latency'           , '%{TABLE}.user, %{TABLE}.total_latency DESC',
                                                       'e.user, (e.total_latency-IFNULL(s.total_latency, 0)) DESC',
                                                       '(e.total - IFNULL(s.total, 0)) > 0', NULL, 'user,event'),
               ('waits_global_by_latency'            , '%{TABLE}.total_latency DESC',
                                                       '(e.total_latency-IFNULL(s.total_latency, 0)) DESC',
                                                       '(e.total - IFNULL(s.total, 0)) > 0', NULL, 'events')
        ;
    END IF;


    SELECT '

=======================

     Configuration

=======================

' AS '';
    -- Get the configuration.
    SELECT 'GLOBAL VARIABLES' AS 'The following output is:';
    SELECT LOWER(VARIABLE_NAME) AS Variable_name, VARIABLE_VALUE AS Variable_value FROM performance_schema.global_variables ORDER BY VARIABLE_NAME;

    IF (v_has_ps = 'YES') THEN
        -- Overview of the Performance Schema dynamic settings used for this report.
        SELECT 'Performance Schema Setup - Actors' AS 'The following output is:';
        SELECT * FROM performance_schema.setup_actors;

        SELECT 'Performance Schema Setup - Consumers' AS 'The following output is:';
        SELECT NAME AS Consumer, ENABLED, sys.ps_is_consumer_enabled(NAME) AS COLLECTS
          FROM performance_schema.setup_consumers;

        SELECT 'Performance Schema Setup - Instruments' AS 'The following output is:';
        SELECT SUBSTRING_INDEX(NAME, '/', 2) AS 'InstrumentClass',
               ROUND(100*SUM(IF(ENABLED = 'YES', 1, 0))/COUNT(*), 2) AS 'EnabledPct',
               ROUND(100*SUM(IF(TIMED = 'YES', 1, 0))/COUNT(*), 2) AS 'TimedPct'
          FROM performance_schema.setup_instruments
         GROUP BY SUBSTRING_INDEX(NAME, '/', 2)
         ORDER BY SUBSTRING_INDEX(NAME, '/', 2);

        SELECT 'Performance Schema Setup - Objects' AS 'The following output is:';
        SELECT * FROM performance_schema.setup_objects;

        SELECT 'Performance Schema Setup - Threads' AS 'The following output is:';
        SELECT `TYPE` AS ThreadType, COUNT(*) AS 'Total', ROUND(100*SUM(IF(INSTRUMENTED = 'YES', 1, 0))/COUNT(*), 2) AS 'InstrumentedPct'
          FROM performance_schema.threads
        GROUP BY TYPE;
    END IF;


    IF (v_has_replication = 'NO') THEN
        SELECT 'No Replication Configured' AS 'Replication Status';
    ELSE
        -- No guarantee that replication is actually configured, but we can't really know
        SELECT CONCAT('Replication Configured: ', v_has_replication, ' - Performance Schema Replication Tables: ', v_has_ps_replication) AS 'Replication Status';

        IF (v_has_ps_replication = 'YES') THEN
            SELECT 'Replication - Connection Configuration' AS 'The following output is:';
            SELECT * FROM performance_schema.replication_connection_configuration ORDER BY CHANNEL_NAME;
        END IF;

        IF (v_has_ps_replication = 'YES') THEN
            SELECT 'Replication - Applier Configuration' AS 'The following output is:';
            SELECT * FROM performance_schema.replication_applier_configuration ORDER BY CHANNEL_NAME;
        END IF;

        SELECT 'Replication - Connection metadata' AS 'The following output is:';
        -- Can't just do SELECT *  as the password may be present in plain text
        -- Don't include binary log file and position as that will be determined in each iteration as well
        SELECT Channel_name, Host, User_name, Port, Connect_retry,
                Enabled_ssl, Ssl_ca, Ssl_capath, Ssl_cert, Ssl_cipher, Ssl_key, Ssl_verify_server_cert,
                Heartbeat, Bind, Ignored_server_ids, Uuid, Retry_count, Ssl_crl, Ssl_crlpath,
                Tls_version, Enabled_auto_position
            FROM mysql.slave_master_info ORDER BY Channel_name;

        SELECT 'Replication - Applier metadata' AS 'The following output is:';
        SELECT Channel_name, Sql_delay, Number_of_workers, Id
            FROM mysql.slave_relay_log_info ORDER BY Channel_name;
    END IF;


    IF (v_has_ndb IN ('DEFAULT', 'YES')) THEN
       SELECT 'Cluster Thread Blocks' AS 'The following output is:';
       SELECT * FROM ndbinfo.threadblocks;
    END IF;

    -- For a number of sys views as well as events_statements_summary_by_digest,
    -- just get the start data and then at the end output the overall and delta values
    IF (v_has_ps = 'YES') THEN
        IF (@sys.diagnostics.include_raw = 'ON') THEN
            SELECT '

========================

     Initial Status

========================

' AS '';
        END IF;

        DROP TEMPORARY TABLE IF EXISTS tmp_digests_start;
        CALL sys.statement_performance_analyzer('create_tmp', 'tmp_digests_start', NULL);
        CALL sys.statement_performance_analyzer('snapshot', NULL, NULL);
        CALL sys.statement_performance_analyzer('save', 'tmp_digests_start', NULL);

        -- Loop over the sys views where deltas should be calculated.
        IF (@sys.diagnostics.include_raw = 'ON') THEN
            SET @sys.diagnostics.sql = REPLACE(@sys.diagnostics.sql_gen_query_template, '%{OUTPUT}', 'start');
            IF (@sys.debug = 'ON') THEN
                SELECT 'The following query will be used to generate the query for each sys view' AS 'Debug';
                SELECT @sys.diagnostics.sql AS 'Debug';
            END IF;
            PREPARE stmt_gen_query FROM @sys.diagnostics.sql;
        END IF;
        SET v_done = FALSE;
        OPEN c_sysviews_w_delta;
        c_sysviews_w_delta_loop: LOOP
            FETCH c_sysviews_w_delta INTO v_table_name;
            IF v_done THEN
                LEAVE c_sysviews_w_delta_loop;
            END IF;

            IF (@sys.debug = 'ON') THEN
                SELECT CONCAT('The following queries are for storing the initial content of ', v_table_name) AS 'Debug';
            END IF;

            CALL sys.execute_prepared_stmt(CONCAT('DROP TEMPORARY TABLE IF EXISTS `tmp_', v_table_name, '_start`'));
            CALL sys.execute_prepared_stmt(CONCAT('CREATE TEMPORARY TABLE `tmp_', v_table_name, '_start` SELECT * FROM `sys`.`x$', v_table_name, '`'));

            IF (@sys.diagnostics.include_raw = 'ON') THEN
                SET @sys.diagnostics.table_name = CONCAT('x$', v_table_name);
                EXECUTE stmt_gen_query USING @sys.diagnostics.table_name;
                -- If necessary add ORDER BY and LIMIT
                SELECT CONCAT(@sys.diagnostics.sql_select,
                              IF(order_by IS NOT NULL, CONCAT('\n ORDER BY ', REPLACE(order_by, '%{TABLE}', CONCAT('tmp_', v_table_name, '_start'))), ''),
                              IF(limit_rows IS NOT NULL, CONCAT('\n LIMIT ', limit_rows), '')
                       )
                  INTO @sys.diagnostics.sql_select
                  FROM tmp_sys_views_delta
                 WHERE TABLE_NAME COLLATE utf8mb4_0900_as_ci = v_table_name;
                SELECT CONCAT('Initial ', v_table_name) AS 'The following output is:';
                CALL sys.execute_prepared_stmt(@sys.diagnostics.sql_select);
            END IF;
        END LOOP;
        CLOSE c_sysviews_w_delta;

        IF (@sys.diagnostics.include_raw = 'ON') THEN
            DEALLOCATE PREPARE stmt_gen_query;
        END IF;
    END IF;

    -- If in_include_status_summary is TRUE then a temporary table is required to store the data
    SET v_sql_status_summary_select = 'SELECT Variable_name',
        v_sql_status_summary_delta  = '',
        v_sql_status_summary_from   = '';

    -- Start the loop
    REPEAT
        SET v_output_count = v_output_count + 1;
        IF (v_output_count > 1) THEN
            -- Don't sleep on the first execution
            SET v_sleep = in_interval-(UNIX_TIMESTAMP(NOW(2))-v_iter_start);
            SELECT NOW() AS 'Time', CONCAT('Going to sleep for ', v_sleep, ' seconds. Please do not interrupt') AS 'The following output is:';
            DO SLEEP(in_interval);
        END IF;
        SET v_iter_start = UNIX_TIMESTAMP(NOW(2));

        SELECT NOW(), CONCAT('Iteration Number ', IFNULL(v_output_count, 'NULL')) AS 'The following output is:';

        -- Even in 5.7 there is no way to get all the info from SHOW BINARY LOG|REPLICA STATUS using the Performance Schema or
        -- other tables, so include them even though they are no longer optimal solutions and if present get the additional
        -- information from the other tables available.
        IF (@@log_bin = 1) THEN
            SELECT 'SHOW BINARY LOG STATUS' AS 'The following output is:';
            SHOW BINARY LOG STATUS;
        END IF;

        IF (v_has_replication <> 'NO') THEN
            SELECT 'SHOW REPLICA STATUS' AS 'The following output is:';
            SHOW REPLICA STATUS;

            IF (v_has_ps_replication = 'YES') THEN
                SELECT 'Replication Connection Status' AS 'The following output is:';
                SELECT * FROM performance_schema.replication_connection_status;

                SELECT 'Replication Applier Status' AS 'The following output is:';
                SELECT * FROM performance_schema.replication_applier_status ORDER BY CHANNEL_NAME;

                SELECT 'Replication Applier Status - Coordinator' AS 'The following output is:';
                SELECT * FROM performance_schema.replication_applier_status_by_coordinator ORDER BY CHANNEL_NAME;

                SELECT 'Replication Applier Status - Worker' AS 'The following output is:';
                SELECT * FROM performance_schema.replication_applier_status_by_worker ORDER BY CHANNEL_NAME, WORKER_ID;
            END IF;

            SELECT 'Replication - Master Log Status' AS 'The following output is:';
            SELECT Master_log_name, Master_log_pos FROM mysql.slave_master_info;

            SELECT 'Replication - Relay Log Status' AS 'The following output is:';
            SELECT sys.format_path(Relay_log_name) AS Relay_log_name, Relay_log_pos, Master_log_name, Master_log_pos FROM mysql.slave_relay_log_info;

            SELECT 'Replication - Worker Status' AS 'The following output is:';
            SELECT Id, sys.format_path(Relay_log_name) AS Relay_log_name, Relay_log_pos, Master_log_name, Master_log_pos,
                    sys.format_path(Checkpoint_relay_log_name) AS Checkpoint_relay_log_name, Checkpoint_relay_log_pos,
                    Checkpoint_master_log_name, Checkpoint_master_log_pos, Checkpoint_seqno, Checkpoint_group_size,
                    HEX(Checkpoint_group_bitmap) AS Checkpoint_group_bitmap, Channel_name
                FROM mysql.slave_worker_info ORDER BY Channel_name, Id;
        END IF;

        -- We need one table per output as a temporary table cannot be opened twice in the same query, and we need to
        -- join the outputs in the summary at the end.
        SET v_table_name = CONCAT('tmp_metrics_', v_output_count);
        CALL sys.execute_prepared_stmt(CONCAT('DROP TEMPORARY TABLE IF EXISTS ', v_table_name));

        -- Currently information_schema.GLOBAL_STATUS has VARIABLE_VALUE as varchar(1024)
        CALL sys.execute_prepared_stmt(CONCAT('CREATE TEMPORARY TABLE ', v_table_name, ' (
  Variable_name VARCHAR(193) NOT NULL,
  Variable_value VARCHAR(1024),
  Type VARCHAR(225) NOT NULL,
  Enabled ENUM(''YES'', ''NO'', ''PARTIAL'') NOT NULL,
  PRIMARY KEY (Type, Variable_name)
) ENGINE = InnoDB DEFAULT CHARSET=utf8mb4'));

        SET @sys.diagnostics.sql = CONCAT(
            'INSERT INTO ', v_table_name,
            ' SELECT Variable_name, REPLACE(Variable_value, ''\n'', ''\\\\n'') AS Variable_value, Type, Enabled FROM sys.metrics'
        );
        CALL sys.execute_prepared_stmt(@sys.diagnostics.sql);

        -- Prepare the query to retrieve the summary
        CALL sys.execute_prepared_stmt(
            CONCAT('(SELECT Variable_value INTO @sys.diagnostics.output_time FROM ', v_table_name, ' WHERE Type = ''System Time'' AND Variable_name = ''UNIX_TIMESTAMP()'')')
        );
        SET v_output_time = @sys.diagnostics.output_time;

        -- Limit each value to v_status_summary_width chars (when v_has_ndb = TRUE the values can be very wide - refer to the output here for the full values)
        -- v_sql_status_summary_select, v_sql_status_summary_delta, v_sql_status_summary_from
        SET v_sql_status_summary_select = CONCAT(v_sql_status_summary_select, ',
       CONCAT(
           LEFT(s', v_output_count, '.Variable_value, ', v_status_summary_width, '),
           IF(', REPLACE(v_no_delta_names, '%{COUNT}', v_output_count), ' AND s', v_output_count, '.Variable_value REGEXP ''^[0-9]+(\\\\.[0-9]+)?$'', CONCAT('' ('', ROUND(s', v_output_count, '.Variable_value/', v_output_time, ', 2), ''/sec)''), '''')
       ) AS ''Output ', v_output_count, ''''),
            v_sql_status_summary_from   = CONCAT(v_sql_status_summary_from, '
',
                                                    IF(v_output_count = 1, '  FROM ', '       INNER JOIN '),
                                                    v_table_name, ' s', v_output_count,
                                                    IF (v_output_count = 1, '', ' USING (Type, Variable_name)'));
        IF (v_output_count > 1) THEN
            SET v_sql_status_summary_delta  = CONCAT(v_sql_status_summary_delta, ',
       IF(', REPLACE(v_no_delta_names, '%{COUNT}', v_output_count), ' AND s', (v_output_count-1), '.Variable_value REGEXP ''^[0-9]+(\\\\.[0-9]+)?$'' AND s', v_output_count, '.Variable_value REGEXP ''^[0-9]+(\\\\.[0-9]+)?$'',
          CONCAT(IF(s', (v_output_count-1), '.Variable_value REGEXP ''^[0-9]+\\\\.[0-9]+$'' OR s', v_output_count, '.Variable_value REGEXP ''^[0-9]+\\\\.[0-9]+$'',
                    ROUND((s', v_output_count, '.Variable_value-s', (v_output_count-1), '.Variable_value), 2),
                    (s', v_output_count, '.Variable_value-s', (v_output_count-1), '.Variable_value)
                   ),
                 '' ('', ROUND((s', v_output_count, '.Variable_value-s', (v_output_count-1), '.Variable_value)/(', v_output_time, '-', v_output_time_prev, '), 2), ''/sec)''
          ),
          ''''
       ) AS ''Delta (', (v_output_count-1), ' -> ', v_output_count, ')''');
        END IF;

        SET v_output_time_prev = v_output_time;

        IF (@sys.diagnostics.include_raw = 'ON') THEN
            SELECT 'SELECT * FROM sys.metrics' AS 'The following output is:';
            -- Ensures that the output here is the same as the one used in the status summary at the end
            CALL sys.execute_prepared_stmt(CONCAT('SELECT Type, Variable_name, Enabled, Variable_value FROM ', v_table_name, ' ORDER BY Type, Variable_name'));
        END IF;

        -- InnoDB
        IF (v_has_innodb IN ('DEFAULT', 'YES')) THEN
            SELECT 'SHOW ENGINE INNODB STATUS' AS 'The following output is:';
            EXECUTE stmt_innodb_status;
            SELECT 'InnoDB - Transactions' AS 'The following output is:';
            SELECT * FROM information_schema.INNODB_TRX;
        END IF;

        -- NDBCluster
        IF (v_has_ndb IN ('DEFAULT', 'YES')) THEN
            SELECT 'SHOW ENGINE NDBCLUSTER STATUS' AS 'The following output is:';
            EXECUTE stmt_ndbcluster_status;

            SELECT 'ndbinfo.memoryusage' AS 'The following output is:';
            SELECT node_id, memory_type, format_bytes(used) AS used, used_pages, format_bytes(total) AS total, total_pages,
                   ROUND(100*(used/total), 2) AS 'Used %'
            FROM ndbinfo.memoryusage;

            -- Loop over the ndbinfo tables (except memoryusage which was handled separately above).
            -- The exact tables available are version dependent, so get the list from the Information Schema.
            SET v_done = FALSE;
            OPEN c_ndbinfo;
            c_ndbinfo_loop: LOOP
                FETCH c_ndbinfo INTO v_table_name;
                IF v_done THEN
                LEAVE c_ndbinfo_loop;
                END IF;

                SELECT CONCAT('SELECT * FROM ndbinfo.', v_table_name) AS 'The following output is:';
                CALL sys.execute_prepared_stmt(CONCAT('SELECT * FROM `ndbinfo`.`', v_table_name, '`'));
            END LOOP;
            CLOSE c_ndbinfo;

            SELECT * FROM information_schema.FILES;
        END IF;

        SELECT 'SELECT * FROM sys.processlist' AS 'The following output is:';
        SELECT processlist.* FROM sys.processlist;

        IF (v_has_ps = 'YES') THEN
            -- latest_file_io
            IF (sys.ps_is_consumer_enabled('events_waits_history_long') = 'YES') THEN
                SELECT 'SELECT * FROM sys.latest_file_io' AS 'The following output is:';
                SELECT * FROM sys.latest_file_io;
            END IF;

            -- current memory usage
            IF (EXISTS(SELECT 1 FROM performance_schema.setup_instruments WHERE NAME LIKE 'memory/%' AND ENABLED = 'YES')) THEN
                SELECT 'SELECT * FROM sys.memory_by_host_by_current_bytes' AS 'The following output is:';
                SELECT * FROM sys.memory_by_host_by_current_bytes;

                SELECT 'SELECT * FROM sys.memory_by_thread_by_current_bytes' AS 'The following output is:';
                SELECT * FROM sys.memory_by_thread_by_current_bytes;

                SELECT 'SELECT * FROM sys.memory_by_user_by_current_bytes' AS 'The following output is:';
                SELECT * FROM sys.memory_by_user_by_current_bytes;

                SELECT 'SELECT * FROM sys.memory_global_by_current_bytes' AS 'The following output is:';
                SELECT * FROM sys.memory_global_by_current_bytes;
            END IF;
        END IF;

        SET v_runtime = (UNIX_TIMESTAMP(NOW(2)) - v_start);
    UNTIL (v_runtime + in_interval >= in_max_runtime) END REPEAT;

    -- Get Performance Schema status
    IF (v_has_ps = 'YES') THEN
        SELECT 'SHOW ENGINE PERFORMANCE_SCHEMA STATUS' AS 'The following output is:';
        EXECUTE stmt_ps_status;
    END IF;

    -- Deallocate prepared statements
    IF (v_has_innodb IN ('DEFAULT', 'YES')) THEN
        DEALLOCATE PREPARE stmt_innodb_status;
    END IF;
    IF (v_has_ps = 'YES') THEN
        DEALLOCATE PREPARE stmt_ps_status;
    END IF;
    IF (v_has_ndb IN ('DEFAULT', 'YES')) THEN
        DEALLOCATE PREPARE stmt_ndbcluster_status;
    END IF;


    SELECT '

============================

     Schema Information

============================

' AS '';

    SELECT COUNT(*) AS 'Total Number of Tables' FROM information_schema.TABLES;

    -- The cost of information_schema.TABLES.DATA_LENGTH depends mostly on the number of tables
    IF (@sys.diagnostics.allow_i_s_tables = 'ON') THEN
        SELECT 'Storage Engine Usage' AS 'The following output is:';
        SELECT ENGINE, COUNT(*) AS NUM_TABLES,
                format_bytes(SUM(DATA_LENGTH)) AS DATA_LENGTH,
                format_bytes(SUM(INDEX_LENGTH)) AS INDEX_LENGTH,
                format_bytes(SUM(DATA_LENGTH+INDEX_LENGTH)) AS TOTAL
            FROM information_schema.TABLES
            GROUP BY ENGINE;

        SELECT 'Schema Object Overview' AS 'The following output is:';
        SELECT * FROM sys.schema_object_overview;

        SELECT 'Tables without a PRIMARY KEY' AS 'The following output is:';
        SELECT TABLES.TABLE_SCHEMA, ENGINE, COUNT(*) AS NumTables
          FROM information_schema.TABLES
               LEFT OUTER JOIN information_schema.STATISTICS ON STATISTICS.TABLE_SCHEMA = TABLES.TABLE_SCHEMA
                                                                AND STATISTICS.TABLE_NAME = TABLES.TABLE_NAME
                                                                AND STATISTICS.INDEX_NAME = 'PRIMARY'
         WHERE STATISTICS.TABLE_NAME IS NULL
               AND TABLES.TABLE_SCHEMA NOT IN ('mysql', 'information_schema', 'performance_schema', 'sys')
               AND TABLES.TABLE_TYPE = 'BASE TABLE'
         GROUP BY TABLES.TABLE_SCHEMA, ENGINE;
    END IF;

    IF (v_has_ps = 'YES') THEN
        SELECT 'Unused Indexes' AS 'The following output is:';
        SELECT object_schema, COUNT(*) AS NumUnusedIndexes
          FROM performance_schema.table_io_waits_summary_by_index_usage
         WHERE index_name IS NOT NULL
               AND count_star = 0
               AND object_schema NOT IN ('mysql', 'sys')
               AND index_name != 'PRIMARY'
         GROUP BY object_schema;
    END IF;

    IF (v_has_ps = 'YES') THEN
        SELECT '

=========================

     Overall Status

=========================

' AS '';

        SELECT 'CALL sys.ps_statement_avg_latency_histogram()' AS 'The following output is:';
        CALL sys.ps_statement_avg_latency_histogram();

        CALL sys.statement_performance_analyzer('snapshot', NULL, NULL);
        CALL sys.statement_performance_analyzer('overall', NULL, 'with_runtimes_in_95th_percentile');

        SET @sys.diagnostics.sql = REPLACE(@sys.diagnostics.sql_gen_query_template, '%{OUTPUT}', 'end');
        IF (@sys.debug = 'ON') THEN
            SELECT 'The following query will be used to generate the query for each sys view' AS 'Debug';
            SELECT @sys.diagnostics.sql AS 'Debug';
        END IF;
        PREPARE stmt_gen_query FROM @sys.diagnostics.sql;

        SET v_done = FALSE;
        OPEN c_sysviews_w_delta;
        c_sysviews_w_delta_loop: LOOP
            FETCH c_sysviews_w_delta INTO v_table_name;
            IF v_done THEN
                LEAVE c_sysviews_w_delta_loop;
            END IF;

            IF (@sys.debug = 'ON') THEN
                SELECT CONCAT('The following queries are for storing the final content of ', v_table_name) AS 'Debug';
            END IF;

            CALL sys.execute_prepared_stmt(CONCAT('DROP TEMPORARY TABLE IF EXISTS `tmp_', v_table_name, '_end`'));
            CALL sys.execute_prepared_stmt(CONCAT('CREATE TEMPORARY TABLE `tmp_', v_table_name, '_end` SELECT * FROM `sys`.`x$', v_table_name, '`'));

            SET @sys.diagnostics.table_name = CONCAT('x$', v_table_name);
            EXECUTE stmt_gen_query USING @sys.diagnostics.table_name;
            -- If necessary add ORDER BY and LIMIT
            SELECT CONCAT(@sys.diagnostics.sql_select,
                            IF(order_by IS NOT NULL, CONCAT('\n ORDER BY ', REPLACE(order_by, '%{TABLE}', CONCAT('tmp_', v_table_name, '_end'))), ''),
                            IF(limit_rows IS NOT NULL, CONCAT('\n LIMIT ', limit_rows), '')
                    )
                INTO @sys.diagnostics.sql_select
                FROM tmp_sys_views_delta
                WHERE TABLE_NAME COLLATE utf8mb4_0900_as_ci = v_table_name;
            SELECT CONCAT('Overall ', v_table_name) AS 'The following output is:';
            CALL sys.execute_prepared_stmt(@sys.diagnostics.sql_select);
        END LOOP;
        CLOSE c_sysviews_w_delta;

        DEALLOCATE PREPARE stmt_gen_query;


        SELECT '

======================

     Delta Status

======================

' AS '';

        CALL sys.statement_performance_analyzer('delta', 'tmp_digests_start', 'with_runtimes_in_95th_percentile');
        CALL sys.statement_performance_analyzer('cleanup', NULL, NULL);

        DROP TEMPORARY TABLE tmp_digests_start;

        -- @sys.diagnostics.sql_gen_query_delta is defined near the to together with @sys.diagnostics.sql_gen_query_template
        IF (@sys.debug = 'ON') THEN
            SELECT 'The following query will be used to generate the query for each sys view delta' AS 'Debug';
            SELECT @sys.diagnostics.sql_gen_query_delta AS 'Debug';
        END IF;
        PREPARE stmt_gen_query_delta FROM @sys.diagnostics.sql_gen_query_delta;

        SET v_old_group_concat_max_len = @@session.group_concat_max_len;
        SET @@session.group_concat_max_len = 2048;
        SET v_done = FALSE;
        OPEN c_sysviews_w_delta;
        c_sysviews_w_delta_loop: LOOP
            FETCH c_sysviews_w_delta INTO v_table_name;
            IF v_done THEN
                LEAVE c_sysviews_w_delta_loop;
            END IF;

            SET @sys.diagnostics.table_name = v_table_name;
            EXECUTE stmt_gen_query_delta USING @sys.diagnostics.table_name;
            -- If necessary add WHERE, ORDER BY, and LIMIT
            SELECT CONCAT(@sys.diagnostics.sql_select,
                            IF(where_delta IS NOT NULL, CONCAT('\n WHERE ', where_delta), ''),
                            IF(order_by_delta IS NOT NULL, CONCAT('\n ORDER BY ', order_by_delta), ''),
                            IF(limit_rows IS NOT NULL, CONCAT('\n LIMIT ', limit_rows), '')
                    )
                INTO @sys.diagnostics.sql_select
                FROM tmp_sys_views_delta
                WHERE TABLE_NAME COLLATE utf8mb4_0900_as_ci = v_table_name;

            SELECT CONCAT('Delta ', v_table_name) AS 'The following output is:';
            CALL sys.execute_prepared_stmt(@sys.diagnostics.sql_select);

            CALL sys.execute_prepared_stmt(CONCAT('DROP TEMPORARY TABLE `tmp_', v_table_name, '_end`'));
            CALL sys.execute_prepared_stmt(CONCAT('DROP TEMPORARY TABLE `tmp_', v_table_name, '_start`'));
        END LOOP;
        CLOSE c_sysviews_w_delta;
        SET @@session.group_concat_max_len = v_old_group_concat_max_len;

        DEALLOCATE PREPARE stmt_gen_query_delta;
        DROP TEMPORARY TABLE tmp_sys_views_delta;
    END IF;

    SELECT 'SELECT * FROM sys.metrics' AS 'The following output is:';
    CALL sys.execute_prepared_stmt(
        CONCAT(v_sql_status_summary_select, v_sql_status_summary_delta, ', Type, s1.Enabled', v_sql_status_summary_from,
               '
 ORDER BY Type, Variable_name'
        )
    );

    -- Remove all the metrics temporary tables again
    SET v_count = 0;
    WHILE (v_count < v_output_count) DO
        SET v_count = v_count + 1;
        SET v_table_name = CONCAT('tmp_metrics_', v_count);
        CALL sys.execute_prepared_stmt(CONCAT('DROP TEMPORARY TABLE IF EXISTS ', v_table_name));
    END WHILE;

    IF (in_auto_config <> 'current') THEN
        CALL sys.ps_setup_reload_saved();
        IF ((@log_bin = 1) AND (@@binlog_format = 'STATEMENT')) THEN
            SET sql_log_bin = @log_bin;
        END IF;
    END IF;

    -- Reset the @sys.diagnostics.% user variables internal to this procedure
    SET @sys.diagnostics.output_time            = NULL,
        @sys.diagnostics.sql                    = NULL,
        @sys.diagnostics.sql_gen_query_delta    = NULL,
        @sys.diagnostics.sql_gen_query_template = NULL,
        @sys.diagnostics.sql_select             = NULL,
        @sys.diagnostics.table_name             = NULL;

    -- Restore INSTRUMENTED for this thread
    IF (v_this_thread_enabled = 'YES') THEN
        CALL sys.ps_setup_enable_thread(CONNECTION_ID());
    END IF;

    IF ((@log_bin = 1) AND (@@binlog_format = 'STATEMENT')) THEN
        SET sql_log_bin = @log_bin;
    END IF;
END$$

DELIMITER ;
-- Copyright (c) 2014, 2024, Oracle and/or its affiliates.
--
-- This program is free software; you can redistribute it and/or modify
-- it under the terms of the GNU General Public License as published by
-- the Free Software Foundation; version 2 of the License.
--
-- This program is distributed in the hope that it will be useful,
-- but WITHOUT ANY WARRANTY; without even the implied warranty of
-- MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
-- GNU General Public License for more details.
--
-- You should have received a copy of the GNU General Public License
-- along with this program; if not, write to the Free Software
-- Foundation, Inc., 51 Franklin St, Fifth Floor, Boston, MA 02110-1301 USA

DROP PROCEDURE IF EXISTS ps_statement_avg_latency_histogram;

DELIMITER $$

CREATE DEFINER='mysql.sys'@'localhost' PROCEDURE ps_statement_avg_latency_histogram ()
    COMMENT '
Description
-----------

Outputs a textual histogram graph of the average latency values
across all normalized queries tracked within the Performance Schema
events_statements_summary_by_digest table.

Can be used to show a very high level picture of what kind of 
latency distribution statements running within this instance have.

Parameters
-----------

None.

Example
-----------

mysql> CALL sys.ps_statement_avg_latency_histogram()\\G
*************************** 1. row ***************************
Performance Schema Statement Digest Average Latency Histogram:

  . = 1 unit
  * = 2 units
  # = 3 units

(0 - 38ms)     240 | ################################################################################
(38 - 77ms)    38  | ......................................
(77 - 115ms)   3   | ...
(115 - 154ms)  62  | *******************************
(154 - 192ms)  3   | ...
(192 - 231ms)  0   |
(231 - 269ms)  0   |
(269 - 307ms)  0   |
(307 - 346ms)  0   |
(346 - 384ms)  1   | .
(384 - 423ms)  1   | .
(423 - 461ms)  0   |
(461 - 499ms)  0   |
(499 - 538ms)  0   |
(538 - 576ms)  0   |
(576 - 615ms)  1   | .

  Total Statements: 350; Buckets: 16; Bucket Size: 38 ms;
'
    SQL SECURITY INVOKER
    NOT DETERMINISTIC
    READS SQL DATA
BEGIN
SELECT CONCAT('\n',
       '\n  . = 1 unit',
       '\n  * = 2 units',
       '\n  # = 3 units\n',
       @label := CONCAT(@label_inner := CONCAT('\n(0 - ',
                                               ROUND((@bucket_size := (SELECT ROUND((MAX(avg_us) - MIN(avg_us)) / (@buckets := 16)) AS size
                                                                         FROM sys.x$ps_digest_avg_latency_distribution)) / (@unit_div := 1000)),
                                                (@unit := 'ms'), ')'),
                        REPEAT(' ', (@max_label_size := ((1 + LENGTH(ROUND((@bucket_size * 15) / @unit_div)) + 3 + LENGTH(ROUND(@bucket_size * 16) / @unit_div)) + 1)) - LENGTH(@label_inner)),
                        @count_in_bucket := IFNULL((SELECT SUM(cnt)
                                                      FROM sys.x$ps_digest_avg_latency_distribution AS b1 
                                                     WHERE b1.avg_us <= @bucket_size), 0)),
       REPEAT(' ', (@max_label_len := (@max_label_size + LENGTH((@total_queries := (SELECT SUM(cnt) FROM sys.x$ps_digest_avg_latency_distribution)))) + 1) - LENGTH(@label)), '| ',
       IFNULL(REPEAT(IF(@count_in_bucket < (@one_unit := 40), '.', IF(@count_in_bucket < (@two_unit := 80), '*', '#')), 
       	             IF(@count_in_bucket < @one_unit, @count_in_bucket,
       	             	IF(@count_in_bucket < @two_unit, @count_in_bucket / 2, @count_in_bucket / 3))), ''),

       @label := CONCAT(@label_inner := CONCAT('\n(', ROUND(@bucket_size / @unit_div), ' - ', ROUND((@bucket_size * 2) / @unit_div), @unit, ')'),
                        REPEAT(' ', @max_label_size - LENGTH(@label_inner)),
                        @count_in_bucket := IFNULL((SELECT SUM(cnt)
                                                      FROM sys.x$ps_digest_avg_latency_distribution AS b1 
                                                     WHERE b1.avg_us > @bucket_size AND b1.avg_us <= @bucket_size * 2), 0)),
       REPEAT(' ', @max_label_len - LENGTH(@label)), '| ',
       IFNULL(REPEAT(IF(@count_in_bucket < @one_unit, '.', IF(@count_in_bucket < @two_unit, '*', '#')), 
       	             IF(@count_in_bucket < @one_unit, @count_in_bucket,
       	             	IF(@count_in_bucket < @two_unit, @count_in_bucket / 2, @count_in_bucket / 3))), ''),
       @label := CONCAT(@label_inner := CONCAT('\n(', ROUND((@bucket_size * 2) / @unit_div), ' - ', ROUND((@bucket_size * 3) / @unit_div), @unit, ')'),
                        REPEAT(' ', @max_label_size - LENGTH(@label_inner)),
                        @count_in_bucket := IFNULL((SELECT SUM(cnt)
                                                      FROM sys.x$ps_digest_avg_latency_distribution AS b1 
                                                     WHERE b1.avg_us > @bucket_size * 2 AND b1.avg_us <= @bucket_size * 3), 0)),
       REPEAT(' ', @max_label_len - LENGTH(@label)), '| ',
       IFNULL(REPEAT(IF(@count_in_bucket < @one_unit, '.', IF(@count_in_bucket < @two_unit, '*', '#')), 
       	             IF(@count_in_bucket < @one_unit, @count_in_bucket,
       	             	IF(@count_in_bucket < @two_unit, @count_in_bucket / 2, @count_in_bucket / 3))), ''),
       @label := CONCAT(@label_inner := CONCAT('\n(', ROUND((@bucket_size * 3) / @unit_div), ' - ', ROUND((@bucket_size * 4) / @unit_div), @unit, ')'),
                        REPEAT(' ', @max_label_size - LENGTH(@label_inner)),
                        @count_in_bucket := IFNULL((SELECT SUM(cnt)
                                                      FROM sys.x$ps_digest_avg_latency_distribution AS b1 
                                                     WHERE b1.avg_us > @bucket_size * 3 AND b1.avg_us <= @bucket_size * 4), 0)),
       REPEAT(' ', @max_label_len - LENGTH(@label)), '| ',
       IFNULL(REPEAT(IF(@count_in_bucket < @one_unit, '.', IF(@count_in_bucket < @two_unit, '*', '#')), 
       	             IF(@count_in_bucket < @one_unit, @count_in_bucket,
       	             	IF(@count_in_bucket < @two_unit, @count_in_bucket / 2, @count_in_bucket / 3))), ''),
       @label := CONCAT(@label_inner := CONCAT('\n(', ROUND((@bucket_size * 4) / @unit_div), ' - ', ROUND((@bucket_size * 5) / @unit_div), @unit, ')'),
                        REPEAT(' ', @max_label_size - LENGTH(@label_inner)),
                        @count_in_bucket := IFNULL((SELECT SUM(cnt)
                                                      FROM sys.x$ps_digest_avg_latency_distribution AS b1 
                                                     WHERE b1.avg_us > @bucket_size * 4 AND b1.avg_us <= @bucket_size * 5), 0)),
       REPEAT(' ', @max_label_len - LENGTH(@label)), '| ',
       IFNULL(REPEAT(IF(@count_in_bucket < @one_unit, '.', IF(@count_in_bucket < @two_unit, '*', '#')), 
       	             IF(@count_in_bucket < @one_unit, @count_in_bucket,
       	             	IF(@count_in_bucket < @two_unit, @count_in_bucket / 2, @count_in_bucket / 3))), ''),
       @label := CONCAT(@label_inner := CONCAT('\n(', ROUND((@bucket_size * 5) / @unit_div), ' - ', ROUND((@bucket_size * 6) / @unit_div), @unit, ')'),
                        REPEAT(' ', @max_label_size - LENGTH(@label_inner)),
                        @count_in_bucket := IFNULL((SELECT SUM(cnt)
                                                      FROM sys.x$ps_digest_avg_latency_distribution AS b1 
                                                     WHERE b1.avg_us > @bucket_size * 5 AND b1.avg_us <= @bucket_size * 6), 0)),
       REPEAT(' ', @max_label_len - LENGTH(@label)), '| ',
       IFNULL(REPEAT(IF(@count_in_bucket < @one_unit, '.', IF(@count_in_bucket < @two_unit, '*', '#')), 
       	             IF(@count_in_bucket < @one_unit, @count_in_bucket,
       	             	IF(@count_in_bucket < @two_unit, @count_in_bucket / 2, @count_in_bucket / 3))), ''),
       @label := CONCAT(@label_inner := CONCAT('\n(', ROUND((@bucket_size * 6) / @unit_div), ' - ', ROUND((@bucket_size * 7) / @unit_div), @unit, ')'),
                        REPEAT(' ', @max_label_size - LENGTH(@label_inner)),
                        @count_in_bucket := IFNULL((SELECT SUM(cnt)
                                                      FROM sys.x$ps_digest_avg_latency_distribution AS b1 
                                                     WHERE b1.avg_us > @bucket_size * 6 AND b1.avg_us <= @bucket_size * 7), 0)),
       REPEAT(' ', @max_label_len - LENGTH(@label)), '| ',
       IFNULL(REPEAT(IF(@count_in_bucket < @one_unit, '.', IF(@count_in_bucket < @two_unit, '*', '#')), 
       	             IF(@count_in_bucket < @one_unit, @count_in_bucket,
       	             	IF(@count_in_bucket < @two_unit, @count_in_bucket / 2, @count_in_bucket / 3))), ''),
       @label := CONCAT(@label_inner := CONCAT('\n(', ROUND((@bucket_size * 7) / @unit_div), ' - ', ROUND((@bucket_size * 8) / @unit_div), @unit, ')'),
                        REPEAT(' ', @max_label_size - LENGTH(@label_inner)),
                        @count_in_bucket := IFNULL((SELECT SUM(cnt)
                                                      FROM sys.x$ps_digest_avg_latency_distribution AS b1 
                                                     WHERE b1.avg_us > @bucket_size * 7 AND b1.avg_us <= @bucket_size * 8), 0)),
       REPEAT(' ', @max_label_len - LENGTH(@label)), '| ',
       IFNULL(REPEAT(IF(@count_in_bucket < @one_unit, '.', IF(@count_in_bucket < @two_unit, '*', '#')), 
       	             IF(@count_in_bucket < @one_unit, @count_in_bucket,
       	             	IF(@count_in_bucket < @two_unit, @count_in_bucket / 2, @count_in_bucket / 3))), ''),
       @label := CONCAT(@label_inner := CONCAT('\n(', ROUND((@bucket_size * 8) / @unit_div), ' - ', ROUND((@bucket_size * 9) / @unit_div), @unit, ')'),
                        REPEAT(' ', @max_label_size - LENGTH(@label_inner)),
                        @count_in_bucket := IFNULL((SELECT SUM(cnt)
                                                      FROM sys.x$ps_digest_avg_latency_distribution AS b1 
                                                     WHERE b1.avg_us > @bucket_size * 8 AND b1.avg_us <= @bucket_size * 9), 0)),
       REPEAT(' ', @max_label_len - LENGTH(@label)), '| ',
       IFNULL(REPEAT(IF(@count_in_bucket < @one_unit, '.', IF(@count_in_bucket < @two_unit, '*', '#')), 
       	             IF(@count_in_bucket < @one_unit, @count_in_bucket,
       	             	IF(@count_in_bucket < @two_unit, @count_in_bucket / 2, @count_in_bucket / 3))), ''),
       @label := CONCAT(@label_inner := CONCAT('\n(', ROUND((@bucket_size * 9) / @unit_div), ' - ', ROUND((@bucket_size * 10) / @unit_div), @unit, ')'),
                         REPEAT(' ', @max_label_size - LENGTH(@label_inner)),
                         @count_in_bucket := IFNULL((SELECT SUM(cnt)
                                                       FROM sys.x$ps_digest_avg_latency_distribution AS b1 
                                                      WHERE b1.avg_us > @bucket_size * 9 AND b1.avg_us <= @bucket_size * 10), 0)),
       REPEAT(' ', @max_label_len - LENGTH(@label)), '| ',
       IFNULL(REPEAT(IF(@count_in_bucket < @one_unit, '.', IF(@count_in_bucket < @two_unit, '*', '#')), 
       	             IF(@count_in_bucket < @one_unit, @count_in_bucket,
       	             	IF(@count_in_bucket < @two_unit, @count_in_bucket / 2, @count_in_bucket / 3))), ''),
       @label := CONCAT(@label_inner := CONCAT('\n(', ROUND((@bucket_size * 10) / @unit_div), ' - ', ROUND((@bucket_size * 11) / @unit_div), @unit, ')'),
                        REPEAT(' ', @max_label_size - LENGTH(@label_inner)),
                        @count_in_bucket := IFNULL((SELECT SUM(cnt)
                                                      FROM sys.x$ps_digest_avg_latency_distribution AS b1 
                                                     WHERE b1.avg_us > @bucket_size * 10 AND b1.avg_us <= @bucket_size * 11), 0)),
       REPEAT(' ', @max_label_len - LENGTH(@label)), '| ',
       IFNULL(REPEAT(IF(@count_in_bucket < @one_unit, '.', IF(@count_in_bucket < @two_unit, '*', '#')), 
       	             IF(@count_in_bucket < @one_unit, @count_in_bucket,
       	             	IF(@count_in_bucket < @two_unit, @count_in_bucket / 2, @count_in_bucket / 3))), ''),
       @label := CONCAT(@label_inner := CONCAT('\n(', ROUND((@bucket_size * 11) / @unit_div), ' - ', ROUND((@bucket_size * 12) / @unit_div), @unit, ')'),
                        REPEAT(' ', @max_label_size - LENGTH(@label_inner)),
                        @count_in_bucket := IFNULL((SELECT SUM(cnt)
                                                      FROM sys.x$ps_digest_avg_latency_distribution AS b1 
                                                     WHERE b1.avg_us > @bucket_size * 11 AND b1.avg_us <= @bucket_size * 12), 0)),
       REPEAT(' ', @max_label_len - LENGTH(@label)), '| ',
       IFNULL(REPEAT(IF(@count_in_bucket < @one_unit, '.', IF(@count_in_bucket < @two_unit, '*', '#')), 
       	             IF(@count_in_bucket < @one_unit, @count_in_bucket,
       	             	IF(@count_in_bucket < @two_unit, @count_in_bucket / 2, @count_in_bucket / 3))), ''),
       @label := CONCAT(@label_inner := CONCAT('\n(', ROUND((@bucket_size * 12) / @unit_div), ' - ', ROUND((@bucket_size * 13) / @unit_div), @unit, ')'),
                        REPEAT(' ', @max_label_size - LENGTH(@label_inner)),
                        @count_in_bucket := IFNULL((SELECT SUM(cnt)
                                                      FROM sys.x$ps_digest_avg_latency_distribution AS b1 
                                                     WHERE b1.avg_us > @bucket_size * 12 AND b1.avg_us <= @bucket_size * 13), 0)),
       REPEAT(' ', @max_label_len - LENGTH(@label)), '| ',
       IFNULL(REPEAT(IF(@count_in_bucket < @one_unit, '.', IF(@count_in_bucket < @two_unit, '*', '#')), 
       	             IF(@count_in_bucket < @one_unit, @count_in_bucket,
       	             	IF(@count_in_bucket < @two_unit, @count_in_bucket / 2, @count_in_bucket / 3))), ''),
       @label := CONCAT(@label_inner := CONCAT('\n(', ROUND((@bucket_size * 13) / @unit_div), ' - ', ROUND((@bucket_size * 14) / @unit_div), @unit, ')'),
                        REPEAT(' ', @max_label_size - LENGTH(@label_inner)),
                        @count_in_bucket := IFNULL((SELECT SUM(cnt)
                                                      FROM sys.x$ps_digest_avg_latency_distribution AS b1 
                                                     WHERE b1.avg_us > @bucket_size * 13 AND b1.avg_us <= @bucket_size * 14), 0)),
       REPEAT(' ', @max_label_len - LENGTH(@label)), '| ',
       IFNULL(REPEAT(IF(@count_in_bucket < @one_unit, '.', IF(@count_in_bucket < @two_unit, '*', '#')), 
       	             IF(@count_in_bucket < @one_unit, @count_in_bucket,
       	             	IF(@count_in_bucket < @two_unit, @count_in_bucket / 2, @count_in_bucket / 3))), ''),
       @label := CONCAT(@label_inner := CONCAT('\n(', ROUND((@bucket_size * 14) / @unit_div), ' - ', ROUND((@bucket_size * 15) / @unit_div), @unit, ')'),
                        REPEAT(' ', @max_label_size - LENGTH(@label_inner)),
                        @count_in_bucket := IFNULL((SELECT SUM(cnt)
                                                      FROM sys.x$ps_digest_avg_latency_distribution AS b1 
                                                     WHERE b1.avg_us > @bucket_size * 14 AND b1.avg_us <= @bucket_size * 15), 0)),
       REPEAT(' ', @max_label_len - LENGTH(@label)), '| ',
       IFNULL(REPEAT(IF(@count_in_bucket < @one_unit, '.', IF(@count_in_bucket < @two_unit, '*', '#')), 
       	             IF(@count_in_bucket < @one_unit, @count_in_bucket,
       	             	IF(@count_in_bucket < @two_unit, @count_in_bucket / 2, @count_in_bucket / 3))), ''),
       @label := CONCAT(@label_inner := CONCAT('\n(', ROUND((@bucket_size * 15) / @unit_div), ' - ', ROUND((@bucket_size * 16) / @unit_div), @unit, ')'),
                        REPEAT(' ', @max_label_size - LENGTH(@label_inner)),
                        @count_in_bucket := IFNULL((SELECT SUM(cnt)
                                                      FROM sys.x$ps_digest_avg_latency_distribution AS b1 
                                                     WHERE b1.avg_us > @bucket_size * 15 AND b1.avg_us <= @bucket_size * 16), 0)),
       REPEAT(' ', @max_label_len - LENGTH(@label)), '| ',
       IFNULL(REPEAT(IF(@count_in_bucket < @one_unit, '.', IF(@count_in_bucket < @two_unit, '*', '#')), 
       	             IF(@count_in_bucket < @one_unit, @count_in_bucket,
       	             	IF(@count_in_bucket < @two_unit, @count_in_bucket / 2, @count_in_bucket / 3))), ''),

       '\n\n  Total Statements: ', @total_queries, '; Buckets: ', @buckets , '; Bucket Size: ', ROUND(@bucket_size / @unit_div) , ' ', @unit, ';\n'

      ) AS `Performance Schema Statement Digest Average Latency Histogram`;

END $$

DELIMITER ;
-- Copyright (c) 2014, 2024, Oracle and/or its affiliates.
--
-- This program is free software; you can redistribute it and/or modify
-- it under the terms of the GNU General Public License as published by
-- the Free Software Foundation; version 2 of the License.
--
-- This program is distributed in the hope that it will be useful,
-- but WITHOUT ANY WARRANTY; without even the implied warranty of
-- MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
-- GNU General Public License for more details.
--
-- You should have received a copy of the GNU General Public License
-- along with this program; if not, write to the Free Software
-- Foundation, Inc., 51 Franklin St, Fifth Floor, Boston, MA 02110-1301 USA

DROP PROCEDURE IF EXISTS ps_trace_statement_digest;

DELIMITER $$

CREATE DEFINER='mysql.sys'@'localhost' PROCEDURE ps_trace_statement_digest (
        IN in_digest VARCHAR(64),
        IN in_runtime INT,
        IN in_interval DECIMAL(2,2),
        IN in_start_fresh BOOLEAN,
        IN in_auto_enable BOOLEAN
    )
    COMMENT '
Description
-----------

Traces all instrumentation within Performance Schema for a specific
Statement Digest.

When finding a statement of interest within the
performance_schema.events_statements_summary_by_digest table, feed
the DIGEST value in to this procedure, set how long to poll for,
and at what interval to poll, and it will generate a report of all
statistics tracked within Performance Schema for that digest for the
interval.

It will also attempt to generate an EXPLAIN for the longest running
example of the digest during the interval. Note this may fail, as:

   * Performance Schema truncates long SQL_TEXT values (and hence the
     EXPLAIN will fail due to parse errors)
   * the default schema is sys (so tables that are not fully qualified
     in the query may not be found)
   * some queries such as SHOW are not supported in EXPLAIN.

When the EXPLAIN fails, the error will be ignored and no EXPLAIN
output generated.

Requires the SUPER privilege for "SET sql_log_bin = 0;".

Parameters
-----------

in_digest (VARCHAR(64)):
  The statement digest identifier you would like to analyze
in_runtime (INT):
  The number of seconds to run analysis for
in_interval (DECIMAL(2,2)):
  The interval (in seconds, may be fractional) at which to try
  and take snapshots
in_start_fresh (BOOLEAN):
  Whether to TRUNCATE the events_statements_history_long and
  events_stages_history_long tables before starting
in_auto_enable (BOOLEAN):
  Whether to automatically turn on required consumers

Example
-----------

mysql> call ps_trace_statement_digest(\'891ec6860f98ba46d89dd20b0c03652c\', 10, 0.1, true, true);
+--------------------+
| SUMMARY STATISTICS |
+--------------------+
| SUMMARY STATISTICS |
+--------------------+
1 row in set (9.11 sec)

+------------+-----------+-----------+-----------+---------------+------------+------------+
| executions | exec_time | lock_time | rows_sent | rows_examined | tmp_tables | full_scans |
+------------+-----------+-----------+-----------+---------------+------------+------------+
|         21 | 4.11 ms   | 2.00 ms   |         0 |            21 |          0 |          0 |
+------------+-----------+-----------+-----------+---------------+------------+------------+
1 row in set (9.11 sec)

+------------------------------------------+-------+-----------+
| event_name                               | count | latency   |
+------------------------------------------+-------+-----------+
| stage/sql/checking query cache for query |    16 | 724.37 us |
| stage/sql/statistics                     |    16 | 546.92 us |
| stage/sql/freeing items                  |    18 | 520.11 us |
| stage/sql/init                           |    51 | 466.80 us |
...
| stage/sql/cleaning up                    |    18 | 11.92 us  |
| stage/sql/executing                      |    16 | 6.95 us   |
+------------------------------------------+-------+-----------+
17 rows in set (9.12 sec)

+---------------------------+
| LONGEST RUNNING STATEMENT |
+---------------------------+
| LONGEST RUNNING STATEMENT |
+---------------------------+
1 row in set (9.16 sec)

+-----------+-----------+-----------+-----------+---------------+------------+-----------+
| thread_id | exec_time | lock_time | rows_sent | rows_examined | tmp_tables | full_scan |
+-----------+-----------+-----------+-----------+---------------+------------+-----------+
|    166646 | 618.43 us | 1.00 ms   |         0 |             1 |          0 |         0 |
+-----------+-----------+-----------+-----------+---------------+------------+-----------+
1 row in set (9.16 sec)

// Truncated for clarity...
+-----------------------------------------------------------------+
| sql_text                                                        |
+-----------------------------------------------------------------+
| select hibeventhe0_.id as id1382_, hibeventhe0_.createdTime ... |
+-----------------------------------------------------------------+
1 row in set (9.17 sec)

+------------------------------------------+-----------+
| event_name                               | latency   |
+------------------------------------------+-----------+
| stage/sql/init                           | 8.61 us   |
| stage/sql/Waiting for query cache lock   | 453.23 us |
| stage/sql/init                           | 331.07 ns |
| stage/sql/checking query cache for query | 43.04 us  |
...
| stage/sql/freeing items                  | 30.46 us  |
| stage/sql/cleaning up                    | 662.13 ns |
+------------------------------------------+-----------+
18 rows in set (9.23 sec)

+----+-------------+--------------+-------+---------------+-----------+---------+-------------+------+-------+
| id | select_type | table        | type  | possible_keys | key       | key_len | ref         | rows | Extra |
+----+-------------+--------------+-------+---------------+-----------+---------+-------------+------+-------+
|  1 | SIMPLE      | hibeventhe0_ | const | fixedTime     | fixedTime | 775     | const,const |    1 | NULL  |
+----+-------------+--------------+-------+---------------+-----------+---------+-------------+------+-------+
1 row in set (9.27 sec)

Query OK, 0 rows affected (9.28 sec)
'
    SQL SECURITY INVOKER
    NOT DETERMINISTIC
    MODIFIES SQL DATA
BEGIN

    DECLARE v_start_fresh BOOLEAN DEFAULT false;
    DECLARE v_auto_enable BOOLEAN DEFAULT false;
    DECLARE v_explain     BOOLEAN DEFAULT true;
    DECLARE v_this_thread_enabed ENUM('YES', 'NO');
    DECLARE v_runtime INT DEFAULT 0;
    DECLARE v_start INT DEFAULT 0;
    DECLARE v_found_stmts INT;

    SET @log_bin := @@sql_log_bin;
    SET sql_log_bin = 0;

    -- Do not track the current thread, it will kill the stack
    SELECT INSTRUMENTED INTO v_this_thread_enabed FROM performance_schema.threads WHERE PROCESSLIST_ID = CONNECTION_ID();
    CALL sys.ps_setup_disable_thread(CONNECTION_ID());

    DROP TEMPORARY TABLE IF EXISTS stmt_trace;
    CREATE TEMPORARY TABLE stmt_trace (
        thread_id BIGINT UNSIGNED,
        timer_start BIGINT UNSIGNED,
        event_id BIGINT UNSIGNED,
        sql_text longtext,
        timer_wait BIGINT UNSIGNED,
        lock_time BIGINT UNSIGNED,
        errors BIGINT UNSIGNED,
        mysql_errno INT,
        rows_sent BIGINT UNSIGNED,
        rows_affected BIGINT UNSIGNED,
        rows_examined BIGINT UNSIGNED,
        created_tmp_tables BIGINT UNSIGNED,
        created_tmp_disk_tables BIGINT UNSIGNED,
        no_index_used BIGINT UNSIGNED,
        PRIMARY KEY (thread_id, timer_start)
    );

    DROP TEMPORARY TABLE IF EXISTS stmt_stages;
    CREATE TEMPORARY TABLE stmt_stages (
       event_id BIGINT UNSIGNED,
       stmt_id BIGINT UNSIGNED,
       event_name VARCHAR(128),
       timer_wait BIGINT UNSIGNED,
       PRIMARY KEY (event_id)
    );

    SET v_start_fresh = in_start_fresh;
    IF v_start_fresh THEN
        TRUNCATE TABLE performance_schema.events_statements_history_long;
        TRUNCATE TABLE performance_schema.events_stages_history_long;
    END IF;

    SET v_auto_enable = in_auto_enable;
    IF v_auto_enable THEN
        CALL sys.ps_setup_save(0);

        UPDATE performance_schema.threads
           SET INSTRUMENTED = IF(PROCESSLIST_ID IS NOT NULL, 'YES', 'NO');

        -- Only the events_statements_history_long and events_stages_history_long tables and their ancestors are needed
        UPDATE performance_schema.setup_consumers
           SET ENABLED = 'YES'
         WHERE NAME NOT LIKE '%\_history'
               AND NAME NOT LIKE 'events_wait%'
               AND NAME NOT LIKE 'events_transactions%'
               AND NAME <> 'statements_digest';

        UPDATE performance_schema.setup_instruments
           SET ENABLED = 'YES',
               TIMED   = 'YES'
         WHERE NAME LIKE 'statement/%' OR NAME LIKE 'stage/%';
    END IF;

    WHILE v_runtime < in_runtime DO
        SELECT UNIX_TIMESTAMP() INTO v_start;

        INSERT IGNORE INTO stmt_trace
        SELECT thread_id, timer_start, event_id, sql_text, timer_wait, lock_time, errors, mysql_errno, 
               rows_sent, rows_affected, rows_examined, created_tmp_tables, created_tmp_disk_tables, no_index_used
          FROM performance_schema.events_statements_history_long
        WHERE digest = in_digest;

        INSERT IGNORE INTO stmt_stages
        SELECT stages.event_id, stmt_trace.event_id,
               stages.event_name, stages.timer_wait
          FROM performance_schema.events_stages_history_long AS stages
          JOIN stmt_trace ON stages.nesting_event_id = stmt_trace.event_id;

        SELECT SLEEP(in_interval) INTO @sleep;
        SET v_runtime = v_runtime + (UNIX_TIMESTAMP() - v_start);
    END WHILE;

    SELECT "SUMMARY STATISTICS";

    SELECT COUNT(*) executions,
           format_pico_time(SUM(timer_wait)) AS exec_time,
           format_pico_time(SUM(lock_time)) AS lock_time,
           SUM(rows_sent) AS rows_sent,
           SUM(rows_affected) AS rows_affected,
           SUM(rows_examined) AS rows_examined,
           SUM(created_tmp_tables) AS tmp_tables,
           SUM(no_index_used) AS full_scans
      FROM stmt_trace;

    SELECT event_name,
           COUNT(*) as count,
           format_pico_time(SUM(timer_wait)) as latency
      FROM stmt_stages
     GROUP BY event_name
     ORDER BY SUM(timer_wait) DESC;

    SELECT "LONGEST RUNNING STATEMENT";

    SELECT thread_id,
           format_pico_time(timer_wait) AS exec_time,
           format_pico_time(lock_time) AS lock_time,
           rows_sent,
           rows_affected,
           rows_examined,
           created_tmp_tables AS tmp_tables,
           no_index_used AS full_scan
      FROM stmt_trace
     ORDER BY timer_wait DESC LIMIT 1;

    SELECT sql_text
      FROM stmt_trace
     ORDER BY timer_wait DESC LIMIT 1;

    SELECT sql_text, event_id INTO @sql, @sql_id
      FROM stmt_trace
    ORDER BY timer_wait DESC LIMIT 1;

    IF (@sql_id IS NOT NULL) THEN
        SELECT event_name,
               format_pico_time(timer_wait) as latency
          FROM stmt_stages
         WHERE stmt_id = @sql_id
         ORDER BY event_id;
    END IF;

    DROP TEMPORARY TABLE stmt_trace;
    DROP TEMPORARY TABLE stmt_stages;

    IF (@sql IS NOT NULL) THEN
        SET @stmt := CONCAT("EXPLAIN FORMAT=JSON ", @sql);
        BEGIN
            -- Not all queries support EXPLAIN, so catch the cases that are
            -- not supported. Currently that includes cases where the table
            -- is not fully qualified and is not in the default schema for this
            -- procedure as it's not possible to change the default schema inside
            -- a procedure.
            --
            -- Errno = 1064: You have an error in your SQL syntax
            -- Errno = 1146: Table '...' doesn't exist
            DECLARE CONTINUE HANDLER FOR 1064, 1146 SET v_explain = false;

            PREPARE explain_stmt FROM @stmt;
        END;

        IF (v_explain) THEN
            EXECUTE explain_stmt;
            DEALLOCATE PREPARE explain_stmt;
        END IF;
    END IF;

    IF v_auto_enable THEN
        CALL sys.ps_setup_reload_saved();
    END IF;
    -- Restore INSTRUMENTED for this thread
    IF (v_this_thread_enabed = 'YES') THEN
        CALL sys.ps_setup_enable_thread(CONNECTION_ID());
    END IF;

    SET sql_log_bin = @log_bin;
END$$

DELIMITER ;
-- Copyright (c) 2014, 2024, Oracle and/or its affiliates.
--
-- This program is free software; you can redistribute it and/or modify
-- it under the terms of the GNU General Public License as published by
-- the Free Software Foundation; version 2 of the License.
--
-- This program is distributed in the hope that it will be useful,
-- but WITHOUT ANY WARRANTY; without even the implied warranty of
-- MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
-- GNU General Public License for more details.
--
-- You should have received a copy of the GNU General Public License
-- along with this program; if not, write to the Free Software
-- Foundation, Inc., 51 Franklin St, Fifth Floor, Boston, MA 02110-1301 USA

DROP PROCEDURE IF EXISTS ps_trace_thread;

DELIMITER $$
CREATE DEFINER='mysql.sys'@'localhost' PROCEDURE ps_trace_thread (
        IN in_thread_id BIGINT UNSIGNED,
        IN in_outfile VARCHAR(255),
        IN in_max_runtime DECIMAL(20,2),
        IN in_interval DECIMAL(20,2),
        IN in_start_fresh BOOLEAN,
        IN in_auto_setup BOOLEAN,
        IN in_debug BOOLEAN
    )
    COMMENT '
Description
-----------

Dumps all data within Performance Schema for an instrumented thread,
to create a DOT formatted graph file. 

Each resultset returned from the procedure should be used for a complete graph

Requires the SUPER privilege for "SET sql_log_bin = 0;".

Parameters
-----------

in_thread_id (BIGINT UNSIGNED):
  The thread that you would like a stack trace for
in_outfile  (VARCHAR(255)):
  The filename the dot file will be written to
in_max_runtime (DECIMAL(20,2)):
  The maximum time to keep collecting data.
  Use NULL to get the default which is 60 seconds.
in_interval (DECIMAL(20,2)): 
  How long to sleep between data collections. 
  Use NULL to get the default which is 1 second.
in_start_fresh (BOOLEAN):
  Whether to reset all Performance Schema data before tracing.
in_auto_setup (BOOLEAN):
  Whether to disable all other threads and enable all consumers/instruments. 
  This will also reset the settings at the end of the run.
in_debug (BOOLEAN):
  Whether you would like to include file:lineno in the graph

Example
-----------

mysql> CALL sys.ps_trace_thread(25, CONCAT(\'/tmp/stack-\', REPLACE(NOW(), \' \', \'-\'), \'.dot\'), NULL, NULL, TRUE, TRUE, TRUE);
+-------------------+
| summary           |
+-------------------+
| Disabled 1 thread |
+-------------------+
1 row in set (0.00 sec)

+---------------------------------------------+
| Info                                        |
+---------------------------------------------+
| Data collection starting for THREAD_ID = 25 |
+---------------------------------------------+
1 row in set (0.03 sec)

+-----------------------------------------------------------+
| Info                                                      |
+-----------------------------------------------------------+
| Stack trace written to /tmp/stack-2014-02-16-21:18:41.dot |
+-----------------------------------------------------------+
1 row in set (60.07 sec)

+-------------------------------------------------------------------+
| Convert to PDF                                                    |
+-------------------------------------------------------------------+
| dot -Tpdf -o /tmp/stack_25.pdf /tmp/stack-2014-02-16-21:18:41.dot |
+-------------------------------------------------------------------+
1 row in set (60.07 sec)

+-------------------------------------------------------------------+
| Convert to PNG                                                    |
+-------------------------------------------------------------------+
| dot -Tpng -o /tmp/stack_25.png /tmp/stack-2014-02-16-21:18:41.dot |
+-------------------------------------------------------------------+
1 row in set (60.07 sec)

+------------------+
| summary          |
+------------------+
| Enabled 1 thread |
+------------------+
1 row in set (60.32 sec)
'
    SQL SECURITY INVOKER
    NOT DETERMINISTIC
    MODIFIES SQL DATA
BEGIN
    DECLARE v_done bool DEFAULT FALSE;
    DECLARE v_start, v_runtime DECIMAL(20,2) DEFAULT 0.0;
    DECLARE v_min_event_id bigint unsigned DEFAULT 0;
    DECLARE v_this_thread_enabed ENUM('YES', 'NO');
    DECLARE v_event longtext;
    DECLARE c_stack CURSOR FOR
        SELECT CONCAT(IF(nesting_event_id IS NOT NULL, CONCAT(nesting_event_id, ' -> '), ''), 
                    event_id, '; ', event_id, ' [label="',
                    -- Convert from picoseconds to microseconds
                    '(', format_pico_time(timer_wait), ') ',
                    IF (event_name NOT LIKE 'wait/io%', 
                        SUBSTRING_INDEX(event_name, '/', -2), 
                        IF (event_name NOT LIKE 'wait/io/file%' OR event_name NOT LIKE 'wait/io/socket%',
                            SUBSTRING_INDEX(event_name, '/', -4),
                            event_name)
                        ),
                    -- Always dump the extra wait information gathered for transactions and statements
                    IF (event_name LIKE 'transaction', IFNULL(CONCAT('\\n', wait_info), ''), ''),
                    IF (event_name LIKE 'statement/%', IFNULL(CONCAT('\\n', wait_info), ''), ''),
                    -- If debug is enabled, add the file:lineno information for waits
                    IF (in_debug AND event_name LIKE 'wait%', wait_info, ''),
                    '", ', 
                    -- Depending on the type of event, style appropriately
                    CASE WHEN event_name LIKE 'wait/io/file%' THEN 
                           'shape=box, style=filled, color=red'
                         WHEN event_name LIKE 'wait/io/table%' THEN 
                           'shape=box, style=filled, color=green'
                         WHEN event_name LIKE 'wait/io/socket%' THEN
                           'shape=box, style=filled, color=yellow'
                         WHEN event_name LIKE 'wait/synch/mutex%' THEN
                           'style=filled, color=lightskyblue'
                         WHEN event_name LIKE 'wait/synch/cond%' THEN
                           'style=filled, color=darkseagreen3'
                         WHEN event_name LIKE 'wait/synch/rwlock%' THEN
                           'style=filled, color=orchid'
                         WHEN event_name LIKE 'wait/synch/sxlock%' THEN
                           'style=filled, color=palevioletred' 
                         WHEN event_name LIKE 'wait/lock%' THEN
                           'shape=box, style=filled, color=tan'
                         WHEN event_name LIKE 'statement/%' THEN
                           CONCAT('shape=box, style=bold',
                                  -- Style statements depending on COM vs SQL
                                  CASE WHEN event_name LIKE 'statement/com/%' THEN
                                         ' style=filled, color=darkseagreen'
                                       ELSE
                                         -- Use long query time from the server to
                                         -- flag long running statements in red
                                         IF((timer_wait/1000000000000) > @@long_query_time, 
                                            ' style=filled, color=red', 
                                            ' style=filled, color=lightblue')
                                  END
                           )
                         WHEN event_name LIKE 'transaction' THEN
                           'shape=box, style=filled, color=lightblue3'
                         WHEN event_name LIKE 'stage/%' THEN
                           'style=filled, color=slategray3'
                         -- IDLE events are on their own, call attention to them
                         WHEN event_name LIKE '%idle%' THEN
                           'shape=box, style=filled, color=firebrick3'
                         ELSE '' END,
                     '];\n'
                   ) event, event_id
        FROM (
             -- Select all transactions
             (SELECT thread_id, event_id, event_name, timer_wait, timer_start, nesting_event_id,
                     CONCAT('trx_id: ',  IFNULL(trx_id, ''), '\\n',
                            'gtid: ', IFNULL(gtid, ''), '\\n',
                            'state: ', state, '\\n',
                            'mode: ', access_mode, '\\n',
                            'isolation: ', isolation_level, '\\n',
                            'autocommit: ', autocommit, '\\n',
                            'savepoints: ', number_of_savepoints, '\\n'
                     ) AS wait_info
                FROM performance_schema.events_transactions_history_long
               WHERE thread_id = in_thread_id AND event_id > v_min_event_id)
             UNION
             -- Select all statements, with the extra tracing information available
             (SELECT thread_id, event_id, event_name, timer_wait, timer_start, nesting_event_id, 
                     CONCAT('statement: ', sql_text, '\\n',
                            'errors: ', errors, '\\n',
                            'warnings: ', warnings, '\\n',
                            'lock time: ', format_pico_time(lock_time),'\\n',
                            'rows affected: ', rows_affected, '\\n',
                            'rows sent: ', rows_sent, '\\n',
                            'rows examined: ', rows_examined, '\\n',
                            'tmp tables: ', created_tmp_tables, '\\n',
                            'tmp disk tables: ', created_tmp_disk_tables, '\\n'
                            'select scan: ', select_scan, '\\n',
                            'select full join: ', select_full_join, '\\n',
                            'select full range join: ', select_full_range_join, '\\n',
                            'select range: ', select_range, '\\n',
                            'select range check: ', select_range_check, '\\n', 
                            'sort merge passes: ', sort_merge_passes, '\\n',
                            'sort rows: ', sort_rows, '\\n',
                            'sort range: ', sort_range, '\\n',
                            'sort scan: ', sort_scan, '\\n',
                            'no index used: ', IF(no_index_used, 'TRUE', 'FALSE'), '\\n',
                            'no good index used: ', IF(no_good_index_used, 'TRUE', 'FALSE'), '\\n'
                     ) AS wait_info
                FROM performance_schema.events_statements_history_long
               WHERE thread_id = in_thread_id AND event_id > v_min_event_id)
             UNION
             -- Select all stages
             (SELECT thread_id, event_id, event_name, timer_wait, timer_start, nesting_event_id, null AS wait_info
                FROM performance_schema.events_stages_history_long 
               WHERE thread_id = in_thread_id AND event_id > v_min_event_id)
             UNION 
             -- Select all events, adding information appropriate to the event
             (SELECT thread_id, event_id, 
                     CONCAT(event_name, 
                            IF(event_name NOT LIKE 'wait/synch/mutex%', IFNULL(CONCAT(' - ', operation), ''), ''), 
                            IF(number_of_bytes IS NOT NULL, CONCAT(' ', number_of_bytes, ' bytes'), ''),
                            IF(event_name LIKE 'wait/io/file%', '\\n', ''),
                            IF(object_schema IS NOT NULL, CONCAT('\\nObject: ', object_schema, '.'), ''), 
                            IF(object_name IS NOT NULL, 
                               IF (event_name LIKE 'wait/io/socket%',
                                   -- Print the socket if used, else the IP:port as reported
                                   CONCAT('\\n', IF (object_name LIKE ':0%', @@socket, object_name)),
                                   object_name),
                               ''
                            ),
                            IF(index_name IS NOT NULL, CONCAT(' Index: ', index_name), ''), '\\n'
                     ) AS event_name,
                     timer_wait, timer_start, nesting_event_id, source AS wait_info
                FROM performance_schema.events_waits_history_long
               WHERE thread_id = in_thread_id AND event_id > v_min_event_id)
           ) events 
       ORDER BY event_id;
    DECLARE CONTINUE HANDLER FOR NOT FOUND SET v_done = TRUE;

    SET @log_bin := @@sql_log_bin;
    SET sql_log_bin = 0;

    -- Do not track the current thread, it will kill the stack
    SELECT INSTRUMENTED INTO v_this_thread_enabed FROM performance_schema.threads WHERE PROCESSLIST_ID = CONNECTION_ID();
    CALL sys.ps_setup_disable_thread(CONNECTION_ID());

    IF (in_auto_setup) THEN
        CALL sys.ps_setup_save(0);
        
        -- Ensure only the thread to create the stack trace for is instrumented and that we instrument everything.
        DELETE FROM performance_schema.setup_actors;

        UPDATE performance_schema.threads
           SET INSTRUMENTED = IF(THREAD_ID = in_thread_id, 'YES', 'NO');

        -- only the %_history_long tables and it ancestors are needed
        UPDATE performance_schema.setup_consumers
           SET ENABLED = 'YES'
         WHERE NAME NOT LIKE '%\_history';

        UPDATE performance_schema.setup_instruments
           SET ENABLED = 'YES',
               TIMED   = 'YES';
    END IF;

    IF (in_start_fresh) THEN
        TRUNCATE performance_schema.events_transactions_history_long;
        TRUNCATE performance_schema.events_statements_history_long;
        TRUNCATE performance_schema.events_stages_history_long;
        TRUNCATE performance_schema.events_waits_history_long;
    END IF;

    DROP TEMPORARY TABLE IF EXISTS tmp_events;
    CREATE TEMPORARY TABLE tmp_events (
      event_id bigint unsigned NOT NULL,
      event longblob,
      PRIMARY KEY (event_id)
    );

    -- Print headers for a .dot file
    INSERT INTO tmp_events VALUES (0, CONCAT('digraph events { rankdir=LR; nodesep=0.10;\n',
                                             '// Stack created .....: ', NOW(), '\n',
                                             '// MySQL version .....: ', VERSION(), '\n',
                                             '// MySQL hostname ....: ', @@hostname, '\n',
                                             '// MySQL port ........: ', @@port, '\n',
                                             '// MySQL socket ......: ', @@socket, '\n',
                                             '// MySQL user ........: ', CURRENT_USER(), '\n'));

    SELECT CONCAT('Data collection starting for THREAD_ID = ', in_thread_id) AS 'Info';

    SET v_min_event_id = 0,
        v_start        = UNIX_TIMESTAMP(),
        in_interval    = IFNULL(in_interval, 1.00),
        in_max_runtime = IFNULL(in_max_runtime, 60.00);

    WHILE (v_runtime < in_max_runtime
           AND (SELECT INSTRUMENTED FROM performance_schema.threads WHERE THREAD_ID = in_thread_id) = 'YES') DO
        SET v_done = FALSE;
        OPEN c_stack;
        c_stack_loop: LOOP
            FETCH c_stack INTO v_event, v_min_event_id;
            IF v_done THEN
                LEAVE c_stack_loop;
            END IF;

            IF (LENGTH(v_event) > 0) THEN
                INSERT INTO tmp_events VALUES (v_min_event_id, v_event);
            END IF;
        END LOOP;
        CLOSE c_stack;

        SELECT SLEEP(in_interval) INTO @sleep;
        SET v_runtime = (UNIX_TIMESTAMP() - v_start);
    END WHILE;

    INSERT INTO tmp_events VALUES (v_min_event_id+1, '}');
   
    SET @query = CONCAT('SELECT event FROM tmp_events ORDER BY event_id INTO OUTFILE ''', in_outfile, ''' FIELDS ESCAPED BY '''' LINES TERMINATED BY ''''');
    PREPARE stmt_output FROM @query;
    EXECUTE stmt_output;
    DEALLOCATE PREPARE stmt_output;
   
    SELECT CONCAT('Stack trace written to ', in_outfile) AS 'Info';
    SELECT CONCAT('dot -Tpdf -o /tmp/stack_', in_thread_id, '.pdf ', in_outfile) AS 'Convert to PDF';
    SELECT CONCAT('dot -Tpng -o /tmp/stack_', in_thread_id, '.png ', in_outfile) AS 'Convert to PNG';
    DROP TEMPORARY TABLE tmp_events;

    -- Reset the settings for the performance schema
    IF (in_auto_setup) THEN
        CALL sys.ps_setup_reload_saved();
    END IF;
    -- Restore INSTRUMENTED for this thread
    IF (v_this_thread_enabed = 'YES') THEN
        CALL sys.ps_setup_enable_thread(CONNECTION_ID());
    END IF;

    SET sql_log_bin = @log_bin;
END$$

DELIMITER ;
-- Copyright (c) 2014, 2024, Oracle and/or its affiliates.
--
-- This program is free software; you can redistribute it and/or modify
-- it under the terms of the GNU General Public License as published by
-- the Free Software Foundation; version 2 of the License.
--
-- This program is distributed in the hope that it will be useful,
-- but WITHOUT ANY WARRANTY; without even the implied warranty of
-- MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
-- GNU General Public License for more details.
--
-- You should have received a copy of the GNU General Public License
-- along with this program; if not, write to the Free Software
-- Foundation, Inc., 51 Franklin St, Fifth Floor, Boston, MA 02110-1301 USA

DROP PROCEDURE IF EXISTS ps_setup_disable_background_threads;

DELIMITER $$

CREATE DEFINER='mysql.sys'@'localhost' PROCEDURE ps_setup_disable_background_threads ()
    COMMENT '
Description
-----------

Disable all background thread instrumentation within Performance Schema.

Parameters
-----------

None.

Example
-----------

mysql> CALL sys.ps_setup_disable_background_threads();
+--------------------------------+
| summary                        |
+--------------------------------+
| Disabled 18 background threads |
+--------------------------------+
1 row in set (0.00 sec)
'
    SQL SECURITY INVOKER
    NOT DETERMINISTIC
    MODIFIES SQL DATA
BEGIN
    UPDATE performance_schema.threads
       SET instrumented = 'NO'
     WHERE type = 'BACKGROUND';

    SELECT CONCAT('Disabled ', @rows := ROW_COUNT(), ' background thread', IF(@rows != 1, 's', '')) AS summary;
END$$

DELIMITER ;
-- Copyright (c) 2014, 2024, Oracle and/or its affiliates.
--
-- This program is free software; you can redistribute it and/or modify
-- it under the terms of the GNU General Public License as published by
-- the Free Software Foundation; version 2 of the License.
--
-- This program is distributed in the hope that it will be useful,
-- but WITHOUT ANY WARRANTY; without even the implied warranty of
-- MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
-- GNU General Public License for more details.
--
-- You should have received a copy of the GNU General Public License
-- along with this program; if not, write to the Free Software
-- Foundation, Inc., 51 Franklin St, Fifth Floor, Boston, MA 02110-1301 USA

DROP PROCEDURE IF EXISTS ps_setup_disable_consumer;

DELIMITER $$

CREATE DEFINER='mysql.sys'@'localhost' PROCEDURE ps_setup_disable_consumer (
        IN consumer VARCHAR(128)
    )
    COMMENT '
Description
-----------

Disables consumers within Performance Schema 
matching the input pattern.

Parameters
-----------

consumer (VARCHAR(128)):
  A LIKE pattern match (using "%consumer%") of consumers to disable

Example
-----------

To disable all consumers:

mysql> CALL sys.ps_setup_disable_consumer(\'\');
+--------------------------+
| summary                  |
+--------------------------+
| Disabled 15 consumers    |
+--------------------------+
1 row in set (0.02 sec)

To disable just the event_stage consumers:

mysql> CALL sys.ps_setup_disable_comsumers(\'stage\');
+------------------------+
| summary                |
+------------------------+
| Disabled 3 consumers   |
+------------------------+
1 row in set (0.00 sec)
'
    SQL SECURITY INVOKER
    NOT DETERMINISTIC
    MODIFIES SQL DATA
BEGIN
    UPDATE performance_schema.setup_consumers
       SET enabled = 'NO'
     WHERE name LIKE CONCAT('%', consumer, '%');

    SELECT CONCAT('Disabled ', @rows := ROW_COUNT(), ' consumer', IF(@rows != 1, 's', '')) AS summary;
END$$

DELIMITER ;
-- Copyright (c) 2014, 2024, Oracle and/or its affiliates.
--
-- This program is free software; you can redistribute it and/or modify
-- it under the terms of the GNU General Public License as published by
-- the Free Software Foundation; version 2 of the License.
--
-- This program is distributed in the hope that it will be useful,
-- but WITHOUT ANY WARRANTY; without even the implied warranty of
-- MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
-- GNU General Public License for more details.
--
-- You should have received a copy of the GNU General Public License
-- along with this program; if not, write to the Free Software
-- Foundation, Inc., 51 Franklin St, Fifth Floor, Boston, MA 02110-1301 USA

DROP PROCEDURE IF EXISTS ps_setup_disable_instrument;

DELIMITER $$

CREATE DEFINER='mysql.sys'@'localhost' PROCEDURE ps_setup_disable_instrument (
        IN in_pattern VARCHAR(128)
    )
    COMMENT '
Description
-----------

Disables instruments within Performance Schema 
matching the input pattern.

Parameters
-----------

in_pattern (VARCHAR(128)):
  A LIKE pattern match (using "%in_pattern%") of events to disable

Example
-----------

To disable all mutex instruments:

mysql> CALL sys.ps_setup_disable_instrument(\'wait/synch/mutex\');
+--------------------------+
| summary                  |
+--------------------------+
| Disabled 155 instruments |
+--------------------------+
1 row in set (0.02 sec)

To disable just a specific TCP/IP based network IO instrument:

mysql> CALL sys.ps_setup_disable_instrument(\'wait/io/socket/sql/server_tcpip_socket\');
+------------------------+
| summary                |
+------------------------+
| Disabled 1 instruments |
+------------------------+
1 row in set (0.00 sec)

To disable all instruments:

mysql> CALL sys.ps_setup_disable_instrument(\'\');
+--------------------------+
| summary                  |
+--------------------------+
| Disabled 547 instruments |
+--------------------------+
1 row in set (0.01 sec)
'
    SQL SECURITY INVOKER
    NOT DETERMINISTIC
    MODIFIES SQL DATA
BEGIN
    UPDATE performance_schema.setup_instruments
       SET enabled = 'NO', timed = 'NO'
     WHERE name LIKE CONCAT('%', in_pattern, '%');

    SELECT CONCAT('Disabled ', @rows := ROW_COUNT(), ' instrument', IF(@rows != 1, 's', '')) AS summary;
END$$

DELIMITER ;
-- Copyright (c) 2014, 2024, Oracle and/or its affiliates.
--
-- This program is free software; you can redistribute it and/or modify
-- it under the terms of the GNU General Public License as published by
-- the Free Software Foundation; version 2 of the License.
--
-- This program is distributed in the hope that it will be useful,
-- but WITHOUT ANY WARRANTY; without even the implied warranty of
-- MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
-- GNU General Public License for more details.
--
-- You should have received a copy of the GNU General Public License
-- along with this program; if not, write to the Free Software
-- Foundation, Inc., 51 Franklin St, Fifth Floor, Boston, MA 02110-1301 USA

DROP PROCEDURE IF EXISTS ps_setup_disable_thread;

DELIMITER $$

CREATE DEFINER='mysql.sys'@'localhost' PROCEDURE ps_setup_disable_thread (
        IN in_connection_id BIGINT
    )
    COMMENT '
Description
-----------

Disable the given connection/thread in Performance Schema.

Parameters
-----------

in_connection_id (BIGINT):
  The connection ID (PROCESSLIST_ID from performance_schema.threads
  or the ID shown within SHOW PROCESSLIST)

Example
-----------

mysql> CALL sys.ps_setup_disable_thread(3);
+-------------------+
| summary           |
+-------------------+
| Disabled 1 thread |
+-------------------+
1 row in set (0.01 sec)

To disable the current connection:

mysql> CALL sys.ps_setup_disable_thread(CONNECTION_ID());
+-------------------+
| summary           |
+-------------------+
| Disabled 1 thread |
+-------------------+
1 row in set (0.00 sec)
'
    SQL SECURITY INVOKER
    NOT DETERMINISTIC
    MODIFIES SQL DATA
BEGIN
    UPDATE performance_schema.threads
       SET instrumented = 'NO'
     WHERE processlist_id = in_connection_id;

    SELECT CONCAT('Disabled ', @rows := ROW_COUNT(), ' thread', IF(@rows != 1, 's', '')) AS summary;
END$$

DELIMITER ;
-- Copyright (c) 2014, 2024, Oracle and/or its affiliates.
--
-- This program is free software; you can redistribute it and/or modify
-- it under the terms of the GNU General Public License as published by
-- the Free Software Foundation; version 2 of the License.
--
-- This program is distributed in the hope that it will be useful,
-- but WITHOUT ANY WARRANTY; without even the implied warranty of
-- MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
-- GNU General Public License for more details.
--
-- You should have received a copy of the GNU General Public License
-- along with this program; if not, write to the Free Software
-- Foundation, Inc., 51 Franklin St, Fifth Floor, Boston, MA 02110-1301 USA

DROP PROCEDURE IF EXISTS ps_setup_enable_background_threads;

DELIMITER $$

CREATE DEFINER='mysql.sys'@'localhost' PROCEDURE ps_setup_enable_background_threads ()
    COMMENT '
Description
-----------

Enable all background thread instrumentation within Performance Schema.

Parameters
-----------

None.

Example
-----------

mysql> CALL sys.ps_setup_enable_background_threads();
+-------------------------------+
| summary                       |
+-------------------------------+
| Enabled 18 background threads |
+-------------------------------+
1 row in set (0.00 sec)
'
    SQL SECURITY INVOKER
    NOT DETERMINISTIC
    MODIFIES SQL DATA
BEGIN
    UPDATE performance_schema.threads
       SET instrumented = 'YES'
     WHERE type = 'BACKGROUND';

    SELECT CONCAT('Enabled ', @rows := ROW_COUNT(), ' background thread', IF(@rows != 1, 's', '')) AS summary;
END$$

DELIMITER ;
-- Copyright (c) 2014, 2024, Oracle and/or its affiliates.
--
-- This program is free software; you can redistribute it and/or modify
-- it under the terms of the GNU General Public License as published by
-- the Free Software Foundation; version 2 of the License.
--
-- This program is distributed in the hope that it will be useful,
-- but WITHOUT ANY WARRANTY; without even the implied warranty of
-- MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
-- GNU General Public License for more details.
--
-- You should have received a copy of the GNU General Public License
-- along with this program; if not, write to the Free Software
-- Foundation, Inc., 51 Franklin St, Fifth Floor, Boston, MA 02110-1301 USA

DROP PROCEDURE IF EXISTS ps_setup_enable_consumer;

DELIMITER $$

CREATE DEFINER='mysql.sys'@'localhost' PROCEDURE ps_setup_enable_consumer (
        IN consumer VARCHAR(128)
    )
    COMMENT '
Description
-----------

Enables consumers within Performance Schema 
matching the input pattern.

Parameters
-----------

consumer (VARCHAR(128)):
  A LIKE pattern match (using "%consumer%") of consumers to enable

Example
-----------

To enable all consumers:

mysql> CALL sys.ps_setup_enable_consumer(\'\');
+-------------------------+
| summary                 |
+-------------------------+
| Enabled 10 consumers    |
+-------------------------+
1 row in set (0.02 sec)

Query OK, 0 rows affected (0.02 sec)

To enable just "waits" consumers:

mysql> CALL sys.ps_setup_enable_consumer(\'waits\');
+-----------------------+
| summary               |
+-----------------------+
| Enabled 3 consumers   |
+-----------------------+
1 row in set (0.00 sec)

Query OK, 0 rows affected (0.00 sec)
'
    SQL SECURITY INVOKER
    NOT DETERMINISTIC
    MODIFIES SQL DATA
BEGIN
    UPDATE performance_schema.setup_consumers
       SET enabled = 'YES'
     WHERE name LIKE CONCAT('%', consumer, '%');

    SELECT CONCAT('Enabled ', @rows := ROW_COUNT(), ' consumer', IF(@rows != 1, 's', '')) AS summary;
END$$

DELIMITER ;
-- Copyright (c) 2014, 2024, Oracle and/or its affiliates.
--
-- This program is free software; you can redistribute it and/or modify
-- it under the terms of the GNU General Public License as published by
-- the Free Software Foundation; version 2 of the License.
--
-- This program is distributed in the hope that it will be useful,
-- but WITHOUT ANY WARRANTY; without even the implied warranty of
-- MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
-- GNU General Public License for more details.
--
-- You should have received a copy of the GNU General Public License
-- along with this program; if not, write to the Free Software
-- Foundation, Inc., 51 Franklin St, Fifth Floor, Boston, MA 02110-1301 USA

DROP PROCEDURE IF EXISTS ps_setup_enable_instrument;

DELIMITER $$

CREATE DEFINER='mysql.sys'@'localhost' PROCEDURE ps_setup_enable_instrument (
        IN in_pattern VARCHAR(128)
    )
    COMMENT '
Description
-----------

Enables instruments within Performance Schema 
matching the input pattern.

Parameters
-----------

in_pattern (VARCHAR(128)):
  A LIKE pattern match (using "%in_pattern%") of events to enable

Example
-----------

To enable all mutex instruments:

mysql> CALL sys.ps_setup_enable_instrument(\'wait/synch/mutex\');
+-------------------------+
| summary                 |
+-------------------------+
| Enabled 155 instruments |
+-------------------------+
1 row in set (0.02 sec)

Query OK, 0 rows affected (0.02 sec)

To enable just a specific TCP/IP based network IO instrument:

mysql> CALL sys.ps_setup_enable_instrument(\'wait/io/socket/sql/server_tcpip_socket\');
+-----------------------+
| summary               |
+-----------------------+
| Enabled 1 instruments |
+-----------------------+
1 row in set (0.00 sec)

Query OK, 0 rows affected (0.00 sec)

To enable all instruments:

mysql> CALL sys.ps_setup_enable_instrument(\'\');
+-------------------------+
| summary                 |
+-------------------------+
| Enabled 547 instruments |
+-------------------------+
1 row in set (0.01 sec)

Query OK, 0 rows affected (0.01 sec)
'
    SQL SECURITY INVOKER
    NOT DETERMINISTIC
    MODIFIES SQL DATA
BEGIN
    UPDATE performance_schema.setup_instruments
       SET enabled = 'YES', timed = 'YES'
     WHERE name LIKE CONCAT('%', in_pattern, '%');

    SELECT CONCAT('Enabled ', @rows := ROW_COUNT(), ' instrument', IF(@rows != 1, 's', '')) AS summary;
END$$

DELIMITER ;
-- Copyright (c) 2014, 2024, Oracle and/or its affiliates.
--
-- This program is free software; you can redistribute it and/or modify
-- it under the terms of the GNU General Public License as published by
-- the Free Software Foundation; version 2 of the License.
--
-- This program is distributed in the hope that it will be useful,
-- but WITHOUT ANY WARRANTY; without even the implied warranty of
-- MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
-- GNU General Public License for more details.
--
-- You should have received a copy of the GNU General Public License
-- along with this program; if not, write to the Free Software
-- Foundation, Inc., 51 Franklin St, Fifth Floor, Boston, MA 02110-1301 USA

DROP PROCEDURE IF EXISTS ps_setup_enable_thread;

DELIMITER $$

CREATE DEFINER='mysql.sys'@'localhost' PROCEDURE ps_setup_enable_thread (
        IN in_connection_id BIGINT
    )
    COMMENT '
Description
-----------

Enable the given connection/thread in Performance Schema.

Parameters
-----------

in_connection_id (BIGINT):
  The connection ID (PROCESSLIST_ID from performance_schema.threads
  or the ID shown within SHOW PROCESSLIST)

Example
-----------

mysql> CALL sys.ps_setup_enable_thread(3);
+------------------+
| summary          |
+------------------+
| Enabled 1 thread |
+------------------+
1 row in set (0.01 sec)

To enable the current connection:

mysql> CALL sys.ps_setup_enable_thread(CONNECTION_ID());
+------------------+
| summary          |
+------------------+
| Enabled 1 thread |
+------------------+
1 row in set (0.00 sec)
'
    SQL SECURITY INVOKER
    NOT DETERMINISTIC
    MODIFIES SQL DATA
BEGIN
    UPDATE performance_schema.threads
       SET instrumented = 'YES'
     WHERE processlist_id = in_connection_id;

    SELECT CONCAT('Enabled ', @rows := ROW_COUNT(), ' thread', IF(@rows != 1, 's', '')) AS summary;
END$$

DELIMITER ;
-- Copyright (c) 2014, 2024, Oracle and/or its affiliates.
--
-- This program is free software; you can redistribute it and/or modify
-- it under the terms of the GNU General Public License as published by
-- the Free Software Foundation; version 2 of the License.
--
-- This program is distributed in the hope that it will be useful,
-- but WITHOUT ANY WARRANTY; without even the implied warranty of
-- MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
-- GNU General Public License for more details.
--
-- You should have received a copy of the GNU General Public License
-- along with this program; if not, write to the Free Software
-- Foundation, Inc., 51 Franklin St, Fifth Floor, Boston, MA 02110-1301 USA

DROP PROCEDURE IF EXISTS ps_setup_reload_saved;

DELIMITER $$

CREATE DEFINER='mysql.sys'@'localhost' PROCEDURE ps_setup_reload_saved ()
    COMMENT '
Description
-----------

Reloads a saved Performance Schema configuration,
so that you can alter the setup for debugging purposes, 
but restore it to a previous state.

Use the companion procedure - ps_setup_save(), to 
save a configuration.

Requires the SUPER privilege for "SET sql_log_bin = 0;".

Parameters
-----------

None.

Example
-----------

mysql> CALL sys.ps_setup_save();
Query OK, 0 rows affected (0.08 sec)

mysql> UPDATE performance_schema.setup_instruments SET enabled = \'YES\', timed = \'YES\';
Query OK, 547 rows affected (0.40 sec)
Rows matched: 784  Changed: 547  Warnings: 0

/* Run some tests that need more detailed instrumentation here */

mysql> CALL sys.ps_setup_reload_saved();
Query OK, 0 rows affected (0.32 sec)
'
    SQL SECURITY INVOKER
    NOT DETERMINISTIC
    MODIFIES SQL DATA
BEGIN
    DECLARE v_done bool DEFAULT FALSE;
    DECLARE v_lock_result INT;
    DECLARE v_lock_used_by BIGINT;
    DECLARE v_signal_message TEXT;
    DECLARE EXIT HANDLER FOR SQLEXCEPTION
    BEGIN
        SIGNAL SQLSTATE VALUE '90001'
           SET MESSAGE_TEXT = 'An error occurred, was sys.ps_setup_save() run before this procedure?';
    END;

    SET @log_bin := @@sql_log_bin;
    SET sql_log_bin = 0;

    SELECT IS_USED_LOCK('sys.ps_setup_save') INTO v_lock_used_by;

    IF (v_lock_used_by != CONNECTION_ID()) THEN
        SET v_signal_message = CONCAT('The sys.ps_setup_save lock is currently owned by ', v_lock_used_by);
        SIGNAL SQLSTATE VALUE '90002'
           SET MESSAGE_TEXT = v_signal_message;
    END IF;

    DELETE FROM performance_schema.setup_actors;
    INSERT INTO performance_schema.setup_actors SELECT * FROM tmp_setup_actors;

    BEGIN
        -- Workaround for http://bugs.mysql.com/bug.php?id=70025
        DECLARE v_name varchar(64);
        DECLARE v_enabled enum('YES', 'NO');
        DECLARE c_consumers CURSOR FOR SELECT NAME, ENABLED FROM tmp_setup_consumers;
        DECLARE CONTINUE HANDLER FOR NOT FOUND SET v_done = TRUE;

        SET v_done = FALSE;
        OPEN c_consumers;
        c_consumers_loop: LOOP
            FETCH c_consumers INTO v_name, v_enabled;
            IF v_done THEN
               LEAVE c_consumers_loop;
            END IF;

            UPDATE performance_schema.setup_consumers
               SET ENABLED = v_enabled
             WHERE NAME = v_name;
         END LOOP;
         CLOSE c_consumers;
    END;

    UPDATE performance_schema.setup_instruments
     INNER JOIN tmp_setup_instruments USING (NAME)
       SET performance_schema.setup_instruments.ENABLED = tmp_setup_instruments.ENABLED,
           performance_schema.setup_instruments.TIMED   = tmp_setup_instruments.TIMED;
    BEGIN
        -- Workaround for http://bugs.mysql.com/bug.php?id=70025
        DECLARE v_thread_id bigint unsigned;
        DECLARE v_instrumented enum('YES', 'NO');
        DECLARE c_threads CURSOR FOR SELECT THREAD_ID, INSTRUMENTED FROM tmp_threads;
        DECLARE CONTINUE HANDLER FOR NOT FOUND SET v_done = TRUE;

        SET v_done = FALSE;
        OPEN c_threads;
        c_threads_loop: LOOP
            FETCH c_threads INTO v_thread_id, v_instrumented;
            IF v_done THEN
               LEAVE c_threads_loop;
            END IF;

            UPDATE performance_schema.threads
               SET INSTRUMENTED = v_instrumented
             WHERE THREAD_ID = v_thread_id;
        END LOOP;
        CLOSE c_threads;
    END;

    UPDATE performance_schema.threads
       SET INSTRUMENTED = IF(PROCESSLIST_USER IS NOT NULL,
                             sys.ps_is_account_enabled(PROCESSLIST_HOST, PROCESSLIST_USER),
                             'YES')
     WHERE THREAD_ID NOT IN (SELECT THREAD_ID FROM tmp_threads);

    DROP TEMPORARY TABLE tmp_setup_actors;
    DROP TEMPORARY TABLE tmp_setup_consumers;
    DROP TEMPORARY TABLE tmp_setup_instruments;
    DROP TEMPORARY TABLE tmp_threads;

    SELECT RELEASE_LOCK('sys.ps_setup_save') INTO v_lock_result;

    SET sql_log_bin = @log_bin; 
END$$

DELIMITER ;
-- Copyright (c) 2014, 2024, Oracle and/or its affiliates.
--
-- This program is free software; you can redistribute it and/or modify
-- it under the terms of the GNU General Public License as published by
-- the Free Software Foundation; version 2 of the License.
--
-- This program is distributed in the hope that it will be useful,
-- but WITHOUT ANY WARRANTY; without even the implied warranty of
-- MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
-- GNU General Public License for more details.
--
-- You should have received a copy of the GNU General Public License
-- along with this program; if not, write to the Free Software
-- Foundation, Inc., 51 Franklin St, Fifth Floor, Boston, MA 02110-1301 USA

DROP PROCEDURE IF EXISTS ps_setup_reset_to_default;

DELIMITER $$

CREATE DEFINER='mysql.sys'@'localhost' PROCEDURE ps_setup_reset_to_default (
       IN in_verbose BOOLEAN
    )
    COMMENT '
Description
-----------

Resets the Performance Schema setup to the default settings.

Parameters
-----------

in_verbose (BOOLEAN):
  Whether to print each setup stage (including the SQL) whilst running.

Example
-----------

mysql> CALL sys.ps_setup_reset_to_default(true)\\G
*************************** 1. row ***************************
status: Resetting: setup_actors
DELETE
FROM performance_schema.setup_actors
 WHERE NOT (HOST = \'%\' AND USER = \'%\' AND `ROLE` = \'%\')
1 row in set (0.00 sec)

*************************** 1. row ***************************
status: Resetting: setup_actors
INSERT IGNORE INTO performance_schema.setup_actors
VALUES (\'%\', \'%\', \'%\')
1 row in set (0.00 sec)
...

mysql> CALL sys.ps_setup_reset_to_default(false)\\G
Query OK, 0 rows affected (0.00 sec)
'
    SQL SECURITY INVOKER
    NOT DETERMINISTIC
    MODIFIES SQL DATA
BEGIN
    SET @query = 'DELETE
                    FROM performance_schema.setup_actors
                   WHERE NOT (HOST = ''%'' AND USER = ''%'' AND `ROLE` = ''%'')';

    IF (in_verbose) THEN
        SELECT CONCAT('Resetting: setup_actors\n', REPLACE(@query, '  ', '')) AS status;
    END IF;

    PREPARE reset_stmt FROM @query;
    EXECUTE reset_stmt;
    DEALLOCATE PREPARE reset_stmt;

    SET @query = 'INSERT IGNORE INTO performance_schema.setup_actors
                  VALUES (''%'', ''%'', ''%'', ''YES'', ''YES'')';

    IF (in_verbose) THEN
        SELECT CONCAT('Resetting: setup_actors\n', REPLACE(@query, '  ', '')) AS status;
    END IF;

    PREPARE reset_stmt FROM @query;
    EXECUTE reset_stmt;
    DEALLOCATE PREPARE reset_stmt;

    SET @query = 'UPDATE performance_schema.setup_instruments
                     SET ENABLED = sys.ps_is_instrument_default_enabled(NAME),
                         TIMED   = sys.ps_is_instrument_default_timed(NAME)';

    IF (in_verbose) THEN
        SELECT CONCAT('Resetting: setup_instruments\n', REPLACE(@query, '  ', '')) AS status;
    END IF;

    PREPARE reset_stmt FROM @query;
    EXECUTE reset_stmt;
    DEALLOCATE PREPARE reset_stmt;

    SET @query = 'UPDATE performance_schema.setup_consumers
                     SET ENABLED = IF(NAME IN (''events_statements_current'', ''events_transactions_current'', ''global_instrumentation'', ''thread_instrumentation'', ''statements_digest''), ''YES'', ''NO'')';

    IF (in_verbose) THEN
        SELECT CONCAT('Resetting: setup_consumers\n', REPLACE(@query, '  ', '')) AS status;
    END IF;

    PREPARE reset_stmt FROM @query;
    EXECUTE reset_stmt;
    DEALLOCATE PREPARE reset_stmt;

    SET @query = 'DELETE
                    FROM performance_schema.setup_objects
                   WHERE NOT (OBJECT_TYPE IN (''EVENT'', ''FUNCTION'', ''PROCEDURE'', ''TABLE'', ''TRIGGER'') AND OBJECT_NAME = ''%'' 
                     AND (OBJECT_SCHEMA = ''mysql''              AND ENABLED = ''NO''  AND TIMED = ''NO'' )
                      OR (OBJECT_SCHEMA = ''performance_schema'' AND ENABLED = ''NO''  AND TIMED = ''NO'' )
                      OR (OBJECT_SCHEMA = ''information_schema'' AND ENABLED = ''NO''  AND TIMED = ''NO'' )
                      OR (OBJECT_SCHEMA = ''%''                  AND ENABLED = ''YES'' AND TIMED = ''YES''))';

    IF (in_verbose) THEN
        SELECT CONCAT('Resetting: setup_objects\n', REPLACE(@query, '  ', '')) AS status;
    END IF;

    PREPARE reset_stmt FROM @query;
    EXECUTE reset_stmt;
    DEALLOCATE PREPARE reset_stmt;

    SET @query = 'INSERT IGNORE INTO performance_schema.setup_objects
                  VALUES (''EVENT''    , ''mysql''             , ''%'', ''NO'' , ''NO'' ),
                         (''EVENT''    , ''performance_schema'', ''%'', ''NO'' , ''NO'' ),
                         (''EVENT''    , ''information_schema'', ''%'', ''NO'' , ''NO'' ),
                         (''EVENT''    , ''%''                 , ''%'', ''YES'', ''YES''),
                         (''FUNCTION'' , ''mysql''             , ''%'', ''NO'' , ''NO'' ),
                         (''FUNCTION'' , ''performance_schema'', ''%'', ''NO'' , ''NO'' ),
                         (''FUNCTION'' , ''information_schema'', ''%'', ''NO'' , ''NO'' ),
                         (''FUNCTION'' , ''%''                 , ''%'', ''YES'', ''YES''),
                         (''PROCEDURE'', ''mysql''             , ''%'', ''NO'' , ''NO'' ),
                         (''PROCEDURE'', ''performance_schema'', ''%'', ''NO'' , ''NO'' ),
                         (''PROCEDURE'', ''information_schema'', ''%'', ''NO'' , ''NO'' ),
                         (''PROCEDURE'', ''%''                 , ''%'', ''YES'', ''YES''),
                         (''TABLE''    , ''mysql''             , ''%'', ''NO'' , ''NO'' ),
                         (''TABLE''    , ''performance_schema'', ''%'', ''NO'' , ''NO'' ),
                         (''TABLE''    , ''information_schema'', ''%'', ''NO'' , ''NO'' ),
                         (''TABLE''    , ''%''                 , ''%'', ''YES'', ''YES''),
                         (''TRIGGER''  , ''mysql''             , ''%'', ''NO'' , ''NO'' ),
                         (''TRIGGER''  , ''performance_schema'', ''%'', ''NO'' , ''NO'' ),
                         (''TRIGGER''  , ''information_schema'', ''%'', ''NO'' , ''NO'' ),
                         (''TRIGGER''  , ''%''                 , ''%'', ''YES'', ''YES'')';

    IF (in_verbose) THEN
        SELECT CONCAT('Resetting: setup_objects\n', REPLACE(@query, '  ', '')) AS status;
    END IF;

    PREPARE reset_stmt FROM @query;
    EXECUTE reset_stmt;
    DEALLOCATE PREPARE reset_stmt;

    SET @query = 'UPDATE performance_schema.threads
                     SET INSTRUMENTED = ''YES''';

    IF (in_verbose) THEN
        SELECT CONCAT('Resetting: threads\n', REPLACE(@query, '  ', '')) AS status;
    END IF;

    PREPARE reset_stmt FROM @query;
    EXECUTE reset_stmt;
    DEALLOCATE PREPARE reset_stmt;
END$$

DELIMITER ;

-- Copyright (c) 2014, 2024, Oracle and/or its affiliates.
--
-- This program is free software; you can redistribute it and/or modify
-- it under the terms of the GNU General Public License as published by
-- the Free Software Foundation; version 2 of the License.
--
-- This program is distributed in the hope that it will be useful,
-- but WITHOUT ANY WARRANTY; without even the implied warranty of
-- MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
-- GNU General Public License for more details.
--
-- You should have received a copy of the GNU General Public License
-- along with this program; if not, write to the Free Software
-- Foundation, Inc., 51 Franklin St, Fifth Floor, Boston, MA 02110-1301 USA

DROP PROCEDURE IF EXISTS ps_setup_save;

DELIMITER $$

CREATE DEFINER='mysql.sys'@'localhost' PROCEDURE ps_setup_save (
        IN in_timeout INT
    )
    COMMENT '
Description
-----------

Saves the current configuration of Performance Schema, 
so that you can alter the setup for debugging purposes, 
but restore it to a previous state.

Use the companion procedure - ps_setup_reload_saved(), to 
restore the saved config.

The named lock "sys.ps_setup_save" is taken before the
current configuration is saved. If the attempt to get the named
lock times out, an error occurs.

The lock is released after the settings have been restored by
calling ps_setup_reload_saved().

Requires the SUPER privilege for "SET sql_log_bin = 0;".

Parameters
-----------

in_timeout INT
  The timeout in seconds used when trying to obtain the lock.
  A negative timeout means infinite timeout.

Example
-----------

mysql> CALL sys.ps_setup_save(-1);
Query OK, 0 rows affected (0.08 sec)

mysql> UPDATE performance_schema.setup_instruments 
    ->    SET enabled = \'YES\', timed = \'YES\';
Query OK, 547 rows affected (0.40 sec)
Rows matched: 784  Changed: 547  Warnings: 0

/* Run some tests that need more detailed instrumentation here */

mysql> CALL sys.ps_setup_reload_saved();
Query OK, 0 rows affected (0.32 sec)
'
    SQL SECURITY INVOKER
    NOT DETERMINISTIC
    MODIFIES SQL DATA
BEGIN
    DECLARE v_lock_result INT;

    SET @log_bin := @@sql_log_bin;
    SET sql_log_bin = 0;

    SELECT GET_LOCK('sys.ps_setup_save', in_timeout) INTO v_lock_result;

    IF v_lock_result THEN
        DROP TEMPORARY TABLE IF EXISTS tmp_setup_actors;
        DROP TEMPORARY TABLE IF EXISTS tmp_setup_consumers;
        DROP TEMPORARY TABLE IF EXISTS tmp_setup_instruments;
        DROP TEMPORARY TABLE IF EXISTS tmp_threads;

        CREATE TEMPORARY TABLE tmp_setup_actors SELECT * FROM performance_schema.setup_actors LIMIT 0;
        CREATE TEMPORARY TABLE tmp_setup_consumers LIKE performance_schema.setup_consumers;
        CREATE TEMPORARY TABLE tmp_setup_instruments LIKE performance_schema.setup_instruments;
        CREATE TEMPORARY TABLE tmp_threads (THREAD_ID bigint unsigned NOT NULL PRIMARY KEY, INSTRUMENTED enum('YES','NO') NOT NULL);

        INSERT INTO tmp_setup_actors SELECT * FROM performance_schema.setup_actors;
        INSERT INTO tmp_setup_consumers SELECT * FROM performance_schema.setup_consumers;
        INSERT INTO tmp_setup_instruments SELECT * FROM performance_schema.setup_instruments;
        INSERT INTO tmp_threads SELECT THREAD_ID, INSTRUMENTED FROM performance_schema.threads;
    ELSE
        SIGNAL SQLSTATE VALUE '90000'
           SET MESSAGE_TEXT = 'Could not lock the sys.ps_setup_save user lock, another thread has a saved configuration';
    END IF;

    SET sql_log_bin = @log_bin;
END$$

DELIMITER ;
-- Copyright (c) 2014, 2024, Oracle and/or its affiliates.
--
-- This program is free software; you can redistribute it and/or modify
-- it under the terms of the GNU General Public License as published by
-- the Free Software Foundation; version 2 of the License.
--
-- This program is distributed in the hope that it will be useful,
-- but WITHOUT ANY WARRANTY; without even the implied warranty of
-- MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
-- GNU General Public License for more details.
--
-- You should have received a copy of the GNU General Public License
-- along with this program; if not, write to the Free Software
-- Foundation, Inc., 51 Franklin St, Fifth Floor, Boston, MA 02110-1301 USA

DROP PROCEDURE IF EXISTS ps_setup_show_disabled;

DELIMITER $$

CREATE DEFINER='mysql.sys'@'localhost' PROCEDURE ps_setup_show_disabled (
        IN in_show_instruments BOOLEAN,
        IN in_show_threads BOOLEAN
    )
    COMMENT '
Description
-----------

Shows all currently disable Performance Schema configuration.

Disabled users is only available for MySQL 5.7.6 and later.
In earlier versions it was only possible to enable users.

Parameters
-----------

in_show_instruments (BOOLEAN):
  Whether to print disabled instruments (can print many items)

in_show_threads (BOOLEAN):
  Whether to print disabled threads

Example
-----------

mysql> CALL sys.ps_setup_show_disabled(TRUE, TRUE);
+----------------------------+
| performance_schema_enabled |
+----------------------------+
|                          1 |
+----------------------------+
1 row in set (0.00 sec)

+--------------------+
| disabled_users     |
+--------------------+
| \'mark\'@\'localhost\' |
+--------------------+
1 row in set (0.00 sec)

+-------------+----------------------+---------+-------+
| object_type | objects              | enabled | timed |
+-------------+----------------------+---------+-------+
| EVENT       | mysql.%              | NO      | NO    |
| EVENT       | performance_schema.% | NO      | NO    |
| EVENT       | information_schema.% | NO      | NO    |
| FUNCTION    | mysql.%              | NO      | NO    |
| FUNCTION    | performance_schema.% | NO      | NO    |
| FUNCTION    | information_schema.% | NO      | NO    |
| PROCEDURE   | mysql.%              | NO      | NO    |
| PROCEDURE   | performance_schema.% | NO      | NO    |
| PROCEDURE   | information_schema.% | NO      | NO    |
| TABLE       | mysql.%              | NO      | NO    |
| TABLE       | performance_schema.% | NO      | NO    |
| TABLE       | information_schema.% | NO      | NO    |
| TRIGGER     | mysql.%              | NO      | NO    |
| TRIGGER     | performance_schema.% | NO      | NO    |
| TRIGGER     | information_schema.% | NO      | NO    |
+-------------+----------------------+---------+-------+
15 rows in set (0.00 sec)

+----------------------------------+
| disabled_consumers               |
+----------------------------------+
| events_stages_current            |
| events_stages_history            |
| events_stages_history_long       |
| events_statements_history        |
| events_statements_history_long   |
| events_transactions_history      |
| events_transactions_history_long |
| events_waits_current             |
| events_waits_history             |
| events_waits_history_long        |
+----------------------------------+
10 rows in set (0.00 sec)

Empty set (0.00 sec)

+---------------------------------------------------------------------------------------+-------+
| disabled_instruments                                                                  | timed |
+---------------------------------------------------------------------------------------+-------+
| wait/synch/mutex/sql/TC_LOG_MMAP::LOCK_tc                                             | NO    |
| wait/synch/mutex/sql/LOCK_des_key_file                                                | NO    |
| wait/synch/mutex/sql/MYSQL_BIN_LOG::LOCK_commit                                       | NO    |
...
| memory/sql/servers_cache                                                              | NO    |
| memory/sql/udf_mem                                                                    | NO    |
| wait/lock/metadata/sql/mdl                                                            | NO    |
+---------------------------------------------------------------------------------------+-------+
547 rows in set (0.00 sec)

Query OK, 0 rows affected (0.01 sec)
'
    SQL SECURITY INVOKER
    NOT DETERMINISTIC
    READS SQL DATA
BEGIN
    SELECT @@performance_schema AS performance_schema_enabled;

    SELECT CONCAT('\'', user, '\'@\'', host, '\'') AS disabled_users
      FROM performance_schema.setup_actors
     WHERE enabled = 'NO'
     ORDER BY disabled_users;

    SELECT object_type,
           CONCAT(object_schema, '.', object_name) AS objects,
           enabled,
           timed
      FROM performance_schema.setup_objects
     WHERE enabled = 'NO'
     ORDER BY object_type, objects;

    SELECT name AS disabled_consumers
      FROM performance_schema.setup_consumers
     WHERE enabled = 'NO'
     ORDER BY disabled_consumers;

    IF (in_show_threads) THEN
        SELECT IF(name = 'thread/sql/one_connection', 
                  CONCAT(processlist_user, '@', processlist_host), 
                  REPLACE(name, 'thread/', '')) AS disabled_threads,
        TYPE AS thread_type
          FROM performance_schema.threads
         WHERE INSTRUMENTED = 'NO'
         ORDER BY disabled_threads;
    END IF;

    IF (in_show_instruments) THEN
        SELECT name AS disabled_instruments,
               timed
          FROM performance_schema.setup_instruments
         WHERE enabled = 'NO'
         ORDER BY disabled_instruments;
    END IF;
END$$

DELIMITER ;
-- Copyright (c) 2014, 2024, Oracle and/or its affiliates.
--
-- This program is free software; you can redistribute it and/or modify
-- it under the terms of the GNU General Public License as published by
-- the Free Software Foundation; version 2 of the License.
--
-- This program is distributed in the hope that it will be useful,
-- but WITHOUT ANY WARRANTY; without even the implied warranty of
-- MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
-- GNU General Public License for more details.
--
-- You should have received a copy of the GNU General Public License
-- along with this program; if not, write to the Free Software
-- Foundation, Inc., 51 Franklin St, Fifth Floor, Boston, MA 02110-1301 USA

DROP PROCEDURE IF EXISTS ps_setup_show_disabled_consumers;

DELIMITER $$

CREATE DEFINER='mysql.sys'@'localhost' PROCEDURE ps_setup_show_disabled_consumers ()
    COMMENT '
Description
-----------

Shows all currently disabled consumers.

Parameters
-----------

None

Example
-----------

mysql> CALL sys.ps_setup_show_disabled_consumers();

+---------------------------+
| disabled_consumers        |
+---------------------------+
| events_statements_current |
| global_instrumentation    |
| thread_instrumentation    |
| statements_digest         |
+---------------------------+
4 rows in set (0.05 sec)
'
    SQL SECURITY INVOKER
    DETERMINISTIC
    READS SQL DATA
BEGIN
    SELECT name AS disabled_consumers
      FROM performance_schema.setup_consumers
     WHERE enabled = 'NO'
     ORDER BY disabled_consumers;
END$$

DELIMITER ;
-- Copyright (c) 2014, 2024, Oracle and/or its affiliates.
--
-- This program is free software; you can redistribute it and/or modify
-- it under the terms of the GNU General Public License as published by
-- the Free Software Foundation; version 2 of the License.
--
-- This program is distributed in the hope that it will be useful,
-- but WITHOUT ANY WARRANTY; without even the implied warranty of
-- MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
-- GNU General Public License for more details.
--
-- You should have received a copy of the GNU General Public License
-- along with this program; if not, write to the Free Software
-- Foundation, Inc., 51 Franklin St, Fifth Floor, Boston, MA 02110-1301 USA

DROP PROCEDURE IF EXISTS ps_setup_show_disabled_instruments;

DELIMITER $$

CREATE DEFINER='mysql.sys'@'localhost' PROCEDURE ps_setup_show_disabled_instruments ()
    COMMENT '
Description
-----------

Shows all currently disabled instruments.

Parameters
-----------

None

Example
-----------

mysql> CALL sys.ps_setup_show_disabled_instruments();
'
    SQL SECURITY INVOKER
    DETERMINISTIC
    READS SQL DATA
BEGIN
    SELECT name AS disabled_instruments, timed
      FROM performance_schema.setup_instruments
     WHERE enabled = 'NO'
     ORDER BY disabled_instruments;
END$$

DELIMITER ;
-- Copyright (c) 2014, 2024, Oracle and/or its affiliates.
--
-- This program is free software; you can redistribute it and/or modify
-- it under the terms of the GNU General Public License as published by
-- the Free Software Foundation; version 2 of the License.
--
-- This program is distributed in the hope that it will be useful,
-- but WITHOUT ANY WARRANTY; without even the implied warranty of
-- MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
-- GNU General Public License for more details.
--
-- You should have received a copy of the GNU General Public License
-- along with this program; if not, write to the Free Software
-- Foundation, Inc., 51 Franklin St, Fifth Floor, Boston, MA 02110-1301 USA

DROP PROCEDURE IF EXISTS ps_setup_show_enabled;

DELIMITER $$

CREATE DEFINER='mysql.sys'@'localhost' PROCEDURE ps_setup_show_enabled (
        IN in_show_instruments BOOLEAN,
        IN in_show_threads BOOLEAN
    )
    COMMENT '
Description
-----------

Shows all currently enabled Performance Schema configuration.

Parameters
-----------

in_show_instruments (BOOLEAN):
  Whether to print enabled instruments (can print many items)

in_show_threads (BOOLEAN):
  Whether to print enabled threads

Example
-----------

mysql> CALL sys.ps_setup_show_enabled(TRUE, TRUE);
+----------------------------+
| performance_schema_enabled |
+----------------------------+
|                          1 |
+----------------------------+
1 row in set (0.00 sec)

+---------------+
| enabled_users |
+---------------+
| \'%\'@\'%\'       |
+---------------+
1 row in set (0.01 sec)

+-------------+---------+---------+-------+
| object_type | objects | enabled | timed |
+-------------+---------+---------+-------+
| EVENT       | %.%     | YES     | YES   |
| FUNCTION    | %.%     | YES     | YES   |
| PROCEDURE   | %.%     | YES     | YES   |
| TABLE       | %.%     | YES     | YES   |
| TRIGGER     | %.%     | YES     | YES   |
+-------------+---------+---------+-------+
5 rows in set (0.01 sec)

+---------------------------+
| enabled_consumers         |
+---------------------------+
| events_statements_current |
| global_instrumentation    |
| thread_instrumentation    |
| statements_digest         |
+---------------------------+
4 rows in set (0.05 sec)

+---------------------------------+-------------+
| enabled_threads                 | thread_type |
+---------------------------------+-------------+
| sql/main                        | BACKGROUND  |
| sql/thread_timer_notifier       | BACKGROUND  |
| innodb/io_ibuf_thread           | BACKGROUND  |
| innodb/io_log_thread            | BACKGROUND  |
| innodb/io_read_thread           | BACKGROUND  |
| innodb/io_read_thread           | BACKGROUND  |
| innodb/io_write_thread          | BACKGROUND  |
| innodb/io_write_thread          | BACKGROUND  |
| innodb/page_cleaner_thread      | BACKGROUND  |
| innodb/srv_lock_timeout_thread  | BACKGROUND  |
| innodb/srv_error_monitor_thread | BACKGROUND  |
| innodb/srv_monitor_thread       | BACKGROUND  |
| innodb/srv_master_thread        | BACKGROUND  |
| innodb/srv_purge_thread         | BACKGROUND  |
| innodb/srv_worker_thread        | BACKGROUND  |
| innodb/srv_worker_thread        | BACKGROUND  |
| innodb/srv_worker_thread        | BACKGROUND  |
| innodb/buf_dump_thread          | BACKGROUND  |
| innodb/dict_stats_thread        | BACKGROUND  |
| sql/signal_handler              | BACKGROUND  |
| sql/compress_gtid_table         | FOREGROUND  |
| root@localhost                  | FOREGROUND  |
+---------------------------------+-------------+
22 rows in set (0.01 sec)

+-------------------------------------+-------+
| enabled_instruments                 | timed |
+-------------------------------------+-------+
| wait/io/file/sql/map                | YES   |
| wait/io/file/sql/binlog             | YES   |
...
| statement/com/Error                 | YES   |
| statement/com/                      | YES   |
| idle                                | YES   |
+-------------------------------------+-------+
210 rows in set (0.08 sec)

Query OK, 0 rows affected (0.89 sec)
'
    SQL SECURITY INVOKER
    DETERMINISTIC
    READS SQL DATA
BEGIN
    SELECT @@performance_schema AS performance_schema_enabled;

    SELECT CONCAT('\'', user, '\'@\'', host, '\'') AS enabled_users
      FROM performance_schema.setup_actors
     WHERE enabled = 'YES'
     ORDER BY enabled_users;

    SELECT object_type,
           CONCAT(object_schema, '.', object_name) AS objects,
           enabled,
           timed
      FROM performance_schema.setup_objects
     WHERE enabled = 'YES'
     ORDER BY object_type, objects;

    SELECT name AS enabled_consumers
      FROM performance_schema.setup_consumers
     WHERE enabled = 'YES'
     ORDER BY enabled_consumers;

    IF (in_show_threads) THEN
        SELECT IF(name = 'thread/sql/one_connection', 
                  CONCAT(processlist_user, '@', processlist_host), 
                  REPLACE(name, 'thread/', '')) AS enabled_threads,
        TYPE AS thread_type
          FROM performance_schema.threads
         WHERE INSTRUMENTED = 'YES'
         ORDER BY enabled_threads;
    END IF;

    IF (in_show_instruments) THEN
        SELECT name AS enabled_instruments,
               timed
          FROM performance_schema.setup_instruments
         WHERE enabled = 'YES'
         ORDER BY enabled_instruments;
    END IF;
END$$

DELIMITER ;
-- Copyright (c) 2014, 2024, Oracle and/or its affiliates.
--
-- This program is free software; you can redistribute it and/or modify
-- it under the terms of the GNU General Public License as published by
-- the Free Software Foundation; version 2 of the License.
--
-- This program is distributed in the hope that it will be useful,
-- but WITHOUT ANY WARRANTY; without even the implied warranty of
-- MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
-- GNU General Public License for more details.
--
-- You should have received a copy of the GNU General Public License
-- along with this program; if not, write to the Free Software
-- Foundation, Inc., 51 Franklin St, Fifth Floor, Boston, MA 02110-1301 USA

DROP PROCEDURE IF EXISTS ps_setup_show_enabled_consumers;

DELIMITER $$

CREATE DEFINER='mysql.sys'@'localhost' PROCEDURE ps_setup_show_enabled_consumers ()
    COMMENT '
Description
-----------

Shows all currently enabled consumers.

Parameters
-----------

None

Example
-----------

mysql> CALL sys.ps_setup_show_enabled_consumers();

+---------------------------+
| enabled_consumers         |
+---------------------------+
| events_statements_current |
| global_instrumentation    |
| thread_instrumentation    |
| statements_digest         |
+---------------------------+
4 rows in set (0.05 sec)
'
    SQL SECURITY INVOKER
    DETERMINISTIC
    READS SQL DATA
BEGIN
    SELECT name AS enabled_consumers
      FROM performance_schema.setup_consumers
     WHERE enabled = 'YES'
     ORDER BY enabled_consumers;
END$$

DELIMITER ;
-- Copyright (c) 2014, 2024, Oracle and/or its affiliates.
--
-- This program is free software; you can redistribute it and/or modify
-- it under the terms of the GNU General Public License as published by
-- the Free Software Foundation; version 2 of the License.
--
-- This program is distributed in the hope that it will be useful,
-- but WITHOUT ANY WARRANTY; without even the implied warranty of
-- MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
-- GNU General Public License for more details.
--
-- You should have received a copy of the GNU General Public License
-- along with this program; if not, write to the Free Software
-- Foundation, Inc., 51 Franklin St, Fifth Floor, Boston, MA 02110-1301 USA

DROP PROCEDURE IF EXISTS ps_setup_show_enabled_instruments;

DELIMITER $$

CREATE DEFINER='mysql.sys'@'localhost' PROCEDURE ps_setup_show_enabled_instruments ()
    COMMENT '
Description
-----------

Shows all currently enabled instruments.

Parameters
-----------

None

Example
-----------

mysql> CALL sys.ps_setup_show_enabled_instruments();
'
    SQL SECURITY INVOKER
    DETERMINISTIC
    READS SQL DATA
BEGIN
    SELECT name AS enabled_instruments, timed
      FROM performance_schema.setup_instruments
     WHERE enabled = 'YES'
     ORDER BY enabled_instruments;
END$$

DELIMITER ;
-- Copyright (c) 2014, 2024, Oracle and/or its affiliates.
--
-- This program is free software; you can redistribute it and/or modify
-- it under the terms of the GNU General Public License as published by
-- the Free Software Foundation; version 2 of the License.
--
-- This program is distributed in the hope that it will be useful,
-- but WITHOUT ANY WARRANTY; without even the implied warranty of
-- MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
-- GNU General Public License for more details.
--
-- You should have received a copy of the GNU General Public License
-- along with this program; if not, write to the Free Software
-- Foundation, Inc., 51 Franklin St, Fifth Floor, Boston, MA 02110-1301 USA

DROP PROCEDURE IF EXISTS ps_truncate_all_tables;

DELIMITER $$

CREATE DEFINER='mysql.sys'@'localhost' PROCEDURE ps_truncate_all_tables (
        IN in_verbose BOOLEAN
    )
    COMMENT '
Description
-----------

Truncates all summary tables within Performance Schema, 
resetting all aggregated instrumentation as a snapshot.

Parameters
-----------

in_verbose (BOOLEAN):
  Whether to print each TRUNCATE statement before running

Example
-----------

mysql> CALL sys.ps_truncate_all_tables(false);
+---------------------+
| summary             |
+---------------------+
| Truncated 44 tables |
+---------------------+
1 row in set (0.10 sec)

Query OK, 0 rows affected (0.10 sec)
'
    SQL SECURITY INVOKER
    DETERMINISTIC
    MODIFIES SQL DATA
BEGIN
    DECLARE v_done INT DEFAULT FALSE;
    DECLARE v_total_tables INT DEFAULT 0;
    DECLARE v_ps_table VARCHAR(64);
    DECLARE ps_tables CURSOR FOR
        SELECT table_name 
          FROM INFORMATION_SCHEMA.TABLES 
         WHERE table_schema = 'performance_schema' 
           AND (table_name LIKE '%summary%' 
            OR table_name LIKE '%history%');
    DECLARE CONTINUE HANDLER FOR NOT FOUND SET v_done = TRUE;

    OPEN ps_tables;

    ps_tables_loop: LOOP
        FETCH ps_tables INTO v_ps_table;
        IF v_done THEN
          LEAVE ps_tables_loop;
        END IF;

        SET @truncate_stmt := CONCAT('TRUNCATE TABLE performance_schema.', v_ps_table);
        IF in_verbose THEN
            SELECT CONCAT('Running: ', @truncate_stmt) AS status;
        END IF;

        PREPARE truncate_stmt FROM @truncate_stmt;
        EXECUTE truncate_stmt;
        DEALLOCATE PREPARE truncate_stmt;

        SET v_total_tables = v_total_tables + 1;
    END LOOP;

    CLOSE ps_tables;

    SELECT CONCAT('Truncated ', v_total_tables, ' tables') AS summary;

END$$

DELIMITER ;
-- Copyright (c) 2015, 2024, Oracle and/or its affiliates.
-- 
-- This program is free software; you can redistribute it and/or modify
-- it under the terms of the GNU General Public License as published by
-- the Free Software Foundation; version 2 of the License.
-- 
-- This program is distributed in the hope that it will be useful,
-- but WITHOUT ANY WARRANTY; without even the implied warranty of
-- MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
-- GNU General Public License for more details.
-- 
-- You should have received a copy of the GNU General Public License
-- along with this program; if not, write to the Free Software
-- Foundation, Inc., 51 Franklin St, Fifth Floor, Boston, MA 02110-1301 USA

DROP PROCEDURE IF EXISTS statement_performance_analyzer;

DELIMITER $$

CREATE DEFINER='mysql.sys'@'localhost' PROCEDURE statement_performance_analyzer (
        IN in_action ENUM('snapshot', 'overall', 'delta', 'create_table', 'create_tmp', 'save', 'cleanup'),
        IN in_table VARCHAR(129),
        IN in_views SET ('with_runtimes_in_95th_percentile', 'analysis', 'with_errors_or_warnings', 'with_full_table_scans', 'with_sorting', 'with_temp_tables', 'custom')
    )
    COMMENT '
Description
-----------

Create a report of the statements running on the server.

The views are calculated based on the overall and/or delta activity.

Requires the SUPER privilege for "SET sql_log_bin = 0;".

Parameters
-----------

in_action (ENUM(''snapshot'', ''overall'', ''delta'', ''create_tmp'', ''create_table'', ''save'', ''cleanup'')):
  The action to take. Supported actions are:
    * snapshot      Store a snapshot. The default is to make a snapshot of the current content of
                    performance_schema.events_statements_summary_by_digest, but by setting in_table
                    this can be overwritten to copy the content of the specified table.
                    The snapshot is stored in the sys.tmp_digests temporary table.
    * overall       Generate analyzis based on the content specified by in_table. For the overall analyzis,
                    in_table can be NOW() to use a fresh snapshot. This will overwrite an existing snapshot.
                    Use NULL for in_table to use the existing snapshot. If in_table IS NULL and no snapshot
                    exists, a new will be created.
                    See also in_views and @sys.statement_performance_analyzer.limit.
    * delta         Generate a delta analysis. The delta will be calculated between the reference table in
                    in_table and the snapshot. An existing snapshot must exist.
                    The action uses the sys.tmp_digests_delta temporary table.
                    See also in_views and @sys.statement_performance_analyzer.limit.
    * create_table  Create a regular table suitable for storing the snapshot for later use, e.g. for
                    calculating deltas.
    * create_tmp    Create a temporary table suitable for storing the snapshot for later use, e.g. for
                    calculating deltas.
    * save          Save the snapshot in the table specified by in_table. The table must exists and have
                    the correct structure.
                    If no snapshot exists, a new is created.
    * cleanup       Remove the temporary tables used for the snapshot and delta.

in_table (VARCHAR(129)):
  The table argument used for some actions. Use the format ''db1.t1'' or ''t1'' without using any backticks (`)
  for quoting. Periods (.) are not supported in the database and table names.

  The meaning of the table for each action supporting the argument is:

    * snapshot      The snapshot is created based on the specified table. Set to NULL or NOW() to use
                    the current content of performance_schema.events_statements_summary_by_digest.
    * overall       The table with the content to create the overall analyzis for. The following values
                    can be used:
                      - A table name - use the content of that table.
                      - NOW()        - create a fresh snapshot and overwrite the existing snapshot.
                      - NULL         - use the last stored snapshot.
    * delta         The table name is mandatory and specified the reference view to compare the currently
                    stored snapshot against. If no snapshot exists, a new will be created.
    * create_table  The name of the regular table to create.
    * create_tmp    The name of the temporary table to create.
    * save          The name of the table to save the currently stored snapshot into.

in_views (SET (''with_runtimes_in_95th_percentile'', ''analysis'', ''with_errors_or_warnings'',
               ''with_full_table_scans'', ''with_sorting'', ''with_temp_tables'', ''custom''))
  Which views to include:

    * with_runtimes_in_95th_percentile  Based on the sys.statements_with_runtimes_in_95th_percentile view
    * analysis                          Based on the sys.statement_analysis view
    * with_errors_or_warnings           Based on the sys.statements_with_errors_or_warnings view
    * with_full_table_scans             Based on the sys.statements_with_full_table_scans view
    * with_sorting                      Based on the sys.statements_with_sorting view
    * with_temp_tables                  Based on the sys.statements_with_temp_tables view
    * custom                            Use a custom view. This view must be specified in @sys.statement_performance_analyzer.view to an existing view or a query

Default is to include all except ''custom''.


Configuration Options
----------------------

sys.statement_performance_analyzer.limit
  The maximum number of rows to include for the views that does not have a built-in limit (e.g. the 95th percentile view).
  If not set the limit is 100.

sys.statement_performance_analyzer.view
  Used together with the ''custom'' view. If the value contains a space, it is considered a query, otherwise it must be
  an existing view querying the performance_schema.events_statements_summary_by_digest table. There cannot be any limit
  clause including in the query or view definition if @sys.statement_performance_analyzer.limit > 0.
  If specifying a view, use the same format as for in_table.

sys.debug
  Whether to provide debugging output.
  Default is ''OFF''. Set to ''ON'' to include.


Example
--------

To create a report with the queries in the 95th percentile since last truncate of performance_schema.events_statements_summary_by_digest
and the delta for a 1 minute period:

   1. Create a temporary table to store the initial snapshot.
   2. Create the initial snapshot.
   3. Save the initial snapshot in the temporary table.
   4. Wait one minute.
   5. Create a new snapshot.
   6. Perform analyzis based on the new snapshot.
   7. Perform analyzis based on the delta between the initial and new snapshots.

mysql> CALL sys.statement_performance_analyzer(''create_tmp'', ''mydb.tmp_digests_ini'', NULL);
Query OK, 0 rows affected (0.08 sec)

mysql> CALL sys.statement_performance_analyzer(''snapshot'', NULL, NULL);
Query OK, 0 rows affected (0.02 sec)

mysql> CALL sys.statement_performance_analyzer(''save'', ''mydb.tmp_digests_ini'', NULL);
Query OK, 0 rows affected (0.00 sec)

mysql> DO SLEEP(60);
Query OK, 0 rows affected (1 min 0.00 sec)

mysql> CALL sys.statement_performance_analyzer(''snapshot'', NULL, NULL);
Query OK, 0 rows affected (0.02 sec)

mysql> CALL sys.statement_performance_analyzer(''overall'', NULL, ''with_runtimes_in_95th_percentile'');
+-----------------------------------------+
| Next Output                             |
+-----------------------------------------+
| Queries with Runtime in 95th Percentile |
+-----------------------------------------+
1 row in set (0.05 sec)

...

mysql> CALL sys.statement_performance_analyzer(''delta'', ''mydb.tmp_digests_ini'', ''with_runtimes_in_95th_percentile'');
+-----------------------------------------+
| Next Output                             |
+-----------------------------------------+
| Queries with Runtime in 95th Percentile |
+-----------------------------------------+
1 row in set (0.03 sec)

...


To create an overall report of the 95th percentile queries and the top 10 queries with full table scans:

mysql> CALL sys.statement_performance_analyzer(''snapshot'', NULL, NULL);
Query OK, 0 rows affected (0.01 sec)

mysql> SET @sys.statement_performance_analyzer.limit = 10;
Query OK, 0 rows affected (0.00 sec)

mysql> CALL sys.statement_performance_analyzer(''overall'', NULL, ''with_runtimes_in_95th_percentile,with_full_table_scans'');
+-----------------------------------------+
| Next Output                             |
+-----------------------------------------+
| Queries with Runtime in 95th Percentile |
+-----------------------------------------+
1 row in set (0.01 sec)

...

+-------------------------------------+
| Next Output                         |
+-------------------------------------+
| Top 10 Queries with Full Table Scan |
+-------------------------------------+
1 row in set (0.09 sec)

...


Use a custom view showing the top 10 query sorted by total execution time refreshing the view every minute using
the watch command in Linux.

mysql> CREATE OR REPLACE VIEW mydb.my_statements AS
    -> SELECT sys.format_statement(DIGEST_TEXT) AS query,
    ->        SCHEMA_NAME AS db,
    ->        COUNT_STAR AS exec_count,
    ->        format_pico_time(SUM_TIMER_WAIT) AS total_latency,
    ->        format_pico_time(AVG_TIMER_WAIT) AS avg_latency,
    ->        ROUND(IFNULL(SUM_ROWS_SENT / NULLIF(COUNT_STAR, 0), 0)) AS rows_sent_avg,
    ->        ROUND(IFNULL(SUM_ROWS_EXAMINED / NULLIF(COUNT_STAR, 0), 0)) AS rows_examined_avg,
    ->        ROUND(IFNULL(SUM_ROWS_AFFECTED / NULLIF(COUNT_STAR, 0), 0)) AS rows_affected_avg,
    ->        DIGEST AS digest
    ->   FROM performance_schema.events_statements_summary_by_digest
    -> ORDER BY SUM_TIMER_WAIT DESC;
Query OK, 0 rows affected (0.01 sec)

mysql> CALL sys.statement_performance_analyzer(''create_table'', ''mydb.digests_prev'', NULL);
Query OK, 0 rows affected (0.10 sec)

shell$ watch -n 60 "mysql sys --table -e \"
> SET @sys.statement_performance_analyzer.view = ''mydb.my_statements'';
> SET @sys.statement_performance_analyzer.limit = 10;
> CALL statement_performance_analyzer(''snapshot'', NULL, NULL);
> CALL statement_performance_analyzer(''delta'', ''mydb.digests_prev'', ''custom'');
> CALL statement_performance_analyzer(''save'', ''mydb.digests_prev'', NULL);
> \""

Every 60.0s: mysql sys --table -e "                                                                                                   ...  Mon Dec 22 10:58:51 2014

+----------------------------------+
| Next Output                      |
+----------------------------------+
| Top 10 Queries Using Custom View |
+----------------------------------+
+-------------------+-------+------------+---------------+-------------+---------------+-------------------+-------------------+----------------------------------+
| query             | db    | exec_count | total_latency | avg_latency | rows_sent_avg | rows_examined_avg | rows_affected_avg | digest                           |
+-------------------+-------+------------+---------------+-------------+---------------+-------------------+-------------------+----------------------------------+
...
'
    SQL SECURITY INVOKER
    NOT DETERMINISTIC
    CONTAINS SQL
BEGIN
    DECLARE v_table_exists, v_tmp_digests_table_exists, v_custom_view_exists ENUM('', 'BASE TABLE', 'VIEW', 'TEMPORARY') DEFAULT '';
    DECLARE v_this_thread_enabled ENUM('YES', 'NO');
    DECLARE v_force_new_snapshot BOOLEAN DEFAULT FALSE;
    DECLARE v_digests_table VARCHAR(133);
    DECLARE v_quoted_table, v_quoted_custom_view VARCHAR(133) DEFAULT '';
    DECLARE v_table_db, v_table_name, v_custom_db, v_custom_name VARCHAR(64);
    DECLARE v_digest_table_template, v_checksum_ref, v_checksum_table text;
    DECLARE v_sql longtext;
    -- Maximum supported length for MESSAGE_TEXT with the SIGNAL command is 128 chars.
    DECLARE v_error_msg VARCHAR(128);
    DECLARE v_old_group_concat_max_len INT UNSIGNED DEFAULT 0;


    -- Don't instrument this thread
    SELECT INSTRUMENTED INTO v_this_thread_enabled FROM performance_schema.threads WHERE PROCESSLIST_ID = CONNECTION_ID();
    IF (v_this_thread_enabled = 'YES') THEN
        CALL sys.ps_setup_disable_thread(CONNECTION_ID());
    END IF;

    -- Temporary table are used - disable sql_log_bin if necessary to prevent them replicating
    SET @log_bin := @@sql_log_bin;
    IF ((@log_bin = 1) AND (@@binlog_format = 'STATEMENT')) THEN
        SET sql_log_bin = 0;
    END IF;


    -- Set configuration options
    IF (@sys.statement_performance_analyzer.limit IS NULL) THEN
        SET @sys.statement_performance_analyzer.limit = sys.sys_get_config('statement_performance_analyzer.limit', '100');
    END IF;
    IF (@sys.debug IS NULL) THEN
        SET @sys.debug                                = sys.sys_get_config('debug'                               , 'OFF');
    END IF;


    -- If in_table is set, break in_table into a db and table component and check whether it exists
    -- in_table = NOW() is considered like it's not set.
    IF (in_table = 'NOW()') THEN
        SET v_force_new_snapshot = TRUE,
            in_table             = NULL;
    ELSEIF (in_table IS NOT NULL) THEN
        IF (NOT INSTR(in_table, '.')) THEN
            -- No . in the table name - use current database
            -- DATABASE() will be the database of the procedure
            SET v_table_db   = DATABASE(),
                v_table_name = in_table;
        ELSE
            SET v_table_db   = SUBSTRING_INDEX(in_table, '.', 1);
            SET v_table_name = SUBSTRING(in_table, CHAR_LENGTH(v_table_db)+2);
        END IF;

        SET v_quoted_table = CONCAT('`', v_table_db, '`.`', v_table_name, '`');

        IF (@sys.debug = 'ON') THEN
            SELECT CONCAT('in_table is: db = ''', v_table_db, ''', table = ''', v_table_name, '''') AS 'Debug';
        END IF;

        IF (v_table_db = DATABASE() AND (v_table_name = 'tmp_digests' OR v_table_name = 'tmp_digests_delta')) THEN
            SET v_error_msg = CONCAT('Invalid value for in_table: ', v_quoted_table, ' is reserved table name.');
            SIGNAL SQLSTATE '45000'
               SET MESSAGE_TEXT = v_error_msg;
        END IF;

        CALL sys.table_exists(v_table_db, v_table_name, v_table_exists);
        IF (@sys.debug = 'ON') THEN
            SELECT CONCAT('v_table_exists = ', v_table_exists) AS 'Debug';
        END IF;

        IF (v_table_exists = 'BASE TABLE') THEN
            SET v_old_group_concat_max_len = @@session.group_concat_max_len;
            SET @@session.group_concat_max_len = 2048;
            -- Verify that the table has the correct table definition
            -- This can only be done for base tables as temporary aren't in information_schema.COLUMNS.
            -- This also minimises the risk of using a production table.
            SET v_checksum_ref = (
                 SELECT GROUP_CONCAT(CONCAT(COLUMN_NAME, COLUMN_TYPE) ORDER BY ORDINAL_POSITION) AS Checksum
                   FROM information_schema.COLUMNS
                  WHERE TABLE_SCHEMA = 'performance_schema' AND TABLE_NAME = 'events_statements_summary_by_digest'
                ),
                v_checksum_table = (
                 SELECT GROUP_CONCAT(CONCAT(COLUMN_NAME, COLUMN_TYPE) ORDER BY ORDINAL_POSITION) AS Checksum
                   FROM information_schema.COLUMNS
                  WHERE TABLE_SCHEMA = v_table_db AND TABLE_NAME = v_table_name
                );
            SET @@session.group_concat_max_len = v_old_group_concat_max_len;
            IF (v_checksum_ref <> v_checksum_table) THEN
                -- The table does not have the correct definition, so abandon
                SET v_error_msg = CONCAT('The table ',
                                         IF(CHAR_LENGTH(v_quoted_table) > 93, CONCAT('...', SUBSTRING(v_quoted_table, -90)), v_quoted_table),
                                         ' has the wrong definition.');
                SIGNAL SQLSTATE '45000'
                   SET MESSAGE_TEXT = v_error_msg;
            END IF;
        END IF;
    END IF;


    IF (in_views IS NULL OR in_views = '') THEN
        -- Set to default
        SET in_views = 'with_runtimes_in_95th_percentile,analysis,with_errors_or_warnings,with_full_table_scans,with_sorting,with_temp_tables';
    END IF;


    -- Validate settings
    CALL sys.table_exists(DATABASE(), 'tmp_digests', v_tmp_digests_table_exists);
    IF (@sys.debug = 'ON') THEN
        SELECT CONCAT('v_tmp_digests_table_exists = ', v_tmp_digests_table_exists) AS 'Debug';
    END IF;

    CASE
        WHEN in_action IN ('snapshot', 'overall') THEN
            -- in_table must be NULL, NOW(), or an existing table
            IF (in_table IS NOT NULL) THEN
                IF (NOT v_table_exists IN ('TEMPORARY', 'BASE TABLE')) THEN
                    SET v_error_msg = CONCAT('The ', in_action, ' action requires in_table to be NULL, NOW() or specify an existing table.',
                                             ' The table ',
                                             IF(CHAR_LENGTH(v_quoted_table) > 16, CONCAT('...', SUBSTRING(v_quoted_table, -13)), v_quoted_table),
                                             ' does not exist.');
                    SIGNAL SQLSTATE '45000'
                       SET MESSAGE_TEXT = v_error_msg;
                END IF;
            END IF;

        WHEN in_action IN ('delta', 'save') THEN
            -- in_table must be an existing table
            IF (v_table_exists NOT IN ('TEMPORARY', 'BASE TABLE')) THEN
                SET v_error_msg = CONCAT('The ', in_action, ' action requires in_table to be an existing table.',
                                         IF(in_table IS NOT NULL, CONCAT(' The table ',
                                             IF(CHAR_LENGTH(v_quoted_table) > 39, CONCAT('...', SUBSTRING(v_quoted_table, -36)), v_quoted_table),
                                             ' does not exist.'), ''));
                SIGNAL SQLSTATE '45000'
                   SET MESSAGE_TEXT = v_error_msg;
            END IF;

            IF (in_action = 'delta' AND v_tmp_digests_table_exists <> 'TEMPORARY') THEN
                SIGNAL SQLSTATE '45000'
                   SET MESSAGE_TEXT = 'An existing snapshot generated with the statement_performance_analyzer() must exist.';
            END IF;
        WHEN in_action = 'create_tmp' THEN
            -- in_table must not exists as a temporary table
            IF (v_table_exists = 'TEMPORARY') THEN
                SET v_error_msg = CONCAT('Cannot create the table ',
                                         IF(CHAR_LENGTH(v_quoted_table) > 72, CONCAT('...', SUBSTRING(v_quoted_table, -69)), v_quoted_table),
                                         ' as it already exists.');
                SIGNAL SQLSTATE '45000'
                   SET MESSAGE_TEXT = v_error_msg;
            END IF;

        WHEN in_action = 'create_table' THEN
            -- in_table must not exists at all
            IF (v_table_exists <> '') THEN
                SET v_error_msg = CONCAT('Cannot create the table ',
                                         IF(CHAR_LENGTH(v_quoted_table) > 52, CONCAT('...', SUBSTRING(v_quoted_table, -49)), v_quoted_table),
                                         ' as it already exists',
                                         IF(v_table_exists = 'TEMPORARY', ' as a temporary table.', '.'));
                SIGNAL SQLSTATE '45000'
                   SET MESSAGE_TEXT = v_error_msg;
            END IF;

        WHEN in_action = 'cleanup' THEN
            -- doesn't use any of the arguments
            DO (SELECT 1);
        ELSE
            SIGNAL SQLSTATE '45000'
               SET MESSAGE_TEXT = 'Unknown action. Supported actions are: cleanup, create_table, create_tmp, delta, overall, save, snapshot';
    END CASE;

    SET v_digest_table_template = 'CREATE %{TEMPORARY}TABLE %{TABLE_NAME} (
  `SCHEMA_NAME` varchar(64) DEFAULT NULL,
  `DIGEST` varchar(64) DEFAULT NULL,
  `DIGEST_TEXT` longtext,
  `COUNT_STAR` bigint unsigned NOT NULL,
  `SUM_TIMER_WAIT` bigint unsigned NOT NULL,
  `MIN_TIMER_WAIT` bigint unsigned NOT NULL,
  `AVG_TIMER_WAIT` bigint unsigned NOT NULL,
  `MAX_TIMER_WAIT` bigint unsigned NOT NULL,
  `SUM_LOCK_TIME` bigint unsigned NOT NULL,
  `SUM_ERRORS` bigint unsigned NOT NULL,
  `SUM_WARNINGS` bigint unsigned NOT NULL,
  `SUM_ROWS_AFFECTED` bigint unsigned NOT NULL,
  `SUM_ROWS_SENT` bigint unsigned NOT NULL,
  `SUM_ROWS_EXAMINED` bigint unsigned NOT NULL,
  `SUM_CREATED_TMP_DISK_TABLES` bigint unsigned NOT NULL,
  `SUM_CREATED_TMP_TABLES` bigint unsigned NOT NULL,
  `SUM_SELECT_FULL_JOIN` bigint unsigned NOT NULL,
  `SUM_SELECT_FULL_RANGE_JOIN` bigint unsigned NOT NULL,
  `SUM_SELECT_RANGE` bigint unsigned NOT NULL,
  `SUM_SELECT_RANGE_CHECK` bigint unsigned NOT NULL,
  `SUM_SELECT_SCAN` bigint unsigned NOT NULL,
  `SUM_SORT_MERGE_PASSES` bigint unsigned NOT NULL,
  `SUM_SORT_RANGE` bigint unsigned NOT NULL,
  `SUM_SORT_ROWS` bigint unsigned NOT NULL,
  `SUM_SORT_SCAN` bigint unsigned NOT NULL,
  `SUM_NO_INDEX_USED` bigint unsigned NOT NULL,
  `SUM_NO_GOOD_INDEX_USED` bigint unsigned NOT NULL,
  `SUM_CPU_TIME` bigint unsigned NOT NULL,
  `MAX_CONTROLLED_MEMORY` bigint unsigned NOT NULL,
  `MAX_TOTAL_MEMORY` bigint unsigned NOT NULL,
  `COUNT_SECONDARY` bigint unsigned NOT NULL,
  `FIRST_SEEN` timestamp(6) NULL DEFAULT NULL,
  `LAST_SEEN` timestamp(6) NULL DEFAULT NULL,
  `QUANTILE_95` bigint unsigned NOT NULL,
  `QUANTILE_99` bigint unsigned NOT NULL,
  `QUANTILE_999` bigint unsigned NOT NULL,
  `QUERY_SAMPLE_TEXT` longtext,
  `QUERY_SAMPLE_SEEN` timestamp(6) NULL DEFAULT NULL,
  `QUERY_SAMPLE_TIMER_WAIT` bigint unsigned NOT NULL,
  INDEX (SCHEMA_NAME, DIGEST)
) DEFAULT CHARSET=utf8mb4';

    -- Do the action
    -- The actions snapshot, ... requires a fresh snapshot - create it now
    IF (v_force_new_snapshot
           OR in_action = 'snapshot'
           OR (in_action = 'overall' AND in_table IS NULL)
           OR (in_action = 'save' AND v_tmp_digests_table_exists <> 'TEMPORARY')
       ) THEN
        IF (v_tmp_digests_table_exists = 'TEMPORARY') THEN
            IF (@sys.debug = 'ON') THEN
                SELECT 'DROP TEMPORARY TABLE IF EXISTS tmp_digests' AS 'Debug';
            END IF;
            DROP TEMPORARY TABLE IF EXISTS tmp_digests;
        END IF;
        CALL sys.execute_prepared_stmt(REPLACE(REPLACE(v_digest_table_template, '%{TEMPORARY}', 'TEMPORARY '), '%{TABLE_NAME}', 'tmp_digests'));

        SET v_sql = CONCAT('INSERT INTO tmp_digests SELECT * FROM ',
                           IF(in_table IS NULL OR in_action = 'save', 'performance_schema.events_statements_summary_by_digest', v_quoted_table));
        CALL sys.execute_prepared_stmt(v_sql);
    END IF;

    -- Go through the remaining actions
    IF (in_action IN ('create_table', 'create_tmp')) THEN
        IF (in_action = 'create_table') THEN
            CALL sys.execute_prepared_stmt(REPLACE(REPLACE(v_digest_table_template, '%{TEMPORARY}', ''), '%{TABLE_NAME}', v_quoted_table));
        ELSE
            CALL sys.execute_prepared_stmt(REPLACE(REPLACE(v_digest_table_template, '%{TEMPORARY}', 'TEMPORARY '), '%{TABLE_NAME}', v_quoted_table));
        END IF;
    ELSEIF (in_action = 'save') THEN
        CALL sys.execute_prepared_stmt(CONCAT('DELETE FROM ', v_quoted_table));
        CALL sys.execute_prepared_stmt(CONCAT('INSERT INTO ', v_quoted_table, ' SELECT * FROM tmp_digests'));
    ELSEIF (in_action = 'cleanup') THEN
        DROP TEMPORARY TABLE IF EXISTS sys.tmp_digests;
        DROP TEMPORARY TABLE IF EXISTS sys.tmp_digests_delta;
    ELSEIF (in_action IN ('overall', 'delta')) THEN
        -- These are almost the same - for delta calculate the delta in tmp_digests_delta and use that instead of tmp_digests.
        -- And overall allows overriding the table to use.
        IF (in_action = 'overall') THEN
            IF (in_table IS NULL) THEN
                SET v_digests_table = 'tmp_digests';
            ELSE
                SET v_digests_table = v_quoted_table;
            END IF;
        ELSE
            SET v_digests_table = 'tmp_digests_delta';
            DROP TEMPORARY TABLE IF EXISTS tmp_digests_delta;
            CREATE TEMPORARY TABLE tmp_digests_delta LIKE tmp_digests;
            SET v_sql = CONCAT('INSERT INTO tmp_digests_delta
SELECT `d_end`.`SCHEMA_NAME`,
       `d_end`.`DIGEST`,
       `d_end`.`DIGEST_TEXT`,
       `d_end`.`COUNT_STAR`-IFNULL(`d_start`.`COUNT_STAR`, 0) AS ''COUNT_STAR'',
       `d_end`.`SUM_TIMER_WAIT`-IFNULL(`d_start`.`SUM_TIMER_WAIT`, 0) AS ''SUM_TIMER_WAIT'',
       `d_end`.`MIN_TIMER_WAIT` AS ''MIN_TIMER_WAIT'',
       IFNULL((`d_end`.`SUM_TIMER_WAIT`-IFNULL(`d_start`.`SUM_TIMER_WAIT`, 0))/NULLIF(`d_end`.`COUNT_STAR`-IFNULL(`d_start`.`COUNT_STAR`, 0), 0), 0) AS ''AVG_TIMER_WAIT'',
       `d_end`.`MAX_TIMER_WAIT` AS ''MAX_TIMER_WAIT'',
       `d_end`.`SUM_LOCK_TIME`-IFNULL(`d_start`.`SUM_LOCK_TIME`, 0) AS ''SUM_LOCK_TIME'',
       `d_end`.`SUM_ERRORS`-IFNULL(`d_start`.`SUM_ERRORS`, 0) AS ''SUM_ERRORS'',
       `d_end`.`SUM_WARNINGS`-IFNULL(`d_start`.`SUM_WARNINGS`, 0) AS ''SUM_WARNINGS'',
       `d_end`.`SUM_ROWS_AFFECTED`-IFNULL(`d_start`.`SUM_ROWS_AFFECTED`, 0) AS ''SUM_ROWS_AFFECTED'',
       `d_end`.`SUM_ROWS_SENT`-IFNULL(`d_start`.`SUM_ROWS_SENT`, 0) AS ''SUM_ROWS_SENT'',
       `d_end`.`SUM_ROWS_EXAMINED`-IFNULL(`d_start`.`SUM_ROWS_EXAMINED`, 0) AS ''SUM_ROWS_EXAMINED'',
       `d_end`.`SUM_CREATED_TMP_DISK_TABLES`-IFNULL(`d_start`.`SUM_CREATED_TMP_DISK_TABLES`, 0) AS ''SUM_CREATED_TMP_DISK_TABLES'',
       `d_end`.`SUM_CREATED_TMP_TABLES`-IFNULL(`d_start`.`SUM_CREATED_TMP_TABLES`, 0) AS ''SUM_CREATED_TMP_TABLES'',
       `d_end`.`SUM_SELECT_FULL_JOIN`-IFNULL(`d_start`.`SUM_SELECT_FULL_JOIN`, 0) AS ''SUM_SELECT_FULL_JOIN'',
       `d_end`.`SUM_SELECT_FULL_RANGE_JOIN`-IFNULL(`d_start`.`SUM_SELECT_FULL_RANGE_JOIN`, 0) AS ''SUM_SELECT_FULL_RANGE_JOIN'',
       `d_end`.`SUM_SELECT_RANGE`-IFNULL(`d_start`.`SUM_SELECT_RANGE`, 0) AS ''SUM_SELECT_RANGE'',
       `d_end`.`SUM_SELECT_RANGE_CHECK`-IFNULL(`d_start`.`SUM_SELECT_RANGE_CHECK`, 0) AS ''SUM_SELECT_RANGE_CHECK'',
       `d_end`.`SUM_SELECT_SCAN`-IFNULL(`d_start`.`SUM_SELECT_SCAN`, 0) AS ''SUM_SELECT_SCAN'',
       `d_end`.`SUM_SORT_MERGE_PASSES`-IFNULL(`d_start`.`SUM_SORT_MERGE_PASSES`, 0) AS ''SUM_SORT_MERGE_PASSES'',
       `d_end`.`SUM_SORT_RANGE`-IFNULL(`d_start`.`SUM_SORT_RANGE`, 0) AS ''SUM_SORT_RANGE'',
       `d_end`.`SUM_SORT_ROWS`-IFNULL(`d_start`.`SUM_SORT_ROWS`, 0) AS ''SUM_SORT_ROWS'',
       `d_end`.`SUM_SORT_SCAN`-IFNULL(`d_start`.`SUM_SORT_SCAN`, 0) AS ''SUM_SORT_SCAN'',
       `d_end`.`SUM_NO_INDEX_USED`-IFNULL(`d_start`.`SUM_NO_INDEX_USED`, 0) AS ''SUM_NO_INDEX_USED'',
       `d_end`.`SUM_NO_GOOD_INDEX_USED`-IFNULL(`d_start`.`SUM_NO_GOOD_INDEX_USED`, 0) AS ''SUM_NO_GOOD_INDEX_USED'',
       `d_end`.`SUM_CPU_TIME`-IFNULL(`d_start`.`SUM_CPU_TIME`, 0) AS ''SUM_CPU_TIME'',
       `d_end`.`MAX_CONTROLLED_MEMORY` AS ''MAX_CONTROLLED_MEMORY'',
       `d_end`.`MAX_TOTAL_MEMORY` AS ''MAX_TOTAL_MEMORY'',
       `d_end`.`COUNT_SECONDARY`-IFNULL(`d_start`.`COUNT_SECONDARY`, 0) AS ''COUNT_SECONDARY'',
       `d_end`.`FIRST_SEEN`,
       `d_end`.`LAST_SEEN`,
       `d_end`.`QUANTILE_95`,
       `d_end`.`QUANTILE_99`,
       `d_end`.`QUANTILE_999`,
       `d_end`.`QUERY_SAMPLE_TEXT`,
       `d_end`.`QUERY_SAMPLE_SEEN`,
       `d_end`.`QUERY_SAMPLE_TIMER_WAIT`
  FROM tmp_digests d_end
       LEFT OUTER JOIN ', v_quoted_table, ' d_start ON `d_start`.`DIGEST` = `d_end`.`DIGEST`
                                                    AND (`d_start`.`SCHEMA_NAME` = `d_end`.`SCHEMA_NAME`
                                                          OR (`d_start`.`SCHEMA_NAME` IS NULL AND `d_end`.`SCHEMA_NAME` IS NULL)
                                                        )
 WHERE `d_end`.`COUNT_STAR`-IFNULL(`d_start`.`COUNT_STAR`, 0) > 0');
            CALL sys.execute_prepared_stmt(v_sql);
        END IF;

        IF (FIND_IN_SET('with_runtimes_in_95th_percentile', in_views)) THEN
            SELECT 'Queries with Runtime in 95th Percentile' AS 'Next Output';

            DROP TEMPORARY TABLE IF EXISTS tmp_digest_avg_latency_distribution1;
            DROP TEMPORARY TABLE IF EXISTS tmp_digest_avg_latency_distribution2;
            DROP TEMPORARY TABLE IF EXISTS tmp_digest_95th_percentile_by_avg_us;

            CREATE TEMPORARY TABLE tmp_digest_avg_latency_distribution1 (
              cnt bigint unsigned NOT NULL,
              avg_us decimal(21,0) NOT NULL,
              PRIMARY KEY (avg_us)
            ) ENGINE=InnoDB;

            SET v_sql = CONCAT('INSERT INTO tmp_digest_avg_latency_distribution1
SELECT COUNT(*) cnt,
       ROUND(avg_timer_wait/1000000) AS avg_us
  FROM ', v_digests_table, '
 GROUP BY avg_us');
            CALL sys.execute_prepared_stmt(v_sql);

            CREATE TEMPORARY TABLE tmp_digest_avg_latency_distribution2 LIKE tmp_digest_avg_latency_distribution1;
            INSERT INTO tmp_digest_avg_latency_distribution2 SELECT * FROM tmp_digest_avg_latency_distribution1;

            CREATE TEMPORARY TABLE tmp_digest_95th_percentile_by_avg_us (
              avg_us decimal(21,0) NOT NULL,
              percentile decimal(46,4) NOT NULL,
              PRIMARY KEY (avg_us)
            ) ENGINE=InnoDB;

            SET v_sql = CONCAT('INSERT INTO tmp_digest_95th_percentile_by_avg_us
SELECT s2.avg_us avg_us,
       IFNULL(SUM(s1.cnt)/NULLIF((SELECT COUNT(*) FROM ', v_digests_table, '), 0), 0) percentile
  FROM tmp_digest_avg_latency_distribution1 AS s1
       JOIN tmp_digest_avg_latency_distribution2 AS s2 ON s1.avg_us <= s2.avg_us
 GROUP BY s2.avg_us
HAVING percentile > 0.95
 ORDER BY percentile
 LIMIT 1');
            CALL sys.execute_prepared_stmt(v_sql);

            SET v_sql =
                REPLACE(
                    REPLACE(
                        (SELECT VIEW_DEFINITION
                           FROM information_schema.VIEWS
                          WHERE TABLE_SCHEMA = DATABASE() AND TABLE_NAME = 'statements_with_runtimes_in_95th_percentile'
                        ),
                        '`performance_schema`.`events_statements_summary_by_digest`',
                        v_digests_table
                    ),
                    'sys.x$ps_digest_95th_percentile_by_avg_us',
                    '`sys`.`x$ps_digest_95th_percentile_by_avg_us`'
              );
            CALL sys.execute_prepared_stmt(v_sql);

            DROP TEMPORARY TABLE tmp_digest_avg_latency_distribution1;
            DROP TEMPORARY TABLE tmp_digest_avg_latency_distribution2;
            DROP TEMPORARY TABLE tmp_digest_95th_percentile_by_avg_us;
        END IF;

        IF (FIND_IN_SET('analysis', in_views)) THEN
            SELECT CONCAT('Top ', @sys.statement_performance_analyzer.limit, ' Queries Ordered by Total Latency') AS 'Next Output';
            SET v_sql =
                REPLACE(
                    (SELECT VIEW_DEFINITION
                       FROM information_schema.VIEWS
                      WHERE TABLE_SCHEMA = DATABASE() AND TABLE_NAME = 'statement_analysis'
                    ),
                    '`performance_schema`.`events_statements_summary_by_digest`',
                    v_digests_table
                );
            IF (@sys.statement_performance_analyzer.limit > 0) THEN
                SET v_sql = CONCAT(v_sql, ' LIMIT ', @sys.statement_performance_analyzer.limit);
            END IF;
            CALL sys.execute_prepared_stmt(v_sql);
        END IF;

        IF (FIND_IN_SET('with_errors_or_warnings', in_views)) THEN
            SELECT CONCAT('Top ', @sys.statement_performance_analyzer.limit, ' Queries with Errors') AS 'Next Output';
            SET v_sql =
                REPLACE(
                    (SELECT VIEW_DEFINITION
                       FROM information_schema.VIEWS
                      WHERE TABLE_SCHEMA = DATABASE() AND TABLE_NAME = 'statements_with_errors_or_warnings'
                    ),
                    '`performance_schema`.`events_statements_summary_by_digest`',
                    v_digests_table
                );
            IF (@sys.statement_performance_analyzer.limit > 0) THEN
                SET v_sql = CONCAT(v_sql, ' LIMIT ', @sys.statement_performance_analyzer.limit);
            END IF;
            CALL sys.execute_prepared_stmt(v_sql);
        END IF;

        IF (FIND_IN_SET('with_full_table_scans', in_views)) THEN
            SELECT CONCAT('Top ', @sys.statement_performance_analyzer.limit, ' Queries with Full Table Scan') AS 'Next Output';
            SET v_sql =
                REPLACE(
                    (SELECT VIEW_DEFINITION
                       FROM information_schema.VIEWS
                      WHERE TABLE_SCHEMA = DATABASE() AND TABLE_NAME = 'statements_with_full_table_scans'
                    ),
                    '`performance_schema`.`events_statements_summary_by_digest`',
                    v_digests_table
                );
            IF (@sys.statement_performance_analyzer.limit > 0) THEN
                SET v_sql = CONCAT(v_sql, ' LIMIT ', @sys.statement_performance_analyzer.limit);
            END IF;
            CALL sys.execute_prepared_stmt(v_sql);
        END IF;

        IF (FIND_IN_SET('with_sorting', in_views)) THEN
            SELECT CONCAT('Top ', @sys.statement_performance_analyzer.limit, ' Queries with Sorting') AS 'Next Output';
            SET v_sql =
                REPLACE(
                    (SELECT VIEW_DEFINITION
                       FROM information_schema.VIEWS
                      WHERE TABLE_SCHEMA = DATABASE() AND TABLE_NAME = 'statements_with_sorting'
                    ),
                    '`performance_schema`.`events_statements_summary_by_digest`',
                    v_digests_table
                );
            IF (@sys.statement_performance_analyzer.limit > 0) THEN
                SET v_sql = CONCAT(v_sql, ' LIMIT ', @sys.statement_performance_analyzer.limit);
            END IF;
            CALL sys.execute_prepared_stmt(v_sql);
        END IF;

        IF (FIND_IN_SET('with_temp_tables', in_views)) THEN
            SELECT CONCAT('Top ', @sys.statement_performance_analyzer.limit, ' Queries with Internal Temporary Tables') AS 'Next Output';
            SET v_sql =
                REPLACE(
                    (SELECT VIEW_DEFINITION
                       FROM information_schema.VIEWS
                      WHERE TABLE_SCHEMA = DATABASE() AND TABLE_NAME = 'statements_with_temp_tables'
                    ),
                    '`performance_schema`.`events_statements_summary_by_digest`',
                    v_digests_table
                );
            IF (@sys.statement_performance_analyzer.limit > 0) THEN
                SET v_sql = CONCAT(v_sql, ' LIMIT ', @sys.statement_performance_analyzer.limit);
            END IF;
            CALL sys.execute_prepared_stmt(v_sql);
        END IF;

        IF (FIND_IN_SET('custom', in_views)) THEN
            SELECT CONCAT('Top ', @sys.statement_performance_analyzer.limit, ' Queries Using Custom View') AS 'Next Output';

            IF (@sys.statement_performance_analyzer.view IS NULL) THEN
                SET @sys.statement_performance_analyzer.view = sys.sys_get_config('statement_performance_analyzer.view', NULL);
            END IF;
            IF (@sys.statement_performance_analyzer.view IS NULL) THEN
                SIGNAL SQLSTATE '45000'
                   SET MESSAGE_TEXT = 'The @sys.statement_performance_analyzer.view user variable must be set with the view or query to use.';
            END IF;

            IF (NOT INSTR(@sys.statement_performance_analyzer.view, ' ')) THEN
                -- No spaces, so can't be a query
                IF (NOT INSTR(@sys.statement_performance_analyzer.view, '.')) THEN
                    -- No . in the table name - use current database
                    -- DATABASE() will be the database of the procedure
                    SET v_custom_db   = DATABASE(),
                        v_custom_name = @sys.statement_performance_analyzer.view;
                ELSE
                    SET v_custom_db   = SUBSTRING_INDEX(@sys.statement_performance_analyzer.view, '.', 1);
                    SET v_custom_name = SUBSTRING(@sys.statement_performance_analyzer.view, CHAR_LENGTH(v_custom_db)+2);
                END IF;

                CALL sys.table_exists(v_custom_db, v_custom_name, v_custom_view_exists);
                IF (v_custom_view_exists <> 'VIEW') THEN
                    SIGNAL SQLSTATE '45000'
                       SET MESSAGE_TEXT = 'The @sys.statement_performance_analyzer.view user variable is set but specified neither an existing view nor a query.';
                END IF;

                SET v_sql =
                    REPLACE(
                        (SELECT VIEW_DEFINITION
                           FROM information_schema.VIEWS
                          WHERE TABLE_SCHEMA = v_custom_db AND TABLE_NAME = v_custom_name
                        ),
                        '`performance_schema`.`events_statements_summary_by_digest`',
                        v_digests_table
                    );
            ELSE
                SET v_sql = REPLACE(@sys.statement_performance_analyzer.view, '`performance_schema`.`events_statements_summary_by_digest`', v_digests_table);
            END IF;

            IF (@sys.statement_performance_analyzer.limit > 0) THEN
                SET v_sql = CONCAT(v_sql, ' LIMIT ', @sys.statement_performance_analyzer.limit);
            END IF;

            CALL sys.execute_prepared_stmt(v_sql);
        END IF;
    END IF;

    -- Restore INSTRUMENTED for this thread
    IF (v_this_thread_enabled = 'YES') THEN
        CALL sys.ps_setup_enable_thread(CONNECTION_ID());
    END IF;

    IF ((@log_bin = 1) AND (@@binlog_format = 'STATEMENT')) THEN
        SET sql_log_bin = @log_bin;
    END IF;
END$$

DELIMITER ;
-- Copyright (c) 2015, 2024, Oracle and/or its affiliates.
-- 
-- This program is free software; you can redistribute it and/or modify
-- it under the terms of the GNU General Public License as published by
-- the Free Software Foundation; version 2 of the License.
-- 
-- This program is distributed in the hope that it will be useful,
-- but WITHOUT ANY WARRANTY; without even the implied warranty of
-- MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
-- GNU General Public License for more details.
-- 
-- You should have received a copy of the GNU General Public License
-- along with this program; if not, write to the Free Software
-- Foundation, Inc., 51 Franklin St, Fifth Floor, Boston, MA 02110-1301 USA

DROP PROCEDURE IF EXISTS table_exists;

DELIMITER $$

CREATE DEFINER='mysql.sys'@'localhost' PROCEDURE table_exists (
        IN in_db VARCHAR(64), IN in_table VARCHAR(64),
        OUT out_exists ENUM('', 'BASE TABLE', 'VIEW', 'TEMPORARY')
    )
    COMMENT '
Description
-----------

Tests whether the table specified in in_db and in_table exists either as a regular
table, or as a temporary table. The returned value corresponds to the table that
will be used, so if there''s both a temporary and a permanent table with the given
name, then ''TEMPORARY'' will be returned.

Parameters
-----------

in_db (VARCHAR(64)):
  The database name to check for the existance of the table in.

in_table (VARCHAR(64)):
  The name of the table to check the existance of.

out_exists ENUM('''', ''BASE TABLE'', ''VIEW'', ''TEMPORARY''):
  The return value: whether the table exists. The value is one of:
    * ''''           - the table does not exist neither as a base table, view, nor temporary table.
    * ''BASE TABLE'' - the table name exists as a permanent base table table.
    * ''VIEW''       - the table name exists as a view.
    * ''TEMPORARY''  - the table name exists as a temporary table.

Example
--------

mysql> CREATE DATABASE db1;
Query OK, 1 row affected (0.07 sec)

mysql> use db1;
Database changed
mysql> CREATE TABLE t1 (id INT PRIMARY KEY);
Query OK, 0 rows affected (0.08 sec)

mysql> CREATE TABLE t2 (id INT PRIMARY KEY);
Query OK, 0 rows affected (0.08 sec)

mysql> CREATE view v_t1 AS SELECT * FROM t1;
Query OK, 0 rows affected (0.00 sec)

mysql> CREATE TEMPORARY TABLE t1 (id INT PRIMARY KEY);
Query OK, 0 rows affected (0.00 sec)

mysql> CALL sys.table_exists(''db1'', ''t1'', @exists); SELECT @exists;
Query OK, 0 rows affected (0.00 sec)

+------------+
| @exists    |
+------------+
| TEMPORARY  |
+------------+
1 row in set (0.00 sec)

mysql> CALL sys.table_exists(''db1'', ''t2'', @exists); SELECT @exists;
Query OK, 0 rows affected (0.00 sec)

+------------+
| @exists    |
+------------+
| BASE TABLE |
+------------+
1 row in set (0.01 sec)

mysql> CALL sys.table_exists(''db1'', ''v_t1'', @exists); SELECT @exists;
Query OK, 0 rows affected (0.00 sec)

+---------+
| @exists |
+---------+
| VIEW    |
+---------+
1 row in set (0.00 sec)

mysql> CALL sys.table_exists(''db1'', ''t3'', @exists); SELECT @exists;
Query OK, 0 rows affected (0.01 sec)

+---------+
| @exists |
+---------+
|         |
+---------+
1 row in set (0.00 sec)
'
    SQL SECURITY INVOKER
    NOT DETERMINISTIC
    CONTAINS SQL
BEGIN
    DECLARE v_error BOOLEAN DEFAULT FALSE;
    DECLARE CONTINUE HANDLER FOR 1050 SET v_error = TRUE;
    DECLARE CONTINUE HANDLER FOR 1146 SET v_error = TRUE;

    SET out_exists = '';

    -- Verify whether the table name exists as a normal table
    IF (EXISTS(SELECT 1 FROM information_schema.TABLES WHERE TABLE_SCHEMA = in_db AND TABLE_NAME = in_table)) THEN
        -- Unfortunately the only way to determine whether there is also a temporary table is to try to create
        -- a temporary table with the same name. If it succeeds the table didn't exist as a temporary table.
        SET @sys.tmp.table_exists.SQL = CONCAT('CREATE TEMPORARY TABLE `', in_db, '`.`', in_table, '` (id INT PRIMARY KEY)');
        PREPARE stmt_create_table FROM @sys.tmp.table_exists.SQL;
        EXECUTE stmt_create_table;
        DEALLOCATE PREPARE stmt_create_table;
        IF (v_error) THEN
            SET out_exists = 'TEMPORARY';
        ELSE
            -- The temporary table was created, i.e. it didn't exist. Remove it again so we don't leave garbage around.
            SET @sys.tmp.table_exists.SQL = CONCAT('DROP TEMPORARY TABLE `', in_db, '`.`', in_table, '`');
            PREPARE stmt_drop_table FROM @sys.tmp.table_exists.SQL;
            EXECUTE stmt_drop_table;
            DEALLOCATE PREPARE stmt_drop_table;
            SET out_exists = (SELECT TABLE_TYPE FROM information_schema.TABLES WHERE TABLE_SCHEMA = in_db AND TABLE_NAME = in_table);
        END IF;
    ELSE
        -- Check whether a temporary table exists with the same name.
        -- If it does it's possible to SELECT from the table without causing an error.
        -- If it does not exist even a PREPARE using the table will fail.
        SET @sys.tmp.table_exists.SQL = CONCAT('SELECT COUNT(*) FROM `', in_db, '`.`', in_table, '`');
        PREPARE stmt_select FROM @sys.tmp.table_exists.SQL;
        IF (NOT v_error) THEN
            DEALLOCATE PREPARE stmt_select;
            SET out_exists = 'TEMPORARY';
        END IF;
    END IF;
END$$

DELIMITER ;
-- Copyright (c) 2014, 2023, Oracle and/or its affiliates.
--
-- This program is free software; you can redistribute it and/or modify
-- it under the terms of the GNU General Public License as published by
-- the Free Software Foundation; version 2 of the License.
--
-- This program is distributed in the hope that it will be useful,
-- but WITHOUT ANY WARRANTY; without even the implied warranty of
-- MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
-- GNU General Public License for more details.
--
-- You should have received a copy of the GNU General Public License
-- along with this program; if not, write to the Free Software
-- Foundation, Inc., 51 Franklin St, Fifth Floor, Boston, MA 02110-1301 USA
-- Copyright (c) 2023, Shannon Data AI and/or its affiliates.

DROP PROCEDURE IF EXISTS ml_explain_row;

DELIMITER $$

CREATE DEFINER='mysql.sys'@'localhost' PROCEDURE ml_explain_row (
    IN input_data JSON,
    IN model_handle VARCHAR(64),
    IN options JSON
)
COMMENT '
Description
-----------
Generate explanations for one or more rows of unlabeled data using a trained ML model.
This procedure limits explanations to the 100 most relevant features.

Supported Models:
- Classification
- Regression

NOT Supported Models:
- Recommendation
- Anomaly detection
- Anomaly detection for logs
- Topic modeling
- Forecasting

Parameters
-----------
input_data (JSON):
  The data to generate explanations for in JSON format.
  Column names must match the feature column names used to train the model.

model_handle (VARCHAR(64)):
  The model handle or session variable containing the model handle.

options (JSON):
  Optional parameters in JSON format:
  - "prediction_explainer": {"permutation_importance"|"shap"|NULL}
    - "permutation_importance": Default explainer
    - "shap": SHAP explainer based on Shapley values
'
SQL SECURITY INVOKER
NOT DETERMINISTIC
READS SQL DATA
BEGIN
    DECLARE v_error BOOLEAN DEFAULT FALSE;
    DECLARE v_user_name VARCHAR(64);
    DECLARE v_db_name VARCHAR(64);
    DECLARE v_model_type VARCHAR(32);
    DECLARE v_model_status VARCHAR(32);
    DECLARE v_prediction_explainer VARCHAR(64) DEFAULT 'permutation_importance';
    DECLARE v_error_msg TEXT;
    DECLARE v_schema_name VARCHAR(64);
    DECLARE v_shap_exists INT DEFAULT 0;

    DECLARE v_array_length INT DEFAULT 0;
    DECLARE v_i INT DEFAULT 0;
    DECLARE v_row_data JSON;

    DECLARE CONTINUE HANDLER FOR SQLEXCEPTION
    BEGIN
        SET v_error = TRUE;
        GET DIAGNOSTICS CONDITION 1 v_error_msg = MESSAGE_TEXT;
    END;

    -- Get current user and database
    SELECT USER() INTO v_user_name;
    SELECT DATABASE() INTO v_db_name;

    -- Extract schema name from username
    SET v_user_name = SUBSTRING_INDEX(v_user_name, '@', 1);
    SET v_schema_name = CONCAT('ML_SCHEMA_', v_user_name);

    -- Validate parameters
    IF input_data IS NULL THEN
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'input_data parameter cannot be NULL';
    END IF;

    IF model_handle IS NULL OR model_handle = '' THEN
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'model_handle parameter cannot be NULL or empty';
    END IF;

    -- Parse options
    IF options IS NOT NULL THEN
        IF JSON_VALID(options) = 0 THEN
            SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'options parameter must be valid JSON';
        END IF;

        IF JSON_EXTRACT(options, '$.prediction_explainer') IS NOT NULL THEN
            SET v_prediction_explainer = JSON_UNQUOTE(JSON_EXTRACT(options, '$.prediction_explainer'));
        END IF;

        IF v_prediction_explainer NOT IN ('permutation_importance', 'shap') THEN
            SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'prediction_explainer must be "permutation_importance" or "shap"';
        END IF;
    END IF;

    -- Check model catalog
    SET @sql_model_check = CONCAT(
        'SELECT COUNT(*) INTO @tmp_model_exists ',
        'FROM ', v_schema_name, '.MODEL_CATALOG WHERE model_handle = ?'
    );
    PREPARE stmt FROM @sql_model_check;
    SET @mh := model_handle;
    EXECUTE stmt USING @mh;
    DEALLOCATE PREPARE stmt;

    IF @tmp_model_exists = 0 THEN
        SET v_error_msg = CONCAT('Model handle not found: ', model_handle);
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = v_error_msg;
    END IF;
    SET @tmp_model_exists = NULL;

    -- Get model type and status
    SET @sql_model_info = CONCAT(
        'SELECT model_type, model_status INTO @tmp_model_type, @tmp_model_status ',
        'FROM ', v_schema_name, '.MODEL_CATALOG WHERE model_handle = ?'
    );
    PREPARE stmt FROM @sql_model_info;
    SET @mh := model_handle;
    EXECUTE stmt USING @mh;
    DEALLOCATE PREPARE stmt;

    SET v_model_type = @tmp_model_type;
    SET v_model_status = @tmp_model_status;
    SET @tmp_model_type = NULL;
    SET @tmp_model_status = NULL;

    IF v_model_status != 'READY' THEN
        SET v_error_msg = CONCAT('Model is not ready. Current status: ', v_model_status);
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = v_error_msg;
    END IF;

    IF v_model_type IN ('recommendation','anomaly_detection','topic_modeling','anomaly_detection_logs','forecasting') THEN
        SET v_error_msg = CONCAT('ML_EXPLAIN_ROW does not support ', v_model_type, ' models');
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = v_error_msg;
    END IF;

    IF JSON_VALID(input_data) = 0 THEN
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'input_data must be valid JSON';
    END IF;

    IF JSON_TYPE(input_data) = 'ARRAY' THEN
        SET v_array_length = JSON_LENGTH(input_data);
        IF v_array_length = 0 THEN
            SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'input_data array cannot be empty';
        END IF;

        SET v_i = 0;
        WHILE v_i < v_array_length DO
            SET v_row_data = JSON_EXTRACT(input_data, CONCAT('$[', v_i, ']'));
            IF JSON_VALID(v_row_data) = 0 OR JSON_LENGTH(v_row_data) = 0 THEN
                SET v_error_msg = CONCAT('Invalid or empty row at index ', v_i);
                SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = v_error_msg;
            END IF;
            SET v_i = v_i + 1;
        END WHILE;
    ELSE
        IF JSON_LENGTH(input_data) = 0 THEN
            SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'input_data cannot be empty';
        END IF;
    END IF;

    IF v_prediction_explainer = 'shap' THEN
        SET @sql_shap_check = CONCAT(
            'SELECT COUNT(*) INTO @tmp_shap ',
            'FROM ', v_schema_name, '.MODEL_EXPLAINERS ',
            'WHERE model_handle = ? AND explainer_type = ''shap'' AND status = ''READY'''
        );
        PREPARE stmt FROM @sql_shap_check;
        SET @mh := model_handle;
        EXECUTE stmt USING @mh;
        DEALLOCATE PREPARE stmt;

        SET v_shap_exists = @tmp_shap;
        SET @tmp_shap = NULL;

        IF v_shap_exists = 0 THEN
            SIGNAL SQLSTATE '45000'
            SET MESSAGE_TEXT = 'SHAP explainer not found or not ready. Please run ML_EXPLAIN with "shap" explainer first.';
        END IF;
    END IF;

    IF v_error THEN
        RESIGNAL;
    END IF;

    -- Call native function ML_EXPLAIN_ROW
    SELECT ML_EXPLAIN_ROW(input_data, model_handle, options);

END$$

DELIMITER ;-- Copyright (c) 2014, 2023, Oracle and/or its affiliates.
--
-- This program is free software; you can redistribute it and/or modify
-- it under the terms of the GNU General Public License as published by
-- the Free Software Foundation; version 2 of the License.
--
-- This program is distributed in the hope that it will be useful,
-- but WITHOUT ANY WARRANTY; without even the implied warranty of
-- MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
-- GNU General Public License for more details.
--
-- You should have received a copy of the GNU General Public License
-- along with this program; if not, write to the Free Software
-- Foundation, Inc., 51 Franklin St, Fifth Floor, Boston, MA 02110-1301 USA
-- Copyright (c) 2023, Shannon Data AI and/or its affiliates.

DROP PROCEDURE IF EXISTS ml_explain_table;

DELIMITER $$

CREATE DEFINER='mysql.sys'@'localhost' PROCEDURE ml_explain_table (
    IN table_name VARCHAR(128),
    IN model_handle VARCHAR(64), 
    IN output_table_name VARCHAR(128),
    IN options JSON
)
COMMENT '
Description
-----------
Generate explanations for an entire table of unlabeled data using a trained ML model.
This is a memory-intensive process with specific row limits based on MySQL version.

Memory and Performance Guidelines:
- MySQL 9.4.1+: Max 100 rows, 10 rows if >10 columns
- Before MySQL 9.4.1: Use batch_size option (10-100 rows)
- Limited to 100 most relevant features

Output Table Features:
- Includes primary key from input table or auto-generated _4aad19ca6e_pk_id
- Contains all original columns plus attribution columns
- Includes ml_results column with JSON explanations
- Can append extra columns not used in training

Supported Models:
- Classification
- Regression

NOT Supported Models:
- Forecasting
- Recommendation  
- Anomaly detection
- Anomaly detection for logs
- Topic modeling

Parameters
-----------
table_name (VARCHAR(128)):
  Fully qualified name of input table (schema.table_name).
  Must contain same feature columns as training table.
  Target column (if present) is ignored during explanation.

model_handle (VARCHAR(64)):
  The model handle for the trained and loaded model.

output_table_name (VARCHAR(128)):
  Fully qualified name for output table (schema.table_name).
  As of MySQL 9.4.1, can be same as input table under specific conditions.

options (JSON):
  Optional parameters in JSON format:
  - "prediction_explainer": {"permutation_importance"|"shap"}
  - "batch_size": N (deprecated in MySQL 9.4.1+)

Examples
---------
-- Basic table explanation with default explainer
CALL sys.ml_explain_table(
    "census_data.census_test", 
    @census_model, 
    "census_data.census_explanations",
    JSON_OBJECT("prediction_explainer", "permutation_importance")
);

-- With SHAP explainer (must be pre-trained)
CALL sys.ml_explain_table(
    "census_data.census_test",
    @census_model,
    "census_data.census_shap_explanations", 
    JSON_OBJECT("prediction_explainer", "shap")
);

-- With batch_size (pre MySQL 9.4.1)
CALL sys.ml_explain_table(
    "large_data.test_table",
    @model,
    "large_data.explanations",
    JSON_OBJECT("prediction_explainer", "permutation_importance", "batch_size", 50)
);
'
SQL SECURITY INVOKER
NOT DETERMINISTIC
MODIFIES SQL DATA
BEGIN
    DECLARE v_error BOOLEAN DEFAULT FALSE;
    DECLARE v_user_name VARCHAR(64);
    DECLARE v_db_name VARCHAR(64);
    DECLARE v_input_schema VARCHAR(64);
    DECLARE v_input_table VARCHAR(64);
    DECLARE v_output_schema VARCHAR(64);
    DECLARE v_output_table VARCHAR(64);
    DECLARE v_model_type VARCHAR(32);
    DECLARE v_model_status VARCHAR(32);
    DECLARE v_prediction_explainer VARCHAR(64) DEFAULT 'permutation_importance';
    DECLARE v_batch_size INT DEFAULT NULL;
    DECLARE v_error_msg TEXT;
    DECLARE v_input_table_exists INT DEFAULT 0;
    DECLARE v_output_schema_exists INT DEFAULT 0;
    DECLARE v_row_count INT DEFAULT 0;
    DECLARE v_column_count INT DEFAULT 0;
    DECLARE v_mysql_version VARCHAR(20);
    DECLARE v_has_primary_key INT DEFAULT 0;
    DECLARE v_pk_column_conflict INT DEFAULT 0;
    DECLARE v_model_exists INT DEFAULT 0;
    DECLARE v_shap_exists INT DEFAULT 0;

    DECLARE CONTINUE HANDLER FOR SQLEXCEPTION
    BEGIN
        SET v_error = TRUE;
        GET DIAGNOSTICS CONDITION 1 v_error_msg = MESSAGE_TEXT;
    END;

    -- Get current user, database and MySQL version
    SELECT USER() INTO v_user_name;
    SELECT DATABASE() INTO v_db_name;
    SELECT VERSION() INTO v_mysql_version;

    -- Validate input parameters
    IF table_name IS NULL OR table_name = '' THEN
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'table_name parameter cannot be NULL or empty';
    END IF;

    IF model_handle IS NULL OR model_handle = '' THEN
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'model_handle parameter cannot be NULL or empty';
    END IF;

    IF output_table_name IS NULL OR output_table_name = '' THEN
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'output_table_name parameter cannot be NULL or empty';
    END IF;

    -- Parse input table name
    IF LOCATE('.', table_name) > 0 THEN
        SET v_input_schema = SUBSTRING_INDEX(table_name, '.', 1);
        SET v_input_table = SUBSTRING_INDEX(table_name, '.', -1);
    ELSE
        SET v_input_schema = v_db_name;
        SET v_input_table = table_name;
    END IF;

    -- Parse output table name
    IF LOCATE('.', output_table_name) > 0 THEN
        SET v_output_schema = SUBSTRING_INDEX(output_table_name, '.', 1);
        SET v_output_table = SUBSTRING_INDEX(output_table_name, '.', -1);
    ELSE
        SET v_output_schema = v_db_name;
        SET v_output_table = output_table_name;
    END IF;

    -- Parse options if provided
    IF options IS NOT NULL THEN
        IF JSON_VALID(options) = 0 THEN
            SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'options parameter must be valid JSON';
        END IF;

        -- Extract prediction_explainer if specified
        IF JSON_EXTRACT(options, '$.prediction_explainer') IS NOT NULL THEN
            SET v_prediction_explainer = JSON_UNQUOTE(JSON_EXTRACT(options, '$.prediction_explainer'));
        END IF;

        -- Extract batch_size if specified
        IF JSON_EXTRACT(options, '$.batch_size') IS NOT NULL THEN
            SET v_batch_size = CAST(JSON_UNQUOTE(JSON_EXTRACT(options, '$.batch_size')) AS UNSIGNED);

            -- Check if batch_size is deprecated (MySQL 9.4.1+)
            IF v_mysql_version >= '9.4.1' THEN
                SELECT 'WARNING: batch_size option is deprecated in MySQL 9.4.1+. Manually limit input table to 100 rows (10 rows if >10 columns).' AS warning_message;
            END IF;

            IF v_batch_size < 1 OR v_batch_size > 100 THEN
                SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'batch_size must be between 1 and 100';
            END IF;
        END IF;

        -- Validate prediction_explainer values
        IF v_prediction_explainer NOT IN ('permutation_importance', 'shap') THEN
            SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'prediction_explainer must be "permutation_importance" or "shap"';
        END IF;
    END IF;

    -- Check if input table exists and get its properties
    SELECT COUNT(*) INTO v_input_table_exists
    FROM information_schema.TABLES
    WHERE TABLE_SCHEMA = v_input_schema
    AND TABLE_NAME = v_input_table;

    IF v_input_table_exists = 0 THEN
        SET v_error_msg = CONCAT('Input table not found: ', table_name);
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = v_error_msg;
    END IF;

    -- Check if output schema exists
    SELECT COUNT(*) INTO v_output_schema_exists
    FROM information_schema.SCHEMATA
    WHERE SCHEMA_NAME = v_output_schema;

    IF v_output_schema_exists = 0 THEN
        SET v_error_msg = CONCAT('Output schema not found: ', v_output_schema);
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = v_error_msg;
    END IF;

    -- Get table row count using prepared statement (FIXED)
    SET @row_count_sql = CONCAT('SELECT COUNT(*) FROM `', v_input_schema, '`.`', v_input_table, '` INTO @temp_row_count');
    PREPARE stmt FROM @row_count_sql;
    EXECUTE stmt;
    DEALLOCATE PREPARE stmt;
    SET v_row_count = @temp_row_count;

    -- Get table column count
    SELECT COUNT(*) INTO v_column_count
    FROM information_schema.COLUMNS
    WHERE TABLE_SCHEMA = v_input_schema
    AND TABLE_NAME = v_input_table;

    -- Check row count limits based on MySQL version
    IF v_mysql_version >= '9.4.1' THEN
        IF v_column_count > 10 AND v_row_count > 10 THEN
            SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Input table has >10 columns and >10 rows. Limit to 10 rows for tables with >10 columns in MySQL 9.4.1+';
        ELSEIF v_row_count > 100 THEN
            SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Input table exceeds 100 row limit for MySQL 9.4.1+';
        END IF;
    END IF;

    -- Check if model exists (simplified check)
    SELECT COUNT(*) INTO v_model_exists
    FROM performance_schema.ml_model_endpoints 
    WHERE model_handle = model_handle;

    IF v_model_exists = 0 THEN
        SET v_error_msg = CONCAT('Model handle not found: ', model_handle);
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = v_error_msg;
    END IF;

    -- Check if SHAP explainer is requested but not trained
    IF v_prediction_explainer = 'shap' THEN
        SELECT COUNT(*) INTO v_shap_exists
        FROM performance_schema.ml_model_explainers 
        WHERE model_handle = model_handle 
        AND explainer_type = 'shap' 
        AND status = 'READY';

        IF v_shap_exists = 0 THEN
            SET v_error_msg = 'SHAP explainer not found or not ready. Please run ML_EXPLAIN with "shap" explainer first.';
            SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = v_error_msg;
        END IF;
    END IF;

    -- Check for primary key in input table
    SELECT COUNT(*) INTO v_has_primary_key
    FROM information_schema.KEY_COLUMN_USAGE k
    JOIN information_schema.TABLE_CONSTRAINTS t
        ON k.CONSTRAINT_NAME = t.CONSTRAINT_NAME
        AND k.TABLE_SCHEMA = t.TABLE_SCHEMA
        AND k.TABLE_NAME = t.TABLE_NAME
    WHERE k.TABLE_SCHEMA = v_input_schema
    AND k.TABLE_NAME = v_input_table
    AND t.CONSTRAINT_TYPE = 'PRIMARY KEY';

    -- Check for problematic column name conflicts
    IF v_has_primary_key = 0 THEN
        IF v_mysql_version >= '8.4.1' THEN
            SELECT COUNT(*) INTO v_pk_column_conflict
            FROM information_schema.COLUMNS
            WHERE TABLE_SCHEMA = v_input_schema
            AND TABLE_NAME = v_input_table
            AND COLUMN_NAME = '_4aad19ca6e_pk_id';

            IF v_pk_column_conflict > 0 THEN
                SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Input table cannot have column named "_4aad19ca6e_pk_id" that is not a primary key';
            END IF;
        ELSE
            SELECT COUNT(*) INTO v_pk_column_conflict
            FROM information_schema.COLUMNS
            WHERE TABLE_SCHEMA = v_input_schema
            AND TABLE_NAME = v_input_table
            AND COLUMN_NAME = '_id';

            IF v_pk_column_conflict > 0 THEN
                SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Input table cannot have column named "_id" that is not a primary key';
            END IF;
        END IF;
    END IF;

    IF v_error THEN
        RESIGNAL;
    END IF;

    -- Call native function ML_EXPLAIN_TABLE
    SELECT ML_EXPLAIN_TABLE(table_name, model_handle, output_table_name, options);
END$$

DELIMITER ;-- Copyright (c) 2014, 2023, Oracle and/or its affiliates.
--
-- This program is free software; you can redistribute it and/or modify
-- it under the terms of the GNU General Public License as published by
-- the Free Software Foundation; version 2 of the License.
--
-- This program is distributed in the hope that it will be useful,
-- but WITHOUT ANY WARRANTY; without even the implied warranty of
-- MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
-- GNU General Public License for more details.
--
-- You should have received a copy of the GNU General Public License
-- along with this program; if not, write to the Free Software
-- Foundation, Inc., 51 Franklin St, Fifth Floor, Boston, MA 02110-1301 USA
-- Copyright (c) 2023, Shannon Data AI and/or its affiliates.

DROP PROCEDURE IF EXISTS ml_explain;

DELIMITER $$

CREATE DEFINER='mysql.sys'@'localhost' PROCEDURE ml_explain (
        IN in_sche_tb_name VARCHAR(64), 
        IN in_target_name VARCHAR(64),
        IN in_model_handle VARCHAR(64),
        IN in_option JSON
    )
    COMMENT '
Description
-----------

Run the ml_explain routine on a labeled training dataset to produce a trained machine learning model.

Parameters
-----------

in_sche_tb_name (VARCHAR(64)):
  fully qualified name of the table containing the training dataset.
in_target_name (VARCHAR(64)):
  name of the column in \'table_name\' representing the target, i.e. ground truth values (required for some tasks)
in_model_handle (VARCHAR(64))
   user-defined session variable storing the ML model handle for the duration of the connection
in_option (JSON)
 Optional parameters specified as key-value pairs in JSON format. If an option is not specified, the default setting is used.
 If you specify NULL in place of the JSON argument, the default Permutation 
 Importance model explainer is trained, and no prediction explainer is trained. 
Example
-----------
mysql> SET @iris_model = \'iris_manual\';
mysql> CALL sys.ML_EXPLAIN(\'ml_data.iris_train\', \'class\',
          \'ml_data.iris_train_user1_1636729526\', 
          JSON_OBJECT(\'model_explainer\', \'fast_shap\', \'prediction_explainer\', \'shap\'));
...
'
    SQL SECURITY INVOKER
    NOT DETERMINISTIC
    MODIFIES SQL DATA
BEGIN
    DECLARE in_user_name VARCHAR(64);
    DECLARE v_user_name VARCHAR(64);
    DECLARE v_sys_schema_name VARCHAR(64);
    DECLARE v_exp_obj_check INT;

    DECLARE v_db_err_msg TEXT;
    DECLARE v_score_obj_check INT;
    DECLARE v_model_id INT;

   IF in_sche_tb_name NOT REGEXP '^[^.]+\.[^.]+$' THEN
      SIGNAL SQLSTATE '45000'
        SET MESSAGE_TEXT = 'Invalid schema.table format, please using fully qualified name of the table.';
   END IF;

   IF in_user_name IS NULL THEN
     SELECT SUBSTRING_INDEX(CURRENT_USER(), '@', 1) INTO v_user_name;
     SET v_sys_schema_name = CONCAT('ML_SCHEMA_', v_user_name);
     SET in_user_name = v_user_name;
   ELSE
     SET v_sys_schema_name = CONCAT('ML_SCHEMA_', in_user_name);
   END IF;

   SET @select_model_stm = CONCAT('SELECT MODEL_ID INTO @MODEL_ID FROM ',  v_sys_schema_name,
                                  '.MODEL_CATALOG WHERE MODEL_HANDLE = \"', in_model_handle, '\";');
   PREPARE select_model_stmt FROM @select_model_stm;
   EXECUTE select_model_stmt;
   SELECT @MODEL_ID into v_model_id;
   DEALLOCATE PREPARE select_model_stmt;

   IF (v_model_id IS NULL) THEN
     SIGNAL SQLSTATE 'HY000'
        SET MESSAGE_TEXT = "The model you explaining does NOT exist.";
   END IF;

   SELECT ML_MODEL_EXPLAIN(in_sche_tb_name, in_target_name, in_model_handle, in_option) INTO v_exp_obj_check;
   IF v_exp_obj_check != 0 THEN
        SET v_db_err_msg = CONCAT('ML_EXPLAIN failed.');
        SIGNAL SQLSTATE 'HY000'
          SET MESSAGE_TEXT = v_db_err_msg;
   END IF;
END$$
DELIMITER ;
-- Copyright (c) 2014, 2023, Oracle and/or its affiliates.
--
-- This program is free software; you can redistribute it and/or modify
-- it under the terms of the GNU General Public License as published by
-- the Free Software Foundation; version 2 of the License.
--
-- This program is distributed in the hope that it will be useful,
-- but WITHOUT ANY WARRANTY; without even the implied warranty of
-- MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
-- GNU General Public License for more details.
--
-- You should have received a copy of the GNU General Public License
-- along with this program; if not, write to the Free Software
-- Foundation, Inc., 51 Franklin St, Fifth Floor, Boston, MA 02110-1301 USA
-- Copyright (c) 2023, Shannon Data AI and/or its affiliates.

DROP PROCEDURE IF EXISTS ml_model_export;

DELIMITER $$

CREATE DEFINER='mysql.sys'@'localhost' PROCEDURE ml_model_export (
        IN in_model_handle_name varchar(256),
        IN in_output_table_name VARCHAR(256)
    )
    COMMENT '
Description
-----------

Run the ML_MODEL_EXPORT routine to export an existed trained model.

Parameters
-----------

in_model_handle_name (VARCHAR(64))
   user-defined session variable storing the ML model handle for the duration of the connection.
in_output_table_name VARCHAR(256):
  output table name.
Example
-----------
mysql> SET @iris_model = \'iris_manual\';
mysql> CALL sys.ML_MODEL_EXPORT(@iris_model,\'ML_SCHEMA_user1.model_export\');
...
'
SQL SECURITY INVOKER
NOT DETERMINISTIC
MODIFIES SQL DATA
BEGIN
    DECLARE v_user_name VARCHAR(64);
    DECLARE v_sys_meta_catalog_name VARCHAR(128);
    DECLARE v_schema  VARCHAR(64);
    DECLARE v_table   VARCHAR(64);
    DECLARE v_model_cnt INT;
    DECLARE v_import_obj_check INT;

    -- Step 1: gets current username 
    SELECT SUBSTRING_INDEX(CURRENT_USER(), '@', 1) INTO v_user_name;

    -- Step 2: get ml_schema catalog name
    SET v_sys_meta_catalog_name = CONCAT('ML_SCHEMA_', v_user_name, '.MODEL_CATALOG');

    -- Step 3: check existence.
    SET @check_sql = CONCAT(
        'SELECT COUNT(*) INTO @cnt FROM ', v_sys_meta_catalog_name,
        ' WHERE model_handle = ', '\"', in_model_handle_name , '\";'
    );
    PREPARE check_stmt FROM @check_sql;
    EXECUTE check_stmt;
    DEALLOCATE PREPARE check_stmt;

    SELECT @cnt INTO v_model_cnt;
    IF v_model_cnt = 0 THEN
        SIGNAL SQLSTATE '45000'
        SET MESSAGE_TEXT = 'The model_handle your input does not exist in MODEL_CATALOG.';
    END IF;

    -- Step 4: gets schema and table name of output table
    SELECT SUBSTRING_INDEX(in_output_table_name, '.', 1) INTO v_schema;
    SELECT SUBSTRING_INDEX(in_output_table_name, '.', -1) INTO v_table;

    -- Step 5: check output table existence
    SET @check_sql = CONCAT(
        'SELECT COUNT(*) INTO @cnt FROM INFORMATION_SCHEMA.TABLES', 
        ' WHERE TABLE_SCHEMA = "', v_schema , '\" AND TABLE_NAME = "', v_table, '\";'
    );
    PREPARE check_stmt FROM @check_sql;
    EXECUTE check_stmt;
    DEALLOCATE PREPARE check_stmt;

    SELECT @cnt INTO v_import_obj_check;

    IF v_import_obj_check = 0 THEN
        -- create schema
        SET @sql_create_db = CONCAT('CREATE DATABASE IF NOT EXISTS `', v_schema, '`;');
        PREPARE stmt FROM @sql_create_db;
        EXECUTE stmt;
        DEALLOCATE PREPARE stmt;

        -- create table
        SET @sql_create_table = CONCAT(
            'CREATE TABLE IF NOT EXISTS `', v_schema, '`.`', v_table, '` (',
            'chunk_id INT AUTO_INCREMENT PRIMARY KEY,',
            'model_object LONGTEXT DEFAULT NULL,',
            'model_metadata JSON',
            ');'
        );
        PREPARE stmt FROM @sql_create_table;
        EXECUTE stmt;
        DEALLOCATE PREPARE stmt;
    END IF;

    -- Step 6: insert data.
    SET @insert_sql = CONCAT(
        'INSERT INTO `', v_schema, '`.`', v_table, '` (model_object, model_metadata) ',
        'SELECT model_object, model_metadata FROM ', v_sys_meta_catalog_name,
        ' WHERE model_handle = ', '\"', in_model_handle_name, '\";'
    );
    PREPARE stmt FROM @insert_sql;
    EXECUTE stmt;
    DEALLOCATE PREPARE stmt;
END$$

DELIMITER ;-- Copyright (c) 2014, 2023, Oracle and/or its affiliates.
--
-- This program is free software; you can redistribute it and/or modify
-- it under the terms of the GNU General Public License as published by
-- the Free Software Foundation; version 2 of the License.
--
-- This program is distributed in the hope that it will be useful,
-- but WITHOUT ANY WARRANTY; without even the implied warranty of
-- MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
-- GNU General Public License for more details.
--
-- You should have received a copy of the GNU General Public License
-- along with this program; if not, write to the Free Software
-- Foundation, Inc., 51 Franklin St, Fifth Floor, Boston, MA 02110-1301 USA
-- Copyright (c) 2023, Shannon Data AI and/or its affiliates.

DROP PROCEDURE IF EXISTS ml_model_import;

DELIMITER $$

CREATE DEFINER='mysql.sys'@'localhost' PROCEDURE ml_model_import (
        IN in_model_content LONGTEXT,
        IN in_metadata JSON,
        IN in_model_handle_name VARCHAR(256)
    )
    COMMENT '
Description
-----------

Run the ML_MODEL_IMPORT routine to import an existed trained model into a new model handle.

Parameters
-----------

in_model_content LONGTEXT:
  model content.
in_metadata (JSON)
  optional training parameters as key-value pairs in JSON format.
    1: The most important parameter is \'task\', which specifies the ML task to be performed (if not specified, \'classification\' is assumed)
    2: Other parameters allow finer-grained control on the training task
in_model_handle_name (VARCHAR(64))
   user-defined session variable storing the ML model handle for the duration of the connection
Example
-----------
mysql> SET @iris_model = \'iris_manual\';
mysql> CALL sys.ML_MODEL_IMPORT(\'xxxx\', JSON_OBJECT(\'task\', \'classification\'),
          @iris_model);
...
'
    SQL SECURITY INVOKER
    NOT DETERMINISTIC
    MODIFIES SQL DATA
BEGIN
    DECLARE v_user_name VARCHAR(64);
    DECLARE v_sys_meta_catalog_name VARCHAR(64);
    DECLARE v_sys_meta_catalog_obj_name VARCHAR(64);

    DECLARE v_db_err_msg TEXT;
    DECLARE v_import_obj_check INT;
    DECLARE v_schema  VARCHAR(64);
    DECLARE v_table VARCHAR(64);
    DECLARE v_model_cnt INT;
    DECLARE v_model_meta JSON;
    DECLARE v_model_object LONGTEXT;
    DECLARE v_model_handle_name VARCHAR(64);

    SELECT SUBSTRING_INDEX(CURRENT_USER(), '@', 1) INTO v_user_name;
    SET v_sys_meta_catalog_name = CONCAT('ML_SCHEMA_', v_user_name, '.MODEL_CATALOG');
    SET v_sys_meta_catalog_obj_name = CONCAT('ML_SCHEMA_', v_user_name, '.MODEL_OBJECT_CATALOG');

    IF in_metadata IS NULL THEN
    SIGNAL SQLSTATE 'HY000'
       SET MESSAGE_TEXT = "The options missed.";
    END IF;

   IF in_model_handle_name IS NULL THEN
      SET in_model_handle_name = CONCAT('ML_SCHEMA_', v_user_name, '_', SUBSTRING(MD5(RAND()), 1, 10));
   END IF;

   SET @select_model_stm = CONCAT('SELECT COUNT(MODEL_ID) INTO @MODEL_CNT FROM ',  v_sys_meta_catalog_name,
                                  ' WHERE MODEL_HANDLE = \"', in_model_handle_name, '\";');
   PREPARE select_model_stmt FROM @select_model_stm;
   EXECUTE select_model_stmt;
   SELECT @MODEL_CNT into v_model_cnt;
   DEALLOCATE PREPARE select_model_stmt;

   IF (v_model_cnt != 0) THEN
     SIGNAL SQLSTATE 'HY000'
        SET MESSAGE_TEXT = "The handle name you specify is already exists.";
   END IF;

   -- import from a tabble. in_model_content set to null.
   IF JSON_CONTAINS_PATH(in_metadata, 'one', '$.schema') AND JSON_CONTAINS_PATH(in_metadata, 'one', '$.table')
   THEN
      SELECT in_metadata->'$.schema', in_metadata->'$.table' INTO v_schema, v_table;

      SELECT COUNT(*) INTO v_import_obj_check
      FROM INFORMATION_SCHEMA.TABLES
      WHERE TABLE_SCHEMA = v_schema AND TABLE_NAME = v_table;
      IF v_import_obj_check = 0 THEN
          SET v_db_err_msg = CONCAT(in_table_name, ' used to import from does not exists.');
            SIGNAL SQLSTATE 'HY000'
            SET MESSAGE_TEXT = v_db_err_msg;
      END IF;

      -- The table should have the following columns, and their recommended parameters:
      SET @v_model_meta_check_stmt = CONCAT('SELECT COUNT(1) INTO @MODEL_CNT FROM INFORMATION_SCHEMA.COLUMNS ',
                                            ' WHERE TABLE_SCHEMA = \"', v_schema, '\" AND TABLE_NAME = \"', v_table, '\"',
                                            ' AND COLUMN_NAME IN (\"chunk_id\", \"model_object\", \"model_metadata\");');
      PREPARE check_stmt FROM @v_model_meta_check_stmt;
      EXECUTE check_stmt;
      SELECT @MODEL_CNT into v_model_cnt;
      DEALLOCATE PREPARE check_stmt;
      IF v_model_cnt = 0 THEN
        SIGNAL SQLSTATE 'HY000'
           SET MESSAGE_TEXT = "The table definition imported is wrong.";
      END IF;

      SET @v_model_meta_check_stmt = CONCAT('SELECT COUNT(1) INTO @MODEL_CNT FROM INFORMATION_SCHEMA.KEY_COLUMN_USAGE ',
                                          ' WHERE TABLE_SCHEMA = \"', v_schema, '\" AND TABLE_NAME = \"', v_table, '\"',
                                          ' AND CONSTRAINT_NAME = \"PRIMARY\" AND COLUMN_NAME = \"CHUNK_ID\";');
      PREPARE check_stmt FROM @v_model_meta_check_stmt;
      EXECUTE check_stmt;
      SELECT @MODEL_CNT into v_model_cnt;
      DEALLOCATE PREPARE check_stmt;
      IF v_model_cnt = 0 THEN
        SIGNAL SQLSTATE 'HY000'
           SET MESSAGE_TEXT = "The column definition of CHUNK_ID imported is wrong.";
      END IF;

      SET @v_model_meta_check_stmt = CONCAT('SELECT COUNT(1) INTO @MODEL_CNT FROM INFORMATION_SCHEMA.KEY_COLUMN_USAGE ',
                                          ' WHERE TABLE_SCHEMA = \"', v_schema, '\" AND TABLE_NAME = \"', v_table, '\"',
                                          ' AND COLUMN_NAME = \"MODEL_OBJECT\" AND IS_NULLABLE = \"NO\" AND DATA_TYPE = \"LONGTEXT\";');

      PREPARE check_stmt FROM @v_model_meta_check_stmt;
      EXECUTE check_stmt;
      SELECT @MODEL_CNT into v_model_cnt;
      DEALLOCATE PREPARE check_stmt;
      IF v_model_cnt = 0 THEN
        SIGNAL SQLSTATE 'HY000'
           SET MESSAGE_TEXT = "The column definition of model_object imported is wrong.";
      END IF;

      SET @v_model_meta_check_stmt = CONCAT('SELECT COUNT(1) INTO @MODEL_CNT FROM INFORMATION_SCHEMA.COLUMNS ',
                                          ' WHERE TABLE_SCHEMA = \"', v_schema, '\" AND TABLE_NAME = \"', v_table, '\"',
                                          ' AND COLUMN_NAME = \"MODEL_METADATA\" AND COLUMN_DEFAULT IS NULL AND COLUMN_TYPE = \"JSON\";');

      PREPARE check_stmt FROM @v_model_meta_check_stmt;
      EXECUTE check_stmt;
      SELECT @MODEL_CNT into v_model_cnt;
      DEALLOCATE PREPARE check_stmt;
      IF v_model_cnt = 0 THEN
        SIGNAL SQLSTATE 'HY000'
           SET MESSAGE_TEXT = "The column definition of MODEL_METADATA imported is wrong.";
      END IF;

      -- There must be one row, and only one row, in the table with chunk_id = 1.
      SET @select_model_stm = CONCAT('SELECT COUNT(MODEL_METADATA) INTO @MODEL_CNT FROM ',
                                      v_schema, '.', v_table,
                                      ' WHERE chunk_id = 1;');
      PREPARE select_model_stmt FROM @select_model_stm;
      EXECUTE select_model_stmt;
      SELECT @MODEL_CNT into v_model_cnt;
      DEALLOCATE PREPARE select_model_stmt;
      IF v_model_cnt != 1 THEN
        SIGNAL SQLSTATE 'HY000'
            SET MESSAGE_TEXT = "the table your imported more than one row with CHUNK_ID = 1.";
      END IF;


      SET @model_obj_stm = CONCAT('SELECT MODEL_OBJECT, MODEL_METADATA INTO @MODEL_OBJ, @MODEL_META FROM',
                                  v_schema, '.', v_table, ' WHERE CHUNK_ID = 1;');
      PREPARE select_model_stmt FROM @model_obj_stm;
      EXECUTE select_model_stmt;
      SELECT @MODEL_OBJ, @model_metadata into v_model_object, v_model_meta;
      DEALLOCATE PREPARE select_model_stmt;

      SET @model_obj_size = OCTET_LENGTH(v_model_object);
      SET @model_obj_stm = CONCAT('INSERT INTO ', v_sys_meta_catalog_name,
                                  '(MODEL_HANDLE, MODEL_OBJECT, MODEL_OWNER, MODEL_OBJECT_SIZE, MODEL_METADATA)',
                                  ' VALUES(', '\"', in_model_handle_name, '\", NULL,',
                                  '\"', v_user_name, '\",', @model_obj_size, ',',
                                  '''',JSON_UNQUOTE(JSON_EXTRACT(v_model_meta, '$')), ''');');
      PREPARE select_model_stmt FROM @model_obj_stm;
      EXECUTE select_model_stmt;
      DEALLOCATE PREPARE select_model_stmt;

      SET @model_obj_stm = CONCAT('INSERT INTO ', v_sys_meta_catalog_obj_name, '(MODEL_HANDLE, MODEL_OBJECT)',
                                    ' VALUES(', '\"', in_model_handle_name, '\",',
                                    JSON_QUOTE(CAST(v_model_object AS CHAR)), ');');
      PREPARE select_model_stmt FROM @model_obj_stm;
      EXECUTE select_model_stmt;
      DEALLOCATE PREPARE select_model_stmt;
   ELSE
    -- The preprocessed model object.
      SET @model_obj_size = OCTET_LENGTH(in_model_content);
      SET @model_obj_stm = CONCAT('INSERT INTO ', v_sys_meta_catalog_name,
                                  '(MODEL_HANDLE, MODEL_OBJECT, MODEL_OWNER, MODEL_OBJECT_SIZE, MODEL_METADATA)',
                                  ' VALUES(', '\"', in_model_handle_name, '\", NULL,',
                                  '\"', v_user_name, '\",', @model_obj_size, ',',
                                  '''',JSON_UNQUOTE(JSON_EXTRACT(in_metadata, '$')), ''');');
      PREPARE select_model_stmt FROM @model_obj_stm;
      EXECUTE select_model_stmt;
      DEALLOCATE PREPARE select_model_stmt;

      SET @model_obj_stm = CONCAT('INSERT INTO ', v_sys_meta_catalog_obj_name, '(MODEL_HANDLE, MODEL_OBJECT)',
                                    ' VALUES(', '\"', in_model_handle_name, '\",',
                                    JSON_QUOTE(CAST(in_model_content AS CHAR)), ');');
      PREPARE select_model_stmt FROM @model_obj_stm;
      EXECUTE select_model_stmt;
      DEALLOCATE PREPARE select_model_stmt;
   END IF;
END$$
DELIMITER ;
-- Copyright (c) 2014, 2023, Oracle and/or its affiliates.
--
-- This program is free software; you can redistribute it and/or modify
-- it under the terms of the GNU General Public License as published by
-- the Free Software Foundation; version 2 of the License.
--
-- This program is distributed in the hope that it will be useful,
-- but WITHOUT ANY WARRANTY; without even the implied warranty of
-- MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
-- GNU General Public License for more details.
--
-- You should have received a copy of the GNU General Public License
-- along with this program; if not, write to the Free Software
-- Foundation, Inc., 51 Franklin St, Fifth Floor, Boston, MA 02110-1301 USA
-- Copyright (c) 2023, Shannon Data AI and/or its affiliates.

DROP PROCEDURE IF EXISTS ml_model_load;

DELIMITER $$

CREATE DEFINER='mysql.sys'@'localhost' PROCEDURE ml_model_load (
        IN in_model_handle_name VARCHAR(64),
        IN in_user_name VARCHAR(64)
    )
    COMMENT '
Description
-----------

Run the ML_MODEL_LOAD routine load the trained model into memory.

Parameters
-----------

in_model_handle_name (VARCHAR(64)):
   user-defined session variable storing the ML model handle for the duration of the connection
in_user_name (VARCHAR(64)):
  name of user
Example
-----------
mysql> SET @iris_model = \'iris_manual\';
mysql> CALL sys.ML_MODEL_LOAD(@iris_model, \'root\');
...
'
    SQL SECURITY INVOKER
    NOT DETERMINISTIC
    MODIFIES SQL DATA
BEGIN
    DECLARE v_user_name VARCHAR(64);
    DECLARE v_sys_schema_name VARCHAR(64);

    DECLARE v_db_err_msg TEXT;
    DECLARE v_load_obj_check INT;
    DECLARE v_model_id INT;

   IF in_user_name IS NULL THEN
     SELECT SUBSTRING_INDEX(CURRENT_USER(), '@', 1) INTO v_user_name;
     SET v_sys_schema_name = CONCAT('ML_SCHEMA_', v_user_name);
     SET in_user_name = v_user_name;
   ELSE
     SET v_sys_schema_name = CONCAT('ML_SCHEMA_', in_user_name);
   END IF;

   SET @select_model_stm = CONCAT('SELECT MODEL_ID INTO @MODEL_ID FROM ',  v_sys_schema_name,
                                  '.MODEL_CATALOG WHERE MODEL_HANDLE = \"', in_model_handle_name, '\";');
   PREPARE select_model_stmt FROM @select_model_stm;
   EXECUTE select_model_stmt;
   SELECT @MODEL_ID into v_model_id;
   DEALLOCATE PREPARE select_model_stmt;

   IF (v_model_id IS NULL) THEN
     SIGNAL SQLSTATE 'HY000'
        SET MESSAGE_TEXT = "The model you loading does NOT exist.";
   END IF;

   SELECT ML_MODEL_LOAD(in_model_handle_name) INTO v_load_obj_check;
   IF v_load_obj_check != 0 THEN
        SET v_db_err_msg = CONCAT('ML_MODEL_LOAD failed.');
        SIGNAL SQLSTATE 'HY000'
          SET MESSAGE_TEXT = v_db_err_msg;
   END IF;
END$$
DELIMITER ;
-- Copyright (c) 2014, 2023, Oracle and/or its affiliates.
--
-- This program is free software; you can redistribute it and/or modify
-- it under the terms of the GNU General Public License as published by
-- the Free Software Foundation; version 2 of the License.
--
-- This program is distributed in the hope that it will be useful,
-- but WITHOUT ANY WARRANTY; without even the implied warranty of
-- MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
-- GNU General Public License for more details.
--
-- You should have received a copy of the GNU General Public License
-- along with this program; if not, write to the Free Software
-- Foundation, Inc., 51 Franklin St, Fifth Floor, Boston, MA 02110-1301 USA
-- Copyright (c) 2023, Shannon Data AI and/or its affiliates.

DROP PROCEDURE IF EXISTS ml_model_unload;

DELIMITER $$

CREATE DEFINER='mysql.sys'@'localhost' PROCEDURE ml_model_unload (
        IN in_model_handle_name VARCHAR(64)
    )
    COMMENT '
Description
-----------

Run the ML_MODEL_UNLOAD routine unload the trained model from memory.

Parameters
-----------

in_model_handle_name (VARCHAR(64)):
   user-defined session variable storing the ML model handle for the duration of the connection
Example
-----------
mysql> SET @iris_model = \'iris_manual\';
mysql> CALL sys.ML_MODEL_UNLOAD(@iris_model);
...
'
    SQL SECURITY INVOKER
    NOT DETERMINISTIC
    MODIFIES SQL DATA
BEGIN
    DECLARE v_user_name VARCHAR(64);
    DECLARE v_sys_schema_name VARCHAR(64);

    DECLARE v_db_err_msg TEXT;
    DECLARE v_unload_obj_check INT;
    DECLARE v_model_id INT;

   SELECT SUBSTRING_INDEX(CURRENT_USER(), '@', 1) INTO v_user_name;
   SET v_sys_schema_name = CONCAT('ML_SCHEMA_', v_user_name);

   SET @select_model_stm = CONCAT('SELECT MODEL_ID INTO @MODEL_ID FROM ',  v_sys_schema_name,
                                  '.MODEL_CATALOG WHERE MODEL_HANDLE = \"', in_model_handle_name, '\";');
   PREPARE select_model_stmt FROM @select_model_stm;
   EXECUTE select_model_stmt;
   SELECT @MODEL_ID into v_model_id;
   DEALLOCATE PREPARE select_model_stmt;

   IF (v_model_id IS NULL) THEN
     SIGNAL SQLSTATE 'HY000'
        SET MESSAGE_TEXT = "The model you unloading does NOT exist.";
   END IF;

   SELECT ML_MODEL_UNLOAD(in_model_handle_name) INTO v_unload_obj_check;
   IF v_unload_obj_check != 0 THEN
        SET v_db_err_msg = CONCAT('ML_MODEL_UNLOAD failed.');
        SIGNAL SQLSTATE 'HY000'
        SET MESSAGE_TEXT = v_db_err_msg;
   END IF;
END$$
DELIMITER ;
-- Copyright (c) 2014, 2023, Oracle and/or its affiliates.
--
-- This program is free software; you can redistribute it and/or modify
-- it under the terms of the GNU General Public License as published by
-- the Free Software Foundation; version 2 of the License.
--
-- This program is distributed in the hope that it will be useful,
-- but WITHOUT ANY WARRANTY; without even the implied warranty of
-- MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
-- GNU General Public License for more details.
--
-- You should have received a copy of the GNU General Public License
-- along with this program; if not, write to the Free Software
-- Foundation, Inc., 51 Franklin St, Fifth Floor, Boston, MA 02110-1301 USA
-- Copyright (c) 2023, Shannon Data AI and/or its affiliates.

DROP PROCEDURE IF EXISTS ml_model_active;

DELIMITER $$

CREATE DEFINER='mysql.sys'@'localhost' PROCEDURE ml_model_active (
        IN in_user_name VARCHAR(64),
        OUT out_model_info JSON
    )
    COMMENT '
Description
-----------

Run the ML_MODEL_ACTIVE routine to get the trained model into memory.

Parameters
-----------

in_user_name (VARCHAR(64)):
  name of user
out_model_info JSON:
  The name of the JSON array that will contain the active user and model information

Example
-----------
mysql> CALL sys.ML_MODEL_ACTIVE(\'root\',@iris_model);
...
'
    SQL SECURITY INVOKER
    NOT DETERMINISTIC
    MODIFIES SQL DATA
BEGIN
    DECLARE v_user_name VARCHAR(64);
    DECLARE v_sys_schema_name VARCHAR(64);

    DECLARE v_db_err_msg TEXT;
    DECLARE v_load_obj_check INT;
    DECLARE v_model_id INT;

   IF in_user_name IS NULL THEN
     SELECT SUBSTRING_INDEX(CURRENT_USER(), '@', 1) INTO v_user_name;
     SET v_sys_schema_name = CONCAT('ML_SCHEMA_', v_user_name);
     SET in_user_name = v_user_name;
   ELSE
     SET v_sys_schema_name = CONCAT('ML_SCHEMA_', in_user_name);
   END IF;

   SET @select_model_stm = CONCAT('SELECT MODEL_ID INTO @MODEL_ID FROM ',  v_sys_schema_name,
                                  '.MODEL_CATALOG WHERE MODEL_HANDLE = \"', in_model_handle_name, '\";');
   PREPARE select_model_stmt FROM @select_model_stm;
   EXECUTE select_model_stmt;
   SELECT @MODEL_ID into v_model_id;
   DEALLOCATE PREPARE select_model_stmt;

   IF (v_model_id IS NULL) THEN
     SIGNAL SQLSTATE 'HY000'
        SET MESSAGE_TEXT = "The model you loading does NOT exist.";
   END IF;

   SELECT ML_MODEL_ACTIVE(in_model_handle_name, out_model_info) INTO v_load_obj_check;
   IF v_load_obj_check != 0 THEN
        SET v_db_err_msg = CONCAT('ML_MODEL_LOAD failed.');
        SIGNAL SQLSTATE 'HY000'
          SET MESSAGE_TEXT = v_db_err_msg;
   END IF;
END$$
DELIMITER ;
-- Copyright (c) 2014, 2023, Oracle and/or its affiliates.
--
-- This program is free software; you can redistribute it and/or modify
-- it under the terms of the GNU General Public License as published by
-- the Free Software Foundation; version 2 of the License.
--
-- This program is distributed in the hope that it will be useful,
-- but WITHOUT ANY WARRANTY; without even the implied warranty of
-- MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
-- GNU General Public License for more details.
--
-- You should have received a copy of the GNU General Public License
-- along with this program; if not, write to the Free Software
-- Foundation, Inc., 51 Franklin St, Fifth Floor, Boston, MA 02110-1301 USA
-- Copyright (c) 2023, Shannon Data AI and/or its affiliates.

DROP PROCEDURE IF EXISTS ml_score;
DELIMITER $$

CREATE DEFINER='mysql.sys'@'localhost' PROCEDURE ml_score (
        IN in_sch_tb_name VARCHAR(64), IN in_target_name VARCHAR(64), IN in_handle_name VARCHAR(64),
        IN in_metric_name VARCHAR(64), OUT in_score_var FLOAT, IN in_option JSON
    )
    COMMENT '
Description
-----------

Run the ml_score routine on a labeled training dataset to predict to ground truth values in the target column of the labeled dataset.

Parameters
-----------
 in_sch_tb_name VARCHAR(64): fully qualified name of the table containing the dataset used to compute model quality.
 in_target_name VARCHAR(64): name of the target column in \'table_name\' containing ground truth values.
 in_handle_name VARCHAR(64): explicit model handle string or session variable containing the model handle.
 in_metric_name VARCHAR(64): specifies which metric should be used to evaluate model quality. Different values can be used depending on ML task and
target variable (e.g. f1, precision, recall, roc_auc, f1_weighted, balanced_accuracy…).
 in_score_var VARCHAR(64): user-defined session variable name storing the computed score for the duration of the connection.
 in_option JSON[option]: a set of optional key-value pairs, can be specified only starting in MySQL 8.0.32 and only for some tasks.
Example
-----------
mysql> CALL sys.ML_SCORE(\'ml_data.iris_validate\', \'class\', @iris_model, \'balanced_accuracy\', @score, NULL);
'
    SQL SECURITY INVOKER
    NOT DETERMINISTIC
    MODIFIES SQL DATA
BEGIN
    DECLARE in_user_name VARCHAR(64);
    DECLARE v_user_name VARCHAR(64);
    DECLARE v_sys_schema_name VARCHAR(64);
    DECLARE v_train_test_schema_name VARCHAR(64);
    DECLARE v_train_test_table_name VARCHAR(64);

    DECLARE v_db_err_msg TEXT;
    DECLARE v_train_test_obj_check INT;
    DECLARE v_model_id INT;

   IF in_sch_tb_name NOT REGEXP '^[^.]+\.[^.]+$' THEN
      SIGNAL SQLSTATE '45000'
        SET MESSAGE_TEXT = 'Invalid schema.table format, please using fully qualified name of the table.';
   END IF;

   IF in_user_name IS NULL THEN
     SELECT SUBSTRING_INDEX(CURRENT_USER(), '@', 1) INTO v_user_name;
     SET v_sys_schema_name = CONCAT('ML_SCHEMA_', v_user_name);
     SET in_user_name = v_user_name;
   ELSE
     SET v_sys_schema_name = CONCAT('ML_SCHEMA_', in_user_name);
   END IF;

   SET @select_model_stm = CONCAT('SELECT MODEL_ID INTO @MODEL_ID FROM ',  v_sys_schema_name,
                                  '.MODEL_CATALOG WHERE MODEL_HANDLE = \"', in_handle_name, '\";');
   PREPARE select_model_stmt FROM @select_model_stm;
   EXECUTE select_model_stmt;
   SELECT @MODEL_ID into v_model_id;
   DEALLOCATE PREPARE select_model_stmt;

   IF (v_model_id IS NULL) THEN
     SIGNAL SQLSTATE 'HY000'
        SET MESSAGE_TEXT = "The model you scoring does NOT exist.";
   END IF;

  SELECT SUBSTRING_INDEX(in_sch_tb_name, '.', 1) INTO v_train_test_schema_name;
  SELECT SUBSTRING_INDEX(in_sch_tb_name, '.', -1) INTO v_train_test_table_name;

  SELECT COUNT(*) INTO v_train_test_obj_check
  FROM INFORMATION_SCHEMA.TABLES
  WHERE TABLE_SCHEMA = v_train_test_schema_name AND TABLE_NAME = v_train_test_table_name;
  IF v_train_test_obj_check = 0 THEN
      SET v_db_err_msg = CONCAT(in_table_name, ' used to do training test does not exists.');
        SIGNAL SQLSTATE 'HY000'
        SET MESSAGE_TEXT = v_db_err_msg;
  END IF;

  SELECT ML_MODEL_SCORE(in_sch_tb_name, in_target_name, in_handle_name, in_metric_name, in_option) INTO in_score_var;
END$$
DELIMITER ;
-- Copyright (c) 2014, 2023, Oracle and/or its affiliates.
--
-- This program is free software; you can redistribute it and/or modify
-- it under the terms of the GNU General Public License as published by
-- the Free Software Foundation; version 2 of the License.
--
-- This program is distributed in the hope that it will be useful,
-- but WITHOUT ANY WARRANTY; without even the implied warranty of
-- MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
-- GNU General Public License for more details.
--
-- You should have received a copy of the GNU General Public License
-- along with this program; if not, write to the Free Software
-- Foundation, Inc., 51 Franklin St, Fifth Floor, Boston, MA 02110-1301 USA
-- Copyright (c) 2023, Shannon Data AI and/or its affiliates.

DROP PROCEDURE IF EXISTS ml_train;
DELIMITER $$

CREATE DEFINER='mysql.sys'@'localhost' PROCEDURE ml_train (
        IN in_table_name VARCHAR(64),
        IN in_target_name VARCHAR(64),
        IN in_option JSON,
        IN in_model_handle VARCHAR(64)
    )
    COMMENT '
Description
-----------

Run the ML_TRAIN routine on a labeled training dataset to produce a trained machine learning model.

Parameters
-----------
in_table_name (VARCHAR(64)):
  fully qualified name of the table containing the training dataset.
in_target_name (VARCHAR(64)):
  name of the column in \'table_name\' representing the target, i.e. ground truth values (required for some tasks)
in_option (JSON)
  optional training parameters as key-value pairs in JSON format.
    1: The most important parameter is \'task\', which specifies the ML task to be performed (if not specified, \'classification\' is assumed)
    2: Other parameters allow finer-grained control on the training task
in_model_handle (VARCHAR(64))
   user-defined session variable storing the ML model handle for the duration of the connection
Example
-----------
mysql> SET @iris_model = \'iris_manual\';
mysql> CALL sys.ML_TRAIN(\'ml_data.iris_train\', \'class\', 
          JSON_OBJECT(\'task\', \'classification\'), 
          @iris_model);
...    
'
    SQL SECURITY INVOKER
    NOT DETERMINISTIC
    MODIFIES SQL DATA
BEGIN
    -- Variable declarations for validation and processing
    DECLARE v_user_name VARCHAR(64);
    DECLARE v_db_name_check VARCHAR(64);
    DECLARE v_sys_schema_name VARCHAR(64);
    DECLARE v_db_err_msg TEXT;

    -- Table and model validation variables
    DECLARE v_train_obj_check INT;
    DECLARE v_train_schema_name VARCHAR(64);
    DECLARE v_train_table_name VARCHAR(64);
    DECLARE v_model_name VARCHAR(255);

    -- Table constraint variables
    DECLARE table_size_gb DECIMAL(10, 2);
    DECLARE table_rows BIGINT;
    DECLARE column_count INT;

    -- Task and option processing variables
    DECLARE v_task VARCHAR(64) DEFAULT 'classification';
    DECLARE v_datetime_index VARCHAR(64);
    DECLARE v_endogenous_vars JSON;
    DECLARE v_exogenous_vars JSON;
    DECLARE v_model_list JSON;
    DECLARE v_exclude_models JSON;
    DECLARE v_optimization_metric VARCHAR(64);
    DECLARE v_contamination DECIMAL(5,4);
    DECLARE v_users_column VARCHAR(64);
    DECLARE v_items_column VARCHAR(64);
    DECLARE v_feedback VARCHAR(64);
    DECLARE v_document_column VARCHAR(64);

    -- Step 1: Validate table name format
    IF in_table_name NOT REGEXP '^[^.]+\.[^.]+$' THEN
        SIGNAL SQLSTATE '45000'
        SET MESSAGE_TEXT = 'Invalid schema.table format, please using fully qualified name of the table.';
    END IF;

    -- Step 2: Extract schema and table names
    SELECT SUBSTRING_INDEX(in_table_name, '.', 1) INTO v_train_schema_name;
    SELECT SUBSTRING_INDEX(in_table_name, '.', -1) INTO v_train_table_name;

    -- Step 3: Validate table size constraints
    SELECT ROUND((DATA_LENGTH + INDEX_LENGTH) / 1024 / 1024 / 1024, 2) INTO table_size_gb
    FROM information_schema.TABLES
    WHERE TABLE_SCHEMA = v_train_schema_name
    AND TABLE_NAME = v_train_table_name;

    SELECT TABLE_ROWS INTO table_rows
    FROM information_schema.TABLES
    WHERE TABLE_SCHEMA = v_train_schema_name
    AND TABLE_NAME = v_train_table_name;

    SELECT COUNT(*) INTO column_count
    FROM information_schema.COLUMNS
    WHERE TABLE_SCHEMA = v_train_schema_name
    AND TABLE_NAME = v_train_table_name;

    -- Enforce size constraints
    IF table_size_gb > 10 THEN
        SIGNAL SQLSTATE '45000'
        SET MESSAGE_TEXT = 'The table cannot exceed 10 GB';
    END IF;

    IF table_rows > 100000000 THEN
        SIGNAL SQLSTATE '45001'
        SET MESSAGE_TEXT = 'The table cannot exceed 100 million rows';
    END IF;

    IF column_count > 1017 THEN
        SIGNAL SQLSTATE '45002'
        SET MESSAGE_TEXT = 'The table cannot exceed 1017 columns';
    END IF;

    -- Step 4: Setup ML schema for user
    SELECT SUBSTRING_INDEX(CURRENT_USER(), '@', 1) INTO v_user_name;  
    SET v_sys_schema_name = CONCAT('ML_SCHEMA_', v_user_name);

    SELECT SCHEMA_NAME INTO v_db_name_check
    FROM INFORMATION_SCHEMA.SCHEMATA
    WHERE SCHEMA_NAME = v_sys_schema_name;

    -- Create ML schema and catalog tables if they don't exist
    IF v_db_name_check IS NULL THEN
        START TRANSACTION;

        -- Create ML schema
        SET @create_db_stmt = CONCAT('CREATE DATABASE ', v_sys_schema_name, ';');
        PREPARE create_db_stmt FROM @create_db_stmt;
        EXECUTE create_db_stmt;
        DEALLOCATE PREPARE create_db_stmt;

        -- Create MODEL_CATALOG table
        SET @create_tb_stmt = CONCAT(' CREATE TABLE ', v_sys_schema_name, '.MODEL_CATALOG(
                                        MODEL_ID INT NOT NULL AUTO_INCREMENT,
                                        MODEL_HANDLE VARCHAR(255) UNIQUE,
                                        MODEL_OBJECT JSON DEFAULT NULL,
                                        MODEL_OWNER VARCHAR(255) DEFAULT NULL,
                                        MODEL_OBJECT_SIZE INT DEFAULT 0,
                                        MODEL_METADATA JSON DEFAULT NULL,
                                        PRIMARY KEY (MODEL_ID));');
        PREPARE create_tb_stmt FROM @create_tb_stmt;
        EXECUTE create_tb_stmt;
        DEALLOCATE PREPARE create_tb_stmt;

        -- Create MODEL_OBJECT_CATALOG table
        SET @create_tb_stmt = CONCAT(' CREATE TABLE ', v_sys_schema_name, '.MODEL_OBJECT_CATALOG (
                                        CHUNK_ID INT NOT NULL AUTO_INCREMENT,
                                        MODEL_HANDLE VARCHAR(255),
                                        MODEL_OBJECT JSON DEFAULT NULL,
                                        PRIMARY KEY (CHUNK_ID, MODEL_HANDLE));');
        PREPARE create_tb_stmt FROM @create_tb_stmt;
        EXECUTE create_tb_stmt;
        DEALLOCATE PREPARE create_tb_stmt;

        -- Add foreign key constraint
        SET @add_fk_tb_stmt = CONCAT(' ALTER TABLE ', v_sys_schema_name, '.MODEL_OBJECT_CATALOG
                                     ADD CONSTRAINT fk_cat_handle_objcat_handl FOREIGN KEY (MODEL_HANDLE) ',
                                     'REFERENCES ', v_sys_schema_name, '.MODEL_CATALOG(MODEL_HANDLE);');
        PREPARE add_fk_tb_stmt FROM @add_fk_tb_stmt;
        EXECUTE add_fk_tb_stmt;
        DEALLOCATE PREPARE add_fk_tb_stmt;

        COMMIT;
    END IF;

    -- Step 5: Validate training table exists
    SELECT COUNT(*) INTO v_train_obj_check
    FROM INFORMATION_SCHEMA.TABLES
    WHERE TABLE_SCHEMA = v_train_schema_name
    AND TABLE_NAME = v_train_table_name;

    IF v_train_obj_check = 0 THEN
        SET v_db_err_msg = CONCAT(in_table_name, ' used to do training does not exists.');
        SIGNAL SQLSTATE 'HY000'
            SET MESSAGE_TEXT = v_db_err_msg;
    END IF;

    -- Step 6: Handle model handle - check if exists or generate new one
    IF in_model_handle IS NOT NULL THEN
        SET @select_model_stm = CONCAT('SELECT COUNT(MODEL_HANDLE) INTO @MODEL_HANDLE_COUNT FROM ',  
                                       v_sys_schema_name,
                                       '.MODEL_CATALOG WHERE MODEL_HANDLE = \"', 
                                       in_model_handle, '\";');
        PREPARE select_model_stmt FROM @select_model_stm;
        EXECUTE select_model_stmt;
        SELECT @MODEL_HANDLE_COUNT INTO v_train_obj_check;
        DEALLOCATE PREPARE select_model_stmt;

        IF v_train_obj_check > 0 THEN
            SIGNAL SQLSTATE 'HY000'
                SET MESSAGE_TEXT = "The model has already existed.";
        END IF;
    ELSE
        -- Generate unique model handle
        SET in_model_handle = CONCAT(in_table_name, '_', v_user_name, '_', 
                                   SUBSTRING(MD5(RAND()), 1, 10));
    END IF;

    -- Step 7: Validate target column exists (if specified)
    IF in_target_name IS NOT NULL THEN
        SELECT COUNT(COLUMN_NAME) INTO v_train_obj_check
        FROM INFORMATION_SCHEMA.COLUMNS
        WHERE TABLE_SCHEMA = v_train_schema_name
        AND TABLE_NAME = v_train_table_name 
        AND COLUMN_NAME = in_target_name;

        IF v_train_obj_check = 0 THEN
            SET v_db_err_msg = CONCAT('column ', in_target_name, 
                                    ' labelled does not exists in ', v_train_table_name);
            SIGNAL SQLSTATE 'HY000'
                SET MESSAGE_TEXT = v_db_err_msg;
        END IF;
    END IF;

    -- Step 8: Process training options and extract task-specific parameters
    IF in_option IS NULL THEN
        SET in_option = JSON_OBJECT('task', 'classification');
    END IF;

    -- Extract task type
    SET v_task = COALESCE(JSON_UNQUOTE(JSON_EXTRACT(in_option, '$.task')), 'classification');

    -- Extract common parameters
    SET v_model_list = JSON_EXTRACT(in_option, '$.model_list');
    SET v_exclude_models = JSON_EXTRACT(in_option, '$.exclude_model_list');
    SET v_optimization_metric = JSON_UNQUOTE(JSON_EXTRACT(in_option, '$.optimization_metric'));

    -- Extract task-specific parameters
    CASE v_task
        WHEN 'forecasting' THEN
            SET v_datetime_index = JSON_UNQUOTE(JSON_EXTRACT(in_option, '$.datetime_index'));
            SET v_endogenous_vars = JSON_EXTRACT(in_option, '$.endogenous_variables');
            SET v_exogenous_vars = JSON_EXTRACT(in_option, '$.exogenous_variables');

            -- Validate required forecasting parameters
            IF v_datetime_index IS NULL OR v_endogenous_vars IS NULL THEN
                SIGNAL SQLSTATE 'HY000'
                    SET MESSAGE_TEXT = 'Forecasting requires datetime_index and endogenous_variables';
            END IF;

        WHEN 'anomaly_detection' THEN
            SET v_contamination = JSON_UNQUOTE(JSON_EXTRACT(in_option, '$.contamination'));
            IF v_contamination IS NULL THEN
                SET v_contamination = 0.01;
            END IF;

            -- Validate contamination range
            IF v_contamination <= 0 OR v_contamination >= 0.5 THEN
                SIGNAL SQLSTATE 'HY000'
                    SET MESSAGE_TEXT = 'Contamination must be between 0 and 0.5';
            END IF;

        WHEN 'recommendation' THEN
            SET v_users_column = JSON_UNQUOTE(JSON_EXTRACT(in_option, '$.users'));
            SET v_items_column = JSON_UNQUOTE(JSON_EXTRACT(in_option, '$.items'));
            SET v_feedback = COALESCE(JSON_UNQUOTE(JSON_EXTRACT(in_option, '$.feedback')), 'explicit');

            -- Validate required recommendation parameters
            IF v_users_column IS NULL OR v_items_column IS NULL THEN
                SIGNAL SQLSTATE 'HY000'
                    SET MESSAGE_TEXT = 'Recommendation requires users and items columns';
            END IF;

        WHEN 'topic_modeling' THEN
            SET v_document_column = JSON_UNQUOTE(JSON_EXTRACT(in_option, '$.document_column'));

            IF v_document_column IS NULL THEN
                SIGNAL SQLSTATE 'HY000'
                    SET MESSAGE_TEXT = 'Topic modeling requires document_column';
            END IF;
        ELSE
            -- Classification and regression use defaults
            SET v_task = v_task;
    END CASE;

    -- Step 9: Execute the actual ML training
    -- Note: This calls the native ML_TRAIN function which handles the actual model training
    START TRANSACTION;

    -- Call the native ML_TRAIN function with validated parameters
    SELECT ML_TRAIN(in_table_name, in_target_name, in_option, in_model_handle) INTO v_train_obj_check;

    COMMIT;

    -- Step 10: Check training result and handle errors
    IF v_train_obj_check != 0 THEN
        SET v_db_err_msg = CONCAT('ML_TRAIN failed with error code: ', v_train_obj_check);
        SIGNAL SQLSTATE 'HY000'
            SET MESSAGE_TEXT = v_db_err_msg;
    END IF;

    -- Step 11: Log successful training completion
    -- The model metadata and objects are automatically stored by the native ML_TRAIN function

END$$
DELIMITER ;
-- Copyright (c) 2014, 2023, Oracle and/or its affiliates.
--
-- This program is free software; you can redistribute it and/or modify
-- it under the terms of the GNU General Public License as published by
-- the Free Software Foundation; version 2 of the License.
--
-- This program is distributed in the hope that it will be useful,
-- but WITHOUT ANY WARRANTY; without even the implied warranty of
-- MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
-- GNU General Public License for more details.
--
-- You should have received a copy of the GNU General Public License
-- along with this program; if not, write to the Free Software
-- Foundation, Inc., 51 Franklin St, Fifth Floor, Boston, MA 02110-1301 USA
-- Copyright (c) 2023, Shannon Data AI and/or its affiliates.

DROP PROCEDURE IF EXISTS ml_predict_table;

DELIMITER $$

CREATE DEFINER='mysql.sys'@'localhost' PROCEDURE ml_predict_table (
        in_sch_tb_name varchar(256),
        in_model_handle_name VARCHAR(256),
        in_output_table_name VARCHAR(256),
        in_model_option JSON
    )
    COMMENT '
ML_PREDICT_TABLE generates predictions for an entire table of unlabeled data and saves the results to an output table.
Parameters
-----------

in_sch_tb_name varchar(256):
  Specifies the fully qualified name of the input table (schema_name.table_name). The input table should contain the same feature columns as the training dataset but no target column.
in_model_handle_name (VARCHAR(256)):
  Specifies the model handle or a session variable containing the model handle.
in_output_table_name VARCHAR(256):
  Specifies the table where predictions are stored. The table is created if it does not exist. A fully qualified table name must be specified (schema_name.table_name). If the table already exists, an error is returned.
in_model_option JSON:
  A set of options in JSON format.
Example
-----------
mysql> CALL sys.ML_PREDICT_TABLE(JSON_OBJECT(\'in_sch_tb_name\', \'in_model_handle_name\',
          \'in_output_table_name\', in_model_option);
    '
    SQL SECURITY INVOKER
    DETERMINISTIC
    CONTAINS SQL
BEGIN
    DECLARE v_db_err_msg TEXT;
    DECLARE v_pred_table_obj_check JSON;
    DECLARE v_in_schema_name VARCHAR(64);
    DECLARE v_in_table_name VARCHAR(64);
    DECLARE v_out_schema_name VARCHAR(64);
    DECLARE v_out_table_name VARCHAR(64);

    DECLARE v_table_count INT;
    DECLARE v_model_user_name VARCHAR(64);
    DECLARE v_model_sch_name VARCHAR(64);
    DECLARE v_model_target_col_name VARCHAR(255);

    SET @pk_col = '_4aad19ca6e_pk_id';

    -- CHECK input sch_tb_name format
    IF in_sch_tb_name NOT REGEXP '^[^.]+\.[^.]+$' THEN
        SIGNAL SQLSTATE '45000'
        SET MESSAGE_TEXT = 'Invalid schema.table format, please using fully qualified name of the table.';
    END IF;

    -- CHECK OUTPUT TABLE NAME FORMAT
    IF in_output_table_name NOT REGEXP '^[^.]+\.[^.]+$' THEN
        SIGNAL SQLSTATE '45000'
        SET MESSAGE_TEXT = 'Invalid schema.table format, please using fully qualified name of the table.';
    END IF;

    SELECT SUBSTRING_INDEX(in_sch_tb_name, '.', 1) INTO v_in_schema_name;
    SELECT SUBSTRING_INDEX(in_sch_tb_name, '.', -1) INTO v_in_table_name;
    
    SELECT COUNT(*) INTO v_table_count
    FROM INFORMATION_SCHEMA.TABLES
    WHERE TABLE_SCHEMA = v_in_schema_name AND TABLE_NAME = v_in_table_name;
    IF v_table_count = 0 THEN
        SET v_db_err_msg = CONCAT(in_sch_tb_name, ' you specified as input does not exists.');
        SIGNAL SQLSTATE 'HY000'
            SET MESSAGE_TEXT = v_db_err_msg;
    END IF;

    SELECT SUBSTRING_INDEX(in_output_table_name, '.', 1) INTO v_out_schema_name;
    SELECT SUBSTRING_INDEX(in_output_table_name, '.', -1) INTO v_out_table_name;
    
    SELECT COUNT(*) INTO v_table_count
    FROM INFORMATION_SCHEMA.TABLES
    WHERE TABLE_SCHEMA = v_out_schema_name AND TABLE_NAME = v_out_table_name;
    IF v_table_count != 0 THEN
        SET v_db_err_msg = CONCAT(in_output_table_name, ' you specified as input already exists.');
        SIGNAL SQLSTATE 'HY000'
            SET MESSAGE_TEXT = v_db_err_msg;
    END IF;

    SELECT COUNT(*) INTO @has_pk FROM information_schema.TABLE_CONSTRAINTS
    WHERE TABLE_SCHEMA = v_in_schema_name
    AND TABLE_NAME = v_in_table_name
    AND CONSTRAINT_TYPE = 'PRIMARY KEY';

    SELECT COUNT(*) INTO @conflict  FROM information_schema.COLUMNS
    WHERE TABLE_SCHEMA = @schema_name
    AND TABLE_NAME = @table_name
    AND COLUMN_NAME = @pk_col
    AND (COLUMN_KEY != 'PRI' OR COLUMN_KEY IS NULL);

    IF @conflict > 0 THEN
      SIGNAL SQLSTATE '45000' 
      SET MESSAGE_TEXT = 'Conflict: Column name already exists and is not a primary key.';
    END IF;

    SET @sql = CONCAT(
      'CREATE TABLE ', v_out_schema_name, '.', v_out_table_name, ' LIKE ', v_in_schema_name, '.', v_in_table_name, ';'
    );
    PREPARE stmt FROM @sql;
    EXECUTE stmt;
    DEALLOCATE PREPARE stmt;

    SET @sql = CONCAT(
      'ALTER TABLE ', v_out_schema_name, '.', v_out_table_name, ' secondary_engine NULL;'
    );
    PREPARE stmt FROM @sql;
    EXECUTE stmt;
    DEALLOCATE PREPARE stmt;

    -- add the primary key if it do not exists.
    IF @has_pk = 0 THEN
     SET @sql = CONCAT(
       'ALTER TABLE ', v_out_schema_name, '.', v_out_table_name, 
       ' ADD COLUMN `', @pk_col, '` INT AUTO_INCREMENT PRIMARY KEY;'
      );
      PREPARE stmt FROM @sql;
      EXECUTE stmt;
      DEALLOCATE PREPARE stmt;
    END IF;

    -- add the new column.
    SET @sql = CONCAT(
      'ALTER TABLE ', v_out_schema_name, '.', v_out_table_name,
      ' ADD COLUMN prediction VARCHAR(256),',
      ' ADD COLUMN ml_results JSON;'
    );
    PREPARE stmt FROM @sql;
    EXECUTE stmt;
    DEALLOCATE PREPARE stmt;

    SELECT ML_MODEL_PREDICT_TABLE(in_sch_tb_name, in_model_handle_name, in_output_table_name, in_model_option) INTO v_pred_table_obj_check;
        IF v_pred_table_obj_check != 0 THEN
        SET @sql = CONCAT('DROP TABLE ', v_out_schema_name, '.', v_out_table_name, ';');
        PREPARE stmt FROM @sql;
        EXECUTE stmt;
        DEALLOCATE PREPARE stmt;

        SET v_db_err_msg = CONCAT('ML_MODEL_PREDICT_TABLE failed.');
        SIGNAL SQLSTATE 'HY000'
        SET MESSAGE_TEXT = v_db_err_msg;
    END IF;
END$$
DELIMITER ;
-- Copyright (c) 2014, 2023, Oracle and/or its affiliates.
--
-- This program is free software; you can redistribute it and/or modify
-- it under the terms of the GNU General Public License as published by
-- the Free Software Foundation; version 2 of the License.
--
-- This program is distributed in the hope that it will be useful,
-- but WITHOUT ANY WARRANTY; without even the implied warranty of
-- MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
-- GNU General Public License for more details.
--
-- You should have received a copy of the GNU General Public License
-- along with this program; if not, write to the Free Software
-- Foundation, Inc., 51 Franklin St, Fifth Floor, Boston, MA 02110-1301 USA
-- Copyright (c) 2023, Shannon Data AI and/or its affiliates.

DROP PROCEDURE IF EXISTS ml_embed_table;

DELIMITER $$

CREATE DEFINER='mysql.sys'@'localhost' PROCEDURE ml_embed_table (
    IN in_input_table_column VARCHAR(255),
    IN in_output_table_column VARCHAR(255),
    IN in_options JSON
)
COMMENT '
Description
-----------
The ML_EMBED_TABLE routine uses the specified embedding model to encode text data 
from an input table column into vector embeddings and stores them in an output table column.

Parameters
-----------
in_input_table_column (VARCHAR(255)):
  Specifies the input database, table, and column in format: DBName.TableName.ColumnName
  
in_output_table_column (VARCHAR(255)):
  Specifies the output database, table, and column in format: DBName.TableName.ColumnName

in_options (JSON):
  Specifies optional parameters as key-value pairs in JSON format:
  - model_id: The embedding model to use (required)
  - truncate: Whether to truncate inputs longer than maximum token size (true|false, default: true)
  - batch_size: Number of rows to process in each batch (1-1000, default: 1000)
  - details_column: Name of column to store error details (default: "details")

Example
-----------
mysql> CALL sys.ML_EMBED_TABLE(
    "demo_db.input_table.Input", 
    "demo_db.output_table.Output",
    JSON_OBJECT(
        "model_id", "all_minilm_l12_v2",
        "batch_size", 500,
        "truncate", true
    )
);
'
SQL SECURITY INVOKER
MODIFIES SQL DATA
BEGIN
    DECLARE v_input_db VARCHAR(64);
    DECLARE v_input_table VARCHAR(64);
    DECLARE v_input_column VARCHAR(64);
    DECLARE v_output_db VARCHAR(64);
    DECLARE v_output_table VARCHAR(64);
    DECLARE v_output_column VARCHAR(64);
    DECLARE v_model_id VARCHAR(255);
    DECLARE v_truncate BOOLEAN DEFAULT TRUE;
    DECLARE v_batch_size INT DEFAULT 1000;
    DECLARE v_details_column VARCHAR(64) DEFAULT 'details';
    DECLARE v_input_same_as_output BOOLEAN DEFAULT FALSE;
    DECLARE v_table_exists INT DEFAULT 0;
    DECLARE v_column_exists INT DEFAULT 0;
    DECLARE v_has_primary_key INT DEFAULT 0;
    DECLARE v_is_external_table INT DEFAULT 0;
    DECLARE v_sql TEXT;
    DECLARE v_error_msg TEXT DEFAULT '';
    DECLARE v_total_rows INT DEFAULT 0;
    DECLARE v_processed_rows INT DEFAULT 0;
    DECLARE v_batch_start INT DEFAULT 0;

    DECLARE EXIT HANDLER FOR SQLEXCEPTION
    BEGIN
        GET DIAGNOSTICS CONDITION 1
            v_error_msg = MESSAGE_TEXT;
        RESIGNAL SET MESSAGE_TEXT = v_error_msg;
    END;

    -- Parse input table column (DBName.TableName.ColumnName)
    IF CHAR_LENGTH(in_input_table_column) - CHAR_LENGTH(REPLACE(in_input_table_column, '.', '')) != 2 THEN
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Invalid input table column format. Use DBName.TableName.ColumnName';
    END IF;

    SET v_input_db = SUBSTRING_INDEX(in_input_table_column, '.', 1);
    SET v_input_table = SUBSTRING_INDEX(SUBSTRING_INDEX(in_input_table_column, '.', 2), '.', -1);
    SET v_input_column = SUBSTRING_INDEX(in_input_table_column, '.', -1);

    -- Parse output table column (DBName.TableName.ColumnName)
    IF CHAR_LENGTH(in_output_table_column) - CHAR_LENGTH(REPLACE(in_output_table_column, '.', '')) != 2 THEN
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Invalid output table column format. Use DBName.TableName.ColumnName';
    END IF;

    SET v_output_db = SUBSTRING_INDEX(in_output_table_column, '.', 1);
    SET v_output_table = SUBSTRING_INDEX(SUBSTRING_INDEX(in_output_table_column, '.', 2), '.', -1);
    SET v_output_column = SUBSTRING_INDEX(in_output_table_column, '.', -1);

    -- Validate no backticks or periods in names
    IF v_input_db REGEXP '`|\\..*\\.' OR v_input_table REGEXP '`|\\..*\\.' OR 
       v_output_db REGEXP '`|\\..*\\.' OR v_output_table REGEXP '`|\\..*\\.' THEN
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Database and table names cannot contain backticks or periods';
    END IF;

    -- Extract options from JSON
    IF in_options IS NOT NULL AND JSON_VALID(in_options) THEN
        SET v_model_id = JSON_UNQUOTE(JSON_EXTRACT(in_options, '$.model_id'));
        SET v_truncate = COALESCE(CAST(JSON_UNQUOTE(JSON_EXTRACT(in_options, '$.truncate')) AS UNSIGNED), TRUE);
        SET v_batch_size = COALESCE(CAST(JSON_UNQUOTE(JSON_EXTRACT(in_options, '$.batch_size')) AS UNSIGNED), 1000);
        SET v_details_column = COALESCE(JSON_UNQUOTE(JSON_EXTRACT(in_options, '$.details_column')), 'details');
    END IF;

    -- Validate required parameters
    IF v_model_id IS NULL OR v_model_id = '' THEN
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'model_id is required in options';
    END IF;

    -- Validate batch_size range
    IF v_batch_size < 1 OR v_batch_size > 1000 THEN
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'batch_size must be between 1 and 1000';
    END IF;

    -- Check if input table exists
    SELECT COUNT(*) INTO v_table_exists
    FROM information_schema.tables 
    WHERE table_schema = v_input_db AND table_name = v_input_table;

    IF v_table_exists = 0 THEN
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Input table does not exist';
    END IF;

    -- Check if input table has primary key
    SELECT COUNT(*) INTO v_has_primary_key
    FROM information_schema.table_constraints 
    WHERE table_schema = v_input_db 
    AND table_name = v_input_table 
    AND constraint_type = 'PRIMARY KEY';

    IF v_has_primary_key = 0 THEN
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Input table must have a primary key';
    END IF;

    -- Check if input column exists and is valid
    SELECT COUNT(*) INTO v_column_exists
    FROM information_schema.columns 
    WHERE table_schema = v_input_db 
    AND table_name = v_input_table 
    AND column_name = v_input_column
    AND data_type IN ('text', 'varchar', 'char');

    IF v_column_exists = 0 THEN
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Input column does not exist or is not a text/varchar type';
    END IF;

    -- Check if input column is part of primary key
    SELECT COUNT(*) INTO v_column_exists
    FROM information_schema.key_column_usage k
    JOIN information_schema.table_constraints t ON k.constraint_name = t.constraint_name
    WHERE k.table_schema = v_input_db 
    AND k.table_name = v_input_table 
    AND k.column_name = v_input_column
    AND t.constraint_type = 'PRIMARY KEY';
    
    IF v_column_exists > 0 THEN
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Input column cannot be part of the primary key';
    END IF;

    -- Check if input and output tables are the same
    IF v_input_db = v_output_db AND v_input_table = v_output_table THEN
        SET v_input_same_as_output = TRUE;

        -- Check if output column already exists
        SELECT COUNT(*) INTO v_column_exists
        FROM information_schema.columns 
        WHERE table_schema = v_output_db 
        AND table_name = v_output_table 
        AND column_name = v_output_column;

        IF v_column_exists > 0 THEN
            SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Output column already exists in the table';
        END IF;

        -- Add vector column to existing table
        SET v_sql = CONCAT('ALTER TABLE `', v_output_db, '`.`', v_output_table, '` 
                           ADD COLUMN `', v_output_column, '` VECTOR');

        -- Add details column if specified and doesn't exist
        SELECT COUNT(*) INTO v_column_exists
        FROM information_schema.columns 
        WHERE table_schema = v_output_db 
        AND table_name = v_output_table 
        AND column_name = v_details_column;

        IF v_column_exists = 0 THEN
            SET v_sql = CONCAT(v_sql, ', ADD COLUMN `', v_details_column, '` TEXT');
        END IF;

        SET @sql = v_sql;
        PREPARE stmt FROM @sql;
        EXECUTE stmt;
        DEALLOCATE PREPARE stmt;

    ELSE
        -- Create new output table
        -- First check if output table already exists
        SELECT COUNT(*) INTO v_table_exists
        FROM information_schema.tables 
        WHERE table_schema = v_output_db AND table_name = v_output_table;

        IF v_table_exists > 0 THEN
            SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Output table already exists';
        END IF;

        -- Get primary key columns from input table
        SET v_sql = CONCAT('CREATE TABLE `', v_output_db, '`.`', v_output_table, '` AS 
                           SELECT ');

        -- Add primary key columns
        SELECT GROUP_CONCAT(CONCAT('`', column_name, '`') ORDER BY ordinal_position)
        INTO @pk_columns
        FROM information_schema.key_column_usage k
        JOIN information_schema.table_constraints t ON k.constraint_name = t.constraint_name
        WHERE k.table_schema = v_input_db 
        AND k.table_name = v_input_table 
        AND t.constraint_type = 'PRIMARY KEY';

        SET v_sql = CONCAT(v_sql, @pk_columns, ' FROM `', v_input_db, '`.`', v_input_table, '`');

        SET @sql = v_sql;
        PREPARE stmt FROM @sql;
        EXECUTE stmt;
        DEALLOCATE PREPARE stmt;

        -- Add vector column
        SET v_sql = CONCAT('ALTER TABLE `', v_output_db, '`.`', v_output_table, '` 
                           ADD COLUMN `', v_output_column, '` VECTOR,
                           ADD COLUMN `', v_details_column, '` TEXT');

        SET @sql = v_sql;
        PREPARE stmt FROM @sql;
        EXECUTE stmt;
        DEALLOCATE PREPARE stmt;

        -- Create primary key on new table
        SET v_sql = CONCAT('ALTER TABLE `', v_output_db, '`.`', v_output_table, '` 
                           ADD PRIMARY KEY (', @pk_columns, ')');

        SET @sql = v_sql;
        PREPARE stmt FROM @sql;
        EXECUTE stmt;
        DEALLOCATE PREPARE stmt;
    END IF;

    -- Process embeddings in batches using ML_EMBED_ROW
    IF v_input_same_as_output THEN
        -- Update same table with embeddings
        SET v_sql = CONCAT('UPDATE `', v_output_db, '`.`', v_output_table, '` 
                           SET `', v_output_column, '` = sys.ML_EMBED_ROW(`', v_input_column, '`, 
                           JSON_OBJECT("model_id", "', v_model_id, '", "truncate", ', v_truncate, ')),
                           `', v_details_column, '` = 
                           CASE 
                               WHEN `', v_input_column, '` IS NULL OR TRIM(`', v_input_column, '`) = "" 
                               THEN "Empty or null input text"
                               ELSE NULL 
                           END
                           WHERE `', v_input_column, '` IS NOT NULL AND TRIM(`', v_input_column, '`) != ""');
    ELSE
        -- Insert data with embeddings into new table
        SELECT GROUP_CONCAT(CONCAT('s.`', column_name, '`') ORDER BY ordinal_position)
        INTO @pk_columns_prefixed
        FROM information_schema.key_column_usage k
        JOIN information_schema.table_constraints t ON k.constraint_name = t.constraint_name
        WHERE k.table_schema = v_input_db 
        AND k.table_name = v_input_table 
        AND t.constraint_type = 'PRIMARY KEY';

        SET v_sql = CONCAT('INSERT INTO `', v_output_db, '`.`', v_output_table, '` 
                           SELECT ', @pk_columns, ',
                           sys.ML_EMBED_ROW(s.`', v_input_column, '`, 
                           JSON_OBJECT("model_id", "', v_model_id, '", "truncate", ', v_truncate, ')) as `', v_output_column, '`,
                           CASE 
                               WHEN s.`', v_input_column, '` IS NULL OR TRIM(s.`', v_input_column, '`) = "" 
                               THEN "Empty or null input text"
                               ELSE NULL 
                           END as `', v_details_column, '`
                           FROM `', v_input_db, '`.`', v_input_table, '` s
                           WHERE s.`', v_input_column, '` IS NOT NULL AND TRIM(s.`', v_input_column, '`) != ""');
    END IF;

    SET @sql = v_sql;
    PREPARE stmt FROM @sql;
    EXECUTE stmt;
    DEALLOCATE PREPARE stmt;

END$$

DELIMITER ;-- Copyright (c) 2014, 2023, Oracle and/or its affiliates.
--
-- This program is free software; you can redistribute it and/or modify
-- it under the terms of the GNU General Public License as published by
-- the Free Software Foundation; version 2 of the License.
--
-- This program is distributed in the hope that it will be useful,
-- but WITHOUT ANY WARRANTY; without even the implied warranty of
-- MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
-- GNU General Public License for more details.
--
-- You should have received a copy of the GNU General Public License
-- along with this program; if not, write to the Free Software
-- Foundation, Inc., 51 Franklin St, Fifth Floor, Boston, MA 02110-1301 USA
-- Copyright (c) 2023, Shannon Data AI and/or its affiliates.

DROP PROCEDURE IF EXISTS ml_rag;

DELIMITER $$

CREATE DEFINER='mysql.sys'@'localhost' PROCEDURE ml_rag (
    IN in_query_text TEXT,
    OUT out_output JSON,
    IN in_options JSON
)
COMMENT '
Description
-----------
The ML_RAG routine performs retrieval-augmented generation (RAG) by:
- Taking a natural-language query
- Retrieving context from relevant documents using semantic search
- Generating a response that integrates information from the retrieved documents

This routine aims to provide detailed, accurate, and contextually relevant answers 
by augmenting a generative model with information retrieved from a comprehensive knowledge base.

Parameters
-----------
in_query_text (TEXT):
  The natural-language query to process

out_output (JSON):
  Stores the generated output containing:
  - text: the generated text-based response
  - citations: array of retrieved segments with details (segment, distance, document_name, vector_store)

in_options (JSON):
  Specifies optional parameters as key-value pairs:
  - vector_store: JSON array of vector store table names to use
  - schema: JSON array of schema names to search
  - n_citations: number of segments for context retrieval (default: 3, range: 0-100)
  - distance_metric: COSINE|DOT|EUCLIDEAN (default: COSINE)
  - document_name: JSON array of specific documents to use
  - skip_generate: true|false (default: false)
  - model_options: additional options for text generation
  - exclude_vector_store: JSON array of vector stores to exclude
  - exclude_document_name: JSON array of documents to exclude
  - retrieval_options: context retrieval parameters
  - vector_store_columns: column name mappings
  - embed_model_id: embedding model to use (default: multilingual-e5-small)
  - query_embedding: pre-computed query embedding

Example
-----------
mysql> SET @options = JSON_OBJECT("vector_store", JSON_ARRAY("demo_db.demo_embeddings"));
mysql> CALL sys.ML_RAG("What is AutoML", @output, @options);
mysql> SELECT @output;
'
SQL SECURITY INVOKER
READS SQL DATA
BEGIN
    -- =========================
    -- Variable declarations
    -- =========================
    DECLARE v_vector_store JSON;
    DECLARE v_schema JSON;
    DECLARE v_n_citations INT DEFAULT 3;
    DECLARE v_distance_metric VARCHAR(32) DEFAULT 'COSINE';
    DECLARE v_document_name JSON;
    DECLARE v_skip_generate BOOLEAN DEFAULT FALSE;
    DECLARE v_model_options JSON;
    DECLARE v_embed_model_id VARCHAR(255) DEFAULT 'all-MiniLM-L12-v2';
    DECLARE v_query_embedding VECTOR(384);
    DECLARE v_max_distance DECIMAL(10,6) DEFAULT 0.6;
    DECLARE v_percentage_distance DECIMAL(5,2) DEFAULT 20.0;
    DECLARE v_segment_overlap INT DEFAULT 1;

    DECLARE v_generated_text LONGTEXT DEFAULT '';
    DECLARE v_citations JSON DEFAULT JSON_ARRAY();
    DECLARE v_error_msg TEXT DEFAULT '';
    DECLARE v_store_count INT DEFAULT 0;
    DECLARE v_current_store VARCHAR(255);
    DECLARE v_curr_schema VARCHAR(64);
    DECLARE v_curr_table VARCHAR(64);
    DECLARE v_vector_string TEXT;
    DECLARE v_min_distance DECIMAL(10,6);
    DECLARE v_max_allowed_distance DECIMAL(10,6);

    DECLARE v_doc_filter TEXT DEFAULT '';
    DECLARE v_doc_count INT DEFAULT 0;
    DECLARE v_doc_name TEXT;

    -- Vector store column mapping (default)
    DECLARE v_col_segment VARCHAR(255) DEFAULT 'segment';
    DECLARE v_col_segment_embedding VARCHAR(255) DEFAULT 'segment_embedding';
    DECLARE v_col_document_name VARCHAR(255) DEFAULT 'document_name';
    DECLARE v_col_document_id VARCHAR(255) DEFAULT 'document_id';
    DECLARE v_col_metadata VARCHAR(255) DEFAULT 'metadata';
    DECLARE v_col_segment_number VARCHAR(255) DEFAULT 'segment_number';

    -- Cursor
    DECLARE done INT DEFAULT FALSE;
    DECLARE store_cursor CURSOR FOR 
        SELECT store_name, schema_name, table_name FROM temp_vector_stores;
    DECLARE CONTINUE HANDLER FOR NOT FOUND SET done = TRUE;

    -- Exception handler
    DECLARE EXIT HANDLER FOR SQLEXCEPTION
    BEGIN
        GET DIAGNOSTICS CONDITION 1 v_error_msg = MESSAGE_TEXT;
        DROP TEMPORARY TABLE IF EXISTS temp_vector_stores;
        DROP TEMPORARY TABLE IF EXISTS temp_citations_base;
        DROP TEMPORARY TABLE IF EXISTS temp_citations_overlap;
        DROP TEMPORARY TABLE IF EXISTS temp_citations_final;
        SET out_output = JSON_OBJECT('error', CONCAT('RAG processing failed: ', v_error_msg));
        RESIGNAL;
    END;

    -- Input validation
    IF in_query_text IS NULL OR TRIM(in_query_text) = '' THEN
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Query text cannot be null or empty';
    END IF;

    -- Parse options
    IF JSON_VALID(in_options) AND in_options IS NOT NULL THEN
        SET v_vector_store = JSON_EXTRACT(in_options, '$.vector_store');
        SET v_schema = JSON_EXTRACT(in_options, '$.schema');
        SET v_n_citations = COALESCE(CAST(JSON_UNQUOTE(JSON_EXTRACT(in_options, '$.n_citations')) AS UNSIGNED), 3);
        SET v_distance_metric = COALESCE(JSON_UNQUOTE(JSON_EXTRACT(in_options, '$.distance_metric')), 'COSINE');
        SET v_document_name = JSON_EXTRACT(in_options, '$.document_name');
        SET v_skip_generate = COALESCE(CAST(JSON_UNQUOTE(JSON_EXTRACT(in_options, '$.skip_generate')) AS UNSIGNED), FALSE);
        SET v_model_options = JSON_EXTRACT(in_options, '$.model_options');
        SET v_embed_model_id = COALESCE(JSON_UNQUOTE(JSON_EXTRACT(in_options, '$.embed_model_id')), 'multilingual-e5-small');

        -- Vector store columns override
        IF JSON_EXTRACT(in_options, '$.vector_store_columns') IS NOT NULL THEN
            SET v_col_segment = COALESCE(JSON_UNQUOTE(JSON_EXTRACT(in_options, '$.vector_store_columns.segment')), v_col_segment);
            SET v_col_segment_embedding = COALESCE(JSON_UNQUOTE(JSON_EXTRACT(in_options, '$.vector_store_columns.segment_embedding')), v_col_segment_embedding);
            SET v_col_document_name = COALESCE(JSON_UNQUOTE(JSON_EXTRACT(in_options, '$.vector_store_columns.document_name')), v_col_document_name);
            SET v_col_document_id = COALESCE(JSON_UNQUOTE(JSON_EXTRACT(in_options, '$.vector_store_columns.document_id')), v_col_document_id);
            SET v_col_metadata = COALESCE(JSON_UNQUOTE(JSON_EXTRACT(in_options, '$.vector_store_columns.metadata')), v_col_metadata);
            SET v_col_segment_number = COALESCE(JSON_UNQUOTE(JSON_EXTRACT(in_options, '$.vector_store_columns.segment_number')), v_col_segment_number);
        END IF;

        -- Retrieval options
        IF JSON_EXTRACT(in_options, '$.retrieval_options') IS NOT NULL THEN
            SET v_max_distance = COALESCE(CAST(JSON_UNQUOTE(JSON_EXTRACT(in_options, '$.retrieval_options.max_distance')) AS DECIMAL(10,6)), 0.6);
            SET v_percentage_distance = COALESCE(CAST(JSON_UNQUOTE(JSON_EXTRACT(in_options, '$.retrieval_options.percentage_distance')) AS DECIMAL(5,2)), 20.0);
            SET v_segment_overlap = COALESCE(CAST(JSON_UNQUOTE(JSON_EXTRACT(in_options, '$.retrieval_options.segment_overlap')) AS UNSIGNED), 1);
        END IF;

        -- Pre-computed query embedding
        IF JSON_EXTRACT(in_options, '$.query_embedding') IS NOT NULL THEN
            SET v_query_embedding = STRING_TO_VECTOR(JSON_UNQUOTE(JSON_EXTRACT(in_options, '$.query_embedding')));
        END IF;
    END IF;

    -- Parameter validation
    IF v_n_citations < 0 OR v_n_citations > 100 THEN
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'n_citations must be between 0 and 100';
    END IF;

    IF v_distance_metric NOT IN ('COSINE', 'DOT', 'EUCLIDEAN', 'L2') THEN
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'distance_metric must be COSINE, DOT, EUCLIDEAN, or L2';
    END IF;

    -- Generate query embedding if needed
    IF v_query_embedding IS NULL THEN
        SELECT ML_MODEL_EMBED_ROW(
            in_query_text, 
            JSON_OBJECT('model_id', v_embed_model_id, 'truncate', true)
        ) INTO v_query_embedding;

        IF v_query_embedding IS NULL THEN
            SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Failed to generate query embedding';
        END IF;
    END IF;

    SET v_vector_string = REPLACE(VECTOR_TO_STRING(v_query_embedding), '''', '''''');

    -- Prepare vector stores list
    DROP TEMPORARY TABLE IF EXISTS temp_vector_stores;
    CREATE TEMPORARY TABLE temp_vector_stores (
        store_name VARCHAR(255) COLLATE utf8mb4_0900_ai_ci PRIMARY KEY,
        schema_name VARCHAR(64) COLLATE utf8mb4_0900_ai_ci,
        table_name VARCHAR(64) COLLATE utf8mb4_0900_ai_ci
    ) ENGINE=InnoDB;

    IF v_vector_store IS NOT NULL AND JSON_LENGTH(v_vector_store) > 0 THEN
        SET v_store_count = JSON_LENGTH(v_vector_store);
        WHILE v_store_count > 0 DO
            SET v_store_count = v_store_count - 1;
            SET v_current_store = JSON_UNQUOTE(JSON_EXTRACT(v_vector_store, CONCAT('$[', v_store_count, ']')));
            IF LOCATE('.', v_current_store) > 0 THEN
                INSERT INTO temp_vector_stores (store_name, schema_name, table_name) VALUES (
                    v_current_store,
                    SUBSTRING_INDEX(v_current_store, '.', 1),
                    SUBSTRING_INDEX(v_current_store, '.', -1)
                );
            ELSE
                INSERT INTO temp_vector_stores (store_name, schema_name, table_name) VALUES (
                    v_current_store,
                    DATABASE(),
                    v_current_store
                );
            END IF;
        END WHILE;
    ELSE
        -- Auto-discover tables with matching embedding column
        INSERT INTO temp_vector_stores (store_name, schema_name, table_name)
        SELECT CONCAT(c.TABLE_SCHEMA, '.', c.TABLE_NAME),
               c.TABLE_SCHEMA,
               c.TABLE_NAME
        FROM information_schema.COLUMNS c
        WHERE c.DATA_TYPE = 'vector'
          AND c.COLUMN_NAME = v_col_segment_embedding
          AND c.TABLE_SCHEMA NOT IN ('information_schema','mysql','performance_schema','sys')
        GROUP BY c.TABLE_SCHEMA, c.TABLE_NAME;
    END IF;

    -- 1. Create base retrieval results table
    DROP TEMPORARY TABLE IF EXISTS temp_citations_base;
    CREATE TEMPORARY TABLE temp_citations_base (
        segment LONGTEXT COLLATE utf8mb4_0900_ai_ci,
        distance DECIMAL(10,6),
        document_name VARCHAR(255) COLLATE utf8mb4_0900_ai_ci,
        vector_store VARCHAR(255) COLLATE utf8mb4_0900_ai_ci,
        segment_number INT,
        metadata JSON,
        INDEX idx_distance (distance)
    ) ENGINE=InnoDB;

    -- 2. base retrieve
    OPEN store_cursor;
    store_loop: LOOP
        FETCH store_cursor INTO v_current_store, v_curr_schema, v_curr_table;
        IF done THEN
            LEAVE store_loop;
        END IF;

        SET @sql = CONCAT(
            'INSERT INTO temp_citations_base (segment, distance, document_name, vector_store, segment_number, metadata) ',
            'SELECT COALESCE(CAST(`', v_col_segment, '` AS CHAR CHARACTER SET utf8mb4) COLLATE utf8mb4_0900_ai_ci, '''') AS segment, ',
            'DISTANCE(`', v_col_segment_embedding, '`, STRING_TO_VECTOR(''', v_vector_string, '''), ''', v_distance_metric, ''') AS distance, ',
            'COALESCE(CAST(`', v_col_document_name, '` AS CHAR CHARACTER SET utf8mb4) COLLATE utf8mb4_0900_ai_ci, '''') AS document_name, ',
            '''', REPLACE(v_current_store, '''', ''''''), ''' AS vector_store, ',
            'COALESCE(`', v_col_segment_number, '`, 0) AS segment_number, ',
            'COALESCE(`', v_col_metadata, '`, JSON_OBJECT()) AS metadata ',
            'FROM `', v_curr_schema, '`.`', v_curr_table, '` ',
            'WHERE `', v_col_segment, '` IS NOT NULL AND CAST(`', v_col_segment, '` AS CHAR CHARACTER SET utf8mb4) COLLATE utf8mb4_0900_ai_ci <> '''' ',
            'AND `', v_col_segment_embedding, '` IS NOT NULL '
        );

        -- Document name filter
        IF v_document_name IS NOT NULL AND JSON_LENGTH(v_document_name) > 0 THEN
            SET v_doc_count = JSON_LENGTH(v_document_name);
            SET v_doc_filter = '';
            WHILE v_doc_count > 0 DO
                SET v_doc_count = v_doc_count - 1;
                SET v_doc_name = REPLACE(JSON_UNQUOTE(JSON_EXTRACT(v_document_name, CONCAT('$[', v_doc_count, ']'))), '''', '''''');
                SET v_doc_filter = CONCAT(v_doc_filter, IF(v_doc_filter = '', '', ', '), '''', v_doc_name, '''');
            END WHILE;
            SET @sql = CONCAT(@sql, ' AND CAST(`', v_col_document_name, '` AS CHAR CHARACTER SET utf8mb4) COLLATE utf8mb4_0900_ai_ci IN (', v_doc_filter, ') ');
        END IF;

        SET @sql = CONCAT(@sql, ' ORDER BY distance ASC LIMIT ', CAST(v_n_citations * 2 AS CHAR));

        PREPARE stmt FROM @sql;
        EXECUTE stmt;
        DEALLOCATE PREPARE stmt;

    END LOOP;
    CLOSE store_cursor;

    -- 3. Handle segment overlap (if needed)
    IF v_segment_overlap > 0 THEN
        DROP TEMPORARY TABLE IF EXISTS temp_citations_overlap;
        CREATE TEMPORARY TABLE temp_citations_overlap (
            segment LONGTEXT,
            distance DECIMAL(10,6),
            document_name VARCHAR(255),
            vector_store VARCHAR(255),
            segment_number INT,
            metadata JSON,
            INDEX idx_distance (distance)
        ) ENGINE=InnoDB;

        -- reopen cursor to handler overlap
        SET done = FALSE;
        OPEN store_cursor;
        overlap_loop: LOOP
            FETCH store_cursor INTO v_current_store, v_curr_schema, v_curr_table;
            IF done THEN
                LEAVE overlap_loop;
            END IF;

            -- get the adjacent segment
            SET @overlap_sql = CONCAT(
                'INSERT INTO temp_citations_overlap (segment, distance, document_name, vector_store, segment_number, metadata) ',
                'SELECT CAST(t2.`', v_col_segment, '` AS CHAR CHARACTER SET utf8mb4) COLLATE utf8mb4_0900_ai_ci, (base.distance + 0.01), base.document_name, base.vector_store, t2.`', v_col_segment_number, '`, t2.`', v_col_metadata, '` ',
                'FROM `', v_curr_schema, '`.`', v_curr_table, '` t2 ',
                'INNER JOIN temp_citations_base base ',
                'ON CAST(t2.`', v_col_document_name, '` AS CHAR CHARACTER SET utf8mb4) COLLATE utf8mb4_0900_ai_ci = base.document_name COLLATE utf8mb4_0900_ai_ci ',
                'AND ABS(t2.`', v_col_segment_number, '` - base.segment_number) <= ', CAST(v_segment_overlap AS CHAR), ' ',
                'AND t2.`', v_col_segment_number, '` <> base.segment_number ',
                'WHERE t2.`', v_col_segment, '` IS NOT NULL AND CAST(t2.`', v_col_segment, '` AS CHAR CHARACTER SET utf8mb4) COLLATE utf8mb4_0900_ai_ci <> '''' ',
                'AND base.vector_store COLLATE utf8mb4_0900_ai_ci = ''', REPLACE(v_current_store, '''', ''''''), ''' '
            );

            PREPARE stmt2 FROM @overlap_sql;
            EXECUTE stmt2;
            DEALLOCATE PREPARE stmt2;

        END LOOP;
        CLOSE store_cursor;

        -- Merge base results and overlap results
        DROP TEMPORARY TABLE IF EXISTS temp_citations_final;
        CREATE TEMPORARY TABLE temp_citations_final (
            segment LONGTEXT,
            distance DECIMAL(10,6),
            document_name VARCHAR(255),
            vector_store VARCHAR(255),
            segment_number INT,
            metadata JSON,
            INDEX idx_distance (distance)
        ) ENGINE=InnoDB;

        INSERT INTO temp_citations_final SELECT * FROM temp_citations_base;
        
        INSERT INTO temp_citations_final 
        SELECT o.* FROM temp_citations_overlap o
        WHERE NOT EXISTS (
            SELECT 1 FROM temp_citations_base b 
            WHERE b.document_name = o.document_name 
            AND b.segment_number = o.segment_number
        );

        DROP TEMPORARY TABLE temp_citations_base;
        DROP TEMPORARY TABLE temp_citations_overlap;

    ELSE
        -- not overlap
        DROP TEMPORARY TABLE IF EXISTS temp_citations_final;
        RENAME TABLE temp_citations_base TO temp_citations_final;
    END IF;

    -- =========================
    -- Distance filtering and ranking
    -- =========================
    SELECT MIN(distance) INTO v_min_distance FROM temp_citations_final;
    IF v_min_distance IS NULL THEN
        SET v_min_distance = v_max_distance;
    END IF;
    SET v_max_allowed_distance = LEAST(v_max_distance, v_min_distance + (v_min_distance * v_percentage_distance / 100.0));
    DELETE FROM temp_citations_final WHERE distance > v_max_allowed_distance;

    -- =========================
    -- Build citations JSON
    -- =========================
    SELECT JSON_ARRAYAGG(
        JSON_OBJECT(
            'segment', segment,
            'distance', distance,
            'document_name', document_name,
            'vector_store', vector_store,
            'segment_number', segment_number,
            'metadata', metadata
        )
    ) INTO v_citations
    FROM (
        SELECT * FROM temp_citations_final
        ORDER BY distance ASC
        LIMIT v_n_citations
    ) ordered_citations;

    IF v_citations IS NULL THEN
        SET v_citations = JSON_ARRAY();
    END IF;

    -- =========================
    -- Generate response
    -- =========================
    IF NOT v_skip_generate THEN
        SELECT COALESCE(GROUP_CONCAT(segment SEPARATOR '\n\n'), '') INTO @context
        FROM (
            SELECT segment FROM temp_citations_final
            ORDER BY distance ASC
            LIMIT v_n_citations
        ) contexts;

        SET @prompt = CONCAT(
            'Based on the following context, answer the question: ', COALESCE(in_query_text, ''), '\n\nContext:\n', COALESCE(@context, ''), '\n\nAnswer:'
        );

        IF v_model_options IS NULL THEN
            SET v_model_options = JSON_OBJECT(
                'model_id', 'Llama-3.2-3B-Instruct',
                'max_tokens', 1000,
                'temperature', 0.7
            );
        END IF;

        SELECT ML_MODEL_GENERATE(@prompt, v_model_options) INTO v_generated_text;

        IF v_generated_text IS NULL OR v_generated_text = '' THEN
            SET v_generated_text = 'Unable to generate response based on the provided context.';
        END IF;
    END IF;

    -- =========================
    -- Build final output
    -- =========================
    SELECT COUNT(*) INTO @total_found FROM temp_citations_final;
    SET out_output = JSON_OBJECT(
        'text', v_generated_text,
        'citations', COALESCE(v_citations, JSON_ARRAY()),
        'query_embedding', v_vector_string,
        'processing_info', JSON_OBJECT(
            'total_citations_found', @total_found,
            'citations_returned', LEAST(v_n_citations, @total_found),
            'min_distance', v_min_distance,
            'max_allowed_distance', v_max_allowed_distance,
            'vector_stores_queried', (SELECT COUNT(*) FROM temp_vector_stores)
        )
    );

    -- Clean up all temporary tables
    DROP TEMPORARY TABLE IF EXISTS temp_vector_stores;
    DROP TEMPORARY TABLE IF EXISTS temp_citations_final;

END$$

DELIMITER ;-- Copyright (c) 2014, 2023, Oracle and/or its affiliates.
--
-- This program is free software; you can redistribute it and/or modify
-- it under the terms of the GNU General Public License as published by
-- the Free Software Foundation; version 2 of the License.
--
-- This program is distributed in the hope that it will be useful,
-- but WITHOUT ANY WARRANTY; without even the implied warranty of
-- MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
-- GNU General Public License for more details.
--
-- You should have received a copy of the GNU General Public License
-- along with this program; if not, write to the Free Software
-- Foundation, Inc., 51 Franklin St, Fifth Floor, Boston, MA 02110-1301 USA
-- Copyright (c) 2023, Shannon Data AI and/or its affiliates.

DROP PROCEDURE IF EXISTS ml_rag_table;

DELIMITER $$

CREATE DEFINER='mysql.sys'@'localhost' PROCEDURE ml_rag_table (
    IN in_input_table_column VARCHAR(255),
    IN in_output_table_column VARCHAR(255),
    IN in_options JSON
)
COMMENT '
Description
-----------
The ML_RAG_TABLE routine runs multiple retrieval-augmented generation (RAG) queries
in a batch, in parallel. The output generated for every input query is the same as
the output generated by the ML_RAG routine.

Parameters
-----------
in_input_table_column (VARCHAR(255)):
  Specifies the names of the input database, table, and column that contains the
  natural-language queries in format: DBName.TableName.ColumnName

in_output_table_column (VARCHAR(255)):
  Specifies the names of the database, table, and column where the generated
  text-based response is stored in format: DBName.TableName.ColumnName

in_options (JSON):
  Specifies optional parameters as key-value pairs:
  - vector_store: JSON array of vector store table names to use
  - schema: JSON array of schema names to search
  - n_citations: number of segments for context retrieval (default: 3, range: 0-100)
  - distance_metric: COSINE|DOT|EUCLIDEAN (default: COSINE)
  - document_name: JSON array of specific documents to use
  - skip_generate: true|false (default: false)
  - model_options: additional options for text generation
  - exclude_vector_store: JSON array of vector stores to exclude
  - exclude_document_name: JSON array of documents to exclude
  - batch_size: batch size for processing (default: 1000, range: 1-1000)
  - retrieval_options: context retrieval parameters
  - vector_store_columns: column name mappings
  - embed_model_id: embedding model to use (default: multilingual-e5-small)
  - embed_column: pre-computed query embeddings column name
  - fail_on_embedding_error: true|false (default: true)

Example
-----------
mysql> CALL sys.ML_RAG_TABLE("demo_db.input_table.Input", "demo_db.output_table.Output",
       JSON_OBJECT("vector_store", JSON_ARRAY("demo_db.demo_embeddings"), "batch_size", 10));
'
SQL SECURITY INVOKER
READS SQL DATA
MODIFIES SQL DATA
BEGIN
    -- =========================
    -- Variable declarations
    -- =========================
    DECLARE v_input_db VARCHAR(64);
    DECLARE v_input_table VARCHAR(64);
    DECLARE v_input_column VARCHAR(64);
    DECLARE v_output_db VARCHAR(64);
    DECLARE v_output_table VARCHAR(64);
    DECLARE v_output_column VARCHAR(64);
    DECLARE v_batch_size INT DEFAULT 1000;
    DECLARE v_fail_on_embedding_error BOOLEAN DEFAULT TRUE;
    DECLARE v_embed_column VARCHAR(64) DEFAULT NULL;

    DECLARE v_current_query_text TEXT;
    DECLARE v_current_rag_output JSON;
    DECLARE v_current_id VARCHAR(255);
    DECLARE v_batch_count INT DEFAULT 0;
    DECLARE v_total_processed INT DEFAULT 0;
    DECLARE v_total_failed INT DEFAULT 0;
    DECLARE v_error_msg TEXT DEFAULT '';

    -- Table existence flags
    DECLARE v_input_table_exists BOOLEAN DEFAULT FALSE;
    DECLARE v_output_table_exists BOOLEAN DEFAULT FALSE;
    DECLARE v_same_table BOOLEAN DEFAULT FALSE;

    -- Cursor variables
    DECLARE done INT DEFAULT FALSE;
    DECLARE batch_cursor CURSOR FOR 
        SELECT pk_values, query_text FROM temp_batch_data ORDER BY batch_order;
    DECLARE CONTINUE HANDLER FOR NOT FOUND SET done = TRUE;

    -- Exception handler - FIXED: Use variable for SIGNAL message
    DECLARE EXIT HANDLER FOR SQLEXCEPTION
    BEGIN
        GET DIAGNOSTICS CONDITION 1 v_error_msg = MESSAGE_TEXT;
        DROP TEMPORARY TABLE IF EXISTS temp_batch_data;
        DROP TEMPORARY TABLE IF EXISTS temp_pk_columns;
        SET v_error_msg = CONCAT('ML_RAG_TABLE failed: ', v_error_msg);
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = v_error_msg;
    END;

    -- Input validation
    IF in_input_table_column IS NULL OR TRIM(in_input_table_column) = '' THEN
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Input table column specification cannot be null or empty';
    END IF;

    IF in_output_table_column IS NULL OR TRIM(in_output_table_column) = '' THEN
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Output table column specification cannot be null or empty';
    END IF;

    -- Parse input table specification
    IF (LENGTH(in_input_table_column) - LENGTH(REPLACE(in_input_table_column, '.', ''))) <> 2 THEN
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Input table column must be in format: DBName.TableName.ColumnName';
    END IF;
    
    SET v_input_db = SUBSTRING_INDEX(in_input_table_column, '.', 1);
    SET v_input_table = SUBSTRING_INDEX(SUBSTRING_INDEX(in_input_table_column, '.', 2), '.', -1);
    SET v_input_column = SUBSTRING_INDEX(in_input_table_column, '.', -1);

    -- Parse output table specification
    IF (LENGTH(in_output_table_column) - LENGTH(REPLACE(in_output_table_column, '.', ''))) <> 2 THEN
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Output table column must be in format: DBName.TableName.ColumnName';
    END IF;

    SET v_output_db = SUBSTRING_INDEX(in_output_table_column, '.', 1);
    SET v_output_table = SUBSTRING_INDEX(SUBSTRING_INDEX(in_output_table_column, '.', 2), '.', -1);
    SET v_output_column = SUBSTRING_INDEX(in_output_table_column, '.', -1);

    -- Parse options
    IF JSON_VALID(in_options) AND in_options IS NOT NULL THEN
        SET v_batch_size = COALESCE(CAST(JSON_UNQUOTE(JSON_EXTRACT(in_options, '$.batch_size')) AS UNSIGNED), 1000);
        SET v_fail_on_embedding_error = COALESCE(CAST(JSON_UNQUOTE(JSON_EXTRACT(in_options, '$.fail_on_embedding_error')) AS UNSIGNED), TRUE);
        SET v_embed_column = JSON_UNQUOTE(JSON_EXTRACT(in_options, '$.embed_column'));
    END IF;

    -- Validate batch_size
    IF v_batch_size < 1 OR v_batch_size > 1000 THEN
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'batch_size must be between 1 and 1000';
    END IF;

    -- Check input table existence and structure
    SELECT COUNT(*) > 0 INTO v_input_table_exists
    FROM information_schema.TABLES
    WHERE TABLE_SCHEMA = v_input_db AND TABLE_NAME = v_input_table;

    IF NOT v_input_table_exists THEN
        SET v_error_msg = CONCAT('Input table does not exist: ', v_input_db, '.', v_input_table);
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = v_error_msg;
    END IF;

    -- Verify input column exists and is text/varchar
    IF NOT EXISTS (
        SELECT 1 FROM information_schema.COLUMNS 
        WHERE TABLE_SCHEMA = v_input_db 
        AND TABLE_NAME = v_input_table 
        AND COLUMN_NAME = v_input_column
        AND DATA_TYPE IN ('text', 'varchar', 'longtext', 'mediumtext', 'tinytext')
    ) THEN
        SET v_error_msg = CONCAT('Input column does not exist or is not a text type: ', v_input_column);
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = v_error_msg;
    END IF;

    -- Verify input table has primary key
    IF NOT EXISTS (
        SELECT 1 FROM information_schema.KEY_COLUMN_USAGE k
        WHERE k.TABLE_SCHEMA = v_input_db 
        AND k.TABLE_NAME = v_input_table
        AND k.CONSTRAINT_NAME = 'PRIMARY'
    ) THEN
        SET v_error_msg = CONCAT('Input table must have a primary key: ', v_input_db, '.', v_input_table);
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = v_error_msg;        
    END IF;

    -- Check output table
    SELECT COUNT(*) > 0 INTO v_output_table_exists
    FROM information_schema.TABLES
    WHERE TABLE_SCHEMA = v_output_db AND TABLE_NAME = v_output_table;

    SET v_same_table = (v_input_db = v_output_db AND v_input_table = v_output_table);

    -- If output table exists, must be same as input table
    IF v_output_table_exists AND NOT v_same_table THEN
        SET v_error_msg = 'If output table exists, it must be the same as input table';
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = v_error_msg;          
    END IF;

    -- If same table, output column must not exist
    IF v_same_table AND EXISTS (
        SELECT 1 FROM information_schema.COLUMNS 
        WHERE TABLE_SCHEMA = v_output_db 
        AND TABLE_NAME = v_output_table 
        AND COLUMN_NAME = v_output_column
    ) THEN
        SET v_error_msg = CONCAT('Output column already exists: ', v_output_column);
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = v_error_msg;            
    END IF;

    -- =========================
    -- Prepare primary key column information
    -- =========================
    DROP TEMPORARY TABLE IF EXISTS temp_pk_columns;
    CREATE TEMPORARY TABLE temp_pk_columns (
        column_name VARCHAR(64),
        column_type TEXT,
        ordinal_position INT,
        PRIMARY KEY (ordinal_position)
    );

    INSERT INTO temp_pk_columns (column_name, column_type, ordinal_position)
    SELECT k.COLUMN_NAME, c.COLUMN_TYPE, k.ORDINAL_POSITION
    FROM information_schema.KEY_COLUMN_USAGE k
    JOIN information_schema.COLUMNS c 
        ON k.TABLE_SCHEMA = c.TABLE_SCHEMA 
        AND k.TABLE_NAME = c.TABLE_NAME 
        AND k.COLUMN_NAME = c.COLUMN_NAME
    WHERE k.TABLE_SCHEMA = v_input_db 
    AND k.TABLE_NAME = v_input_table
    AND k.CONSTRAINT_NAME = 'PRIMARY'
    ORDER BY k.ORDINAL_POSITION;

    -- =========================
    -- Create output table if needed
    -- =========================
    IF NOT v_output_table_exists THEN
        -- Build CREATE TABLE statement with primary key columns
        SET @create_sql = CONCAT('CREATE TABLE `', v_output_db, '`.`', v_output_table, '` (');

        -- Add primary key columns
        SET @pk_columns = '';
        SET @pk_list = '';

        SELECT GROUP_CONCAT(
            CONCAT('`', column_name, '` ', column_type) ORDER BY ordinal_position SEPARATOR ', '
        ), GROUP_CONCAT(
            CONCAT('`', column_name, '`') ORDER BY ordinal_position SEPARATOR ', '
        ) INTO @pk_columns, @pk_list
        FROM temp_pk_columns;

        SET @create_sql = CONCAT(@create_sql, @pk_columns, ', ');
        SET @create_sql = CONCAT(@create_sql, '`', v_output_column, '` JSON, ');
        SET @create_sql = CONCAT(@create_sql, 'PRIMARY KEY (', @pk_list, '))');

        PREPARE create_stmt FROM @create_sql;
        EXECUTE create_stmt;
        DEALLOCATE PREPARE create_stmt;
    ELSE
        -- Add output column to existing table
        SET @alter_sql = CONCAT('ALTER TABLE `', v_output_db, '`.`', v_output_table, 
                               '` ADD COLUMN `', v_output_column, '` JSON');
        PREPARE alter_stmt FROM @alter_sql;
        EXECUTE alter_stmt;
        DEALLOCATE PREPARE alter_stmt;
    END IF;

    -- =========================
    -- Process data in batches
    -- =========================
    SET @batch_offset = 0;

    batch_loop: WHILE TRUE DO
        -- Create temporary table for current batch
        DROP TEMPORARY TABLE IF EXISTS temp_batch_data;
        CREATE TEMPORARY TABLE temp_batch_data (
            batch_order INT AUTO_INCREMENT PRIMARY KEY,
            pk_values JSON,
            query_text LONGTEXT,
            embed_vector VECTOR(384) DEFAULT NULL
        );

        -- Build primary key selection for batch
        SET @pk_select = '';
        SELECT GROUP_CONCAT(
            CONCAT('`', column_name, '`') ORDER BY ordinal_position SEPARATOR ', '
        ) INTO @pk_select
        FROM temp_pk_columns;

        -- Prepare batch query
        SET @batch_sql = CONCAT(
            'INSERT INTO temp_batch_data (pk_values, query_text',
            CASE WHEN v_embed_column IS NOT NULL THEN ', embed_vector' ELSE '' END,
            ') SELECT JSON_ARRAY(', @pk_select, '), `', v_input_column, '`',
            CASE WHEN v_embed_column IS NOT NULL THEN CONCAT(', `', v_embed_column, '`') ELSE '' END,
            ' FROM `', v_input_db, '`.`', v_input_table, '`',
            ' WHERE `', v_input_column, '` IS NOT NULL AND TRIM(`', v_input_column, '`) <> ''''',
            ' LIMIT ', v_batch_size, ' OFFSET ', @batch_offset
        );

        PREPARE batch_stmt FROM @batch_sql;
        EXECUTE batch_stmt;
        DEALLOCATE PREPARE batch_stmt;

        -- Check if batch is empty
        SELECT COUNT(*) INTO v_batch_count FROM temp_batch_data;
        IF v_batch_count = 0 THEN
            LEAVE batch_loop;
        END IF;

        -- Process each row in current batch
        SET done = FALSE;
        OPEN batch_cursor;

        batch_row_loop: LOOP
            FETCH batch_cursor INTO v_current_id, v_current_query_text;
            IF done THEN
                LEAVE batch_row_loop;
            END IF;

            -- Process single RAG query
            BEGIN
                DECLARE CONTINUE HANDLER FOR SQLEXCEPTION
                BEGIN
                    SET v_total_failed = v_total_failed + 1;
                    IF v_fail_on_embedding_error THEN
                        GET DIAGNOSTICS CONDITION 1 v_error_msg = MESSAGE_TEXT;
                        SET v_error_msg = CONCAT('Batch processing failed: ', v_error_msg);
                        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = v_error_msg;
                    ELSE
                        -- Continue processing other rows
                        SET v_current_rag_output = JSON_OBJECT(
                            'error', 'Failed to process this query',
                            'text', '',
                            'citations', JSON_ARRAY()
                        );
                    END IF;
                END;

                -- Add pre-computed embedding to options if available
                SET @rag_options = in_options;
                IF v_embed_column IS NOT NULL THEN
                    SELECT embed_vector INTO @current_embedding 
                    FROM temp_batch_data 
                    WHERE pk_values = v_current_id;

                    IF @current_embedding IS NOT NULL THEN
                        SET @rag_options = JSON_SET(
                            COALESCE(@rag_options, JSON_OBJECT()),
                            '$.query_embedding', 
                            VECTOR_TO_STRING(@current_embedding)
                        );
                    END IF;
                END IF;

                -- Call ML_RAG for single query
                CALL sys.ML_RAG(v_current_query_text, v_current_rag_output, @rag_options);

                SET v_total_processed = v_total_processed + 1;

            END;

            -- Update output table with result
            SET @pk_conditions = '';
            SET @pk_count = (SELECT COUNT(*) FROM temp_pk_columns);
            SET @i = 0;

            WHILE @i < @pk_count DO
                SELECT column_name INTO @col_name 
                FROM temp_pk_columns 
                WHERE ordinal_position = @i + 1;

                SET @pk_conditions = CONCAT(
                    @pk_conditions,
                    IF(@i > 0, ' AND ', ''),
                    '`', @col_name, '` = JSON_UNQUOTE(JSON_EXTRACT(''', 
                    REPLACE(v_current_id, '''', ''''''), 
                    ''', ''$[', @i, ']''))'
                );
                SET @i = @i + 1;
            END WHILE;

            SET @update_sql = CONCAT(
                'UPDATE `', v_output_db, '`.`', v_output_table, '` ',
                'SET `', v_output_column, '` = ''', 
                REPLACE(JSON_UNQUOTE(v_current_rag_output), '''', ''''''), 
                ''' WHERE ', @pk_conditions
            );

            PREPARE update_stmt FROM @update_sql;
            EXECUTE update_stmt;
            DEALLOCATE PREPARE update_stmt;

        END LOOP;

        CLOSE batch_cursor;

        -- Move to next batch
        SET @batch_offset = @batch_offset + v_batch_size;

    END WHILE batch_loop;

    -- Clean up
    DROP TEMPORARY TABLE IF EXISTS temp_batch_data;
    DROP TEMPORARY TABLE IF EXISTS temp_pk_columns;

    -- Return processing summary
    SELECT CONCAT(
        'ML_RAG_TABLE processing completed. ',
        'Total processed: ', v_total_processed, ', ',
        'Total failed: ', v_total_failed
    ) AS processing_summary;

END$$

DELIMITER ;-- Copyright (c) 2014, 2023, Oracle and/or its affiliates.
--
-- This program is free software; you can redistribute it and/or modify
-- it under the terms of the GNU General Public License as published by
-- the Free Software Foundation; version 2 of the License.
--
-- This program is distributed in the hope that it will be useful,
-- but WITHOUT ANY WARRANTY; without even the implied warranty of
-- MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
-- GNU General Public License for more details.
--
-- You should have received a copy of the GNU General Public License
-- along with this program; if not, write to the Free Software
-- Foundation, Inc., 51 Franklin St, Fifth Floor, Boston, MA 02110-1301 USA
-- Copyright (c) 2023, Shannon Data AI and/or its affiliates.

DROP PROCEDURE IF EXISTS ml_generate_table;

DELIMITER $$

CREATE DEFINER='mysql.sys'@'localhost' PROCEDURE ml_generate_table (
        in input_table_column  varchar(256),
        in output_table_column  VARCHAR(256),
        in options JSON
    )
    COMMENT '
Description
-----------
The ML_GENERATE_TABLE routine runs multiple text generation or summarization queries in a batch, in parallel. 
The output generated for every input query is the same as the output generated by the ML_GENERATE routine.
Parameters
-----------
in_input_table_column (VARCHAR(255)):
  Specifies the input database, table, and column in format: DBName.TableName.ColumnName
  
in_output_table_column (VARCHAR(255)):
  Specifies the output database, table, and column in format: DBName.TableName.ColumnName

in_options (JSON):
  options: specifies optional parameters as key-value pairs in JSON format. It can include the following parameters::
  - task: specifies the task expected from the large language model (LLM). Default value is generation.generation,summarization
  - model_id: specifies the LLM to use for the task.llama3.2-3b-instruct-v1, etc.
  - context_column: specifies the table column that contains the context to be used for augmenting the queries and guiding the text generation of the LLM. The specified column must be an existing column in the input table. Default value is NULL.
  - language: specifies the language to be used for writing queries, ingesting documents, and generating the output. 
  - temperature: specifies a non-negative float that tunes the degree of randomness in generation. Lower temperatures mean less random generations.
  - max_tokens: specifies the maximum number of tokens to predict per generation using an estimate of three tokens per word. Default value is 256. 
  - top_k: specifies the number of top most likely tokens to consider for text generation at each step. Default value is 40, which means that top 40 most likely tokens are considered for text generation at each step. Possible values are integer values between 0 and 32000.
  - top_p: specifies a number, p, and ensures that only the most likely tokens with the sum of probabilities p are considered for generation at each step. A higher value of p introduces more randomness into the output.
  - repeat_penalty: assigns a penalty when a token appears repeatedly. High penalties encourage less repeated tokens and produce more random outputs. Default value is 1.1. Possible values are float values between 0 and 2.
  - frequency_penalty: assigns a penalty when a token appears frequently. High penalties encourage less repeated tokens and produce more random outputs. Default value is 0. Possible values are float values between 0 and 1.
  - presence_penalty: assigns a penalty to each token when it appears in the output to encourage generating outputs with tokens that haven\'t been used. This is similar to frequency_penalty, except that this penalty is applied equally to all tokens that have already appeared, irrespective of their exact frequencies.
  - stop_sequences: specifies a list of characters such as a word, a phrase, a newline, or a period that tells the LLM when to end the generated output. If you have more than one stop sequence, then the LLM stops when it reaches any of those sequences. Default value is NULL.
  - batch_size: specifies the batch size for the routine. This parameter is supported for internal tables only. Default value is 1000. Possible values are integer values between 1 and 1000.
  - speculative_decoding: enables or disables speculative decoding when generating tokens with an LLM. If set to true, speculative decoding enables faster response token generation, which speeds up LLM text generation. Speculative decoding is supported for the llama3.1-8b-instruct-v1 LLM, which uses llama3.2-1B-instruct-v1 as the draft LLM. Default value is true.
  - image_column: specifies the name of the column in the input table where the the base64 encoding of images are stored.

Example
-----------
mysql> CALL sys.ML_GENERATE_TABLE("demo_db.input_table.Input", "demo_db.output_table.Output", JSON_OBJECT("task", "generation", "model_id", "mistral-7b-instruct-v3", "language", "en"));
    '
SQL SECURITY INVOKER
DETERMINISTIC
CONTAINS SQL
BEGIN
    DECLARE done INT DEFAULT FALSE;
    DECLARE batch_counter INT DEFAULT 0;
    DECLARE current_batch_size INT DEFAULT 1000;
    DECLARE total_rows INT DEFAULT 0;
    DECLARE processed_rows INT DEFAULT 0;
    
    -- Parameter parsing variables
    DECLARE input_db VARCHAR(64);
    DECLARE input_table VARCHAR(64);
    DECLARE input_column VARCHAR(64);
    DECLARE output_db VARCHAR(64);
    DECLARE output_table VARCHAR(64);
    DECLARE output_column VARCHAR(64);
    DECLARE context_col VARCHAR(64) DEFAULT NULL;
    DECLARE image_col VARCHAR(64) DEFAULT NULL;
    
    -- LLM configuration parameters
    DECLARE task_type VARCHAR(32) DEFAULT 'generation';
    DECLARE model_id VARCHAR(128) DEFAULT 'llama3.2-3b-instruct-v1';
    DECLARE language_code VARCHAR(8) DEFAULT 'en';
    DECLARE temperature_val DECIMAL(5,2) DEFAULT 0.0;
    DECLARE max_tokens_val INT DEFAULT 256;
    DECLARE top_k_val INT DEFAULT 40;
    DECLARE top_p_val DECIMAL(5,2) DEFAULT 0.95;
    DECLARE repeat_penalty_val DECIMAL(5,2) DEFAULT 1.1;
    DECLARE frequency_penalty_val DECIMAL(5,2) DEFAULT 0.0;
    DECLARE presence_penalty_val DECIMAL(5,2) DEFAULT 0.0;
    DECLARE stop_sequences_val JSON DEFAULT NULL;
    DECLARE batch_size_val INT DEFAULT 1000;
    DECLARE speculative_decoding_val BOOLEAN DEFAULT TRUE;
    
    -- ML_MODEL_GENERATE option JSON
    DECLARE model_options JSON DEFAULT NULL;
    
    -- Dynamic SQL variables
    DECLARE sql_stmt TEXT DEFAULT '';
    DECLARE create_table_sql TEXT DEFAULT '';
    DECLARE insert_sql TEXT DEFAULT '';
    DECLARE select_sql TEXT DEFAULT '';
    
    -- Exception handling
    DECLARE EXIT HANDLER FOR SQLEXCEPTION
    BEGIN
        ROLLBACK;
        GET DIAGNOSTICS CONDITION 1
            @p1 = RETURNED_SQLSTATE, @p2 = MESSAGE_TEXT;
        SELECT CONCAT('Error: ', @p1, ' - ', @p2) AS error_message;
        RESIGNAL;
    END;

    -- Start transaction
    START TRANSACTION;

    -- 1. Parse input and output table column names
    SET input_db = SUBSTRING_INDEX(input_table_column, '.', 1);
    SET input_table = SUBSTRING_INDEX(SUBSTRING_INDEX(input_table_column, '.', 2), '.', -1);
    SET input_column = SUBSTRING_INDEX(input_table_column, '.', -1);
    
    SET output_db = SUBSTRING_INDEX(output_table_column, '.', 1);
    SET output_table = SUBSTRING_INDEX(SUBSTRING_INDEX(output_table_column, '.', 2), '.', -1);
    SET output_column = SUBSTRING_INDEX(output_table_column, '.', -1);

    -- 2. Parse configuration parameters
    IF options IS NOT NULL THEN
        SET task_type = COALESCE(JSON_UNQUOTE(JSON_EXTRACT(options, '$.task')), task_type);
        SET model_id = COALESCE(JSON_UNQUOTE(JSON_EXTRACT(options, '$.model_id')), model_id);
        SET context_col = JSON_UNQUOTE(JSON_EXTRACT(options, '$.context_column'));
        SET language_code = COALESCE(JSON_UNQUOTE(JSON_EXTRACT(options, '$.language')), language_code);
        SET temperature_val = COALESCE(JSON_EXTRACT(options, '$.temperature'), temperature_val);
        SET max_tokens_val = COALESCE(JSON_EXTRACT(options, '$.max_tokens'), max_tokens_val);
        SET top_k_val = COALESCE(JSON_EXTRACT(options, '$.top_k'), top_k_val);
        SET top_p_val = COALESCE(JSON_EXTRACT(options, '$.top_p'), top_p_val);
        SET repeat_penalty_val = COALESCE(JSON_EXTRACT(options, '$.repeat_penalty'), repeat_penalty_val);
        SET frequency_penalty_val = COALESCE(JSON_EXTRACT(options, '$.frequency_penalty'), frequency_penalty_val);
        SET presence_penalty_val = COALESCE(JSON_EXTRACT(options, '$.presence_penalty'), presence_penalty_val);
        SET stop_sequences_val = JSON_EXTRACT(options, '$.stop_sequences');
        SET batch_size_val = COALESCE(JSON_EXTRACT(options, '$.batch_size'), batch_size_val);
        SET speculative_decoding_val = COALESCE(JSON_EXTRACT(options, '$.speculative_decoding'), speculative_decoding_val);
        SET image_col = JSON_UNQUOTE(JSON_EXTRACT(options, '$.image_column'));
    END IF;

    SET current_batch_size = batch_size_val;

    -- 3. Build ML_MODEL_GENERATE options JSON
    SET model_options = JSON_OBJECT(
        'task', task_type,
        'model_id', model_id,
        'language', language_code,
        'temperature', temperature_val,
        'max_tokens', max_tokens_val,
        'top_k', top_k_val,
        'top_p', top_p_val,
        'repeat_penalty', repeat_penalty_val,
        'frequency_penalty', frequency_penalty_val,
        'presence_penalty', presence_penalty_val,
        'speculative_decoding', speculative_decoding_val
    );

    -- Add stop_sequences if provided
    IF stop_sequences_val IS NOT NULL THEN
        SET model_options = JSON_SET(model_options, '$.stop_sequences', stop_sequences_val);
    END IF;

    -- 4. Validate input table and column existence
    SET @table_exists = 0;
    SET @sql_stmt = CONCAT(
        'SELECT COUNT(*) INTO @table_exists FROM information_schema.tables ',
        'WHERE table_schema = "', input_db, '" AND table_name = "', input_table, '"'
    );
    PREPARE stmt FROM @sql_stmt;
    EXECUTE stmt;
    DEALLOCATE PREPARE stmt;
    
    IF @table_exists = 0 THEN
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Input table does not exist';
    END IF;

    -- Validate input column exists
    SET @column_exists = 0;
    SET @sql_stmt = CONCAT(
        'SELECT COUNT(*) INTO @column_exists FROM information_schema.columns ',
        'WHERE table_schema = "', input_db, '" AND table_name = "', input_table, '" AND column_name = "', input_column, '"'
    );
    PREPARE stmt FROM @sql_stmt;
    EXECUTE stmt;
    DEALLOCATE PREPARE stmt;
    
    IF @column_exists = 0 THEN
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Input column does not exist';
    END IF;

    -- Validate context column if specified
    IF context_col IS NOT NULL THEN
        SET @context_col_exists = 0;
        SET @sql_stmt = CONCAT(
            'SELECT COUNT(*) INTO @context_col_exists FROM information_schema.columns ',
            'WHERE table_schema = "', input_db, '" AND table_name = "', input_table, '" AND column_name = "', context_col, '"'
        );
        PREPARE stmt FROM @sql_stmt;
        EXECUTE stmt;
        DEALLOCATE PREPARE stmt;
        
        IF @context_col_exists = 0 THEN
            SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Context column does not exist';
        END IF;
    END IF;

    -- Validate image column if specified
    IF image_col IS NOT NULL THEN
        SET @image_col_exists = 0;
        SET @sql_stmt = CONCAT(
            'SELECT COUNT(*) INTO @image_col_exists FROM information_schema.columns ',
            'WHERE table_schema = "', input_db, '" AND table_name = "', input_table, '" AND column_name = "', image_col, '"'
        );
        PREPARE stmt FROM @sql_stmt;
        EXECUTE stmt;
        DEALLOCATE PREPARE stmt;
        
        IF @image_col_exists = 0 THEN
            SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Image column does not exist';
        END IF;
    END IF;

    -- 5. Check if input table has primary key
    SET @pk_exists = 0;
    SET @sql_stmt = CONCAT(
        'SELECT COUNT(*) INTO @pk_exists FROM information_schema.key_column_usage ',
        'WHERE table_schema = "', input_db, '" AND table_name = "', input_table, '" AND constraint_name = "PRIMARY"'
    );
    PREPARE stmt FROM @sql_stmt;
    EXECUTE stmt;
    DEALLOCATE PREPARE stmt;
    
    IF @pk_exists = 0 THEN
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Input table must have a primary key';
    END IF;

    -- 6. Get total row count
    SET @sql_stmt = CONCAT('SELECT COUNT(*) INTO @total_rows FROM `', input_db, '`.`', input_table, '` WHERE `', input_column, '` IS NOT NULL AND `', input_column, '` != ""');
    PREPARE stmt FROM @sql_stmt;
    EXECUTE stmt;
    DEALLOCATE PREPARE stmt;
    SET total_rows = @total_rows;

    IF total_rows = 0 THEN
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Input table is empty or contains no valid data';
    END IF;

    -- 7. Create or validate output table
    SET @output_table_exists = 0;
    SET @sql_stmt = CONCAT(
        'SELECT COUNT(*) INTO @output_table_exists FROM information_schema.tables ',
        'WHERE table_schema = "', output_db, '" AND table_name = "', output_table, '"'
    );
    PREPARE stmt FROM @sql_stmt;
    EXECUTE stmt;
    DEALLOCATE PREPARE stmt;

    IF @output_table_exists = 0 THEN
        -- Create new output table
        -- First get input table's primary key structure
        SET @sql_stmt = CONCAT(
            'SELECT GROUP_CONCAT(DISTINCT ',
            'CONCAT("`", column_name, "` ", data_type, ',
            'CASE WHEN character_maximum_length IS NOT NULL THEN CONCAT("(", character_maximum_length, ")") ',
            'WHEN numeric_precision IS NOT NULL THEN CONCAT("(", numeric_precision, IFNULL(CONCAT(",", numeric_scale), ""), ")") ',
            'ELSE "" END) SEPARATOR ", ") INTO @pk_columns ',
            'FROM information_schema.columns c ',
            'JOIN information_schema.key_column_usage k ON c.table_schema = k.table_schema AND c.table_name = k.table_name AND c.column_name = k.column_name ',
            'WHERE c.table_schema = "', input_db, '" AND c.table_name = "', input_table, '" AND k.constraint_name = "PRIMARY" ',
            'ORDER BY k.ordinal_position'
        );
        PREPARE stmt FROM @sql_stmt;
        EXECUTE stmt;
        DEALLOCATE PREPARE stmt;

        -- Get primary key column names for PRIMARY KEY constraint
        SET @sql_stmt = CONCAT(
            'SELECT GROUP_CONCAT(DISTINCT CONCAT("`", column_name, "`") ORDER BY ordinal_position SEPARATOR ", ") INTO @pk_names ',
            'FROM information_schema.key_column_usage ',
            'WHERE table_schema = "', input_db, '" AND table_name = "', input_table, '" AND constraint_name = "PRIMARY"'
        );
        PREPARE stmt FROM @sql_stmt;
        EXECUTE stmt;
        DEALLOCATE PREPARE stmt;

        SET @create_table_sql = CONCAT(
            'CREATE TABLE `', output_db, '`.`', output_table, '` (',
            @pk_columns, ', ',
            '`', output_column, '` JSON, ',
            'PRIMARY KEY (', @pk_names, ')',
            ') ENGINE=InnoDB'
        );
        
        PREPARE stmt FROM @create_table_sql;
        EXECUTE stmt;
        DEALLOCATE PREPARE stmt;
    ELSE
        -- Validate output table structure (if same table, check output column doesn't exist)
        IF input_db = output_db AND input_table = output_table THEN
            SET @output_column_exists = 0;
            SET @sql_stmt = CONCAT(
                'SELECT COUNT(*) INTO @output_column_exists FROM information_schema.columns ',
                'WHERE table_schema = "', output_db, '" AND table_name = "', output_table, '" AND column_name = "', output_column, '"'
            );
            PREPARE stmt FROM @sql_stmt;
            EXECUTE stmt;
            DEALLOCATE PREPARE stmt;
            
            IF @output_column_exists > 0 THEN
                SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Output column already exists in the same table';
            END IF;
            
            -- Add output column
            SET @sql_stmt = CONCAT('ALTER TABLE `', output_db, '`.`', output_table, '` ADD COLUMN `', output_column, '` JSON');
            PREPARE stmt FROM @sql_stmt;
            EXECUTE stmt;
            DEALLOCATE PREPARE stmt;
        END IF;
    END IF;

    -- 8. Get primary key columns for later use
    SET @sql_stmt = CONCAT(
        'SELECT GROUP_CONCAT(DISTINCT CONCAT("`", column_name, "`") ORDER BY ordinal_position SEPARATOR ", ") INTO @pk_columns_list ',
        'FROM information_schema.key_column_usage ',
        'WHERE table_schema = "', input_db, '" AND table_name = "', input_table, '" AND constraint_name = "PRIMARY"'
    );
    PREPARE stmt FROM @sql_stmt;
    EXECUTE stmt;
    DEALLOCATE PREPARE stmt;

    -- 9. Process data in batches
    SET batch_counter = 0;
    SET processed_rows = 0;

    -- Create temporary table to store batch results
    DROP TEMPORARY TABLE IF EXISTS temp_batch_results;
    
    -- Build temporary table creation SQL dynamically
    SET @sql_stmt = CONCAT(
        'SELECT GROUP_CONCAT(DISTINCT ',
        'CONCAT("`", column_name, "` ", data_type, ',
        'CASE WHEN character_maximum_length IS NOT NULL THEN CONCAT("(", character_maximum_length, ")") ',
        'WHEN numeric_precision IS NOT NULL THEN CONCAT("(", numeric_precision, IFNULL(CONCAT(",", numeric_scale), ""), ")") ',
        'ELSE "" END) SEPARATOR ", ") INTO @temp_pk_columns ',
        'FROM information_schema.columns c ',
        'JOIN information_schema.key_column_usage k ON c.table_schema = k.table_schema AND c.table_name = k.table_name AND c.column_name = k.column_name ',
        'WHERE c.table_schema = "', input_db, '" AND c.table_name = "', input_table, '" AND k.constraint_name = "PRIMARY" ',
        'ORDER BY k.ordinal_position'
    );
    PREPARE stmt FROM @sql_stmt;
    EXECUTE stmt;
    DEALLOCATE PREPARE stmt;

    SET @sql_stmt = CONCAT(
        'CREATE TEMPORARY TABLE temp_batch_results (',
        'batch_id INT AUTO_INCREMENT PRIMARY KEY, ',
        @temp_pk_columns, ', ',
        'input_text TEXT, ',
        'context_text TEXT, ',
        CASE WHEN image_col IS NOT NULL THEN 'image_data LONGTEXT, ' ELSE '' END,
        'generated_output JSON, ',
        'processing_status ENUM("pending", "processed", "error") DEFAULT "pending", ',
        'error_message TEXT NULL',
        ')'
    );
    PREPARE stmt FROM @sql_stmt;
    EXECUTE stmt;
    DEALLOCATE PREPARE stmt;

    -- Main batch processing loop
    WHILE processed_rows < total_rows DO
        SET batch_counter = batch_counter + 1;
        
        -- Clear temporary table
        TRUNCATE temp_batch_results;
        
        -- Load batch data into temporary table
        SET @select_sql = CONCAT(
            'INSERT INTO temp_batch_results (', @pk_columns_list, ', input_text, context_text',
            CASE WHEN image_col IS NOT NULL THEN ', image_data' ELSE '' END,
            ') SELECT ', @pk_columns_list, ', `', input_column, '`',
            CASE WHEN context_col IS NOT NULL THEN CONCAT(', `', context_col, '`') ELSE ', NULL' END,
            CASE WHEN image_col IS NOT NULL THEN CONCAT(', `', image_col, '`') ELSE '' END,
            ' FROM `', input_db, '`.`', input_table, '` ',
            'WHERE `', input_column, '` IS NOT NULL AND `', input_column, '` != "" ',
            'LIMIT ', current_batch_size, ' OFFSET ', processed_rows
        );
        
        PREPARE stmt FROM @select_sql;
        EXECUTE stmt;
        DEALLOCATE PREPARE stmt;

        -- Get actual batch size loaded
        SELECT COUNT(*) INTO @current_batch_count FROM temp_batch_results;

        -- Process each row in the batch using ML_MODEL_GENERATE
        BEGIN
            DECLARE cur_done INT DEFAULT FALSE;
            DECLARE cur_input_text TEXT;
            DECLARE cur_context_text TEXT;
            DECLARE cur_image_data LONGTEXT;
            DECLARE cur_batch_id INT;
            DECLARE final_input_text TEXT;
            DECLARE generate_result JSON;
            DECLARE err_state VARCHAR(5);
            DECLARE err_msg TEXT;
            
            DECLARE batch_cursor CURSOR FOR 
                SELECT batch_id, input_text, context_text, 
                       CASE WHEN image_col IS NOT NULL THEN image_data ELSE NULL END
                FROM temp_batch_results 
                WHERE processing_status = 'pending';
            
            DECLARE CONTINUE HANDLER FOR NOT FOUND SET cur_done = TRUE;
            
            -- Handle ML_MODEL_GENERATE errors
            DECLARE CONTINUE HANDLER FOR SQLEXCEPTION
            BEGIN
                GET DIAGNOSTICS CONDITION 1
                    err_state = RETURNED_SQLSTATE, err_msg = MESSAGE_TEXT;
                
                UPDATE temp_batch_results 
                SET processing_status = 'error',
                    error_message = CONCAT('ML_MODEL_GENERATE Error: ', err_state, ' - ', err_msg)
                WHERE batch_id = cur_batch_id;
            END;
            
            OPEN batch_cursor;
            
            batch_loop: LOOP
                FETCH batch_cursor INTO cur_batch_id, cur_input_text, cur_context_text, cur_image_data;
                IF cur_done THEN
                    LEAVE batch_loop;
                END IF;
                
                -- Prepare input text with context if provided
                SET final_input_text = cur_input_text;
                IF cur_context_text IS NOT NULL AND cur_context_text != '' THEN
                    SET final_input_text = CONCAT('Context: ', cur_context_text, '\n\nQuery: ', cur_input_text);
                END IF;
                
                -- Handle image data if provided
                IF cur_image_data IS NOT NULL AND cur_image_data != '' THEN
                    SET model_options = JSON_SET(model_options, '$.image', cur_image_data);
                END IF;
                
                -- Call ML_MODEL_GENERATE function
                SELECT ML_MODEL_GENERATE(final_input_text, model_options) INTO generate_result;
                
                -- Update temporary table with result
                UPDATE temp_batch_results 
                SET generated_output = generate_result,
                    processing_status = 'processed'
                WHERE batch_id = cur_batch_id;
                
            END LOOP;
            
            CLOSE batch_cursor;
        END;

        -- Insert/Update results into output table
        IF input_db = output_db AND input_table = output_table THEN
            -- Same table, update existing records
            -- Build join condition for primary key columns
            SET @sql_stmt = CONCAT(
                'SELECT GROUP_CONCAT(DISTINCT CONCAT("t.`", column_name, "` = r.`", column_name, "`") ORDER BY ordinal_position SEPARATOR " AND ") INTO @join_condition ',
                'FROM information_schema.key_column_usage ',
                'WHERE table_schema = "', input_db, '" AND table_name = "', input_table, '" AND constraint_name = "PRIMARY"'
            );
            PREPARE stmt_join FROM @sql_stmt;
            EXECUTE stmt_join;
            DEALLOCATE PREPARE stmt_join;
            
            SET @sql_stmt = CONCAT(
                'UPDATE `', output_db, '`.`', output_table, '` t ',
                'JOIN temp_batch_results r ON (', @join_condition, ') ',
                'SET t.`', output_column, '` = r.generated_output ',
                'WHERE r.processing_status = "processed"'
            );
        ELSE
            -- Different table, insert new records
            SET @sql_stmt = CONCAT(
                'INSERT INTO `', output_db, '`.`', output_table, '` (',
                @pk_columns_list, ', `', output_column, '`) ',
                'SELECT ', @pk_columns_list, ', generated_output ',
                'FROM temp_batch_results ',
                'WHERE processing_status = "processed"'
            );
        END IF;
        
        PREPARE stmt FROM @sql_stmt;
        EXECUTE stmt;
        DEALLOCATE PREPARE stmt;

        -- Count processed and error records
        SELECT COUNT(*) INTO @batch_processed FROM temp_batch_results WHERE processing_status = 'processed';
        SELECT COUNT(*) INTO @batch_errors FROM temp_batch_results WHERE processing_status = 'error';

        SET processed_rows = processed_rows + @current_batch_count;
        
        -- Display progress
        SELECT CONCAT('Batch ', batch_counter, ' completed. Processed: ', 
                     LEAST(processed_rows, total_rows), '/', total_rows, ' rows. ',
                     'Success: ', @batch_processed, ', Errors: ', @batch_errors) AS progress;
        
        -- Log errors if any
        IF @batch_errors > 0 THEN
            SELECT 'Errors in batch:' as error_summary;
            SELECT batch_id, error_message FROM temp_batch_results WHERE processing_status = 'error';
        END IF;
        
    END WHILE;

    -- Get final statistics
    SET @sql_stmt = CONCAT('SELECT COUNT(*) INTO @final_count FROM `', output_db, '`.`', output_table, '` WHERE `', output_column, '` IS NOT NULL');
    PREPARE stmt FROM @sql_stmt;
    EXECUTE stmt;
    DEALLOCATE PREPARE stmt;

    -- Clean up temporary table
    DROP TEMPORARY TABLE IF EXISTS temp_batch_results;

    -- Commit transaction
    COMMIT;

    -- Return result summary
    SELECT 
        'ML_GENERATE_TABLE completed successfully' AS status,
        task_type AS task,
        model_id AS model_used,
        total_rows AS total_input_rows,
        @final_count AS total_generated_rows,
        batch_counter AS total_batches,
        current_batch_size AS batch_size,
        CONCAT(output_db, '.', output_table, '.', output_column) AS output_location;

END$$

DELIMITER ;-- Copyright (c) 2014, 2024, Oracle and/or its affiliates.
--
-- This program is free software; you can redistribute it and/or modify
-- it under the terms of the GNU General Public License as published by
-- the Free Software Foundation; version 2 of the License.
--
-- This program is distributed in the hope that it will be useful,
-- but WITHOUT ANY WARRANTY; without even the implied warranty of
-- MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
-- GNU General Public License for more details.
--
-- You should have received a copy of the GNU General Public License
-- along with this program; if not, write to the Free Software
-- Foundation, Inc., 51 Franklin St, Fifth Floor, Boston, MA 02110-1301  USA

SET @@sql_log_bin = @sql_log_bin;
