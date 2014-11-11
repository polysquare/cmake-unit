# /tests/CMakeBuildTestErrorOnConfigureFailVerify.cmake
#
# Check that there's a CMake error when the configure step fails
#
# See LICENCE.md for Copyright information

include (CMakeUnit)

set (TEST_OUTPUT "${CMAKE_CURRENT_BINARY_DIR}/TEST.output")
assert_file_has_line_matching ("${TEST_OUTPUT}"
                               "^.*CMake Error.*$")
assert_file_has_line_matching ("${TEST_OUTPUT}"
                               "^.*${CMAKE_COMMAND}.*$")
assert_file_has_line_matching ("${TEST_OUTPUT}"
                               "^.*failed.*$")
assert_file_has_line_matching ("${TEST_OUTPUT}"
                               "^.*1.*$")