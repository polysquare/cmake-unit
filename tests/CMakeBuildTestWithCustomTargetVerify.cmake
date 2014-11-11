# /tests/CMakeTestWithCustomTargetVerify.cmake
#
# Make sure that we passed our custom target to cmake --build
#
# See LICENCE.md for Copyright information

include (CMakeUnit)

set (TEST_OUTPUT "${CMAKE_CURRENT_BINARY_DIR}/TEST.output")
assert_file_has_line_matching ("${TEST_OUTPUT}" "^.*Start.*SampleTest.*$")
assert_file_has_line_matching ("${TEST_OUTPUT}"
                               "^.*${CMAKE_COMMAND} --build.*$")
assert_file_has_line_matching ("${TEST_OUTPUT}"
                               "^.*--target custom_target.*$")