# /CMakeUnitRunner.cmake
#
# The main test runner for the CMakeUnit framework.
#
# Users should first call cmake_unit_init which will
# set up some necessary global variables. Tests are organized
# into test scripts (because CMake doesn't have the ability to
# refer to function names as variables and call them later).
#
# As a performance consideration, there are two types of tests,
# CMake tests and Build Tests.
#
# Build tests are a superset of CMake tests. They will run cmake
# on the specified script, but also use cmake --build to build
# the resulting project and then run the verification script
# specified in order to check that the build succeeded in the
# way that the user expected it to. Build tests can take
# much longer to execute and should be used sparingly.
#
# See /LICENCE.md for Copyright information
if (NOT BIICODE)

    set (CMAKE_MODULE_PATH
         "${CMAKE_CURRENT_LIST_DIR}/bii/deps"
         "${CMAKE_MODULE_PATH}")

endif (NOT BIICODE)

include ("smspillaz/cmake-include-guard/IncludeGuard")
cmake_include_guard (CMAKE_UNIT_RUNNER SET_MODULE_PATH)

include (CMakeParseArguments)
include (CMakeUnit)
include ("smspillaz/cmake-call-function/CallFunction")

# Phase not set, begin PRECONFIGURE phase
if (NOT _CMAKE_UNIT_PHASE)
    set (_CMAKE_UNIT_PHASE PRECONFIGURE)
    include (CTest)

    enable_testing ()
endif ()

set (CMAKE_POLICY_CACHE_DEFINITIONS
     "--no-warn-unused-cli"
     "-DCMAKE_POLICY_DEFAULT_CMP0054=NEW"
     "-DCMAKE_POLICY_DEFAULT_CMP0056=NEW"
     "-DCMAKE_POLICY_DEFAULT_CMP0042=NEW"
     "-DCMAKE_POLICY_DEFAULT_CMP0025=NEW")

option (CMAKE_UNIT_NO_DEV_WARNINGS OFF
        "Turn off developer warnings")
option (CMAKE_UNIT_NO_UNINITIALIZED_WARNINGS OFF
        "Turn off uninitialized variable usage warnings")
option (CMAKE_UNIT_PRESERVE_BUILD_ON_COMPLETION OFF
        "Preserve contents of test build directories on completion")

if (CMAKE_UNIT_COVERAGE_FILE)

    set (CMAKE_UNIT_COVERAGE_FILE
         "${CMAKE_CURRENT_BINARY_DIR}/${CMAKE_PROJECT_NAME}.trace"
         CACHE FILE "File where coverage data will be stored")

endif ()

set (CMAKE_UNIT_TRACE_CONVERTER_LOCATION_OUTPUT ""
     CACHE FILE "Where location of CMakeTraceToLCov.cmake will be written")

if (NOT CMAKE_UNIT_TRACE_CONVERTER_LOCATION_OUTPUT STREQUAL "")

    file (WRITE "${CMAKE_UNIT_TRACE_CONVERTER_LOCATION_OUTPUT}"
          "${CMAKE_CURRENT_LIST_DIR}/CMakeTraceToLCov.cmake")

endif ()

# Whether or not we are testing cmake-unit itself.
set (_CMAKE_UNIT_INTERNAL_TESTING OFF CACHE BOOL "")
mark_as_advanced (_CMAKE_UNIT_INTERNAL_TESTING)

set (_RUNNER_LIST_DIR "${CMAKE_CURRENT_LIST_DIR}")
set (_RUNNER_LIST_FILE "${CMAKE_CURRENT_LIST_FILE}")

# _cmake_unit_runner_assert
#
# Internal function used to make assertions about internal state
#
# CONDITION: Condition to check
# [Optional] MESSAGE: Message to print when assertion fails
function (_cmake_unit_runner_assert)

    cmake_parse_arguments (CMAKE_UNIT_RUNNER_ASSERT
                           ""
                           ""
                           "CONDITION;MESSAGE"
                           ${ARGN})

    if (NOT DEFINED CMAKE_UNIT_RUNNER_ASSERT_CONDITION)

        message (FATAL_ERROR
                 "CONDITION must be passed to _cmake_unit_runner_assert")

    endif ()

    if (${CMAKE_UNIT_RUNNER_ASSERT_CONDITION})

        return ()

    else ()

        _cmake_unit_spacify (SPACIFIED_COND
                             LIST ${CMAKE_UNIT_RUNNER_ASSERT_CONDITION}
                             NO_QUOTES)

        if (NOT DEFINED CMAKE_UNIT_RUNNER_ASSERT_MESSAGE)

            set (MESSAGE "Assertion failed: ${SPACIFIED_COND}")

        else ()

            set (MESSAGE "${CMAKE_UNIT_RUNNER_ASSERT_MESSAGE} - "
                         "(${SPACIFIED_COND} failed)")

        endif ()

    endif ()

endfunction ()

# _cmake_unit_forward_arguments
#
# Internal function to forward arguments used by cmake_parse_arguments
#
# SOURCE_PREFIX: Prefix of set variables to forward from
# RETURN_LIST: List of "forwarded" variables, suitable for passing to
#              cmake_parse_arguments
# [Optional] OPTION_ARGS: "Option" arguments (true or false)
# [Optional] SINGLEVAR_ARGS: "Single variable" arguments (variable, if
#                            set, has one value. Represented by NAME VALUE)
# [Optional] MULTIVAR_ARGS: "Multi variable" arguments (variable, if set, has
#                           a list value. Represented by NAME VALUE0 ... VALUEN)
function (_cmake_unit_forward_arguments SOURCE_PREFIX RETURN_LIST)

    cmake_parse_arguments (FORWARD
                           ""
                           ""
                           "OPTION_ARGS;SINGLEVAR_ARGS;MULTIVAR_ARGS"
                           ${ARGN})

    set (_RETURN_LIST)
    foreach (FORWARDED_OPTION ${FORWARD_OPTION_ARGS})

        if (${SOURCE_PREFIX}_${FORWARDED_OPTION})

            list (APPEND _RETURN_LIST ${FORWARDED_OPTION})

        endif ()

    endforeach ()

    foreach (FORWARDED_VAR ${FORWARD_SINGLEVAR_ARGS} ${FORWARD_MULTIVAR_ARGS})

        if (${SOURCE_PREFIX}_${FORWARDED_VAR})

            list (APPEND _RETURN_LIST
                         ${FORWARDED_VAR}
                         ${${SOURCE_PREFIX}_${FORWARDED_VAR}})

        endif ()

    endforeach ()

    set (${RETURN_LIST} ${_RETURN_LIST} PARENT_SCOPE)

endfunction ()

function (_cmake_unit_discover_functions_in NAMESPACE RETURN_LIST)

    set (FUNCTIONS_LIST)
    get_property (ALL_KNOWN_COMMANDS GLOBAL PROPERTY "COMMANDS")

    foreach (KNOWN_COMMAND ${ALL_KNOWN_COMMANDS})

        if (KNOWN_COMMAND MATCHES "^${NAMESPACE}_[A-Za-z0-9_]+")

            list (APPEND FUNCTIONS_LIST ${KNOWN_COMMAND})

        endif ()

    endforeach ()

    set (${RETURN_LIST} ${FUNCTIONS_LIST} PARENT_SCOPE)

endfunction ()

