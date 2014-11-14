# /tests/SourceFileCreatedBeforeBuildHeaderGuardsIfHeader.cmake
#
# Check that a source file by the name Header.h was created in
# ${CMAKE_CURRENT_SOURCE_DIR} and contains header guards like
# #ifdef HEADER_H
# #define HEADER_H
# ...
# #endif
#
# See LICENCE.md for Copyright information.

include (CMakeUnit)

cmake_unit_create_source_file_before_build (NAME "Header.h"
                                            PREPEND_CONTENTS
                                            "int foo@SEMICOLON@")

assert_file_has_line_matching ("${CMAKE_CURRENT_SOURCE_DIR}/Header.h"
                               "^.*ifndef HEADER_H")
assert_file_has_line_matching ("${CMAKE_CURRENT_SOURCE_DIR}/Header.h"
                               "^.*define HEADER_H")
assert_file_has_line_matching ("${CMAKE_CURRENT_SOURCE_DIR}/Header.h"
                               "^.*endif")
