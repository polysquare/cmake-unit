# /tests/SourceFileCreatedBeforeBuildHasPrependedContents.cmake
#
# Check that a source file by the name Source.cpp was created in
# ${CMAKE_CURRENT_SOURCE_DIR} with specified prepended contents
# (after defines and includes)
#
# See LICENCE.md for Copyright information.

include (CMakeUnit)

set (PREPEND_CONTENTS_INPUT "static int i@SEMICOLON@")
cmake_unit_create_source_file_before_build (PREPEND_CONTENTS
                                            "${PREPEND_CONTENTS_INPUT}")

assert_file_has_line_matching ("${CMAKE_CURRENT_SOURCE_DIR}/Source.cpp"
                               "^static int i.$")
