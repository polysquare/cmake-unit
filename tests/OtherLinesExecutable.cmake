# /tests/OtherLinesExecutable.cmake
#
# Anything else not part of an exclusionary rule should be marked executable.
#
# See LICENCE.md for Copyright information

include (CMakeUnit)
include (RunCMakeTraceToLCovOnCoveredFileCommon)

set (EXECUTABLE_LINES_VARIABLE
     "_${FILE_FOR_COVERAGE_LOCAL_PATH}_EXECUTABLE_LINES")
cmake_unit_assert_list_contains_value ("${EXECUTABLE_LINES_VARIABLE}"
                                       STRING EQUAL "2")
cmake_unit_assert_list_contains_value ("${EXECUTABLE_LINES_VARIABLE}"
                                       STRING EQUAL "5")
cmake_unit_assert_list_contains_value ("${EXECUTABLE_LINES_VARIABLE}"
                                       STRING EQUAL "11")
cmake_unit_assert_list_contains_value ("${EXECUTABLE_LINES_VARIABLE}"
                                       STRING EQUAL "13")
cmake_unit_assert_list_contains_value ("${EXECUTABLE_LINES_VARIABLE}"
                                       STRING EQUAL "14")
cmake_unit_assert_list_contains_value ("${EXECUTABLE_LINES_VARIABLE}"
                                       STRING EQUAL "21")
cmake_unit_assert_list_contains_value ("${EXECUTABLE_LINES_VARIABLE}"
                                       STRING EQUAL "24")
cmake_unit_assert_list_contains_value ("${EXECUTABLE_LINES_VARIABLE}"
                                       STRING EQUAL "26")
cmake_unit_assert_list_contains_value ("${EXECUTABLE_LINES_VARIABLE}"
                                       STRING EQUAL "30")
cmake_unit_assert_list_contains_value ("${EXECUTABLE_LINES_VARIABLE}"
                                       STRING EQUAL "32")
