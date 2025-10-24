file(REMOVE_RECURSE
  "../archive_output_directory/libdecimal.a"
  "../archive_output_directory/libdecimal.pdb"
)

# Per-language clean rules from dependency scanning.
foreach(lang CXX)
  include(CMakeFiles/decimal.dir/cmake_clean_${lang}.cmake OPTIONAL)
endforeach()
