# /tests/CommandExecutesWithSuccess.cmake
#
# Check the _cmake_unit_command_executes_with_success matcher.
#
# See LICENCE.md for Copyright information

include (CMakeUnit)

_cmake_unit_command_executes_with_success (RESULT_TRUE
                                           ERROR_TRUE
                                           CODE_TRUE
                                           COMMAND "${CMAKE_COMMAND}")

# Bogus argument to CMake, won't ever succeed
set (UNSUCCESSFUL_EXECUTABLE "${CMAKE_CURRENT_BINARY_DIR}/does_not_exist")
_cmake_unit_command_executes_with_success (RESULT_FALSE
                                           ERROR_FALSE
                                           CODE_FALSE
                                           COMMAND
                                           "${CMAKE_COMMAND}"
                                           "${UNSUCCESSFUL_EXECUTABLE}")

cmake_unit_assert_true (${RESULT_TRUE})
cmake_unit_assert_false (${RESULT_FALSE})
