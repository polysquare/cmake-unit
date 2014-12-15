# /tests/CMakeLists.txt
#
# Main entry point for the common-universal-cmake tests.
#
# See LICENCE.md for Copyright information

if (POLICY CMP0025)

    cmake_policy (SET CMP0025 NEW)

endif ()

if (POLICY CMP0056)

    cmake_policy (SET CMP0056 NEW)

endif (POLICY CMP0056)

project (CMakeUnitTests)
cmake_minimum_required (VERSION 2.8)

# We assume that it is one-above us
set (CMAKE_UNIT_RELATIVE_CMAKE_DIRECTORY
     "${CMAKE_CURRENT_SOURCE_DIR}/..")
get_filename_component (CMAKE_UNIT_DIRECTORY
                        "${CMAKE_UNIT_RELATIVE_CMAKE_DIRECTORY}"
                        ABSOLUTE)

set (CMAKE_MODULE_PATH
     "${CMAKE_UNIT_DIRECTORY}"
     "${CMAKE_CURRENT_SOURCE_DIR}")

# Set up variables to forward
set (MOCK_TRACEFILE_INPUT
     "${CMAKE_CURRENT_SOURCE_DIR}/TestProjectMockTracefile.trace.in")
set (FILE_FOR_COVERAGE_PATH "${CMAKE_CURRENT_SOURCE_DIR}/FileForCoverage.cmake")
set (UNEXECUTED_FILE_FOR_COVERAGE_PATH
     "${CMAKE_CURRENT_SOURCE_DIR}/UnexecutedFileForCoverage.cmake")

include (CMakeUnitRunner)

cmake_unit_init (VARIABLES
                 CMAKE_MODULE_PATH
                 MOCK_TRACEFILE_INPUT
                 FILE_FOR_COVERAGE_PATH
                 UNEXECUTED_FILE_FOR_COVERAGE_PATH
                 COVERAGE_FILES
                 "${CMAKE_UNIT_DIRECTORY}/CMakeUnitRunner.cmake"
                 "${CMAKE_UNIT_DIRECTORY}/CMakeTraceToLCov.cmake"
                 "${CMAKE_UNIT_DIRECTORY}/CMakeUnit.cmake")

cmake_unit_config_test (TargetExists)
cmake_unit_config_test (StringContains)
cmake_unit_config_test (VariableIs)
cmake_unit_config_test (VariableIsEmpty)
cmake_unit_config_test (CommandExecutesWithSuccess)
cmake_unit_config_test (TargetIsLinkedTo)
cmake_unit_config_test (ItemHasPropertyWithValue)
cmake_unit_config_test (ItemHasPropertyWithValueEmpty)
cmake_unit_config_test (ItemHasPropertyWithValueGlobal)
cmake_unit_config_test (ItemHasPropertyContainingValue)
cmake_unit_config_test (ItemHasPropertyContainingValueEmpty)
cmake_unit_config_test (ItemHasPropertyContainingValueGlobal)
cmake_unit_config_test (FileExists)
cmake_unit_config_test (FileContainsSubstring)
cmake_unit_config_test (FileHasLineMatching)
cmake_unit_config_test (ListContainsValue)
cmake_unit_config_test (ListContainsValueEmpty)

# Tests for CMakeUnitRunner
cmake_unit_config_test (CoverageFileClobberedOnBootstrap)
cmake_unit_config_test (InitialCacheWrittenAfterTestAdded)
cmake_unit_config_test (InitialCacheContainsForwardedVariables)
cmake_unit_config_test (DriverScriptWrittenAfterTestAdded)

# Test adding CMake test and error behaviour
cmake_unit_build_test (CMakeTestAddedWhereSetupScriptExists
                       CMakeTestAddedWhereSetupScriptExistsVerify)
cmake_unit_build_test (CMakeTestNotAddedWhenSetupScriptDoesntExist
                       CMakeTestNotAddedWhenSetupScriptDoesntExistVerify
                       ALLOW_CONFIGURE_FAIL)
cmake_unit_build_test (CMakeBuildTestAddedWhereVerifyScriptExists
                       CMakeBuildTestAddedWhereVerifyScriptExistsVerify)
cmake_unit_build_test (CMakeBuildTestNotAddedWhenVerifyScriptDoesntExist
                       CMakeBuildTestNotAddedWhenVerifyScriptDoesntExistVerify
                       ALLOW_CONFIGURE_FAIL)
cmake_unit_build_test (CMakeBuildTestErrorOnConfigureFail
                       CMakeBuildTestErrorOnConfigureFailVerify
                       ALLOW_TEST_FAIL)
cmake_unit_build_test (CMakeBuildTestNoErrorOnConfigureFailIfFailAllowed
                       CMakeBuildTestNoErrorOnConfigureFailIfFailAllowedVerify)
cmake_unit_build_test (CMakeBuildTestErrorOnBuildFail
                       CMakeBuildTestErrorOnBuildFailVerify
                       ALLOW_TEST_FAIL)
