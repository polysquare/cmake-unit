# /tests/GeneratedAndCreatedSourceFilesEqual.cmake
#
# Check that source files created and generated with the same options
# are completely equal
#
# See LICENCE.md for Copyright information

include (CMakeUnit)

set (GENERATE_OPTIONS
     NAME "CustomSource.cpp"
     INCLUDES "custom_include.h" "other_include.h"
     DEFINES "CUSTOM_DEFINITION" "OTHER_DEFINITION"
     FUNCTIONS "function_one" "function_two"
     PREPEND_CONTENTS "static int integer_variable@SEMICOLON@")

cmake_unit_generate_source_file_during_build (GENERATED_DURING_TARGET
                                              ${GENERATE_OPTIONS})
cmake_unit_create_source_file_before_build (${GENERATE_OPTIONS})
