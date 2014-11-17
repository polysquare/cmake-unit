# /tests/CMakeBuildTestWarningsNotErrorsWhereWErrorDisabledVerify.cmake
#
# Make sure that we don't have any errors, but warnings are allowed
#
# See LICENCE.md for Copyright information

include (CMakeUnit)

set (TEST_OUTPUT "${CMAKE_CURRENT_BINARY_DIR}/TEST.output")
assert_file_does_not_have_line_matching ("${TEST_OUTPUT}" "^.*CMake Error.*$")
assert_file_has_line_matching ("${TEST_OUTPUT}" "^.*CMake Warning.*$")
