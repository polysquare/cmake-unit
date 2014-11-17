# /tests/InitialCacheContainsForwardedVariables.cmake
#
# Ensure that ${CMAKE_CURRENT_BINARY_DIR}/${TEST_NAME}/initial_cache.cmake
# contains some of the variables that we intended to forward to each test,
# in this test that would be TEST_VARIABLE
#
# See LICENCE.md for Copyright information

set (TEST_NAME SampleTest)
file (WRITE "${CMAKE_CURRENT_SOURCE_DIR}/${TEST_NAME}.cmake" "")

include (CMakeUnit)
include (CMakeUnitRunner)

set (VARIABLE "test_value")
bootstrap_cmake_unit (VARIABLES VARIABLE)

add_cmake_test (${TEST_NAME})

set (INITIAL_CACHE_FILE
     ${CMAKE_CURRENT_BINARY_DIR}/${TEST_NAME}/initial_cache.cmake)
assert_file_has_line_matching ("${INITIAL_CACHE_FILE}"
                               "^.*set .*VARIABLE.*test_value.*CACHE.*$")
