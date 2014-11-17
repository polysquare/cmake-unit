# /tests/SourceFileCreatedBeforeBuildExists.cmake
#
# Check that a source file by the name Source.cpp was created in
# ${CMAKE_CURRENT_SOURCE_DIR} when we call
# cmake_unit_create_source_file_before_build
#
# See LICENCE.md for Copyright information

include (CMakeUnit)

cmake_unit_create_source_file_before_build ()

assert_file_exists ("${CMAKE_CURRENT_SOURCE_DIR}/Source.cpp")
