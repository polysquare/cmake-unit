# /tests/CMakeBuildTestWarningsAreErrorsVerify.cmake
#
# Check to make sure we got an error
#
# See LICENCE.md for Copyright information

include (CMakeUnit)

set (TEST_OUTPUT "${CMAKE_CURRENT_BINARY_DIR}/TEST.output")
assert_file_has_line_matching ("${TEST_OUTPUT}"
                               "^.*CMake Error.*$")
