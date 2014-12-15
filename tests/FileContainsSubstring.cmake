# /tests/FileContainsSubstring.cmake
#
# Check the _cmake_unit_file_contains_substring matcher.
#
# See LICENCE.md for Copyright information

include (CMakeUnit)

set (SUBSTRING "substring")
set (MAIN_STRING "main_${SUBSTRING}_string")

file (WRITE "${CMAKE_CURRENT_BINARY_DIR}/File" ${MAIN_STRING})

_cmake_unit_file_contains_substring ("${CMAKE_CURRENT_BINARY_DIR}/File"
                                     ${SUBSTRING}
                                     CONTAINING_SUBSTRING)
_cmake_unit_file_contains_substring ("${CMAKE_CURRENT_BINARY_DIR}/File"
                                     "other_string"
                                     NOT_CONTAINING_SUBSTRING)

cmake_unit_assert_true (${CONTAINING_SUBSTRING})
cmake_unit_assert_false (${NOT_CONTAINING_SUBSTRING})
