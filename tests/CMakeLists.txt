# /tests/CMakeLists.txt
# Main entry point for the common-universal-cmake tests.
#
# See LICENCE.md for Copyright information

if (POLICY CMP0025)

    cmake_policy (SET CMP0025 NEW)

endif (POLICY CMP0025)

project (CMakeUnitTests)
cmake_minimum_required (VERSION 2.8)

# We assume that it is one-above us
set (CMAKE_UNIT_RELATIVE_CMAKE_DIRECTORY
     ${CMAKE_CURRENT_SOURCE_DIR}/..)
get_filename_component (CMAKE_UNIT_DIRECTORY
                        ${CMAKE_UNIT_RELATIVE_CMAKE_DIRECTORY}
                        ABSOLUTE)

set (CMAKE_MODULE_PATH
     ${CMAKE_UNIT_DIRECTORY}
     ${CMAKE_MODULE_PATH})

foreach (PATH ${CMAKE_MODULE_PATH})
     set (CMAKE_UNIT_INITIAL_CACHE_CONTENTS
          "${CMAKE_UNIT_INITIAL_CACHE_CONTENTS}\n"
          "set (CMAKE_MODULE_PATH ${PATH} \${CMAKE_MODULE_PATH}\n"
          "     CACHE STRING \"\" FORCE)\n")
endforeach ()

include (CMakeUnitRunner)

bootstrap_cmake_unit (INITIAL_CACHE_CONTENTS
                      CMAKE_UNIT_INITIAL_CACHE_CONTENTS)
add_cmake_test (TargetExists)
add_cmake_test (StringContains)
add_cmake_test (VariableIs)
add_cmake_test (CommandExecutesWithSuccess)
add_cmake_test (TargetIsLinkedTo)
add_cmake_test (ItemHasPropertyWithValue)
add_cmake_test (ItemHasPropertyWithValueGlobal)
add_cmake_test (ItemHasPropertyContainingValue)
add_cmake_test (ItemHasPropertyContainingValueGlobal)
add_cmake_test (FileExists)
add_cmake_test (FileContainsSubstring)
add_cmake_test (FileHasLineMatching)
add_cmake_test (ListContainsValue)