# /tests/TargetIsLinkedTo.cmake
#
# Check the _cmake_unit_target_is_linked_to matcher.
#
# See LICENCE.md for Copyright information

include (CMakeUnit)

file (WRITE "${CMAKE_CURRENT_BINARY_DIR}/Library.cpp" "")
file (WRITE "${CMAKE_CURRENT_BINARY_DIR}/Source.cpp" "")

add_library (library SHARED
             "${CMAKE_CURRENT_BINARY_DIR}/Library.cpp")
add_executable (executable
                "${CMAKE_CURRENT_BINARY_DIR}/Source.cpp")

target_link_libraries (executable library)

_cmake_unit_target_is_linked_to (executable library RESULT)
_cmake_unit_target_is_linked_to (executable not_linked_to_this NOT_RESULT)

cmake_unit_assert_true (${RESULT})
cmake_unit_assert_false (${NOT_RESULT})
