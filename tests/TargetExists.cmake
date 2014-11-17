# /tests/TargetExists.cmake
#
# Check the _target_exists matcher.
#
# See LICENCE.md for Copyright information

include (CMakeUnit)

file (WRITE ${CMAKE_CURRENT_BINARY_DIR}/Library.cpp "")
add_library (library SHARED
             ${CMAKE_CURRENT_BINARY_DIR}/Library.cpp)

_target_exists (library RESULT)
_target_exists (not_existing NOT_RESULT)

assert_true (${RESULT})
assert_false (${NOT_RESULT})
