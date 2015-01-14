# /CMakeUnit.cmake
#
# A Simple CMake Unit Testing Framework - assertions
# and utility library.
#
# This file provides some simple assertions for CMakeUnit
# which test scripts can use to verify certain details about
# what CMake knows about targets and properties set up.
#
# Most of the assertions take the form
#  - cmake_unit_assert_invariant
#  - cmake_unit_assert_not_invariant
#
# Usually the assertions would use the same determination
# as thier backend.
#
# This library also provides some utility functions which are useful
# in implementing CMake tests, like functions to generate source
# files and simple executables or to find the location of such
# libraries and executables at verify-time.
#
# The library isn't really designed for total flexibility
# but rather should be modified (and patches sent upstream!).
# This is due to a lack of polymorphism or support for
# first class functions in CMake .
#
# See LICENCE.md for Copyright information

# Be paranoid about multiple-inclusion. This file overrides core functions
# so it can only ever be included once.
if (_CMAKE_UNIT_INCLUDED)

    return ()

endif ()
set (_CMAKE_UNIT_INCLUDED TRUE)

include (CMakeParseArguments)
include (GenerateExportHeader)

# cmake_unit_escape_string
#
# Escape all regex control characters from INPUT and store in
# OUTPUT_VARIABLE
#
# INPUT: Input string
# OUTPUT_VARIABLE: Name of variable to store escaped string into
function (cmake_unit_escape_string INPUT OUTPUT_VARIABLE)

    string (REPLACE "\\" "\\\\" INPUT "${INPUT}")
    string (REPLACE "(" "\\(" INPUT "${INPUT}")
    string (REPLACE ")" "\\)" INPUT "${INPUT}")
    string (REPLACE "[" "\\[" INPUT "${INPUT}")
    string (REPLACE "]" "\\]" INPUT "${INPUT}")
    string (REPLACE "*" "\\*" INPUT "${INPUT}")
    string (REPLACE "+" "\\+" INPUT "${INPUT}")
    string (REPLACE "$" "\\$" INPUT "${INPUT}")
    string (REPLACE "^" "\\^" INPUT "${INPUT}")
    string (REPLACE "}" "\\}" INPUT "${INPUT}")
    string (REPLACE "{" "\\{" INPUT "${INPUT}")

    set (${OUTPUT_VARIABLE} "${INPUT}" PARENT_SCOPE)

endfunction ()

# Helper macro to append an accumulated command list to
# ADD_CUSTOM_COMMAND_PRINT_STRINGS
#
# Do not call this macro outside of the add_custom_command
# wrapper. Do not change it to a function.
macro (_cmake_unit_append_command_being_accumulated)

    if (ACCUMULATING_COMMAND)

        string (REPLACE ";" " "
                STRINGIFIED_COMMAND "${COMMAND_BEING_ACCUMULATED}")
        list (APPEND
              ADD_CUSTOM_COMMAND_PRINT_STRINGS # NOLINT:unused/var_in_func
              COMMAND "${STRINGIFIED_COMMAND}")
        unset (COMMAND_BEING_ACCUMULATED)
        set (ACCUMULATING_COMMAND FALSE)

    endif ()

endmacro ()

# Wraps add_custom_command to print out the COMMAND line on generators that
# wont print that even when verbose mode is enabled.
#
# This function must be named add_custom_command, so we are disabling
# structure/namespace here
function (add_custom_command) # NOLINT:structure/namespace

    set (ADD_CUSTOM_COMMAND_KNOWN_ARGUMENTS
         OUTPUT
         COMMAND
         MAIN_DEPENDENCY
         DEPENDS
         IMPLICIT_DEPENDS
         WORKING_DIRECTORY
         COMMENT
         VERBATIM)

    set (ADD_CUSTOM_COMMAND_PRINT_STRINGS)
    # COMMAND can be repeated multiple times inside of add_custom_command
    # so we can't use cmake_parse_arguments to extract it. Instead we
    # need to loop through all the arguments and find instances of
    # COMMAND. Once one is found, we'll stop and add a a new COMMAND to
    # append-arguments list to print it
    set (ACCUMULATING_COMMAND FALSE)
    set (COMMAND_BEING_ACCUMULATED)

    foreach (ARG ${ARGN})

        foreach (KNOWN_ARG ${ADD_CUSTOM_COMMAND_KNOWN_ARGUMENTS})

            if (KNOWN_ARG STREQUAL ARG)

                # Hit a new list argument. If we're accumulating a command,
                # stop and add it to our PRINT_STRINGS list
                _cmake_unit_append_command_being_accumulated ()

            endif ()

        endforeach ()

        if (ACCUMULATING_COMMAND)

            list (APPEND COMMAND_BEING_ACCUMULATED
                  ${ARG})

        endif ()

        # Avoid CMP0054 violation
        set (COMMAND_ARG "COMMAND")

        # If the arg we just hit was COMMAND, then start
        # accumulating commands
        if (ARG STREQUAL COMMAND_ARG)

            set (ACCUMULATING_COMMAND TRUE)

        endif ()

    endforeach ()

    # End of list. If a command was being accumulated, add it now
    _cmake_unit_append_command_being_accumulated ()

    # Now loop over PRINT_STRINGS to build the APPEND_ARGUMENTS list
    set (ADD_CUSTOM_COMMAND_APPEND_ARGUMENTS)
    foreach (STRING ${ADD_CUSTOM_COMMAND_PRINT_STRINGS})

        list (APPEND ADD_CUSTOM_COMMAND_APPEND_ARGUMENTS
              COMMAND "${CMAKE_COMMAND}" -E echo "${STRING}")

    endforeach ()

    # Obviously, the private function must be accessed
    _add_custom_command (${ARGN} # NOLINT:access/other_private
                         ${ADD_CUSTOM_COMMAND_APPEND_ARGUMENTS})

endfunction ()

set (_CMAKE_UNIT_SOURCE_FILE_OPTION_ARGS)
set (_CMAKE_UNIT_SOURCE_FILE_SINGLEVAR_ARGS NAME FUNCTIONS_EXPORT_TARGET)
set (_CMAKE_UNIT_SOURCE_FILE_MULTIVAR_ARGS
     INCLUDES
     DEFINES
     FUNCTIONS
     PREPEND_CONTENTS
     INCLUDE_DIRECTORIES)

