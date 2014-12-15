# /tests/CMakeBuildTestErrorOnTestFailVerify.cmake
#
# Check that there's a CMake error when the test step fails
#
# See LICENCE.md for Copyright information

include (CMakeUnit)

cmake_unit_escape_string ("${CMAKE_CTEST_COMMAND}" ESCAPED_CTEST_COMMAND)

set (TEST_OUTPUT "${CMAKE_CURRENT_BINARY_DIR}/TEST.output")
cmake_unit_assert_file_has_line_matching ("${TEST_OUTPUT}"
                                          "^.*CMake Error.*$")
cmake_unit_assert_file_has_line_matching ("${TEST_OUTPUT}"
                                          "^.*${ESCAPED_CTEST_COMMAND}.*$")
cmake_unit_assert_file_has_line_matching ("${TEST_OUTPUT}"
                                          "^.*failed.*$")
cmake_unit_assert_file_has_line_matching ("${TEST_OUTPUT}"
                                          "^.*1.*$")
