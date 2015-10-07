# /CMakeLists.txt
#
# Main entry point for the cmake-unit tests.
#
# See /LICENCE.md for Copyright information

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

set (TESTS_LIST_DIR "${CMAKE_CURRENT_LIST_DIR}/tests")
set (CMAKE_MODULE_PATH "${CMAKE_CURRENT_LIST_DIR};${CMAKE_MODULE_PATH}")

# Set up variables to forward
set (MOCK_TRACEFILE_INPUT
     "${TESTS_LIST_DIR}/TestProjectMockTracefile.trace.in")
set (FILE_FOR_COVERAGE_PATH "${TESTS_LIST_DIR}/FileForCoverage.cmake")
set (UNEXECUTED_FILE_FOR_COVERAGE_PATH
     "${TESTS_LIST_DIR}/UnexecutedFileForCoverage.cmake")

set (_CURRENT_LIST_FILE "${CMAKE_CURRENT_LIST_FILE}")

include (CMakeUnitRunner)

function (_cmake_unit_test_gen_configure_no_discover RETURN_AUX_CMAKELISTS)

    set (PHASE_TYPES CLEAN
                     PRECONFIGURE
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
         "if (_CMAKE_UNIT_PHASE STREQUAL \"RM_BUILD\")\n"
         "    set (CMAKE_UNIT_PRESERVE_BUILD_ON_COMPLETION TRUE)\n"
         "endif ()\n"
         "function (${GEN_CONFIGURE_NAMESPACE}_test_${GEN_CONFIGURE_NAME})\n")
    set (TEST_CONFIGURATION "")

    foreach (PHASE_TYPE ${PHASE_TYPES})

        set (PHASE_ARGUMENTS ${GEN_CONFIGURE_${PHASE_TYPE}})

        # Work around a strange cmakelint bug
        set (END "end")

        # We have options for our phase, now parse those options into the
        # script itself and all its other options to be passed as part
        # of the configuration
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
          "${END}function ()\n"
          "set (CMAKE_UNIT_PRESERVE_BUILD_ON_COMPLETION ON)\n")

    set (${RETURN_AUX_CMAKELISTS} ${AUX_CMAKELISTS_FILE_CONTENTS} PARENT_SCOPE)

endfunction ()

function (_cmake_unit_test_gen_discover_from_contents)

    # Overrides variables when including /AuxCMakeLists.txt
    set (_CMAKE_UNIT_PHASE PRECONFIGURE)  # NOLINT:unused/var_in_func
    unset (_CMAKE_UNIT_ACTIVE_TEST)  # NOLINT:unused/var_in_func

    set (CMAKE_MODULE_PATH "${CMAKE_UNIT_DIRECTORY}" "${CMAKE_MODULE_PATH}")

    set (GEN_DISCOVER_SINGLEVAR_ARGS NAMESPACE NAME COVERAGE_FILE)
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

    # Ensure everything in INIT_OPTIONS is quoted so that
    # there is no ambiguity when we insert it into the
    # /AuxCMakeLists.txt script later.
    foreach (OPTION ${INIT_OPTIONS})
        list (APPEND QUOTED_INIT_OPTIONS "\"${OPTION}\"")
    endforeach ()
    string (REPLACE ";" " " INIT_OPTIONS "${QUOTED_INIT_OPTIONS}")

    list (APPEND AUX_CMAKELISTS_FILE_CONTENTS
          "set (NEXT_TESTS)\n"
          "set (CMAKE_UNIT_PARENT_BINARY_DIR\n"
          "     \"${CMAKE_CURRENT_BINARY_DIR}\")\n"
          "set (_CMAKE_UNIT_INTERNAL_TESTING ON CACHE BOOL \"\" FORCE)\n"
          "cmake_unit_init (NAMESPACE \"${GEN_DISCOVER_NAMESPACE}\"\n"
          "                 ${INIT_OPTIONS})\n")

    file (WRITE "${AUX_CMAKELISTS_FILE}"
          ${AUX_CMAKELISTS_FILE_CONTENTS})

    # If a coverage file was specified, we want to log coverage for these
    # inner-tests. Set CMAKE_UNIT_COVERAGE_FILE as such. Otherwise,
    # must should set CMAKE_UNIT_COVERAGE_FILE to an empty string, such
    # that it will not be clobbered by running this inner test.
    if (GEN_DISCOVER_COVERAGE_FILE)

        set (CMAKE_UNIT_COVERAGE_FILE "${GEN_DISCOVER_COVERAGE_FILE}"
             CACHE STRING "" FORCE)

    else ()

        set (CMAKE_UNIT_COVERAGE_FILE "" CACHE STRING "" FORCE)

    endif ()

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

        set (TEST_OUTPUT_REGEX "^.*Start.*sample_test_one.*$")

        cmake_unit_get_log_for (INVOKE_TEST OUTPUT TEST_OUTPUT)
        cmake_unit_assert_that ("${TEST_OUTPUT}" file_contents any_line
                                matches_regex "${TEST_OUTPUT_REGEX}")

    endfunction ()

    cmake_unit_configure_test (CONFIGURE COMMAND _cmake_unit_configure
                               VERIFY COMMAND _cmake_unit_verify)

endfunction ()

# Check that where we call cmake_unit_configure_test and pass
# the current generator to SKIP_GENERATOR_REGEX that the test is skipped
function (cmake_unit_test_cmake_test_not_added_where_skipping_generator)

    function (_cmake_unit_configure)

        _cmake_unit_test_gen_configure (NAMESPACE sample
                                        NAME one
                                        PRECONFIGURE OPTIONS
                                                     SKIP_GENERATOR_REGEX
                                                     "${CMAKE_GENERATOR}"
                                                     "AnotherGenerator")

    endfunction ()

    function (_cmake_unit_verify)

        set (TEST_OUTPUT_REGEX "^.*Start.*sample_test_one.*$")

        cmake_unit_get_log_for (INVOKE_TEST OUTPUT TEST_OUTPUT)
        cmake_unit_assert_that ("${TEST_OUTPUT}" not file_contents any_line
                                matches_regex "${TEST_OUTPUT_REGEX}")

    endfunction ()

    cmake_unit_configure_test (CONFIGURE COMMAND _cmake_unit_configure
                               VERIFY COMMAND _cmake_unit_verify)

endfunction ()

# Check that where we call cmake_unit_configure_test and pass
# the an unknown generator to SKIP_GENERATOR_REGEX that the test is
# not skipped.
function (cmake_unit_test_cmake_test_added_where_not_skipping_generator)

    function (_cmake_unit_configure)

        _cmake_unit_test_gen_configure (NAMESPACE sample
                                        NAME one
                                        PRECONFIGURE OPTIONS
                                                     SKIP_GENERATOR_REGEX
                                                     "AnotherGenerator")

    endfunction ()

    function (_cmake_unit_verify)

        set (TEST_OUTPUT_REGEX "^.*Start.*sample_test_one.*$")

        cmake_unit_get_log_for (INVOKE_TEST OUTPUT TEST_OUTPUT)
        cmake_unit_assert_that ("${TEST_OUTPUT}" file_contents any_line
                                matches_regex "${TEST_OUTPUT_REGEX}")

    endfunction ()

    cmake_unit_configure_test (CONFIGURE COMMAND _cmake_unit_configure
                               VERIFY COMMAND _cmake_unit_verify)

endfunction ()

# Check that where we call cmake_unit_configure_test and pass
# the current system to SKIP_GENERATOR_REGEX that the test is skipped
function (cmake_unit_test_cmake_test_not_added_where_skipping_system)

    function (_cmake_unit_configure)

        _cmake_unit_test_gen_configure (NAMESPACE sample
                                        NAME one
                                        PRECONFIGURE OPTIONS
                                                     SKIP_SYSTEM_REGEX
                                                     "${CMAKE_SYSTEM}"
                                                     "AnotherSystem")

    endfunction ()

    function (_cmake_unit_verify)

        set (TEST_OUTPUT_REGEX "^.*Start.*sample_test_one.*$")

        cmake_unit_get_log_for (INVOKE_TEST OUTPUT TEST_OUTPUT)
        cmake_unit_assert_that ("${TEST_OUTPUT}" not file_contents any_line
                                matches_regex "${TEST_OUTPUT_REGEX}")

    endfunction ()

    cmake_unit_configure_test (CONFIGURE COMMAND _cmake_unit_configure
                               VERIFY COMMAND _cmake_unit_verify)

endfunction ()

# Check that where we call cmake_unit_configure_test and pass
# the an unknown system to SKIP_SYSTEM_REGEX that the test is
# not skipped.
function (cmake_unit_test_cmake_test_added_where_not_skipping_generator)

    function (_cmake_unit_configure)

        _cmake_unit_test_gen_configure (NAMESPACE sample
                                        NAME one
                                        PRECONFIGURE OPTIONS
                                                     SKIP_SYSTEM_REGEX
                                                     "AnotherSystem")

    endfunction ()

    function (_cmake_unit_verify)

        set (TEST_OUTPUT_REGEX "^.*Start.*sample_test_one.*$")

        cmake_unit_get_log_for (INVOKE_TEST OUTPUT TEST_OUTPUT)
        cmake_unit_assert_that ("${TEST_OUTPUT}" file_contents any_line
                                matches_regex "${TEST_OUTPUT_REGEX}")

    endfunction ()

    cmake_unit_configure_test (CONFIGURE COMMAND _cmake_unit_configure
                               VERIFY COMMAND _cmake_unit_verify)

endfunction ()

# Check that where we use the Ninja generator, the verbose option is
# passed.
function (cmake_unit_test_verbose_option_passed_to_ninja_generator)

    function (_cmake_unit_configure)

        set (CMAKE_LAST_GENERATOR "${CMAKE_GENERATOR}")
        set (CMAKE_GENERATOR "Ninja")
        _cmake_unit_test_gen_configure (NAMESPACE sample
                                        NAME one)
        set (CMAKE_GENERATOR "${CMAKE_LAST_GENERATOR}")


    endfunction ()

    function (_cmake_unit_verify)

        set (TEST_OUTPUT_REGEX "^.*cmake.*--build.*--.*-v.*$")

        cmake_unit_get_log_for (INVOKE_TEST OUTPUT TEST_OUTPUT)
        cmake_unit_assert_that ("${TEST_OUTPUT}" file_contents any_line
                                matches_regex "${TEST_OUTPUT_REGEX}")

    endfunction ()

    cmake_unit_configure_test (CONFIGURE COMMAND _cmake_unit_configure
                               VERIFY COMMAND _cmake_unit_verify)

endfunction ()

# Check that where we have a test matching the test pattern in /CMakeLists.txt
# that calling cmake_unit_configure_test actually adds a test and that the build
# output indicates that we've built, tested and verified sample too
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

        cmake_unit_assert_that ("${TEST_OUTPUT}" file_contents any_line
                                matches_regex
                                "^.*Star.*sample_test_one.*$")
        set (CMAKE_BUILD_REGEX "^.*${ESC_CMAKE_COMMAND}[ \"]+--build.*$")
        cmake_unit_assert_that ("${TEST_OUTPUT}" file_contents any_line
                                matches_regex
                                "${CMAKE_BUILD_REGEX}")
        set (CMAKE_TEST_REGEX "^.*${ESC_CMAKE_TEST_COMMAND}.*$")
        cmake_unit_assert_that ("${TEST_OUTPUT}" file_contents any_line
                                matches_regex
                                "${CMAKE_TEST_REGEX}")
        cmake_unit_assert_that ("${TEST_OUTPUT}" file_contents any_line
                                matches_regex "^.*Ran.*$")

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
        cmake_unit_assert_that ("${TEST_OUTPUT}" file_contents any_line
                                matches_regex
                                "^.*CMake Error.*$")
        cmake_unit_assert_that ("${TEST_OUTPUT}" file_contents any_line
                                matches_regex
                                "^.*${ESC_CMAKE_COMMAND}.*$")
        cmake_unit_assert_that ("${TEST_OUTPUT}" file_contents any_line
                                matches_regex
                                "^.*failed.*$")
        cmake_unit_assert_that ("${TEST_OUTPUT}" file_contents any_line
                                matches_regex
                                "^.*1.*$")

    endfunction ()

    cmake_unit_configure_test (CONFIGURE COMMAND _cmake_unit_configure
                               INVOKE_TEST ALLOW_FAIL
                               VERIFY COMMAND _cmake_unit_verify)