function (_cmake_unit_discover_tests_in NAMESPACE RETURN_LIST)

    # Check the cache global property _CMAKE_UNIT_DISCOVERED_TESTS_${NAMESPACE}
    # first. If there's no value, then discover tests and save them in the
    # cache.
    get_property (DISCOVERED_TESTS
                  GLOBAL PROPERTY "_CMAKE_UNIT_DISCOVERED_TESTS_${NAMESPACE}")

    if (NOT DISCOVERED_TESTS)

        _cmake_unit_discover_functions_in ("${NAMESPACE}_test" DISCOVERED_TESTS)
        set_property (GLOBAL PROPERTY
                      "_CMAKE_UNIT_DISCOVERED_TESTS_${NAMESPACE}"
                      ${DISCOVERED_TESTS})

    endif ()

    set (${RETURN_LIST} ${DISCOVERED_TESTS} PARENT_SCOPE)

endfunction ()

# This is an optimization on cmake_parse_arguments which should
# help to reduce the number of times which it is called. Effectively,
# it hashes its arguments and then checks to see if we've called
# cmake_parse_arguments with this kind of hash. If we have, it uses
# the cached values.
function (_cmake_unit_parse_args_key PREFIX
                                     OPTION_ARGS_STRING
                                     SINGLEVAR_ARGS_STRING
                                     MULTIVAR_ARGS_STRING
                                     RETURN_KEY)

    # First get the key for this argv set
    string (MD5 CACHE_KEY "${ARGV}")

    # Lookup to see if we've parsed arguments like these before
    get_property (CACHE_KEY_IS_SET
                  GLOBAL
                  PROPERTY _CMAKE_UNIT_CACHED_${CACHE_KEY})
    if (NOT CACHE_KEY_IS_SET)

        # Cache key was not set. Parse arguments and then store the
        # results in global properties.
        cmake_parse_arguments (${PREFIX}
                               "${OPTION_ARGS_STRING}"
                               "${SINGLEVAR_ARGS_STRING}"
                               "${MULTIVAR_ARGS_STRING}"
                               ${ARGN})

        set (VARIABLES ${OPTION_ARGS_STRING}
                       ${SINGLEVAR_ARGS_STRING}
                       ${MULTIVAR_ARGS_STRING})

        foreach (VAR ${VARIABLES})

            set_property (GLOBAL
                          PROPERTY _CMAKE_UNIT_PARSE_CACHE_${CACHE_KEY}_${VAR}
                          "${${PREFIX}_${VAR}}")

        endforeach ()

        set_property (GLOBAL
                      PROPERTY _CMAKE_UNIT_CACHED_${CACHE_KEY}
                      TRUE)

    endif ()

    set (${RETURN_KEY} ${CACHE_KEY} PARENT_SCOPE)

endfunction ()

function (_cmake_unit_fetch_parsed_arg CACHE_KEY PREFIX ARGUMENT)

    get_property (VALUE GLOBAL
                  PROPERTY _CMAKE_UNIT_PARSE_CACHE_${CACHE_KEY}_${ARGUMENT})
    set (${PREFIX}_${ARGUMENT} "${VALUE}" PARENT_SCOPE)

endfunction ()

function (cmake_unit_init)

    _cmake_unit_parse_args_key (CMAKE_UNIT_INIT
                                ""
                                ""
                                "NAMESPACE;COVERAGE_FILES"
                                PARSE_KEY
                                ${ARGN})

    _cmake_unit_fetch_parsed_arg (${PARSE_KEY} CMAKE_UNIT_INIT NAMESPACE)
    _cmake_unit_discover_tests_in (${CMAKE_UNIT_INIT_NAMESPACE}
                                   CMAKE_UNIT_INIT_TESTS)

    if (CMAKE_UNIT_COVERAGE_FILE)

        # Escape characters out of filenames that will cause problems when
        # attempting to regex match them later
        _cmake_unit_fetch_parsed_arg (${PARSE_KEY} CMAKE_UNIT_INIT
                                      COVERAGE_FILES)
        foreach (COVERAGE_FILE ${CMAKE_UNIT_INIT_COVERAGE_FILES})

            cmake_unit_escape_string ("${COVERAGE_FILE}" ESCAPED_COVERAGE_FILE)
            list (APPEND ESCAPED_COVERAGE_FILES "${ESCAPED_COVERAGE_FILE}")

        endforeach ()

        set_property (GLOBAL PROPERTY _CMAKE_UNIT_COVERAGE_LOGGING_FILES
                      ${ESCAPED_COVERAGE_FILES})

        # Clobber the coverage report, but only if we're in the PRECONFIGURE
        # phase (so that we don't end up overwriting it on every phase)
        if (_CMAKE_UNIT_PHASE STREQUAL "PRECONFIGURE")

            file (WRITE "${CMAKE_UNIT_COVERAGE_FILE}" "")

        endif ()

    endif ()

    if (_CMAKE_UNIT_ACTIVE_TEST)

        set (FUNCTIONS_TO_CALL ${_CMAKE_UNIT_ACTIVE_TEST})

    else ()

        set (FUNCTIONS_TO_CALL ${CMAKE_UNIT_INIT_TESTS})

    endif ()

    foreach (FUNCTION ${FUNCTIONS_TO_CALL})

        set (BASE_BINARY_DIR "${CMAKE_CURRENT_BINARY_DIR}")

        if (CMAKE_UNIT_PARENT_BINARY_DIR)

            set (BASE_BINARY_DIR "${CMAKE_UNIT_PARENT_BINARY_DIR}")

        endif ()

        set (TEST_SOURCE_DIR "${BASE_BINARY_DIR}/${FUNCTION}")
        set (TEST_BINARY_DIR "${TEST_SOURCE_DIR}/build")

        # Pass source and binary directory to test here as it will be the same
        # for all phases and we can use the directories in per-test variables
        # easily.
        cmake_call_function (${FUNCTION}
                             SOURCE_DIR "${TEST_SOURCE_DIR}"
                             BINARY_DIR "${TEST_BINARY_DIR}")

    endforeach ()

    unset (_CMAKE_UNIT_PHASE)
    unset (_CMAKE_UNIT_ACTIVE_TEST)

endfunction ()

function (_cmake_unit_spacify RETURN_SPACED)

    _cmake_unit_parse_args_key (SPACIFY
                                "NO_QUOTES"
                                ""
                                "LIST"
                                PARSE_KEY ${ARGN})
    _cmake_unit_fetch_parsed_arg (${PARSE_KEY} SPACIFY LIST)

    set (SPACIFIED "")
    foreach (ELEMENT ${SPACIFY_LIST})

        if (SPACIFY_NO_QUOTES)

            set (SPACIFIED "${SPACIFIED}${ELEMENT} ")

        else ()

            set (SPACIFIED "${SPACIFIED}\"${ELEMENT}\" ")

        endif ()

    endforeach ()

    string (STRIP "${SPACIFIED}" SPACIFIED)
    set (${RETURN_SPACED} "${SPACIFIED}" PARENT_SCOPE)

endfunction ()

# Gets a set_property line in a script which contains the forwarded
# version of our GLOBAL property GLOBAL
function (_cmake_unit_forwarded_script_prop_line RETURN_LINE PROPERTY)

    get_property (VALUE GLOBAL PROPERTY "${PROPERTY}")
    _cmake_unit_spacify (SPACIFIED_VALUE LIST ${VALUE})
    set (${RETURN_LINE}
         "set_property (GLOBAL PROPERTY ${PROPERTY} ${SPACIFIED_VALUE})\n"
         PARENT_SCOPE)

endfunction ()

