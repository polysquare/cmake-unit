# /tests/CMakeLists.txt
# Main entry point for the common-universal-cmake tests.
#
# See LICENCE.md for Copyright information

if (POLICY CMP0025)

    cmake_policy (SET CMP0025 NEW)

endif (POLICY CMP0025)

project (CMakeUnitTests)
cmake_minimum_required (VERSION 2.8)

# We assume that it is one-above us
set (CMAKE_UNIT_RELATIVE_CMAKE_DIRECTORY
     ${CMAKE_CURRENT_SOURCE_DIR}/..)
get_filename_component (CMAKE_UNIT_DIRECTORY
                        ${CMAKE_UNIT_RELATIVE_CMAKE_DIRECTORY}
                        ABSOLUTE)

set (CMAKE_MODULE_PATH
     ${CMAKE_UNIT_DIRECTORY}
     ${CMAKE_CURRENT_SOURCE_DIR})

# Set up variables to forward
set (MOCK_TRACEFILE_INPUT
     "${CMAKE_CURRENT_SOURCE_DIR}/TestProjectMockTracefile.trace.in")
set (FILE_FOR_COVERAGE_PATH "${CMAKE_CURRENT_SOURCE_DIR}/FileForCoverage.cmake")
set (UNEXECUTED_FILE_FOR_COVERAGE_PATH
     "${CMAKE_CURRENT_SOURCE_DIR}/UnexecutedFileForCoverage.cmake")

include (CMakeUnitRunner)

bootstrap_cmake_unit (VARIABLES
                      CMAKE_MODULE_PATH
                      MOCK_TRACEFILE_INPUT
                      FILE_FOR_COVERAGE_PATH
                      UNEXECUTED_FILE_FOR_COVERAGE_PATH
                      COVERAGE_FILES
                      "${CMAKE_UNIT_DIRECTORY}/CMakeUnitRunner.cmake"
                      "${CMAKE_UNIT_DIRECTORY}/CMakeTraceToLCov.cmake"
                      "${CMAKE_UNIT_DIRECTORY}/CMakeUnit.cmake")

add_cmake_test (TargetExists)
add_cmake_test (StringContains)
add_cmake_test (VariableIs)
add_cmake_test (VariableIsEmpty)
add_cmake_test (CommandExecutesWithSuccess)
add_cmake_test (TargetIsLinkedTo)
add_cmake_test (ItemHasPropertyWithValue)
add_cmake_test (ItemHasPropertyWithValueEmpty)
add_cmake_test (ItemHasPropertyWithValueGlobal)
add_cmake_test (ItemHasPropertyContainingValue)
add_cmake_test (ItemHasPropertyContainingValueEmpty)
add_cmake_test (ItemHasPropertyContainingValueGlobal)
add_cmake_test (FileExists)
add_cmake_test (FileContainsSubstring)
add_cmake_test (FileHasLineMatching)
add_cmake_test (ListContainsValue)
add_cmake_test (ListContainsValueEmpty)

# Tests for CMakeUnitRunner
add_cmake_test (CoverageFileClobberedOnBootstrap)
add_cmake_test (InitialCacheWrittenAfterTestAdded)
add_cmake_test (InitialCacheContainsForwardedVariables)
add_cmake_test (DriverScriptWrittenAfterTestAdded)

add_cmake_build_test (CMakeTestAddedWhereSetupScriptExists
                      CMakeTestAddedWhereSetupScriptExistsVerify)
add_cmake_build_test (CMakeTestNotAddedWhenSetupScriptDoesntExist
                      CMakeTestNotAddedWhenSetupScriptDoesntExistVerify
                      ALLOW_CONFIGURE_FAIL)
add_cmake_build_test (CMakeBuildTestAddedWhereVerifyScriptExists
                      CMakeBuildTestAddedWhereVerifyScriptExistsVerify)
add_cmake_build_test (CMakeBuildTestNotAddedWhenVerifyScriptDoesntExist
                      CMakeBuildTestNotAddedWhenVerifyScriptDoesntExistVerify
                      ALLOW_CONFIGURE_FAIL)
add_cmake_build_test (CMakeBuildTestErrorOnConfigureFail
                      CMakeBuildTestErrorOnConfigureFailVerify
                      ALLOW_TEST_FAIL)
add_cmake_build_test (CMakeBuildTestNoErrorOnConfigureFailWhereFailAllowed
                      CMakeBuildTestNoErrorOnConfigureFailWhereFailAllowedVerify)
add_cmake_build_test (CMakeBuildTestErrorOnBuildFail
                      CMakeBuildTestErrorOnBuildFailVerify
                      ALLOW_TEST_FAIL)
add_cmake_build_test (CMakeBuildTestErrorOnTestFail
                      CMakeBuildTestErrorOnTestFailVerify
                      ALLOW_TEST_FAIL)
add_cmake_build_test (CMakeBuildTestNoErrorOnTestFailWhereFailAllowed
                      CMakeBuildTestNoErrorOnTestFailWhereFailAllowedVerify
                      ALLOW_TEST_FAIL)
add_cmake_build_test (CMakeBuildTestErrorOnVerifyFail
                      CMakeBuildTestErrorOnVerifyFailVerify
                      ALLOW_TEST_FAIL)

add_cmake_build_test (CMakeBuildTestBuildStepNotRunIfConfigureCanFail
                      CMakeBuildTestBuildStepNotRunIfConfigureCanFailVerify)
add_cmake_build_test (CMakeBuildTestTestStepNotRunIfBuildCanFail
                      CMakeBuildTestTestStepNotRunIfBuildCanFailVerify)

add_cmake_build_test (CMakeBuildTestWithCustomTarget
                      CMakeBuildTestWithCustomTargetVerify)
add_cmake_build_test (CMakeBuildTestCleanStepAlwaysRuns
                      CMakeBuildTestCleanStepAlwaysRunsVerify)
add_cmake_build_test (CMakeBuildTestCleanStepNotRunOnNoClean
                      CMakeBuildTestCleanStepNotRunOnNoCleanVerify)

add_cmake_build_test (CMakeBuildTestWarningsAreErrors
                      CMakeBuildTestWarningsAreErrorsVerify
                      ALLOW_TEST_FAIL)
add_cmake_build_test (CMakeBuildTestWarningsNotErrorsWhereWErrorDisabled
                      CMakeBuildTestWarningsNotErrorsWhereWErrorDisabledVerify)

add_cmake_build_test (CMakeTestFilesRecordedInTracefileAcrossTests
                      CMakeTestFilesRecordedInTracefileAcrossTestsVerify)

add_cmake_build_test (CMakeTestsHaveVerboseOutput
                      CMakeTestsHaveVerboseOutputVerify)

# Tests for CMakeTraceToLCov
add_cmake_test (LinesStartingWithCommentNotExecutable)
add_cmake_test (LinesWithNoContentNotExecutable)
add_cmake_test (LinesStartingWithEndNotExecutable)
add_cmake_test (LinesUntilCloseBraceNotExecutable)
add_cmake_test (LinesUntilCloseBraceWithInterleavedCommentsNotExecutable)
add_cmake_test (SemicolonsDontBreakLines)
add_cmake_test (SlashNDoesntBreakLines)
add_cmake_test (AllFilesSpecifiedInTraceFileHaveCoverage)
add_cmake_test (OtherLinesExecutable)
add_cmake_test (HitLinesHaveNonZeroDACounter)
add_cmake_test (MissedLinesHaveNonZeroDACounter)
