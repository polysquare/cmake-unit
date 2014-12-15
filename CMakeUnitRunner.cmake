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
# CMake tests should be added with cmake_unit_config_test . These tests
# will only run cmake in script-execution mode on the specified
# script and check for success.
#
# Build tests are a superset of CMake tests. They will run cmake
# on the specified script, but also use cmake --build to build
# the resulting project and then run the verfication script
# specified in order to check that the build succeeded in the
# way that the user expected it to. Build tests can take
# much longer to execute and should be used sparingly.
#
# See LICENCE.md for Copyright information

include (CMakeParseArguments)
include (CMakeUnit)
include (CTest)

enable_testing ()

option (CMAKE_UNIT_LOG_COVERAGE OFF
        "Log line hits to ${CMAKE_PROJECT_NAME}.trace")
option (CMAKE_UNIT_NO_DEV_WARNINGS OFF
        "Turn off developer warnings")
option (CMAKE_UNIT_NO_UNINITIALIZED_WARNINGS OFF
        "Turn off uninitialized variable usage warnings")

if (CMAKE_UNIT_LOG_COVERAGE)

    set (CMAKE_UNIT_COVERAGE_FILE
         "${CMAKE_CURRENT_BINARY_DIR}/${CMAKE_PROJECT_NAME}.trace")

endif ()

set (_RUNNER_LIST_DIR "${CMAKE_CURRENT_LIST_DIR}")

# cmake_unit_init
#
# Sets up the initial environment to use cmake-unit. Call this function
# before calling cmake_unit_config_test or cmake_unit_build_test.
#
# VARIABLES: A list of variables to "forward" on to the tests with the same
#            value that they have at the time of calling cmake_unit_init
# COVERAGE_FILES: A list of full absolute paths to files which should
#                 be tracked for code coverage.
function (cmake_unit_init)

    set (BOOTSTRAP_MULTIVAR_ARGS VARIABLES COVERAGE_FILES)

    cmake_parse_arguments (BOOTSTRAP
                           ""
                           ""
                           "${BOOTSTRAP_MULTIVAR_ARGS}"
                           ${ARGN})

    # Put variables we want to forward to the tests into their cache
    foreach (VAR ${BOOTSTRAP_VARIABLES})

        get_property (TYPE
                      CACHE ${VAR}
                      PROPERTY TYPE)

        if (NOT TYPE STREQUAL "STRING" OR
            NOT TYPE STREQUAL "BOOL" OR
            NOT TYPE STREQUAL "PATH" OR
            NOT TYPE STREQUAL "FILEPATH")

            # If the variable is not part of the "public" cache, then
            # we can still forward it, but we need to set a type of "STRING"
            set (TYPE STRING)

        endif (NOT TYPE STREQUAL "STRING" OR
               NOT TYPE STREQUAL "BOOL" OR
               NOT TYPE STREQUAL "PATH" OR
               NOT TYPE STREQUAL "FILEPATH")

        # This needs to be squeezed all on to one line so that we don't get
        # semicolonization from having multiple strings in the set () command
        set (ICC "${ICC}set (${VAR} \"${${VAR}}\" CACHE ${TYPE} \"\" FORCE)\n")

    endforeach ()

    # Escape semicolons
    string (REPLACE ";" "/;" ICC "${ICC}")
    set_property (GLOBAL PROPERTY
                  _CMAKE_UNIT_INITIAL_CACHE_CONTENTS "${ICC}")

    if (CMAKE_UNIT_LOG_COVERAGE)

        # Escape characters out of filenames that will cause problems when
        # attempting to regex match them later
        foreach (COVERAGE_FILE ${BOOTSTRAP_COVERAGE_FILES})

            cmake_unit_escape_string ("${COVERAGE_FILE}" ESCAPED_COVERAGE_FILE)
            list (APPEND ESCAPED_COVERAGE_FILES "${ESCAPED_COVERAGE_FILE}")

        endforeach ()

        set_property (GLOBAL PROPERTY _CMAKE_UNIT_COVERAGE_LOGGING_FILES
                      ${ESCAPED_COVERAGE_FILES})

        # Clobber the coverage report
        file (WRITE "${CMAKE_UNIT_COVERAGE_FILE}" "")

    endif ()

endfunction ()

function (_cmake_unit_get_test_variables TEST_NAME
                                         TEST_FILE_RETURN
                                         TEST_DIRECTORY_RETURN
                                         TEST_WORKING_DIRECTORY_RETURN
                                         TEST_INITIAL_CACHE_FILE_RETURN
                                         TEST_DRIVER_SCRIPT_RETURN)

    set (TEST_DIRECTORY "${CMAKE_CURRENT_BINARY_DIR}/${TEST_NAME}")

    set (${TEST_FILE_RETURN} "${TEST_NAME}.cmake" PARENT_SCOPE)
    set (${TEST_DIRECTORY_RETURN} "${TEST_DIRECTORY}" PARENT_SCOPE)
    set (${TEST_WORKING_DIRECTORY_RETURN} "${TEST_DIRECTORY}/build"
         PARENT_SCOPE)
    set (${TEST_INITIAL_CACHE_FILE_RETURN}
         "${TEST_DIRECTORY}/initial_cache.cmake"
         PARENT_SCOPE)
    set (${TEST_DRIVER_SCRIPT_RETURN}
         "${TEST_DIRECTORY}/${TEST_NAME}Driver.cmake"
         PARENT_SCOPE)

