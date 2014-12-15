# /tests/CMakeBuildTestAddedWhereVerifyScriptExistsVerify.cmake
#
# Make sure that the CTest output indicates that we're running SampleTest and
# furthermore that the build output indicates that we built, tested and
# verified SampleTest too.
#
# See LICENCE.md for Copyright information

include (CMakeUnit)

cmake_unit_escape_string ("${CMAKE_COMMAND}" ESCAPED_CMAKE_COMMAND)
cmake_unit_escape_string ("${CMAKE_CTEST_COMMAND}" ESCAPED_CMAKE_CTEST_COMMAND)

set (TEST_OUTPUT "${CMAKE_CURRENT_BINARY_DIR}/TEST.output")
cmake_unit_assert_file_has_line_matching ("${TEST_OUTPUT}"
                                          "^.*Start.*SampleTest.*$")
set (CMAKE_BUILD_REGEX "^.*${ESCAPED_CMAKE_COMMAND} --build.*$")
cmake_unit_assert_file_has_line_matching ("${TEST_OUTPUT}"
                                          "${CMAKE_BUILD_REGEX}")
set (CMAKE_TEST_REGEX "^.*${ESCAPED_CMAKE_TEST_COMMAND}.*$")
cmake_unit_assert_file_has_line_matching ("${TEST_OUTPUT}"
                                          "${CMAKE_TEST_REGEX}")
set (VERIFY_REGEX "^.*${ESCAPED_CMAKE_COMMAND}.*P.*SampleTestVerify.*$")
cmake_unit_assert_file_has_line_matching ("${TEST_OUTPUT}" "${VERIFY_REGEX}")
