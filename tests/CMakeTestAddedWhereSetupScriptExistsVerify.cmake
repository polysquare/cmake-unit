# /tests/CMakeTestAddedWhereSetupScriptExistsVerify.cmake
#
# Make sure that the CTest output indicates that we're running SampleTest
#
# See LICENCE.md for Copyright information

include (CMakeUnit)

set (TEST_OUTPUT "${CMAKE_CURRENT_BINARY_DIR}/TEST.output")
cmake_unit_assert_file_has_line_matching ("${TEST_OUTPUT}"
                                          "^.*Start.*SampleTest.*$")
