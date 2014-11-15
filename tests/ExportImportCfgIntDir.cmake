# /tests/ExportImportCfgIntDir.cmake
#
# Create an external project with an exported library and use
# cmake_export_cfg_int_dir in that external project to write out
# CMAKE_CFG_INT_DIR to CfgIntDirValue.txt in its BINARY_DIR
#
# See LICENCE.md for Copyright information

include (ExternalProject)
include (CMakeUnit)
include (CMakeUnitRunner)

set (EXTERNAL_PROJECT_SOURCE_DIR "${CMAKE_CURRENT_BINARY_DIR}/ExternalProject")
set (EXTERNAL_PROJECT_BINARY_DIR "${EXTERNAL_PROJECT_SOURCE_DIR}/build")
set (EXTERNAL_PROJECT_CMAKELISTS_TXT
     "${EXTERNAL_PROJECT_SOURCE_DIR}/CMakeLists.txt")
string (REPLACE ";" " " STRINGIFIED_CMAKE_MODULE_PATH
        "${CMAKE_MODULE_PATH}")
set (EXTERNAL_PROJECT_CMAKELISTS_TXT_CONTENT
     "set (CMAKE_MODULE_PATH ${STRINGIFIED_CMAKE_MODULE_PATH})\n"
     "include (CMakeUnit)\n"
     "cmake_unit_create_simple_executable (executable)\n"
     "export (TARGETS executable\n"
     "        FILE \${CMAKE_CURRENT_BINARY_DIR}/exports.cmake)\n"
     "set (CFG_INT_DIR_LOCATION ${CMAKE_CURRENT_BINARY_DIR}/CfgIntDir.txt)\n"
     "cmake_unit_export_cfg_int_dir (\${CFG_INT_DIR_LOCATION})\n")

file (MAKE_DIRECTORY "${EXTERNAL_PROJECT_SOURCE_DIR}")
file (MAKE_DIRECTORY "${EXTERNAL_PROJECT_BINARY_DIR}")
file (WRITE "${EXTERNAL_PROJECT_CMAKELISTS_TXT}"
      ${EXTERNAL_PROJECT_CMAKELISTS_TXT_CONTENT})

externalproject_add (ExternalProject
                     SOURCE_DIR "${EXTERNAL_PROJECT_SOURCE_DIR}"
                     BINARY_DIR "${EXTERNAL_PROJECT_BINARY_DIR}"
                     INSTALL_COMMAND "")

add_custom_target (target ALL DEPENDS ExternalProject)
