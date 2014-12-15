# /tests/LinesStartingWithEndNotExecutable.cmake
#
# Check that lines starting with ".*end" are not executable
#
# See LICENCE.md for Copyright information

include (CMakeUnit)
include (RunCMakeTraceToLCovOnCoveredFileCommon)

set (EXECUTABLE_LINES_VARIABLE
     "_${FILE_FOR_COVERAGE_LOCAL_PATH}_EXECUTABLE_LINES")
cmake_unit_assert_list_does_not_contain_value ("${EXECUTABLE_LINES_VARIABLE}"
                                               STRING EQUAL "3")
cmake_unit_assert_list_does_not_contain_value ("${EXECUTABLE_LINES_VARIABLE}"
                                               STRING EQUAL "19")
cmake_unit_assert_list_does_not_contain_value ("${EXECUTABLE_LINES_VARIABLE}"
                                               STRING EQUAL "28")
cmake_unit_assert_list_does_not_contain_value ("${EXECUTABLE_LINES_VARIABLE}"
                                               STRING EQUAL "34")
cmake_unit_assert_list_does_not_contain_value ("${EXECUTABLE_LINES_VARIABLE}"
                                               STRING EQUAL "36")

cmake_unit_assert_file_does_not_have_line_matching ("${LCOV_OUTPUT}" "^DA:3$")
cmake_unit_assert_file_does_not_have_line_matching ("${LCOV_OUTPUT}" "^DA:19$")
cmake_unit_assert_file_does_not_have_line_matching ("${LCOV_OUTPUT}" "^DA:28$")
cmake_unit_assert_file_does_not_have_line_matching ("${LCOV_OUTPUT}" "^DA:34$")
cmake_unit_assert_file_does_not_have_line_matching ("${LCOV_OUTPUT}" "^DA:36$")
