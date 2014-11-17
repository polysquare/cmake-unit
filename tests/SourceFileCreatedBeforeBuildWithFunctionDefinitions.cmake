# /tests/SourceFileCreatedBeforeBuildWithFunctionDefinitions.cmake
#
# Check that a source file by the name Source.cpp was created in
# ${CMAKE_CURRENT_SOURCE_DIR} with a definition like
# int custom_function ()\n{\n    return 1;\n} when we call
# cmake_unit_create_source_file_before_build with FUNCTIONS custom_function
#
# See LICENCE.md for Copyright information

include (CMakeUnit)

cmake_unit_create_source_file_before_build (FUNCTIONS custom_function)

assert_file_has_line_matching ("${CMAKE_CURRENT_SOURCE_DIR}/Source.cpp"
                               "^.*return 0.*$")
