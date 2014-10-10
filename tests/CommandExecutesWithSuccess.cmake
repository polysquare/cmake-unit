# /tests/CommandExecutesWithSuccess.cmake
# Check the _command_executes_with_success matcher.

find_program (FALSE_PROGRAM false)
find_program (TRUE_PROGRAM true)

include (CMakeUnit)

_command_executes_with_success (TRUE_PROGRAM
                                RESULT_TRUE
                                ERROR_TRUE
                                CODE_TRUE)
_command_executes_with_success (FALSE_PROGRAM
                                RESULT_FALSE
                                ERROR_FALSE
                                CODE_FALSE)

assert_true (${RESULT_TRUE})
assert_false (${RESULT_FALSE})