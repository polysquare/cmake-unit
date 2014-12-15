# /tests/CMakeBuildTestCleanStepNotRunOnNoCleanVerify.cmake
#
# Make sure that we cleaned out the build directory
#
# See LICENCE.md for Copyright information

include (CMakeUnit)

set (FILE_THAT_SHOULD_NOT_EXIST
     "${CMAKE_CURRENT_BINARY_DIR}/SampleTest/build/check_file")
cmake_unit_assert_file_exists (${FILE_THAT_SHOULD_NOT_EXIST})
