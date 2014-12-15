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
cmake_unit_init (VARIABLES VARIABLE)

cmake_unit_config_test (${TEST_NAME})

set (INITIAL_CACHE_FILE
     "${CMAKE_CURRENT_BINARY_DIR}/${TEST_NAME}/initial_cache.cmake")
set (INITIAL_CACHE_REGEX "^.*set .*VARIABLE.*test_value.*CACHE.*$")
cmake_unit_assert_file_has_line_matching ("${INITIAL_CACHE_FILE}"
                                          "${INITIAL_CACHE_REGEX}")