function (_cmake_unit_get_created_source_file_contents CONTENTS_RETURN
                                                       NAME_RETURN)

    set (GET_CREATED_SOURCE_FILE_OPTION_ARGS
         ${_CMAKE_UNIT_SOURCE_FILE_OPTION_ARGS})
    set (GET_CREATED_CONTENTS_SINGLEVAR_ARGS
         ${_CMAKE_UNIT_SOURCE_FILE_SINGLEVAR_ARGS})
    set (GET_CREATED_CONTENTS_MULTIVAR_ARGS
         ${_CMAKE_UNIT_SOURCE_FILE_MULTIVAR_ARGS})

    cmake_parse_arguments (GET_CREATED
                           "${GET_CREATED_SOURCE_FILE_OPTION_ARGS}"
                           "${GET_CREATED_CONTENTS_SINGLEVAR_ARGS}"
                           "${GET_CREATED_CONTENTS_MULTIVAR_ARGS}"
                           ${ARGN})

    if (NOT GET_CREATED_NAME)

        set (GET_CREATED_NAME "Source.cpp")

    endif ()

    # Detect intended file type from filename

    get_filename_component (EXTENSION "${GET_CREATED_NAME}" EXT)
    string (SUBSTRING "${EXTENSION}" 1 -1 EXTENSION)
    set (SOURCE_EXTENSIONS
         ${CMAKE_C_SOURCE_FILE_EXTENSIONS}
         ${CMAKE_CXX_SOURCE_FILE_EXTENSIONS})
    list (FIND SOURCE_EXTENSIONS ${EXTENSION} SOURCE_INDEX)

    if (SOURCE_INDEX EQUAL -1)

        set (SOURCE_TYPE HEADER)

    else ()

        set (SOURCE_TYPE SOURCE)

    endif ()

    # Header guards (if header)
    if (SOURCE_TYPE STREQUAL "HEADER")

        get_filename_component (HEADER_BASENAME "${GET_CREATED_NAME}" NAME)
        string (REPLACE "." "_" HEADER_BASENAME "${HEADER_BASENAME}")
        string (TOUPPER "${HEADER_BASENAME}" HEADER_GUARD)
        list (APPEND CONTENTS
              "#ifndef ${HEADER_GUARD}"
              "#define ${HEADER_GUARD}")

    endif ()

    # If this is a "source" file and FUNCTIONS_EXPORT_TARGET is set then
    # we're building a library. As such, we need to insert some platform
    # specific defines to indicate that functions should be exported.
    if (GET_CREATED_FUNCTIONS_EXPORT_TARGET)

        set (EXPORT_HEADER "${GET_CREATED_FUNCTIONS_EXPORT_TARGET}_export.h")
        set (EXPORT_HEADER_PATH "${CMAKE_CURRENT_BINARY_DIR}/${EXPORT_HEADER}")
        list (APPEND CONTENTS "#include \"${EXPORT_HEADER_PATH}\"")

        string (TOUPPER "${GET_CREATED_FUNCTIONS_EXPORT_TARGET}"
                EXPORT_TARGET_UPPER)
        set (EXPORT_MACRO "${EXPORT_TARGET_UPPER}_EXPORT ")

    endif ()

    # Defines
    foreach (DEFINE ${GET_CREATED_DEFINES})

        list (APPEND CONTENTS
              "#define ${DEFINE}")

    endforeach ()

    # Includes
    foreach (INCLUDE ${GET_CREATED_INCLUDES})

        set (INCLUDED_AT_GLOBAL_SCOPE FALSE)

        foreach (DIR ${GET_CREATED_INCLUDE_DIRECTORIES})

            string (LENGTH "${DIR}" DIR_LENGTH)
            string (LENGTH "${INCLUDE}" INCLUDE_LENGTH)

            # If DIR_LENGTH is greater than INCLUDE_LENGTH then
            # the INCLUDE is definitely not within DIR. Avoid a STRING error.
            if (DIR_LENGTH LESS INCLUDE_LENGTH)

                string (SUBSTRING "${INCLUDE}" 0 ${DIR_LENGTH} INCLUDE_BEGIN)

                # If its the same, then this include was part of the specified
                # DIR, so put the rest of it in angle brackets
                if ("${INCLUDE_BEGIN}" STREQUAL "${DIR}")

                    math (EXPR INCLUDE_END_START "${DIR_LENGTH} + 1")
                    string (SUBSTRING "${INCLUDE}" ${INCLUDE_END_START} -1
                            INCLUDE_END)
                    list (APPEND CONTENTS
                          "#include <${INCLUDE_END}>")
                    set (INCLUDED_AT_GLOBAL_SCOPE TRUE)
                    break ()

                endif ()

            endif ()

        endforeach ()

        if (NOT INCLUDED_AT_GLOBAL_SCOPE)

            list (APPEND CONTENTS
                  "#include \"${INCLUDE}\"")

        endif ()

    endforeach ()

    # Forward declare all functions
    foreach (FUNCTION ${GET_CREATED_FUNCTIONS})

        # EXPORT_MACRO might be empty, so there's no space here
        # (we insert the space in the nonempty case)
        list (APPEND CONTENTS
              "${EXPORT_MACRO}int ${FUNCTION} ()@SEMICOLON@")

    endforeach ()

    # Prepend Contents - these must come after includes, defines
    # and function decls
    if (GET_CREATED_PREPEND_CONTENTS)

        list (APPEND CONTENTS "${GET_CREATED_PREPEND_CONTENTS}")

    endif ()

    # Function definitions, but only if we're a source
    if ("${SOURCE_TYPE}" STREQUAL "SOURCE")

        foreach (FUNCTION ${GET_CREATED_FUNCTIONS})

            list (APPEND CONTENTS
                  "${EXPORT_MACRO} int ${FUNCTION} ()"
                  "{"
                  "    return 0@SEMICOLON@"
                  "}")

        endforeach ()

    endif ()

    # End header guard
    if ("${SOURCE_TYPE}" STREQUAL "HEADER")

        list (APPEND CONTENTS
              "#endif")

    endif ()

    set (${NAME_RETURN} "${GET_CREATED_NAME}" PARENT_SCOPE)
    set (${CONTENTS_RETURN} "${CONTENTS}" PARENT_SCOPE)

endfunction ()

function (_cmake_unit_write_out_file_without_semicolons NAME)

    cmake_parse_arguments (WRITE_OUT_FILE
                           ""
                           ""
                           "CONTENTS"
                           ${ARGN})

    string (REPLACE ";" "\n" CONTENTS "${WRITE_OUT_FILE_CONTENTS}")
    string (REPLACE "@SEMICOLON@" ";" CONTENTS "${CONTENTS}")
    file (WRITE "${CMAKE_CURRENT_SOURCE_DIR}/${NAME}"
          "${CONTENTS}\n")

endfunction ()

