# /tests/MissedLinesHaveNonZeroDACounter.cmake
#
# All missed-but-executable lines have a DA counter of zero.
#
# See LICENCE.md for Copyright information

include (CMakeUnit)
include (RunCMakeTraceToLCovOnCoveredFileCommon)

assert_file_has_line_matching ("${LCOV_OUTPUT}" "^DA:32,0$")
