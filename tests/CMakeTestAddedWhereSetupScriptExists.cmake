# /tests/CMakeTestAddedWhereSetupScriptExists.cmake
#
# Check that where we have TestName.cmake in CMAKE_CURRENT_SOURCE_DIR
# that calling cmake_unit_config_test actually adds a test
#
# See LICENCE.md for Copyright information

set (TEST_NAME SampleTest)
file (WRITE "${CMAKE_CURRENT_SOURCE_DIR}/${TEST_NAME}.cmake" "")

include (CMakeUnit)
include (CMakeUnitRunner)

cmake_unit_init ()
cmake_unit_config_test (${TEST_NAME})
