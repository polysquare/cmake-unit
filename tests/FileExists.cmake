# /tests/FileExists.cmake
#
# Check the _file_exists matcher.
#
# See LICENCE.md for Copyright information

include (CMakeUnit)

file (WRITE ${CMAKE_CURRENT_BINARY_DIR}/File "")

_file_exists (${CMAKE_CURRENT_BINARY_DIR}/File EXISTING_FILE)
_file_exists (${CMAKE_CURRENT_BINARY_DIR}/NotFile NOT_EXISTING_FILE)

assert_true (${EXISTING_FILE})
assert_false (${NOT_EXISTING_FILE})
