# CMakeUnitRunner.cmake
#
# The main test runner for the CMakeUnit framework.
#
# Users should first call bootstrap_cmake_unit which will
# set up some necessary global variables. Tests are organized
# into test scripts (because CMake doesn't have the ability to
# refer to function names as variables and call them later).
#
# As a performance consideration, there are two types of tests,
# CMake tests and Build Tests.
#
# CMake tests should be added with add_cmake_test . These tests
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
# See LICENCE.md for Copyright information.

# bootstrap_cmake_unit:
#
# Defines some global variables for the CMakeUnit framework. Pass
# VARIABLES to forward those variables to tests.
include (CMakeParseArguments)
include (CTest)

enable_testing ()

function (bootstrap_cmake_unit)

    set (FORWARD_MULTIVAR_ARGS VARIABLES)

    cmake_parse_arguments (FORWARD
                           ""
                           ""
                           "${FORWARD_MULTIVAR_ARGS}"
                           ${ARGN})

    foreach (VAR ${FORWARD_VARIABLES})

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
    set (_CMAKE_UNIT_INITIAL_CACHE_CONTENTS "${ICC}" PARENT_SCOPE)

endfunction (bootstrap_cmake_unit)

macro (_define_variables_for_test TEST_NAME)

    set (TEST_FILE "${TEST_NAME}.cmake")
    set (TEST_DIRECTORY_NAME "${CMAKE_CURRENT_BINARY_DIR}/${TEST_NAME}")
    set (TEST_WORKING_DIRECTORY_NAME "${TEST_DIRECTORY_NAME}/build")
    set (TEST_DRIVER_SCRIPT
         "${TEST_DIRECTORY_NAME}/${TEST_NAME}Driver.cmake")
    set (TEST_INITIAL_CACHE_FILE
         "${TEST_DIRECTORY_NAME}/initial_cache.cmake")

endmacro (_define_variables_for_test)

function (_bootstrap_test_driver_script TEST_NAME DRIVER_SCRIPT CACHE_FILE)

    file (MAKE_DIRECTORY "${TEST_DIRECTORY_NAME}")
    file (MAKE_DIRECTORY "${TEST_WORKING_DIRECTORY_NAME}")
    set (TEST_DRIVER_SCRIPT_CONTENTS
         "include (CMakeParseArguments)\n"
         "function (add_driver_command)\n"
         "    set (ADD_COMMAND_OPTION_ARGS ALLOW_FAIL)\n"
         "    set (ADD_COMMAND_SINGLEVAR_ARGS OUTPUT_LOG ERROR_LOG)\n"
         "    set (ADD_COMMAND_MULTIVAR_ARGS COMMAND)\n"
         "    cmake_parse_arguments (ADD_COMMAND\n"
         "                           \"\${ADD_COMMAND_OPTION_ARGS}\"\n"
         "                           \"\${ADD_COMMAND_SINGLEVAR_ARGS}\"\n"
         "                           \"\${ADD_COMMAND_MULTIVAR_ARGS}\"\n"
         "                           \${ARGN})\n"
         "    string (REPLACE \"\;\" \" \"\n"
         "            STRINGIFIED_COMMAND \"\${ADD_COMMAND_COMMAND}\")\n"
         "    message (STATUS \"Running \${STRINGIFIED_COMMAND}\")\n"
         "    execute_process (COMMAND \${ADD_COMMAND_COMMAND}\n"
         "                     WORKING_DIRECTORY\n"
         "                     \"${TEST_WORKING_DIRECTORY_NAME}\"\n"
         "                     RESULT_VARIABLE RESULT\n"
         "                     OUTPUT_VARIABLE OUTPUT\n"
         "                     ERROR_VARIABLE ERROR)\n"
         "    if (RESULT EQUAL 0 OR ALLOW_FAIL)\n"
         "        message (\"\\n\${OUTPUT}\\n\${ERROR}\")\n"
         "    else (RESULT EQUAL 0 OR ALLOW_FAIL)\n"
         "        message (FATAL_ERROR \n"
         "                 \"The command \${STRINFIED_COMMAND} failed with \"\n"
         "                 \"\${RESULT}\\n\${ERROR}\\n\${OUTPUT}\")\n"
         "    endif (RESULT EQUAL 0 OR ALLOW_FAIL)\n"
         "    file (WRITE\n"
         "          \"\${ADD_COMMAND_OUTPUT_LOG}\"\n"
         "          \"Output:\\n\"\n"
         "          \${OUTPUT})\n"
         "    file (WRITE\n"
         "          \"\${ADD_COMMAND_ERROR_LOG}\"\n"
         "          \"Errors:\\n\"\n"
         "          \${ERROR})\n"
         "endfunction (add_driver_command)\n")
    file (WRITE "${DRIVER_SCRIPT}" ${TEST_DRIVER_SCRIPT_CONTENTS})

    file (WRITE "${CACHE_FILE}"
          "${_CMAKE_UNIT_INITIAL_CACHE_CONTENTS}")

