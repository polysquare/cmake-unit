# /tests/CMakeBuildTestWarningsAreErrors.cmake
#
# Adds a cmake_build_test with a warning
#
# See LICENCE.md for Copyright information

set (TEST_NAME SampleTest)
set (TEST_NAME_VERIFY SampleTestVerify)

# Generate a warning
file (WRITE "${CMAKE_CURRENT_SOURCE_DIR}/${TEST_NAME}.cmake"
      "message (WARNING \"Warning\")\n")
file (WRITE "${CMAKE_CURRENT_SOURCE_DIR}/${TEST_NAME_VERIFY}.cmake" "")

include (CMakeUnit)
include (CMakeUnitRunner)

cmake_unit_build_test (${TEST_NAME}
                       ${TEST_NAME_VERIFY}
                       ALLOW_CONFIGURE_FAIL)
