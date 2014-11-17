# /tests/SourceFileGeneratedDuringBuildExists.cmake
#
# Check that a source file by the name Source.cpp was created in
# ${CMAKE_CURRENT_SOURCE_DIR} when we call
# cmake_unit_create_source_file_before_build
#
# See LICENCE.md for Copyright information

include (CMakeUnit)

cmake_unit_generate_source_file_during_build (GENERATED_DURING_TARGET)

# File should not exist yet
assert_file_does_not_exist ("${CMAKE_CURRENT_SOURCE_DIR}/Source.cpp")
