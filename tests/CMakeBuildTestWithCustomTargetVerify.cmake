# /tests/CMakeBuildTestWithCustomTargetVerify.cmake
#
# Make sure that we passed our custom target to cmake --build
#
# See LICENCE.md for Copyright information

include (CMakeUnit)

cmake_unit_escape_string ("${CMAKE_COMMAND}" ESCAPED_CMAKE_COMMAND)

set (TEST_OUTPUT "${CMAKE_CURRENT_BINARY_DIR}/TEST.output")
cmake_unit_assert_file_has_line_matching ("${TEST_OUTPUT}"
                                          "^.*Start.*SampleTest.*$")

set (CMAKE_BUILD_REGEX "^.*${ESCAPED_CMAKE_COMMAND} --build.*$")
cmake_unit_assert_file_has_line_matching ("${TEST_OUTPUT}"
                                          "${CMAKE_BUILD_REGEX}")
cmake_unit_assert_file_has_line_matching ("${TEST_OUTPUT}"
                                          "^.*--target custom_target.*$")