# Generates a header common to all child scripts.
function (_cmake_unit_get_child_invocation_script_header HEADER_RETURN)

    # Get the cached dispatch table names for TEST_NAME and forward them
    # on to the child script. The list must be converted into a space
    # separated string.
    set (CACHED_DISPATCH_TABLE_PROPERTY
         "_CMAKE_UNIT_DISPATCH_CONFIGURE_DISPATCH_FOR_${TEST_NAME}")
    _cmake_unit_forwarded_script_prop_line (DISPATCH_TABLE_PROP_LINE
                                            ${CACHED_DISPATCH_TABLE_PROPERTY})

    # Get the list of tests for this namespace. The namespace is every character
    # before the word "_test" in the TEST_NAME
    string (FIND "${TEST_NAME}" "_test" TEST_MARKER_INDEX)
    string (SUBSTRING "${TEST_NAME}" 0 ${TEST_MARKER_INDEX} NAMESPACE)
    set (CACHED_DISCOVERED_TESTS_PROPERTY
         "_CMAKE_UNIT_DISCOVERED_TESTS_${NAMESPACE}")
    _cmake_unit_forwarded_script_prop_line (DISCOVERED_TESTS_PROP_LINE
                                            ${CACHED_DISCOVERED_TESTS_PROPERTY})

    _cmake_unit_spacify (SPACIFIED_MODULE_PATH LIST "${CMAKE_MODULE_PATH}")

    set (${HEADER_RETURN}
         "set (CMAKE_MODULE_PATH \"${_RUNNER_LIST_DIR}\"\n"
         "     ${SPACIFIED_MODULE_PATH})\n"
         "set (_CMAKE_UNIT_ACTIVE_TEST ${TEST_NAME})\n"
         "set (CMAKE_UNIT_COVERAGE_FILE \"${CMAKE_UNIT_COVERAGE_FILE}\"\n"
         "     CACHE STRING \"\" FORCE)\n"
         "set (CMAKE_GENERATOR \"${CMAKE_GENERATOR}\")\n"
         ${DISPATCH_TABLE_PROP_LINE}
         ${DISCOVERED_TESTS_PROP_LINE}
         PARENT_SCOPE)

endfunction ()

function (_cmake_unit_preconfigure_test)

    cmake_parse_arguments (PRECONFIGURE_TEST
                           ""
                           "TEST_NAME;BINARY_DIR;SOURCE_DIR"
                           ""
                           ${CALLER_ARGN})

    set (TEST_NAME "${PRECONFIGURE_TEST_TEST_NAME}")
    set (DRIVER_SCRIPT "${PRECONFIGURE_TEST_SOURCE_DIR}/Driver.cmake")
    set (COVERAGE_SCRIPT "${PRECONFIGURE_TEST_SOURCE_DIR}/Coverage.cmake")

    file (MAKE_DIRECTORY "${PRECONFIGURE_TEST_SOURCE_DIR}")
    file (MAKE_DIRECTORY "${PRECONFIGURE_TEST_BINARY_DIR}")

    get_property (COVERAGE_FILES_LIST
                  GLOBAL PROPERTY _CMAKE_UNIT_COVERAGE_LOGGING_FILES)

    _cmake_unit_spacify (COVERAGE_FILES LIST ${COVERAGE_FILES_LIST})

    _cmake_unit_get_child_invocation_script_header (COMMON_PROLOGUE)

    # /Driver.cmake writs some initial variable definitions
    file (WRITE "${DRIVER_SCRIPT}"
          "set (_CMAKE_UNIT_PHASE CLEAN)\n"
          ${COMMON_PROLOGUE}
          "set (CMAKE_GENERATOR \"${CMAKE_GENERATOR}\")\n"
          "set (CMAKE_UNIT_NO_DEV_WARNINGS ${CMAKE_UNIT_NO_DEV_WARNINGS}\n"
          "     CACHE BOOL \"\" FORCE)\n"
          "set (CMAKE_UNIT_NO_UNINITIALIZED_WARNINGS\n"
          "     ${CMAKE_UNIT_NO_UNINITIALIZED_WARNINGS}\n"
          "     CACHE BOOL \"\" FORCE)\n"
          "set (CMAKE_PROJECT_NAME \"${CMAKE_PROJECT_NAME}\")\n"
          "set_property (GLOBAL PROPERTY _CMAKE_UNIT_COVERAGE_LOGGING_FILES\n"
          "              ${COVERAGE_FILES})\n"
          "include (\"${CMAKE_CURRENT_LIST_FILE}\")\n")

    # /Coverage.cmake is intended to wrap /Driver.cmake and write trace data
    # into CMAKE_UNIT_COVERAGE_FILE
    _cmake_unit_spacify (POLICY_CACHE_DEFS_SPACIFIED
                         LIST ${CMAKE_POLICY_CACHE_DEFINITIONS})
    set (DRIVER_OUTPUT_LOG "${CMAKE_CURRENT_BINARY_DIR}/DRIVER.output")
    set (DRIVER_ERROR_LOG "${CMAKE_CURRENT_BINARY_DIR}/DRIVER.error")

    set (TRACE_OPTION)
    if (CMAKE_UNIT_COVERAGE_FILE AND
        _CMAKE_UNIT_INTERNAL_TESTING)

        set (TRACE_OPTION "--trace")

    endif ()

    get_filename_component (ABSOLUTE_COVERAGE_FILE_PATH
                            "${CMAKE_UNIT_COVERAGE_FILE}"
                            ABSOLUTE)

    # Working around a bug in cmakelint
    set (END "end")
    file (WRITE "${COVERAGE_SCRIPT}"
          ${COMMON_PROLOGUE}
          "set (_CMAKE_UNIT_PHASE UTILITY)\n"
          "include (\"${_RUNNER_LIST_FILE}\")\n"
          "_cmake_unit_invoke_command (COMMAND \"${CMAKE_COMMAND}\"\n"
          "                                    ${POLICY_CACHE_DEFS_SPACIFIED}\n"
          "                                    -P \"${DRIVER_SCRIPT}\"\n"
          "                                    ${TRACE_OPTION}\n"
          "                            OUTPUT_FILE \"${DRIVER_OUTPUT_LOG}\"\n"
          "                            ERROR_FILE \"${DRIVER_ERROR_LOG}\"\n"
          "                            PHASE DRIVER)\n"
          "set (LOG_COVERAGE \"${CMAKE_UNIT_COVERAGE_FILE}\")\n"
          "if (LOG_COVERAGE)\n"
          "    _cmake_unit_filter_trace_lines (FILTERED_LINES\n"
          "                                    TEST_NAME \"${TEST_NAME}\"\n"
          "                                    TRACE_FILE\n"
          "                                    \"\${LOG_COVERAGE}\"\n"
          "                                    COVERAGE_FILES\n"
          "                                    ${COVERAGE_FILES})\n"
          "    file (APPEND \"${ABSOLUTE_COVERAGE_FILE_PATH}\"\n"
          "          \${FILTERED_LINES})\n"
          "${END}if ()\n")

    # The test step invokes the script at the INVOKE_CONFIGURE
    # phase, which will then move on to the other phases once its done.
    add_test ("${TEST_NAME}"
              "${CMAKE_COMMAND}"
              ${CMAKE_POLICY_CACHE_DEFINITIONS}
              -P
              "${COVERAGE_SCRIPT}"
              WORKING_DIRECTORY
              "${PRECONFIGURE_TEST_BINARY_DIR}")

endfunction ()

