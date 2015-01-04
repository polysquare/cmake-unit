# /tests/CMakeLists.txt
#
# Main entry point for the cmake-unit tests.
#
# See LICENCE.md for Copyright information

if (NOT CMAKE_SCRIPT_MODE_FILE)

    project (CMakeUnitTest NONE)
    set (NEW_POLICIES CMP0025 CMP0056)

    foreach (POLICY ${NEW_POLICIES})

        if (POLICY ${POLICY})

            cmake_policy (SET ${POLICY} NEW)

        endif ()

    endforeach ()

endif ()

cmake_minimum_required (VERSION 2.8)

set (TESTS_LIST_DIR "${CMAKE_CURRENT_LIST_DIR}")

# We assume that it is one-above us
set (CMAKE_UNIT_RELATIVE_CMAKE_DIRECTORY
     "${TESTS_LIST_DIR}/..")
get_filename_component (CMAKE_UNIT_DIRECTORY
                        "${CMAKE_UNIT_RELATIVE_CMAKE_DIRECTORY}"
                        ABSOLUTE)

set (CMAKE_MODULE_PATH
     "${CMAKE_UNIT_DIRECTORY}"
     "${CMAKE_MODULE_PATH}")

# Set up variables to forward
set (MOCK_TRACEFILE_INPUT
     "${TESTS_LIST_DIR}/TestProjectMockTracefile.trace.in")
set (FILE_FOR_COVERAGE_PATH "${TESTS_LIST_DIR}/FileForCoverage.cmake")
set (UNEXECUTED_FILE_FOR_COVERAGE_PATH
     "${TESTS_LIST_DIR}/UnexecutedFileForCoverage.cmake")

include (CMakeUnitRunner)

function (_cmake_unit_test_gen_configure_no_discover RETURN_AUX_CMAKELISTS)

    set (PHASE_TYPES CLEAN
                     INVOKE_CONFIGURE
                     CONFIGURE
                     INVOKE_BUILD
                     INVOKE_TEST
                     VERIFY)

    set (GEN_CONFIGURE_SINGLEVAR_ARGS NAMESPACE NAME)
    set (GEN_CONFIGURE_MULTIVAR_ARGS ${PHASE_TYPES} INIT_OPTIONS)
    cmake_parse_arguments (GEN_CONFIGURE
                           ""
                           "${GEN_CONFIGURE_SINGLEVAR_ARGS}"
                           "${GEN_CONFIGURE_MULTIVAR_ARGS}"
                           ${ARGN})

    set (AUX_CMAKELISTS_FILE_CONTENTS
         "function (${GEN_CONFIGURE_NAMESPACE}_test_${GEN_CONFIGURE_NAME})\n")
    set (TEST_CONFIGURATION "")

    foreach (PHASE_TYPE ${PHASE_TYPES})

        set (PHASE_ARGUMENTS ${GEN_CONFIGURE_${PHASE_TYPE}})

        # Work around a strange cmakelint bug
        set (END "end")

        # We have options for our phase, now parse those options into the
        # script itself and all its other options to be passed as part
        # of the configuraton
        if (PHASE_ARGUMENTS)

            set (PHASE_OPTIONS_MULTIVAR_ARGS SCRIPT OPTIONS)
            cmake_parse_arguments (PHASE
                                   ""
                                   ""
                                   "${PHASE_OPTIONS_MULTIVAR_ARGS}"
                                   ${PHASE_ARGUMENTS})

            set (TEST_ADD_CONFIG "${PHASE_TYPE} ")

            if (PHASE_SCRIPT)

                string (TOLOWER "${PHASE_TYPE}" PHASE_FUNCTION)
                set (PHASE_FUNCTION "gen_${PHASE_FUNCTION}")

                list (APPEND AUX_CMAKELISTS_FILE_CONTENTS
                      "    function (${PHASE_FUNCTION})\n")

                foreach (LINE ${PHASE_SCRIPT})
                    list (APPEND AUX_CMAKELISTS_FILE_CONTENTS
                          "        ${LINE}")
                endforeach ()

                list (APPEND AUX_CMAKELISTS_FILE_CONTENTS
                      "    ${END}function ()\n")

                set (TEST_ADD_CONFIG
                     "${TEST_ADD_CONFIG}COMMAND ${PHASE_FUNCTION} ")

            endif ()

            foreach (OPTION ${PHASE_OPTIONS})

                set (TEST_ADD_CONFIG "${TEST_ADD_CONFIG}${OPTION} ")

            endforeach ()

            set (TEST_CONFIGURATION "${TEST_CONFIGURATION}${TEST_ADD_CONFIG} ")

        endif ()

    endforeach ()

    list (APPEND AUX_CMAKELISTS_FILE_CONTENTS
          "    cmake_unit_configure_test (${TEST_CONFIGURATION})\n"
          "${END}function ()\n")

    set (${RETURN_AUX_CMAKELISTS} ${AUX_CMAKELISTS_FILE_CONTENTS} PARENT_SCOPE)

endfunction ()

function (_cmake_unit_test_gen_discover_from_contents)

    # Overrides variables when including AuxCMakeLists.txt
    set (_CMAKE_UNIT_PHASE PRECONFIGURE)  # NOLINT:unused/var_in_func
    unset (_CMAKE_UNIT_ACTIVE_TEST)  # NOLINT:unused/var_in_func

    set (CMAKE_MODULE_PATH "${CMAKE_UNIT_DIRECTORY}" "${CMAKE_MODULE_PATH}")

    set (GEN_DISCOVER_SINGLEVAR_ARGS NAMESPACE NAME)
    set (GEN_DISCOVER_MULTIVAR_ARGS CONTENTS INIT_OPTIONS)
    cmake_parse_arguments (GEN_DISCOVER
                           ""
                           "${GEN_DISCOVER_SINGLEVAR_ARGS}"
                           "${GEN_DISCOVER_MULTIVAR_ARGS}"
                           ${ARGN})

    # Import previously created contents and then append the final discovery
    # code
    set (AUX_CMAKELISTS_FILE "${CMAKE_CURRENT_BINARY_DIR}/AuxCMakeLists.txt")
    set (AUX_CMAKELISTS_FILE_CONTENTS
         "set (CMAKE_MODULE_PATH \"${CMAKE_UNIT_DIRECTORY}\"\n"
         "                       \"\${CMAKE_MODULE_PATH}\")\n"
         "include (CMakeUnitRunner)\n"
         ${GEN_DISCOVER_CONTENTS})

    set (INIT_OPTIONS "${GEN_DISCOVER_INIT_OPTIONS}")
    string (REPLACE ";" " " INIT_OPTIONS "${INIT_OPTIONS}")

    list (APPEND AUX_CMAKELISTS_FILE_CONTENTS
          "set (NEXT_TESTS)\n"
          "set (CMAKE_UNIT_PARENT_BINARY_DIR\n"
          "     \"${CMAKE_CURRENT_BINARY_DIR}\")\n"
          "cmake_unit_init (NAMESPACE \"${GEN_DISCOVER_NAMESPACE}\"\n"
          "                 ${INIT_OPTIONS})\n")

    file (WRITE "${AUX_CMAKELISTS_FILE}"
          ${AUX_CMAKELISTS_FILE_CONTENTS})

    include ("${AUX_CMAKELISTS_FILE}")

endfunction ()

function (_cmake_unit_test_gen_configure)

    _cmake_unit_test_gen_configure_no_discover (CONTENTS ${ARGN})
    _cmake_unit_test_gen_discover_from_contents (CONTENTS ${CONTENTS} ${ARGN})

endfunction ()

# Check that where we call cmake_unit_configure_test and pass
# a CONFIGURE and VERIFY step to it, that a test is added successfully.
function (cmake_unit_test_cmake_test_added_where_setup_script_exists)

    function (_cmake_unit_configure)

        _cmake_unit_test_gen_configure (NAMESPACE sample
                                        NAME one)

    endfunction ()

    function (_cmake_unit_verify)

        cmake_unit_get_log_for (INVOKE_TEST OUTPUT TEST_OUTPUT)
        cmake_unit_assert_file_has_line_matching ("${TEST_OUTPUT}"
                                                  "^.*Start.*sample_test_one.*$")

    endfunction ()

    cmake_unit_configure_test (CONFIGURE COMMAND _cmake_unit_configure
                               VERIFY COMMAND _cmake_unit_verify)

endfunction ()

# Check that where we have TestName.cmake in CMAKE_CURRENT_SOURCE_DIR
# that calling cmake_unit_configure_test actually adds a test and that the build
# output indicates that we've built, tested and verified SampleTest too
function (cmake_unit_test_cmake_build_test_added_where_verify_script_exists)

    function (_cmake_unit_configure)

        _cmake_unit_test_gen_configure (NAMESPACE sample
                                        NAME one
                                        VERIFY SCRIPT
                                               "message (STATUS \"Ran\")\n")

    endfunction ()

    function (_cmake_unit_verify)

        cmake_unit_get_log_for (INVOKE_TEST OUTPUT TEST_OUTPUT)
        cmake_unit_escape_string ("${CMAKE_COMMAND}" ESC_CMAKE_COMMAND)
        cmake_unit_escape_string ("${CMAKE_CTEST_COMMAND}" ESC_CTEST_COMMAND)

        cmake_unit_assert_file_has_line_matching ("${TEST_OUTPUT}"
                                                  "^.*Start.*sample_test_one.*$")
        set (CMAKE_BUILD_REGEX "^.*${ESC_CMAKE_COMMAND} --build.*$")
        cmake_unit_assert_file_has_line_matching ("${TEST_OUTPUT}"
                                                  "${CMAKE_BUILD_REGEX}")
        set (CMAKE_TEST_REGEX "^.*${ESC_CMAKE_TEST_COMMAND}.*$")
        cmake_unit_assert_file_has_line_matching ("${TEST_OUTPUT}"
                                                  "${CMAKE_TEST_REGEX}")
        cmake_unit_assert_file_has_line_matching ("${TEST_OUTPUT}" "^.*Ran.*$")

    endfunction ()

    cmake_unit_configure_test (CONFIGURE COMMAND _cmake_unit_configure
                               VERIFY COMMAND _cmake_unit_verify)

endfunction ()

# Check that there's a CMake error when the _cmake_unit_configure step fails
function (cmake_unit_test_cmake_build_test_error_on_configure_fail)

    function (_cmake_unit_configure)

        set (CONFIGURE_SCRIPT "message (FATAL_ERROR \"Fatal Error\")\n")
        _cmake_unit_test_gen_configure (NAMESPACE sample
                                        NAME one
                                        CONFIGURE SCRIPT
                                                  "${CONFIGURE_SCRIPT}")

    endfunction ()

    function (_cmake_unit_verify)

        cmake_unit_escape_string ("${CMAKE_COMMAND}" ESC_CMAKE_COMMAND)

        cmake_unit_get_log_for (INVOKE_TEST OUTPUT TEST_OUTPUT)
        cmake_unit_assert_file_has_line_matching ("${TEST_OUTPUT}"
                                                  "^.*CMake Error.*$")
        cmake_unit_assert_file_has_line_matching ("${TEST_OUTPUT}"
                                                  "^.*${ESC_CMAKE_COMMAND}.*$")
        cmake_unit_assert_file_has_line_matching ("${TEST_OUTPUT}"
                                                  "^.*failed.*$")
        cmake_unit_assert_file_has_line_matching ("${TEST_OUTPUT}"
                                                  "^.*1.*$")

    endfunction ()

    cmake_unit_configure_test (CONFIGURE COMMAND _cmake_unit_configure
                               INVOKE_TEST ALLOW_FAIL
                               VERIFY COMMAND _cmake_unit_verify)

endfunction ()