# cmake_unit_write_out_source_file_before_build
#
# Writes out a source file, for use with add_library, add_executable
# or source scanners during the configure phase.
#
# If the source is detected as a header based on the NAME property such that
# it does not have a C or C++ extension, then header guards will be written
# and function definitions will not be included.
#
# [Optional] NAME: Name of the source file. May include slashes which will
#                  be interpreted as a subdirectory relative to
#                  CMAKE_CURRENT_SOURCE_DIR. The default is Source.cpp
# [Optional] INCLUDES: A list of files, relative or absolute paths, to #include
# [Optional] DEFINES: A list of #defines (macro name only)
# [Optional] FUNCTIONS: A list of functions.
# [Optional] PREPEND_CONTENTS: Contents to include in the file after
#                              INCLUDES, DEFINES and Function Declarations,
#                              but before Function Definitions
# [Optional] INCLUDE_DIRECTORIES: A list of directories such that, if an entry
#                                 in the INCLUDES list has the same directory
#                                 name as an entry in INCLUDE_DIRECTORIES then
#                                 the entry will be angle-brackets <include>
#                                 with the path relative to that include
#                                 directory.
function (cmake_unit_create_source_file_before_build)

    _cmake_unit_get_created_source_file_contents (CONTENTS NAME ${ARGN})
    _cmake_unit_write_out_file_without_semicolons ("${NAME}"
                                                   CONTENTS ${CONTENTS})

endfunction ()

# cmake_unit_generate_source_file_during_build
#
# Generates a source file, for use with add_library, add_executable
# or source scanners during the build phase.
#
# If the source is detected as a header based on the NAME property such that
# it does not have a C or C++ extension, then header guards will be written
# and function definitions will not be included.
#
# TARGET_RETURN: Name of the target that this source file will be generated on.
# [Optional] NAME: Name of the source file. May include slashes which will
#                  be interpreted as a subdirectory relative to
#                  CMAKE_CURRENT_SOURCE_DIR. The default is Source.cpp
# [Optional] FUNCTIONS_EXPORT_TARGET: The target that this source file is
#                                     built for. Generally this is used
#                                     if it is necessary to export functions
#                                     from this source file.
#                                     cmake_unit_create_simple_library uses
#                                     this argument for instance.
# [Optional] INCLUDES: A list of files, relative or absolute paths, to #include
# [Optional] DEFINES: A list of #defines (macro name only)
# [Optional] FUNCTIONS: A list of functions.
# [Optional] PREPEND_CONTENTS: Contents to include in the file after
#                              INCLUDES, DEFINES and Function Declarations,
#                              but before Function Definitions
# [Optional] INCLUDE_DIRECTORIES: A list of directories such that, if an entry
#                                 in the INCLUDES list has the same directory
#                                 name as an entry in INCLUDE_DIRECTORIES then
#                                 the entry will be angle-brackets <include>
#                                 with the path relative to that include
#                                 directory.
function (cmake_unit_generate_source_file_during_build TARGET_RETURN)

    # Write out to temporary location, which we'll later move into place
    # during the build
    _cmake_unit_get_created_source_file_contents (CONTENTS NAME ${ARGN})

    set (TMP_LOCATION "tmp/${NAME}")
    _cmake_unit_write_out_file_without_semicolons ("${TMP_LOCATION}"
                                                   CONTENTS ${CONTENTS})

    get_filename_component (BASENAME "${NAME}" NAME)
    get_filename_component (DIRECTORY "${NAME}" PATH)
    string (RANDOM SUFFIX)

    set (WRITE_SOURCE_FILE_SCRIPT
         "${CMAKE_CURRENT_SOURCE_DIR}/Write${BASENAME}${SUFFIX}.cmake")
    file (WRITE "${WRITE_SOURCE_FILE_SCRIPT}"
          "file (COPY \"${CMAKE_CURRENT_SOURCE_DIR}/${TMP_LOCATION}\"\n"
          "      DESTINATION \"${CMAKE_CURRENT_BINARY_DIR}/${DIRECTORY}\")\n")


    # Generate target name
    string (REGEX MATCHALL "[a-zA-z0-9]" MATCHED_TARGET_CHARACTERS
            "${BASENAME}${SUFFIX}")
    string (REPLACE ";" "" TARGET_NAME_WITH_UPPER_CHARACTERS
            "${MATCHED_TARGET_CHARACTERS}")
    string (TOLOWER "${TARGET_NAME_WITH_UPPER_CHARACTERS}" TARGET_NAME)
    set (TARGET_NAME "generate_${TARGET_NAME}")

    add_custom_command (OUTPUT "${CMAKE_CURRENT_BINARY_DIR}/${NAME}"
                        COMMAND "${CMAKE_COMMAND}" -P
                        "${WRITE_SOURCE_FILE_SCRIPT}")
    add_custom_target (${TARGET_NAME} ALL
                       SOURCES "${CMAKE_CURRENT_BINARY_DIR}/${NAME}")

    set (${TARGET_RETURN} "${TARGET_NAME}" PARENT_SCOPE)

endfunction ()

function (_cmake_unit_create_source_for_simple_target NAME
                                                      SOURCE_LOCATION_RETURN)

    string (RANDOM SUFFIX)
    set (SOURCE_LOCATION "${NAME}${SUFFIX}.cpp")
    cmake_unit_create_source_file_before_build (NAME "${SOURCE_LOCATION}"
                                                ${ARGN})
    set (${SOURCE_LOCATION_RETURN} "${SOURCE_LOCATION}" PARENT_SCOPE)

endfunction ()

# cmake_unit_create_simple_executable
#
# Creates a simple executable by the name "NAME" which will always have a
# "main" function.
#
# NAME: Name of executable
function (cmake_unit_create_simple_executable NAME)

    set (CREATE_SIMPLE_EXECUTABLE_SINGLEVAR_ARGS FUNCTIONS)
    cmake_parse_arguments (CREATE_SIMPLE_EXECUTABLE
                           ""
                           "${CREATE_SIMPLE_EXECUTABLE_SINGLEVAR_ARGS}"
                           ""
                           ${ARGN})

    # Ensure there is always a main in our source file
    set (CREATE_SOURCE_FUNCTIONS ${CREATE_SIMPLE_EXECUTABLE_FUNCTIONS} main)
    _cmake_unit_create_source_for_simple_target (${NAME} LOCATION
                                                 ${ARGN}
                                                 FUNCTIONS
                                                 ${CREATE_SOURCE_FUNCTIONS})
    add_executable (${NAME} "${LOCATION}")

endfunction ()