function (cmake_unit_invoke_clean)

    cmake_parse_arguments (CLEAN
                           ""
                           "BINARY_DIR"
                           ""
                           ${CALLER_ARGN})

    file (REMOVE_RECURSE "${CLEAN_BINARY_DIR}")
    file (MAKE_DIRECTORY "${CLEAN_BINARY_DIR}")

endfunction ()

function (cmake_unit_invoke_rm_build)

    if (CMAKE_UNIT_PRESERVE_BUILD_ON_COMPLETION)

        return ()

    endif ()

    cmake_parse_arguments (RM_BUILD
                           ""
                           "BINARY_DIR;SOURCE_DIR"
                           ""
                           ${CALLER_ARGN})

    file (REMOVE_RECURSE "${RM_BUILD_BINARY_DIR}")
    file (REMOVE_RECURSE "${RM_BUILD_SOURCE_DIR}")

endfunction ()

# Parse INPUT_FILE, remove a problematic regex and write to OUTPUT_FILE
function (_cmake_unit_remove_problematic_regex PHASE
                                               LOG_TYPE
                                               INPUT_FILE
                                               OUTPUT_FILE)

    # We only need to do this if the phase is INVOKE_CONFIGURE
    if (PHASE STREQUAL "INVOKE_CONFIGURE" AND LOG_TYPE STREQUAL "ERROR")

        set (REMOVE_REGEX_FILE
             "util/RemoveProblematicRegexFromFile.cmake")

        execute_process (COMMAND "${CMAKE_COMMAND}"
                                 "-DINPUT_FILE:FILEPATH=${INPUT_FILE}"
                                 "-DOUTPUT_FILE:FILEPATH=${OUTPUT_FILE}"
                                 ${CMAKE_POLICY_CACHE_DEFINITIONS}
                                 -P
                                 "${_RUNNER_LIST_DIR}/${REMOVE_REGEX_FILE}")

    endif ()

endfunction ()

function (_cmake_unit_print_lines_for_log PHASE
                                          LOG_TYPE
                                          LOG_FILE)

    file (STRINGS "${LOG_FILE}" LINES)

    set (FILTER_PRINTED_LINES OFF)
    if (PHASE STREQUAL INVOKE_CONFIGURE OR
        PHASE STREQUAL DRIVER)

        set (FILTER_PRINTED_LINES ON)

    endif ()

    # Print error lines to stderr and output lines to stdout, mimicking the
    # same format for each
    if (LOG_TYPE STREQUAL "ERROR")

        set (MESSAGE_INITIAL_ARGS "-- ")

    elseif (LOG_TYPE STREQUAL "OUTPUT")

        set (MESSAGE_INITIAL_ARGS STATUS)

    endif ()

    # Attempt to filter out trace-file like lines
    if (FILTER_PRINTED_LINES AND LOG_TYPE STREQUAL ERROR)

        foreach (LINE ${LINES})

            if (NOT LINE MATCHES "^.+\\([0-9]+\\):  .+$")

                message (${MESSAGE_INITIAL_ARGS} "${PHASE} ERROR ${LINE}")

            endif ()

        endforeach ()

    else ()

        foreach (LINE ${LINES})

            message (${MESSAGE_INITIAL_ARGS} "${PHASE} ${LOG_TYPE} ${LINE}")

        endforeach ()

    endif ()

endfunction ()

set (_CMAKE_UNIT_ALL_INVOKE_OPTION_ARGS ALLOW_FAIL)
set (_CMAKE_UNIT_ALL_INVOKE_SINGLEVAR_ARGS OUTPUT_FILE
                                           ERROR_FILE
                                           COMMAND
                                           TEST_NAME
                                           SOURCE_DIR
                                           BINARY_DIR)

function (_cmake_unit_invoke_command)

    set (CMAKE_UNIT_INVOKE_COMMAND_SINGLEVAR_ARGS PHASE
                                                  OUTPUT_FILE
                                                  ERROR_FILE
                                                  WORKING_DIRECTORY)

    cmake_parse_arguments (INVOKE_COMMAND
                           "ALLOW_FAIL"
                           "${CMAKE_UNIT_INVOKE_COMMAND_SINGLEVAR_ARGS}"
                           "COMMAND"
                           ${ARGN})

    _cmake_unit_spacify (SPACIFIED_COMMAND
                         LIST ${INVOKE_COMMAND_COMMAND}
                         NO_QUOTES)
    message (STATUS "Running ${SPACIFIED_COMMAND}")

    execute_process (COMMAND ${INVOKE_COMMAND_COMMAND}
                     OUTPUT_VARIABLE COMMAND_OUTPUT
                     ERROR_VARIABLE COMMAND_ERROR
                     RESULT_VARIABLE RESULT
                     WORKING_DIRECTORY "${INVOKE_COMMAND_WORKING_DIRECTORY}")

    # We need to write the log files after and not during execution as there's
    # chance we could run a command which wipes out the directory holding the
    # log files
    file (WRITE "${INVOKE_COMMAND_OUTPUT_FILE}" "${COMMAND_OUTPUT}")
    file (WRITE "${INVOKE_COMMAND_ERROR_FILE}" "${COMMAND_ERROR}")

    # Print the contents of each logfile, if they exist
    set (LOG_TYPES OUTPUT ERROR)
    foreach (LOG_TYPE ${LOG_TYPES})

        set (LOG_FILE "${INVOKE_COMMAND_${LOG_TYPE}_FILE}")

        if (LOG_FILE AND EXISTS "${LOG_FILE}")

            # HACK: Remove square brackets as their presence can confuse
            # CMake into not using ; as a list delimiter. We can't even use
            # the character here as it will cause confusion in coverage mode.
            _cmake_unit_remove_problematic_regex (${INVOKE_COMMAND_PHASE}
                                                  ${LOG_TYPE}
                                                  "${LOG_FILE}"
                                                  "${LOG_FILE}")
            _cmake_unit_print_lines_for_log (${INVOKE_COMMAND_PHASE}
                                             ${LOG_TYPE}
                                             "${LOG_FILE}")

        endif ()

    endforeach ()

    # Check for command failure if appropriate
    if (NOT INVOKE_COMMAND_ALLOW_FAIL AND NOT RESULT EQUAL 0)

        message (FATAL_ERROR "The command ${SPACIFIED_COMMAND}"
                             " failed with ${RESULT}")

    endif ()

endfunction ()

