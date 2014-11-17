# /tests/ExportImportCfgIntDirVerify.cmake
#
# Uses cmake_unit_import_cfg_int_dir and cross-checks that against an
# exported target from the external project's location. If the path
# ${CMAKE_CURRENT_BINARY_DIR}/ExternalProject/build/${CFG_INT_DIR}
# is the prefix to the exported target's LOCATION property then that
# means that the CFG_INT_DIR was successful stored on this generator.
#
# See LICENCE.md for Copyright information

include (CMakeUnit)

set (EXTERNAL_PROJECT_BINARY_DIR
     "${CMAKE_CURRENT_BINARY_DIR}/ExternalProject/build")
set (EXTERNAL_PROJECT_EXPORTS
     "${EXTERNAL_PROJECT_BINARY_DIR}/exports.cmake")

cmake_unit_import_cfg_int_dir (${CMAKE_CURRENT_BINARY_DIR}/CfgIntDir.txt
                               CFG_INT_DIR)
cmake_unit_get_target_location_from_exports ("${EXTERNAL_PROJECT_EXPORTS}"
                                             executable
                                             EXECUTABLE_LOCATION)


set (EXPECTED_EXECUTABLE_LOCATION_HEADER
     "${EXTERNAL_PROJECT_BINARY_DIR}/${CFG_INT_DIR}")
# Normalize path
get_filename_component (EXPECTED_EXECUTABLE_LOCATION_HEADER
                        "${EXPECTED_EXECUTABLE_LOCATION_HEADER}"
                        ABSOLUTE)
string (LENGTH "${EXPECTED_EXECUTABLE_LOCATION_HEADER}"
        EXPECTED_EXECUTABLE_LOCATION_HEADER_LENGTH)
string (SUBSTRING "${EXECUTABLE_LOCATION}"
        0 ${EXPECTED_EXECUTABLE_LOCATION_HEADER_LENGTH}
        EXECUTABLE_LOCATION_HEADER)

assert_variable_is (EXECUTABLE_LOCATION_HEADER STRING EQUAL
                    "${EXPECTED_EXECUTABLE_LOCATION_HEADER}")
