# /tests/CoverageFileClobberedOnBootstrap.cmake
#
# Check that ${CMAKE_PROJECT_NAME}.trace (in this case, TestProject.trace)
# is overwritten with nothing when bootstrap_cmake_unit is called
#
# See LICENCE.md for Copyright information

project (TestProject)
set (CMAKE_UNIT_LOG_COVERAGE ON CACHE BOOL "" FORCE)

include (CMakeUnit)
include (CMakeUnitRunner)

set (TRACE_FILE "${CMAKE_CURRENT_BINARY_DIR}/TestProject.trace")
file (WRITE "${TRACE_FILE}" "Non-empty contents")

bootstrap_cmake_unit ()

assert_file_exists ("${CMAKE_CURRENT_BINARY_DIR}/TestProject.trace")
file (READ "${CMAKE_CURRENT_BINARY_DIR}/TestProject.trace" TRACE_FILE_CONTENTS)
assert_variable_is (TRACE_FILE_CONTENTS STRING EQUAL "")
