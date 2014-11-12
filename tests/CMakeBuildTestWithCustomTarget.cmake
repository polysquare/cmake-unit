# /tests/CMakeBuildTestWithCustomTarget.cmake
#
# Tells a build test to build a custom target
#
# See LICENCE.md for Copyright information

set (TEST_NAME SampleTest)
set (TEST_NAME_VERIFY SampleTestVerify)
file (WRITE "${CMAKE_CURRENT_SOURCE_DIR}/${TEST_NAME}.cmake"
      "add_custom_target (custom_target)\n")
file (WRITE "${CMAKE_CURRENT_SOURCE_DIR}/${TEST_NAME_VERIFY}.cmake" "")

include (CMakeUnit)
include (CMakeUnitRunner)

bootstrap_cmake_unit ()
add_cmake_build_test (${TEST_NAME} ${TEST_NAME_VERIFY}
                      TARGET custom_target)