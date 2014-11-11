# /tests/CMakeTestAddedWhereVerifyScriptExistsVerify.cmake
#
# Make sure that the CTest output indicates that we're running SampleTest and
# furthermore that the build output indicates that we built, tested and
# verified SampleTest too.
#
# See LICENCE.md for Copyright information

include (CMakeUnit)

set (TEST_OUTPUT "${CMAKE_CURRENT_BINARY_DIR}/TEST.output")
assert_file_has_line_matching ("${TEST_OUTPUT}" "^.*Start.*SampleTest.*$")
assert_file_has_line_matching ("${TEST_OUTPUT}"
                               "^.*${CMAKE_COMMAND} --build.*$")
assert_file_has_line_matching ("${TEST_OUTPUT}"
                               "^.*${CMAKE_CTEST_COMMAND}.*$")
assert_file_has_line_matching ("${TEST_OUTPUT}"
                               "^.*${CMAKE_COMMAND}.*P.*SampleTestVerify.*$")