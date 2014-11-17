# /tests/RunCMakeTraceToLCovOnCoveredFileCommon.cmake
#
# A script shared between tests to copy in a common "covered file"
# and run CMakeTraceToLCov on it.
#
# See LICENCE.md for Copyright information

set (FILE_FOR_COVERAGE_LOCAL_PATH
     "${CMAKE_CURRENT_SOURCE_DIR}/FileForCoverage.cmake")
file (READ "${FILE_FOR_COVERAGE_PATH}" FILE_FOR_COVERAGE_CONTENTS)
file (WRITE "${FILE_FOR_COVERAGE_LOCAL_PATH}" "${FILE_FOR_COVERAGE_CONTENTS}")

set (UNEXECUTED_FILE_FOR_COVERAGE_LOCAL_PATH
     "${CMAKE_CURRENT_SOURCE_DIR}/UnexecutedFileForCoverage.cmake")
file (READ "${UNEXECUTED_FILE_FOR_COVERAGE_PATH}"
      UNEXECUTED_FILE_FOR_COVERAGE_CONTENTS)
file (WRITE
      "${UNEXECUTED_FILE_FOR_COVERAGE_LOCAL_PATH}"
      "${UNEXECUTED_FILE_FOR_COVERAGE_CONTENTS}")

set (MOCK_TRACEFILE_OUTPUT "${CMAKE_CURRENT_BINARY_DIR}/MockTracefile.trace")
configure_file ("${MOCK_TRACEFILE_INPUT}"
                "${MOCK_TRACEFILE_OUTPUT}"
                @ONLY)

set (TRACEFILE "${MOCK_TRACEFILE_OUTPUT}" CACHE STRING "" FORCE)
set (LCOV_OUTPUT "${CMAKE_CURRENT_BINARY_DIR}/mock_test_coverage.lcov"
     CACHE STRING "" FORCE)

include (CMakeTraceToLCov)