# Don't error out on _cmake_unit_configure fail if failure is allowed
function (cmake_unit_test_cmake_build_test_no_error_on_configure_fail_if_fail_allowed)

    function (_cmake_unit_configure)

        set (CONFIGURE_SCRIPT "message (FATAL_ERROR \"Fatal Error\")\n")
        _cmake_unit_test_gen_configure (NAMESPACE sample
                                        NAME one
                                        INVOKE_CONFIGURE OPTIONS ALLOW_FAIL
                                        CONFIGURE SCRIPT
                                                  "${CONFIGURE_SCRIPT}")

    endfunction ()

    function (_cmake_unit_verify)

        cmake_unit_get_log_for (INVOKE_TEST OUTPUT TEST_OUTPUT)
        cmake_unit_assert_file_does_not_have_line_matching ("${TEST_OUTPUT}"
                                                            "^.*failed with.*$")

    endfunction ()

    cmake_unit_configure_test (CONFIGURE COMMAND _cmake_unit_configure
                               VERIFY COMMAND _cmake_unit_verify)

endfunction ()

# Add a build test that will fail to build due to invalid syntax. Check that
# the test fails accordingly.
function (cmake_unit_test_cmake_build_test_error_on_build_fail)

    cmake_unit_get_dirs (BINARY_DIR SOURCE_DIR)

    function (_cmake_unit_configure)

        set (SOURCE "${SOURCE_DIR}/Source.cpp")
        file (WRITE "${SOURCE}" "invalid(")

        set (CONFIGURE_SCRIPT "add_executable (exec ${SOURCE})\n")
        _cmake_unit_test_gen_configure (NAMESPACE sample
                                        NAME one
                                        INVOKE_CONFIGURE OPTIONS
                                                         LANGUAGES
                                                         C
                                                         CXX
                                        CONFIGURE SCRIPT
                                                  ${CONFIGURE_SCRIPT})

    endfunction ()

    function (_cmake_unit_verify)

        cmake_unit_escape_string ("${CMAKE_COMMAND}" ESC_CMAKE_COMMAND)

        cmake_unit_get_log_for (INVOKE_TEST OUTPUT TEST_OUTPUT)
        cmake_unit_assert_file_has_line_matching ("${TEST_OUTPUT}"
                                                  "^.*CMake Error.*$")
        cmake_unit_assert_file_has_line_matching ("${TEST_OUTPUT}"
                                                  "^.*${ESC_CMAKE_COMMAND}.*$")
        cmake_unit_assert_file_has_line_matching ("${TEST_OUTPUT}"
                                                  "^.*--build.*$")
        cmake_unit_assert_file_has_line_matching ("${TEST_OUTPUT}"
                                                  "^.*failed.*$")
        cmake_unit_assert_file_has_line_matching ("${TEST_OUTPUT}"
                                                  "^.*1.*$")

    endfunction ()

    cmake_unit_configure_test (CONFIGURE COMMAND _cmake_unit_configure
                               INVOKE_TEST ALLOW_FAIL
                               VERIFY COMMAND _cmake_unit_verify)

endfunction ()

# Add a build test that will fail to _cmake_unit_configure.
# The fact that we have defined no tests is an error
# Check that there's a CMake error when the test step fails
function (cmake_unit_test_cmake_build_test_error_on_test_fail)

    function (_cmake_unit_configure)

        set (CONFIGURE_SCRIPT "enable_testing ()\n"
                              "add_test (always_fails\n"
                              "          \"\${CMAKE_COMMAND}\"\n"
                              "          does_not_exist)\n")
        _cmake_unit_test_gen_configure (NAMESPACE sample
                                        NAME one
                                        CONFIGURE SCRIPT
                                                  ${CONFIGURE_SCRIPT})

    endfunction ()

    function (_cmake_unit_verify)

        cmake_unit_escape_string ("${CMAKE_CTEST_COMMAND}" ESCAPED_CTEST_COMMAND)

        cmake_unit_get_log_for (INVOKE_TEST OUTPUT TEST_OUTPUT)
        cmake_unit_assert_file_has_line_matching ("${TEST_OUTPUT}"
                                                  "^.*CMake Error.*$")
        cmake_unit_assert_file_has_line_matching ("${TEST_OUTPUT}"
                                                  "^.*${ESCAPED_CTEST_COMMAND}.*$")
        cmake_unit_assert_file_has_line_matching ("${TEST_OUTPUT}"
                                                  "^.*failed.*$")
        cmake_unit_assert_file_has_line_matching ("${TEST_OUTPUT}"
                                                  "^.*1.*$")

    endfunction ()

    cmake_unit_configure_test (CONFIGURE COMMAND _cmake_unit_configure
                               INVOKE_TEST ALLOW_FAIL
                               VERIFY COMMAND _cmake_unit_verify)

endfunction ()

# Add a build test that will fail to test, but don't fail because ALLOW_FAIL
# was specified for the test step.
function (cmake_unit_test_cmake_build_test_no_error_on_test_fail_where_fail_allowed)

    function (_cmake_unit_configure)

        set (CONFIGURE_SCRIPT "enable_testing ()\n"
                              "add_test (always_fails\n"
                              "          \"\${CMAKE_COMMAND}\"\n"
                              "          does_not_exist)\n")
        _cmake_unit_test_gen_configure (NAMESPACE sample
                                        NAME one
                                        CONFIGURE SCRIPT
                                                  ${CONFIGURE_SCRIPT}
                                        INVOKE_TEST OPTIONS ALLOW_FAIL)

    endfunction ()

    function (_cmake_unit_verify)

        cmake_unit_get_log_for (INVOKE_TEST OUTPUT TEST_OUTPUT)
        cmake_unit_assert_file_does_not_have_line_matching ("${TEST_OUTPUT}"
                                                            "^.*failed with.*$")

    endfunction ()

    cmake_unit_configure_test (CONFIGURE COMMAND _cmake_unit_configure
                               VERIFY COMMAND _cmake_unit_verify)

endfunction ()

# Add a build test that will fail on its _cmake_unit_verify step. Check to make sure
# that the test fails.
function (cmake_unit_test_cmake_build_test_error_on_verify_fail)

    function (_cmake_unit_configure)

        set (VERIFY_SCRIPT "message (FATAL_ERROR \"Fatal Error\")\n")
        _cmake_unit_test_gen_configure (NAMESPACE sample
                                        NAME one
                                        VERIFY SCRIPT
                                               ${VERIFY_SCRIPT})

    endfunction ()

    function (_cmake_unit_verify)

        cmake_unit_escape_string ("${CMAKE_COMMAND}" ESC_CMAKE_COMMAND)

        cmake_unit_get_log_for (INVOKE_TEST OUTPUT TEST_OUTPUT)
        cmake_unit_assert_file_has_line_matching ("${TEST_OUTPUT}"
                                                  "^.*CMake Error.*$")
        set (EXPECTED_STR
             "A command failed during the"
             "invocation of callback \"gen_verify\"")
        string (REPLACE ";" " " EXPECTED_STR "${EXPECTED_STR}")
        cmake_unit_assert_file_has_line_matching ("${TEST_OUTPUT}"
                                                  "^.*${EXPECTED_STR}.*$")

    endfunction ()

    cmake_unit_configure_test (CONFIGURE COMMAND _cmake_unit_configure
                               INVOKE_TEST ALLOW_FAIL
                               VERIFY COMMAND _cmake_unit_verify)

endfunction ()

# Add a build test that will fail to _cmake_unit_configure, the build step should not run.
function (cmake_unit_test_cmake_build_test_build_step_not_run_if_configure_can_fail)

    function (_cmake_unit_configure)

        _cmake_unit_test_gen_configure (NAMESPACE sample
                                        NAME one
                                        INVOKE_CONFIGURE OPTIONS ALLOW_FAIL)

    endfunction ()

    function (_cmake_unit_verify)

        cmake_unit_get_log_for (INVOKE_TEST OUTPUT TEST_OUTPUT)
        cmake_unit_assert_file_does_not_have_line_matching ("${TEST_OUTPUT}"
                                                            "^.*--build.*$")

    endfunction ()

    cmake_unit_configure_test (CONFIGURE COMMAND _cmake_unit_configure
                               VERIFY COMMAND _cmake_unit_verify)

endfunction ()

# Add a build test that can fail to build - the test step should never run.
function (cmake_unit_test_cmake_build_test_test_step_not_run_if_build_can_fail)

    function (_cmake_unit_configure)

        _cmake_unit_test_gen_configure (NAMESPACE sample
                                        NAME one
                                        INVOKE_BUILD OPTIONS ALLOW_FAIL)

    endfunction ()

    function (_cmake_unit_verify)

        cmake_unit_escape_string ("${CMAKE_CTEST_COMMAND}" ESCAPED_CTEST_COMMAND)

        cmake_unit_get_log_for (INVOKE_TEST OUTPUT TEST_OUTPUT)

        set (CTEST_REGEX "^.*${ESCAPED_CTEST_COMMAND}.*$")
        cmake_unit_assert_file_does_not_have_line_matching ("${TEST_OUTPUT}"
                                                            "${CTEST_REGEX}")

    endfunction ()

    cmake_unit_configure_test (CONFIGURE COMMAND _cmake_unit_configure
                               VERIFY COMMAND _cmake_unit_verify)

endfunction ()

# Make sure that a custom target is passed to cmake --build
function (cmake_unit_test_cmake_build_test_with_custom_target)

    function (_cmake_unit_configure)

        set (CONFIGURE_SCRIPT
             "add_custom_target (custom_target)\n")

        _cmake_unit_test_gen_configure (NAMESPACE sample
                                        NAME one
                                        CONFIGURE SCRIPT ${CONFIGURE_SCRIPT}
                                        INVOKE_BUILD OPTIONS
                                                     TARGET
                                                     custom_target)

    endfunction ()

    function (_cmake_unit_verify)

        cmake_unit_escape_string ("${CMAKE_COMMAND}" ESC_CMAKE_COMMAND)

        cmake_unit_get_log_for (INVOKE_TEST OUTPUT TEST_OUTPUT)

        set (CMAKE_BUILD_REGEX
             "^.*${ESC_CMAKE_COMMAND} --build.*--target custom_target.*$")
        cmake_unit_assert_file_has_line_matching ("${TEST_OUTPUT}"
                                                  "${CMAKE_BUILD_REGEX}")

    endfunction ()

    cmake_unit_configure_test (CONFIGURE COMMAND _cmake_unit_configure
                               VERIFY COMMAND _cmake_unit_verify)

endfunction ()

# Adds a cmake_build_test. Override the clean step and put something in the
# binary directory. Make sure it is completely cleaned out after passing
# control back to cmake_unit_invoke_clean
function (cmake_unit_test_cmake_build_test_clean_step_always_runs)

    cmake_unit_get_dirs (BINARY_DIR SOURCE_DIR)

    # The file is inside the inner test build dir
    set (FILE_THAT_SHOULD_NOT_EXIST
         "${BINARY_DIR}/sample_test_one/build/check_dir")

    function (_cmake_unit_configure)

        set (CLEAN_SCRIPT
             "file (MAKE_DIRECTORY \"${FILE_THAT_SHOULD_NOT_EXIST}\")\n"
             "_cmake_unit_call_function (cmake_unit_invoke_clean\n"
             "                           \${CALLER_ARGN})\n")
        _cmake_unit_test_gen_configure (NAMESPACE sample
                                        NAME one
                                        CLEAN SCRIPT ${CLEAN_SCRIPT})

    endfunction ()

    function (_cmake_unit_verify)

        cmake_unit_assert_file_does_not_exist ("${FILE_THAT_SHOULD_NOT_EXIST}")

    endfunction ()

    cmake_unit_configure_test (CONFIGURE COMMAND _cmake_unit_configure
                               VERIFY COMMAND _cmake_unit_verify)

endfunction ()