# cmake_unit_create_simple_library
#
# Creates a simple library by the name "NAME".
#
# NAME: Name of library
# TYPE: Type of the library (SHARED, STATIC)
# FUNCTIONS: Functions that the library should have.
function (cmake_unit_create_simple_library NAME TYPE)

    _cmake_unit_create_source_for_simple_target (${NAME} LOCATION ${ARGN}
                                                 FUNCTIONS_EXPORT_TARGET
                                                 ${NAME})
    add_library (${NAME} ${TYPE} "${LOCATION}")
    generate_export_header (${NAME})

endfunction ()

# cmake_unit_get_target_location_from_exports
#
# For an exports file EXPORTS and target TARGET, finds the location of a
# target from an already generated EXPORTS file.
#
# This function should be run in the verify phase in order to determine the
# location of a binary or library built by CMake. The initial configure
# step should run export (TARGETS ...) in order to generate this file.
#
# This function should alwyas be used where a binary or library needs to
# be invoked after build. Different platforms put the completed binaries
# in different places and also give them a different name. This function
# will resolve all those issues.
#
# EXPORTS: Full path to EXPORTS file to read
# TARGET: Name of TARGET as it will be found in the EXPORTS file
# LOCATION_RETURN: Variable to write target's LOCATION property into.
function (cmake_unit_get_target_location_from_exports EXPORTS
                                                      BINARY_DIR
                                                      TARGET
                                                      LOCATION_RETURN)

    # We create a new project which includes the exports file (as we
    # cannot do so whilst in script mode) and then prints the location
    # on the stderr. We'll capture this and return it.
    set (DETERMINE_LOCATION_DIRECTORY
         "${BINARY_DIR}/dle_${TARGET}")
    set (DETERMINE_LOCATION_BINARY_DIRECTORY
         "${DETERMINE_LOCATION_DIRECTORY}/build")
    set (DETERMINE_LOCATION_CAPTURE
         "${DETERMINE_LOCATION_BINARY_DIRECTORY}/Capture")
    set (DETERMINE_LOCATION_CMAKELISTS_TXT_FILE
         "${DETERMINE_LOCATION_DIRECTORY}/CMakeLists.txt")
    set (DETERMINE_LOCATION_CMAKELISTS_TXT
         "include (\"${EXPORTS}\")\n"
         "get_property (LOCATION TARGET ${TARGET} PROPERTY LOCATION)\n"
         "file (WRITE \"${DETERMINE_LOCATION_CAPTURE}\" \"\${LOCATION}\")\n")

    string (REPLACE ";" ""
            DETERMINE_LOCATION_CMAKELISTS_TXT
            "${DETERMINE_LOCATION_CMAKELISTS_TXT}")

    file (MAKE_DIRECTORY "${DETERMINE_LOCATION_DIRECTORY}")
    file (MAKE_DIRECTORY "${DETERMINE_LOCATION_BINARY_DIRECTORY}")
    file (WRITE "${DETERMINE_LOCATION_CMAKELISTS_TXT_FILE}"
          "${DETERMINE_LOCATION_CMAKELISTS_TXT}")

    set (DETERMINE_LOCATION_OUTPUT_LOG
         "${DETERMINE_LOCATION_BINARY_DIRECTORY}/DetermineLocationOutput.txt")
    set (DETERMINE_LOCATION_ERROR_LOG
         "${DETERMINE_LOCATION_BINARY_DIRECTORY}/DetermineLocationError.txt")

    execute_process (COMMAND "${CMAKE_COMMAND}" -Wno-dev
                     "${DETERMINE_LOCATION_DIRECTORY}"
                     OUTPUT_FILE ${DETERMINE_LOCATION_OUTPUT_LOG}
                     ERROR_FILE ${DETERMINE_LOCATION_ERROR_LOG}
                     RESULT_VARIABLE RESULT
                     WORKING_DIRECTORY "${DETERMINE_LOCATION_BINARY_DIRECTORY}")

    if (NOT RESULT EQUAL 0)

        message (FATAL_ERROR
                 "Error whilst getting location of ${TARGET}\n"
                 "See ${DETERMINE_LOCATION_ERROR_LOG} for details")

    endif ()

    file (READ ${DETERMINE_LOCATION_CAPTURE} LOCATION)
    set (${LOCATION_RETURN} "${LOCATION}" PARENT_SCOPE)

endfunction ()

# cmake_unit_export_cfg_int_dir
#
# Exports the current CMAKE_CFG_INTDIR variable (known at configure-time)
# and writes it into the file specified at LOCATION. This file could be read
# after the build to determine the CMAKE_CFG_INTDIR property
#
# LOCATION: Filename to write CMAKE_CFG_INTDIR variable to.
function (cmake_unit_export_cfg_int_dir LOCATION)

    get_filename_component (LOCATION_NAME "${LOCATION}" NAME)
    set (WRITE_TO_OUTPUT_SCRIPT_FILE "${LOCATION}.write.cmake")
    set (WRITE_TO_OUTPUT_FILE_SCRIPT_CONTENTS
         "file (WRITE \"${LOCATION}\" \"\${INTDIR}\")\n")
    file (WRITE "${WRITE_TO_OUTPUT_SCRIPT_FILE}"
          "${WRITE_TO_OUTPUT_FILE_SCRIPT_CONTENTS}")
    add_custom_command (OUTPUT ${LOCATION}
                        COMMAND "${CMAKE_COMMAND}"
                                -DINTDIR=${CMAKE_CFG_INTDIR}
                                -P
                                "${WRITE_TO_OUTPUT_SCRIPT_FILE}")
    add_custom_target (write_cfg_int_dir_${LOCATION_NAME} ALL
                       SOURCES ${LOCATION})

endfunction ()

# cmake_unit_import_cfg_int_dir
#
# Reads OUTPUT_FILE to import the value of the CMAKE_CFG_INTDIR property
# and stores the value inside of LOCATION_RETURN. This should be run in the
# verify phase to get the CMAKE_CFG_INTDIR property for the configure phase
# generator. Use cmake_unit_export_cfg_int_dir in the configure phase
# to export the CMAKE_CFG_INTDIR property.
#
# OUTPUT_FILE: Filename to read CMAKE_CFG_INTDIR variable from.
# LOCATION_RETURN: Variable to store CMAKE_CFG_INTDIR value into.
function (cmake_unit_import_cfg_int_dir OUTPUT_FILE LOCATION_RETURN)

    file (READ "${OUTPUT_FILE}" LOCATION)
    set (${LOCATION_RETURN} "${LOCATION}" PARENT_SCOPE)

endfunction ()

function (cmake_unit_assert_true VARIABLE)

    if (NOT VARIABLE)

        message (SEND_ERROR
                 "Expected ${VARIABLE} to be true")

    endif ()

endfunction ()

function (cmake_unit_assert_false VARIABLE)

    if (VARIABLE)

        message (SEND_ERROR
                 "Expected ${VARIABLE} to be false")

    endif ()