endfunction ()

function (_cmake_unit_init_test_driver_script PARENT_DRIVER_SCRIPT_CONTENTS
                                              TEST_DIRECTORY
                                              TEST_WORKING_DIRECTORY)

    file (MAKE_DIRECTORY "${TEST_DIRECTORY}")
    file (MAKE_DIRECTORY "${TEST_WORKING_DIRECTORY}")
    set (DRIVER_SCRIPT_CONTENTS "")
    list (APPEND DRIVER_SCRIPT_CONTENTS
          "include (CMakeParseArguments)\n"
          "function (add_driver_command STEP\n"
          "                             OUTPUT_RETURN\n"
          "                             ERROR_RETURN\n"
          "                             RESULT_RETURN)\n"
          "    set (ADD_COMMAND_OPTION_ARGS ALLOW_FAIL)\n"
          "    set (ADD_COMMAND_MULTIVAR_ARGS COMMAND)\n"
          "    cmake_parse_arguments (ADD_COMMAND\n"
          "                           \"\${ADD_COMMAND_OPTION_ARGS}\"\n"
          "                           \"\"\n"
          "                           \"\${ADD_COMMAND_MULTIVAR_ARGS}\"\n"
          "                           \${ARGN})\n"
          "    string (REPLACE \"@SEMICOLON@\" \" \"\n"
          "            STRINGIFIED_COMMAND \"\${ADD_COMMAND_COMMAND}\")\n"
          "    message (STATUS \"Running \${STRINGIFIED_COMMAND}\")\n"
          "    set (OUTPUT_LOG\n"
          "         \"${TEST_WORKING_DIRECTORY}/\${STEP}.output\")\n"
          "    set (ERROR_LOG\n"
          "         \"${TEST_WORKING_DIRECTORY}/\${STEP}.error\")\n"
          "    execute_process (COMMAND \${ADD_COMMAND_COMMAND}\n"
          "                     WORKING_DIRECTORY\n"
          "                     \"${TEST_WORKING_DIRECTORY}\"\n"
          "                     RESULT_VARIABLE RESULT\n"
          "                     OUTPUT_FILE \"\${OUTPUT_LOG}\"\n"
          "                     ERROR_FILE \"\${ERROR_LOG}\")\n"
          "    file (STRINGS \"\${OUTPUT_LOG}\" OUTPUT_LINES)\n"
          "    file (STRINGS \"\${ERROR_LOG}\" ERROR_LINES)\n"
          "    foreach (LINE \${OUTPUT_LINES})\n"
          "        message (STATUS \"\${STEP} OUTPUT \${LINE}\")\n"
          "    endforeach ()\n"
          # HACK: Remove square brackets, as their presence can confuse
          # CMake into not using ; as list delimiter. We can't even
          # use the character directly here as CMake will become confused.
          "    if (\"\${STEP}\" STREQUAL \"CONFIGURE\")\n"
          "        string (REPLACE \"@PROBLEMATIC_REGEX_ONE@\" \"\"\n"
          "                ERROR_LINES \"\${ERROR_LINES}\")\n"
          "        string (REPLACE \"@PROBLEMATIC_REGEX_TWO@\" \"\"\n"
          "                ERROR_LINES \"\${ERROR_LINES}\")\n"
          "        set (IN_CMAKE_ERROR_OR_WARNING OFF)\n"
          "    endif ()\n"
          "    foreach (LINE \${ERROR_LINES})\n"
          # Only print contents of FATAL_ERROR, SEND_ERROR and WARNING for
          # the configure step. Otherwise too much will be printed, especially
          # when trace mode is enabled
          "        if (\"\${STEP}\" STREQUAL \"CONFIGURE\")\n"
          "            if (\"\${LINE}\" MATCHES \"CMake (Error|Warning).*$\")\n"
          "                set (IN_CMAKE_ERROR_OR_WARNING ON)\n"
          "            elseif (IN_CMAKE_ERROR_OR_WARNING AND\n"
          "                    \"\${LINE}\" MATCHES \"^Call Stack.*$\")\n"
          "                set (IN_CMAKE_ERROR_OR_WARNING ON)\n"
          "            elseif (IN_CMAKE_ERROR_OR_WARNING AND\n"
          "                    \"\${LINE}\" MATCHES \"^  .*$\")\n"
          "                set (IN_CMAKE_ERROR_OR_WARNING ON)\n"
          "            else ()\n"
          "                set (IN_CMAKE_ERROR_OR_WARNING OFF)\n"
          "            endif ()\n"
          "            if (IN_CMAKE_ERROR_OR_WARNING)\n"
          "                message (STATUS \"\${STEP} ERROR \${LINE}\")\n"
          "            endif ()\n"
          "        else ()\n"
          "            message (STATUS \"\${STEP} ERROR \${LINE}\")\n"
          "        endif ()\n"
          "    endforeach ()\n"
          "    if (NOT RESULT EQUAL 0 AND NOT ADD_COMMAND_ALLOW_FAIL)\n"
          "        message (FATAL_ERROR \n"
          "                 \"The command \${STRINGIFIED_COMMAND}\"\n"
          "                 \" failed with \${RESULT}\")\n"
          "    endif ()\n"
          "    set (\${OUTPUT_RETURN} \${OUTPUT_LINES} PARENT_SCOPE)\n"
          "    set (\${ERROR_RETURN} \${ERROR_LINES} PARENT_SCOPE)\n"
          "    set (\${RESULT_RETURN} \"\${RESULT}\" PARENT_SCOPE)\n"
          "endfunction ()\n"
          "\n")

    set (${PARENT_DRIVER_SCRIPT_CONTENTS} ${DRIVER_SCRIPT_CONTENTS}
         PARENT_SCOPE)

