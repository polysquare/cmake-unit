# /tests/SourceFileCreatedBeforeBuildWithFunctionDecls.cmake
#
# Check that a source file by the name Source.cpp was created in
# ${CMAKE_CURRENT_SOURCE_DIR} with a declaration like
# int custom_function (); when we call
# cmake_unit_create_source_file_before_build with FUNCTIONS custom_function
#
# See LICENCE.md for Copyright information

include (CMakeUnit)

cmake_unit_create_source_file_before_build (FUNCTIONS custom_function)

set (SOURCE_FILE "${CMAKE_CURRENT_SOURCE_DIR}/Source.cpp")
cmake_unit_assert_file_has_line_matching ("${SOURCE_FILE}"
                                          "^int custom_function ...$")
