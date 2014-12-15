# /tests/CMakeTestNotAddedWhenSetupScriptDoesntExist.cmake
#
# Check that where we dont have TestName.cmake in CMAKE_CURRENT_SOURCE_DIR
# that calling cmake_unit_config_test errors out
#
# See LICENCE.md for Copyright information

set (TEST_NAME SampleTest)

include (CMakeUnit)
include (CMakeUnitRunner)

cmake_unit_init ()
cmake_unit_config_test (${TEST_NAME})
