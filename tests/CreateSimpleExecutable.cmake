# /tests/CreateSimpleExecutable.cmake
#
# Creates a simple executable named "executable" by using
# cmake_unit_create_simple_executable
#
# See LICENCE.md for Copyright information

include (CMakeUnit)

cmake_unit_create_simple_executable (executable)
export (TARGETS executable FILE ${CMAKE_CURRENT_BINARY_DIR}/exports.cmake)
