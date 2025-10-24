# Install script for directory: /home/wuy/ShannonBase/man

# Set the install prefix
if(NOT DEFINED CMAKE_INSTALL_PREFIX)
  set(CMAKE_INSTALL_PREFIX "/home/wuy/DB/ShannonBase/shannon_bin_asan")
endif()
string(REGEX REPLACE "/$" "" CMAKE_INSTALL_PREFIX "${CMAKE_INSTALL_PREFIX}")

# Set the install configuration name.
if(NOT DEFINED CMAKE_INSTALL_CONFIG_NAME)
  if(BUILD_TYPE)
    string(REGEX REPLACE "^[^A-Za-z0-9_]+" ""
           CMAKE_INSTALL_CONFIG_NAME "${BUILD_TYPE}")
  else()
    set(CMAKE_INSTALL_CONFIG_NAME "Debug")
  endif()
  message(STATUS "Install configuration: \"${CMAKE_INSTALL_CONFIG_NAME}\"")
endif()

# Set the component getting installed.
if(NOT CMAKE_INSTALL_COMPONENT)
  if(COMPONENT)
    message(STATUS "Install component: \"${COMPONENT}\"")
    set(CMAKE_INSTALL_COMPONENT "${COMPONENT}")
  else()
    set(CMAKE_INSTALL_COMPONENT)
  endif()
endif()

# Install shared libraries without execute permission?
if(NOT DEFINED CMAKE_INSTALL_SO_NO_EXE)
  set(CMAKE_INSTALL_SO_NO_EXE "1")
endif()

# Is this installation the result of a crosscompile?
if(NOT DEFINED CMAKE_CROSSCOMPILING)
  set(CMAKE_CROSSCOMPILING "FALSE")
endif()

# Set path to fallback-tool for dependency-resolution.
if(NOT DEFINED CMAKE_OBJDUMP)
  set(CMAKE_OBJDUMP "/usr/bin/objdump")
endif()

if(CMAKE_INSTALL_COMPONENT STREQUAL "ManPages" OR NOT CMAKE_INSTALL_COMPONENT)
  file(INSTALL DESTINATION "${CMAKE_INSTALL_PREFIX}/man/man1" TYPE FILE FILES
    "/home/wuy/ShannonBase/man/comp_err.1"
    "/home/wuy/ShannonBase/man/ibd2sdi.1"
    "/home/wuy/ShannonBase/man/innochecksum.1"
    "/home/wuy/ShannonBase/man/my_print_defaults.1"
    "/home/wuy/ShannonBase/man/myisam_ftdump.1"
    "/home/wuy/ShannonBase/man/myisamchk.1"
    "/home/wuy/ShannonBase/man/myisamlog.1"
    "/home/wuy/ShannonBase/man/myisampack.1"
    "/home/wuy/ShannonBase/man/mysql.1"
    "/home/wuy/ShannonBase/man/mysql_config.1"
    "/home/wuy/ShannonBase/man/mysql_config_editor.1"
    "/home/wuy/ShannonBase/man/mysql_secure_installation.1"
    "/home/wuy/ShannonBase/man/mysql_tzinfo_to_sql.1"
    "/home/wuy/ShannonBase/man/mysqladmin.1"
    "/home/wuy/ShannonBase/man/mysqlbinlog.1"
    "/home/wuy/ShannonBase/man/mysqlcheck.1"
    "/home/wuy/ShannonBase/man/mysqldump.1"
    "/home/wuy/ShannonBase/man/mysqldumpslow.1"
    "/home/wuy/ShannonBase/man/mysqlimport.1"
    "/home/wuy/ShannonBase/man/mysqlman.1"
    "/home/wuy/ShannonBase/man/mysqlshow.1"
    "/home/wuy/ShannonBase/man/mysqlslap.1"
    "/home/wuy/ShannonBase/man/perror.1"
    "/home/wuy/ShannonBase/man/mysql.server.1"
    "/home/wuy/ShannonBase/man/mysqld_multi.1"
    "/home/wuy/ShannonBase/man/mysqld_safe.1"
    )
endif()

if(CMAKE_INSTALL_COMPONENT STREQUAL "ManPages" OR NOT CMAKE_INSTALL_COMPONENT)
  file(INSTALL DESTINATION "${CMAKE_INSTALL_PREFIX}/man/man8" TYPE FILE FILES "/home/wuy/ShannonBase/man/mysqld.8")
endif()

if(CMAKE_INSTALL_COMPONENT STREQUAL "ManPages" OR NOT CMAKE_INSTALL_COMPONENT)
  file(INSTALL DESTINATION "${CMAKE_INSTALL_PREFIX}/man/man1" TYPE FILE FILES
    "/home/wuy/ShannonBase/man/mysqlrouter.1"
    "/home/wuy/ShannonBase/man/mysqlrouter_passwd.1"
    "/home/wuy/ShannonBase/man/mysqlrouter_plugin_info.1"
    )
endif()

string(REPLACE ";" "\n" CMAKE_INSTALL_MANIFEST_CONTENT
       "${CMAKE_INSTALL_MANIFEST_FILES}")
if(CMAKE_INSTALL_LOCAL_ONLY)
  file(WRITE "/home/wuy/ShannonBase/cmake_build_asan/man/install_local_manifest.txt"
     "${CMAKE_INSTALL_MANIFEST_CONTENT}")
endif()
