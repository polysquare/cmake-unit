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
# the option INITIAL_CACHE_CONTENTS along with the name of a variable
# which contains a string containing the contents of a file that could be
# passed to -C to set an initial cache for the tests.
include (CMakeParseArguments)

macro (bootstrap_cmake_unit)

    include (CMakeParseArguments)
    include (CTest)
    enable_testing ()

    # Find CMake binary
    find_program (CMAKE cmake)

    if (NOT CMAKE)

        message (FATAL_ERROR "Failed to find cmake binary on this system")

    endif (NOT CMAKE)

    cmake_parse_arguments (CMAKE_UNIT_BOOT
                           ""
                           "INITIAL_CACHE_CONTENTS"
                           ""
                           ${ARGN})

    set (_CMAKE_UNIT_INITIAL_CACHE_CONTENTS
         ${${CMAKE_UNIT_BOOT_INITIAL_CACHE_CONTENTS}})

endmacro (bootstrap_cmake_unit)

macro (_define_variables_for_test TEST_NAME)

    set (TEST_FILE ${TEST_NAME}.cmake)
    set (TEST_DIRECTORY_NAME ${CMAKE_CURRENT_BINARY_DIR}/${TEST_NAME})
    set (TEST_WORKING_DIRECTORY_NAME ${TEST_DIRECTORY_NAME}/build)
    set (TEST_DRIVER_SCRIPT
         ${TEST_WORKING_DIRECTORY_NAME}/${TEST_NAME}Driver.cmake)
    set (TEST_INITIAL_CACHE_FILE
         ${TEST_WORKING_DIRECTORY_NAME}/initial_cache.cmake)

endmacro (_define_variables_for_test)

function (_bootstrap_test_driver_script TEST_NAME DRIVER_SCRIPT CACHE_FILE)

    file (MAKE_DIRECTORY ${TEST_DIRECTORY_NAME})
    file (MAKE_DIRECTORY ${TEST_WORKING_DIRECTORY_NAME})
    set (TEST_DRIVER_SCRIPT_CONTENTS
         "function (add_driver_command COMMAND_VAR\n"
         "                             OUTPUT_FILE\n"
         "                             ERROR_FILE\n"
         "                             ALLOW_FAIL)\n"
         "    message (\"Running \" \${\${COMMAND_VAR}})\n"
         "    execute_process (COMMAND \${\${COMMAND_VAR}}\n"
         "                     RESULT_VARIABLE RESULT\n"
         "                     OUTPUT_VARIABLE OUTPUT\n"
         "                     ERROR_VARIABLE ERROR)\n"
         "    if (RESULT EQUAL 0 OR ALLOW_FAIL)\n"
         "        message (\"\\n\${OUTPUT}\\n\${ERROR}\")\n"
         "    else (RESULT EQUAL 0 OR ALLOW_FAIL)\n"
         "        message (FATAL_ERROR \n"
         "                 \"The command \${\${COMMAND_VAR}}} failed with \"\n"
         "                 \"\${RESULT}\\n\${ERROR}\\n\${OUTPUT}\")\n"
         "    endif (RESULT EQUAL 0 OR ALLOW_FAIL)\n"
         "    file (WRITE\n"
         "          \${OUTPUT_FILE}\n"
         "          \"Output:\\n\"\n"
         "          \${OUTPUT})\n"
         "    file (WRITE\n"
         "          \${ERROR_FILE}\n"
         "          \"Errors:\\n\"\n"
         "          \${ERROR})\n"
         "endfunction (add_driver_command)\n")
    file (WRITE ${DRIVER_SCRIPT} ${TEST_DRIVER_SCRIPT_CONTENTS})

    file (WRITE ${CACHE_FILE}
          ${_CMAKE_UNIT_INITIAL_CACHE_CONTENTS})

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

        set (ALLOW_FAIL ON)

    else (ADD_DRIVER_STEP_ALLOW_FAIL)

        set (ALLOW_FAIL OFF)

    endif (ADD_DRIVER_STEP_ALLOW_FAIL)

    file (APPEND ${DRIVER_SCRIPT}
          "set (${STEP} ${ADD_DRIVER_STEP_COMMAND})\n"
          "add_driver_command (${STEP}\n"
          "                    \${CMAKE_CURRENT_BINARY_DIR}/${STEP}.output\n"
          "                    \${CMAKE_CURRENT_BINARY_DIR}/${STEP}.error\n"
          "                    ${ALLOW_FAIL})\n")

