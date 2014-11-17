# /tests/ListContainsValueEmpty.cmake
#
# Check the _list_contains_value matcher with empty values
#
# See LICENCE.md for Copyright information

include (CMakeUnit)

set (LIST "")

_list_contains_value (LIST STRING EQUAL "" CONTAINS_VALUE)

# Empty values are never stored in lists
assert_false (${CONTAINS_VALUE})
