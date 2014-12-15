# /tests/SourceFileCreatedBeforeBuildWithIncludes.cmake
#
# Check that a source file by the name Source.cpp was created in
# ${CMAKE_CURRENT_SOURCE_DIR} with #include "my_include.h" when we call
# cmake_unit_create_source_file_before_build with INCLUDES my_include.h
#
# See LICENCE.md for Copyright information

include (CMakeUnit)

cmake_unit_create_source_file_before_build (INCLUDES my_include.h)

set (SOURCE_FILE "${CMAKE_CURRENT_SOURCE_DIR}/Source.cpp")
cmake_unit_assert_file_has_line_matching ("${SOURCE_FILE}"
                                          "^.include \"my_include.h\"$")
