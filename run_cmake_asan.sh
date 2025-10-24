#!/bin/bash
# ShannonBase ASan Build Configuration
# For debugging Rapid engine memory corruption

SHANNON_BASE_DIR="/home/wuy/DB/ShannonBase"
SHANNON_INSTALL_DIR="${SHANNON_BASE_DIR}/shannon_bin_asan"

# Create separate build directory for ASan
mkdir -p cmake_build_asan

cd cmake_build_asan && cmake ../ \
  -DWITH_BOOST=/home/wuy/software/boost_1_77_0 \
  -DCMAKE_BUILD_TYPE=Debug \
  -DCMAKE_INSTALL_PREFIX=${SHANNON_INSTALL_DIR} \
  -DMYSQL_DATADIR=${SHANNON_BASE_DIR}/db/data_asan \
  -DSYSCONFDIR=${SHANNON_BASE_DIR}/db \
  -DMYSQL_UNIX_ADDR=/tmp/mysql_asan.sock \
  -DWITH_EMBEDDED_SERVER=OFF \
  -DWITH_MYISAM_STORAGE_ENGINE=1 \
  -DWITH_INNOBASE_STORAGE_ENGINE=1 \
  -DWITH_PARTITION_STORAGE_ENGINE=1 \
  -DMYSQL_TCP_PORT=3308 \
  -DENABLED_LOCAL_INFILE=1 \
  -DEXTRA_CHARSETS=all \
  -DWITH_PROTOBUF=bundled \
  -DWITH_SSL=system \
  -DDEFAULT_SET=community \
  -DWITH_UNIT_TESTS=OFF \
  -DWITH_DEBUG=1 \
  -DWITH_ASAN=ON \
  -DWITH_ASAN_SCOPE=ON \
  -DOPTIMIZE_SANITIZER_BUILDS=ON

echo ""
echo "=========================================="
echo "CMake configuration complete!"
echo "=========================================="
echo "Build directory: cmake_build_asan"
echo "Install directory: ${SHANNON_INSTALL_DIR}"
echo "Data directory: ${SHANNON_BASE_DIR}/db/data_asan"
echo "Port: 3308"
echo ""
echo "Next steps:"
echo "  cd cmake_build_asan"
echo "  make -j\$(nproc)"
echo "  make install"
echo ""