endfunction ()

function (_cmake_unit_add_driver_step ADD_STEP_PARENT_DRIVER_SCRIPT_CONTENTS
                                      STEP)

    set (DRIVER_STEP_OPTION_ARGS ALLOW_FAIL)
    set (DRIVER_STEP_MULTIVAR_ARGS COMMAND)

    cmake_parse_arguments (ADD_DRIVER_STEP
                           "${DRIVER_STEP_OPTION_ARGS}"
                           ""
                           "${DRIVER_STEP_MULTIVAR_ARGS}"
                           ${ARGN})

    if (NOT ADD_DRIVER_STEP_COMMAND)

        message (FATAL_ERROR "A COMMAND must be provided to add_driver_step")

    endif ()

    if (ADD_DRIVER_STEP_ALLOW_FAIL)

        set (ALLOW_FAIL ALLOW_FAIL)

    else ()

        set (ALLOW_FAIL "")

    endif ()

    # When we pass ADD_DRIVER_STEP_COMMAND into this string, it will appear to
    # just be a space-separated string, which will have each element converted
    # into a list element. That's obviously not what we want, so we instead
    # create a string with escaped quotes for each item that we want to put
    # on the commandline and then append that to our script.
    foreach (ARGUMENT ${ADD_DRIVER_STEP_COMMAND})

        list (APPEND STRINGIFIED_ARGS "\"${ARGUMENT}\"")

    endforeach ()

    # Ensure that the list expands with spaces and not semicolons
    string (REPLACE ";" " " STRINGIFIED_ARGS "${STRINGIFIED_ARGS}")

    set (DRIVER_SCRIPT_CONTENTS ${${ADD_STEP_PARENT_DRIVER_SCRIPT_CONTENTS}})
    list (APPEND DRIVER_SCRIPT_CONTENTS
          "add_driver_command (${STEP}\n"
          "                    ${STEP}_OUTPUT\n"
          "                    ${STEP}_ERROR\n"
          "                    ${STEP}_RESULT\n"
          "                    COMMAND ${STRINGIFIED_ARGS}\n"
          "                    ${ALLOW_FAIL})\n")
    set (${ADD_STEP_PARENT_DRIVER_SCRIPT_CONTENTS} ${DRIVER_SCRIPT_CONTENTS}
         PARENT_SCOPE)

endfunction ()

function (_cmake_unit_define_test_for_driver TEST_NAME
                                             TEST_DIRECTORY
                                             DRIVER_SCRIPT)

    set (DEFINE_TEST_FOR_DRIVER_MULTIVAR_ARGS CONTENTS)
    cmake_parse_arguments (DEFINE_TEST_FOR_DRIVER
                           ""
                           ""
                           "${DEFINE_TEST_FOR_DRIVER_MULTIVAR_ARGS}"
                           ${ARGN})

    if (NOT DEFINE_TEST_FOR_DRIVER_CONTENTS)

        message (FATAL_ERROR "Test driver script must have contents")

    endif ()

    # Write driver script, but see below:
    string (REPLACE "@SEMICOLON@" "\;" DEFINE_TEST_FOR_DRIVER_CONTENTS
            "${DEFINE_TEST_FOR_DRIVER_CONTENTS}")
    string (REPLACE "@ESCAPED_SEMICOLON@" "\\\\;"
            DEFINE_TEST_FOR_DRIVER_CONTENTS
            "${DEFINE_TEST_FOR_DRIVER_CONTENTS}")
    file (WRITE "${DRIVER_SCRIPT}"
          ${DEFINE_TEST_FOR_DRIVER_CONTENTS})

    # Inject problematic regex outside of any coverage scopes
    set (INJECT_REGEX_HACK_FILE
         "util/InjectProblematicRegexIntoDriverHack.cmake")
    execute_process (COMMAND "${CMAKE_COMMAND}"
                     "-DDRIVER_SCRIPT_FILE=${DRIVER_SCRIPT}"
                     -P
                     "${_RUNNER_LIST_DIR}/${INJECT_REGEX_HACK_FILE}")

    # Write initial cache
    get_property (ICC GLOBAL PROPERTY _CMAKE_UNIT_INITIAL_CACHE_CONTENTS)
    file (WRITE "${TEST_INITIAL_CACHE_FILE}" "${ICC}")

    add_test (NAME ${TEST_NAME}
              COMMAND "${CMAKE_COMMAND}" -P "${DRIVER_SCRIPT}"
              WORKING_DIRECTORY "${TEST_DIRECTORY}")