function (cmake_unit_invoke_configure)

    set (INVOKE_CONFIGURE_OPTION_ARGS ${_CMAKE_UNIT_ALL_INVOKE_OPTION_ARGS}
                                      ALLOW_WARNINGS)
    set (INVOKE_CONFIGURE_MULTIVAR_ARGS FORWARD_CACHE_VALUES
                                        LANGUAGES)

    cmake_parse_arguments (INVOKE_CONFIGURE
                           "${INVOKE_CONFIGURE_OPTION_ARGS}"
                           "${_CMAKE_UNIT_ALL_INVOKE_SINGLEVAR_ARGS}"
                           "${INVOKE_CONFIGURE_MULTIVAR_ARGS}"
                           ${CALLER_ARGN})

    set (TEST_CMAKELISTS_TXT "${INVOKE_CONFIGURE_SOURCE_DIR}/CMakeLists.txt")

    # If INVOKE_CONFIGURE_LANGUAGES has no value, then set it to the special
    # value of NONE, where no languages are configured.
    if (NOT INVOKE_CONFIGURE_LANGUAGES)

        set (INVOKE_CONFIGURE_LANGUAGES NONE)

    endif ()

    _cmake_unit_get_child_invocation_script_header (COMMON_PROLOGUE)

    # Write out ${INVOKE_CONFIGURE_SOURCE_DIR}/CMakeLists.txt. This is a special
    # case where we re-include everything, this time in project-processing mode
    file (WRITE "${TEST_CMAKELISTS_TXT}"
          "cmake_minimum_required (VERSION 2.8 FATAL_ERROR)\n"
          "project (${TEST_NAME} ${INVOKE_CONFIGURE_LANGUAGES})\n"
          "set (_CMAKE_UNIT_PHASE CONFIGURE)\n"
          ${COMMON_PROLOGUE}
          "include (CTest)\n"
          "enable_testing ()\n"
          "include (\"${CMAKE_CURRENT_LIST_FILE}\")\n")

    set (TRACE_OPTION "")
    set (UNINITIALIZED_OPTION "")
    set (UNUSED_VARIABLE_OPTION "")
    set (DEVELOPER_WARNINGS_OPTION "-Wno-dev")

    # Set our binary dir as the parent so that we get the test binary dir
    # correct
    set (PARENT_BINARY_DIR_OPTION
         "-DCMAKE_UNIT_PARENT_BINARY_DIR:PATH=${CMAKE_CURRENT_BINARY_DIR}")

    # When coverage is being logged pass the --trace switch
    if (CMAKE_UNIT_COVERAGE_FILE)

        set (TRACE_OPTION "--trace")

    endif ()

    if (NOT CMAKE_UNIT_NO_UNINITIALIZED_WARNINGS)

        set (UNINITIALIZED_OPTION "--warn-uninitialized")

    endif ()

    if (NOT CMAKE_UNIT_NO_DEV_WARNINGS)

        set (DEVELOPER_WARNINGS_OPTION "-Wdev")

    endif ()

    _cmake_unit_forward_arguments (INVOKE_CONFIGURE INVOKE_COMMAND_ARGUMENTS
                                   OPTION_ARGS ALLOW_FAIL
                                   SINGLEVAR_ARGS OUTPUT_FILE ERROR_FILE)
    _cmake_unit_invoke_command (COMMAND "${CMAKE_COMMAND}"
                                        "${INVOKE_CONFIGURE_SOURCE_DIR}"
                                        "${TRACE_OPTION}"
                                        "${UNINITIALIZED_OPTION}"
                                        "${UNUSED_VARIABLE_OPTION}"
                                        "${DEVELOPER_WARNINGS_OPTION}"
                                        "${PARENT_BINARY_DIR_OPTION}"
                                        ${CMAKE_POLICY_CACHE_DEFINITIONS}
                                        -DCMAKE_VERBOSE_MAKEFILE=ON
                                        "-G${CMAKE_GENERATOR}"
                                WORKING_DIRECTORY
                                "${INVOKE_CONFIGURE_BINARY_DIR}"
                                ${INVOKE_COMMAND_ARGUMENTS}
                                PHASE INVOKE_CONFIGURE)

    # Check log file for warnings and raise a fatal error if there are any.
    # Looping twice to check for warnings when we could have done it earlier
    # is not very efficient, but it makes for slightly neater code.
    if (NOT INVOKE_CONFIGURE_ALLOW_WARNINGS)

        file (STRINGS "${INVOKE_CONFIGURE_ERROR_FILE}" CONFIGURE_ERROR_LINES)
        foreach (LINE ${CONFIGURE_ERROR_LINES})

            if (LINE MATCHES "^CMake Warning.*")

                message (STATUS "${LINE}")
                message (SEND_ERROR
                         "CMake Warnings were present!")

            endif ()

        endforeach ()

    endif ()

endfunction ()

function (cmake_unit_invoke_build)

    set (CMAKE_UNIT_INVOKE_BUILD_SINGLEVAR_ARGS
         ${_CMAKE_UNIT_ALL_INVOKE_SINGLEVAR_ARGS}
         TARGET)

    cmake_parse_arguments (INVOKE_BUILD
                           "${_CMAKE_UNIT_ALL_INVOKE_OPTION_ARGS}"
                           "${CMAKE_UNIT_INVOKE_BUILD_SINGLEVAR_ARGS}"
                           ""
                           ${CALLER_ARGN})

    # The "all" target is special. It means "do whatever happens by
    # default". Some build systems literally have a target called
    # "all", but others (XCode) don't, so in that case, just don't
    # add a --target.
    if (INVOKE_BUILD_TARGET STREQUAL "all")

        set (TARGET_OPTION "")

    else ()

        set (TARGET_OPTION --target ${INVOKE_BUILD_TARGET})

    endif ()

    if (CMAKE_MAKE_PROGRAM MATCHES ".*ninja.*")

        set (BUILD_TOOL_VERBOSE_OPTION "-v")

    endif ()

    _cmake_unit_forward_arguments (INVOKE_BUILD INVOKE_COMMAND_ARGUMENTS
                                   OPTION_ARGS ALLOW_FAIL
                                   SINGLEVAR_ARGS OUTPUT_FILE ERROR_FILE)
    _cmake_unit_invoke_command (COMMAND "${CMAKE_COMMAND}"
                                        --build
                                        "${INVOKE_BUILD_BINARY_DIR}"
                                        ${TARGET_OPTION}
                                        --
                                        ${BUILD_TOOL_VERBOSE_OPTION}
                                WORKING_DIRECTORY "${INVOKE_BUILD_BINARY_DIR}"
                                ${INVOKE_COMMAND_ARGUMENTS}
                                PHASE BUILD)

endfunction ()

function (cmake_unit_invoke_test)

    cmake_parse_arguments (INVOKE_TEST
                           "${_CMAKE_UNIT_ALL_INVOKE_OPTION_ARGS}"
                           "${_CMAKE_UNIT_ALL_INVOKE_SINGLEVAR_ARGS}"
                           ""
                           ${CALLER_ARGN})

    _cmake_unit_forward_arguments (INVOKE_TEST INVOKE_COMMAND_ARGUMENTS
                                   OPTION_ARGS ALLOW_FAIL
                                   SINGLEVAR_ARGS OUTPUT_FILE ERROR_FILE)
    _cmake_unit_invoke_command (COMMAND "${CMAKE_CTEST_COMMAND}"
                                        -C
                                        Debug
                                        -VV
                                        "${INVOKE_TEST_BINARY_DIR}"
                                WORKING_DIRECTORY "${INVOKE_TEST_BINARY_DIR}"
                                ${INVOKE_COMMAND_ARGUMENTS}
                                PHASE INVOKE_TEST)

endfunction ()

