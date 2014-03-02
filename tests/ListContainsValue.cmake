# /tests/ListContainsValue.cmake
# Check the _list_contains_value matcher.
#
# See LICENCE.md for Copyright information.

include (${CMAKE_UNIT_DIRECTORY}/CMakeUnit.cmake)

set (LIST
     value
     other_value)

_list_contains_value (LIST STRING EQUAL "value" CONTAINS_VALUE)
_list_contains_value (LIST STRING EQUAL "other_value" CONTAINS_OTHER_VALUE)
_list_contains_value (LIST STRING EQUAL "does_not_contain" DOESNT_CONTAIN)

assert_true (${CONTAINS_VALUE})
assert_true (${CONTAINS_OTHER_VALUE})
assert_false (${DOESNT_CONTAIN})