endfunction (_add_driver_step DRIVER_SCRIPT STEP COMMAND_VAR)

function (_define_test_for_driver TEST_NAME DRIVER_SCRIPT)

    add_test (NAME ${TEST_NAME}
              COMMAND
              ${CMAKE} -P ${DRIVER_SCRIPT}
              WORKING_DIRECTORY ${TEST_WORKING_DIRECTORY_NAME})

endfunction (_define_test_for_driver)

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
             ${TEST_DIRECTORY_NAME}/CMakeLists.txt)
        set (TEST_DIRECTORY_CONFIGURE_SCRIPT_CONTENTS
             "if (POLICY CMP0025)\n"
             "  cmake_policy (SET CMP0025 NEW)\n"
             "endif (POLICY CMP0025)\n"
             "project (TestProject CXX C)\n"
             "cmake_minimum_required (VERSION 2.8 FATAL_ERROR)\n"
             "include (${CMAKE_CURRENT_SOURCE_DIR}/${TEST_FILE})\n")

        file (WRITE ${TEST_DIRECTORY_CONFIGURE_SCRIPT}
              ${TEST_DIRECTORY_CONFIGURE_SCRIPT_CONTENTS})

        if (CONFIGURE_STEP_ALLOW_FAIL)

            set (ALLOW_FAIL_OPTION ALLOW_FAIL)

        endif (CONFIGURE_STEP_ALLOW_FAIL)

        string (REPLACE " " "\\ " GENERATOR ${CMAKE_GENERATOR})
        set (CONFIGURE_COMMAND
             ${CMAKE} ..
             -C${CACHE_FILE}
             -DCMAKE_VERBOSE_MAKEFILE=ON
             -G "${GENERATOR}")
        _add_driver_step (${DRIVER_SCRIPT} CONFIGURE
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

    set (BUILD_STEP_OPTION_ARGS ALLOW_FAIL NO_CLEAN)

    cmake_parse_arguments (BUILD_STEP
                           "${BUILD_STEP_OPTION_ARGS}"
                           ""
                           ""
                           ${ARGN})

    if (BUILD_STEP_ALLOW_FAIL)

        set (ALLOW_FAIL_OPTION ALLOW_FAIL)

    endif (BUILD_STEP_ALLOW_FAIL)

    if (NOT BUILD_STEP_NO_CLEAN)

        set (CLEAN_FIRST_OPTION --clean-first)

    endif (NOT BUILD_STEP_NO_CLEAN)

    set (BUILD_COMMAND ${CMAKE}
                       --build
                       ${TEST_WORKING_DIRECTORY_NAME}
                       ${CLEAN_FIRST_OPTION}
                       --target
                       ${TARGET})
    _add_driver_step (${DRIVER_SCRIPT} BUILD
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
             ${CMAKE}
             -C${CACHE_FILE}
             -P ${TEST_VERIFY_SCRIPT_FILE})
        _add_driver_step (${DRIVER_SCRIPT} VERIFY
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
                                  ${TEST_DRIVER_SCRIPT}
                                  ${TEST_INITIAL_CACHE_FILE})
    _append_configure_step (${TEST_NAME}
                            ${TEST_DRIVER_SCRIPT}
                            ${TEST_INITIAL_CACHE_FILE}
                            ${TEST_DIRECTORY_NAME}
                            ${TEST_WORKING_DIRECTORY_NAME}
                            ${TEST_FILE})
    _define_test_for_driver (${TEST_NAME} ${TEST_DRIVER_SCRIPT})

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

    if (ADD_CMAKE_BUILD_TEST_NO_CLEAN)

        set (NO_CLEAN_OPTION NO_CLEAN)

    endif (ADD_CMAKE_BUILD_TEST_NO_CLEAN)

    _define_variables_for_test (${TEST_NAME})
    _bootstrap_test_driver_script(${TEST_NAME}
                                  ${TEST_DRIVER_SCRIPT}
                                  ${TEST_INITIAL_CACHE_FILE})
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
