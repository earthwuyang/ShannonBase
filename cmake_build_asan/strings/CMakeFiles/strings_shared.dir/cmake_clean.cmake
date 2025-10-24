file(REMOVE_RECURSE
  "../library_output_directory/libstrings_shared.pdb"
  "../library_output_directory/libstrings_shared.so"
)

# Per-language clean rules from dependency scanning.
foreach(lang CXX)
  include(CMakeFiles/strings_shared.dir/cmake_clean_${lang}.cmake OPTIONAL)
endforeach()
