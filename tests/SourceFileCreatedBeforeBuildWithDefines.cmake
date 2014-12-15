# /tests/SourceFileCreatedBeforeBuildWithDefines.cmake
#
# Check that a source file by the name Source.cpp was created in
# ${CMAKE_CURRENT_SOURCE_DIR} with #define CUSTOM_DEFINE when we call
# cmake_unit_create_source_file_before_build with DEFINES CUSTOM_DEFINE
#
# See LICENCE.md for Copyright information

include (CMakeUnit)

cmake_unit_create_source_file_before_build (DEFINES "CUSTOM_DEFINE")

set (SOURCE_FILE "${CMAKE_CURRENT_SOURCE_DIR}/Source.cpp")
cmake_unit_assert_file_has_line_matching ("${SOURCE_FILE}"
                                          "^.define CUSTOM_DEFINE$")
