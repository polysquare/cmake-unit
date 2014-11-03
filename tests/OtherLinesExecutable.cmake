# /tests/OtherLinesExecutable.cmake
# Anything else not part of an exclusionary rule should be marked executable.
#
# See LICENCE.md for Copyright information

include (CMakeUnit)
include (RunCMakeTraceToLCovOnCoveredFileCommon)

set (EXECUTABLE_LINES_VARIABLE
     "_${FILE_FOR_COVERAGE_LOCAL_PATH}_EXECUTABLE_LINES")
assert_list_contains_value ("${EXECUTABLE_LINES_VARIABLE}"
                            STRING EQUAL "2")
assert_list_contains_value ("${EXECUTABLE_LINES_VARIABLE}"
                            STRING EQUAL "5")
assert_list_contains_value ("${EXECUTABLE_LINES_VARIABLE}"
                            STRING EQUAL "11")
assert_list_contains_value ("${EXECUTABLE_LINES_VARIABLE}"
                            STRING EQUAL "13")
assert_list_contains_value ("${EXECUTABLE_LINES_VARIABLE}"
                            STRING EQUAL "14")
assert_list_contains_value ("${EXECUTABLE_LINES_VARIABLE}"
                            STRING EQUAL "21")
assert_list_contains_value ("${EXECUTABLE_LINES_VARIABLE}"
                            STRING EQUAL "24")
assert_list_contains_value ("${EXECUTABLE_LINES_VARIABLE}"
                            STRING EQUAL "26")
assert_list_contains_value ("${EXECUTABLE_LINES_VARIABLE}"
                            STRING EQUAL "30")
assert_list_contains_value ("${EXECUTABLE_LINES_VARIABLE}"
                            STRING EQUAL "32")