endfunction (_bootstrap_test_driver_script)

function (_add_driver_step DRIVER_SCRIPT STEP)

    set (DRIVER_STEP_OPTION_ARGS ALLOW_FAIL)
    set (DRIVER_STEP_MULTIVAR_ARGS COMMAND)

    cmake_parse_arguments (ADD_DRIVER_STEP
                           "${DRIVER_STEP_OPTION_ARGS}"
                           ""
                           "${DRIVER_STEP_MULTIVAR_ARGS}"
                           ${ARGN})

    if (NOT ADD_DRIVER_STEP_COMMAND)

        message (FATAL_ERROR "A COMMAND must be provided to add_driver_step")

    endif (NOT ADD_DRIVER_STEP_COMMAND)

    if (ADD_DRIVER_STEP_ALLOW_FAIL)

        set (ALLOW_FAIL ALLOW_FAIL)

    else (ADD_DRIVER_STEP_ALLOW_FAIL)

        set (ALLOW_FAIL "")

    endif (ADD_DRIVER_STEP_ALLOW_FAIL)

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

    file (APPEND "${DRIVER_SCRIPT}"
          "set (OUTPUT_FILE \"${TEST_WORKING_DIRECTORY_NAME}/${STEP}.output\")\n"
          "set (ERROR_FILE \"${TEST_WORKING_DIRECTORY_NAME}/${STEP}.error\")\n"
          "add_driver_command (COMMAND ${STRINGIFIED_ARGS}\n"
          "                    OUTPUT_LOG \"\${OUTPUT_FILE}\"\n"
          "                    ERROR_LOG \"\${ERROR_FILE}\"\n"
          "                    ${ALLOW_FAIL})\n")

endfunction (_add_driver_step DRIVER_SCRIPT STEP COMMAND_VAR)

function (_define_test_for_driver TEST_NAME DRIVER_SCRIPT)

    add_test (NAME ${TEST_NAME}
              COMMAND
              ${CMAKE_COMMAND} -P "${DRIVER_SCRIPT}"
              WORKING_DIRECTORY "${TEST_DIRECTORY_NAME}")

endfunction (_define_test_for_driver)

function (_append_clean_step DRIVER_SCRIPT
                             TEST_WORKING_DIRECTORY_NAME)

    file (APPEND "${DRIVER_SCRIPT}"
          "file (REMOVE_RECURSE \"${TEST_WORKING_DIRECTORY_NAME}\")\n"
          "file (MAKE_DIRECTORY \"${TEST_WORKING_DIRECTORY_NAME}\")\n")

endfunction (_append_clean_step)

