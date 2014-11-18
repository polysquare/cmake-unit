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

set (GENERATED_FILE "${CMAKE_CURRENT_BINARY_DIR}/Generated.cpp")

file (WRITE "${TEST_FILE}"
      "include (CMakeUnit)\n"
      "add_custom_command (OUTPUT\n"
      "                    \"${GENERATED_FILE}\"\n"
      # The two commands will actually be to generate a
      # file called FirstCommand.cpp, and then another
      # command to generate SecondCommand.cpp
      "                    COMMAND\n"
      "                    \"${CMAKE_COMMAND}\" -E touch\n"
      "                    \"${CMAKE_CURRENT_BINARY_DIR}/FirstCommand.cpp\"\n"
      "                    COMMAND\n"
      "                    \"${CMAKE_COMMAND}\" -E touch\n"
      "                    \"${CMAKE_CURRENT_BINARY_DIR}/SecondCommand.cpp\")\n"
      "add_custom_target (custom_target ALL\n"
      "                   SOURCES \"${GENERATED_FILE}\")\n")
file (WRITE "${TEST_VERIFY_FILE}" "")

bootstrap_cmake_unit (VARIABLES CMAKE_MODULE_PATH)
add_cmake_build_test (${TEST_NAME} ${TEST_NAME_VERIFY})
