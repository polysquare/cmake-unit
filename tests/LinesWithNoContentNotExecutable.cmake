# /tests/LinesWithNoContentNotExecutable.cmake
#
# Check that lines starting with a "\n" or just whitespace are not executable
# with CMakeTraceToLCov
#
# See LICENCE.md for Copyright information

include (CMakeUnit)
include (RunCMakeTraceToLCovOnCoveredFileCommon)

set (EXECUTABLE_LINES_VARIABLE
     "_${FILE_FOR_COVERAGE_LOCAL_PATH}_EXECUTABLE_LINES")
cmake_unit_assert_list_does_not_contain_value ("${EXECUTABLE_LINES_VARIABLE}"
                                               STRING EQUAL "7")
cmake_unit_assert_list_does_not_contain_value ("${EXECUTABLE_LINES_VARIABLE}"
                                               STRING EQUAL "10")

cmake_unit_assert_file_does_not_have_line_matching ("${LCOV_OUTPUT}" "^DA:7$")
cmake_unit_assert_file_does_not_have_line_matching ("${LCOV_OUTPUT}" "^DA:10$")
