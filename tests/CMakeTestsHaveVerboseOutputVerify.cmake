# /tests/CMakeTestsHaveVerboseOutputVerify.cmake
#
# Checks that cmake -E touch Generated.cpp was in the test output -
# if it was, it means that this command was run with verbose
# output.
#
# See LICENCE.md for Copyright information

include (CMakeUnit)

cmake_unit_escape_string ("${CMAKE_COMMAND}" ESCAPED_CMAKE_COMMAND)

set (TEST_OUTPUT "${CMAKE_CURRENT_BINARY_DIR}/TEST.output")

set (CUSTOM_COMMAND_CMAKE_REGEX
     "^.*${ESCAPED_CMAKE_COMMAND} -E touch .*Generated.cpp.*$")
cmake_unit_assert_file_has_line_matching ("${TEST_OUTPUT}"
                                          "${CUSTOM_COMMAND_CMAKE_REGEX}")