# Put something in the build directory but also override the clean step
# so that nothing is run. The file should still be there at _cmake_unit_verify-stage
function (cmake_unit_test_cmake_build_test_clean_step_not_run_on_no_clean)

    cmake_unit_get_dirs (BINARY_DIR SOURCE_DIR)

    # The file is inside the inner test build dir
    set (FILE_THAT_SHOULD_EXIST "${BINARY_DIR}/sample_test_one/build/check_dir")

    function (_cmake_unit_configure)

        set (CLEAN_SCRIPT
             "message (STATUS \"MKDIR ${FILE_THAT_SHOULD_EXIST}\")\n"
             "file (MAKE_DIRECTORY \"${FILE_THAT_SHOULD_EXIST}\")\n")
        _cmake_unit_test_gen_configure (NAMESPACE sample
                                        NAME one
                                        CLEAN SCRIPT ${CLEAN_SCRIPT})

    endfunction ()

    function (_cmake_unit_verify)

        cmake_unit_assert_file_exists ("${FILE_THAT_SHOULD_EXIST}")

    endfunction ()

    cmake_unit_configure_test (CONFIGURE COMMAND _cmake_unit_configure
                               VERIFY COMMAND _cmake_unit_verify)

endfunction ()

# Generates a warning, make sure that INVOKE_CONFIGURE errors out by default
function (cmake_unit_test_cmake_build_test_warnings_are_errors)

    function (_cmake_unit_configure)

        set (CONFIGURE_SCRIPT
             "message (WARNING \"Warning\")\n")
        _cmake_unit_test_gen_configure (NAMESPACE sample
                                        NAME one
                                        CONFIGURE SCRIPT ${CONFIGURE_SCRIPT})

    endfunction ()

    function (_cmake_unit_verify)

        cmake_unit_get_log_for (INVOKE_TEST OUTPUT TEST_OUTPUT)
        cmake_unit_assert_file_has_line_matching ("${TEST_OUTPUT}"
                                                  "^.*CMake Error.*$")

    endfunction ()

    cmake_unit_configure_test (CONFIGURE COMMAND _cmake_unit_configure
                               INVOKE_TEST ALLOW_FAIL
                               VERIFY COMMAND _cmake_unit_verify)
endfunction ()

# Generates a warning, make sure that INVOKE_CONFIGURE does not error out
# when ALLOW_WARNINGS is specified.
function (cmake_unit_test_cmake_build_test_warnings_not_errors_where_w_error_disabled)

    function (_cmake_unit_configure)

        set (CONFIGURE_SCRIPT
             "message (WARNING \"Warning\")\n")
        _cmake_unit_test_gen_configure (NAMESPACE sample
                                        NAME one
                                        INVOKE_CONFIGURE OPTIONS
                                                         ALLOW_WARNINGS
                                        CONFIGURE SCRIPT
                                                  ${CONFIGURE_SCRIPT})

    endfunction ()

    function (_cmake_unit_verify)

        cmake_unit_get_log_for (INVOKE_TEST OUTPUT TEST_OUTPUT)
        cmake_unit_assert_file_does_not_have_line_matching ("${TEST_OUTPUT}"
                                                            "^.*CMake Error.*$")
        cmake_unit_assert_file_has_line_matching ("${TEST_OUTPUT}"
                                                  "^.*CMake Warning.*$")

    endfunction ()

    cmake_unit_configure_test (CONFIGURE COMMAND _cmake_unit_configure
                               VERIFY COMMAND _cmake_unit_verify)

endfunction ()

# Set up some tests which will include some specifified scripts, but not
# a certain excluded script. Eg
# FirstTest:
# - Excluded.cmake
# - Included.cmake
# - FirstTestSpecific.cmake
# SecondTest:
# - Excluded.cmake
# - Included.cmake
# - SecondTestSpecific.cmake
# The following files will be added as part of COVERAGE_FILES
# - Included.cmake
# - FirstTestSpecific.cmake
# - SecondTestSpecific.cmake
# Use the excluded script as a convenient crutch to disable
# all the warnings
# Coverage should be recorded in both the test and _cmake_unit_verify steps
# Check that when CMAKE_UNIT_LOG_COVERAGE was on we created a file
# called SampleTests.trace in CMAKE_CURRENT_BINARY_DIR
# and that file contains the following:
# ^.*Included.cmake\(1\).*$
# ^.*FirstTestSpecific.cmake\(1\).*$
# ^.*SecondTestSpecific.cmake\(1\).*$
# ^.*FirstTest\(1\).*$
# ^.*FirstTest\(2\).*$
# ^.*FirstTest\(3\).*$
# ^.*SecondTest\(1\).*$
# ^.*SecondTest\(2\).*$
# ^.*SecondTest\(3\).*$
# It should NOT have any line matching ^.*Excluded.cmake.*$
# Included.cmake
# FirstTestSpecific.cmake
# SecondTestSpecific.cmake
# Don't include the tests themselves
# Does not include Excluded.cmake
function (cmake_unit_test_cmake_test_files_recorded_in_tracefile_across_tests)

    cmake_unit_get_dirs (BINARY_DIR SOURCE_DIR)

    set (COVERAGE_TRACEFILE "${BINARY_DIR}/coverage.trace")

    function (_cmake_unit_configure)

        set (CMAKE_UNIT_LOG_COVERAGE ON CACHE BOOL "" FORCE)
        set (CMAKE_UNIT_COVERAGE_FILE "${COVERAGE_TRACEFILE}"
             CACHE STRING "" FORCE)

        set (EXCLUDED "${CMAKE_CURRENT_BINARY_DIR}/Excluded.cmake")
        set (INCLUDED "${CMAKE_CURRENT_BINARY_DIR}/Included.cmake")
        set (FIRST_TEST_SPECIFIC
             "${CMAKE_CURRENT_BINARY_DIR}/FirstTestSpecific.cmake")
        set (SECOND_TEST_SPECIFIC
             "${CMAKE_CURRENT_BINARY_DIR}/SecondTestSpecific.cmake")

        file (WRITE "${EXCLUDED}"
              "message (STATUS \"Excluded Script\")\n")
        file (WRITE "${INCLUDED}"
              "message (STATUS \"Included Script\")\n")
        file (WRITE "${FIRST_TEST_SPECIFIC}"
              "message (STATUS \"First Test Specific Script\")\n")
        file (WRITE "${SECOND_TEST_SPECIFIC}"
              "message (STATUS \"Second Test Specific Script\")\n")

        set (TEST_ONE
             "include (${EXCLUDED})\n"
             "include (${INCLUDED})\n"
             "include (${FIRST_TEST_SPECIFIC})\n")

        _cmake_unit_test_gen_configure_no_discover (TEST_ONE_CONTENTS
                                                    NAMESPACE sample
                                                    NAME one
                                                    INVOKE_BUILD OPTIONS
                                                                 COMMAND
                                                                 NONE
                                                    INVOKE_TEST OPTIONS
                                                                COMMAND
                                                                NONE
                                                    CONFIGURE SCRIPT
                                                              "${TEST_ONE}")

        set (TEST_TWO
             "include (${EXCLUDED})\n"
             "include (${INCLUDED})\n"
             "include (${SECOND_TEST_SPECIFIC})\n")

        _cmake_unit_test_gen_configure_no_discover (TEST_TWO_CONTENTS
                                                    NAMESPACE sample
                                                    NAME two
                                                    INVOKE_BUILD OPTIONS
                                                                 COMMAND
                                                                 NONE
                                                    INVOKE_TEST OPTIONS
                                                                COMMAND
                                                                NONE
                                                    CONFIGURE SCRIPT
                                                              "${TEST_TWO}")

        # Work around a strange bug in cmakelint
        set (END "end")

        set (CONTENTS_PROLOGUE
             "if (NOT CMAKE_SCRIPT_MODE_FILE)\n"
             "    project (SampleTests NONE)\n"
             "${END}if ()\n")
        _cmake_unit_test_gen_discover_from_contents (CONTENTS
                                                     "${CONTENTS_PROLOGUE}\n"
                                                     ${TEST_ONE_CONTENTS}
                                                     ${TEST_TWO_CONTENTS}
                                                     INIT_OPTIONS
                                                     COVERAGE_FILES
                                                     "${INCLUDED}"
                                                     "${SECOND_TEST_SPECIFIC}"
                                                     "${FIRST_TEST_SPECIFIC}"
                                                     NAMESPACE sample)

    endfunction ()

    function (_cmake_unit_verify)

        cmake_unit_assert_file_exists ("${COVERAGE_TRACEFILE}")

        cmake_unit_assert_file_has_line_matching ("${COVERAGE_TRACEFILE}"
                                                  "^.*Included.cmake.1.*$")

        cmake_unit_assert_file_has_line_matching ("${COVERAGE_TRACEFILE}"
                                                  "^.*FirstTestSpecific.cmake.1.*$")

        cmake_unit_assert_file_has_line_matching ("${COVERAGE_TRACEFILE}"
                                                  "^.*SecondTestSpecific.cmake.1.*$")

        cmake_unit_assert_file_does_not_have_line_matching ("${COVERAGE_TRACEFILE}"
                                                            "^.*Excluded.cmake.*$")

    endfunction ()

    cmake_unit_configure_test (CONFIGURE COMMAND _cmake_unit_configure
                               VERIFY COMMAND _cmake_unit_verify)

endfunction ()

# Adds a test which adds a custom target with a command "cmake -E touch
# Generated.cpp" to the ALL target. Checks that cmake -E touch Generated.cpp
# was in the test output
function (cmake_unit_test_cmake_tests_have_verbose_output)

    function (_cmake_unit_configure)

        set (CONFIGURE_SCRIPT
             "set (BINARY_DIR \"\${CMAKE_CURRENT_BINARY_DIR}\")\n"
             "set (GENERATED_FILE \"\${BINARY_DIR}/Generated.cpp\")\n"
             "add_custom_command (OUTPUT\n"
             "                    \"\${GENERATED_FILE}\"\n"
             # The two commands will actually be to generate a
             # file called FirstCommand.cpp, and then another
             # command to generate SecondCommand.cpp
             "                    COMMAND\n"
             "                    \"\${CMAKE_COMMAND}\" -E touch\n"
             "                    \"\${BINARY_DIR}/FirstCommand.cpp\"\n"
             "                    COMMAND\n"
             "                    \"\${CMAKE_COMMAND}\" -E touch\n"
             "                    \"\${BINARY_DIR}/SecondCommand.cpp\")\n"
             "add_custom_target (custom_target ALL\n"
             "                   SOURCES \"\${GENERATED_FILE}\")\n")

        _cmake_unit_test_gen_configure (NAMESPACE sample
                                        NAME one
                                        CONFIGURE SCRIPT
                                                  ${CONFIGURE_SCRIPT})

    endfunction ()

    function (_cmake_unit_verify)

        cmake_unit_escape_string ("${CMAKE_COMMAND}" ESC_CMAKE_COMMAND)

        cmake_unit_get_log_for (INVOKE_TEST OUTPUT TEST_OUTPUT)
        set (FIRST_REGEX
             "^.*${ESC_CMAKE_COMMAND}.*-E touch .*FirstCommand.cpp.*$")
        cmake_unit_assert_file_has_line_matching ("${TEST_OUTPUT}"
                                                  "${FIRST_REGEX}")

        set (SECOND_REGEX
             "^.*${ESC_CMAKE_COMMAND}.*-E touch .*SecondCommand.cpp.*$")
        cmake_unit_assert_file_has_line_matching ("${TEST_OUTPUT}"
                                                  "${SECOND_REGEX}")

    endfunction ()

    cmake_unit_configure_test (CONFIGURE COMMAND _cmake_unit_configure
                               VERIFY COMMAND _cmake_unit_verify)

endfunction ()

