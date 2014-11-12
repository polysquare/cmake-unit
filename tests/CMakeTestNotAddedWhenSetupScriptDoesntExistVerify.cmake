# /tests/CMakeTestNotAddedWhenSetupScriptDoesntExistVerify.cmake
#
# Make sure that we error out when trying to add a setup script that doesn't
# actually exist
#
# See LICENCE.md for Copyright information

include (CMakeUnit)

set (CONFIGURE_ERROR "${CMAKE_CURRENT_BINARY_DIR}/CONFIGURE.error")
assert_file_has_line_matching ("${CONFIGURE_ERROR}" "^.*CMake Error.*$")
assert_file_has_line_matching ("${CONFIGURE_ERROR}" "^.*SampleTest.*$")