endfunction ()

function (_cmake_unit_target_exists TARGET_NAME RESULT_VARIABLE)

    set (${RESULT_VARIABLE} FALSE PARENT_SCOPE)

    if (TARGET ${TARGET_NAME})

        set (${RESULT_VARIABLE} TRUE PARENT_SCOPE)

    endif ()

endfunction ()

# cmake_unit_assert_target_exists
#
# Throws a non-fatal error if the target specified
# by TARGET_NAME is not a target known by CMake.
function (cmake_unit_assert_target_exists TARGET_NAME)

    _cmake_unit_target_exists (${TARGET_NAME} RESULT)

    if (NOT RESULT)

        message (SEND_ERROR
                 "Expected ${TARGET_NAME} to be a target")

    endif ()

endfunction ()


# cmake_unit_assert_target_does_not_exist
#
# Throws a non-fatal error if the target specified
# by TARGET_NAME is a target known by CMake.
function (cmake_unit_assert_target_does_not_exist TARGET_NAME)

    _cmake_unit_target_exists (${TARGET_NAME} RESULT)

    if (RESULT)

        message (SEND_ERROR
                 "Expected ${TARGET_NAME} not to be a target")

    endif ()

endfunction ()

function (_cmake_unit_string_contains MAIN_STRING SUBSTRING RESULT_VARIABLE)

    set (${RESULT_VARIABLE} FALSE PARENT_SCOPE)

    string (FIND ${MAIN_STRING} ${SUBSTRING} POSITION)

    if (NOT POSITION EQUAL -1)

        set (${RESULT_VARIABLE} TRUE PARENT_SCOPE)

    endif ()

endfunction ()

# cmake_unit_assert_string_contains
#
# Throws a non-fatal error if the string SUBSTRING
# is not a substring of MAIN_STRING.
function (cmake_unit_assert_string_contains MAIN_STRING SUBSTRING)

    _cmake_unit_string_contains (${MAIN_STRING} ${SUBSTRING} RESULT)

    if (NOT RESULT)

        message (SEND_ERROR
                 "Substring ${SUBSTRING} not found in ${MAIN_STRING}")

    endif ()

endfunction ()

# cmake_unit_assert_string_does_not_contain
#
# Throws a non-fatal error if the string SUBSTRING
# is a substring of MAIN_STRING.
function (cmake_unit_assert_string_does_not_contain MAIN_STRING SUBSTRING)

    _cmake_unit_string_contains (${MAIN_STRING} ${SUBSTRING} RESULT)

    if (RESULT)

        message (SEND_ERROR
                 "Substring ${SUBSTRING} not found in ${MAIN_STRING}")

    endif ()

endfunction ()

function (_cmake_unit_variable_is VARIABLE
                                  TYPE
                                  COMPARATOR
                                  VALUE
                                  RESULT_VARIABLE)

    set (${RESULT_VARIABLE} FALSE PARENT_SCOPE)

    # Prevent automatic deference of arguments which are intended to be
    # values and not variables
    set (STRING_TYPE "STRING")
    set (INTEGER_TYPE "INTEGER")
    set (BOOL_TYPE "BOOL")

    if (TYPE MATCHES "${STRING_TYPE}")

        if ("${${VARIABLE}}" STR${COMPARATOR} VALUE)

            set (${RESULT_VARIABLE} TRUE PARENT_SCOPE)

        endif ()

    elseif (TYPE MATCHES "${INTEGER_TYPE}")

        if ("${${VARIABLE}}" ${COMPARATOR} VALUE)

            set (${RESULT_VARIABLE} TRUE PARENT_SCOPE)

        endif ()

    elseif (TYPE MATCHES "${BOOL_TYPE}")

        if (COMPARATOR STREQUAL "EQUAL")

            if (${${VARIABLE}} AND VALUE)

                set (${RESULT_VARIABLE} TRUE PARENT_SCOPE)

            elseif (NOT ${${VARIABLE}} AND NOT VALUE)

                set (${RESULT_VARIABLE} TRUE PARENT_SCOPE)

            else ()

                set (${RESULT_VARIABLE} FALSE PARENT_SCOPE)

            endif ()

        else ()

            message (FATAL_ERROR "No comparators other than EQUAL are supported"
                                 "for comparing BOOL variables")

        endif ()

    else ()

        message (FATAL_ERROR
                 "Asked to match unknown type ${TYPE}")

    endif ()

endfunction ()

# cmake_unit_assert_variable_is
#
# Used to check if one VARIABLE is equal, greater than
# or less than another VALUE. The variable TYPE must
# be provided as the checks differ subtly between
# variable types. Valid types are:
#
#  STRING
#  INTEGER
#  BOOL
#
# A fatal error will be thrown when passing an unrecognized
# type. A non-fatal error will be thrown if the COMPARATOR
# operation fails between VARIABLE and VALUE
function (cmake_unit_assert_variable_is VARIABLE TYPE COMPARATOR VALUE)

    _cmake_unit_variable_is (${VARIABLE}
                             ${TYPE}
                             ${COMPARATOR}
                             "${VALUE}"
                             RESULT)

    if (NOT RESULT)

        message (SEND_ERROR
                 "Expected type ${TYPE} with value ${VALUE}"
                 " but was ${${VARIABLE}}")

    endif ()

endfunction ()

# cmake_unit_assert_variable_is_not
#
# Used to check if one VARIABLE is not equal, greater than
# or less than another VALUE. The variable TYPE must
# be provided as the checks differ subtly between
# variable types. Valid types are:
#
#  STRING
#  INTEGER
#  BOOL
#
# A fatal error will be thrown when passing an unrecognized
# type. A non-fatal error will be thrown if the COMPARATOR
# operation succeeds between VARIABLE and VALUE
function (cmake_unit_assert_variable_is_not VARIABLE TYPE COMPARATOR VALUE)

    _cmake_unit_variable_is (${VARIABLE}
                             ${TYPE}
                             ${COMPARATOR}
                             "${VALUE}"
                             RESULT)

    if (RESULT)

        message (SEND_ERROR
                 "Expected type ${TYPE} with value ${VALUE}"
                 " but was ${${VARIABLE}}")

    endif ()

endfunction ()

# cmake_unit_assert_variable_matches_regex
#
# The variable VARIABLE will be coerced into a string
# matched against the REGEX provided. Throws a non-fatal
# error if VARIABLE does not match REGEX.
function (cmake_unit_assert_variable_matches_regex VARIABLE REGEX)

    if (NOT ${VARIABLE} MATCHES ${REGEX})

        message (SEND_ERROR
                 "Expected ${VARIABLE} to match ${REGEX}")

    endif ()

