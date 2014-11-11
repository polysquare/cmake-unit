# /tests/CMakeBuildTestNoErrorOnConfigureFailWhereFailAllowed.cmake
#
# Add a build test that will fail to build.
#
# See LICENCE.md for Copyright information

set (TEST_NAME SampleTest)
set (TEST_NAME_VERIFY SampleTestVerify)

# Executable build will fail - no main defined.
file (WRITE "${CMAKE_CURRENT_SOURCE_DIR}/${TEST_NAME}.cmake"
            "message (FATAL_ERROR \"Fatal Error\")\n")
file (WRITE "${CMAKE_CURRENT_SOURCE_DIR}/${TEST_NAME_VERIFY}.cmake" "")

include (CMakeUnit)
include (CMakeUnitRunner)

set (VARIABLE "test_value")
bootstrap_cmake_unit (VARIABLES VARIABLE)

add_cmake_build_test (${TEST_NAME} ${TEST_NAME_VERIFY}
                      ALLOW_CONFIGURE_FAIL)