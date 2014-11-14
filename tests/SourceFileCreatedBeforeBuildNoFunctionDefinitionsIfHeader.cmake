# /tests/SourceFileCreatedBeforeBuildNoFunctionDefinitionsIfHeader.cmake
#
# Check that a source file by the name Header.h was created in
# ${CMAKE_CURRENT_SOURCE_DIR} but does not contain a definition like
# int custom_function ()\n{\n    return 1;\n} when we call
# cmake_unit_create_source_file_before_build with FUNCTIONS custom_function
#
# See LICENCE.md for Copyright information.

include (CMakeUnit)

cmake_unit_create_source_file_before_build (NAME "Header.h"
                                            FUNCTIONS custom_function)

assert_file_does_not_have_line_matching ("${CMAKE_CURRENT_SOURCE_DIR}/Header.h"
                                         "^.*return 1.*$")