endfunction ()

# cmake_unit_assert_variable_does_not_match_regex
#
# The variable VARIABLE will be coerced into a string
# matched against the REGEX provided. Throws a non-fatal
# error if VARIABLE does matches REGEX.
function (cmake_unit_assert_variable_does_not_match_regex VARIABLE REGEX)

    if (${VARIABLE} MATCHES ${REGEX})

        message (SEND_ERROR
                 "Expected ${VARIABLE} to not match ${REGEX}")

    endif ()

endfunction ()

# cmake_unit_assert_variable_is_defined
#
# Throws a non-fatal error if the variable specified by VARIABLE
# is not defined. Note that the variable name itself and not
# its value must be passed to this function.
function (cmake_unit_assert_variable_is_defined VARIABLE)

    if (NOT DEFINED ${VARIABLE})

        message (SEND_ERROR
                 "${VARIABLE} is not defined")

    endif ()

endfunction ()

# cmake_unit_assert_variable_is_not_defined
#
# Throws a non-fatal error if the variable specified by VARIABLE
# is defined. Note that the variable name itself and not
# its value must be passed to this function.
function (cmake_unit_assert_variable_is_not_defined VARIABLE)

    if (DEFINED ${VARIABLE})

        message (SEND_ERROR
                 "${VARIABLE} is defined")

    endif ()

endfunction ()

function (_cmake_unit_command_executes_with_success RESULT_VARIABLE
                                                    ERROR_VARIABLE
                                                    CODE_VARIABLE)

    set (COMMAND_EXECUTES_WITH_SUCCESS_MULTIVAR_ARGS COMMAND)
    cmake_parse_arguments (COMMAND_EXECUTES_WITH_SUCCESS
                           ""
                           ""
                           "${COMMAND_EXECUTES_WITH_SUCCESS_MULTIVAR_ARGS}"
                           ${ARGN})

    set (${RESULT_VARIABLE} FALSE PARENT_SCOPE)

    set (COMMAND_TO_RUN
         ${COMMAND_EXECUTES_WITH_SUCCESS_COMMAND}) # NOLINT:correctness/quotes

    execute_process (COMMAND ${COMMAND_TO_RUN}
                     RESULT_VARIABLE RESULT
                     ERROR_VARIABLE ERROR)

    if (RESULT EQUAL 0)

        set (${RESULT_VARIABLE} TRUE PARENT_SCOPE)

    endif ()

    set (${ERROR_VARIABLE} ${ERROR} PARENT_SCOPE)
    set (${CODE_VARIABLE} ${RESULT} PARENT_SCOPE)

endfunction ()

# cmake_unit_assert_command_executes_with_success
#
# Throws a non-fatal error if the command and argument
# list specified by COMMAND does not execute with
# success. Note that the name of the variable containing
# the command and the argument list must be provided
# as opposed to the command and argument list itself.
#
# COMMAND: Command to execute
function (cmake_unit_assert_command_executes_with_success)

    _cmake_unit_command_executes_with_success (RESULT ERROR CODE ${ARGN})

    if (NOT RESULT)

        message (SEND_ERROR
                 "The command ${ARGN} failed with result "
                 " ${CODE} : ${ERROR}\n")

    endif ()

endfunction ()

# cmake_unit_assert_command_does_not_execute_with_success
#
# Throws a non-fatal error if the command and argument
# list specified by COMMAND executes with
# success. Note that the name of the variable containing
# the command and the argument list must be provided
# as opposed to the command and argument list itself.
function (cmake_unit_assert_command_does_not_execute_with_success)

    _cmake_unit_command_executes_with_success (RESULT ERROR CODE ${ARGN})

    if (RESULT)

        message (SEND_ERROR
                 "The command ${ARGN} succeeded with result "
                 " ${RESULT}\n")

    endif ()

endfunction ()

function (_cmake_unit_lib_found_in_libraries LIBRARY RESULT_VARIABLE)

    set (LIB_FOUND_IN_LIBRARIES_MULTIVAR_ARGS LIBRARIES)

    cmake_parse_arguments (LIB_FOUND
                           ""
                           ""
                           "${LIB_FOUND_IN_LIBRARIES_MULTIVAR_ARGS}"
                           ${ARGN})

    foreach (_lib ${LIB_FOUND_LIBRARIES})

        if (_lib MATCHES "(^.*${LIBRARY}.*$)")

            set (${RESULT_VARIABLE} TRUE PARENT_SCOPE)

        endif ()

    endforeach ()

endfunction ()

function (_cmake_unit_print_all_target_libraries TARGET)

    get_property (INTERFACE_LIBRARIES
                  TARGET ${TARGET}
                  PROPERTY INTERFACE_LINK_LIBRARIES)
    get_property (LINK_LIBRARIES
                  TARGET ${TARGET}
                  PROPERTY LINK_LIBRARIES)

    foreach (LIB ${INTERFACE_LIBRARIES})

        message (STATUS "Part of link interface: ${LIB}")

    endforeach ()

    foreach (LIB ${LINK_LIBRARIES})

        message (STATUS "Link library: ${LIB}")

    endforeach ()

endfunction ()

function (_cmake_unit_target_is_linked_to TARGET_NAME
                                          LIBRARY
                                          RESULT_VARIABLE)

    get_property (INTERFACE_LIBS
                  TARGET ${TARGET_NAME}
                  PROPERTY INTERFACE_LINK_LIBRARIES)
    get_property (LINK_LIBS
                  TARGET ${TARGET_NAME}
                  PROPERTY LINK_LIBRARIES)

    _cmake_unit_lib_found_in_libraries (${LIBRARY} FOUND_IN_INTERFACE
                                        LIBRARIES ${INTERFACE_LIBS})
    _cmake_unit_lib_found_in_libraries (${LIBRARY} FOUND_IN_LINK
                                        LIBRARIES ${LINK_LIBS})

    if (FOUND_IN_INTERFACE OR FOUND_IN_LINK)

        set (${RESULT_VARIABLE} TRUE PARENT_SCOPE)

    else ()

        set (${RESULT_VARIABLE} FALSE PARENT_SCOPE)

    endif ()

endfunction ()

# cmake_unit_assert_target_is_linked_to
#
# Throws a non-fatal error if the target specified by
# TARGET_NAME is not linked to a library which matches
# the name LIBRARY. Note that this function does regex
# matching under the hood, matching a whole line which
# contains anything matching LIBRARY.
function (cmake_unit_assert_target_is_linked_to TARGET_NAME LIBRARY)

    _cmake_unit_target_is_linked_to (${TARGET_NAME} ${LIBRARY} RESULT LIBRARIES)

    if (NOT RESULT)

        message (SEND_ERROR
                 "Expected ${LIBRARY} to be a link-library to ${TARGET_NAME}")

        _cmake_unit_print_all_target_libraries (${TARGET_NAME})

    endif ()