cmake_unit_build_test (CMakeBuildTestErrorOnTestFail
                       CMakeBuildTestErrorOnTestFailVerify
                       ALLOW_TEST_FAIL)
cmake_unit_build_test (CMakeBuildTestNoErrorOnTestFailWhereFailAllowed
                       CMakeBuildTestNoErrorOnTestFailWhereFailAllowedVerify
                       ALLOW_TEST_FAIL)
cmake_unit_build_test (CMakeBuildTestErrorOnVerifyFail
                       CMakeBuildTestErrorOnVerifyFailVerify
                       ALLOW_TEST_FAIL)

# Test that certain steps are not run where ALLOW_FAIL is specified
cmake_unit_build_test (CMakeBuildTestBuildStepNotRunIfConfigureCanFail
                       CMakeBuildTestBuildStepNotRunIfConfigureCanFailVerify)
cmake_unit_build_test (CMakeBuildTestTestStepNotRunIfBuildCanFail
                       CMakeBuildTestTestStepNotRunIfBuildCanFailVerify)

# Custom target, clean step
cmake_unit_build_test (CMakeBuildTestWithCustomTarget
                       CMakeBuildTestWithCustomTargetVerify)
cmake_unit_build_test (CMakeBuildTestCleanStepAlwaysRuns
                       CMakeBuildTestCleanStepAlwaysRunsVerify)
cmake_unit_build_test (CMakeBuildTestCleanStepNotRunOnNoClean
                       CMakeBuildTestCleanStepNotRunOnNoCleanVerify)

# Convert warnings to errors
cmake_unit_build_test (CMakeBuildTestWarningsAreErrors
                       CMakeBuildTestWarningsAreErrorsVerify
                       ALLOW_TEST_FAIL)
cmake_unit_build_test (CMakeBuildTestWarningsNotErrorsWhereWErrorDisabled
                       CMakeBuildTestWarningsNotErrorsWhereWErrorDisabledVerify)

# Tracefile recording
cmake_unit_build_test (CMakeTestFilesRecordedInTracefileAcrossTests
                       CMakeTestFilesRecordedInTracefileAcrossTestsVerify)

# Verbose output
cmake_unit_build_test (CMakeTestsHaveVerboseOutput
                       CMakeTestsHaveVerboseOutputVerify)
cmake_unit_build_test (PreserveContentsOfCMakeErrorsInConfigureOutput
                       PreserveContentsOfCMakeErrorsInConfigureOutputVerify)

# Source file and executable generation
cmake_unit_config_test (SourceFileCreatedBeforeBuildExists)
cmake_unit_config_test (SourceFileCreatedBeforeBuildWithCustomName)
cmake_unit_config_test (SourceFileCreatedBeforeBuildWithDefines)
cmake_unit_config_test (SourceFileCreatedBeforeBuildWithIncludes)
cmake_unit_config_test (SourceFileCreatedBeforeBuildWithIncludesInsideIncDir)
cmake_unit_config_test (SourceFileCreatedBeforeBuildHasPrependedContents)
cmake_unit_config_test (SourceFileCreatedBeforeBuildWithFunctionDecls)
cmake_unit_config_test (SourceFileCreatedBeforeBuildWithFunctionDefinitions)
cmake_unit_config_test (SourceFileCreatedBeforeBuildNoFunctionDefsIfHeader)
cmake_unit_config_test (SourceFileCreatedBeforeBuildHeaderGuardsIfHeader)

# Generated source files
cmake_unit_build_test (SourceFileGeneratedDuringBuildExists
                       SourceFileGeneratedDuringBuildExistsVerify)
cmake_unit_build_test (GeneratedAndCreatedSourceFilesEqual
                       GeneratedAndCreatedSourceFilesEqualVerify)

# Superficial Executables and Libraries
cmake_unit_build_test (CreateSimpleExecutable
                       CreateSimpleExecutableVerify)
cmake_unit_build_test (CreateSimpleLibrary
                       CreateSimpleLibraryVerify)

# CFG_INT_DIR
cmake_unit_build_test (ExportImportCfgIntDir
                       ExportImportCfgIntDirVerify)

# Tests for CMakeTraceToLCov
cmake_unit_config_test (LinesStartingWithCommentNotExecutable)
cmake_unit_config_test (LinesWithNoContentNotExecutable)
cmake_unit_config_test (LinesStartingWithEndNotExecutable)
cmake_unit_config_test (LinesUntilCloseBracketNotExecutable)
cmake_unit_config_test (InterleavedCommentsUntilCloseBracketNotExecutable)
cmake_unit_config_test (SemicolonsDontBreakLines)
cmake_unit_config_test (SlashNDoesntBreakLines)
cmake_unit_config_test (AllFilesSpecifiedInTraceFileHaveCoverage)
cmake_unit_config_test (OtherLinesExecutable)
cmake_unit_config_test (HitLinesHaveNonZeroDACounter)
cmake_unit_config_test (MissedLinesHaveNonZeroDACounter)
