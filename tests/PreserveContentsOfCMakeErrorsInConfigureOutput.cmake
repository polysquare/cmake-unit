# /tests/PreserveContentsOfCMakeErrorsInConfigureOutput.cmake
#
# Add a test whose configure step is allowed to fail and make it print a
# FATAL_WARNING on the configure step.
#
# See LICENCE.md for Copyright information

include (CMakeUnit)
include (CMakeUnitRunner)

set (TEST_NAME "SampleTest")

file (WRITE "${CMAKE_CURRENT_SOURCE_DIR}/${TEST_NAME}.cmake"
      "message (FATAL_ERROR \"Fatal Error\\nOn Multiple Lines\")\n")
file (WRITE "${CMAKE_CURRENT_SOURCE_DIR}/${TEST_NAME}Verify.cmake" "")

add_cmake_build_test ("${TEST_NAME}" "${TEST_NAME}Verify"
                      ALLOW_CONFIGURE_FAIL)
