# /tests/CMakeBuildTestErrorOnBuildFailVerify.cmake
#
# Check that there's a CMake error when the build step fails
#
# See LICENCE.md for Copyright information

include (CMakeUnit)

cmake_unit_escape_string ("${CMAKE_COMMAND}" ESCAPED_CMAKE_COMMAND)

set (TEST_OUTPUT "${CMAKE_CURRENT_BINARY_DIR}/TEST.output")
assert_file_has_line_matching ("${TEST_OUTPUT}"
                               "^.*CMake Error.*$")
assert_file_has_line_matching ("${TEST_OUTPUT}"
                               "^.*${ESCAPED_CMAKE_COMMAND}.*$")
assert_file_has_line_matching ("${TEST_OUTPUT}"
                               "^.*-P.*$")
assert_file_has_line_matching ("${TEST_OUTPUT}"
                               "^.*SampleTestVerify.*$")
assert_file_has_line_matching ("${TEST_OUTPUT}"
                               "^.*failed.*$")
assert_file_has_line_matching ("${TEST_OUTPUT}"
                               "^.*1.*$")