endfunction ()

function (_cmake_unit_append_clean_step PARENT_DRIVER_SCRIPT_CONTENTS
                                        TEST_WORKING_DIRECTORY)

    set (DRIVER_SCRIPT_CONTENTS ${${PARENT_DRIVER_SCRIPT_CONTENTS}})
    list (APPEND DRIVER_SCRIPT_CONTENTS
          "file (REMOVE_RECURSE \"${TEST_WORKING_DIRECTORY}\")\n"
          "file (MAKE_DIRECTORY \"${TEST_WORKING_DIRECTORY}\")\n")
    set (${PARENT_DRIVER_SCRIPT_CONTENTS} ${DRIVER_SCRIPT_CONTENTS}
         PARENT_SCOPE)

endfunction ()

function (_cmake_unit_append_configure_step TEST_NAME
                                            PARENT_DRIVER_SCRIPT_CONTENTS
                                            CACHE_FILE
                                            TEST_DIRECTORY
                                            TEST_FILE)

    set (CONFIGURE_STEP_OPTION_ARGS ALLOW_FAIL ALLOW_WARNINGS)

    cmake_parse_arguments (CONFIGURE_STEP
                           "${CONFIGURE_STEP_OPTION_ARGS}"
                           ""
                           ""
                           ${ARGN})

    set (TEST_FILE_PATH
         "${CMAKE_CURRENT_SOURCE_DIR}/${TEST_FILE}")

    if (EXISTS "${TEST_FILE_PATH}")

        set (TEST_DIRECTORY_CONFIGURE_SCRIPT
             "${TEST_DIRECTORY}/CMakeLists.txt")
        set (TEST_DIRECTORY_CONFIGURE_SCRIPT_CONTENTS
             "cmake_minimum_required (VERSION 2.8 FATAL_ERROR)\n"
             "if (POLICY CMP0042)\n"
             "  cmake_policy (SET CMP0042 NEW)\n"
             "endif ()\n"
             "if (POLICY CMP0025)\n"
             "  cmake_policy (SET CMP0025 NEW)\n"
             "endif ()\n"
             "project (TestProject CXX C)\n"
             "include (\"${CMAKE_CURRENT_SOURCE_DIR}/${TEST_FILE}\")\n")

        file (WRITE "${TEST_DIRECTORY_CONFIGURE_SCRIPT}"
              ${TEST_DIRECTORY_CONFIGURE_SCRIPT_CONTENTS})

        set (ALLOW_FAIL_OPTION "")

        # Whether to allow failures in the configure step
        if (CONFIGURE_STEP_ALLOW_FAIL)

            set (ALLOW_FAIL_OPTION ALLOW_FAIL)

        endif ()

        # Set GENERATOR
        string (REPLACE " " "\\ " GENERATOR ${CMAKE_GENERATOR})

        set (TRACE_OPTION "")
        set (UNINITIALIZED_OPTION "")
        set (UNUSED_VARIABLE_OPTION "")
        set (DEVELOPER_WARNINGS_OPTION "-Wno-dev")

        # When coverage is being logged pass the --trace switch
        if (CMAKE_UNIT_LOG_COVERAGE)

            set (TRACE_OPTION "--trace")

        endif ()

        if (NOT CMAKE_UNIT_NO_UNINITIALIZED_WARNINGS)

            set (UNINITIALIZED_OPTION "--warn-uninitialized")

        endif ()

        if (NOT CMAKE_UNIT_NO_DEV_WARNINGS)

            set (DEVELOPER_WARNINGS_OPTION "-Wdev")

        endif ()

        set (CONFIGURE_COMMAND
             "${CMAKE_COMMAND}"
             "${TRACE_OPTION}"
             "${UNINITIALIZED_OPTION}"
             "${UNUSED_VARIABLE_OPTION}"
             "${DEVELOPER_WARNINGS_OPTION}"
             "${TEST_DIRECTORY}"
             "-C${CACHE_FILE}"
             -DCMAKE_VERBOSE_MAKEFILE=ON
             "-G${GENERATOR}")
        set (DRIVER_SCRIPT_CONTENTS ${${PARENT_DRIVER_SCRIPT_CONTENTS}})
        _cmake_unit_add_driver_step (DRIVER_SCRIPT_CONTENTS CONFIGURE
                                     COMMAND ${CONFIGURE_COMMAND}
                                     ${ALLOW_FAIL_OPTION})

        if (NOT CONFIGURE_STEP_ALLOW_WARNINGS)

            # Check for warnings. Potentially looping twice like this
            # is not very efficient, but it makes for slightly neater code
            # than combining all the loop steps
            list (APPEND DRIVER_SCRIPT_CONTENTS
                  "foreach (LINE \${CONFIGURE_ERROR})\n"
                  "    if (\"\${LINE}\" MATCHES \"^CMake Warning.*\")\n"
                  "        message (SEND_ERROR\n"
                  "                 \"CMake Warnings were present!\")\n"
                  "    endif ()\n"
                  "endforeach ()\n"
                  "\n")

        endif ()

        # After we've added the driver step, read back CONFIGURE.error and
        # VERIFY.error and filter through each of the lines to find
        # "coverage" lines, logging them into the main CMAKE_UNIT_COVERAGE_FILE
        if (CMAKE_UNIT_LOG_COVERAGE)

            # We need to make sure that the quotes around our coverage
            # files get passed back down to the driver script
            get_property (LOGGING_FILES
                          GLOBAL PROPERTY _CMAKE_UNIT_COVERAGE_LOGGING_FILES)
            foreach (FILE ${LOGGING_FILES})

                list (APPEND COVERAGE_FILES "\"${FILE}\"")

            endforeach ()

            # Now replace list semicolons with spaces. The result will be
            # that this is a valid list when parsed by CMake in the second
            # stage
            string (REPLACE ";" " " COVERAGE_FILES "${COVERAGE_FILES}")

            # First write out the name of this test and all the files
            # we will be covering
            list (APPEND DRIVER_SCRIPT_CONTENTS
                  # Reduce IO by buffering in memory
                  "set (COVERAGE_FILE_CONTENTS \"\")\n"
                  "list (APPEND\n"
                  "      COVERAGE_FILE_CONTENTS\n"
                  "      \"TEST:${TEST_NAME}\\n\")\n"
                  "set (COVERAGE_FILES ${COVERAGE_FILES})\n"
                  "foreach (FILE \${COVERAGE_FILES})\n"
                  "    list (APPEND COVERAGE_FILE_CONTENTS\n"
                  "          \"FILE:\${FILE}\\n\")\n"
                  "endforeach ()\n"
                  # Ensure that only tracefile-like lines are included
                  "set (TRACE_LINES \${CONFIGURE_ERROR})\n"
                  "foreach (LINE \${TRACE_LINES})\n"
                  # Search for lines matching a trace pattern
                  "    if (\"\${LINE}\" MATCHES \"^.*\\\\([0-9]*\\\\):.*$\")\n"
                  "        foreach (FILE \${COVERAGE_FILES})\n"
                  "            if (\"\${LINE}\"\n"
                  "                MATCHES \"^\${FILE}\\\\([0-9]*\\\\):.*$\")\n"
                  # Once we've found a matching line, strip out the rest of
                  # the mostly useless information. Find the first ":" after
                  # the filename and then write out the string until that
                  # semicolon is reached
                  "                string (LENGTH \"${FILE}\" F_LEN)\n"
                  "                string (SUBSTRING \"\${LINE}\"\n"
                  "                        \${F_LEN} -1\n"
                  "                        AFTER_FILE_STRING)\n"
                  # Match ):. This prevents drive letters on Windows causing
                  # problems
                  "                string (FIND \"\${AFTER_FILE_STRING}\"\n"
                  "                        \"):\" DEL_IDX)\n"
                  "                math (EXPR COLON_INDEX_IN_LINE\n"
                  "                      \"\${F_LEN} + \${DEL_IDX} + 1\")\n"
                  "                string (SUBSTRING \"\${LINE}\"\n"
                  "                        0 \${COLON_INDEX_IN_LINE}\n"
                  "                        FILENAME_AND_LINE)\n"
                  "                list (APPEND\n"
                  "                      COVERAGE_FILE_CONTENTS\n"
                  "                      \"\${FILENAME_AND_LINE}\\n\")\n"
                  "           endif ()\n"
                  "        endforeach ()\n"
                  "    endif ()\n"
                  "endforeach ()\n"
                  "file (APPEND \"${CMAKE_UNIT_COVERAGE_FILE}\"\n"
                  "      \${COVERAGE_FILE_CONTENTS})\n")

        endif ()

        set (${PARENT_DRIVER_SCRIPT_CONTENTS} ${DRIVER_SCRIPT_CONTENTS}
             PARENT_SCOPE)

    else ()

        message (SEND_ERROR "The file ${TEST_FILE_PATH} must exist"
                            " in order for the configure step to run")

    endif ()

