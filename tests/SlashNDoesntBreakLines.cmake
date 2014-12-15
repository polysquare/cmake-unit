# /tests/SlashNDoesntBreakLines.cmake
#
# Check that \n in the middle of the line don't cause extra lines to be
# added (such that we get a bogus line report from CMakeTraceToLCov)
#
# See LICENCE.md for Copyright information

include (CMakeUnit)
include (RunCMakeTraceToLCovOnCoveredFileCommon)

set (EXECUTABLE_LINES_VARIABLE
     "_${FILE_FOR_COVERAGE_LOCAL_PATH}_EXECUTABLE_LINES")
cmake_unit_assert_list_does_not_contain_value ("${EXECUTABLE_LINES_VARIABLE}"
                                               STRING EQUAL "17")

cmake_unit_assert_file_does_not_have_line_matching ("${LCOV_OUTPUT}" "^DA:17$")