function (_cmake_unit_filter_trace_lines FILTERED_LINES)

    cmake_parse_arguments (FILTER_COVERAGE
                           ""
                           "TEST_NAME"
                           "TRACE_FILE;COVERAGE_FILES"
                           ${ARGN})

    set (COVERAGE_FILE_CONTENTS "")
    list (APPEND COVERAGE_FILE_CONTENTS "TEST:${TEST_NAME}\n")
    foreach (FILE ${FILTER_COVERAGE_COVERAGE_FILES})

        list (APPEND COVERAGE_FILE_CONTENTS "FILE:${FILE}\n")

    endforeach ()

    file (STRINGS "${FILTER_COVERAGE_TRACE_FILE}" FILTER_COVERAGE_TRACE_LINES)
    foreach (LINE ${FILTER_COVERAGE_TRACE_LINES})

        # Search for lines matching a trace pattern
        foreach (FILE ${COVERAGE_FILES})

            if (LINE MATCHES "^${FILE}\\([0-9]*\\):.*$")

                # Once we've found a matching line, strip out the
                # rest of the mostly useless information.  Find the
                # first ":" after the filename and then write out
                # the string until that semicolon is reached
                string (LENGTH "${FILE}" F_LEN)
                string (SUBSTRING "${LINE}" "${F_LEN}" -1 AFTER_FILE_STRING)

                # Match ):. This prevents drive letters on Windows
                # causing problems
                string (FIND "${AFTER_FILE_STRING}" "):" DEL_IDX)
                math (EXPR COLON_INDEX_IN_LINE "${F_LEN} + ${DEL_IDX} + 1")
                string (SUBSTRING "${LINE}" 0 ${COLON_INDEX_IN_LINE}
                        FILENAME_AND_LINE)

                list (APPEND
                      COVERAGE_FILE_CONTENTS
                      "${FILENAME_AND_LINE}\n")

            endif ()

        endforeach ()

    endforeach ()

    set (${FILTERED_LINES} ${COVERAGE_FILE_CONTENTS} PARENT_SCOPE)

endfunction ()

function (_cmake_unit_coverage)

    if (NOT CMAKE_UNIT_COVERAGE_FILE)

        return ()

    endif ()

    cmake_parse_arguments (COVERAGE_PHASE
                           ""
                           "TEST_NAME;BINARY_DIR"
                           ""
                           ${CALLER_ARGN})

    # Only INVOKE_CONFIGURE and DRIVER can be observed
    set (ERROR_FILES_WITH_TRACE_CONTENTS INVOKE_CONFIGURE DRIVER)

    foreach (ERROR_FILE ${ERROR_FILES_WITH_TRACE_CONTENTS})

        set (ERROR_LOG_FILE "${COVERAGE_PHASE_BINARY_DIR}/${ERROR_FILE}.error")

        if (EXISTS "${ERROR_LOG_FILE}")

            get_property (COVERAGE_FILES
                          GLOBAL PROPERTY _CMAKE_UNIT_COVERAGE_LOGGING_FILES)

            _cmake_unit_filter_trace_lines (COVERAGE_FILE_CONTENTS
                                            TEST_NAME
                                            "${COVERAGE_PHASE_TEST_NAME}"
                                            TRACE_FILE
                                            "${ERROR_LOG_FILE}"
                                            COVERAGE_FILES ${COVERAGE_FILES})

            # Use relative path
            file (APPEND "${CMAKE_UNIT_COVERAGE_FILE}"
                  ${COVERAGE_FILE_CONTENTS})

        endif ()

    endforeach ()

endfunction ()

function (_cmake_unit_no_op)
endfunction ()

function (_cmake_unit_override_function OVERRIDABLE_VARIABLE
                                        USER_PHASE_COMMAND)

    if (USER_SPECIFIED_PHASE_COMMAND)

        if (USER_SPECIFIED_PHASE_COMMAND STREQUAL "NONE")

            set (${OVERRIDABLE_VARIABLE} _cmake_unit_no_op PARENT_SCOPE)

        elseif (NOT USER_SPECIFIED_PHASE_COMMAND STREQUAL "DEFAULT")

            set (${OVERRIDABLE_VARIABLE} ${USER_PHASE_COMMAND} PARENT_SCOPE)

        endif ()

    endif ()

endfunction ()

function (_cmake_unit_override_func_table RETURN_TABLE)

    # Parse first for a list of overridable entries, default options
    # for those entries and the user options passed to cmake_unit_configure_test
    set (OVERRIDE_TABLE_OPTION_MULTIVAR_ARGS OVERRIDABLE_ENTRIES
                                             CURRENT_DISPATCH
                                             USER_OPTIONS)
    _cmake_unit_parse_args_key (OVERRIDE_TABLE_OPTION
                                ""
                                ""
                                "${OVERRIDE_TABLE_OPTION_MULTIVAR_ARGS}"
                                OVERRIDE_TABLE_OPTION_PARSE_KEY
                                ${ARGN})

    # Now for each overridable entry, get the default option in its own variable
    _cmake_unit_fetch_parsed_arg (${OVERRIDE_TABLE_OPTION_PARSE_KEY}
                                  OVERRIDE_TABLE_OPTION OVERRIDABLE_ENTRIES)
    _cmake_unit_fetch_parsed_arg (${OVERRIDE_TABLE_OPTION_PARSE_KEY}
                                  OVERRIDE_TABLE_OPTION CURRENT_DISPATCH)
    _cmake_unit_fetch_parsed_arg (${OVERRIDE_TABLE_OPTION_PARSE_KEY}
                                  OVERRIDE_TABLE_OPTION USER_OPTIONS)
    _cmake_unit_parse_args_key (POTENTIALLY_OVERRIDDEN
                                ""
                                ""
                                "${OVERRIDE_TABLE_OPTION_OVERRIDABLE_ENTRIES}"
                                POTENTIALLY_OVERRIDDEN_PARSE_KEY
                                ${OVERRIDE_TABLE_OPTION_CURRENT_DISPATCH})
    _cmake_unit_parse_args_key (USER_SPECIFIED
                                ""
                                ""
                                "${OVERRIDE_TABLE_OPTION_OVERRIDABLE_ENTRIES}"
                                USER_SPECIFIED_PARSE_KEY
                                ${OVERRIDE_TABLE_OPTION_USER_OPTIONS})

    # Now for each of those entries, look up the same in USER_OPTIONS
    # and see if a value was set. If so, override the value here
    foreach (ENTRY ${OVERRIDE_TABLE_OPTION_OVERRIDABLE_ENTRIES})

        _cmake_unit_fetch_parsed_arg (${USER_SPECIFIED_PARSE_KEY}
                                      USER_SPECIFIED ${ENTRY})
        _cmake_unit_parse_args_key (USER_SPECIFIED_PHASE
                                    ""
                                    "COMMAND"
                                    ""
                                    USER_SPECIFIED_PHASE_PARSE_KEY
                                    ${USER_SPECIFIED_${ENTRY}})

        _cmake_unit_fetch_parsed_arg (${USER_SPECIFIED_PHASE_PARSE_KEY}
                                      USER_SPECIFIED_PHASE COMMAND)
        _cmake_unit_fetch_parsed_arg (${POTENTIALLY_OVERRIDDEN_PARSE_KEY}
                                      POTENTIALLY_OVERRIDDEN ${ENTRY})
        _cmake_unit_override_function (POTENTIALLY_OVERRIDDEN_${ENTRY}
                                       "${USER_SPECIFIED_PHASE_COMMAND}")

    endforeach ()

    # Now reassemble the table using the potentially overridden entries
    # and set it in the parent scope
    set (REASSEMBLED_FUNCTION_TABLE)
    foreach (ENTRY ${OVERRIDE_TABLE_OPTION_OVERRIDABLE_ENTRIES})

        list (APPEND REASSEMBLED_FUNCTION_TABLE
              ${ENTRY}
              ${POTENTIALLY_OVERRIDDEN_${ENTRY}})

    endforeach ()

    set (${RETURN_TABLE} ${REASSEMBLED_FUNCTION_TABLE} PARENT_SCOPE)

endfunction ()

function (_cmake_unit_get_func_for_phase RETURN_FUNCTION
                                         PHASE)

    _cmake_unit_parse_args_key (DISPATCH_FOR
                                ""
                                "${CMAKE_UNIT_PHASES}"
                                ""
                                DISPATCH_FOR_KEY
                                ${ARGN})
    _cmake_unit_fetch_parsed_arg (${DISPATCH_FOR_KEY} DISPATCH_FOR ${PHASE})

    set (${RETURN_FUNCTION} ${DISPATCH_FOR_${PHASE}} PARENT_SCOPE)