# Add a test whose _cmake_unit_configure step is allowed to fail and make it print a
# FATAL_ERROR on the _cmake_unit_configure step. On the test output, we should see
# "CMake Error", both lines of our error message and the call stack
function (cmake_unit_test_preserve_contents_of_cmake_errors_in_configure_output)

    function (_cmake_unit_configure)

        set (CONFIGURE_SCRIPT
             "message (FATAL_ERROR \"Fatal Error\\nOn Multiple Lines\")\n")

        _cmake_unit_test_gen_configure (NAMESPACE sample
                                        NAME one
                                        INVOKE_CONFIGURE OPTIONS
                                                         ALLOW_FAIL
                                        CONFIGURE SCRIPT
                                                  ${CONFIGURE_SCRIPT})

    endfunction ()

    function (_cmake_unit_verify)

        cmake_unit_get_log_for (INVOKE_TEST OUTPUT TEST_OUTPUT)
        cmake_unit_assert_file_has_line_matching ("${TEST_OUTPUT}" "^.*CMake Error.*$")
        cmake_unit_assert_file_has_line_matching ("${TEST_OUTPUT}" "^.*Fatal Error.*$")
        cmake_unit_assert_file_has_line_matching ("${TEST_OUTPUT}"
                                                  "^.*On Multiple Lines.*$")
        cmake_unit_assert_file_has_line_matching ("${TEST_OUTPUT}" "^.*Call Stack.*$")

    endfunction ()

    cmake_unit_configure_test (CONFIGURE COMMAND _cmake_unit_configure
                               VERIFY COMMAND _cmake_unit_verify)

endfunction ()

# Check that a source file by the name Source.cpp was created in
# ${CMAKE_CURRENT_SOURCE_DIR} when we call
# cmake_unit_generated_source_file_before_build at the _cmake_unit_configure-stage (it
# shouldn't exist at the _cmake_unit_configure stage)
function (cmake_unit_test_source_file_generated_during_build_exists)

    cmake_unit_get_dirs (BINARY_DIR SOURCE_DIR)

    function (_cmake_unit_configure)

        cmake_unit_generate_source_file_during_build (GENERATED_DURING_TARGET)

        cmake_unit_assert_file_does_not_exist ("${SOURCE_DIR}/Source.cpp")

    endfunction ()

    function (_cmake_unit_verify)

        cmake_unit_assert_file_exists ("${BINARY_DIR}/Source.cpp")

    endfunction ()

    cmake_unit_configure_test (CONFIGURE COMMAND _cmake_unit_configure
                               VERIFY COMMAND _cmake_unit_verify)

endfunction ()

# Check that source files created and generated with the same options
# are completely equal. The hash of both should be equal.
function (cmake_unit_test_generated_and_created_source_files_equal)

    cmake_unit_get_dirs (BINARY_DIR SOURCE_DIR)

    function (_cmake_unit_configure)

        set (GENERATE_OPTIONS
             NAME "CustomSource.cpp"
             INCLUDES "custom_include.h" "other_include.h"
             DEFINES "CUSTOM_DEFINITION" "OTHER_DEFINITION"
             FUNCTIONS "function_one" "function_two"
             PREPEND_CONTENTS "static int integer_variable@SEMICOLON@")

        cmake_unit_generate_source_file_during_build (GENERATED_DURING_TARGET
                                                      ${GENERATE_OPTIONS})
        cmake_unit_create_source_file_before_build (${GENERATE_OPTIONS})

    endfunction ()

    function (_cmake_unit_verify)

        file (SHA512 "${SOURCE_DIR}/CustomSource.cpp" CREATED_HASH)
        file (SHA512 "${BINARY_DIR}/CustomSource.cpp" GENERATED_HASH)

        cmake_unit_assert_variable_is (CREATED_HASH STRING EQUAL "${GENERATED_HASH}")

    endfunction ()

    cmake_unit_configure_test (CONFIGURE COMMAND _cmake_unit_configure
                               VERIFY COMMAND _cmake_unit_verify)

endfunction ()

# Creates a simple executable named "executable" by using
# cmake_unit_create_simple_executable/ Look up the location of "executable"
# by using cmake_unit_get_target_location_from_exports from the
# ${CMAKE_CURRENT_BINARY_DIR}/exports.cmake and executes it
function (cmake_unit_test_create_simple_executable)

    cmake_unit_get_dirs (BINARY_DIR SOURCE_DIR)

    function (_cmake_unit_configure)

        cmake_unit_create_simple_executable (executable)
        export (TARGETS executable FILE "${BINARY_DIR}/exports.cmake")

    endfunction ()

    function (_cmake_unit_verify)

        set (EXPORTS_FILE "${BINARY_DIR}/exports.cmake")
        cmake_unit_get_target_location_from_exports ("${EXPORTS_FILE}"
                                                     executable
                                                     LOCATION)

        cmake_unit_assert_file_exists ("${LOCATION}")
        cmake_unit_assert_command_executes_with_success (COMMAND "${LOCATION}")

    endfunction ()

    cmake_unit_configure_test (INVOKE_CONFIGURE LANGUAGES C CXX
                               CONFIGURE COMMAND _cmake_unit_configure
                               VERIFY COMMAND _cmake_unit_verify)

endfunction ()

# Creates a simple executable named "executable" by using
# cmake_unit_create_simple_executable and links to a simple library
# named "library" created by using cmake_unit_create_simple_library
#
# Checks the build output to make sure a "simple" executable is linked to
# the "simple" library.
# There's not too much particularly useful to _cmake_unit_verify here, other than
# the executable and the library being mentioned because the order
# in which they are mentioned is generator specific
function (cmake_unit_test_create_simple_library)

    cmake_unit_get_dirs (BINARY_DIR SOURCE_DIR)

    function (_cmake_unit_configure)

        cmake_unit_create_simple_library (library SHARED FUNCTIONS function)
        cmake_unit_create_simple_executable (executable)
        target_link_libraries (executable library)

    endfunction ()

    function (_cmake_unit_verify)

        cmake_unit_get_log_for (INVOKE_BUILD OUTPUT BUILD_OUTPUT)

        cmake_unit_assert_file_has_line_matching ("${BUILD_OUTPUT}" "^.*library.*$")
        cmake_unit_assert_file_has_line_matching ("${BUILD_OUTPUT}" "^.*executable.*$")

    endfunction ()

    cmake_unit_configure_test (INVOKE_CONFIGURE LANGUAGES C CXX
                               CONFIGURE COMMAND _cmake_unit_configure
                               VERIFY COMMAND _cmake_unit_verify)

endfunction ()

# Create an external project with an exported library and use
# cmake_export_cfg_int_dir in that external project to write out
# CMAKE_CFG_INT_DIR to CfgIntDirValue.txt in its BINARY_DIR
#
# Uses cmake_unit_import_cfg_int_dir and cross-checks that against an
# exported target from the external project's location. If the path
# ${CMAKE_CURRENT_BINARY_DIR}/ExternalProject/build/${CFG_INT_DIR}
# is the prefix to the exported target's LOCATION property then that
# means that the CFG_INT_DIR was successful stored on this generator.
# Normalize path
function (cmake_unit_test_export_import_cfg_int_dir)

    cmake_unit_get_dirs (BINARY_DIR SOURCE_DIR)

    set (EXTERNAL_PROJECT_SOURCE_DIR "${BINARY_DIR}/ExternalProject")
    set (EXTERNAL_PROJECT_BINARY_DIR "${EXTERNAL_PROJECT_SOURCE_DIR}/build")
    set (EXTERNAL_PROJECT_EXPORTS
         "${EXTERNAL_PROJECT_BINARY_DIR}/exports.cmake")

    function (_cmake_unit_configure)

        include (ExternalProject)

        set (EXTERNAL_PROJECT_CMAKELISTS_TXT
             "${EXTERNAL_PROJECT_SOURCE_DIR}/CMakeLists.txt")
        string (REPLACE ";" " " STRINGIFIED_CMAKE_MODULE_PATH
                "${CMAKE_MODULE_PATH}")
        set (EXTERNAL_PROJECT_CMAKELISTS_TXT_CONTENT
             "cmake_minimum_required (VERSION 2.8)\n"
             "set (CMAKE_MODULE_PATH ${STRINGIFIED_CMAKE_MODULE_PATH})\n"
             "include (CMakeUnit)\n"
             "cmake_unit_create_simple_executable (executable)\n"
             "export (TARGETS executable\n"
             "        FILE ${EXTERNAL_PROJECT_EXPORTS})\n"
             "set (CFG_INT_DIR_LOCATION ${BINARY_DIR}/CfgIntDir.txt)\n"
             "cmake_unit_export_cfg_int_dir (\${CFG_INT_DIR_LOCATION})\n")

        file (MAKE_DIRECTORY "${EXTERNAL_PROJECT_SOURCE_DIR}")
        file (MAKE_DIRECTORY "${EXTERNAL_PROJECT_BINARY_DIR}")
        file (WRITE "${EXTERNAL_PROJECT_CMAKELISTS_TXT}"
              ${EXTERNAL_PROJECT_CMAKELISTS_TXT_CONTENT})

        externalproject_add (ExternalProject
                             SOURCE_DIR "${EXTERNAL_PROJECT_SOURCE_DIR}"
                             BINARY_DIR "${EXTERNAL_PROJECT_BINARY_DIR}"
                             INSTALL_COMMAND "")

        add_custom_target (target ALL DEPENDS ExternalProject)

    endfunction ()

    function (_cmake_unit_verify)

        cmake_unit_import_cfg_int_dir ("${BINARY_DIR}/CfgIntDir.txt"
                                       CFG_INT_DIR)
        cmake_unit_get_target_location_from_exports ("${EXTERNAL_PROJECT_EXPORTS}"
                                                     executable
                                                     EXECUTABLE_LOCATION)


        set (EXPECTED_EXECUTABLE_LOCATION_HEADER
             "${EXTERNAL_PROJECT_BINARY_DIR}/${CFG_INT_DIR}")
        get_filename_component (EXPECTED_EXECUTABLE_LOCATION_HEADER
                                "${EXPECTED_EXECUTABLE_LOCATION_HEADER}"
                                ABSOLUTE)
        string (LENGTH "${EXPECTED_EXECUTABLE_LOCATION_HEADER}"
                EXPECTED_EXECUTABLE_LOCATION_HEADER_LENGTH)
        string (SUBSTRING "${EXECUTABLE_LOCATION}"
                0
                ${EXPECTED_EXECUTABLE_LOCATION_HEADER_LENGTH}
                EXECUTABLE_LOCATION_HEADER)

        cmake_unit_assert_variable_is (EXECUTABLE_LOCATION_HEADER
                                       STRING EQUAL
                                       "${EXPECTED_EXECUTABLE_LOCATION_HEADER}")

    endfunction ()

    cmake_unit_configure_test (CONFIGURE COMMAND _cmake_unit_configure
                               VERIFY COMMAND _cmake_unit_verify)

endfunction ()

# Check the _cmake_unit_target_exists matcher.
function (cmake_unit_test_target_exists)

    cmake_unit_get_dirs (BINARY_DIR SOURCE_DIR)

    function (_cmake_unit_configure)

        file (WRITE "${CMAKE_CURRENT_BINARY_DIR}/Library.cpp" "")
        add_library (library SHARED
                     "${CMAKE_CURRENT_BINARY_DIR}/Library.cpp")

        _cmake_unit_target_exists (library RESULT)
        _cmake_unit_target_exists (not_existing NOT_RESULT)

        cmake_unit_assert_true (${RESULT})
        cmake_unit_assert_false (${NOT_RESULT})

    endfunction ()

    cmake_unit_configure_config_only_test (INVOKE_CONFIGURE LANGUAGES C CXX
                                           CONFIGURE COMMAND _cmake_unit_configure)

endfunction ()

# Check the _cmake_unit_string_contains matcher.
function (cmake_unit_test_string_contains)

    function (_cmake_unit_configure)

        set (SUBSTRING "substring")
        set (MAIN_STRING "main_${SUBSTRING}_string")

        _cmake_unit_string_contains (${MAIN_STRING} ${SUBSTRING} RESULT)
        _cmake_unit_string_contains (${MAIN_STRING} "other" NOT_RESULT)

        cmake_unit_assert_true (${RESULT})
        cmake_unit_assert_false (${NOT_RESULT})

    endfunction ()

    cmake_unit_configure_config_only_test (CONFIGURE COMMAND _cmake_unit_configure)

endfunction ()

