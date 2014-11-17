# /tests/FileContainsSubstring.cmake
#
# Check the _file_contains_substring matcher.
#
# See LICENCE.md for Copyright information

include (CMakeUnit)

set (SUBSTRING "substring")
set (MAIN_STRING "main_${SUBSTRING}_string")

file (WRITE ${CMAKE_CURRENT_BINARY_DIR}/File ${MAIN_STRING})

_file_contains_substring (${CMAKE_CURRENT_BINARY_DIR}/File
                          ${SUBSTRING}
                          CONTAINING_SUBSTRING)
_file_contains_substring (${CMAKE_CURRENT_BINARY_DIR}/File
                          "other_string"
                          NOT_CONTAINING_SUBSTRING)

assert_true (${CONTAINING_SUBSTRING})
assert_false (${NOT_CONTAINING_SUBSTRING})
