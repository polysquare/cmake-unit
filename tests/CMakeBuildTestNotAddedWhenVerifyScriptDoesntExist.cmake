# /tests/CMakeBuildTestNotAddedWhenVerifyScriptDoesntExist.cmake
#
# Check that where we dont have TestNameVerify.cmake in CMAKE_CURRENT_SOURCE_DIR
# that calling cmake_unit_build_test errors out
#
# See LICENCE.md for Copyright information

set (TEST_NAME SampleTest)
set (TEST_NAME_VERIFY SampleTestVerify)
file (WRITE "${CMAKE_CURRENT_SOURCE_DIR}/${TEST_NAME}.cmake" "")

include (CMakeUnit)
include (CMakeUnitRunner)

cmake_unit_init ()
cmake_unit_build_test (${TEST_NAME} ${TEST_NAME_VERIFY})