endfunction ()

# Don't error out on _cmake_unit_configure fail if failure is allowed
function (cmake_unit_test_cmake_build_test_no_error_where_config_fail_allowed)

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
        cmake_unit_assert_that ("${TEST_OUTPUT}" not file_contents any_line
                                matches_regex
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
        cmake_unit_write_if_newer ("${SOURCE}" "${_CURRENT_LIST_FILE}"
                                   "invalid(")

        set (CONFIGURE_SCRIPT "add_executable (exec \"${SOURCE}\")\n")
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
        cmake_unit_assert_that ("${TEST_OUTPUT}" file_contents any_line
                                matches_regex
                                "^.*CMake Error.*$")
        cmake_unit_assert_that ("${TEST_OUTPUT}" file_contents any_line
                                matches_regex
                                "^.*${ESC_CMAKE_COMMAND}.*$")
        cmake_unit_assert_that ("${TEST_OUTPUT}" file_contents any_line
                                matches_regex
                                "^.*--build.*$")
        cmake_unit_assert_that ("${TEST_OUTPUT}" file_contents any_line
                                matches_regex
                                "^.*failed.*$")
        cmake_unit_assert_that ("${TEST_OUTPUT}" file_contents any_line
                                matches_regex
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

        cmake_unit_escape_string ("${CMAKE_CTEST_COMMAND}"
                                  ESCAPED_CTEST_COMMAND)
        set (ESCAPED_CTEST_REGEX "^.*${ESCAPED_CTEST_COMMAND}.*$")

        cmake_unit_get_log_for (INVOKE_TEST OUTPUT TEST_OUTPUT)
        cmake_unit_assert_that ("${TEST_OUTPUT}" file_contents any_line
                                matches_regex
                                "^.*CMake Error.*$")
        cmake_unit_assert_that ("${TEST_OUTPUT}" file_contents any_line
                                matches_regex
                                "${ESCAPED_CTEST_REGEX}")
        cmake_unit_assert_that ("${TEST_OUTPUT}" file_contents any_line
                                matches_regex
                                "^.*failed.*$")
        cmake_unit_assert_that ("${TEST_OUTPUT}" file_contents any_line
                                matches_regex
                                "^.*1.*$")

    endfunction ()

    cmake_unit_configure_test (CONFIGURE COMMAND _cmake_unit_configure
                               INVOKE_TEST ALLOW_FAIL
                               VERIFY COMMAND _cmake_unit_verify)

endfunction ()

# Add a build test that will fail to test, but don't fail because ALLOW_FAIL
# was specified for the test step.
function (cmake_unit_test_cmake_build_test_no_error_where_test_fail_allowed)

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
        cmake_unit_assert_that ("${TEST_OUTPUT}" not file_contents any_line
                                matches_regex
                                "^.*failed with.*$")

    endfunction ()

    cmake_unit_configure_test (CONFIGURE COMMAND _cmake_unit_configure
                               VERIFY COMMAND _cmake_unit_verify)

endfunction ()

# Add a build test that will fail on its _cmake_unit_verify step. Check to make
# sure that the test fails.
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
        cmake_unit_assert_that ("${TEST_OUTPUT}" file_contents any_line
                                matches_regex
                                "^.*CMake Error.*$")
        set (EXPECTED_STR
             "A command failed during the"
             "invocation of callback \"gen_verify\"")
        string (REPLACE ";" " " EXPECTED_STR "${EXPECTED_STR}")
        cmake_unit_assert_that ("${TEST_OUTPUT}" file_contents any_line
                                matches_regex
                                "^.*${EXPECTED_STR}.*$")

    endfunction ()

    cmake_unit_configure_test (CONFIGURE COMMAND _cmake_unit_configure
                               INVOKE_TEST ALLOW_FAIL
                               VERIFY COMMAND _cmake_unit_verify)

endfunction ()

# Add a build test that will fail to _cmake_unit_configure, the build step
# should not run.
function (cmake_unit_test_cmake_build_test_build_not_run_if_configure_can_fail)

    function (_cmake_unit_configure)

        _cmake_unit_test_gen_configure (NAMESPACE sample
                                        NAME one
                                        INVOKE_CONFIGURE OPTIONS ALLOW_FAIL)

    endfunction ()

    function (_cmake_unit_verify)

        cmake_unit_get_log_for (INVOKE_TEST OUTPUT TEST_OUTPUT)
        cmake_unit_assert_that ("${TEST_OUTPUT}" not file_contents any_line
                                matches_regex
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

        cmake_unit_escape_string ("${CMAKE_CTEST_COMMAND}"
                                  ESCAPED_CTEST_COMMAND)
        set (CTEST_REGEX "^.*${ESCAPED_CTEST_COMMAND}.*$")

        cmake_unit_get_log_for (INVOKE_TEST OUTPUT TEST_OUTPUT)
        cmake_unit_assert_that ("${TEST_OUTPUT}" not file_contents any_line
                                matches_regex
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
             "^.*${ESC_CMAKE_COMMAND}.*--build.+--target.+custom_target.*$")
        cmake_unit_assert_that ("${TEST_OUTPUT}" file_contents any_line
                                matches_regex
                                "${CMAKE_BUILD_REGEX}")

    endfunction ()

    cmake_unit_configure_test (CONFIGURE COMMAND _cmake_unit_configure
                               VERIFY COMMAND _cmake_unit_verify)

endfunction ()

# Adds a build test. Override the clean step and put something in the
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
             "cmake_call_function (cmake_unit_invoke_clean\n"
             "                     \${CALLER_ARGN})\n")
        _cmake_unit_test_gen_configure (NAMESPACE sample
                                        NAME one
                                        CLEAN SCRIPT ${CLEAN_SCRIPT})

    endfunction ()

    function (_cmake_unit_verify)

        cmake_unit_assert_that ("${FILE_THAT_SHOULD_NOT_EXIST}"
                                not exists_as_file)

    endfunction ()

    cmake_unit_configure_test (CONFIGURE COMMAND _cmake_unit_configure
                               VERIFY COMMAND _cmake_unit_verify)

endfunction ()

# Put something in the build directory but also override the clean step
# so that nothing is run. The file should still be there at verify-stage
function (cmake_unit_test_cmake_build_test_clean_step_not_run_on_no_clean)

    cmake_unit_get_dirs (BINARY_DIR SOURCE_DIR)

    function (_cmake_unit_configure)

        # The file is inside the inner test build dir
        set (FILE_THAT_SHOULD_EXIST
             "${BINARY_DIR}/sample_test_one/build/check_dir")

        file (MAKE_DIRECTORY "${BINARY_DIR}/sample_test_one")
        file (MAKE_DIRECTORY "${BINARY_DIR}/sample_test_one/build")
        file (MAKE_DIRECTORY "${FILE_THAT_SHOULD_EXIST}")

        set (CLEAN_SCRIPT "message (STATUS \"OVERRIDDEN\")\n")
        set (VERIFY_SCRIPT
             "cmake_unit_assert_that(\"${FILE_THAT_SHOULD_EXIST}\"\n"
             "                       exists_as_file)\n")
        _cmake_unit_test_gen_configure (NAMESPACE sample
                                        NAME one
                                        CLEAN SCRIPT "${CLEAN_SCRIPT}"
                                        VERIFY SCRIPT "${VERIFY_SCRIPT}")

    endfunction ()

    cmake_unit_configure_test (CONFIGURE COMMAND _cmake_unit_configure)

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
        cmake_unit_assert_that ("${TEST_OUTPUT}" file_contents any_line
                                matches_regex
                                "^.*CMake Error.*$")

    endfunction ()

    cmake_unit_configure_test (CONFIGURE COMMAND _cmake_unit_configure
                               INVOKE_TEST ALLOW_FAIL
                               VERIFY COMMAND _cmake_unit_verify)
endfunction ()

# Generates a warning, make sure that INVOKE_CONFIGURE does not error out
# when ALLOW_WARNINGS is specified.
function (cmake_unit_test_cmake_build_test_no_errors_where_w_error_disabled)

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
        cmake_unit_assert_that ("${TEST_OUTPUT}" not file_contents any_line
                                matches_regex
                                "^.*CMake Error.*$")
        cmake_unit_assert_that ("${TEST_OUTPUT}" file_contents any_line
                                matches_regex
                                "^.*CMake Warning.*$")

    endfunction ()

    cmake_unit_configure_test (CONFIGURE COMMAND _cmake_unit_configure
                               VERIFY COMMAND _cmake_unit_verify)

endfunction ()

# Check that we can read files put into the top-level binary directory, above
# the tests. This is useful in cases where we might want to generate an
# executable once during the build phase and re-use it during the tests.
function (cmake_unit_test_can_read_from_invoking_binary_dir)

    function (_cmake_unit_configure)

        set (GENERATED_FILE "Generated.cpp")
        cmake_unit_generate_source_file_during_build (TARGET
                                                      NAME "${GENERATED_FILE}"
                                                      GENERATED_FILE
                                                      "${_CURRENT_LIST_FILE}")
        set (VERIFY_SCRIPT
             "cmake_unit_assert_that ("
             "\"\${CMAKE_UNIT_INVOKING_BINARY_DIR}/${GENERATED_FILE}\""
             "exists_as_file)\n")

        _cmake_unit_test_gen_configure (NAMESPACE sample
                                        NAME one
                                        VERIFY SCRIPT "${VERIFY_SCRIPT}")

    endfunction ()

    cmake_unit_configure_test (CONFIGURE COMMAND _cmake_unit_configure
                               INVOKE_CONFIGURE OPTIONS LANGUAGES C CXX)

endfunction ()

# Check that output directories are forwarded.
function (cmake_unit_test_forward_output_directories)

    set (RUNTIME_DIR "runtime")
    set (LIBRARY_DIR "library")
    set (ARCHIVE_DIR "archive")

    set (CMAKE_RUNTIME_OUTPUT_DIRECTORY # NOLINT:unused/var_in_func
         "${RUNTIME_DIR}")
    set (CMAKE_ARCHIVE_OUTPUT_DIRECTORY # NOLINT:unused/var_in_func
         "${ARCHIVE_DIR}")
    set (CMAKE_LIBRARY_OUTPUT_DIRECTORY # NOLINT:unused/var_in_func
         "${LIBRARY_DIR}")

    function (_cmake_unit_configure)

        set (CONFIGURE_SCRIPT
             "cmake_unit_assert_that ("
             "CMAKE_UNIT_INVOKING_RUNTIME_OUTPUT_DIRECTORY compare_as "
             "STRING EQUAL \"${RUNTIME_DIR}\")\n"
             "cmake_unit_assert_that ("
             "CMAKE_UNIT_INVOKING_LIBRARY_OUTPUT_DIRECTORY compare_as "
             "STRING EQUAL \"${LIBRARY_DIR}\")\n"
             "cmake_unit_assert_that ("
             "CMAKE_UNIT_INVOKING_ARCHIVE_OUTPUT_DIRECTORY compare_as "
             "STRING EQUAL \"${ARCHIVE_DIR}\")\n")

        _cmake_unit_test_gen_configure (NAMESPACE sample
                                        NAME one
                                        CONFIGURE SCRIPT "${CONFIGURE_SCRIPT}")

    endfunction ()

    cmake_unit_configure_test (CONFIGURE COMMAND _cmake_unit_configure)

    unset (CMAKE_RUNTIME_OUTPUT_DIRECTORY)
    unset (CMAKE_ARCHIVE_OUTPUT_DIRECTORY)
    unset (CMAKE_LIBRARY_OUTPUT_DIRECTORY)

endfunction ()

# Set up some tests which will include some specified scripts, but not
# a certain excluded script. Eg
# First Test:
# - /Excluded.cmake
# - /Included.cmake
# - /FirstTestSpecific.cmake
# Second Test:
# - /Excluded.cmake
# - /Included.cmake
# - /SecondTestSpecific.cmake
# The following files will be added as part of COVERAGE_FILES
# - /Included.cmake
# - /FirstTestSpecific.cmake
# - /SecondTestSpecific.cmake
#
# Use the excluded script as a convenient crutch to disable
# all the warnings
#
# Coverage should be recorded in both the test and _cmake_unit_verify steps
# Check that when CMAKE_UNIT_LOG_COVERAGE was on we created a file
# called /SampleTests.trace in CMAKE_CURRENT_BINARY_DIR
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
    set (COVERAGE_TRACE "${BINARY_DIR}/coverage.trace")

    function (_cmake_unit_configure)

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
             "include (\"${EXCLUDED}\")\n"
             "include (\"${INCLUDED}\")\n"
             "include (\"${FIRST_TEST_SPECIFIC}\")\n")

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
             "include (\"${EXCLUDED}\")\n"
             "include (\"${INCLUDED}\")\n"
             "include (\"${SECOND_TEST_SPECIFIC}\")\n")

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
                                                     NAMESPACE sample
                                                     COVERAGE_FILE
                                                     "${COVERAGE_TRACE}")

    endfunction ()

    function (_cmake_unit_verify)

        set (FIRST_TEST_REGEX "^.*FirstTestSpecific.cmake.1.*$")
        set (SECOND_TEST_REGEX "^.*SecondTestSpecific.cmake.1.*$")
        set (EXCLUDED_REGEX "^.*Excluded.cmake.*$")

        cmake_unit_assert_that ("${COVERAGE_TRACE}" exists_as_file)
        cmake_unit_assert_that ("${COVERAGE_TRACE}" file_contents any_line
                                matches_regex
                                "^.*Included.cmake.1.*$")
        cmake_unit_assert_that ("${COVERAGE_TRACE}" file_contents any_line
                                matches_regex
                                "${FIRST_TEST_REGEX}")
        cmake_unit_assert_that ("${COVERAGE_TRACE}" file_contents any_line
                                matches_regex
                                "${SECOND_TEST_REGEX}")

        cmake_unit_assert_that ("${COVERAGE_TRACE}" not file_contents any_line
                                matches_regex
                                "${EXCLUDED_REGEX}")

    endfunction ()

    cmake_unit_configure_test (CONFIGURE COMMAND _cmake_unit_configure
                               VERIFY COMMAND _cmake_unit_verify)