# Check the _cmake_unit_variable_is matcher for ints and bools
function (cmake_unit_test_variable_is)

    function (_cmake_unit_configure)

        set (STRING_VARIABLE "value")

        _cmake_unit_variable_is (STRING_VARIABLE STRING EQUAL "value" EXPECT_EQUAL)
        _cmake_unit_variable_is (STRING_VARIABLE STRING EQUAL "nvalue" EXPECT_UNEQUAL)
        _cmake_unit_variable_is (STRING_VARIABLE STRING GREATER "valud" EXPECT_LESS)
        _cmake_unit_variable_is (STRING_VARIABLE STRING GREATER "valuf" EXPECT_NOT_LESS)
        _cmake_unit_variable_is (STRING_VARIABLE STRING LESS "valuf" EXPECT_GREATER)
        _cmake_unit_variable_is (STRING_VARIABLE STRING LESS "valud" EXPECT_NOT_GREATER)

        cmake_unit_assert_true (${EXPECT_EQUAL})
        cmake_unit_assert_false (${EXPECT_UNEQUAL})
        cmake_unit_assert_true (${EXPECT_LESS})
        cmake_unit_assert_false (${EXPECT_NOT_LESS})
        cmake_unit_assert_true (${EXPECT_GREATER})
        cmake_unit_assert_false (${EXPECT_NOT_GREATER})

        set (INTEGER_VARIABLE 1)

        _cmake_unit_variable_is (INTEGER_VARIABLE INTEGER EQUAL 1 EXPECT_EQUAL)
        _cmake_unit_variable_is (INTEGER_VARIABLE INTEGER EQUAL 2 EXPECT_UNEQUAL)
        _cmake_unit_variable_is (INTEGER_VARIABLE INTEGER GREATER 0 EXPECT_LESS)
        _cmake_unit_variable_is (INTEGER_VARIABLE INTEGER GREATER 2 EXPECT_NOT_LESS)
        _cmake_unit_variable_is (INTEGER_VARIABLE INTEGER LESS 2 EXPECT_GREATER)
        _cmake_unit_variable_is (INTEGER_VARIABLE INTEGER LESS 0 EXPECT_NOT_GREATER)

        cmake_unit_assert_true (${EXPECT_EQUAL})
        cmake_unit_assert_false (${EXPECT_UNEQUAL})
        cmake_unit_assert_true (${EXPECT_LESS})
        cmake_unit_assert_false (${EXPECT_NOT_LESS})
        cmake_unit_assert_true (${EXPECT_GREATER})
        cmake_unit_assert_false (${EXPECT_NOT_GREATER})

        set (BOOL_VARIABLE ON)

        _cmake_unit_variable_is (BOOL_VARIABLE BOOL EQUAL ON EXPECT_EQUAL)
        _cmake_unit_variable_is (BOOL_VARIABLE BOOL EQUAL OFF EXPECT_UNEQUAL)

        cmake_unit_assert_true (${EXPECT_EQUAL})
        cmake_unit_assert_false (${EXPECT_UNEQUAL})

    endfunction ()

    cmake_unit_configure_config_only_test (CONFIGURE COMMAND _cmake_unit_configure)

endfunction ()

# Check the _cmake_unit_variable_is matcher with empty values
function (cmake_unit_test_variable_is_empty)

    function (_cmake_unit_configure)

        set (STRING_VARIABLE "")

        _cmake_unit_variable_is ("${STRING_VARIABLE}" STRING EQUAL "" EXPECT_EQUAL)

        cmake_unit_assert_true (${EXPECT_EQUAL})

    endfunction ()

    cmake_unit_configure_config_only_test (CONFIGURE COMMAND _cmake_unit_configure)

endfunction ()

# Check the _cmake_unit_command_executes_with_success matcher.
function (cmake_unit_test_command_executes_with_success)

    cmake_unit_get_dirs (BINARY_DIR SOURCE_DIR)

    function (_cmake_unit_configure)

        _cmake_unit_command_executes_with_success (RESULT_TRUE
                                                   ERROR_TRUE
                                                   CODE_TRUE
                                                   COMMAND "${CMAKE_COMMAND}")

        # Passes bogus argument to CMake, won't ever succeed
        set (UNSUCCESSFUL_EXECUTABLE "${BINARY_DIR}/does_not_exist")
        _cmake_unit_command_executes_with_success (RESULT_FALSE
                                                   ERROR_FALSE
                                                   CODE_FALSE
                                                   COMMAND
                                                   "${CMAKE_COMMAND}"
                                                   "${UNSUCCESSFUL_EXECUTABLE}")

        cmake_unit_assert_true (${RESULT_TRUE})
        cmake_unit_assert_false (${RESULT_FALSE})

    endfunction ()

    cmake_unit_configure_config_only_test (CONFIGURE COMMAND _cmake_unit_configure)

endfunction ()

# Check the _cmake_unit_target_is_linked_to matcher.
function (cmake_unit_test_target_is_linked_to)

    cmake_unit_get_dirs (BINARY_DIR SOURCE_DIR)

    function (_cmake_unit_configure)

        file (WRITE "${BINARY_DIR}/Library.cpp" "")
        file (WRITE "${BINARY_DIR}/Source.cpp" "")

        add_library (library SHARED
                     "${BINARY_DIR}/Library.cpp")
        add_executable (executable
                        "${BINARY_DIR}/Source.cpp")

        target_link_libraries (executable library)

        _cmake_unit_target_is_linked_to (executable library RESULT)
        _cmake_unit_target_is_linked_to (executable not_linked_to_this NOT_RESULT)

        cmake_unit_assert_true (${RESULT})
        cmake_unit_assert_false (${NOT_RESULT})

    endfunction ()

    cmake_unit_configure_config_only_test (INVOKE_CONFIGURE LANGUAGES CXX
                                           CONFIGURE COMMAND _cmake_unit_configure)

endfunction ()

# Check the _cmake_unit_item_has_property_with_value matcher.
function (cmake_unit_test_item_has_property_with_value)

    function (_cmake_unit_configure)

        set (TARGET_PROPERTY_VALUE "value")
        add_custom_target (target)
        set_property (TARGET target
                      PROPERTY TARGET_PROPERTY
                      ${TARGET_PROPERTY_VALUE})

        _cmake_unit_item_has_property_with_value (TARGET target
                                                  TARGET_PROPERTY
                                                  STRING EQUAL
                                                  ${TARGET_PROPERTY_VALUE}
                                                  EXPECT_EQUAL)

        _cmake_unit_item_has_property_with_value (TARGET target
                                                  TARGET_PROPERTY
                                                  STRING EQUAL
                                                  "something_else"
                                                  EXPECT_NOT_EQUAL)

        _cmake_unit_item_has_property_with_value (TARGET target
                                                  TARGET_NON_EXISTENT_PROPERTY
                                                  STRING EQUAL
                                                  ${TARGET_PROPERTY_VALUE}
                                                  EXPECT_DOESNT_EXIST)

        cmake_unit_assert_true (${EXPECT_EQUAL})
        cmake_unit_assert_false (${EXPECT_NOT_EQUAL})
        cmake_unit_assert_false (${EXPECT_DOESNT_EXIST})

    endfunction ()

    cmake_unit_configure_config_only_test (CONFIGURE COMMAND _cmake_unit_configure)

endfunction ()

# Check the _cmake_unit_item_has_property_with_value matcher with empty values.
function (cmake_unit_test_item_has_property_with_value_empty)

    function (_cmake_unit_configure)

        set (TARGET_PROPERTY_VALUE "")
        add_custom_target (target)
        set_property (TARGET target
                      PROPERTY TARGET_PROPERTY
                      "${TARGET_PROPERTY_VALUE}")

        _cmake_unit_item_has_property_with_value (TARGET target
                                                  TARGET_PROPERTY
                                                  STRING EQUAL
                                                  "${TARGET_PROPERTY_VALUE}"
                                                  EXPECT_EQUAL)

        cmake_unit_assert_true (${EXPECT_EQUAL})

    endfunction ()

    cmake_unit_configure_config_only_test (CONFIGURE COMMAND _cmake_unit_configure)

endfunction ()

# Check the _cmake_unit_item_has_property_with_value matcher with GLOBAL
# properties.
function (cmake_unit_test_item_has_property_with_value_global)

    function (_cmake_unit_configure)


        set (GLOBAL_PROPERTY_VALUE "value")
        set_property (GLOBAL
                      PROPERTY GLOBAL_PROPERTY
                      ${GLOBAL_PROPERTY_VALUE})

        _cmake_unit_item_has_property_with_value (GLOBAL GLOBAL
                                                  GLOBAL_PROPERTY
                                                  STRING EQUAL
                                                  ${GLOBAL_PROPERTY_VALUE}
                                                  EXPECT_EQUAL)

        _cmake_unit_item_has_property_with_value (GLOBAL GLOBAL
                                                  GLOBAL_PROPERTY
                                                  STRING EQUAL
                                                  "something_else"
                                                  EXPECT_NOT_EQUAL)

        _cmake_unit_item_has_property_with_value (GLOBAL GLOBAL
                                                  GLOBAL_NON_EXISTENT_PROPERTY
                                                  STRING EQUAL
                                                  ${GLOBAL_PROPERTY_VALUE}
                                                  EXPECT_DOESNT_EXIST)

        cmake_unit_assert_true (${EXPECT_EQUAL})
        cmake_unit_assert_false (${EXPECT_NOT_EQUAL})
        cmake_unit_assert_false (${EXPECT_DOESNT_EXIST})

    endfunction ()

    cmake_unit_configure_config_only_test (CONFIGURE COMMAND _cmake_unit_configure)

endfunction ()

# Check the _cmake_unit_item_has_property_with_value matcher.
function (cmake_unit_test_item_has_property_containing_value)

    function (_cmake_unit_configure)

        set (TARGET_PROPERTY_VALUE "value")
        set (TARGET_PROPERTY_OTHER_VALUE "other_value")
        add_custom_target (target)
        set_property (TARGET target
                      APPEND
                      PROPERTY TARGET_PROPERTY
                      ${TARGET_PROPERTY_VALUE})
        set_property (TARGET target
                      APPEND
                      PROPERTY TARGET_PROPERTY
                      ${TARGET_PROPERTY_OTHER_VALUE})

        _cmake_unit_item_has_property_containing_value (TARGET target
                                                        TARGET_PROPERTY
                                                        STRING EQUAL
                                                        ${TARGET_PROPERTY_VALUE}
                                                        EXPECT_EQUAL_FIRST)

        _cmake_unit_item_has_property_containing_value (TARGET target
                                                        TARGET_PROPERTY
                                                        STRING EQUAL
                                                        ${TARGET_PROPERTY_OTHER_VALUE}
                                                        EXPECT_EQUAL_SECOND)

        _cmake_unit_item_has_property_containing_value (TARGET target
                                                        TARGET_PROPERTY
                                                        STRING EQUAL
                                                        "property_does_not_contain_this"
                                                        EXPECT_NOT_EQUAL)

        _cmake_unit_item_has_property_containing_value (TARGET target
                                                        TARGET_NON_EXISTENT_PROPERTY
                                                        STRING EQUAL
                                                        ${TARGET_PROPERTY_VALUE}
                                                        EXPECT_DOESNT_EXIST)

        cmake_unit_assert_true (${EXPECT_EQUAL_FIRST})
        cmake_unit_assert_true (${EXPECT_EQUAL_SECOND})
        cmake_unit_assert_false (${EXPECT_NOT_EQUAL})
        cmake_unit_assert_false (${EXPECT_DOESNT_EXIST})

    endfunction ()

    cmake_unit_configure_config_only_test (CONFIGURE COMMAND _cmake_unit_configure)

endfunction ()

# Check the _cmake_unit_item_has_property_with_value matcher with empty values.
# Empty variables never stored in lists
function (cmake_unit_test_item_has_property_containing_value_empty)

    function (_cmake_unit_configure)

        set (TARGET_PROPERTY_VALUE "")
        add_custom_target (target)
        set_property (TARGET target
                      APPEND
                      PROPERTY TARGET_PROPERTY
                      "${TARGET_PROPERTY_VALUE}")

        _cmake_unit_item_has_property_containing_value (TARGET target
                                                        TARGET_PROPERTY
                                                        STRING EQUAL
                                                        "${TARGET_PROPERTY_VALUE}"
                                                        EXPECT_EQUAL)

        cmake_unit_assert_false (${EXPECT_EQUAL})

    endfunction ()

    cmake_unit_configure_config_only_test (CONFIGURE COMMAND _cmake_unit_configure)

