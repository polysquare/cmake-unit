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
         "function (add_driver_command COMMAND_VAR)\n"
         "    execute_process (COMMAND \${\${COMMAND_VAR}}\n"
         "                     RESULT_VARIABLE RESULT\n"
         "                     OUTPUT_VARIABLE OUTPUT\n"
         "                     ERROR_VARIABLE ERROR)\n"
         "    if (RESULT EQUAL 0)\n"
         "        message (\${OUTPUT} ${ERROR})\n"
         "    else (RESULT EQUAL 0)\n"
         "        message (FATAL_ERROR \n"
         "                 \"The command \${\${COMMAND_VAR}}} failed with \"\n"
         "                 \"\${RESULT} : \${ERROR}\")\n"
         "    endif (RESULT EQUAL 0)\n"
         "endfunction (add_driver_command)\n")
    file (WRITE ${DRIVER_SCRIPT} ${TEST_DRIVER_SCRIPT_CONTENTS})

    file (WRITE ${CACHE_FILE}
          ${_CMAKE_UNIT_INITIAL_CACHE_CONTENTS})

endfunction (_bootstrap_test_driver_script)

function (_add_driver_step DRIVER_SCRIPT STEP COMMAND_VAR)

    file (APPEND ${DRIVER_SCRIPT}
          "set (${STEP} ${${COMMAND_VAR}})\n"
          "add_driver_command (${STEP})\n")

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

    set (TEST_FILE_PATH
         ${CMAKE_CURRENT_SOURCE_DIR}/${TEST_FILE})

    if (EXISTS ${TEST_FILE_PATH})

        set (TEST_DIRECTORY_CONFIGURE_SCRIPT
             ${TEST_DIRECTORY_NAME}/CMakeLists.txt)
        set (TEST_DIRECTORY_CONFIGURE_SCRIPT_CONTENTS
             "project (TestProject CXX C)\n"
             "cmake_minimum_required (VERSION 2.8 FATAL_ERROR)\n"
             "include (${CMAKE_CURRENT_SOURCE_DIR}/${TEST_FILE})\n")

        file (WRITE ${TEST_DIRECTORY_CONFIGURE_SCRIPT}
              ${TEST_DIRECTORY_CONFIGURE_SCRIPT_CONTENTS})

        set (CONFIGURE_COMMAND ${CMAKE} .. -C${CACHE_FILE})
        _add_driver_step (${DRIVER_SCRIPT} CONFIGURE CONFIGURE_COMMAND)

    endif (EXISTS ${TEST_FILE_PATH})

endfunction (_append_configure_step)

function (_append_build_step DRIVER_SCRIPT
                             TEST_WORKING_DIRECTORY_NAME)

    set (BUILD_COMMAND ${CMAKE} --build ${TEST_WORKING_DIRECTORY_NAME})
    _add_driver_step (${DRIVER_SCRIPT} BUILD BUILD_COMMAND)

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
        _add_driver_step (${DRIVER_SCRIPT} VERIFY VERIFY_COMMAND)

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
    _append_build_step (${TEST_DRIVER_SCRIPT} ${TEST_WORKING_DIRECTORY_NAME})
    _append_verify_step (${TEST_DRIVER_SCRIPT}
                         ${TEST_INITIAL_CACHE_FILE}
                         ${VERIFY})
    _define_test_for_driver (${TEST_NAME} ${TEST_DRIVER_SCRIPT})

endfunction (add_cmake_build_test)