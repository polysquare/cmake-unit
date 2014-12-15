# /tests/CMakeBuildTestBuildStepNotRunIfConfigureCanFailVerify.cmake
#
# Check that the build step never runs
#
# See LICENCE.md for Copyright information

include (CMakeUnit)

set (TEST_OUTPUT "${CMAKE_CURRENT_BINARY_DIR}/TEST.output")
cmake_unit_assert_file_does_not_have_line_matching ("${TEST_OUTPUT}"
                                                    "^.*--build.*$")
