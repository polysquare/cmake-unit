# /tests/DriverScriptWrittenAfterTestAdded.cmake
#
# Ensure that ${CMAKE_CURRENT_BINARY_DIR}/${TEST_NAME}/${TEST_NAME}Driver.cmake
# is written out after add_cmake_test
#
# See LICENCE.md for Copyright information

set (TEST_NAME SampleTest)
file (WRITE "${CMAKE_CURRENT_SOURCE_DIR}/${TEST_NAME}.cmake" "")

include (CMakeUnit)
include (CMakeUnitRunner)

bootstrap_cmake_unit ()

add_cmake_test (${TEST_NAME})

set (DRIVER_FILE
     ${CMAKE_CURRENT_BINARY_DIR}/${TEST_NAME}/${TEST_NAME}Driver.cmake)
assert_file_exists (${DRIVER_FILE})