endfunction ()

# Check the _cmake_unit_item_has_property_with_value matcher with GLOBAL
# properties.
function (cmake_unit_test_item_has_property_containing_value_global)

    function (_cmake_unit_configure)

        set (GLOBAL_PROPERTY_VALUE "value")
        set (GLOBAL_PROPERTY_OTHER_VALUE "other_value")
        set_property (GLOBAL
                      APPEND
                      PROPERTY GLOBAL_PROPERTY
                      ${GLOBAL_PROPERTY_VALUE})
        set_property (GLOBAL
                      APPEND
                      PROPERTY GLOBAL_PROPERTY
                      ${GLOBAL_PROPERTY_OTHER_VALUE})

        _cmake_unit_item_has_property_containing_value (GLOBAL GLOBAL
                                                        GLOBAL_PROPERTY
                                                        STRING EQUAL
                                                        ${GLOBAL_PROPERTY_VALUE}
                                                        EXPECT_EQUAL)

        _cmake_unit_item_has_property_containing_value (GLOBAL GLOBAL
                                                        GLOBAL_PROPERTY
                                                        STRING EQUAL
                                                        "something_else"
                                                        EXPECT_NOT_EQUAL)

        _cmake_unit_item_has_property_containing_value (GLOBAL GLOBAL
                                                        GLOBAL_NON_EXISTENT_PROPERTY
                                                        STRING EQUAL
                                                        ${GLOBAL_PROPERTY_VALUE}
                                                        EXPECT_DOESNT_EXIST)

        cmake_unit_assert_true (${EXPECT_EQUAL})
        cmake_unit_assert_false (${EXPECT_NOT_EQUAL})
        cmake_unit_assert_false (${EXPECT_DOESNT_EXIST})

    endfunction ()

    cmake_unit_configure_config_only_test (CONFIGURE COMMAND _cmake_unit_configure)

endfunction ()

# Check the _cmake_unit_file_exists matcher.
function (cmake_unit_test_file_exists)

    cmake_unit_get_dirs (BINARY_DIR SOURCE_DIR)

    function (_cmake_unit_configure)

        file (WRITE "${BINARY_DIR}/File" "")

        _cmake_unit_file_exists ("${BINARY_DIR}/File" FILE_EXISTS)
        _cmake_unit_file_exists ("${BINARY_DIR}/NotFile" NOT_FILE_EXISTS)

        cmake_unit_assert_true ("${FILE_EXISTS}")
        cmake_unit_assert_false ("${NOT_FILE_EXISTS}")

    endfunction ()

    cmake_unit_configure_config_only_test (CONFIGURE COMMAND _cmake_unit_configure)

endfunction ()

# Check the _cmake_unit_file_contains_substring matcher.
function (cmake_unit_test_file_contains_substring)

    cmake_unit_get_dirs (BINARY_DIR SOURCE_DIR)

    function (_cmake_unit_configure)

        set (SUBSTRING "substring")
        set (MAIN_STRING "main_${SUBSTRING}_string")

        file (WRITE "${BINARY_DIR}/File" ${MAIN_STRING})

        _cmake_unit_file_contains_substring ("${BINARY_DIR}/File"
                                             ${SUBSTRING}
                                             CONTAINING_SUBSTRING)
        _cmake_unit_file_contains_substring ("${BINARY_DIR}/File"
                                             "other_string"
                                             NOT_CONTAINING_SUBSTRING)

        cmake_unit_assert_true (${CONTAINING_SUBSTRING})
        cmake_unit_assert_false (${NOT_CONTAINING_SUBSTRING})

    endfunction ()

    cmake_unit_configure_config_only_test (CONFIGURE COMMAND _cmake_unit_configure)

endfunction ()

# Check the _cmake_unit_file_has_line_matching matcher.
function (cmake_unit_test_file_has_line_matching)

    cmake_unit_get_dirs (BINARY_DIR SOURCE_DIR)

    function (_cmake_unit_configure)

        set (SUBSTRING "substring")
        set (FOO_SUBSTRING "foo")

        set (MATCH_FOO_SUBSTRING_LINE "^.*${FOO_SUBSTRING}.*${SUBSTRING}.*$")
        set (MATCH_FOO_LINE "^.*${FOO_SUBSTRING}.*$")
        set (MATCH_SUBSTRING_LINE "^.*${SUBSTRING}.*$")

        set (MAIN_STRING_WITH_FOO "main_${FOO_SUBSTRING}_string")
        set (MAIN_STRING_WITH_SUBSTRING "main_${SUBSTRING}_string")
        set (MAIN_STRING_WITH_BOTH_INDEPENDENTLY
             "${MAIN_STRING_WITH_FOO}\n"
             "${MAIN_STRING_WITH_SUBSTRING}\n")
        set (MAIN_STRING_WITH_BOTH
             "main_${FOO_SUBSTRING}_string_${SUBSTRING}_end")
        set (MAIN_STRING_WITH_ALL
             "${MAIN_STRING_WITH_BOTH_INDEPENDENTLY}\n"
             "${MAIN_STRING_WITH_BOTH}\n")

        set (FILE_WITH_FOO "${BINARY_DIR}/FileWithFoo")
        set (FILE_WITH_BOTH_INDEPENDENTLY
             "${BINARY_DIR}/FileWithBothIndependently")
        set (FILE_WITH_BOTH "${BINARY_DIR}/FileWithBoth")
        set (FILE_WITH_ALL "${BINARY_DIR}/FileWithAll")

        file (WRITE ${FILE_WITH_FOO} ${MAIN_STRING_WITH_FOO})
        file (WRITE ${FILE_WITH_BOTH_INDEPENDENTLY}
              ${MAIN_STRING_WITH_BOTH_INDEPENDENTLY})
        file (WRITE ${FILE_WITH_BOTH} ${MAIN_STRING_WITH_BOTH})
        file (WRITE ${FILE_WITH_ALL} ${MAIN_STRING_WITH_ALL})

        _cmake_unit_file_has_line_matching (${FILE_WITH_FOO}
                                            ${MATCH_FOO_LINE}
                                            MATCH_FOO_IN_FOO)
        _cmake_unit_file_has_line_matching (${FILE_WITH_FOO}
                                            ${MATCH_FOO_SUBSTRING_LINE}
                                            NO_MATCH_SUBSTRING_IN_FOO)
        _cmake_unit_file_has_line_matching (${FILE_WITH_FOO}
                                            ${MATCH_FOO_SUBSTRING_LINE}
                                            NO_MATCH_BOTH_IN_FOO)

        _cmake_unit_file_has_line_matching (${FILE_WITH_BOTH_INDEPENDENTLY}
                                            ${MATCH_FOO_LINE}
                                            MATCH_FOO_IN_BOTH_INDEPENDENTLY)
        _cmake_unit_file_has_line_matching (${FILE_WITH_BOTH_INDEPENDENTLY}
                                            ${MATCH_SUBSTRING_LINE}
                                            MATCH_SUBSTRING_IN_BOTH_INDEPENDENTLY)
        _cmake_unit_file_has_line_matching (${FILE_WITH_BOTH_INDEPENDENTLY}
                                            ${MATCH_FOO_SUBSTRING_LINE}
                                            NO_MATCH_BOTH_IN_BOTH_INDEPENDENTLY)

        _cmake_unit_file_has_line_matching (${FILE_WITH_BOTH}
                                            ${MATCH_FOO_LINE}
                                            MATCH_FOO_IN_BOTH)
        _cmake_unit_file_has_line_matching (${FILE_WITH_BOTH}
                                            ${MATCH_SUBSTRING_LINE}
                                            MATCH_SUBSTRING_IN_BOTH)
        _cmake_unit_file_has_line_matching (${FILE_WITH_BOTH}
                                            ${MATCH_FOO_SUBSTRING_LINE}
                                            MATCH_BOTH_IN_BOTH)

        _cmake_unit_file_has_line_matching (${FILE_WITH_ALL}
                                            ${MATCH_FOO_LINE}
                                            MATCH_FOO_IN_ALL)
        _cmake_unit_file_has_line_matching (${FILE_WITH_ALL}
                                            ${MATCH_SUBSTRING_LINE}
                                            MATCH_SUBSTRING_IN_ALL)
        _cmake_unit_file_has_line_matching (${FILE_WITH_ALL}
                                            ${MATCH_FOO_SUBSTRING_LINE}
                                            MATCH_BOTH_IN_ALL)

        cmake_unit_assert_true (${MATCH_FOO_IN_FOO})
        cmake_unit_assert_false (${NO_MATCH_SUBSTRING_IN_FOO})
        cmake_unit_assert_false (${NO_MATCH_BOTH_IN_FOO})

        cmake_unit_assert_true (${MATCH_FOO_IN_BOTH_INDEPENDENTLY})
        cmake_unit_assert_true (${MATCH_SUBSTRING_IN_BOTH_INDEPENDENTLY})
        cmake_unit_assert_false (${NO_MATCH_BOTH_IN_BOTH_INDEPENDENTLY})

        cmake_unit_assert_true (${MATCH_FOO_IN_BOTH})
        cmake_unit_assert_true (${MATCH_SUBSTRING_IN_BOTH})
        cmake_unit_assert_true (${MATCH_BOTH_IN_BOTH})

        cmake_unit_assert_true (${MATCH_FOO_IN_ALL})
        cmake_unit_assert_true (${MATCH_SUBSTRING_IN_ALL})
        cmake_unit_assert_true (${MATCH_BOTH_IN_ALL})

    endfunction ()

    cmake_unit_configure_config_only_test (CONFIGURE COMMAND _cmake_unit_configure)

endfunction ()

# Check the _cmake_unit_list_contains_value matcher.
function (cmake_unit_test_list_contains_value)

    function (_cmake_unit_configure)

        set (LIST
             v
             ov)

        _cmake_unit_list_contains_value (LIST STRING EQUAL "v" CONTAINS_VALUE)
        _cmake_unit_list_contains_value (LIST STRING EQUAL "ov" CONTAINS_OTHER_VALUE)
        _cmake_unit_list_contains_value (LIST STRING EQUAL "not_in" DOESNT_CONTAIN)

        cmake_unit_assert_true (${CONTAINS_VALUE})
        cmake_unit_assert_true (${CONTAINS_OTHER_VALUE})
        cmake_unit_assert_false (${DOESNT_CONTAIN})

    endfunction ()

    cmake_unit_configure_config_only_test (CONFIGURE COMMAND _cmake_unit_configure)

endfunction ()

# Check the _cmake_unit_list_contains_value matcher with empty values
# Empty values are never stored in lists
function (cmake_unit_test_list_contains_value_empty)

    function (_cmake_unit_configure)

        set (LIST "")

        _cmake_unit_list_contains_value (LIST STRING EQUAL "" CONTAINS_VALUE)

        cmake_unit_assert_false (${CONTAINS_VALUE})

    endfunction ()

    cmake_unit_configure_config_only_test (CONFIGURE COMMAND _cmake_unit_configure)

endfunction ()

# Check that ${CMAKE_PROJECT_NAME}.trace (in this case, TestProject.trace)
# is overwritten with nothing when cmake_unit_init is called
function (cmake_unit_test_coverage_file_clobbered_on_bootstrap)

    cmake_unit_get_dirs (BINARY_DIR SOURCE_DIR)

    function (_cmake_unit_configure)

        set (CMAKE_UNIT_LOG_COVERAGE ON CACHE BOOL "" FORCE)
        set (CMAKE_UNIT_COVERAGE_FILE "${BINARY_DIR}/coverage.trace"
             CACHE STRING "" FORCE)
        file (WRITE "${CMAKE_UNIT_COVERAGE_FILE}" "Non-empty contents")
        _cmake_unit_test_gen_configure (NAMESPACE sample
                                        NAME one
                                        CONFIGURE SCRIPT
                                                  ${CONFIGURE_SCRIPT})
        # At least after the preconfigure step, the tracefile should be empty
        file (READ "${CMAKE_UNIT_COVERAGE_FILE}" TRACE_FILE_CONTENTS)
        cmake_unit_assert_variable_is (TRACE_FILE_CONTENTS STRING EQUAL "")

    endfunction ()

    cmake_unit_configure_config_only_test (CONFIGURE COMMAND _cmake_unit_configure)

