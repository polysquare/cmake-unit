# /tests/SourceFileCreatedBeforeBuildWithCustomName.cmake
#
# Check that a source file by the name CustomName.cpp was created in
# ${CMAKE_CURRENT_SOURCE_DIR} when we call
# cmake_unit_create_source_file_before_build with NAME
#
# See LICENCE.md for Copyright information

include (CMakeUnit)

cmake_unit_create_source_file_before_build (NAME "CustomName.cpp")

cmake_unit_assert_file_exists ("${CMAKE_CURRENT_SOURCE_DIR}/CustomName.cpp")