endfunction ()

function (_cmake_unit_append_build_step PARENT_DRIVER_SCRIPT_CONTENTS
                                        TEST_WORKING_DIRECTORY
                                        TARGET)

    set (BUILD_STEP_OPTION_ARGS ALLOW_FAIL)

    cmake_parse_arguments (BUILD_STEP
                           "${BUILD_STEP_OPTION_ARGS}"
                           ""
                           ""
                           ${ARGN})

    set (ALLOW_FAIL_OPTION "")

    if (BUILD_STEP_ALLOW_FAIL)

        set (ALLOW_FAIL_OPTION ALLOW_FAIL)

    endif ()

    # The "all" target is special. It means "do whatever happens by
    # default". Some build systems literally have a target called
    # "all", but others (Xcode) don't, so in that case, just don't
    # add a --target.
    if ("${TARGET}" STREQUAL "all")

        set (TARGET_OPTION "")

    else ()

        set (TARGET_OPTION --target ${TARGET})

    endif ()

    if ("${CMAKE_MAKE_PROGRAM}" MATCHES ".*ninja.*")

        set (BUILD_TOOL_VERBOSE_OPTION "-v")

    endif ()

    set (BUILD_COMMAND "${CMAKE_COMMAND}"
                       --build
                       "${TEST_WORKING_DIRECTORY}"
                       ${TARGET_OPTION}
                       --
                       "${BUILD_TOOL_VERBOSE_OPTION}")
    set (DRIVER_SCRIPT_CONTENTS ${${PARENT_DRIVER_SCRIPT_CONTENTS}})
    _cmake_unit_add_driver_step (DRIVER_SCRIPT_CONTENTS BUILD
                                 COMMAND ${BUILD_COMMAND}
                                 ${ALLOW_FAIL_OPTION})
    set (${PARENT_DRIVER_SCRIPT_CONTENTS} ${DRIVER_SCRIPT_CONTENTS}
         PARENT_SCOPE)

