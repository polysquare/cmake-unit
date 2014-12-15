# /tests/ListContainsValueEmpty.cmake
#
# Check the _cmake_unit_list_contains_value matcher with empty values
#
# See LICENCE.md for Copyright information

include (CMakeUnit)

set (LIST "")

_cmake_unit_list_contains_value (LIST STRING EQUAL "" CONTAINS_VALUE)

# Empty values are never stored in lists
cmake_unit_assert_false (${CONTAINS_VALUE})
