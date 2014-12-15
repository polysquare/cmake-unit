# /tests/SourceFileGeneratedDuringBuildExistsVerify.cmake
#
# Checks after build that our source file was generated and exists
#
# See LICENCE.md for Copyright information

include (CMakeUnit)

cmake_unit_assert_file_exists ("${CMAKE_CURRENT_BINARY_DIR}/Source.cpp")
