# /tests/CreateSimpleLibrary.cmake
#
# Creates a simple executable named "executable" by using
# cmake_unit_create_simple_executable and links to a simple library
# named "library" created by using cmake_unit_create_simple_library
#
# See LICENCE.md for Copyright information

include (CMakeUnit)

cmake_unit_create_simple_library (library SHARED FUNCTIONS function)
cmake_unit_create_simple_executable (executable)
target_link_libraries (executable library)