endfunction ()

function (_cmake_unit_append_test_step PARENT_DRIVER_SCRIPT_CONTENTS)

    set (TEST_STEP_OPTION_ARGS ALLOW_FAIL)

    cmake_parse_arguments (TEST_STEP
                           "${TEST_STEP_OPTION_ARGS}"
                           ""
                           ""
                           ${ARGN})

    set (ALLOW_FAIL_OPTION "")

    if (TEST_STEP_ALLOW_FAIL)

        set (ALLOW_FAIL_OPTION ALLOW_FAIL)

    endif ()

    set (TEST_COMMAND "${CMAKE_CTEST_COMMAND}" -C Debug -VV)
    set (DRIVER_SCRIPT_CONTENTS ${${PARENT_DRIVER_SCRIPT_CONTENTS}})
    _cmake_unit_add_driver_step (DRIVER_SCRIPT_CONTENTS TEST
                                 COMMAND ${TEST_COMMAND}
                                 ${ALLOW_FAIL_OPTION})
    set (${PARENT_DRIVER_SCRIPT_CONTENTS} ${DRIVER_SCRIPT_CONTENTS}
         PARENT_SCOPE)

endfunction ()

function (_cmake_unit_append_verify_step PARENT_DRIVER_SCRIPT_CONTENTS
                                         CACHE_FILE
                                         VERIFY_NAME)

    set (TEST_VERIFY_SCRIPT_FILE
         "${CMAKE_CURRENT_SOURCE_DIR}/${VERIFY_NAME}.cmake")

    if (EXISTS "${TEST_VERIFY_SCRIPT_FILE}")

        # When coverage is being logged pass the --trace switch
        if (CMAKE_UNIT_LOG_COVERAGE)

            set (TRACE_OPTION "--trace")

        endif ()

        set (VERIFY_COMMAND
             "${CMAKE_COMMAND}"
             "${TRACE_OPTION}"
             "-C${CACHE_FILE}"
             -P
             "${TEST_VERIFY_SCRIPT_FILE}")
        set (DRIVER_SCRIPT_CONTENTS ${${PARENT_DRIVER_SCRIPT_CONTENTS}})
        _cmake_unit_add_driver_step (DRIVER_SCRIPT_CONTENTS VERIFY
                                     COMMAND ${VERIFY_COMMAND})
        set (${PARENT_DRIVER_SCRIPT_CONTENTS} ${DRIVER_SCRIPT_CONTENTS}
             PARENT_SCOPE)

    else ()

        message (SEND_ERROR "The file ${TEST_VERIFY_SCRIPT_FILE} must exist"
                            " in order for the verify step to run")

    endif ()

endfunction ()