endfunction ()

# cmake_unit_assert_target_is_not_linked_to
#
# Throws a non-fatal error if the target specified by
# TARGET_NAME is linked to a library which matches
# the name LIBRARY. Note that this function does regex
# matching under the hood, matching a whole line which
# contains anything matching LIBRARY.
function (cmake_unit_assert_target_is_not_linked_to TARGET_NAME LIBRARY)

    _cmake_unit_target_is_linked_to (${TARGET_NAME} ${LIBRARY} RESULT LIBRARIES)

    if (RESULT)

        message (SEND_ERROR
                 "Expected ${LIBRARY} not to be a link-library "
                 "to ${TARGET_NAME}")

        _cmake_unit_print_all_target_libraries (${TARGET_NAME})

    endif ()

endfunction ()

function (_cmake_unit_item_has_property_with_value ITEM_TYPE
                                                   ITEM
                                                   PROPERTY
                                                   PROPERTY_TYPE
                                                   COMPARATOR
                                                   VALUE
                                                   RESULT_VARIABLE)

    # GLOBAL scope is special, in that case we don't really
    # have an item, so we need to get rid of it.
    if (ITEM_TYPE STREQUAL "GLOBAL")

        set (ITEM)

    endif ()

    get_property (_PROPERTY_VALUE ${ITEM_TYPE} ${ITEM}
                  PROPERTY ${PROPERTY})

    _cmake_unit_variable_is (_PROPERTY_VALUE
                             ${PROPERTY_TYPE}
                             ${COMPARATOR}
                             "${VALUE}"
                             RESULT)

    set (${RESULT_VARIABLE} ${RESULT} PARENT_SCOPE)

endfunction ()

# cmake_unit_assert_has_property_with_value
#
# Throws a non-fatal error if the ITEM with ITEM_TYPE specified does not
# have a PROPERTY of PROPERTY_TYPE which satisfies COMPARATOR with
# the VALUE specified.
function (cmake_unit_assert_has_property_with_value ITEM_TYPE
                                                    ITEM
                                                    PROPERTY
                                                    PROPERTY_TYPE
                                                    COMPARATOR
                                                    VALUE)

    _cmake_unit_item_has_property_with_value (${ITEM_TYPE}
                                              ${ITEM}
                                              ${PROPERTY}
                                              ${PROPERTY_TYPE}
                                              ${COMPARATOR}
                                              "${VALUE}"
                                              RESULT)

    if (NOT RESULT)

        message (SEND_ERROR
                 "Expected ${ITEM_TYPE} ${ITEM} to have property ${PROPERTY} "
                 " of type ${PROPERTY_TYPE} with value ${VALUE}")

    endif ()

endfunction ()

# cmake_unit_assert_does_not_have_property_with_value
#
# Throws a non-fatal error if the ITEM with ITEM_TYPE specified
# has a PROPERTY of PROPERTY_TYPE which satisfies COMPARATOR with
# the VALUE specified.
function (cmake_unit_assert_does_not_have_property_with_value ITEM_TYPE
                                                              ITEM
                                                              PROPERTY
                                                              PROPERTY_TYPE
                                                              COMPARATOR
                                                              VALUE)


    _cmake_unit_item_has_property_with_value (${ITEM_TYPE}
                                              ${ITEM}
                                              ${PROPERTY}
                                              ${PROPERTY_TYPE}
                                              ${COMPARATOR}
                                              ${VALUE}
                                              RESULT)

    if (RESULT)

        message (SEND_ERROR
                 "Expected ${ITEM_TYPE} ${ITEM} not to have property"
                 " ${PROPERTY} of type ${PROPERTY_TYPE} with value ${VALUE}")

    endif ()

endfunction ()

function (_cmake_unit_list_contains_value LIST_VARIABLE
                                          TYPE
                                          COMPARATOR
                                          VALUE
                                          RESULT_VARIABLE)

    set (${RESULT_VARIABLE} FALSE PARENT_SCOPE)

    foreach (LIST_VALUE ${${LIST_VARIABLE}})

        set (_CHILD_VALUE ${LIST_VALUE})
        _cmake_unit_variable_is (_CHILD_VALUE
                                 ${TYPE}
                                 ${COMPARATOR}
                                 "${VALUE}"
                                 RESULT)

        if (RESULT)

            set (${RESULT_VARIABLE} TRUE PARENT_SCOPE)

        endif ()

    endforeach ()

endfunction ()

# cmake_unit_assert_list_contains_value
#
# Throws a non-fatal error if the list specified by LIST_VARIABLE
# does not contain a value which satisfies COMPARATOR with
# VALUE
function (cmake_unit_assert_list_contains_value LIST_VARIABLE
                                                TYPE
                                                COMPARATOR
                                                VALUE)

    _cmake_unit_list_contains_value (${LIST_VARIABLE}
                                     ${TYPE}
                                     ${COMPARATOR}
                                     ${VALUE}
                                     RESULT)

    if (NOT RESULT)

        message (SEND_ERROR "List ${LIST_VARIABLE} does not contain a value "
                            "${COMPARATOR} ${VALUE}")

    endif ()

endfunction ()

# cmake_unit_assert_list_contains_value
#
# Throws a non-fatal error if the list specified by LIST_VARIABLE
# contains a value which satisfies COMPARATOR with VALUE
function (cmake_unit_assert_list_does_not_contain_value LIST_VARIABLE
                                                        TYPE
                                                        COMPARATOR
                                                        VALUE)

    _cmake_unit_list_contains_value (${LIST_VARIABLE}
                                     ${TYPE}
                                     ${COMPARATOR}
                                     ${VALUE}
                                     RESULT)

    if (RESULT)

        message (SEND_ERROR "List ${LIST_VARIABLE} contains a value "
                            "${COMPARATOR} ${VALUE}")

    endif ()

endfunction ()

function (_cmake_unit_item_has_property_containing_value ITEM_TYPE
                                                         ITEM
                                                         PROPERTY
                                                         PROPERTY_TYPE
                                                         COMPARATOR
                                                         VALUE
                                                         RESULT_VARIABLE)

    set (${RESULT_VARIABLE} FALSE PARENT_SCOPE)

    # GLOBAL scope is special, in that case we don't really
    # have an item, so we need to get rid of it.
    if (ITEM_TYPE STREQUAL "GLOBAL")

        set (ITEM)

    endif ()

    get_property (_PROPERTY_VALUES ${ITEM_TYPE} ${ITEM}
                  PROPERTY ${PROPERTY})

    _cmake_unit_list_contains_value (_PROPERTY_VALUES
                                     ${PROPERTY_TYPE}
                                     ${COMPARATOR}
                                     "${VALUE}"
                                     RESULT)

    if (RESULT)

        set (${RESULT_VARIABLE} TRUE PARENT_SCOPE)

    endif ()

