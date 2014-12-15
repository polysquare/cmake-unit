# /tests/CMakeBuildTestTestStepNotRunIfBuildCanFail.cmake
#
# Add a build test that can fail to build.
#
# See LICENCE.md for Copyright information

set (TEST_NAME SampleTest)
set (TEST_NAME_VERIFY SampleTestVerify)
file (WRITE "${CMAKE_CURRENT_SOURCE_DIR}/${TEST_NAME}.cmake" "")
file (WRITE "${CMAKE_CURRENT_SOURCE_DIR}/${TEST_NAME_VERIFY}.cmake" "")

include (CMakeUnit)
include (CMakeUnitRunner)

cmake_unit_init ()
cmake_unit_build_test (${TEST_NAME} ${TEST_NAME_VERIFY}
                       ALLOW_BUILD_FAIL)
