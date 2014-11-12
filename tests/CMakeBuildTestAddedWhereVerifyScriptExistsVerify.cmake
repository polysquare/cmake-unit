# /tests/CMakeTestAddedWhereVerifyScriptExistsVerify.cmake
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
assert_file_has_line_matching ("${TEST_OUTPUT}" "^.*Start.*SampleTest.*$")
assert_file_has_line_matching ("${TEST_OUTPUT}"
                               "^.*${ESCAPED_CMAKE_COMMAND} --build.*$")
assert_file_has_line_matching ("${TEST_OUTPUT}"
                               "^.*${ESCAPED_CMAKE_TEST_COMMAND}.*$")
set (VERIFY_REGEX "^.*${ESCAPED_CMAKE_COMMAND}.*P.*SampleTestVerify.*$")
assert_file_has_line_matching ("${TEST_OUTPUT}" "${VERIFY_REGEX}")