endfunction ()

# This function assumes that CMAKE_UNIT_PHASES is set in the
# parent scope
function (_cmake_unit_get_arguments_for_phase RETURN_ARGUMENTS
                                              PHASE)

    _cmake_unit_parse_args_key (ARGUMENTS_FOR
                                ""
                                ""
                                "${CMAKE_UNIT_PHASES}"
                                ARGUMENTS_FOR_PARSE_KEY
                                ${ARGN})
    _cmake_unit_fetch_parsed_arg (${ARGUMENTS_FOR_PARSE_KEY}
                                  ARGUMENTS_FOR ${PHASE})

    set (${RETURN_ARGUMENTS} ${ARGUMENTS_FOR_${PHASE}} PARENT_SCOPE)

endfunction ()

set (_CMAKE_UNIT_OVERRIDABLE_PHASES CLEAN
                                    INVOKE_CONFIGURE
                                    CONFIGURE
                                    INVOKE_BUILD
                                    INVOKE_TEST
                                    VERIFY)
set (CMAKE_UNIT_PHASES PRECONFIGURE
                       COVERAGE
                       RM_BUILD
                       ${_CMAKE_UNIT_OVERRIDABLE_PHASES})

# Creates an "override table" of dispatch phase commands for specified
# USER_OPTIONS. If an ALLOW_FAIL is specified for a particular phase then
# every phase after it is disabled (eg, _cmake_unit_no_op is specified
# in the override table)
function (_cmake_unit_get_override_table_for_allowed_failures RETURN_TABLE)

    set (PHASE_INVOCATION_ORDER
         INVOKE_CONFIGURE
         INVOKE_BUILD
         INVOKE_TEST)

    # Parse ARGN for each overridable phase
    cmake_parse_arguments (OPTIONS_FOR
                           ""
                           ""
                           "${_CMAKE_UNIT_OVERRIDABLE_PHASES}"
                           ${ARGN})

    # And now for each phase, check to see if ALLOW_FAIL was defined
    foreach (PHASE ${PHASE_INVOCATION_ORDER})

        _cmake_unit_parse_args_key (PHASE
                                    "ALLOW_FAIL"
                                    ""
                                    ""
                                    PHASE_PARSE_ARGS_KEY
                                    ${OPTIONS_FOR_${PHASE}})
        _cmake_unit_fetch_parsed_arg (${PHASE_PARSE_ARGS_KEY} PHASE ALLOW_FAIL)

        # Allow fail was defined. Look up this phase, generate a table
        # using the remaining phases and return it
        if (PHASE_ALLOW_FAIL)

            list (LENGTH PHASE_INVOCATION_ORDER PHASE_INVOCATION_LENGTH)
            list (FIND PHASE_INVOCATION_ORDER "${PHASE}" PHASE_INDEX)

            _cmake_unit_spacify (PHASE_INVOCATION_SPACIFIED
                                 LIST ${PHASE_INVOCATION_ORDER}
                                 NO_QUOTES)
            _cmake_unit_runner_assert (CONDITION NOT PHASE_INDEX EQUAL -1
                                       MESSAGE "PHASE must be in "
                                               "${PHASE_INVOCATION_SPACIFIED}")

            math (EXPR START_INDEX "${PHASE_INDEX} + 1")
            math (EXPR END_INDEX "${PHASE_INVOCATION_LENGTH} - 1")

            set (OVERRIDE_TABLE)

            if (START_INDEX LESS END_INDEX OR START_INDEX EQUAL END_INDEX)

                foreach (INDEX RANGE ${START_INDEX} ${END_INDEX})

                    list (GET PHASE_INVOCATION_ORDER ${INDEX} MODIFY_PHASE)
                    list (APPEND OVERRIDE_TABLE
                                 ${MODIFY_PHASE}
                                 COMMAND
                                 _cmake_unit_no_op)

                endforeach ()

            endif ()

            set (${RETURN_TABLE} ${OVERRIDE_TABLE} PARENT_SCOPE)
            return ()

        endif ()

    endforeach ()

endfunction ()

function (_cmake_unit_compute_dispatch_table_for_test DISPATCH_TABLE_RETURN)

    set (COMPUTE_DISPATCH_TABLE_SINGLEVAR_ARGS TEST_NAME)
    set (COMPUTE_DISPATCH_TABLE_MULTIVAR_ARGS USER_OPTIONS)

    _cmake_unit_parse_args_key (COMPUTE_DISPATCH_TABLE
                                ""
                                "${COMPUTE_DISPATCH_TABLE_SINGLEVAR_ARGS}"
                                "${COMPUTE_DISPATCH_TABLE_MULTIVAR_ARGS}"
                                COMPUTE_DISPATCH_TABLE_PARSE_KEY
                                ${ARGN})

    # First look up this test name as part of the
    # _CMAKE_UNIT_DISPATCH_CONFIGURE_DISPATCH_FOR_${TEST_NAME} property. If
    # there's a value, then use that (as a cache) instead of recomputing it here
    # as recomputing the value all the time is quite expensive. The value
    # never changes between runs.
    _cmake_unit_fetch_parsed_arg (${COMPUTE_DISPATCH_TABLE_PARSE_KEY}
                                  COMPUTE_DISPATCH_TABLE TEST_NAME)
    set (TEST_NAME "${COMPUTE_DISPATCH_TABLE_TEST_NAME}")
    get_property (DISPATCH_TABLE
                  GLOBAL PROPERTY
                  "_CMAKE_UNIT_DISPATCH_CONFIGURE_DISPATCH_FOR_${TEST_NAME}")

    if (NOT DISPATCH_TABLE)

        # This is the default dispatch table for each phase if the user
        # does not override what to do with
        set (DEFAULT_DISPATCH
             CLEAN cmake_unit_invoke_clean
             INVOKE_CONFIGURE cmake_unit_invoke_configure
             CONFIGURE _cmake_unit_no_op
             INVOKE_BUILD cmake_unit_invoke_build
             INVOKE_TEST cmake_unit_invoke_test
             VERIFY _cmake_unit_no_op)

        _cmake_unit_fetch_parsed_arg (${COMPUTE_DISPATCH_TABLE_PARSE_KEY}
                                      COMPUTE_DISPATCH_TABLE USER_OPTIONS)
        set (OVERRIDABLE ${_CMAKE_UNIT_OVERRIDABLE_PHASES})
        set (USER_ARGN ${COMPUTE_DISPATCH_TABLE_USER_OPTIONS})

        _cmake_unit_override_func_table (OVERRIDDEN_DISPATCH
                                         OVERRIDABLE_ENTRIES ${OVERRIDABLE}
                                         CURRENT_DISPATCH ${DEFAULT_DISPATCH}
                                         USER_OPTIONS ${USER_ARGN})

        set (ALLOWED_FAIL_TABLE)
        _cmake_unit_get_override_table_for_allowed_failures (ALLOWED_FAIL_TABLE
                                                             ${USER_ARGN})

        _cmake_unit_override_func_table (OVERRIDDEN_DISPATCH
                                         OVERRIDABLE_ENTRIES ${OVERRIDABLE}
                                         CURRENT_DISPATCH ${OVERRIDDEN_DISPATCH}
                                         USER_OPTIONS ${ALLOWED_FAIL_TABLE})

        set (DISPATCH_TABLE
             ${OVERRIDDEN_DISPATCH}
             PRECONFIGURE _cmake_unit_preconfigure_test
             COVERAGE _cmake_unit_coverage
             RM_BUILD cmake_unit_invoke_rm_build)

        # Set the _CMAKE_UNIT_DISPATCH_CONFIGURE_DISPATCH_FOR_${TEST_NAME}
        # property.
        set_property (GLOBAL PROPERTY
                      "_CMAKE_UNIT_DISPATCH_CONFIGURE_DISPATCH_FOR_${TEST_NAME}"
                      ${DISPATCH_TABLE})

    endif ()

    set (${DISPATCH_TABLE_RETURN} ${DISPATCH_TABLE} PARENT_SCOPE)

