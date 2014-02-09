# /tests/VariableIs.cmake
# Check the _target_is_linked_to matcher.

include (${CMAKE_UNIT_DIRECTORY}/CMakeUnit.cmake)

file (WRITE ${CMAKE_CURRENT_BINARY_DIR}/Library.cpp "")
file (WRITE ${CMAKE_CURRENT_BINARY_DIR}/Source.cpp "")

add_library (library SHARED
	         ${CMAKE_CURRENT_BINARY_DIR}/Library.cpp)
add_executable (executable
                ${CMAKE_CURRENT_BINARY_DIR}/Source.cpp)

target_link_libraries (executable library)

_target_is_linked_to (executable library RESULT LIBRARIES)
_target_is_linked_to (executable not_linked_to_this NOT_RESULT LIBRARIES)

# INTERFACE_LINK_LIBRARIES is not set on lower cmake versions which means
# that we can't run this test in continuous-integration. Disable it for now.
# assert_true (${RESULT})
assert_false (${NOT_RESULT})