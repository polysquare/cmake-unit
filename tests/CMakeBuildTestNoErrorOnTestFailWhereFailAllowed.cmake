# /tests/CMakeBuildTestNoErrorOnTestFailWhereFailAllowed.cmake
#
# Add a build test that will fail to test.
#
# See LICENCE.md for Copyright information

set (TEST_NAME SampleTest)
set (TEST_NAME_VERIFY SampleTestVerify)

file (WRITE "${CMAKE_CURRENT_SOURCE_DIR}/${TEST_NAME}.cmake"
      "enable_testing ()\n"
      "add_test (always_fails\n"
      "          \"${CMAKE_COMMAND}\" does_not_exist)\n")
file (WRITE "${CMAKE_CURRENT_SOURCE_DIR}/${TEST_NAME_VERIFY}.cmake" "")

include (CMakeUnit)
include (CMakeUnitRunner)

cmake_unit_init ()
cmake_unit_build_test (${TEST_NAME} ${TEST_NAME_VERIFY}
                       ALLOW_TEST_FAIL)