function (_append_configure_step TEST_NAME
                                 DRIVER_SCRIPT
                                 CACHE_FILE
                                 TEST_DIRECTORY_NAME
                                 TEST_WORKING_DIRECTORY_NAME
                                 TEST_FILE)

    set (CONFIGURE_STEP_OPTION_ARGS ALLOW_FAIL)

    cmake_parse_arguments (CONFIGURE_STEP
                           "${CONFIGURE_STEP_OPTION_ARGS}"
                           ""
                           ""
                           ${ARGN})

    set (TEST_FILE_PATH
         ${CMAKE_CURRENT_SOURCE_DIR}/${TEST_FILE})

    if (EXISTS ${TEST_FILE_PATH})

        set (TEST_DIRECTORY_CONFIGURE_SCRIPT
             "${TEST_DIRECTORY_NAME}/CMakeLists.txt")
        set (TEST_DIRECTORY_CONFIGURE_SCRIPT_CONTENTS
             "if (POLICY CMP0025)\n"
             "  cmake_policy (SET CMP0025 NEW)\n"
             "endif (POLICY CMP0025)\n"
             "project (TestProject CXX C)\n"
             "cmake_minimum_required (VERSION 2.8 FATAL_ERROR)\n"
             "include (\"${CMAKE_CURRENT_SOURCE_DIR}/${TEST_FILE}\")\n")

        file (WRITE "${TEST_DIRECTORY_CONFIGURE_SCRIPT}"
              ${TEST_DIRECTORY_CONFIGURE_SCRIPT_CONTENTS})

        if (CONFIGURE_STEP_ALLOW_FAIL)

            set (ALLOW_FAIL_OPTION ALLOW_FAIL)

        endif (CONFIGURE_STEP_ALLOW_FAIL)

        string (REPLACE " " "\\ " GENERATOR ${CMAKE_GENERATOR})
        set (CONFIGURE_COMMAND
             "${CMAKE_COMMAND}" "${TEST_DIRECTORY_NAME}"
             "-C${CACHE_FILE}"
             -DCMAKE_VERBOSE_MAKEFILE=ON
             "-G${GENERATOR}")
        _add_driver_step ("${DRIVER_SCRIPT}" CONFIGURE
                          COMMAND ${CONFIGURE_COMMAND}
                          ${ALLOW_FAIL_OPTION})


    else (EXISTS ${TEST_FILE_PATH})

        message (SEND_ERROR "The file ${TEST_FILE_PATH} must exist"
                            " in order for the configure step to run")

    endif (EXISTS ${TEST_FILE_PATH})

endfunction (_append_configure_step)

function (_append_build_step DRIVER_SCRIPT
                             TEST_WORKING_DIRECTORY_NAME
                             TARGET)

    set (BUILD_STEP_OPTION_ARGS ALLOW_FAIL)

    cmake_parse_arguments (BUILD_STEP
                           "${BUILD_STEP_OPTION_ARGS}"
                           ""
                           ""
                           ${ARGN})

    if (BUILD_STEP_ALLOW_FAIL)

        set (ALLOW_FAIL_OPTION ALLOW_FAIL)

    endif (BUILD_STEP_ALLOW_FAIL)

    # The "all" target is special. It means "do whatever happens by
    # default". Some build systems literally have a target called
    # "all", but others (Xcode) don't, so in that case, just don't
    # add a --target.
    if ("${TARGET}" STREQUAL "all")

        set (TARGET_OPTION "")

    else ("${TARGET}" STREQUAL "all")

        set (TARGET_OPTION --target ${TARGET})

    endif ("${TARGET}" STREQUAL "all")

    set (BUILD_COMMAND "${CMAKE_COMMAND}"
                       --build
                       "${TEST_WORKING_DIRECTORY_NAME}"
                       ${TARGET_OPTION})
    _add_driver_step ("${DRIVER_SCRIPT}" BUILD
                      COMMAND ${BUILD_COMMAND}
                      ${ALLOW_FAIL_OPTION})

endfunction (_append_build_step)

function (_append_verify_step DRIVER_SCRIPT
                              CACHE_FILE
                              VERIFY)

    set (TEST_VERIFY_SCRIPT_FILE
         ${CMAKE_CURRENT_SOURCE_DIR}/${VERIFY}.cmake)

    if (EXISTS ${TEST_VERIFY_SCRIPT_FILE})

        set (VERIFY_COMMAND
             "${CMAKE_COMMAND}"
             -C"${CACHE_FILE}"
             -P "${TEST_VERIFY_SCRIPT_FILE}")
        _add_driver_step ("${DRIVER_SCRIPT}" VERIFY
                          COMMAND ${VERIFY_COMMAND})

    else (EXISTS ${TEST_VERIFY_SCRIPT_FILE})

        message (SEND_ERROR "The file ${TEST_VERIFY_SCRIPT_FILE} must exist"
                            " in order for the verify step to run")

    endif (EXISTS ${TEST_VERIFY_SCRIPT_FILE})

endfunction (_append_verify_step)

