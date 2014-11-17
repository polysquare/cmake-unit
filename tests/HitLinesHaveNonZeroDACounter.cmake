# /tests/HitLinesHaveNonZeroDACounter.cmake
#
# All hit-and-executable lines have a DA counter of > 0.
#
# See LICENCE.md for Copyright information

include (CMakeUnit)
include (RunCMakeTraceToLCovOnCoveredFileCommon)

assert_file_has_line_matching ("${LCOV_OUTPUT}" "^DA:2,1$")
assert_file_has_line_matching ("${LCOV_OUTPUT}" "^DA:5,1$")
assert_file_has_line_matching ("${LCOV_OUTPUT}" "^DA:11,1$")
assert_file_has_line_matching ("${LCOV_OUTPUT}" "^DA:13,1$")
assert_file_has_line_matching ("${LCOV_OUTPUT}" "^DA:14,1$")
assert_file_has_line_matching ("${LCOV_OUTPUT}" "^DA:16,1$")
assert_file_has_line_matching ("${LCOV_OUTPUT}" "^DA:21,1$")
assert_file_has_line_matching ("${LCOV_OUTPUT}" "^DA:24,1$")
assert_file_has_line_matching ("${LCOV_OUTPUT}" "^DA:26,1$")
assert_file_has_line_matching ("${LCOV_OUTPUT}" "^DA:30,1$")