function (_cmake_unit_append_coverage_step PARENT_DRIVER_SCRIPT_CONTENTS)

    if (NOT CMAKE_UNIT_LOG_COVERAGE)

        return ()

    endif ()

    # We need to make sure that the quotes around our coverage
    # files get passed back down to the driver script
    get_property (LOGGING_FILES
                  GLOBAL PROPERTY _CMAKE_UNIT_COVERAGE_LOGGING_FILES)
    foreach (FILE ${LOGGING_FILES})

        list (APPEND COVERAGE_FILES "\"${FILE}\"")

    endforeach ()

    # Now replace list semicolons with spaces. The result will be
    # that this is a valid list when parsed by CMake in the second
    # stage
    string (REPLACE ";" " " COVERAGE_FILES "${COVERAGE_FILES}")

    # First write out the name of this test and all the files
    # we will be covering
    list (APPEND DRIVER_SCRIPT_CONTENTS
          ${${PARENT_DRIVER_SCRIPT_CONTENTS}}
          # Reduce IO by buffering in memory
          "set (COVERAGE_FILE_CONTENTS \"\")\n"
          "list (APPEND\n"
          "      COVERAGE_FILE_CONTENTS\n"
          "      \"TEST:${TEST_NAME}\\n\")\n"
          "set (COVERAGE_FILES ${COVERAGE_FILES})\n"
          "foreach (FILE \${COVERAGE_FILES})\n"
          "    list (APPEND COVERAGE_FILE_CONTENTS\n"
          "          \"FILE:\${FILE}\\n\")\n"
          "endforeach ()\n"
          # Ensure that only tracefile-like lines are included
          "set (TRACE_LINES \${CONFIGURE_ERROR} \${VERIFY_ERROR})\n"
          "foreach (LINE \${TRACE_LINES})\n"
          # Search for lines matching a trace pattern
          "    if (\"\${LINE}\" MATCHES \"^.*\\\\([0-9]*\\\\):.*$\")\n"
          "        foreach (FILE \${COVERAGE_FILES})\n"
          "            if (\"\${LINE}\"\n"
          "                MATCHES \"^\${FILE}\\\\([0-9]*\\\\):.*$\")\n"
          # Once we've found a matching line, strip out the rest of
          # the mostly useless information. Find the first ":" after
          # the filename and then write out the string until that
          # semicolon is reached
          "                string (LENGTH \"${FILE}\" F_LEN)\n"
          "                string (SUBSTRING \"\${LINE}\"\n"
          "                        \${F_LEN} -1\n"
          "                        AFTER_FILE_STRING)\n"
          # Match ):. This prevents drive letters on Windows causing
          # problems
          "                string (FIND \"\${AFTER_FILE_STRING}\"\n"
          "                        \"):\" DEL_IDX)\n"
          "                math (EXPR COLON_INDEX_IN_LINE\n"
          "                      \"\${F_LEN} + \${DEL_IDX} + 1\")\n"
          "                string (SUBSTRING \"\${LINE}\"\n"
          "                        0 \${COLON_INDEX_IN_LINE}\n"
          "                        FILENAME_AND_LINE)\n"
          "                list (APPEND\n"
          "                      COVERAGE_FILE_CONTENTS\n"
          "                      \"\${FILENAME_AND_LINE}\\n\")\n"
          "           endif ()\n"
          "        endforeach ()\n"
          "    endif ()\n"
          "endforeach ()\n"
          "file (APPEND \"${CMAKE_UNIT_COVERAGE_FILE}\"\n"
          "      \${COVERAGE_FILE_CONTENTS})\n")

    set (${PARENT_DRIVER_SCRIPT_CONTENTS}
         ${DRIVER_SCRIPT_CONTENTS}
         PARENT_SCOPE)

endfunction ()

# cmake_unit_config_test:
#
# Adds a test with just the configure step. If the test script
# exits with an error then the test fails.
#
# TEST_NAME: The name of a file to import for a "configure-only" test.
function (cmake_unit_config_test TEST_NAME)

    _cmake_unit_get_test_variables (${TEST_NAME}
                                    TEST_FILE
                                    TEST_DIRECTORY
                                    TEST_WORKING_DIRECTORY
                                    TEST_INITIAL_CACHE_FILE
                                    TEST_DRIVER_SCRIPT_FILE)

    _cmake_unit_init_test_driver_script (TEST_DRIVER_SCRIPT_CONTENTS
                                         "${TEST_DIRECTORY}"
                                         "${TEST_WORKING_DIRECTORY}")
    _cmake_unit_append_clean_step (TEST_DRIVER_SCRIPT_CONTENTS
                                   "${TEST_WORKING_DIRECTORY}")
    _cmake_unit_append_configure_step (${TEST_NAME}
                                       TEST_DRIVER_SCRIPT_CONTENTS
                                       "${TEST_INITIAL_CACHE_FILE}"
                                       "${TEST_DIRECTORY}"
                                       "${TEST_FILE}")
    _cmake_unit_append_coverage_step (TEST_DRIVER_SCRIPT_CONTENTS)
    _cmake_unit_define_test_for_driver (${TEST_NAME}
                                        "${TEST_DIRECTORY}"
                                        "${TEST_DRIVER_SCRIPT_FILE}"
                                        CONTENTS ${TEST_DRIVER_SCRIPT_CONTENTS})

endfunction ()

