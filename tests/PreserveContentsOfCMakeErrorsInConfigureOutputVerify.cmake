# /tests/PreserveContentsOfConfigureOutputVerify.cmake
#
# Check the test output to make sure that we got "CMake Error", both lines of
# our error message and the call stack
#
# See LICENCE.md for Copyright information

include (CMakeUnit)

set (TEST_OUTPUT "${CMAKE_CURRENT_BINARY_DIR}/TEST.output")
assert_file_has_line_matching ("${TEST_OUTPUT}" "^.*CMake Error.*$")
assert_file_has_line_matching ("${TEST_OUTPUT}" "^.*Fatal Error.*$")
assert_file_has_line_matching ("${TEST_OUTPUT}" "^.*On Multiple Lines.*$")
assert_file_has_line_matching ("${TEST_OUTPUT}" "^.*Call Stack.*$")
