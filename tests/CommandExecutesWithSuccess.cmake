# /tests/CommandExecutesWithSuccess.cmake
#
# Check the _command_executes_with_success matcher.
#
# See LICENCE.md for Copyright information

include (CMakeUnit)

_command_executes_with_success (RESULT_TRUE
                                ERROR_TRUE
                                CODE_TRUE
                                COMMAND "${CMAKE_COMMAND}")

# Bogus argument to CMake, won't ever succeed
_command_executes_with_success (RESULT_FALSE
                                ERROR_FALSE
                                CODE_FALSE
                                COMMAND
                                "${CMAKE_COMMAND}"
                                "${CMAKE_CURRENT_BINARY_DIR}/does_not_exist")

assert_true (${RESULT_TRUE})
assert_false (${RESULT_FALSE})