# add_cmake_test:
#
# Adds a test with just the configure step. If the test script
# exits with an error then the test fails.
function (add_cmake_test TEST_NAME)

    _define_variables_for_test (${TEST_NAME})
    _bootstrap_test_driver_script(${TEST_NAME}
                                  "${TEST_DRIVER_SCRIPT}"
                                  "${TEST_INITIAL_CACHE_FILE}")
    _append_clean_step ("${TEST_DRIVER_SCRIPT}"
                        "${TEST_WORKING_DIRECTORY_NAME}")
    _append_configure_step (${TEST_NAME}
                            "${TEST_DRIVER_SCRIPT}"
                            "${TEST_INITIAL_CACHE_FILE}"
                            "${TEST_DIRECTORY_NAME}"
                            "${TEST_WORKING_DIRECTORY_NAME}"
                            "${TEST_FILE}")
    _define_test_for_driver (${TEST_NAME} "${TEST_DRIVER_SCRIPT}")

endfunction (add_cmake_test)

# add_cmake_build_test:
# 
# Adds a test with three steps, a "configure", "build" and "verify"
# step. This will run some checks at the configure phase, then build
# the configured project and then run the script specified by
# VERIFY to ensure that the project built correctly.
function (add_cmake_build_test TEST_NAME VERIFY)

    set (ADD_CMAKE_BUILD_TEST_OPTION_ARGS
         ALLOW_BUILD_FAIL
         ALLOW_CONFIGURE_FAIL
         NO_CLEAN)
    set (ADD_CMAKE_BUILD_TEST_SINGLEVAR_ARGS
         TARGET)
    set (ADD_CMAKE_BUILD_TEST_MULTIVAR_ARGS)

    cmake_parse_arguments (ADD_CMAKE_BUILD_TEST
                           "${ADD_CMAKE_BUILD_TEST_OPTION_ARGS}"
                           "${ADD_CMAKE_BUILD_TEST_SINGLEVAR_ARGS}"
                           "${ADD_CMAKE_BUILD_TEST_MULTIVAR_ARGS}"
                           ${ARGN})

    if (NOT ADD_CMAKE_BUILD_TEST_TARGET)

        set (ADD_CMAKE_BUILD_TEST_TARGET all)

    endif (NOT ADD_CMAKE_BUILD_TEST_TARGET)

    if (ADD_CMAKE_BUILD_TEST_ALLOW_BUILD_FAIL)

        set (ALLOW_BUILD_FAIL_OPTION ALLOW_FAIL)

    endif (ADD_CMAKE_BUILD_TEST_ALLOW_BUILD_FAIL)

    if (ADD_CMAKE_BUILD_TEST_ALLOW_CONFIGURE_FAIL)

        set (ALLOW_CONFIGURE_FAIL_OPTION ALLOW_FAIL)

    endif (ADD_CMAKE_BUILD_TEST_ALLOW_CONFIGURE_FAIL)

    _define_variables_for_test (${TEST_NAME})
    _bootstrap_test_driver_script(${TEST_NAME}
                                  ${TEST_DRIVER_SCRIPT}
                                  ${TEST_INITIAL_CACHE_FILE})

    if (NOT ADD_CMAKE_BUILD_TEST_NO_CLEAN)

      _append_clean_step (${TEST_DRIVER_SCRIPT}
                          ${TEST_WORKING_DIRECTORY_NAME})

    endif (NOT ADD_CMAKE_BUILD_TEST_NO_CLEAN)

    _append_configure_step (${TEST_NAME}
                            ${TEST_DRIVER_SCRIPT}
                            ${TEST_INITIAL_CACHE_FILE}
                            ${TEST_DIRECTORY_NAME}
                            ${TEST_WORKING_DIRECTORY_NAME}
                            ${TEST_FILE}
                            ${ALLOW_CONFIGURE_FAIL_OPTION})

    if (NOT ADD_CMAKE_BUILD_TEST_ALLOW_CONFIGURE_FAIL)

        _append_build_step (${TEST_DRIVER_SCRIPT}
                            ${TEST_WORKING_DIRECTORY_NAME}
                            ${ADD_CMAKE_BUILD_TEST_TARGET}
                            ${ALLOW_BUILD_FAIL_OPTION}
                            ${NO_CLEAN_OPTION})

    endif (NOT ADD_CMAKE_BUILD_TEST_ALLOW_CONFIGURE_FAIL)
    _append_verify_step (${TEST_DRIVER_SCRIPT}
                         ${TEST_INITIAL_CACHE_FILE}
                         ${VERIFY})
    _define_test_for_driver (${TEST_NAME} ${TEST_DRIVER_SCRIPT})

endfunction (add_cmake_build_test)
