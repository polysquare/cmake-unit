# /tests/CMakeBuildTestCleanStepAlwaysRunsVerify.cmake
#
# Make sure that we cleaned out the build directory
#
# See LICENCE.md for Copyright information

include (CMakeUnit)

set (FILE_THAT_SHOULD_NOT_EXIST
     ${CMAKE_CURRENT_BINARY_DIR}/SampleTest/build/check_file)
assert_file_does_not_exist (${FILE_THAT_SHOULD_NOT_EXIST})