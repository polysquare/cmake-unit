# /tests/CoverageFileClobberedOnBootstrap.cmake
#
# Check that ${CMAKE_PROJECT_NAME}.trace (in this case, TestProject.trace)
# is overwritten with nothing when cmake_unit_init is called
#
# See LICENCE.md for Copyright information

project (TestProject)
set (CMAKE_UNIT_LOG_COVERAGE ON CACHE BOOL "" FORCE)

include (CMakeUnit)
include (CMakeUnitRunner)

set (TRACE_FILE "${CMAKE_CURRENT_BINARY_DIR}/TestProject.trace")
file (WRITE "${TRACE_FILE}" "Non-empty contents")

cmake_unit_init ()

cmake_unit_assert_file_exists ("${CMAKE_CURRENT_BINARY_DIR}/TestProject.trace")
file (READ "${CMAKE_CURRENT_BINARY_DIR}/TestProject.trace" TRACE_FILE_CONTENTS)
cmake_unit_assert_variable_is (TRACE_FILE_CONTENTS STRING EQUAL "")