endfunction ()

# cmake_unit_assert_has_property_containing_value
#
# Throws a non-fatal error if the ITEM with ITEM_TYPE specified does not
# have a PROPERTY of PROPERTY_TYPE of which one of the items in the property
# value's list satisfies COMPARATOR
function (cmake_unit_assert_has_property_containing_value ITEM_TYPE
                                                          ITEM
                                                          PROPERTY
                                                          PROPERTY_TYPE
                                                          COMPARATOR
                                                          VALUE)

    _cmake_unit_item_has_property_containing_value (${ITEM_TYPE}
                                                    ${ITEM}
                                                    ${PROPERTY}
                                                    ${PROPERTY_TYPE}
                                                    ${COMPARATOR}
                                                    ${VALUE}
                                                    RESULT)

    if (NOT RESULT)

        message (SEND_ERROR
                 "Expected ${ITEM_TYPE} ${ITEM} to have property ${PROPERTY} "
                 " of type ${PROPERTY_TYPE} containing value ${VALUE}")

    endif ()

endfunction ()

# cmake_unit_assert_does_not_have_property_containing_value
#
# Throws a non-fatal error if the ITEM with ITEM_TYPE specified does not
# have a PROPERTY of PROPERTY_TYPE of which one of the items in the property
# value's list satisfies COMPARATOR
function (cmake_unit_assert_does_not_have_property_containing_value ITEM_TYPE
                                                                    ITEM
                                                                    PROPERTY
                                                                    PROP_TYPE
                                                                    COMPARATOR
                                                                    VALUE)

    _cmake_unit_item_has_property_containing_value (${ITEM_TYPE}
                                                    ${ITEM}
                                                    ${PROPERTY}
                                                    ${PROP_TYPE}
                                                    ${COMPARATOR}
                                                    ${VALUE}
                                                    RESULT)

    if (RESULT)

        message (SEND_ERROR
                 "Expected ${ITEM_TYPE} ${ITEM} not to have property "
                 "${PROPERTY} of type ${PROPERTY_TYPE} containing "
                 "value ${VALUE}")

    endif ()

endfunction ()

function (_cmake_unit_file_exists FILE RESULT_VARIABLE)

    set (${RESULT_VARIABLE} TRUE PARENT_SCOPE)

    if (NOT EXISTS "${FILE}")

        set (${RESULT_VARIABLE} FALSE PARENT_SCOPE)

    endif ()

endfunction ()

# cmake_unit_assert_file_exists:
#
# Throws a non-fatal error if the file specified by FILE
# does not exist on the filesystem
function (cmake_unit_assert_file_exists FILE)

    _cmake_unit_file_exists ("${FILE}" RESULT)

    if (NOT RESULT)

        message (SEND_ERROR "The file ${FILE} does not exist")

    endif ()

endfunction ()

# cmake_unit_assert_file_does_not_exist:
#
# Throws a non-fatal error if the file specified by FILE
# exists the filesystem
function (cmake_unit_assert_file_does_not_exist FILE)

    _cmake_unit_file_exists ("${FILE}" RESULT)

    if (RESULT)

        message (SEND_ERROR "The file ${FILE} does exist")

    endif ()

endfunction ()

function (_cmake_unit_file_contains_substring FILE SUBSTRING RESULT_VARIABLE)

    file (READ "${FILE}" CONTENTS)

    _cmake_unit_string_contains (${CONTENTS} ${SUBSTRING} RESULT)

    # PARENT_SCOPE only propogates up one level so we need to
    # propogate the result here too
    set (${RESULT_VARIABLE} ${RESULT} PARENT_SCOPE)

endfunction ()

# cmake_unit_assert_file_contains:
#
# Throws a non-fatal error if the file specified by FILE
# does not contain the substring SUBSTRING
function (cmake_unit_assert_file_contains FILE SUBSTRING)

    _cmake_unit_file_contains_substring ("${FILE}" ${SUBSTRING} RESULT)

    if (NOT RESULT)

        message (SEND_ERROR
                 "The file ${FILE} does not contain the string ${SUBSTRING}")

    endif ()

endfunction ()

# cmake_unit_assert_file_does_not_contain:
#
# Throws a non-fatal error if the file specified by FILE
# contains the substring SUBSTRING
function (cmake_unit_assert_file_does_not_contain FILE SUBSTRING)

    _cmake_unit_file_contains_substring ("${FILE}" ${SUBSTRING} RESULT)

    if (RESULT)

        message (SEND_ERROR
                 "The file ${FILE} contains the string ${SUBSTRING}")

    endif ()

endfunction ()

function (_cmake_unit_file_has_line_matching FILE PATTERN RESULT_VARIABLE)

    set (${RESULT_VARIABLE} FALSE PARENT_SCOPE)

    file (READ "${FILE}" CONTENTS)

    # Split the string into individual lines
    string (REGEX REPLACE ";" "\\\;" CONTENTS "${CONTENTS}")
    string (REGEX REPLACE "\n" ";" CONTENTS "${CONTENTS}")

    # Now loop over each line and check if there's a match against PATTERN
    foreach (LINE ${CONTENTS})

        if (LINE MATCHES ${PATTERN})

            set (${RESULT_VARIABLE} TRUE PARENT_SCOPE)
            break ()

        endif ()

    endforeach ()

endfunction ()

# cmake_unit_assert_file_has_line_matching
#
# Throws a non-fatal error if the file specified by FILE
# does not have a line that matches PATTERN
function (cmake_unit_assert_file_has_line_matching FILE PATTERN)

    _cmake_unit_file_has_line_matching ("${FILE}" ${PATTERN} RESULT)

    if (NOT RESULT)

        message (SEND_ERROR
                 "The file ${FILE} does not have a line matching ${PATTERN}")

    endif ()

endfunction ()

# cmake_unit_assert_file_does_not_have_line_matching
#
# Throws a non-fatal error if the file specified by FILE
# has a line that matches PATTERN
function (cmake_unit_assert_file_does_not_have_line_matching FILE PATTERN)

    _cmake_unit_file_has_line_matching ("${FILE}" ${PATTERN} RESULT)

    if (RESULT)

        message (SEND_ERROR
                 "The file ${FILE} has a line matching ${PATTERN}")

    endif ()

endfunction ()
