# /tests/AllFilesSpecifiedInTraceFileHaveCoverage.cmake
#
# All files, eg
# - FileForCoverage.cmake
# - UnexecutedFileForCoverage.cmake
# Have coverage information
#
# See LICENCE.md for Copyright information

include (CMakeUnit)
include (RunCMakeTraceToLCovOnCoveredFileCommon)

cmake_unit_assert_file_has_line_matching ("${LCOV_OUTPUT}"
                                          "^SF:.*FileForCoverage.*$")
cmake_unit_assert_file_has_line_matching ("${LCOV_OUTPUT}"
                                          "^SF:.*UnexecutedFileForCoverage.*$")
