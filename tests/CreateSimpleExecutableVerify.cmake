# /tests/CreateSimpleExecutableVerify.cmake
#
# Looks up the location of the "executable" target by using
# cmake_unit_get_target_location_from_exports from the
# ${CMAKE_CURRENT_BINARY_DIR}/exports.cmake and executes it
#
# See LICENCE.md for Copyright information

include (CMakeUnit)

set (EXPORTS_FILE "${CMAKE_CURRENT_BINARY_DIR}/exports.cmake")
cmake_unit_get_target_location_from_exports ("${EXPORTS_FILE}"
                                             executable
                                             LOCATION)

cmake_unit_assert_file_exists ("${LOCATION}")
cmake_unit_assert_command_executes_with_success (COMMAND "${LOCATION}")