endfunction ()

# Variables we implicitly dereference indicating the next phase after
# a current one.
set (_CMAKE_UNIT_PHASE_AFTER_PRECONFIGURE) # NOLINT:unused/private_var
set (_CMAKE_UNIT_PHASE_AFTER_CLEAN # NOLINT:unused/private_var
     INVOKE_CONFIGURE)
set (_CMAKE_UNIT_PHASE_AFTER_INVOKE_CONFIGURE # NOLINT:unused/private_var
     INVOKE_BUILD)
set (_CMAKE_UNIT_PHASE_AFTER_INVOKE_BUILD # NOLINT:unused/private_var
     INVOKE_TEST)
set (_CMAKE_UNIT_PHASE_AFTER_INVOKE_TEST VERIFY) # NOLINT:unused/private_var
set (_CMAKE_UNIT_PHASE_AFTER_VERIFY COVERAGE) # NOLINT:unused/private_var
set (_CMAKE_UNIT_PHASE_AFTER_COVERAGE RM_BUILD) # NOLINT:unused/private_var

function (_cmake_unit_configure_test_internal)

    set (CMAKE_UNIT_CONFIGURE_TEST_SINGLEVAR_ARGS SOURCE_DIR BINARY_DIR)

    # TEST_NAME is by convention, the "called function" directly
    # above us name. It must be set here in case we call another function
    # and CALLED_FUNCTION_NAME is overwritten
    set (TEST_NAME ${CALLED_FUNCTION_NAME})

    cmake_parse_arguments (CMAKE_UNIT_CONFIGURE_TEST
                           ""
                           "${CMAKE_UNIT_CONFIGURE_TEST_SINGLEVAR_ARGS}"
                           "${_CMAKE_UNIT_OVERRIDABLE_PHASES}"
                           ${ARGN})

    _cmake_unit_compute_dispatch_table_for_test (CMAKE_UNIT_TEST_DISPATCH
                                                 TEST_NAME "${TEST_NAME}"
                                                 USER_OPTIONS ${ARGN})

    # Get the function for this phase
    _cmake_unit_get_func_for_phase (PHASE_FUNCTION
                                    ${_CMAKE_UNIT_PHASE}
                                    ${CMAKE_UNIT_TEST_DISPATCH})

    # Get the arguments to pass to this phase, as a list
    set (PHASE_ARGUMENTS)
    _cmake_unit_get_arguments_for_phase (PHASE_ARGUMENTS
                                         ${_CMAKE_UNIT_PHASE}
                                         ${ARGN})

    set (PHASE ${_CMAKE_UNIT_PHASE})
    set (TEST_SOURCE_DIR "${CMAKE_UNIT_CONFIGURE_TEST_SOURCE_DIR}")
    set (TEST_BINARY_DIR "${CMAKE_UNIT_CONFIGURE_TEST_BINARY_DIR}")

    _cmake_unit_forward_arguments (TEST PHASE_FUNCTION_STANDARD_ARGS
                                   SINGLEVAR_ARGS SOURCE_DIR
                                                  BINARY_DIR
                                                  OUTPUT_FILE
                                                  ERROR_FILE)

    cmake_call_function (${PHASE_FUNCTION} ${PHASE_ARGUMENTS}
                         TEST_NAME ${TEST_NAME}
                         SOURCE_DIR "${TEST_SOURCE_DIR}"
                         BINARY_DIR "${TEST_BINARY_DIR}"
                         OUTPUT_FILE "${TEST_BINARY_DIR}/${PHASE}.output"
                         ERROR_FILE "${TEST_BINARY_DIR}/${PHASE}.error")

    # Implicitly dereference _CMAKE_UNIT_PHASE_AFTER_${PHASE} and if there's
    # a phase to go to, recursively call this function and enter the next phase.
    set (NEXT_PHASE "${_CMAKE_UNIT_PHASE_AFTER_${PHASE}}")
    if (NEXT_PHASE)

        set (_CMAKE_UNIT_PHASE ${NEXT_PHASE})
        _cmake_unit_configure_test_internal (${ARGN})

    endif ()

endfunction ()

# Wraps _cmake_unit_configure_test_internal, which does the heavy lifting and
# is a recursive function. This function merely just grabs SOURCE_DIR and
# BINARY_DIR
function (cmake_unit_configure_test)

    # Get the "test function" arguments and this configure function's
    # arguments
    set (ALL_ARGUMENTS ${ARGN} ${CALLER_ARGN})

    # Call through
    _cmake_unit_configure_test_internal (${ALL_ARGUMENTS})

endfunction ()

# A convenience wrapper around cmake_unit_configure_test, use if you're
# not interested in any build steps. Saves typing.
function (cmake_unit_configure_config_only_test)

    cmake_unit_configure_test (INVOKE_BUILD COMMAND NONE
                               INVOKE_TEST COMMAND NONE
                               ${ARGN})

endfunction ()

function (cmake_unit_get_dirs BINARY_DIR_RETURN SOURCE_DIR_RETURN)

    cmake_parse_arguments (GET
                           ""
                           "BINARY_DIR;SOURCE_DIR"
                           ""
                           ${CALLER_ARGN})

    set (${BINARY_DIR_RETURN} "${GET_BINARY_DIR}" PARENT_SCOPE)
    set (${SOURCE_DIR_RETURN} "${GET_SOURCE_DIR}" PARENT_SCOPE)

endfunction ()

function (cmake_unit_get_log_for PHASE LOG_TYPE LOG_FILE_RETURN)

    cmake_unit_get_dirs (BINARY_DIR SOURCE_DIR)

    _cmake_unit_runner_assert (CONDITION
                               NOT LOG_TYPE STREQUAL "ERROR" AND
                               NOT LOG_TYPE STREQUAL "OUTPUT"
                               MESSAGE
                               "LOG_TYPE must be either ERROR or OUTPUT")

    set (ACCEPTABLE_PHASES INVOKE_CONFIGURE INVOKE_BUILD INVOKE_TEST)
    list (FIND ACCEPTABLE_PHASES ${PHASE} PHASE_IN_ACCEPTABLE_INDEX)
    _cmake_unit_spacify (SPACIFIED_ACCEPTABLE_PHASES
                         LIST ${ACCEPTABLE_PHASES}
                         NO_QUOTES)
    _cmake_unit_runner_assert (CONDITION
                               NOT PHASE_IN_ACCEPTABLE_INDEX EQUAL -1
                               MESSAGE
                               "PHASE must be ${SPACIFIED_ACCEPTABLE_PHASES}")

    string (TOLOWER "${LOG_TYPE}" LOG_TYPE_LOWER)
    set (${LOG_FILE_RETURN} "${BINARY_DIR}/${PHASE}.${LOG_TYPE_LOWER}"
         PARENT_SCOPE)

endfunction ()
