#!/usr/bin/perl
# Call mtr in out-of-source build
$ENV{MTR_BINDIR} = '/home/wuy/ShannonBase/cmake_build_asan';
chdir('/home/wuy/ShannonBase/mysql-test');
exit(system($^X, '/home/wuy/ShannonBase/mysql-test/mysql-test-run.pl', @ARGV) >> 8);
