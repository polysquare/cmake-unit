# /tests/CMakeTestNotAddedWhenSetupScriptDoesntExist.cmake
#
# Check that where we dont have TestName.cmake in CMAKE_CURRENT_SOURCE_DIR
# that calling add_cmake_test errors out
#
# See LICENCE.md for Copyright information

set (TEST_NAME SampleTest)

include (CMakeUnit)
include (CMakeUnitRunner)

bootstrap_cmake_unit ()
add_cmake_test (${TEST_NAME})
