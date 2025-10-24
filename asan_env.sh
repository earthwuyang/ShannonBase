#!/bin/bash
# AddressSanitizer Runtime Configuration
# Optimized for detecting connection lifecycle memory corruption

export ASAN_OPTIONS="\
detect_leaks=1:\
detect_stack_use_after_return=1:\
check_initialization_order=1:\
detect_invalid_pointer_pairs=2:\
log_path=/home/wuy/ShannonBase/asan_logs/asan:\
log_exe_name=1:\
print_stats=1:\
print_scariness=1:\
symbolize=1:\
fast_unwind_on_malloc=0:\
malloc_context_size=30:\
verbosity=1:\
print_summary=1:\
print_module_map=1:\
abort_on_error=1:\
halt_on_error=0:\
quarantine_size_mb=256:\
max_redzone=256:\
detect_odr_violation=1:\
strict_string_checks=1:\
strict_init_order=1\
"

export LSAN_OPTIONS="\
suppressions=/home/wuy/ShannonBase/lsan_suppressions.txt:\
print_suppressions=0:\
use_poisoned=1:\
use_registers=1:\
use_stacks=1:\
use_globals=1\
"

# Ensure logs directory exists
mkdir -p /home/wuy/ShannonBase/asan_logs

echo "=========================================="
echo "ASan Environment Configured"
echo "=========================================="
echo "Logs: /home/wuy/ShannonBase/asan_logs/asan.*"
echo "Leak detection: ENABLED"
echo "Stack traces: FULL (slow but detailed)"
echo "Quarantine: 256MB (catches use-after-free)"
echo ""
echo "ASAN_OPTIONS: ${ASAN_OPTIONS}"
echo ""
