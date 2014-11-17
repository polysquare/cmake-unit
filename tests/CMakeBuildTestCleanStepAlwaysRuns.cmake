# /tests/CMakeBuildTestCleanStepAlwaysRuns.cmake
#
# Adds a cmake_build_test
#
# See LICENCE.md for Copyright information

set (TEST_NAME SampleTest)
set (TEST_NAME_VERIFY SampleTestVerify)
file (WRITE "${CMAKE_CURRENT_SOURCE_DIR}/${TEST_NAME}.cmake" "")
file (WRITE "${CMAKE_CURRENT_SOURCE_DIR}/${TEST_NAME_VERIFY}.cmake" "")

include (CMakeUnit)
include (CMakeUnitRunner)

# Put something in the build directory before the test runs
file (MAKE_DIRECTORY
      ${CMAKE_CURRENT_BINARY_DIR}/${TEST_NAME}/build/check_file)

add_cmake_build_test (${TEST_NAME} ${TEST_NAME_VERIFY})