endfunction ()

# Ensure that ${CMAKE_CURRENT_BINARY_DIR}/${TEST_NAME}/${TEST_NAME}Driver.cmake
# is written out after cmake_unit_configure_test
function (cmake_unit_test_driver_script_written_after_test_added)

    cmake_unit_get_dirs (BINARY_DIR SOURCE_DIR)

    function (_cmake_unit_configure)

        _cmake_unit_test_gen_configure (NAMESPACE sample
                                        NAME one)

    endfunction ()

    function (_cmake_unit_verify)

        set (DRIVER_FILE "${BINARY_DIR}/sample_test_one/Driver.cmake")
        cmake_unit_assert_file_exists ("${DRIVER_FILE}")

    endfunction ()

    cmake_unit_configure_test (CONFIGURE COMMAND _cmake_unit_configure
                               VERIFY COMMAND _cmake_unit_verify)

endfunction ()

# Check that a source file by the name Source.cpp was created in
# ${CMAKE_CURRENT_SOURCE_DIR} when we call
# cmake_unit_create_source_file_before_build
function (cmake_unit_test_source_file_created_before_build_exists)

    cmake_unit_get_dirs (BINARY_DIR SOURCE_DIR)

    function (_cmake_unit_configure)

        cmake_unit_create_source_file_before_build ()

        cmake_unit_assert_file_exists ("${SOURCE_DIR}/Source.cpp")

    endfunction ()

    cmake_unit_configure_config_only_test (CONFIGURE COMMAND _cmake_unit_configure)

endfunction ()

# Check that a source file by the name CustomName.cpp was created in
# ${CMAKE_CURRENT_SOURCE_DIR} when we call
# cmake_unit_create_source_file_before_build with NAME
function (cmake_unit_test_source_file_created_before_build_with_custom_name)

    cmake_unit_get_dirs (BINARY_DIR SOURCE_DIR)

    function (_cmake_unit_configure)

        cmake_unit_create_source_file_before_build (NAME "CustomName.cpp")

        cmake_unit_assert_file_exists ("${SOURCE_DIR}/CustomName.cpp")

    endfunction ()

    cmake_unit_configure_config_only_test (CONFIGURE COMMAND _cmake_unit_configure)

endfunction ()

# Check that a source file by the name Source.cpp was created in
# ${CMAKE_CURRENT_SOURCE_DIR} with #define CUSTOM_DEFINE when we call
# cmake_unit_create_source_file_before_build with DEFINES CUSTOM_DEFINE
function (cmake_unit_test_source_file_created_before_build_with_defines)

    cmake_unit_get_dirs (BINARY_DIR SOURCE_DIR)

    function (_cmake_unit_configure)

        cmake_unit_create_source_file_before_build (DEFINES "CUSTOM_DEFINE")

        set (SOURCE_FILE "${SOURCE_DIR}/Source.cpp")
        cmake_unit_assert_file_has_line_matching ("${SOURCE_FILE}"
                                                  "^.define CUSTOM_DEFINE$")

    endfunction ()

    cmake_unit_configure_config_only_test (CONFIGURE COMMAND _cmake_unit_configure)

endfunction ()

# Check that a source file by the name Source.cpp was created in
# ${CMAKE_CURRENT_SOURCE_DIR} with #include "my_include.h" when we call
# cmake_unit_create_source_file_before_build with INCLUDES my_include.h
function (cmake_unit_test_source_file_created_before_build_with_includes)

    cmake_unit_get_dirs (BINARY_DIR SOURCE_DIR)

    function (_cmake_unit_configure)

        cmake_unit_create_source_file_before_build (INCLUDES my_include.h)

        set (SOURCE_FILE "${SOURCE_DIR}/Source.cpp")
        cmake_unit_assert_file_has_line_matching ("${SOURCE_FILE}"
                                                  "^.include \"my_include.h\"$")

    endfunction ()

    cmake_unit_configure_config_only_test (CONFIGURE COMMAND _cmake_unit_configure)

endfunction ()

# Check that a source file by the name Source.cpp was created in
# ${CMAKE_CURRENT_SOURCE_DIR} with #include <include/my_include.h> when we call
# cmake_unit_create_source_file_before_build with
# INCLUDES ${CMAKE_CURRENT_SOURCE_DIR}/include/my_include.h
# and INCLUDE_DIRECTORIES ${CMAKE_CURRENT_SOURCE_DIR}
function (cmake_unit_test_source_file_created_before_build_with_includes_inside_inc_dir)

    cmake_unit_get_dirs (BINARY_DIR SOURCE_DIR)

    function (_cmake_unit_configure)

        set (INCLUDE_DIRECTORY "${SOURCE_DIR}")
        set (MY_INCLUDE "${INCLUDE_DIRECTORY}/include/my_include.h")
        cmake_unit_create_source_file_before_build (INCLUDES
                                                    "${MY_INCLUDE}"
                                                    INCLUDE_DIRECTORIES
                                                    "${INCLUDE_DIRECTORY}")

        set (SOURCE_FILE "${SOURCE_DIR}/Source.cpp")
        cmake_unit_assert_file_has_line_matching ("${SOURCE_FILE}"
                                                  "^.include <include/my_include.h>$")

    endfunction ()

    cmake_unit_configure_config_only_test (CONFIGURE COMMAND _cmake_unit_configure)

endfunction ()

# Check that a source file by the name Source.cpp was created in
# ${CMAKE_CURRENT_SOURCE_DIR} with specified prepended contents
# (after defines and includes)
function (cmake_unit_test_source_file_created_before_build_has_prepended_contents)

    cmake_unit_get_dirs (BINARY_DIR SOURCE_DIR)

    function (_cmake_unit_configure)

        set (PREPEND_CONTENTS_INPUT "static int i@SEMICOLON@")
        cmake_unit_create_source_file_before_build (PREPEND_CONTENTS
                                                    "${PREPEND_CONTENTS_INPUT}")

        set (SOURCE_FILE "${SOURCE_DIR}/Source.cpp")
        cmake_unit_assert_file_has_line_matching ("${SOURCE_FILE}" "^static int i.$")

    endfunction ()

    cmake_unit_configure_config_only_test (CONFIGURE COMMAND _cmake_unit_configure)

endfunction ()

# Check that a source file by the name Source.cpp was created in
# ${CMAKE_CURRENT_SOURCE_DIR} with a declaration like
# int custom_function (); when we call
# cmake_unit_create_source_file_before_build with FUNCTIONS custom_function
function (cmake_unit_test_source_file_created_before_build_with_function_decls)

    cmake_unit_get_dirs (BINARY_DIR SOURCE_DIR)

    function (_cmake_unit_configure)

        cmake_unit_create_source_file_before_build (FUNCTIONS custom_function)

        set (SOURCE_FILE "${SOURCE_DIR}/Source.cpp")
        cmake_unit_assert_file_has_line_matching ("${SOURCE_FILE}"
                                                  "^int custom_function ...$")

    endfunction ()

    cmake_unit_configure_config_only_test (CONFIGURE COMMAND _cmake_unit_configure)

endfunction ()

# Check that a source file by the name Source.cpp was created in
# ${CMAKE_CURRENT_SOURCE_DIR} with a definition like
# int custom_function ()\n{\n    return 0;\n} when we call
# cmake_unit_create_source_file_before_build with FUNCTIONS custom_function
function (cmake_unit_test_source_file_created_before_build_with_function_defs)

    cmake_unit_get_dirs (BINARY_DIR SOURCE_DIR)

    function (_cmake_unit_configure)

        cmake_unit_create_source_file_before_build (FUNCTIONS custom_function)

        set (SOURCE_FILE "${SOURCE_DIR}/Source.cpp")
        cmake_unit_assert_file_has_line_matching ("${SOURCE_FILE}"
                                                  "^.*return 0.*$")

    endfunction ()

    cmake_unit_configure_config_only_test (INVOKE_CONFIGURE LANGUAGES C CXX
                                           CONFIGURE COMMAND _cmake_unit_configure)

endfunction ()

# Check that a source file by the name Header.h was created in
# ${CMAKE_CURRENT_SOURCE_DIR} but does not contain a definition like
# int custom_function ()\n{\n    return 1;\n} when we call
# cmake_unit_create_source_file_before_build with FUNCTIONS custom_function
function (cmake_unit_test_source_file_created_before_build_no_function_defs_if_header)

    cmake_unit_get_dirs (BINARY_DIR SOURCE_DIR)

    function (_cmake_unit_configure)

        cmake_unit_create_source_file_before_build (NAME "Header.h"
                                                    FUNCTIONS custom_function)

        set (HEADER_FILE "${SOURCE_DIR}/Header.h")
        cmake_unit_assert_file_does_not_have_line_matching ("${HEADER_FILE}"
                                                            "^.*return 1.*$")

    endfunction ()

    cmake_unit_configure_config_only_test (CONFIGURE COMMAND _cmake_unit_configure)

endfunction ()

# Check that a source file by the name Header.h was created in
# ${CMAKE_CURRENT_SOURCE_DIR} and contains header guards like
# #ifdef HEADER_H
# #define HEADER_H
# ...
# #endif
function (cmake_unit_test_source_file_created_before_build_header_guards_if_header)

    cmake_unit_get_dirs (BINARY_DIR SOURCE_DIR)

    function (_cmake_unit_configure)

        cmake_unit_create_source_file_before_build (NAME "Header.h"
                                                    PREPEND_CONTENTS
                                                    "int foo@SEMICOLON@")

        cmake_unit_assert_file_has_line_matching ("${SOURCE_DIR}/Header.h"
                                                  "^.*ifndef HEADER_H")
        cmake_unit_assert_file_has_line_matching ("${SOURCE_DIR}/Header.h"
                                                  "^.*define HEADER_H")
        cmake_unit_assert_file_has_line_matching ("${SOURCE_DIR}/Header.h"
                                                  "^.*endif")

    endfunction ()

    cmake_unit_configure_config_only_test (CONFIGURE COMMAND _cmake_unit_configure)

endfunction ()

# A macro between tests to copy in a common "covered file"
# and run CMakeTraceToLCov on it. Assertions are then made
# based on that file. This macro sets variables which are read
# in the parent scope, so keep it as a macro.
macro (_cmake_unit_test_run_trace_to_lcov)

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

endmacro ()

# Check that lines starting with a "#" are not executable
# with CMakeTraceToLCov
function (cmake_unit_test_lines_starting_with_comment_not_executable)

    function (_cmake_unit_configure)

        _cmake_unit_test_run_trace_to_lcov ()

        set (EXECUTABLE_LINES_VARIABLE
             "_${FILE_FOR_COVERAGE_LOCAL_PATH}_EXECUTABLE_LINES")
        cmake_unit_assert_list_does_not_contain_value ("${EXECUTABLE_LINES_VARIABLE}"
                                                       STRING EQUAL "1")
        cmake_unit_assert_file_does_not_have_line_matching ("${LCOV_OUTPUT}" "^DA:1$")

    endfunction ()

    cmake_unit_configure_config_only_test (CONFIGURE COMMAND _cmake_unit_configure)

endfunction ()

