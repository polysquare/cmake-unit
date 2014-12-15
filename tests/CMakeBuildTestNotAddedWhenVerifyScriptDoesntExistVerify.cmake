# /tests/CMakeBuildTestNotAddedWhenVerifyScriptDoesntExistVerify.cmake
#
# Make sure that we error out when trying to add a verify script that doesn't
# actually exist
#
# See LICENCE.md for Copyright information

include (CMakeUnit)

set (CONFIGURE_ERROR "${CMAKE_CURRENT_BINARY_DIR}/CONFIGURE.error")
cmake_unit_assert_file_has_line_matching ("${CONFIGURE_ERROR}"
                                          "^.*CMake Error.*$")
cmake_unit_assert_file_has_line_matching ("${CONFIGURE_ERROR}"
                                          "^.*SampleTestVerify.*$")
