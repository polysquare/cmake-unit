# /tests/CMakeTestAddedWhereSetupScriptExists.cmake
#
# Check that where we have TestName.cmake in CMAKE_CURRENT_SOURCE_DIR
# that calling add_cmake_test actually adds a test
#
# See LICENCE.md for Copyright information

set (TEST_NAME SampleTest)
file (WRITE "${CMAKE_CURRENT_SOURCE_DIR}/${TEST_NAME}.cmake" "")

include (CMakeUnit)
include (CMakeUnitRunner)

set (VARIABLE "test_value")
bootstrap_cmake_unit (VARIABLES VARIABLE)

add_cmake_test (${TEST_NAME})