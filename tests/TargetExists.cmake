# /tests/TargetExists.cmake
#
# Check the _cmake_unit_target_exists matcher.
#
# See LICENCE.md for Copyright information

include (CMakeUnit)

file (WRITE "${CMAKE_CURRENT_BINARY_DIR}/Library.cpp" "")
add_library (library SHARED
             "${CMAKE_CURRENT_BINARY_DIR}/Library.cpp")

_cmake_unit_target_exists (library RESULT)
_cmake_unit_target_exists (not_existing NOT_RESULT)

cmake_unit_assert_true (${RESULT})
cmake_unit_assert_false (${NOT_RESULT})
