# /tests/CMakeBuildTestErrorOnTestFail.cmake
#
# Add a build test that will fail to configure.
#
# See LICENCE.md for Copyright information

set (TEST_NAME SampleTest)
set (TEST_NAME_VERIFY SampleTestVerify)

# The fact that we have defined no tests is an error
file (WRITE "${CMAKE_CURRENT_SOURCE_DIR}/${TEST_NAME}.cmake"
      "enable_testing ()\n"
      "add_test (always_fails\n"
      "          COMMAND \"${CMAKE_COMMAND}\" does_not_exist)\n")
file (WRITE "${CMAKE_CURRENT_SOURCE_DIR}/${TEST_NAME_VERIFY}.cmake" "")

include (CMakeUnit)
include (CMakeUnitRunner)

add_cmake_build_test (${TEST_NAME} ${TEST_NAME_VERIFY})