# Check that lines starting with a "\n" or just whitespace are not executable
# with CMakeTraceToLCov
function (cmake_unit_test_lines_with_no_content_not_executable)

    function (_cmake_unit_configure)

        _cmake_unit_test_run_trace_to_lcov ()

        set (EXECUTABLE_LINES_VARIABLE
             "_${FILE_FOR_COVERAGE_LOCAL_PATH}_EXECUTABLE_LINES")
        cmake_unit_assert_list_does_not_contain_value ("${EXECUTABLE_LINES_VARIABLE}"
                                                       STRING EQUAL "7")
        cmake_unit_assert_list_does_not_contain_value ("${EXECUTABLE_LINES_VARIABLE}"
                                                       STRING EQUAL "10")

        cmake_unit_assert_file_does_not_have_line_matching ("${LCOV_OUTPUT}" "^DA:7$")
        cmake_unit_assert_file_does_not_have_line_matching ("${LCOV_OUTPUT}" "^DA:10$")

    endfunction ()

    cmake_unit_configure_config_only_test (CONFIGURE COMMAND _cmake_unit_configure)

endfunction ()

# Check that lines starting with ".*end" are not executable
function (cmake_unit_test_lines_starting_with_end_not_executable)

    function (_cmake_unit_configure)

        _cmake_unit_test_run_trace_to_lcov ()

        set (EXECUTABLE_LINES_VARIABLE
             "_${FILE_FOR_COVERAGE_LOCAL_PATH}_EXECUTABLE_LINES")
        cmake_unit_assert_list_does_not_contain_value ("${EXECUTABLE_LINES_VARIABLE}"
                                                       STRING EQUAL "3")
        cmake_unit_assert_list_does_not_contain_value ("${EXECUTABLE_LINES_VARIABLE}"
                                                       STRING EQUAL "19")
        cmake_unit_assert_list_does_not_contain_value ("${EXECUTABLE_LINES_VARIABLE}"
                                                       STRING EQUAL "28")
        cmake_unit_assert_list_does_not_contain_value ("${EXECUTABLE_LINES_VARIABLE}"
                                                       STRING EQUAL "34")
        cmake_unit_assert_list_does_not_contain_value ("${EXECUTABLE_LINES_VARIABLE}"
                                                       STRING EQUAL "36")

        cmake_unit_assert_file_does_not_have_line_matching ("${LCOV_OUTPUT}" "^DA:3$")
        cmake_unit_assert_file_does_not_have_line_matching ("${LCOV_OUTPUT}" "^DA:19$")
        cmake_unit_assert_file_does_not_have_line_matching ("${LCOV_OUTPUT}" "^DA:28$")
        cmake_unit_assert_file_does_not_have_line_matching ("${LCOV_OUTPUT}" "^DA:34$")
        cmake_unit_assert_file_does_not_have_line_matching ("${LCOV_OUTPUT}" "^DA:36$")

    endfunction ()

    cmake_unit_configure_config_only_test (CONFIGURE COMMAND _cmake_unit_configure)

endfunction ()

# Check that lines overflowing after an intial open-brace are not executable
# until the brace is closed on the end of the line
function (cmake_unit_test_lines_until_close_bracket_not_executable)

    function (_cmake_unit_configure)

        _cmake_unit_test_run_trace_to_lcov ()

        set (EXECUTABLE_LINES_VARIABLE
             "_${FILE_FOR_COVERAGE_LOCAL_PATH}_EXECUTABLE_LINES")
        cmake_unit_assert_list_does_not_contain_value ("${EXECUTABLE_LINES_VARIABLE}"
                                                       STRING EQUAL "6")
        cmake_unit_assert_list_does_not_contain_value ("${EXECUTABLE_LINES_VARIABLE}"
                                                       STRING EQUAL "22")

        cmake_unit_assert_file_does_not_have_line_matching ("${LCOV_OUTPUT}" "^DA:6$")
        cmake_unit_assert_file_does_not_have_line_matching ("${LCOV_OUTPUT}" "^DA:22$")

    endfunction ()

    cmake_unit_configure_config_only_test (CONFIGURE COMMAND _cmake_unit_configure)

endfunction ()

# Check that lines overflowing after an intial open-brace are not executable
# until the brace is closed on the end of the line
function (cmake_unit_test_interleaved_comments_until_close_bracket_not_executable)

    function (_cmake_unit_configure)

        _cmake_unit_test_run_trace_to_lcov ()

        set (EXECUTABLE_LINES_VARIABLE
             "_${FILE_FOR_COVERAGE_LOCAL_PATH}_EXECUTABLE_LINES")
        cmake_unit_assert_list_does_not_contain_value ("${EXECUTABLE_LINES_VARIABLE}"
                                                       STRING EQUAL "39")
        cmake_unit_assert_list_does_not_contain_value ("${EXECUTABLE_LINES_VARIABLE}"
                                                       STRING EQUAL "40")
        cmake_unit_assert_list_does_not_contain_value ("${EXECUTABLE_LINES_VARIABLE}"
                                                       STRING EQUAL "41")
        cmake_unit_assert_list_does_not_contain_value ("${EXECUTABLE_LINES_VARIABLE}"
                                                       STRING EQUAL "42")

        cmake_unit_assert_file_does_not_have_line_matching ("${LCOV_OUTPUT}" "^DA:39$")
        cmake_unit_assert_file_does_not_have_line_matching ("${LCOV_OUTPUT}" "^DA:40$")
        cmake_unit_assert_file_does_not_have_line_matching ("${LCOV_OUTPUT}" "^DA:41$")
        cmake_unit_assert_file_does_not_have_line_matching ("${LCOV_OUTPUT}" "^DA:42$")

    endfunction ()

    cmake_unit_configure_config_only_test (CONFIGURE COMMAND _cmake_unit_configure)

endfunction ()

# Check that semicolons in the middle of the file don't cause extra lines to be
# added (such that we get a bogus line report from CMakeTraceToLCov)
function (cmake_unit_test_semicolons_dont_break_lines)

    function (_cmake_unit_configure)

        _cmake_unit_test_run_trace_to_lcov ()

        set (EXECUTABLE_LINES_VARIABLE
             "_${FILE_FOR_COVERAGE_LOCAL_PATH}_EXECUTABLE_LINES")
        cmake_unit_assert_list_does_not_contain_value ("${EXECUTABLE_LINES_VARIABLE}"
                                                       STRING EQUAL "15")

        cmake_unit_assert_file_does_not_have_line_matching ("${LCOV_OUTPUT}" "^DA:15$")

    endfunction ()

    cmake_unit_configure_config_only_test (CONFIGURE COMMAND _cmake_unit_configure)

endfunction ()

# Check that \n in the middle of the line don't cause extra lines to be
# added (such that we get a bogus line report from CMakeTraceToLCov)
function (cmake_unit_test_slash_n_doesnt_break_lines)

    function (_cmake_unit_configure)

        _cmake_unit_test_run_trace_to_lcov ()

        set (EXECUTABLE_LINES_VARIABLE
             "_${FILE_FOR_COVERAGE_LOCAL_PATH}_EXECUTABLE_LINES")
        cmake_unit_assert_list_does_not_contain_value ("${EXECUTABLE_LINES_VARIABLE}"
                                                       STRING EQUAL "17")

        cmake_unit_assert_file_does_not_have_line_matching ("${LCOV_OUTPUT}" "^DA:17$")

    endfunction ()

    cmake_unit_configure_config_only_test (CONFIGURE COMMAND _cmake_unit_configure)

endfunction ()

# All files, eg
# - FileForCoverage.cmake
# - UnexecutedFileForCoverage.cmake
# Have coverage information
function (cmake_unit_test_all_files_specified_in_trace_file_have_coverage)

    function (_cmake_unit_configure)

        _cmake_unit_test_run_trace_to_lcov ()

        cmake_unit_assert_file_has_line_matching ("${LCOV_OUTPUT}"
                                                  "^SF:.*FileForCoverage.*$")
        cmake_unit_assert_file_has_line_matching ("${LCOV_OUTPUT}"
                                                  "^SF:.*UnexecutedFileForCoverage.*$")

    endfunction ()

    cmake_unit_configure_config_only_test (CONFIGURE COMMAND _cmake_unit_configure)

endfunction ()

# Anything else not part of an exclusionary rule should be marked executable.
function (cmake_unit_test_other_lines_executable)

    function (_cmake_unit_configure)

        _cmake_unit_test_run_trace_to_lcov ()

        set (EXECUTABLE_LINES_VARIABLE
             "_${FILE_FOR_COVERAGE_LOCAL_PATH}_EXECUTABLE_LINES")
        cmake_unit_assert_list_contains_value ("${EXECUTABLE_LINES_VARIABLE}"
                                               STRING EQUAL "2")
        cmake_unit_assert_list_contains_value ("${EXECUTABLE_LINES_VARIABLE}"
                                               STRING EQUAL "5")
        cmake_unit_assert_list_contains_value ("${EXECUTABLE_LINES_VARIABLE}"
                                               STRING EQUAL "11")
        cmake_unit_assert_list_contains_value ("${EXECUTABLE_LINES_VARIABLE}"
                                               STRING EQUAL "13")
        cmake_unit_assert_list_contains_value ("${EXECUTABLE_LINES_VARIABLE}"
                                               STRING EQUAL "14")
        cmake_unit_assert_list_contains_value ("${EXECUTABLE_LINES_VARIABLE}"
                                               STRING EQUAL "21")
        cmake_unit_assert_list_contains_value ("${EXECUTABLE_LINES_VARIABLE}"
                                               STRING EQUAL "24")
        cmake_unit_assert_list_contains_value ("${EXECUTABLE_LINES_VARIABLE}"
                                               STRING EQUAL "26")
        cmake_unit_assert_list_contains_value ("${EXECUTABLE_LINES_VARIABLE}"
                                               STRING EQUAL "30")
        cmake_unit_assert_list_contains_value ("${EXECUTABLE_LINES_VARIABLE}"
                                               STRING EQUAL "32")

    endfunction ()

    cmake_unit_configure_config_only_test (CONFIGURE COMMAND _cmake_unit_configure)

endfunction ()

# All hit-and-executable lines have a DA counter of > 0.
function (cmake_unit_test_hit_lines_have_non_zero_d_a_counter)

    function (_cmake_unit_configure)

        _cmake_unit_test_run_trace_to_lcov ()

        cmake_unit_assert_file_has_line_matching ("${LCOV_OUTPUT}" "^DA:2,1$")
        cmake_unit_assert_file_has_line_matching ("${LCOV_OUTPUT}" "^DA:5,1$")
        cmake_unit_assert_file_has_line_matching ("${LCOV_OUTPUT}" "^DA:11,1$")
        cmake_unit_assert_file_has_line_matching ("${LCOV_OUTPUT}" "^DA:13,1$")
        cmake_unit_assert_file_has_line_matching ("${LCOV_OUTPUT}" "^DA:14,1$")
        cmake_unit_assert_file_has_line_matching ("${LCOV_OUTPUT}" "^DA:16,1$")
        cmake_unit_assert_file_has_line_matching ("${LCOV_OUTPUT}" "^DA:21,1$")
        cmake_unit_assert_file_has_line_matching ("${LCOV_OUTPUT}" "^DA:24,1$")
        cmake_unit_assert_file_has_line_matching ("${LCOV_OUTPUT}" "^DA:26,1$")
        cmake_unit_assert_file_has_line_matching ("${LCOV_OUTPUT}" "^DA:30,1$")

    endfunction ()

    cmake_unit_configure_config_only_test (CONFIGURE COMMAND _cmake_unit_configure)

endfunction ()

# All missed-but-executable lines have a DA counter of zero.
function (cmake_unit_test_missed_lines_have_non_zero_d_a_counter)

    function (_cmake_unit_configure)

        _cmake_unit_test_run_trace_to_lcov ()

        cmake_unit_assert_file_has_line_matching ("${LCOV_OUTPUT}" "^DA:32,0$")

    endfunction ()

    cmake_unit_configure_config_only_test (CONFIGURE COMMAND _cmake_unit_configure)

endfunction ()

cmake_unit_init (NAMESPACE "cmake_unit"
                 COVERAGE_FILES
                 "${CMAKE_UNIT_DIRECTORY}/CMakeUnitRunner.cmake"
                 "${CMAKE_UNIT_DIRECTORY}/CMakeTraceToLCov.cmake"
                 "${CMAKE_UNIT_DIRECTORY}/CMakeUnit.cmake")
