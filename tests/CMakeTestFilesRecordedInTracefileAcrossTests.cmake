# /tests/CMakeTestFilesRecordedInTracefileAcrossTests.cmake
#
# Set up some tests which will include some specifified scripts, but not
# a certain excluded script. Eg
#
# FirstTest:
# - Excluded.cmake
# - Included.cmake
# - FirstTestSpecific.cmake
#
# SecondTest:
# - Excluded.cmake
# - Included.cmake
# - SecondTestSpecific.cmake
#
# The following files will be added as part of COVERAGE_FILES
# - Included.cmake
# - FirstTestSpecific.cmake
# - SecondTestSpecific.cmake
#
# See LICENCE.md for Copyright information

project (SampleTests)

set (CMAKE_UNIT_LOG_COVERAGE ON CACHE BOOL "" FORCE)

include (CMakeUnit)
include (CMakeUnitRunner)

set (EXCLUDED_SCRIPT "${CMAKE_CURRENT_BINARY_DIR}/ExcludedScript.cmake")
set (INCLUDED_SCRIPT "${CMAKE_CURRENT_BINARY_DIR}/IncludedScript.cmake")
set (FIRST_TEST_SPECIFIC_SCRIPT
     "${CMAKE_CURRENT_BINARY_DIR}/FirstTestSpecificScript.cmake")
set (SECOND_TEST_SPECIFIC_SCRIPT
     "${CMAKE_CURRENT_BINARY_DIR}/SecondTestSpecificScript.cmake")

# Use the excluded script as a convenient crutch to disable
# all the warnings
file (WRITE "${EXCLUDED_SCRIPT}"
      "message (STATUS \"Excluded Script\")\n")
file (WRITE "${INCLUDED_SCRIPT}"
      "message (STATUS \"Included Script\")\n")
file (WRITE "${FIRST_TEST_SPECIFIC_SCRIPT}"
      "message (STATUS \"First Test Specific Script\")\n")
file (WRITE "${SECOND_TEST_SPECIFIC_SCRIPT}"
      "message (STATUS \"Second Test Specific Script\")\n")

set (FIRST_TEST_SCRIPT_NAME "FirstTest")
set (FIRST_TEST_SCRIPT "${CMAKE_CURRENT_SOURCE_DIR}/FirstTest.cmake")
set (SECOND_TEST_SCRIPT_NAME "SecondTest")
set (SECOND_TEST_SCRIPT "${CMAKE_CURRENT_SOURCE_DIR}/SecondTest.cmake")
set (SECOND_TEST_VERIFY_SCRIPT_NAME "SecondTestVerify")
set (SECOND_TEST_VERIFY_SCRIPT
     "${CMAKE_CURRENT_SOURCE_DIR}/SecondTestVerify.cmake")

bootstrap_cmake_unit (COVERAGE_FILES "${INCLUDED_SCRIPT}"
                                     "${FIRST_TEST_SPECIFIC_SCRIPT}"
                                     "${SECOND_TEST_SPECIFIC_SCRIPT}")

file (WRITE "${FIRST_TEST_SCRIPT}"
      "include (${EXCLUDED_SCRIPT})\n"
      "include (${INCLUDED_SCRIPT})\n"
      "include (${FIRST_TEST_SPECIFIC_SCRIPT})\n")
file (WRITE "${SECOND_TEST_SCRIPT}"
      "include (${EXCLUDED_SCRIPT})\n"
      "include (${INCLUDED_SCRIPT})\n"
      "include (${SECOND_TEST_SPECIFIC_SCRIPT})\n")
file (WRITE "${SECOND_TEST_VERIFY_SCRIPT}"
      "include (${SECOND_TEST_SPECIFIC_SCRIPT})\n")

# Coverage should be recorded in both the test and verify steps
add_cmake_test ("${FIRST_TEST_SCRIPT_NAME}")
add_cmake_build_test ("${SECOND_TEST_SCRIPT_NAME}"
                      "${SECOND_TEST_VERIFY_SCRIPT_NAME}")
