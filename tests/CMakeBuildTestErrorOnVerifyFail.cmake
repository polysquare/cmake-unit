# /tests/CMakeBuildTestErrorOnVerifyFail.cmake
#
# Add a build test that will fail to verify.
#
# See LICENCE.md for Copyright information

set (TEST_NAME SampleTest)
set (TEST_NAME_VERIFY SampleTestVerify)

# Executable build will fail - no main defined.
file (WRITE "${CMAKE_CURRENT_SOURCE_DIR}/${TEST_NAME}.cmake" "")
file (WRITE "${CMAKE_CURRENT_SOURCE_DIR}/${TEST_NAME_VERIFY}.cmake"
      "message (FATAL_ERROR \"Fatal error\")\n")

include (CMakeUnit)
include (CMakeUnitRunner)

cmake_unit_init ()
cmake_unit_build_test (${TEST_NAME} ${TEST_NAME_VERIFY})
