# /tests/CMakeTestsHaveVerboseOutput.cmake
#
# Adds a test which adds a custom target with a command
# to the ALL target.
#
# See LICENCE.md for Copyright information

include (CMakeUnit)
include (CMakeUnitRunner)

set (TEST_NAME "SampleTest")
set (TEST_NAME_VERIFY "SampleTestVerify")
set (TEST_FILE "${CMAKE_CURRENT_SOURCE_DIR}/${TEST_NAME}.cmake")
set (TEST_VERIFY_FILE "${CMAKE_CURRENT_SOURCE_DIR}/${TEST_NAME_VERIFY}.cmake")

set (SOURCE_FILE "${CMAKE_CURRENT_BINARY_DIR}/Source.cpp")
set (GENERATED_FILE "${CMAKE_CURRENT_BINARY_DIR}/Generated.cpp")

file (WRITE "${SOURCE_FILE}" "")
file (WRITE "${TEST_FILE}"
      "include (CMakeUnit)\n"
      "add_custom_target (faux_dependency)\n"
      "add_custom_command (OUTPUT\n"
      "                    \"${GENERATED_FILE}\"\n"
      "                    COMMAND\n"
      "                    \"${CMAKE_COMMAND}\" -E touch\n"
      "                    \"${GENERATED_FILE}\"\n"
      "                    DEPENDS\n"
      "                    faux_dependency\n"
      "                    COMMENT\n"
      "                    \"Generating File Comment\n\")\n"
      "add_custom_target (custom_target ALL\n"
      "                   SOURCES \"${GENERATED_FILE}\")\n")
file (WRITE "${TEST_VERIFY_FILE}" "")

bootstrap_cmake_unit (VARIABLES CMAKE_MODULE_PATH)
add_cmake_build_test (${TEST_NAME} ${TEST_NAME_VERIFY})
