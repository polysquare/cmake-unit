# /tests/CMakeTestFilesRecordedInTracefileAcrossTestsVerify.cmake
#
# Check that when CMAKE_UNIT_LOG_COVERAGE was on we created a file
# called SampleTests.trace in CMAKE_CURRENT_BINARY_DIR
# and that file contains the following:
#
# ^.*IncludedScript.cmake\(1\).*$
# ^.*FirstTestSpecificScript.cmake\(1\).*$
# ^.*SecondTestSpecificScript.cmake\(1\).*$
# ^.*FirstTest\(1\).*$
# ^.*FirstTest\(2\).*$
# ^.*FirstTest\(3\).*$
# ^.*SecondTest\(1\).*$
# ^.*SecondTest\(2\).*$
# ^.*SecondTest\(3\).*$
#
# It should NOT have any line matching ^.*ExcludedScript.cmake.*$
#
# See LICENCE.md for Copyright information

include (CMakeUnit)

set (COVERAGE_TRACEFILE "${CMAKE_CURRENT_BINARY_DIR}/SampleTests.trace")
cmake_unit_assert_file_exists ("${COVERAGE_TRACEFILE}")

# IncludedScript.cmake
cmake_unit_assert_file_has_line_matching ("${COVERAGE_TRACEFILE}"
                                          "^.*IncludedScript.cmake.1.*$")

# FirstTestSpecificScript.cmake
cmake_unit_assert_file_has_line_matching ("${COVERAGE_TRACEFILE}"
                                          "^.*FirstTestSpecific.cmake.1.*$")

# SecondTestSpecificScript.cmake
cmake_unit_assert_file_has_line_matching ("${COVERAGE_TRACEFILE}"
                                          "^.*SecondTestSpecific.cmake.1.*$")

# Don't include the tests themselves
cmake_unit_assert_file_does_not_have_line_matching ("${COVERAGE_TRACEFILE}"
                                                    "^.*FirstTest.cmake.*$")
cmake_unit_assert_file_does_not_have_line_matching ("${COVERAGE_TRACEFILE}"
                                                    "^.*SecondTest.cmake.*$")

# Does not include ExcludedScript.cmake
cmake_unit_assert_file_does_not_have_line_matching ("${COVERAGE_TRACEFILE}"
                                                    "^.*Excluded.cmake.*$")