# cmake_unit_build_test:
#
# Adds a test with three steps, a "configure", "build", "test" and "verify"
# step. This will run some checks at the configure phase, then build and test
# the configured project and then run the script specified by
# VERIFY to ensure that the project built correctly.
#
#
# TEST_NAME: The name of a file to import for a "build" test.
# VERIFY: The name of a file to run after build for a "build" test.
# [Optional]: ALLOW_CONFIGURE_FAIL: Allow the configure step to fail. The build
#                                   and test steps will not run with this option
#                                   set
# [Optional]: ALLOW_CONFIGURE_WARNINGS: Don't treat warnings as errors in the
#                                       configure step.
# [Optional]: ALLOW_BUILD_FAIL: Allow the build step to fail. The test step will
#                               not run with this option set.
# [Optional]: ALLOW_TEST_FAIL: Allow the test step to fail.
# [Optional]: NO_CLEAN: Do not clean the source directory before build.
# [Optional]: TARGET: Build this target instead of the default target.
function (cmake_unit_build_test TEST_NAME VERIFY)

    set (CMAKE_UNIT_ADD_BUILD_TEST_OPTION_ARGS
         ALLOW_CONFIGURE_FAIL
         ALLOW_CONFIGURE_WARNINGS
         ALLOW_BUILD_FAIL
         ALLOW_TEST_FAIL
         NO_CLEAN)
    set (CMAKE_UNIT_ADD_BUILD_TEST_SINGLEVAR_ARGS
         TARGET)
    set (CMAKE_UNIT_ADD_BUILD_TEST_MULTIVAR_ARGS)

    cmake_parse_arguments (CMAKE_UNIT_ADD_BUILD_TEST
                           "${CMAKE_UNIT_ADD_BUILD_TEST_OPTION_ARGS}"
                           "${CMAKE_UNIT_ADD_BUILD_TEST_SINGLEVAR_ARGS}"
                           "${CMAKE_UNIT_ADD_BUILD_TEST_MULTIVAR_ARGS}"
                           ${ARGN})

    set (ALLOW_BUILD_FAIL_OPTION "")
    set (ALLOW_CONFIGURE_FAIL_OPTION "")

    if (NOT CMAKE_UNIT_ADD_BUILD_TEST_TARGET)

        set (CMAKE_UNIT_ADD_BUILD_TEST_TARGET all)

    endif ()

    if (CMAKE_UNIT_ADD_BUILD_TEST_ALLOW_CONFIGURE_WARNINGS)

        set (ALLOW_CONFIGURE_WARNINGS_OPTION ALLOW_WARNINGS)

    endif ()

    if (CMAKE_UNIT_ADD_BUILD_TEST_ALLOW_CONFIGURE_FAIL)

        set (ALLOW_CONFIGURE_FAIL_OPTION ALLOW_FAIL)
        set (CMAKE_UNIT_ADD_BUILD_TEST_ALLOW_BUILD_FAIL ON)

    endif ()

    if (CMAKE_UNIT_ADD_BUILD_TEST_ALLOW_BUILD_FAIL)

        set (ALLOW_BUILD_FAIL_OPTION ALLOW_FAIL)

    endif ()

    if (CMAKE_UNIT_ADD_BUILD_TEST_ALLOW_TEST_FAIL)

        set (ALLOW_TEST_FAIL_OPTION ALLOW_FAIL)

    endif ()

    _cmake_unit_get_test_variables (${TEST_NAME}
                                    TEST_FILE
                                    TEST_DIRECTORY
                                    TEST_WORKING_DIRECTORY
                                    TEST_INITIAL_CACHE_FILE
                                    TEST_DRIVER_SCRIPT_FILE)

    _cmake_unit_init_test_driver_script (TEST_DRIVER_SCRIPT_CONTENTS
                                         "${TEST_DIRECTORY}"
                                         "${TEST_WORKING_DIRECTORY}")

    if (NOT CMAKE_UNIT_ADD_BUILD_TEST_NO_CLEAN)

        _cmake_unit_append_clean_step (TEST_DRIVER_SCRIPT_CONTENTS
                                       "${TEST_WORKING_DIRECTORY}")

    endif ()

    _cmake_unit_append_configure_step (${TEST_NAME}
                                       TEST_DRIVER_SCRIPT_CONTENTS
                                       "${TEST_INITIAL_CACHE_FILE}"
                                       "${TEST_DIRECTORY}"
                                       "${TEST_FILE}"
                                       ${ALLOW_CONFIGURE_FAIL_OPTION}
                                       ${ALLOW_CONFIGURE_WARNINGS_OPTION})

    # Can't build if the configure step is allowed to fail
    if (NOT CMAKE_UNIT_ADD_BUILD_TEST_ALLOW_CONFIGURE_FAIL)

        _cmake_unit_append_build_step (TEST_DRIVER_SCRIPT_CONTENTS
                                       "${TEST_WORKING_DIRECTORY}"
                                       ${CMAKE_UNIT_ADD_BUILD_TEST_TARGET}
                                       ${ALLOW_BUILD_FAIL_OPTION}
                                       ${NO_CLEAN_OPTION})

    endif ()

    # Can't test the project if the build step is allowed to fail
    if (NOT CMAKE_UNIT_ADD_BUILD_TEST_ALLOW_BUILD_FAIL)

        _cmake_unit_append_test_step (TEST_DRIVER_SCRIPT_CONTENTS
                                      ${ALLOW_TEST_FAIL_OPTION})

    endif ()

    _cmake_unit_append_verify_step (TEST_DRIVER_SCRIPT_CONTENTS
                                    "${TEST_INITIAL_CACHE_FILE}"
                                    ${VERIFY})
    _cmake_unit_append_coverage_step (TEST_DRIVER_SCRIPT_CONTENTS)
    _cmake_unit_define_test_for_driver (${TEST_NAME}
                                        "${TEST_DIRECTORY}"
                                        "${TEST_DRIVER_SCRIPT_FILE}"
                                        CONTENTS ${TEST_DRIVER_SCRIPT_CONTENTS})

endfunction ()
