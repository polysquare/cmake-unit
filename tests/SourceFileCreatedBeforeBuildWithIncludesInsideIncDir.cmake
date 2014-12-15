# /tests/SourceFileCreatedBeforeBuildWithIncludesInsideIncDir.cmake
#
# Check that a source file by the name Source.cpp was created in
# ${CMAKE_CURRENT_SOURCE_DIR} with #include <include/my_include.h> when we call
# cmake_unit_create_source_file_before_build with
# INCLUDES ${CMAKE_CURRENT_SOURCE_DIR}/include/my_include.h
# and INCLUDE_DIRECTORIES ${CMAKE_CURRENT_SOURCE_DIR}
#
# See LICENCE.md for Copyright information

include (CMakeUnit)

set (INCLUDE_DIRECTORY "${CMAKE_CURRENT_SOURCE_DIR}")
set (MY_INCLUDE "${INCLUDE_DIRECTORY}/include/my_include.h")
cmake_unit_create_source_file_before_build (INCLUDES
                                            "${MY_INCLUDE}"
                                            INCLUDE_DIRECTORIES
                                            "${INCLUDE_DIRECTORY}")

set (SOURCE_FILE "${CMAKE_CURRENT_SOURCE_DIR}/Source.cpp")
cmake_unit_assert_file_has_line_matching ("${SOURCE_FILE}"
                                          "^.include <include/my_include.h>$")
