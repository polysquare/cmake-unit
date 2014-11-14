# /tests/SourceFileCreatedBeforeBuildWithDefines.cmake
#
# Check that a source file by the name Source.cpp was created in
# ${CMAKE_CURRENT_SOURCE_DIR} with #define CUSTOM_DEFINE when we call
# cmake_unit_create_source_file_before_build with DEFINES CUSTOM_DEFINE
#
# See LICENCE.md for Copyright information.

include (CMakeUnit)

cmake_unit_create_source_file_before_build (DEFINES "CUSTOM_DEFINE")

assert_file_has_line_matching ("${CMAKE_CURRENT_SOURCE_DIR}/Source.cpp"
                               "^.define CUSTOM_DEFINE$")
