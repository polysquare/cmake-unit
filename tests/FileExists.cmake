# /tests/FileExists.cmake
#
# Check the _cmake_unit_file_exists matcher.
#
# See LICENCE.md for Copyright information

include (CMakeUnit)

file (WRITE "${CMAKE_CURRENT_BINARY_DIR}/File" "")

_cmake_unit_file_exists ("${CMAKE_CURRENT_BINARY_DIR}/File" FILE_EXISTS)
_cmake_unit_file_exists ("${CMAKE_CURRENT_BINARY_DIR}/NotFile" NOT_FILE_EXISTS)

cmake_unit_assert_true ("${FILE_EXISTS}")
cmake_unit_assert_false ("${NOT_FILE_EXISTS}")
