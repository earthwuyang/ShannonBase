#!/bin/bash
# ShannonBase CMake configuration script - DEBUG BUILD
# Updated paths for local environment

# Base directory (where ShannonBase is located)
SHANNON_BASE_DIR="/home/wuy/DB/ShannonBase"
SHANNON_INSTALL_DIR="${SHANNON_BASE_DIR}/shannon_bin_debug"

# Create cmake_build_debug directory if it doesn't exist
mkdir -p cmake_build_debug

cd cmake_build_debug && cmake ../ \
  -DWITH_BOOST=/home/wuy/software/boost_1_77_0 \
  -DCMAKE_BUILD_TYPE=DEBUG \
  -DCMAKE_INSTALL_PREFIX=${SHANNON_INSTALL_DIR} \
  -DMYSQL_DATADIR=${SHANNON_BASE_DIR}/db/data \
  -DSYSCONFDIR=${SHANNON_BASE_DIR}/db \
  -DMYSQL_UNIX_ADDR=/tmp/mysql.sock \
  -DWITH_EMBEDDED_SERVER=OFF \
  -DWITH_MYISAM_STORAGE_ENGINE=1 \
  -DWITH_INNOBASE_STORAGE_ENGINE=1 \
  -DWITH_PARTITION_STORAGE_ENGINE=1 \
  -DMYSQL_TCP_PORT=3307 \
  -DENABLED_LOCAL_INFILE=1 \
  -DEXTRA_CHARSETS=all \
  -DWITH_PROTOBUF=bundled \
  -DWITH_SSL=system \
  -DDEFAULT_SET=community \
  -DWITH_UNIT_TESTS=OFF \
  -DWITH_DEBUG=1

echo ""
echo "Debug build configured in cmake_build_debug/"
echo "To build: cd cmake_build_debug && make -j$(nproc)"
