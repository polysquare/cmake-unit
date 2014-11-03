# /tests/LinesStartingWithEndNotExecutable.cmake
# Check that lines starting with ".*end" are not executable
#
# See LICENCE.md for Copyright information

include (CMakeUnit)
include (RunCMakeTraceToLCovOnCoveredFileCommon)

set (EXECUTABLE_LINES_VARIABLE
     "_${FILE_FOR_COVERAGE_LOCAL_PATH}_EXECUTABLE_LINES")
assert_list_does_not_contain_value ("${EXECUTABLE_LINES_VARIABLE}"
                                    STRING EQUAL "3")
assert_list_does_not_contain_value ("${EXECUTABLE_LINES_VARIABLE}"
                                    STRING EQUAL "19")
assert_list_does_not_contain_value ("${EXECUTABLE_LINES_VARIABLE}"
                                    STRING EQUAL "28")
assert_list_does_not_contain_value ("${EXECUTABLE_LINES_VARIABLE}"
                                    STRING EQUAL "34")
assert_list_does_not_contain_value ("${EXECUTABLE_LINES_VARIABLE}"
                                    STRING EQUAL "36")

assert_file_does_not_have_line_matching ("${LCOV_OUTPUT}" "^DA:3$")
assert_file_does_not_have_line_matching ("${LCOV_OUTPUT}" "^DA:19$")
assert_file_does_not_have_line_matching ("${LCOV_OUTPUT}" "^DA:28$")
assert_file_does_not_have_line_matching ("${LCOV_OUTPUT}" "^DA:34$")
assert_file_does_not_have_line_matching ("${LCOV_OUTPUT}" "^DA:36$")