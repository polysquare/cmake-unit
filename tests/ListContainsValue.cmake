# /tests/ListContainsValue.cmake
#
# Check the _cmake_unit_list_contains_value matcher.
#
# See LICENCE.md for Copyright information

include (CMakeUnit)

set (LIST
     v
     ov)

_cmake_unit_list_contains_value (LIST STRING EQUAL "v" CONTAINS_VALUE)
_cmake_unit_list_contains_value (LIST STRING EQUAL "ov" CONTAINS_OTHER_VALUE)
_cmake_unit_list_contains_value (LIST STRING EQUAL "not_in" DOESNT_CONTAIN)

cmake_unit_assert_true (${CONTAINS_VALUE})
cmake_unit_assert_true (${CONTAINS_OTHER_VALUE})
cmake_unit_assert_false (${DOESNT_CONTAIN})