endfunction ()

# Adds a test which adds a custom target with a command "cmake -E touch
# /Generated.cpp" to the ALL target. Checks that cmake -E touch /Generated.cpp
# was in the test output
function (cmake_unit_test_cmake_tests_have_verbose_output)

    function (_cmake_unit_configure)

        set (CONFIGURE_SCRIPT
             "set (BINARY_DIR \"\${CMAKE_CURRENT_BINARY_DIR}\")\n"
             "set (GENERATED_FILE \"\${BINARY_DIR}/Generated.cpp\")\n"
             "add_custom_command (OUTPUT\n"
             "                    \"\${GENERATED_FILE}\"\n"
             # The two commands will actually be to generate a
             # file called /FirstCommand.cpp, and then another
             # command to generate /SecondCommand.cpp
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
        cmake_unit_assert_that ("${TEST_OUTPUT}" file_contents any_line
                                matches_regex
                                "${FIRST_REGEX}")

        set (SECOND_REGEX
             "^.*${ESC_CMAKE_COMMAND}.*-E touch .*SecondCommand.cpp.*$")
        cmake_unit_assert_that ("${TEST_OUTPUT}" file_contents any_line
                                matches_regex
                                "${SECOND_REGEX}")

    endfunction ()

    cmake_unit_configure_test (CONFIGURE COMMAND _cmake_unit_configure
                               VERIFY COMMAND _cmake_unit_verify)

endfunction ()

# Add a test whose _cmake_unit_configure step is allowed to fail and make it
# print a FATAL_ERROR on the _cmake_unit_configure step. On the test output, we
# should see "CMake Error", both lines of our error message and the call stack
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
        cmake_unit_assert_that ("${TEST_OUTPUT}" file_contents any_line
                                matches_regex
                                "^.*CMake Error.*$")
        cmake_unit_assert_that ("${TEST_OUTPUT}" file_contents any_line
                                matches_regex
                                "^.*Fatal Error.*$")
        cmake_unit_assert_that ("${TEST_OUTPUT}" file_contents any_line
                                matches_regex
                                "^.*On Multiple Lines.*$")
        cmake_unit_assert_that ("${TEST_OUTPUT}" file_contents any_line
                                matches_regex
                                "^.*Call Stack.*$")

    endfunction ()

    cmake_unit_configure_test (CONFIGURE COMMAND _cmake_unit_configure
                               VERIFY COMMAND _cmake_unit_verify)

endfunction ()

# Check that a source file by the name Source.cpp was created in
# ${CMAKE_CURRENT_SOURCE_DIR} when we call
# cmake_unit_generate_source_file_during_build at the
# _cmake_unit_configure-stage (it shouldn't exist at the _cmake_unit_configure
# stage)
function (cmake_unit_test_source_file_generated_during_build_exists)

    cmake_unit_get_dirs (BINARY_DIR SOURCE_DIR)

    function (_cmake_unit_configure)

        cmake_unit_generate_source_file_during_build (GENERATED_DURING_TARGET)

        cmake_unit_assert_that ("${SOURCE_DIR}/Source.cpp" not exists_as_file)

    endfunction ()

    function (_cmake_unit_verify)

        cmake_unit_assert_that ("${BINARY_DIR}/Source.cpp" exists_as_file)

    endfunction ()

    cmake_unit_configure_test (CONFIGURE COMMAND _cmake_unit_configure
                               VERIFY COMMAND _cmake_unit_verify)

endfunction ()

# Check that a source file by the name Source.cpp was created in
# /${CMAKE_CURRENT_SOURCE_DIR}/subdirectory when we call
# cmake_unit_generate_source_file_during_build at the
# _cmake_unit_configure-stage (it shouldn't exist at the _cmake_unit_configure
# stage). Note that the subdirectory is automatically created.
function (cmake_unit_test_source_file_generated_during_build_exists_subdir)

    cmake_unit_get_dirs (BINARY_DIR SOURCE_DIR)

    function (_cmake_unit_configure)

        cmake_unit_generate_source_file_during_build (GENERATED_DURING_TARGET
                                                      NAME
                                                      "subdirectory/Source.cpp")

        cmake_unit_assert_that ("${SOURCE_DIR}/subdirectory/Source.cpp"
                                not exists_as_file)

    endfunction ()

    function (_cmake_unit_verify)

        cmake_unit_assert_that ("${BINARY_DIR}/subdirectory/Source.cpp"
                                exists_as_file)

    endfunction ()

    cmake_unit_configure_test (CONFIGURE COMMAND _cmake_unit_configure
                               VERIFY COMMAND _cmake_unit_verify)

endfunction ()

# Exit with a fatal error if the source file passed to
# cmake_unit_create_source_file_before_build does not have a valid
# extension.
function (cmake_unit_test_source_file_created_before_build_needs_extension)

    cmake_unit_get_dirs (BINARY_DIR SOURCE_DIR)

    function (_cmake_unit_configure)

        cmake_unit_create_source_file_before_build (NAME "incorrect")

    endfunction ()

    function (_cmake_unit_verify)

        cmake_unit_get_log_for (INVOKE_CONFIGURE ERROR CONFIGURE_ERROR)
        cmake_unit_assert_that ("${CONFIGURE_ERROR}"
                                file_contents any_line matches_regex
                                "^.*current name is incorrect.*$")

    endfunction ()

    cmake_unit_configure_test (CONFIGURE COMMAND _cmake_unit_configure
                               VERIFY COMMAND _cmake_unit_verify
                               INVOKE_CONFIGURE OPTIONS ALLOW_FAIL)

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
        cmake_unit_create_source_file_before_build (${GENERATE_OPTIONS}
                                                    GENERATING_FILE
                                                    "${_CURRENT_LIST_FILE}")

    endfunction ()

    function (_cmake_unit_verify)

        file (SHA512 "${SOURCE_DIR}/CustomSource.cpp" CREATED_HASH)
        file (SHA512 "${BINARY_DIR}/CustomSource.cpp" GENERATED_HASH)

        cmake_unit_assert_that (CREATED_HASH compare_as
                                STRING EQUAL "${GENERATED_HASH}")

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

        cmake_unit_create_simple_executable (executable
                                             GENERATING_FILE
                                             "${_CURRENT_LIST_FILE}")
        export (TARGETS executable FILE "${BINARY_DIR}/exports.cmake")

    endfunction ()

    function (_cmake_unit_verify)

        set (EXPORTS_FILE "${BINARY_DIR}/exports.cmake")
        cmake_unit_get_target_location_from_exports ("${EXPORTS_FILE}"
                                                     "${BINARY_DIR}"
                                                     executable
                                                     LOCATION)

        cmake_unit_assert_that ("${LOCATION}" exists_as_file)
        cmake_unit_assert_that ("${LOCATION}" executes_with_success)

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
# There's not too much particularly useful to _cmake_unit_verify here, other
# than the executable and the library being mentioned because the order
# in which they are mentioned is generator specific
function (cmake_unit_test_create_simple_library)

    cmake_unit_get_dirs (BINARY_DIR SOURCE_DIR)

    function (_cmake_unit_configure)

        cmake_unit_create_simple_library (library SHARED
                                          FUNCTIONS function
                                          GENERATING_FILE
                                          "${_CURRENT_LIST_FILE}")
        cmake_unit_create_simple_executable (executable
                                             GENERATING_FILE
                                             "${_CURRENT_LIST_FILE}")
        target_link_libraries (executable library)

    endfunction ()

    function (_cmake_unit_verify)

        cmake_unit_get_log_for (INVOKE_BUILD OUTPUT BUILD_OUTPUT)

        cmake_unit_assert_that ("${BUILD_OUTPUT}" file_contents any_line
                                matches_regex
                                "^.*library.*$")
        cmake_unit_assert_that ("${BUILD_OUTPUT}" file_contents any_line
                                matches_regex
                                "^.*executable.*$")

    endfunction ()

    cmake_unit_configure_test (INVOKE_CONFIGURE LANGUAGES C CXX
                               CONFIGURE COMMAND _cmake_unit_configure
                               VERIFY COMMAND _cmake_unit_verify)

endfunction ()

# Creates a simple executable named "executable" by using
# cmake_unit_create_simple_executable and links to a simple library
# named "library" created by using cmake_unit_create_simple_library. Note
# that the library has no functions specified, but the test should still
# pass.
function (cmake_unit_test_create_simple_library_without_functions)

    cmake_unit_get_dirs (BINARY_DIR SOURCE_DIR)

    function (_cmake_unit_configure)

        cmake_unit_create_simple_library (library SHARED
                                          GENERATING_FILE
                                          "${_CURRENT_LIST_FILE}")
        cmake_unit_create_simple_executable (executable
                                             GENERATING_FILE
                                             "${_CURRENT_LIST_FILE}")
        target_link_libraries (executable library)

    endfunction ()

    function (_cmake_unit_verify)

        cmake_unit_get_log_for (INVOKE_BUILD OUTPUT BUILD_OUTPUT)

        cmake_unit_assert_that ("${BUILD_OUTPUT}" file_contents any_line
                                matches_regex
                                "^.*library.*$")
        cmake_unit_assert_that ("${BUILD_OUTPUT}" file_contents any_line
                                matches_regex
                                "^.*executable.*$")

    endfunction ()

    cmake_unit_configure_test (INVOKE_CONFIGURE LANGUAGES C CXX
                               CONFIGURE COMMAND _cmake_unit_configure
                               VERIFY COMMAND _cmake_unit_verify)

endfunction ()

# Create an external project with an exported library and use
# cmake_unit_export_cfg_int_dir in that external project to write out
# CMAKE_CFG_INT_DIR to /CfgIntDirValue.txt in its BINARY_DIR
#
# Uses cmake_unit_import_cfg_int_dir and cross-checks that against an
# exported target from the external project's location. If the path
# ${CMAKE_CURRENT_BINARY_DIR}/ExternalProject/build/${CFG_INT_DIR}
# is the prefix to the exported target's LOCATION property then that
# means that the CFG_INT_DIR was successful stored on this generator.
# Normalize path
function (cmake_unit_test_export_import_cfg_int_dir)

    cmake_unit_get_dirs (BINARY_DIR SOURCE_DIR)

    set (EXT_PROJECT_SOURCE_DIR "${BINARY_DIR}/ExternalProject")
    set (EXT_PROJECT_BINARY_DIR "${EXT_PROJECT_SOURCE_DIR}/build")
    set (EXT_PROJECT_EXPORTS
         "${EXT_PROJECT_BINARY_DIR}/exports.cmake")

    function (_cmake_unit_configure)

        include (ExternalProject)

        set (EXT_PROJECT_CMAKELISTS_TXT
             "${EXT_PROJECT_SOURCE_DIR}/CMakeLists.txt")
        string (REPLACE ";" " " STRINGIFIED_CMAKE_MODULE_PATH
                "${CMAKE_MODULE_PATH}")
        set (EXT_PROJECT_CMAKELISTS_TXT_CONTENT
             "cmake_minimum_required (VERSION 2.8)\n"
             "set (CMAKE_MODULE_PATH ${STRINGIFIED_CMAKE_MODULE_PATH})\n"
             "include (CMakeUnit)\n"
             "cmake_unit_create_simple_executable (executable)\n"
             "export (TARGETS executable\n"
             "        FILE \"${EXT_PROJECT_EXPORTS}\")\n"
             "set (CFG_INT_DIR_LOCATION \"${BINARY_DIR}/CfgIntDir.txt\")\n"
             "cmake_unit_export_cfg_int_dir (\"\${CFG_INT_DIR_LOCATION}\")\n")

        file (MAKE_DIRECTORY "${EXT_PROJECT_SOURCE_DIR}")
        file (MAKE_DIRECTORY "${EXT_PROJECT_BINARY_DIR}")
        file (WRITE "${EXT_PROJECT_CMAKELISTS_TXT}"
              ${EXT_PROJECT_CMAKELISTS_TXT_CONTENT})

        externalproject_add (ExternalProject
                             SOURCE_DIR "${EXT_PROJECT_SOURCE_DIR}"
                             BINARY_DIR "${EXT_PROJECT_BINARY_DIR}"
                             INSTALL_COMMAND "")

        add_custom_target (target ALL DEPENDS ExternalProject)

    endfunction ()

    function (_cmake_unit_verify)

        cmake_unit_import_cfg_int_dir ("${BINARY_DIR}/CfgIntDir.txt"
                                       CFG_INT_DIR)
        cmake_unit_get_target_location_from_exports ("${EXT_PROJECT_EXPORTS}"
                                                     "${BINARY_DIR}"
                                                     executable
                                                     EXECUTABLE_LOCATION)


        set (EXPECTED_EXECUTABLE_LOCATION_HEADER
             "${EXT_PROJECT_BINARY_DIR}/${CFG_INT_DIR}")
        get_filename_component (EXPECTED_EXECUTABLE_LOCATION_HEADER
                                "${EXPECTED_EXECUTABLE_LOCATION_HEADER}"
                                ABSOLUTE)
        string (LENGTH "${EXPECTED_EXECUTABLE_LOCATION_HEADER}"
                EXPECTED_EXECUTABLE_LOCATION_HEADER_LENGTH)
        string (SUBSTRING "${EXECUTABLE_LOCATION}"
                0
                ${EXPECTED_EXECUTABLE_LOCATION_HEADER_LENGTH}
                EXECUTABLE_LOCATION_HEADER)

        cmake_unit_assert_that (EXECUTABLE_LOCATION_HEADER compare_as
                                STRING EQUAL
                                "${EXPECTED_EXECUTABLE_LOCATION_HEADER}")

    endfunction ()

    cmake_unit_configure_test (CONFIGURE COMMAND _cmake_unit_configure
                               VERIFY COMMAND _cmake_unit_verify)

endfunction ()

# Check the target_exists matcher.
function (cmake_unit_test_target_exists)

    cmake_unit_get_dirs (BINARY_DIR SOURCE_DIR)

    function (_cmake_unit_configure)

        file (WRITE "${CMAKE_CURRENT_BINARY_DIR}/Library.cpp" "")
        add_library (library SHARED
                     "${CMAKE_CURRENT_BINARY_DIR}/Library.cpp")

        cmake_unit_eval_matcher (library target_exists TARGET_EXISTS_RESULT)
        cmake_unit_eval_matcher (not_existing target_exists
                                 TARGET_EXISTS_NOT_RESULT)

        cmake_unit_assert_that (TARGET_EXISTS_RESULT is_true)
        cmake_unit_assert_that (TARGET_EXISTS_NOT_RESULT
                                compare_as STRING EQUAL
                                "not_existing to be a target")

    endfunction ()

    cmake_unit_configure_config_only_test (INVOKE_CONFIGURE LANGUAGES C CXX
                                           CONFIGURE
                                           COMMAND _cmake_unit_configure)

endfunction ()

# Check the variable_contains matcher.
function (cmake_unit_test_variable_contains)

    function (_cmake_unit_configure)

        set (SUBSTRING "substring")
        set (MAIN_STRING "main_${SUBSTRING}_string")

        cmake_unit_eval_matcher (MAIN_STRING variable_contains ${SUBSTRING}
                                 RESULT)
        cmake_unit_eval_matcher (MAIN_STRING variable_contains "other"
                                 NOT_RESULT)

        cmake_unit_assert_that (RESULT is_true)
        cmake_unit_assert_that (NOT_RESULT
                                variable_contains
                                "substring other to be found in MAIN_STRING")

    endfunction ()

    cmake_unit_configure_config_only_test (CONFIGURE
                                           COMMAND _cmake_unit_configure)

endfunction ()

# Check the compare_as matcher for integers and booleans
function (cmake_unit_test_variable_is)

    function (_cmake_unit_configure)

        set (STR_VAR "value")

        cmake_unit_eval_matcher (STR_VAR compare_as STRING EQUAL "value"
                                 EXPECT_EQUAL)
        cmake_unit_eval_matcher (STR_VAR compare_as STRING EQUAL "nvalue"
                                 EXPECT_UNEQUAL)
        cmake_unit_eval_matcher (STR_VAR compare_as STRING GREATER "valud"
                                 EXPECT_LESS)
        cmake_unit_eval_matcher (STR_VAR compare_as STRING GREATER "valuf"
                                 EXPECT_NOT_LESS)
        cmake_unit_eval_matcher (STR_VAR compare_as STRING LESS "valuf"
                                 EXPECT_GREATER)
        cmake_unit_eval_matcher (STR_VAR compare_as STRING LESS "valud"
                                 EXPECT_NOT_GREATER)

        cmake_unit_assert_that (EXPECT_EQUAL is_true)
        cmake_unit_assert_that (EXPECT_UNEQUAL variable_contains "nvalue")
        cmake_unit_assert_that (EXPECT_LESS is_true)
        cmake_unit_assert_that (EXPECT_NOT_LESS variable_contains "valuf")
        cmake_unit_assert_that (EXPECT_GREATER is_true)
        cmake_unit_assert_that (EXPECT_NOT_GREATER variable_contains "valud")

        set (INT_VAR 1)

        cmake_unit_eval_matcher (INT_VAR compare_as INTEGER EQUAL 1
                                 EXPECT_EQUAL)
        cmake_unit_eval_matcher (INT_VAR compare_as INTEGER EQUAL 2
                                 EXPECT_UNEQUAL)
        cmake_unit_eval_matcher (INT_VAR compare_as INTEGER GREATER 0
                                 EXPECT_LESS)
        cmake_unit_eval_matcher (INT_VAR compare_as INTEGER GREATER 2
                                 EXPECT_NOT_LESS)
        cmake_unit_eval_matcher (INT_VAR compare_as INTEGER LESS 2
                                 EXPECT_GREATER)
        cmake_unit_eval_matcher (INT_VAR compare_as INTEGER LESS 0
                                 EXPECT_NOT_GREATER)

        cmake_unit_assert_that (EXPECT_EQUAL is_true)
        cmake_unit_assert_that (EXPECT_UNEQUAL variable_contains "2")
        cmake_unit_assert_that (EXPECT_LESS is_true)
        cmake_unit_assert_that (EXPECT_NOT_LESS variable_contains "2")
        cmake_unit_assert_that (EXPECT_GREATER is_true)
        cmake_unit_assert_that (EXPECT_NOT_GREATER variable_contains "0")

        set (BOOL_VARIABLE ON)

        cmake_unit_eval_matcher (BOOL_VARIABLE compare_as BOOL EQUAL ON
                                 EXPECT_EQUAL)
        cmake_unit_eval_matcher (BOOL_VARIABLE compare_as BOOL EQUAL OFF
                                 EXPECT_UNEQUAL)

        cmake_unit_assert_that (EXPECT_EQUAL is_true)
        cmake_unit_assert_that (EXPECT_UNEQUAL variable_contains "OFF")

    endfunction ()

    cmake_unit_configure_config_only_test (CONFIGURE
                                           COMMAND _cmake_unit_configure)

endfunction ()

# Check the compare_as matcher with empty values
function (cmake_unit_test_variable_is_empty)

    function (_cmake_unit_configure)

        set (STR_VAR "")

        cmake_unit_eval_matcher (STR_VAR compare_as STRING EMPTY "EMPTY"
                                 EXPECT_EQUAL)

        cmake_unit_assert_that (EXPECT_EQUAL is_true)

    endfunction ()

    cmake_unit_configure_config_only_test (CONFIGURE
                                           COMMAND _cmake_unit_configure)

endfunction ()

# Check the executes_with_success matcher.
function (cmake_unit_test_command_executes_with_success)

    cmake_unit_get_dirs (BINARY_DIR SOURCE_DIR)

    function (_cmake_unit_configure)

        cmake_unit_eval_matcher ("${CMAKE_COMMAND}"
                                 executes_with_success
                                 RESULT_TRUE)

        # Passes bogus argument to CMake, won't ever succeed
        set (UNSUCCESSFUL_EXECUTABLE "${BINARY_DIR}/does_not_exist")
        cmake_unit_eval_matcher ("${UNSUCCESSFUL_EXECUTABLE}"
                                 executes_with_success
                                 RESULT_FALSE)

        cmake_unit_assert_that (RESULT_TRUE is_true)
        cmake_unit_assert_that (RESULT_FALSE
                                variable_contains
                                "to exit with success")

    endfunction ()

    cmake_unit_configure_config_only_test (CONFIGURE
                                           COMMAND _cmake_unit_configure)

endfunction ()

# Check the is_linked_to matcher.
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

        cmake_unit_eval_matcher (executable is_linked_to library RESULT)
        cmake_unit_eval_matcher (executable is_linked_to other__ NOT_RESULT)

        cmake_unit_assert_that (RESULT is_true)
        cmake_unit_assert_that (NOT_RESULT
                                variable_contains
                                "other__ to be a link-library")

    endfunction ()

    cmake_unit_configure_config_only_test (INVOKE_CONFIGURE LANGUAGES CXX
                                           CONFIGURE
                                           COMMAND _cmake_unit_configure)

endfunction ()

# Check the has_property_with_value matcher.
function (cmake_unit_test_item_has_property_with_value)

    function (_cmake_unit_configure)

        set (TARGET_PROPERTY_VALUE "value")
        add_custom_target (target)
        set_property (TARGET target
                      PROPERTY TARGET_PROPERTY
                      ${TARGET_PROPERTY_VALUE})

        cmake_unit_eval_matcher (target item_has_property_with_value
                                 TARGET
                                 TARGET_PROPERTY
                                 STRING EQUAL
                                 ${TARGET_PROPERTY_VALUE}
                                 EXPECT_EQUAL)

        cmake_unit_eval_matcher (target item_has_property_with_value
                                 TARGET
                                 TARGET_PROPERTY
                                 STRING EQUAL
                                 "something_else"
                                 EXPECT_NOT_EQUAL)

        cmake_unit_eval_matcher (target item_has_property_with_value
                                 TARGET
                                 TARGET_NON_EXISTENT_PROPERTY
                                 STRING EQUAL
                                 ${TARGET_PROPERTY_VALUE}
                                 EXPECT_DOESNT_EXIST)

        cmake_unit_assert_that (EXPECT_EQUAL is_true)
        cmake_unit_assert_that (EXPECT_NOT_EQUAL
                                variable_contains
                                "to have property TARGET_PROPERTY")
        cmake_unit_assert_that (EXPECT_DOESNT_EXIST
                                variable_contains
                                "to have property TARGET_NON_EXISTENT_PROPERTY")

    endfunction ()

    cmake_unit_configure_config_only_test (CONFIGURE
                                           COMMAND _cmake_unit_configure)

endfunction ()

# Check the has_property_with_value matcher with empty values.
function (cmake_unit_test_item_has_property_with_value_empty)

    function (_cmake_unit_configure)

        set (TARGET_PROPERTY_VALUE "")
        add_custom_target (target)
        set_property (TARGET target
                      PROPERTY TARGET_PROPERTY
                      "${TARGET_PROPERTY_VALUE}")

        cmake_unit_eval_matcher (target item_has_property_with_value
                                 TARGET
                                 TARGET_PROPERTY
                                 STRING EMPTY
                                 "EMPTY"
                                 EXPECT_EMPTY)

        cmake_unit_assert_that (EXPECT_EMPTY is_true)

    endfunction ()

    cmake_unit_configure_config_only_test (CONFIGURE
                                           COMMAND _cmake_unit_configure)

endfunction ()

# Check the has_property_with_value matcher with GLOBAL properties.
function (cmake_unit_test_item_has_property_with_value_global)

    function (_cmake_unit_configure)


        set (GLOBAL_PROPERTY_VALUE "value")
        set_property (GLOBAL
                      PROPERTY GLOBAL_PROPERTY
                      ${GLOBAL_PROPERTY_VALUE})

        cmake_unit_eval_matcher (GLOBAL item_has_property_with_value
                                 GLOBAL
                                 GLOBAL_PROPERTY
                                 STRING EQUAL
                                 ${GLOBAL_PROPERTY_VALUE}
                                 EXPECT_EQUAL)

        cmake_unit_eval_matcher (GLOBAL item_has_property_with_value
                                 GLOBAL
                                 GLOBAL_PROPERTY
                                 STRING EQUAL
                                 "something_else"
                                 EXPECT_NOT_EQUAL)

        cmake_unit_eval_matcher (GLOBAL item_has_property_with_value
                                 GLOBAL
                                 GLOBAL_NON_EXISTENT_PROPERTY
                                 STRING EQUAL
                                 ${GLOBAL_PROPERTY_VALUE}
                                 EXPECT_DOESNT_EXIST)

        cmake_unit_assert_that (EXPECT_EQUAL is_true)
        cmake_unit_assert_that (EXPECT_NOT_EQUAL
                                variable_contains
                                "to have property GLOBAL_PROPERTY")
        cmake_unit_assert_that (EXPECT_DOESNT_EXIST
                                variable_contains
                                "to have property GLOBAL_NON_EXISTENT_PROPERTY")

    endfunction ()

    cmake_unit_configure_config_only_test (CONFIGURE
                                           COMMAND _cmake_unit_configure)

endfunction ()

# Check the has_property_containing_value matcher.
function (cmake_unit_test_item_has_property_containing_value)

    function (_cmake_unit_configure)

        set (TARGET_PROPERTY_VALUE "value")
        set (TARGET_PROPERTY_VALUE2 "other_value")
        add_custom_target (target)
        set_property (TARGET target
                      APPEND
                      PROPERTY TARGET_PROPERTY
                      ${TARGET_PROPERTY_VALUE})
        set_property (TARGET target
                      APPEND
                      PROPERTY TARGET_PROPERTY
                      ${TARGET_PROPERTY_VALUE2})

        cmake_unit_eval_matcher (target item_has_property_containing_value
                                 TARGET
                                 TARGET_PROPERTY
                                 STRING EQUAL
                                 ${TARGET_PROPERTY_VALUE}
                                 EXPECT_EQUAL_FIRST)

        cmake_unit_eval_matcher (target item_has_property_containing_value
                                 TARGET
                                 TARGET_PROPERTY
                                 STRING EQUAL
                                 ${TARGET_PROPERTY_VALUE}
                                 EXPECT_EQUAL_FIRST)

        cmake_unit_eval_matcher (target item_has_property_containing_value
                                 TARGET
                                 TARGET_PROPERTY
                                 STRING EQUAL
                                 ${TARGET_PROPERTY_VALUE2}
                                 EXPECT_EQUAL_SECOND)

        cmake_unit_eval_matcher (target item_has_property_containing_value
                                 TARGET
                                 TARGET_PROPERTY
                                 STRING EQUAL
                                 "not_contained_in_prop"
                                 EXPECT_NOT_EQUAL)

        cmake_unit_eval_matcher (target item_has_property_containing_value
                                 TARGET
                                 TARGET_NO_EXIST_PROPERTY
                                 STRING EQUAL
                                 ${TARGET_PROPERTY_VALUE}
                                 EXPECT_DOESNT_EXIST)

        cmake_unit_assert_that (EXPECT_EQUAL_FIRST is_true)
        cmake_unit_assert_that (EXPECT_EQUAL_SECOND is_true)
        cmake_unit_assert_that (EXPECT_NOT_EQUAL
                                variable_contains
                                "property STRING TARGET_PROPERTY")
        cmake_unit_assert_that (EXPECT_DOESNT_EXIST
                                variable_contains
                                "property STRING TARGET_NO_EXIST_PROPERTY")

    endfunction ()

    cmake_unit_configure_config_only_test (CONFIGURE
                                           COMMAND _cmake_unit_configure)

endfunction ()

# Check the has_property_containing_value matcher with empty values.
# Empty variables never stored in lists
function (cmake_unit_test_item_has_property_containing_value_empty)

    function (_cmake_unit_configure)

        set (TARGET_PROP_VALUE "")
        add_custom_target (target)
        set_property (TARGET target
                      APPEND
                      PROPERTY TARGET_PROPERTY
                      "${TARGET_PROP_VALUE}")

        cmake_unit_eval_matcher (target item_has_property_containing_value
                                 TARGET
                                 TARGET_PROPERTY
                                 STRING EMPTY
                                 "EMPTY"
                                 EXPECT_EQUAL)

        cmake_unit_assert_that (EXPECT_EQUAL
                                variable_contains
                                "property STRING TARGET_PROPERTY")

    endfunction ()

    cmake_unit_configure_config_only_test (CONFIGURE
                                           COMMAND _cmake_unit_configure)

endfunction ()

# Check the has_property_containing_value matcher with GLOBAL properties.
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

        cmake_unit_eval_matcher (GLOBAL item_has_property_containing_value
                                 GLOBAL
                                 GLOBAL_PROPERTY
                                 STRING EQUAL
                                 ${GLOBAL_PROPERTY_VALUE}
                                 EXPECT_EQUAL)

        cmake_unit_eval_matcher (GLOBAL item_has_property_containing_value
                                 GLOBAL
                                 GLOBAL_PROPERTY
                                 STRING EQUAL
                                 "something_else"
                                 EXPECT_NOT_EQUAL)

        cmake_unit_eval_matcher (GLOBAL item_has_property_containing_value
                                 GLOBAL
                                 GLOBAL_NO_EXIST_PROPERTY
                                 STRING EQUAL
                                 ${GLOBAL_PROPERTY_VALUE}
                                 EXPECT_DOESNT_EXIST)

        cmake_unit_assert_that (EXPECT_EQUAL is_true)
        cmake_unit_assert_that (EXPECT_NOT_EQUAL
                                variable_contains
                                "property STRING GLOBAL_PROPERTY")
        cmake_unit_assert_that (EXPECT_DOESNT_EXIST
                                variable_contains
                                "property STRING GLOBAL_NO_EXIST_PROPERTY")

    endfunction ()

    cmake_unit_configure_config_only_test (CONFIGURE
                                           COMMAND _cmake_unit_configure)

endfunction ()

# Check the exists_as_file matcher.
function (cmake_unit_test_file_exists)

    cmake_unit_get_dirs (BINARY_DIR SOURCE_DIR)

    function (_cmake_unit_configure)

        set (FILE "${BINARY_DIR}/File")
        set (NOT_FILE "${BINARY_DIR}/NotFile")
        file (WRITE "${FILE}" "")

        cmake_unit_eval_matcher ("${FILE}" exists_as_file FILE_EXISTS)
        cmake_unit_eval_matcher ("${NOT_FILE}" exists_as_file NOT_FILE_EXISTS)

        cmake_unit_assert_that (FILE_EXISTS is_true)
        cmake_unit_assert_that (NOT_FILE_EXISTS
                                compare_as STRING EQUAL
                                "(file) to exist")

    endfunction ()

    cmake_unit_configure_config_only_test (CONFIGURE
                                           COMMAND _cmake_unit_configure)

endfunction ()

# Check the file_contents matcher with the variable_contains matcher.
function (cmake_unit_test_file_contains_substring)

    cmake_unit_get_dirs (BINARY_DIR SOURCE_DIR)

    function (_cmake_unit_configure)

        set (SUBSTRING "substring")
        set (MAIN_STRING "main_${SUBSTRING}_string")

        file (WRITE "${BINARY_DIR}/File" ${MAIN_STRING})

        cmake_unit_eval_matcher ("${BINARY_DIR}/File"
                                 file_contents variable_contains "${SUBSTRING}"
                                 CONTAINING_SUBSTRING)
        cmake_unit_eval_matcher ("${BINARY_DIR}/File"
                                 file_contents variable_contains "other_string"
                                 NOT_CONTAINING_SUBSTRING)

        cmake_unit_assert_that (CONTAINING_SUBSTRING is_true)
        cmake_unit_assert_that (NOT_CONTAINING_SUBSTRING
                                variable_contains "${BINARY_DIR}/File")

    endfunction ()

    cmake_unit_configure_config_only_test (CONFIGURE
                                           COMMAND _cmake_unit_configure)

endfunction ()

# Check the file_contents matcher with the any_line matches_regex matcher.
function (cmake_unit_test_file_has_line_matching)

    cmake_unit_get_dirs (BINARY_DIR SOURCE_DIR)

    function (_cmake_unit_configure)

        set (SUBSTR "substring")
        set (FOO_SUBSTR "foo")

        set (MATCH_FOO_SUBSTR_LINE "^.*${FOO_SUBSTR}.*${SUBSTR}.*$")
        set (MATCH_FOO_LINE "^.*${FOO_SUBSTR}.*$")
        set (MATCH_SUBSTR_LINE "^.*${SUBSTR}.*$")

        set (MAIN_STRING_WITH_FOO "main_${FOO_SUBSTR}_string")
        set (MAIN_STRING_WITH_SUBSTR "main_${SUBSTR}_string")
        set (MAIN_STRING_WITH_BOTH_INDEPENDENTLY
             "${MAIN_STRING_WITH_FOO}\n"
             "${MAIN_STRING_WITH_SUBSTR}\n")
        set (MAIN_STRING_WITH_BOTH
             "main_${FOO_SUBSTR}_string_${SUBSTR}_end")
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

        cmake_unit_eval_matcher (${FILE_WITH_FOO}
                                 file_contents
                                 any_line
                                 matches_regex
                                 ${MATCH_FOO_LINE}
                                 MATCH_FOO_IN_FOO)
        cmake_unit_eval_matcher (${FILE_WITH_FOO}
                                 file_contents
                                 any_line
                                 matches_regex
                                 ${MATCH_FOO_SUBSTR_LINE}
                                 NO_MATCH_SUBSTR_IN_FOO)
        cmake_unit_eval_matcher (${FILE_WITH_FOO}
                                 file_contents
                                 any_line
                                 matches_regex
                                 ${MATCH_FOO_SUBSTR_LINE}
                                 NO_MATCH_BOTH_IN_FOO)

        cmake_unit_eval_matcher (${FILE_WITH_BOTH_INDEPENDENTLY}
                                 file_contents
                                 any_line
                                 matches_regex
                                 ${MATCH_FOO_LINE}
                                 MATCH_FOO_IN_BOTH_INDEPENDENTLY)
        cmake_unit_eval_matcher (${FILE_WITH_BOTH_INDEPENDENTLY}
                                 file_contents
                                 any_line
                                 matches_regex
                                 ${MATCH_SUBSTR_LINE}
                                 MATCH_SUBSTR_IN_BOTH_INDEPENDENTLY)
        cmake_unit_eval_matcher (${FILE_WITH_BOTH_INDEPENDENTLY}
                                 file_contents
                                 any_line
                                 matches_regex
                                 ${MATCH_FOO_SUBSTR_LINE}
                                 NO_MATCH_BOTH_IN_BOTH_INDEPENDENTLY)

        cmake_unit_eval_matcher (${FILE_WITH_BOTH}
                                 file_contents
                                 any_line
                                 matches_regex
                                 ${MATCH_FOO_LINE}
                                 MATCH_FOO_IN_BOTH)
        cmake_unit_eval_matcher (${FILE_WITH_BOTH}
                                 file_contents
                                 any_line
                                 matches_regex
                                 ${MATCH_SUBSTR_LINE}
                                 MATCH_SUBSTR_IN_BOTH)
        cmake_unit_eval_matcher (${FILE_WITH_BOTH}
                                 file_contents
                                 any_line
                                 matches_regex
                                 ${MATCH_FOO_SUBSTR_LINE}
                                 MATCH_BOTH_IN_BOTH)

        cmake_unit_eval_matcher (${FILE_WITH_ALL}
                                 file_contents
                                 any_line
                                 matches_regex
                                 ${MATCH_FOO_LINE}
                                 MATCH_FOO_IN_ALL)
        cmake_unit_eval_matcher (${FILE_WITH_ALL}
                                 file_contents
                                 any_line
                                 matches_regex
                                 ${MATCH_SUBSTR_LINE}
                                 MATCH_SUBSTR_IN_ALL)
        cmake_unit_eval_matcher (${FILE_WITH_ALL}
                                 file_contents
                                 any_line
                                 matches_regex
                                 ${MATCH_FOO_SUBSTR_LINE}
                                 MATCH_BOTH_IN_ALL)

        cmake_unit_assert_that (MATCH_FOO_IN_FOO is_true)
        cmake_unit_assert_that (NO_MATCH_SUBSTR_IN_FOO
                                variable_contains
                                "${FILE_WITH_FOO}")
        cmake_unit_assert_that (NO_MATCH_BOTH_IN_FOO
                                variable_contains
                                "${FILE_WITH_FOO}")

        cmake_unit_assert_that (MATCH_FOO_IN_BOTH_INDEPENDENTLY is_true)
        cmake_unit_assert_that (MATCH_SUBSTR_IN_BOTH_INDEPENDENTLY is_true)
        cmake_unit_assert_that (NO_MATCH_BOTH_IN_BOTH_INDEPENDENTLY
                                variable_contains
                                "${FILE_WITH_BOTH_INDEPENDENTLY}")

        cmake_unit_assert_that (MATCH_FOO_IN_BOTH is_true)
        cmake_unit_assert_that (MATCH_SUBSTR_IN_BOTH is_true)
        cmake_unit_assert_that (MATCH_BOTH_IN_BOTH is_true)

        cmake_unit_assert_that (MATCH_FOO_IN_ALL is_true)
        cmake_unit_assert_that (MATCH_SUBSTR_IN_ALL is_true)
        cmake_unit_assert_that (MATCH_BOTH_IN_ALL is_true)

    endfunction ()

    cmake_unit_configure_config_only_test (CONFIGURE
                                           COMMAND _cmake_unit_configure)

endfunction ()

# Check the list_contains_value matcher.
function (cmake_unit_test_list_contains_value)

    function (_cmake_unit_configure)

        set (LIST
             v
             ov)

        cmake_unit_eval_matcher (LIST list_contains_value
                                 STRING EQUAL "v" CONTAINS_VAL)
        cmake_unit_eval_matcher (LIST list_contains_value
                                 STRING EQUAL "ov" CONTAINS_VAL2)
        cmake_unit_eval_matcher (LIST list_contains_value
                                 STRING EQUAL "not_in" NO_CONTAIN)

        cmake_unit_assert_that (CONTAINS_VAL is_true)
        cmake_unit_assert_that (CONTAINS_VAL2 is_true)
        cmake_unit_assert_that (NO_CONTAIN
                                compare_as STRING EQUAL
                                "LIST contains a value EQUAL not_in")

    endfunction ()

    cmake_unit_configure_config_only_test (CONFIGURE
                                           COMMAND _cmake_unit_configure)

endfunction ()

# Check the list_contains_value matcher with empty values
# Empty values are never stored in lists
function (cmake_unit_test_list_contains_value_empty)

    function (_cmake_unit_configure)

        set (LIST "")

        cmake_unit_eval_matcher (LIST list_contains_value
                                 STRING EMPTY "EMPTY" CONTAINS_VALUE)

        cmake_unit_assert_that (CONTAINS_VALUE
                                compare_as STRING EQUAL
                                "LIST contains a value EMPTY EMPTY")

    endfunction ()

    cmake_unit_configure_config_only_test (CONFIGURE
                                           COMMAND _cmake_unit_configure)

endfunction ()

# Check that /${CMAKE_PROJECT_NAME}.trace (in this case, /coverage.trace)
# is overwritten with nothing when cmake_unit_init is called
function (cmake_unit_test_coverage_file_clobbered_on_bootstrap)

    cmake_unit_get_dirs (BINARY_DIR SOURCE_DIR)

    function (_cmake_unit_configure)

        set (COVERAGE_FILE "${BINARY_DIR}/coverage.trace")
        file (WRITE "${COVERAGE_FILE}" "Non-empty contents")
        _cmake_unit_test_gen_configure (NAMESPACE sample
                                        NAME one
                                        COVERAGE_FILE
                                        "${COVERAGE_FILE}"
                                        CONFIGURE SCRIPT
                                        ${CONFIGURE_SCRIPT})
        # At least after the preconfigure step, the tracefile should be empty
        file (READ "${COVERAGE_FILE}" TRACE_FILE_CONTENTS)
        cmake_unit_assert_that (TRACE_FILE_CONTENTS
                                compare_as STRING EMPTY "EMPTY")

    endfunction ()

    cmake_unit_configure_config_only_test (CONFIGURE
                                           COMMAND _cmake_unit_configure)

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
        cmake_unit_assert_that ("${DRIVER_FILE}" exists_as_file)

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

        set (GENERATE_OPTIONS GENERATING_FILE "${_CURRENT_LIST_FILE}")
        cmake_unit_create_source_file_before_build (${GENERATE_OPTIONS})
        cmake_unit_assert_that ("${SOURCE_DIR}/Source.cpp" exists_as_file)

    endfunction ()

    cmake_unit_configure_config_only_test (CONFIGURE
                                           COMMAND _cmake_unit_configure)

endfunction ()

# Check that a source file by the name /CustomName.cpp was created in
# ${CMAKE_CURRENT_SOURCE_DIR} when we call
# cmake_unit_create_source_file_before_build with NAME
function (cmake_unit_test_source_file_created_before_build_with_custom_name)

    cmake_unit_get_dirs (BINARY_DIR SOURCE_DIR)

    function (_cmake_unit_configure)

        set (GENERATE_OPTIONS
             NAME "CustomName.cpp"
             GENERATING_FILE "${_CURRENT_LIST_FILE}")
        cmake_unit_create_source_file_before_build (${GENERATE_OPTIONS})
        cmake_unit_assert_that ("${SOURCE_DIR}/CustomName.cpp" exists_as_file)

    endfunction ()

    cmake_unit_configure_config_only_test (CONFIGURE
                                           COMMAND _cmake_unit_configure)

endfunction ()

# Check that a source file by the name /Source.cpp was created in
# ${CMAKE_CURRENT_SOURCE_DIR} with #define CUSTOM_DEFINE when we call
# cmake_unit_create_source_file_before_build with DEFINES CUSTOM_DEFINE
function (cmake_unit_test_source_file_created_before_build_with_defines)

    cmake_unit_get_dirs (BINARY_DIR SOURCE_DIR)

    function (_cmake_unit_configure)

        set (GENERATE_OPTIONS
             DEFINES "CUSTOM_DEFINE"
             GENERATING_FILE "${_CURRENT_LIST_FILE}")
        cmake_unit_create_source_file_before_build (${GENERATE_OPTIONS})

        set (SOURCE_FILE "${SOURCE_DIR}/Source.cpp")
        cmake_unit_assert_that ("${SOURCE_FILE}"
                                file_contents any_line matches_regex
                                "^.define CUSTOM_DEFINE$")

    endfunction ()

    cmake_unit_configure_config_only_test (CONFIGURE
                                           COMMAND _cmake_unit_configure)

endfunction ()

# Check that a source file by the name Source.cpp was created in
# ${CMAKE_CURRENT_SOURCE_DIR} with #include "my_include.h" when we call
# cmake_unit_create_source_file_before_build with INCLUDES my_include.h
function (cmake_unit_test_source_file_created_before_build_with_includes)

    cmake_unit_get_dirs (BINARY_DIR SOURCE_DIR)

    function (_cmake_unit_configure)

        set (GENERATE_OPTIONS
             INCLUDES my_include.h
             GENERATING_FILE "${_CURRENT_LIST_FILE}")
        cmake_unit_create_source_file_before_build (${GENERATE_OPTIONS})

        set (SOURCE_FILE "${SOURCE_DIR}/Source.cpp")
        cmake_unit_assert_that ("${SOURCE_FILE}"
                                file_contents any_line matches_regex
                                "^.include \"my_include.h\"$")

    endfunction ()

    cmake_unit_configure_config_only_test (CONFIGURE
                                           COMMAND _cmake_unit_configure)

endfunction ()

# Check that a source file by the name Source.cpp was created in
# ${CMAKE_CURRENT_SOURCE_DIR} with #include <include/my_include.h> when we call
# cmake_unit_create_source_file_before_build with
# INCLUDES ${CMAKE_CURRENT_SOURCE_DIR}/include/my_include.h
# and INCLUDE_DIRECTORIES ${CMAKE_CURRENT_SOURCE_DIR}
function (cmake_unit_test_source_file_created_with_includes_inside_inc_dir)

    cmake_unit_get_dirs (BINARY_DIR SOURCE_DIR)

    function (_cmake_unit_configure)

        set (INCLUDE_DIRECTORY "${SOURCE_DIR}")
        set (MY_INCLUDE "${INCLUDE_DIRECTORY}/include/my_include.h")
        cmake_unit_create_source_file_before_build (INCLUDES
                                                    "${MY_INCLUDE}"
                                                    INCLUDE_DIRECTORIES
                                                    "${INCLUDE_DIRECTORY}"
                                                    GENERATING_FILE
                                                    "${_CURRENT_LIST_FILE}")

        set (SOURCE_FILE "${SOURCE_DIR}/Source.cpp")
        set (EXPECTED_INCLUDES "^.include <include/my_include.h>$")
        cmake_unit_assert_that ("${SOURCE_FILE}"
                                file_contents any_line matches_regex
                                "${EXPECTED_INCLUDES}")

    endfunction ()

    cmake_unit_configure_config_only_test (CONFIGURE
                                           COMMAND _cmake_unit_configure)

endfunction ()

# Check that a source file by the name Source.cpp was created in
# ${CMAKE_CURRENT_SOURCE_DIR} with specified prepended contents
# (after defines and includes)
function (cmake_unit_test_source_file_created_has_prepended_contents)

    cmake_unit_get_dirs (BINARY_DIR SOURCE_DIR)

    function (_cmake_unit_configure)

        set (PREPEND_CONTENTS_INPUT "static int i@SEMICOLON@")
        cmake_unit_create_source_file_before_build (GENERATING_FILE
                                                    "${_CURRENT_LIST_FILE}"
                                                    PREPEND_CONTENTS
                                                    "${PREPEND_CONTENTS_INPUT}")

        set (SOURCE_FILE "${SOURCE_DIR}/Source.cpp")
        cmake_unit_assert_that ("${SOURCE_FILE}"
                                file_contents any_line matches_regex
                                "^static int i.$")

    endfunction ()

    cmake_unit_configure_config_only_test (CONFIGURE
                                           COMMAND _cmake_unit_configure)

endfunction ()

# Check that a source file by the name Source.cpp was created in
# ${CMAKE_CURRENT_SOURCE_DIR} with a declaration like
# int custom_function (); when we call
# cmake_unit_create_source_file_before_build with FUNCTIONS custom_function
function (cmake_unit_test_source_file_created_with_function_decls)

    cmake_unit_get_dirs (BINARY_DIR SOURCE_DIR)

    function (_cmake_unit_configure)

        set (GENERATE_OPTIONS
             FUNCTIONS custom_function
             GENERATING_FILE "${_CURRENT_LIST_FILE}")
        cmake_unit_create_source_file_before_build (${GENERATE_OPTIONS})

        set (SOURCE_FILE "${SOURCE_DIR}/Source.cpp")
        cmake_unit_assert_that ("${SOURCE_FILE}"
                                file_contents any_line matches_regex
                                "^int custom_function ...$")

    endfunction ()

    cmake_unit_configure_config_only_test (CONFIGURE
                                           COMMAND _cmake_unit_configure)

endfunction ()

# Check that a source file by the name Source.cpp was created in
# ${CMAKE_CURRENT_SOURCE_DIR} with a definition like
# int custom_function ()\n{\n    return 0;\n} when we call
# cmake_unit_create_source_file_before_build with FUNCTIONS custom_function
function (cmake_unit_test_source_file_created_with_function_defs)

    cmake_unit_get_dirs (BINARY_DIR SOURCE_DIR)

    function (_cmake_unit_configure)

        set (GENERATE_OPTIONS
             FUNCTIONS custom_function
             GENERATING_FILE "${_CURRENT_LIST_FILE}")
        cmake_unit_create_source_file_before_build (${GENERATE_OPTIONS})

        set (SOURCE_FILE "${SOURCE_DIR}/Source.cpp")
        cmake_unit_assert_that ("${SOURCE_FILE}"
                                file_contents any_line matches_regex
                                "^.*return 0.*$")

    endfunction ()

    cmake_unit_configure_config_only_test (INVOKE_CONFIGURE LANGUAGES C CXX
                                           CONFIGURE
                                           COMMAND _cmake_unit_configure)

endfunction ()

# Check that a source file by the name /Header.h was created in
# ${CMAKE_CURRENT_SOURCE_DIR} but does not contain a definition like
# int custom_function ()\n{\n    return 1;\n} when we call
# cmake_unit_create_source_file_before_build with FUNCTIONS custom_function
function (cmake_unit_test_source_file_created_no_function_defs_if_header)

    cmake_unit_get_dirs (BINARY_DIR SOURCE_DIR)

    function (_cmake_unit_configure)

        set (GENERATE_OPTIONS
             NAME "Header.h"
             FUNCTIONS custom_function
             GENERATING_FILE "${_CURRENT_LIST_FILE}")
        cmake_unit_create_source_file_before_build (${GENERATE_OPTIONS})

        set (HEADER_FILE "${SOURCE_DIR}/Header.h")
        cmake_unit_assert_that ("${HEADER_FILE}"
                                not file_contents any_line
                                matches_regex "^.*return 1.*$")

    endfunction ()

    cmake_unit_configure_config_only_test (CONFIGURE
                                           COMMAND _cmake_unit_configure)

endfunction ()

# Check that a source file by the name /Header.h was created in
# ${CMAKE_CURRENT_SOURCE_DIR} and contains header guards like
# #ifdef HEADER_H
# #define HEADER_H
# ...
# #endif
function (cmake_unit_test_source_file_created_header_guards_if_header)

    cmake_unit_get_dirs (BINARY_DIR SOURCE_DIR)

    function (_cmake_unit_configure)

        set (GENERATE_OPTIONS
             NAME "Header.h"
             GENERATING_FILE "${_CURRENT_LIST_FILE}"
             PREPEND_CONTENTS "int foo@SEMICOLON@")
        cmake_unit_create_source_file_before_build (${GENERATE_OPTIONS})

        cmake_unit_assert_that ("${SOURCE_DIR}/Header.h"
                                file_contents any_line matches_regex
                                "^.*ifndef HEADER_H")
        cmake_unit_assert_that ("${SOURCE_DIR}/Header.h"
                                file_contents any_line matches_regex
                                "^.*define HEADER_H")
        cmake_unit_assert_that ("${SOURCE_DIR}/Header.h"
                                file_contents any_line matches_regex
                                "^.*endif")

    endfunction ()

    cmake_unit_configure_config_only_test (CONFIGURE
                                           COMMAND _cmake_unit_configure)

endfunction ()

# A macro between tests to copy in a common "covered file"
# and run CMakeTraceToLCov on it. Assertions are then made
# based on that file. This macro sets variables which are read
# in the parent scope, so keep it as a macro.
macro (_cmake_unit_test_run_trace_to_lcov RETURN_LCOV_PATH)

    set (FILE_FOR_COVERAGE_LOCAL_PATH
         "${CMAKE_CURRENT_SOURCE_DIR}/FileForCoverage.cmake")
    file (READ "${FILE_FOR_COVERAGE_PATH}" FILE_FOR_COVERAGE_CONTENTS)
    cmake_unit_write_if_newer ("${FILE_FOR_COVERAGE_LOCAL_PATH}"
                               "${_CURRENT_LIST_FILE}"
                               "${FILE_FOR_COVERAGE_CONTENTS}")

    set (UNEXECUTED_FILE_FOR_COVERAGE_LOCAL_PATH
         "${CMAKE_CURRENT_SOURCE_DIR}/UnexecutedFileForCoverage.cmake")
    file (READ "${UNEXECUTED_FILE_FOR_COVERAGE_PATH}"
          UNEXECUTED_FILE_FOR_COVERAGE_CONTENTS)
    cmake_unit_write_if_newer ("${UNEXECUTED_FILE_FOR_COVERAGE_LOCAL_PATH}"
                               "${_CURRENT_LIST_FILE}"
                               "${UNEXECUTED_FILE_FOR_COVERAGE_CONTENTS}")

    set (MOCK_TRACEFILE_OUTPUT
         "${CMAKE_CURRENT_BINARY_DIR}/MockTracefile.trace")
    configure_file ("${MOCK_TRACEFILE_INPUT}"
                    "${MOCK_TRACEFILE_OUTPUT}"
                    @ONLY)

    set (TRACEFILE "${MOCK_TRACEFILE_OUTPUT}" CACHE STRING "" FORCE)
    set (LCOV_OUTPUT "${CMAKE_CURRENT_BINARY_DIR}/mock_test_coverage.lcov"
         CACHE STRING "" FORCE)
    set ("${RETURN_LCOV_PATH}" "${LCOV_OUTPUT}")  # Shorthand, for use in tests

    include (CMakeTraceToLCov)

endmacro ()

# Check that lines starting with a "#" are not executable
# with CMakeTraceToLCov
function (cmake_unit_test_lines_starting_with_comment_not_executable)

    function (_cmake_unit_configure)

        _cmake_unit_test_run_trace_to_lcov (LCOV)

        set (EXECUTABLE_LINES_VAR
             "_${FILE_FOR_COVERAGE_LOCAL_PATH}_EXECUTABLE_LINES")
        cmake_unit_assert_that ("${EXECUTABLE_LINES_VAR}"
                                not list_contains_value
                                STRING EQUAL "1")
        cmake_unit_assert_that ("${LCOV}"
                                not file_contents any_line
                                matches_regex "^DA:1$")

    endfunction ()

    cmake_unit_configure_config_only_test (CONFIGURE
                                           COMMAND _cmake_unit_configure)

endfunction ()

# Check that lines starting with a "\n" or just whitespace are not executable
# with CMakeTraceToLCov
function (cmake_unit_test_lines_with_no_content_not_executable)

    function (_cmake_unit_configure)

        _cmake_unit_test_run_trace_to_lcov (LCOV)

        set (EXECUTABLE_LINES_VAR
             "_${FILE_FOR_COVERAGE_LOCAL_PATH}_EXECUTABLE_LINES")
        cmake_unit_assert_that ("${EXECUTABLE_LINES_VAR}"
                                not list_contains_value
                                STRING EQUAL "7")
        cmake_unit_assert_that ("${EXECUTABLE_LINES_VAR}"
                                not list_contains_value
                                STRING EQUAL "10")

        cmake_unit_assert_that ("${LCOV}"
                                not file_contents any_line
                                matches_regex "^DA:7$")
        cmake_unit_assert_that ("${LCOV}"
                                not file_contents any_line
                                matches_regex "^DA:10$")

    endfunction ()

    cmake_unit_configure_config_only_test (CONFIGURE
                                           COMMAND _cmake_unit_configure)

endfunction ()

# Check that lines starting with ".*end" are not executable
function (cmake_unit_test_lines_starting_with_end_not_executable)

    function (_cmake_unit_configure)

        _cmake_unit_test_run_trace_to_lcov (LCOV)

        set (EXECUTABLE_LINES_VAR
             "_${FILE_FOR_COVERAGE_LOCAL_PATH}_EXECUTABLE_LINES")
        cmake_unit_assert_that ("${EXECUTABLE_LINES_VAR}"
                                not list_contains_value STRING EQUAL "3")
        cmake_unit_assert_that ("${EXECUTABLE_LINES_VAR}"
                                not list_contains_value STRING EQUAL "19")
        cmake_unit_assert_that ("${EXECUTABLE_LINES_VAR}"
                                not list_contains_value STRING EQUAL "28")
        cmake_unit_assert_that ("${EXECUTABLE_LINES_VAR}"
                                not list_contains_value STRING EQUAL "34")
        cmake_unit_assert_that ("${EXECUTABLE_LINES_VAR}"
                                not list_contains_value STRING EQUAL "36")

        cmake_unit_assert_that ("${LCOV}" not file_contents any_line
                                matches_regex "^DA:3$")
        cmake_unit_assert_that ("${LCOV}" not file_contents any_line
                                matches_regex "^DA:19$")
        cmake_unit_assert_that ("${LCOV}" not file_contents any_line
                                matches_regex "^DA:28$")
        cmake_unit_assert_that ("${LCOV}" not file_contents any_line
                                matches_regex "^DA:34$")
        cmake_unit_assert_that ("${LCOV}" not file_contents any_line
                                matches_regex "^DA:36$")

    endfunction ()

    cmake_unit_configure_config_only_test (CONFIGURE
                                           COMMAND _cmake_unit_configure)

endfunction ()

# Check that lines overflowing after an initial open-brace are not executable
# until the brace is closed on the end of the line
function (cmake_unit_test_lines_until_close_bracket_not_executable)

    function (_cmake_unit_configure)

        _cmake_unit_test_run_trace_to_lcov (LCOV)

        set (EXECUTABLE_LINES_VAR
             "_${FILE_FOR_COVERAGE_LOCAL_PATH}_EXECUTABLE_LINES")
        cmake_unit_assert_that ("${EXECUTABLE_LINES_VAR}"
                                not list_contains_value STRING EQUAL "6")
        cmake_unit_assert_that ("${EXECUTABLE_LINES_VAR}"
                                not list_contains_value STRING EQUAL "22")

        cmake_unit_assert_that ("${LCOV}" not file_contents any_line
                                matches_regex "^DA:6$")
        cmake_unit_assert_that ("${LCOV}" not file_contents any_line
                                matches_regex "^DA:22$")

    endfunction ()

    cmake_unit_configure_config_only_test (CONFIGURE
                                           COMMAND _cmake_unit_configure)

endfunction ()

# Check that lines overflowing after an initial open-brace are not executable
# until the brace is closed on the end of the line
function (cmake_unit_test_interleaved_comments_until_close_bracket_no_exec)

    function (_cmake_unit_configure)

        _cmake_unit_test_run_trace_to_lcov (LCOV)

        set (EXECUTABLE_LINES_VAR
             "_${FILE_FOR_COVERAGE_LOCAL_PATH}_EXECUTABLE_LINES")
        cmake_unit_assert_that ("${EXECUTABLE_LINES_VAR}"
                                not list_contains_value STRING EQUAL "39")
        cmake_unit_assert_that ("${EXECUTABLE_LINES_VAR}"
                                not list_contains_value STRING EQUAL "40")
        cmake_unit_assert_that ("${EXECUTABLE_LINES_VAR}"
                                not list_contains_value STRING EQUAL "41")
        cmake_unit_assert_that ("${EXECUTABLE_LINES_VAR}"
                                not list_contains_value STRING EQUAL "42")

        cmake_unit_assert_that ("${LCOV}" not file_contents any_line
                                matches_regex "^DA:39$")
        cmake_unit_assert_that ("${LCOV}" not file_contents any_line
                                matches_regex "^DA:40$")
        cmake_unit_assert_that ("${LCOV}" not file_contents any_line
                                matches_regex "^DA:41$")
        cmake_unit_assert_that ("${LCOV}" not file_contents any_line
                                matches_regex "^DA:42$")

    endfunction ()

    cmake_unit_configure_config_only_test (CONFIGURE
                                           COMMAND _cmake_unit_configure)

endfunction ()

# Check that semicolons in the middle of the file don't cause extra lines to be
# added (such that we get a bogus line report from CMakeTraceToLCov)
function (cmake_unit_test_semicolons_dont_break_lines)

    function (_cmake_unit_configure)

        _cmake_unit_test_run_trace_to_lcov (LCOV)

        set (EXECUTABLE_LINES_VAR
             "_${FILE_FOR_COVERAGE_LOCAL_PATH}_EXECUTABLE_LINES")
        cmake_unit_assert_that ("${EXECUTABLE_LINES_VAR}"
                                not list_contains_value STRING EQUAL "15")

        cmake_unit_assert_that ("${LCOV}" not file_contents any_line
                                matches_regex "^DA:15$")

    endfunction ()

    cmake_unit_configure_config_only_test (CONFIGURE
                                           COMMAND _cmake_unit_configure)

endfunction ()

# Check that \n in the middle of the line don't cause extra lines to be
# added (such that we get a bogus line report from CMakeTraceToLCov)
function (cmake_unit_test_slash_n_doesnt_break_lines)

    function (_cmake_unit_configure)

        _cmake_unit_test_run_trace_to_lcov (LCOV)

        set (EXECUTABLE_LINES_VAR
             "_${FILE_FOR_COVERAGE_LOCAL_PATH}_EXECUTABLE_LINES")
        cmake_unit_assert_that ("${EXECUTABLE_LINES_VAR}"
                                not list_contains_value STRING EQUAL "17")

        cmake_unit_assert_that ("${LCOV}" not file_contents any_line
                                matches_regex "^DA:17$")

    endfunction ()

    cmake_unit_configure_config_only_test (CONFIGURE
                                           COMMAND _cmake_unit_configure)

endfunction ()

# All files, eg
# - /FileForCoverage.cmake
# - /UnexecutedFileForCoverage.cmake
# Have coverage information
function (cmake_unit_test_all_files_specified_in_trace_file_have_coverage)

    function (_cmake_unit_configure)

        _cmake_unit_test_run_trace_to_lcov (LCOV)

        set (EXECUTED_FILE_FOR_COV "^SF:.*FileForCoverage.*$")
        set (UNEXECUTED_FILE_FOR_COV "^SF:.*UnexecutedFileForCoverage.*$")

        cmake_unit_assert_that ("${LCOV}" file_contents any_line
                                matches_regex
                                "${EXECUTED_FILE_FOR_COV}")
        cmake_unit_assert_that ("${LCOV}" file_contents any_line
                                matches_regex
                                "${UNEXECUTED_FILE_FOR_COV}")

    endfunction ()

    cmake_unit_configure_config_only_test (CONFIGURE
                                           COMMAND _cmake_unit_configure)

endfunction ()

# Anything else not part of an exclusionary rule should be marked executable.
function (cmake_unit_test_other_lines_executable)

    function (_cmake_unit_configure)

        _cmake_unit_test_run_trace_to_lcov (LCOV)

        set (EXECUTABLE_LINES_VAR
             "_${FILE_FOR_COVERAGE_LOCAL_PATH}_EXECUTABLE_LINES")
        cmake_unit_assert_that ("${EXECUTABLE_LINES_VAR}" list_contains_value
                                STRING EQUAL "2")
        cmake_unit_assert_that ("${EXECUTABLE_LINES_VAR}" list_contains_value
                                STRING EQUAL "5")
        cmake_unit_assert_that ("${EXECUTABLE_LINES_VAR}" list_contains_value
                                STRING EQUAL "11")
        cmake_unit_assert_that ("${EXECUTABLE_LINES_VAR}" list_contains_value
                                STRING EQUAL "13")
        cmake_unit_assert_that ("${EXECUTABLE_LINES_VAR}" list_contains_value
                                STRING EQUAL "14")
        cmake_unit_assert_that ("${EXECUTABLE_LINES_VAR}" list_contains_value
                                STRING EQUAL "21")
        cmake_unit_assert_that ("${EXECUTABLE_LINES_VAR}" list_contains_value
                                STRING EQUAL "24")
        cmake_unit_assert_that ("${EXECUTABLE_LINES_VAR}" list_contains_value
                                STRING EQUAL "26")
        cmake_unit_assert_that ("${EXECUTABLE_LINES_VAR}" list_contains_value
                                STRING EQUAL "30")
        cmake_unit_assert_that ("${EXECUTABLE_LINES_VAR}" list_contains_value
                                STRING EQUAL "32")

    endfunction ()

    cmake_unit_configure_config_only_test (CONFIGURE
                                           COMMAND _cmake_unit_configure)

endfunction ()

# All hit-and-executable lines have a DA counter of > 0.
function (cmake_unit_test_hit_lines_have_non_zero_d_a_counter)

    function (_cmake_unit_configure)

        _cmake_unit_test_run_trace_to_lcov (LCOV)

        cmake_unit_assert_that ("${LCOV}" file_contents any_line
                                matches_regex "^DA:2,1$")
        cmake_unit_assert_that ("${LCOV}" file_contents any_line
                                matches_regex "^DA:5,1$")
        cmake_unit_assert_that ("${LCOV}" file_contents any_line
                                matches_regex "^DA:11,1$")
        cmake_unit_assert_that ("${LCOV}" file_contents any_line
                                matches_regex "^DA:13,1$")
        cmake_unit_assert_that ("${LCOV}" file_contents any_line
                                matches_regex "^DA:14,1$")
        cmake_unit_assert_that ("${LCOV}" file_contents any_line
                                matches_regex "^DA:16,1$")
        cmake_unit_assert_that ("${LCOV}" file_contents any_line
                                matches_regex "^DA:21,1$")
        cmake_unit_assert_that ("${LCOV}" file_contents any_line
                                matches_regex "^DA:24,1$")
        cmake_unit_assert_that ("${LCOV}" file_contents any_line
                                matches_regex "^DA:26,1$")
        cmake_unit_assert_that ("${LCOV}" file_contents any_line
                                matches_regex "^DA:30,1$")

    endfunction ()

    cmake_unit_configure_config_only_test (CONFIGURE
                                           COMMAND _cmake_unit_configure)

endfunction ()

# All missed-but-executable lines have a DA counter of zero.
function (cmake_unit_test_missed_lines_have_non_zero_d_a_counter)

    function (_cmake_unit_configure)

        _cmake_unit_test_run_trace_to_lcov (LCOV)

        cmake_unit_assert_that ("${LCOV}" file_contents any_line
                                matches_regex "^DA:32,0$")

    endfunction ()

    cmake_unit_configure_config_only_test (CONFIGURE
                                           COMMAND _cmake_unit_configure)

endfunction ()

cmake_unit_init (NAMESPACE "cmake_unit"
                 COVERAGE_FILES
                 "${CMAKE_CURRENT_LIST_DIR}/CMakeUnitRunner.cmake"
                 "${CMAKE_CURRENT_LIST_DIR}/CMakeTraceToLCov.cmake"
                 "${CMAKE_CURRENT_LIST_DIR}/CMakeUnit.cmake")

if (BIICODE)

    add_bii_targets ()

endif ()
