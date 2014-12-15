# /tests/LinesUntilCloseBracketNotExecutable.cmake
#
# Check that lines overflowing after an intial open-brace are not executable
# until the brace is closed on the end of the line
#
# See LICENCE.md for Copyright information

include (CMakeUnit)
include (RunCMakeTraceToLCovOnCoveredFileCommon)

set (EXECUTABLE_LINES_VARIABLE
     "_${FILE_FOR_COVERAGE_LOCAL_PATH}_EXECUTABLE_LINES")
cmake_unit_assert_list_does_not_contain_value ("${EXECUTABLE_LINES_VARIABLE}"
                                               STRING EQUAL "6")
cmake_unit_assert_list_does_not_contain_value ("${EXECUTABLE_LINES_VARIABLE}"
                                               STRING EQUAL "22")

cmake_unit_assert_file_does_not_have_line_matching ("${LCOV_OUTPUT}" "^DA:6$")
cmake_unit_assert_file_does_not_have_line_matching ("${LCOV_OUTPUT}" "^DA:22$")
