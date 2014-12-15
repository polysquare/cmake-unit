# /tests/DriverScriptWrittenAfterTestAdded.cmake
#
# Ensure that ${CMAKE_CURRENT_BINARY_DIR}/${TEST_NAME}/${TEST_NAME}Driver.cmake
# is written out after cmake_unit_config_test
#
# See LICENCE.md for Copyright information

set (TEST_NAME SampleTest)
file (WRITE "${CMAKE_CURRENT_SOURCE_DIR}/${TEST_NAME}.cmake" "")

include (CMakeUnit)
include (CMakeUnitRunner)

cmake_unit_init ()

cmake_unit_config_test (${TEST_NAME})

set (DRIVER_FILE
     "${CMAKE_CURRENT_BINARY_DIR}/${TEST_NAME}/${TEST_NAME}Driver.cmake")
cmake_unit_assert_file_exists ("${DRIVER_FILE}")
