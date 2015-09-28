# /CMakeUnit.cmake
#
# A Simple CMake Unit Testing Framework - matchers
# and utility library.
#
# This file provides some simple matchers for CMakeUnit
# which test scripts can use to verify certain details about
# what CMake knows about targets and properties set up.
#
# Tests are constructed in the xUnit style, a single, generalized
# cmake_unit_assert_that function is provided along with a standard
# library of matchers. Assert things as so:
#
#     cmake_unit_assert_that (MY_VARIABLE compare_as STRING EQUAL "value")
#     cmake_unit_assert_that ("/File" file_contents compare_as "hello")
#     cmake_unit_assert_that (target is_linked_to other_target)
#
# This library also provides some utility functions which are useful
# in implementing CMake tests, like functions to generate source
# files and simple executables or to find the location of such
# libraries and executables at verify-time.
#
# See /LICENCE.md for Copyright information
if (NOT BIICODE)

    set (CMAKE_MODULE_PATH
         "${CMAKE_CURRENT_LIST_DIR}/bii/deps"
         "${CMAKE_MODULE_PATH}")

endif (NOT BIICODE)

include ("smspillaz/cmake-include-guard/IncludeGuard")
cmake_include_guard (SET_MODULE_PATH)

include (CMakeParseArguments)
include (GenerateExportHeader)
include ("smspillaz/cmake-call-function/CallFunction")
include ("smspillaz/cmake-forward-arguments/ForwardArguments")
include ("smspillaz/cmake-opt-arg-parsing/OptimizedParseArguments")
include ("smspillaz/cmake-spacify-list/SpacifyList")

# _cmake_unit_get_hash_for_file
#
# Lazy-compute a hash for the specified file
#
# FILE: File to compute hash for.
# RETURN_HASH: Variable to place hash in.
function (_cmake_unit_get_hash_for_file FILE RETURN_HASH)

    set (CALLING_FILE_HASH_PROPERTY "${CALLING_FILE}_HASH")
    get_property (CALLING_FILE_HASH_SET
                  GLOBAL PROPERTY "${CALLING_FILE_HASH_PROPERTY}"
                  SET)

    if (NOT CALLING_FILE_HASH_SET)

        file (SHA1 "${FILE}"
              _COMPUTE_USER_HASH_CURRENT_USER_FILE_SHA1)

        set_property (GLOBAL PROPERTY "${CALLING_FILE_HASH_PROPERTY}"
                      "${_COMPUTE_USER_HASH_CURRENT_USER_FILE_SHA1}")

    endif ()

    get_property (CALLING_FILE_HASH
                  GLOBAL PROPERTY "${CALLING_FILE_HASH_PROPERTY}")

    set (${RETURN_HASH} "${CALLING_FILE_HASH}" PARENT_SCOPE)

endfunction ()

# cmake_unit_should_write
#
# Determine if the CALLING_FILE is newer than FILE and if so, write the
# CALLING_FILE's hash on disk and return true.
#
# You should use this function if you need to write the file in a special
# way that does not allow its contents to be passed directly to
# cmake_unit_write_if_newer.
#
# FILE: File proposed to be written to.
# CALLING_FILE: File to compare with.
# SHOULD_WRITE_RETURN: Name of variable to set should-write status to.
function (cmake_unit_should_write FILE CALLING_FILE SHOULD_WRITE_RETURN)

    set (HASH_FILE "${FILE}.stamp.sha1")
    set (SHOULD_WRITE TRUE)

    _cmake_unit_get_hash_for_file ("${CALLING_FILE}" CALLING_FILE_HASH)

    if (EXISTS "${HASH_FILE}")

        file (READ "${HASH_FILE}" HASH_FILE_CONTENTS)

        if ("${HASH_FILE_CONTENTS}" STREQUAL "${CALLING_FILE_HASH}")

            set (SHOULD_WRITE FALSE)

        endif ()

    endif ()

    if (SHOULD_WRITE)

        file (WRITE "${HASH_FILE}" "${CALLING_FILE_HASH}")

    endif ()

    set (${SHOULD_WRITE_RETURN} ${SHOULD_WRITE} PARENT_SCOPE)

endfunction ()

# cmake_unit_write_if_newer
#
# Write contents as specified in ARGN to file specified in FILE
# if the CALLING_FILE is newer than FILE, or FILE does not exist.
#
# FILE: File to write to.
# CALLING_FILE: File to compare with.
function (cmake_unit_write_if_newer FILE CALLING_FILE)

    cmake_unit_should_write ("${FILE}" "${CALLING_FILE}" PERFORM_WRITE)

    if (PERFORM_WRITE)

        file (WRITE "${FILE}" ${ARGN})

    endif ()

endfunction ()

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
                # stop and add it to our ADD_CUSTOM_COMMAND_PRINT_STRINGS list
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

    # Now loop over ADD_CUSTOM_COMMAND_PRINT_STRINGS to build the
    # ADD_CUSTOM_COMMAND_APPEND_ARGUMENTS list
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

    if (NOT EXTENSION)

        message (FATAL_ERROR "Need to specify an extension in order to get "
                             "correct source file contents for this file. The "
                             "current name is ${GET_CREATED_NAME}.")

    endif ()

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
                  "int ${FUNCTION} ()"
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
                           "GENERATING_FILE"
                           "CONTENTS"
                           ${ARGN})

    string (REPLACE ";" "\n" CONTENTS "${WRITE_OUT_FILE_CONTENTS}")
    string (REPLACE "@SEMICOLON@" ";" CONTENTS "${CONTENTS}")

    set (SHOULD_WRITE TRUE)

    if (WRITE_OUT_FILE_GENERATING_FILE)

        cmake_unit_should_write ("${CMAKE_CURRENT_SOURCE_DIR}/${NAME}"
                                 "${WRITE_OUT_FILE_GENERATING_FILE}"
                                 SHOULD_WRITE)

    endif ()

    if (SHOULD_WRITE)

        file (WRITE "${CMAKE_CURRENT_SOURCE_DIR}/${NAME}"
              "${CONTENTS}\n")

    endif ()

endfunction ()

# cmake_unit_create_source_file_before_build
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
# [Optional] GENERATING_FILE: File which is responsible for generating the
#                             specified file, used to avoid redundant writes
#                             into the source directory.
function (cmake_unit_create_source_file_before_build)

    set (CREATE_BEFORE_BUILD_OPTION_ARGS
         ${_CMAKE_UNIT_SOURCE_FILE_OPTION_ARGS})
    set (CREATE_BEFORE_BUILD_SINGLEVAR_ARGS
         GENERATING_FILE
         ${_CMAKE_UNIT_SOURCE_FILE_SINGLEVAR_ARGS})
    set (CREATE_BEFORE_BUILD_MULTIVAR_ARGS
         ${_CMAKE_UNIT_SOURCE_FILE_MULTIVAR_ARGS})

    cmake_parse_arguments (CREATE_BEFORE_BUILD
                           "${CREATE_BEFORE_BUILD_OPTION_ARGS}"
                           "${CREATE_BEFORE_BUILD_SINGLEVAR_ARGS}"
                           "${CREATE_BEFORE_BUILD_MULTIVAR_ARGS}"
                           ${ARGN})

    set (GENERATING_FILE "${CREATE_BEFORE_BUILD_GENERATING_FILE}")
    cmake_forward_arguments (CREATE_BEFORE_BUILD GET_CREATED_ARGUMENTS
                             OPTION_ARGS
                             ${_CMAKE_UNIT_SOURCE_FILE_OPTION_ARGS}
                             SINGLEVAR_ARGS
                             ${_CMAKE_UNIT_SOURCE_FILE_SINGLEVAR_ARGS}
                             MULTIVAR_ARGS
                             ${_CMAKE_UNIT_SOURCE_FILE_MULTIVAR_ARGS})

    _cmake_unit_get_created_source_file_contents (CONTENTS NAME
                                                  ${GET_CREATED_ARGUMENTS})
    _cmake_unit_write_out_file_without_semicolons ("${NAME}"
                                                   CONTENTS ${CONTENTS}
                                                   GENERATING_FILE
                                                   "${GENERATING_FILE}")

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

    string (RANDOM SALT)
    _cmake_unit_write_out_file_without_semicolons ("${NAME}${SALT}"
                                                   CONTENTS ${CONTENTS})
    file (RENAME "${CMAKE_CURRENT_SOURCE_DIR}/${NAME}${SALT}"
                 "${CMAKE_CURRENT_BINARY_DIR}/${NAME}${SALT}")

    set (WRITE_SOURCE_FILE_SCRIPT
         "${CMAKE_CURRENT_BINARY_DIR}/Write${NAME}${SALT}.cmake")
    file (WRITE "${WRITE_SOURCE_FILE_SCRIPT}"
          "file (READ \"${CMAKE_CURRENT_BINARY_DIR}/${NAME}${SALT}\"\n"
          "      GENERATED_FILE_CONTENTS)\n"
          "file (WRITE \"${CMAKE_CURRENT_BINARY_DIR}/${NAME}\"\n"
          "      \"\${GENERATED_FILE_CONTENTS}\")\n")


    # Generate target name, convert temporary location to lowercase.
    string (REPLACE ";" "" TARGET_NAME_WITH_UPPER_CHARACTERS
            "${TMP_LOCATION}")
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

    set (SOURCE_LOCATION "${NAME}.cpp")
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

    set (CREATE_SIMPLE_EXECUTABLE_SINGLEVAR_ARGS FUNCTIONS GENERATING_FILE)
    cmake_parse_arguments (CREATE_SIMPLE_EXECUTABLE
                           ""
                           "${CREATE_SIMPLE_EXECUTABLE_SINGLEVAR_ARGS}"
                           ""
                           ${ARGN})

    # Ensure there is always a main in our source file
    set (CREATE_SOURCE_FUNCTIONS ${CREATE_SIMPLE_EXECUTABLE_FUNCTIONS} main)
    cmake_forward_arguments (CREATE_SIMPLE_EXECUTABLE GENERATE_FWD
                             SINGLEVAR_ARGS GENERATING_FILE)
    _cmake_unit_create_source_for_simple_target (${NAME} LOCATION
                                                 ${ARGN}
                                                 FUNCTIONS
                                                 ${CREATE_SOURCE_FUNCTIONS}
                                                 ${GENERATING_FWD})
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

    set (CREATE_SIMPLE_LIBRARY_OPTION_ARGS
         ${_CMAKE_UNIT_SOURCE_FILE_OPTION_ARGS})
    set (CREATE_SIMPLE_LIBRARY_SINGLEVAR_ARGS
         ${_CMAKE_UNIT_SOURCE_FILE_SINGLEVAR_ARGS})
    set (CREATE_SIMPLE_LIBRARY_MULTIVAR_ARGS
         ${_CMAKE_UNIT_SOURCE_FILE_MULTIVAR_ARGS})

    cmake_parse_arguments (CREATE_SIMPLE_LIBRARY
                           "${CREATE_SIMPLE_LIBRARY_OPTION_ARGS}"
                           "${CREATE_SIMPLE_LIBRARY_SINGLEVAR_ARGS}"
                           "${CREATE_SIMPLE_LIBRARY_MULTIVAR_ARGS}"
                           ${ARGN})

    # Check if there are any functions - if there are not, then we will
    # need to add an internal one to ensure that linking the library
    # is successful. If no functions are added, then certain compilers
    # will not write a file containing our object code.
    if (NOT CREATE_SIMPLE_LIBRARY_FUNCTIONS)

        set (CREATE_SIMPLE_LIBRARY_FUNCTIONS internal_cmake_unit_function__)

    endif ()

    cmake_forward_arguments (CREATE_SIMPLE_LIBRARY CREATE_FWD
                             OPTION_ARGS
                             ${CREATE_SIMPLE_LIBRARY_OPTION_ARGS}
                             SINGLEVAR_ARGS
                             ${CREATE_SIMPLE_LIBRARY_SINGLEVAR_ARGS}
                             MULTIVAR_ARGS
                             ${CREATE_SIMPLE_LIBRARY_MULTIVAR_ARGS})
    _cmake_unit_create_source_for_simple_target (${NAME} LOCATION
                                                 ${CREATE_FWD}
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
# This function should always be used where a binary or library needs to
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

function (_cmake_unit_slice_list LIST
                                 SLICE_BEGIN
                                 SLICE_END
                                 RESULT_LIST_VARIABLE)

    set (RESULT_LIST)

    list (LENGTH ${LIST} LIST_LENGTH)
    math (EXPR LIST_LENGTH "${LIST_LENGTH} - 1")

    if (SLICE_END GREATER LIST_LENGTH)

        set (SLICE_END "${LIST_LENGTH}")

    endif ()

    if (NOT SLICE_END LESS 0)

        foreach (INDEX RANGE ${SLICE_BEGIN} ${SLICE_END})

            list (GET ${LIST} ${INDEX} _VALUE)
            list (APPEND RESULT_LIST ${_VALUE})

        endforeach ()

    endif ()

    set (${RESULT_LIST_VARIABLE} ${RESULT_LIST} PARENT_SCOPE)

endfunction ()

function (_cmake_unit_extract_result_from_argn)

    cmake_parse_arguments (EXTRACT_RESULTS
                           ""
                           "SLICE_FROM;RESULT_VAR;ARGN_VAR"
                           "ARGN"
                           ${ARGN})

    list (GET EXTRACT_RESULTS_ARGN -1 RESULT_VARIABLE)
    list (LENGTH EXTRACT_RESULTS_ARGN ARGN_LENGTH)
    math (EXPR ARGN_LENGTH "${ARGN_LENGTH} - 2")

    if (NOT DEFINED EXTRACT_RESULTS_SLICE_FROM)

        set (EXTRACT_RESULTS_SLICE_FROM "0")

    endif ()

    _cmake_unit_slice_list (EXTRACT_RESULTS_ARGN
                            "${EXTRACT_RESULTS_SLICE_FROM}"
                            "${ARGN_LENGTH}"
                            REMAINING_ARGN)

    set (${EXTRACT_RESULTS_RESULT_VAR} ${RESULT_VARIABLE} PARENT_SCOPE)
    set (${EXTRACT_RESULTS_ARGN_VAR} ${REMAINING_ARGN} PARENT_SCOPE)

endfunction ()

# cmake_unit_register_matcher_namespace
#
# Tell cmake-unit about a namespace that matchers live in. If you define
# a function namespace_matcher and register the namespace "namespace", the
# matcher "matcher" can be used with cmake_unit_assert_that. Namespaces
# registered later take priority over namespaces registered earlier.
#
# NAMESPACE: The namespace to register.
function (cmake_unit_register_matcher_namespace NAMESPACE)

    set_property (GLOBAL APPEND PROPERTY "_CMAKE_UNIT_MATCHER_NAMEPSPACE"
                  "${NAMESPACE}")

endfunction ()

cmake_unit_register_matcher_namespace (cmake_unit)

# cmake_unit_eval_matcher
#
# Evaluates MATCHER against VARIABLE with ARGN, returns result in
# last variable specified. Register additional matcher namespaces
# with cmake_unit_register_matcher_namespace. By default, the
# cmake_unit namespace is available.
#
# VARIABLE: Name of variable to test.
# MATCHER: Name of matcher to run against VARIABLE.
function (cmake_unit_eval_matcher VARIABLE MATCHER)

    _cmake_unit_extract_result_from_argn (RESULT_VAR RESULT_VARIABLE
                                          ARGN_VAR REMAINING_ARGN
                                          ARGN ${ARGN})

    get_property (MATCHER_NAMESPACES GLOBAL PROPERTY
                  "_CMAKE_UNIT_MATCHER_NAMEPSPACE")
    list (REVERSE MATCHER_NAMESPACES)

    foreach (NAMESPACE ${MATCHER_NAMESPACES})

        if (COMMAND "${NAMESPACE}_${MATCHER}")

            cmake_call_function ("${NAMESPACE}_${MATCHER}"
                                 "${VARIABLE}"
                                 ${REMAINING_ARGN}
                                 RESULT)
            break ()

        endif ()

    endforeach ()

    set (${RESULT_VARIABLE} "${RESULT}" PARENT_SCOPE)

endfunction ()

# cmake_unit_assert_that
#
# Runs ASSERTION_FUNCTION against ${VARIABLE_NAME} with ARGN. If it fails,
# an error is reported, otherwise silently succeeds.
#
# VARIABLE: Name of variable to test.
# ASSERTION_FUNCTION: Function to run against argument. Note that the
#                     cmake_unit prefix gets added automatically, so you
#                     only need to pass the name without that prefix. For
#                     example cmake_unit_assert_that (VARIABLE target_exists)
function (cmake_unit_assert_that VARIABLE ASSERTION_FUNCTION)

    cmake_unit_eval_matcher ("${VARIABLE}"
                             "${ASSERTION_FUNCTION}"
                             ${ARGN}
                             RESULT)

    if (NOT RESULT STREQUAL "TRUE")

        message (SEND_ERROR
                 "Expected ${RESULT}, instead ${VARIABLE} was ${${VARIABLE}}")

    endif ()

endfunction ()

# cmake_unit_not
#
# Runs ASSERTION_FUNCTION and fails if VARIABLE_NAME matches the function.
# This should be used in combination with cmake_unit_assert_that, for instance,
# cmake_unit_assert_that (VARIABLE_NAME not target_exists)
function (cmake_unit_not)

    list (GET CALLER_ARGN 0 VARIABLE_NAME)
    list (GET CALLER_ARGN 1 ASSERTION_FUNCTION)

    _cmake_unit_extract_result_from_argn (SLICE_FROM 2
                                          RESULT_VAR RESULT_VARIABLE
                                          ARGN_VAR REMAINING_ARGN
                                          ARGN ${CALLER_ARGN})

    cmake_unit_eval_matcher ("${VARIABLE_NAME}"
                             ${ASSERTION_FUNCTION}
                             ${REMAINING_ARGN}
                             RESULT)

    set (${RESULT_VARIABLE}
         PARENT_SCOPE)

    if (NOT RESULT STREQUAL "TRUE")

        set (${RESULT_VARIABLE} "TRUE" PARENT_SCOPE)

    endif ()

endfunction ()

# cmake_unit_is_true
#
# Matches if the variable provided is either TRUE or ON.
function (cmake_unit_is_true)

    list (GET CALLER_ARGN 0 VARIABLE)
    list (GET CALLER_ARGN 1 RESULT_VARIABLE)

    set (${RESULT_VARIABLE} "${VARIABLE} to be true" PARENT_SCOPE)

    if ("${${VARIABLE}}"
        STREQUAL
        "TRUE"
        OR
        "${${VARIABLE}}"
        STREQUAL
        "ON")

        set (${RESULT_VARIABLE} TRUE PARENT_SCOPE)

    endif ()

endfunction ()

# cmake_unit_is_false
#
# Matches if the variable provided is boolean false.
function (cmake_unit_is_false)

    list (GET CALLER_ARGN 0 VARIABLE)
    list (GET CALLER_ARGN 1 RESULT_VARIABLE)

    set (${RESULT_VARIABLE} "${VARIABLE} to be false" PARENT_SCOPE)

    if (NOT ${${VARIABLE}})

        set (${RESULT_VARIABLE} TRUE PARENT_SCOPE)

    endif ()

endfunction ()

# cmake_unit_target_exists
#
# Matches if the target name provided is a registered target. That is,
# the matcher will be satisfied if if (TARGET target) is taken.
function (cmake_unit_target_exists)

    list (GET CALLER_ARGN 0 TARGET_NAME)
    list (GET CALLER_ARGN 1 RESULT_VARIABLE)

    set (${RESULT_VARIABLE} "${TARGET_NAME} to be a target" PARENT_SCOPE)

    if (TARGET ${TARGET_NAME})

        set (${RESULT_VARIABLE} TRUE PARENT_SCOPE)

    endif ()

endfunction ()

# cmake_unit_variable_contains
#
# Matches if the value of the variable name provided contains the substring
# provided when the value is converted to a string.
function (cmake_unit_variable_contains)

    list (GET CALLER_ARGN 0 VARIABLE)
    list (GET CALLER_ARGN 1 SUBSTRING)
    list (GET CALLER_ARGN 2 RESULT_VARIABLE)

    set (${RESULT_VARIABLE}
         "substring ${SUBSTRING} to be found in ${VARIABLE} (${${VARIABLE}})"
         PARENT_SCOPE)

    string (FIND "${${VARIABLE}}" ${SUBSTRING} POSITION)

    if (NOT POSITION EQUAL -1)

        set (${RESULT_VARIABLE} TRUE PARENT_SCOPE)

    endif ()

endfunction ()

# cmake_unit_compare_as
#
# Matches if the variable satisfies the if-expression,
# "if (VARIABLE ${TYPE}${COMPARATOR} ${VALUE})". For instance, if you wished
# to check for string-equality, you would provide STRING EQUAL value and
# the matcher would be satisfied if the if-expression (VARIABLE STREQUAL value)
# was satisfied.
#
# The variable TYPE must be provided as the checks differ subtly between
# variable types. Valid types are:
#
#  STRING
#  INTEGER
#  BOOL
#
# A fatal error will be thrown when passing an unrecognized
# type. A non-fatal error will be thrown if the COMPARATOR
# operation fails between VARIABLE and VALUE.
function (cmake_unit_compare_as)

    list (GET CALLER_ARGN 0 VARIABLE)
    list (GET CALLER_ARGN 1 TYPE)
    list (GET CALLER_ARGN 2 COMPARATOR)
    list (GET CALLER_ARGN 3 VALUE)
    list (GET CALLER_ARGN 4 RESULT_VARIABLE)

    set (${RESULT_VARIABLE}
         "${VARIABLE} (${${VARIABLE}}) to be ${TYPE} ${COMPARATOR} ${VALUE}"
         PARENT_SCOPE)

    # Prevent automatic deference of arguments which are intended to be
    # values and not variables
    set (STRING_TYPE "STRING")
    set (INTEGER_TYPE "INTEGER")
    set (BOOL_TYPE "BOOL")

    if (TYPE MATCHES "${STRING_TYPE}")

        if (COMPARATOR MATCHES "EMPTY")

            string (LENGTH "${${VARIABLE}}" STRING_LENGTH)

            if (STRING_LENGTH EQUAL 0)

                set ("${RESULT_VARIABLE}" TRUE PARENT_SCOPE)

            endif ()

        elseif ("${${VARIABLE}}" STR${COMPARATOR} "${VALUE}")

            set (${RESULT_VARIABLE} TRUE PARENT_SCOPE)

        endif ()

    elseif (TYPE MATCHES "${INTEGER_TYPE}")

        if ("${${VARIABLE}}" ${COMPARATOR} "${VALUE}")

            set (${RESULT_VARIABLE} TRUE PARENT_SCOPE)

        endif ()

    elseif (TYPE MATCHES "${BOOL_TYPE}")

        if (COMPARATOR STREQUAL "EQUAL")

            if (${${VARIABLE}} AND VALUE)

                set (${RESULT_VARIABLE} TRUE PARENT_SCOPE)

            elseif (NOT ${${VARIABLE}} AND NOT VALUE)

                set (${RESULT_VARIABLE} TRUE PARENT_SCOPE)

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

# cmake_unit_matches_regex
#
# Matches if the value of the variable, after being converted to a string
# matches the provided regex.
function (cmake_unit_matches_regex)

    list (GET CALLER_ARGN 0 VARIABLE)
    list (GET CALLER_ARGN 1 REGEX)
    list (GET CALLER_ARGN 2 RESULT_VARIABLE)

    set (${RESULT_VARIABLE} "${VARIABLE} (${${VARIABLE}}) to match ${REGEX}"
         PARENT_SCOPE)

    if ("${${VARIABLE}}" MATCHES "${REGEX}")

        set (${RESULT_VARIABLE} TRUE PARENT_SCOPE)

    endif ()

endfunction ()

# cmake_unit_is_defined
#
# Matches if the variable is defined, that is, if the variable has
# been set at some point and the if-expression if (DEFINED VARIABLE) would
# pass.
function (cmake_unit_is_defined)

    list (GET CALLER_ARGN 0 VARIABLE)
    list (GET CALLER_ARGN 1 RESULT_VARIABLE)

    set (${RESULT_VARIABLE} "${VARIABLE} to be defined" PARENT_SCOPE)

    if (DEFINED "${VARIABLE}")

        set (${RESULT_VARIABLE} TRUE PARENT_SCOPE)

    endif ()

endfunction ()

# cmake_unit_executes_with_success
#
# Matches if the provided command, which should be a single space-separated
# string of an executable and its arguments, executes with success.
function (cmake_unit_executes_with_success)

    list (GET CALLER_ARGN 0 COMMAND)
    list (GET CALLER_ARGN 1 RESULT_VARIABLE)

    execute_process (COMMAND "${COMMAND}"
                     RESULT_VARIABLE RESULT
                     OUTPUT_VARIABLE OUTPUT
                     ERROR_VARIABLE ERROR)

    set (${RESULT_VARIABLE}
         "to exit with success (exited with: ${RESULT}) because:\n${ERROR}"
         PARENT_SCOPE)

    if (RESULT EQUAL 0)

        set (${RESULT_VARIABLE} TRUE PARENT_SCOPE)

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

function (_cmake_unit_print_all_target_libraries_to TARGET RESULT_VARIABLE)

    get_property (INTERFACE_LIBRARIES
                  TARGET ${TARGET}
                  PROPERTY INTERFACE_LINK_LIBRARIES)
    get_property (LINK_LIBRARIES
                  TARGET ${TARGET}
                  PROPERTY LINK_LIBRARIES)

    foreach (LIB ${INTERFACE_LIBRARIES})

        set (${RESULT_VARIABLE}
             PARENT_SCOPE)

    endforeach ()

    foreach (LIB ${LINK_LIBRARIES})

        set (${RESULT_VARIABLE}
             PARENT_SCOPE)

    endforeach ()

endfunction ()

# cmake_unit_executes_with_success
#
# Matches if the target provided is linked to a library which matches
# the name LIBRARY. Note that this function does regex matching under the hood,
# matching a whole line which contains anything matching LIBRARY.
function (cmake_unit_is_linked_to)

    list (GET CALLER_ARGN 0 TARGET_NAME)
    list (GET CALLER_ARGN 1 LIBRARY)
    list (GET CALLER_ARGN 2 RESULT_VARIABLE)

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

    _cmake_unit_print_all_target_libraries_to ("${TARGET_NAME}" ALL_LIBS)

    set (${RESULT_VARIABLE}
         "${LIBRARY} to be a link-library to ${TARGET_NAME}\n${ALL_LIBS}"
         PARENT_SCOPE)

    if (FOUND_IN_INTERFACE OR FOUND_IN_LINK)

        set (${RESULT_VARIABLE} TRUE PARENT_SCOPE)

    endif ()

endfunction ()

# cmake_unit_item_has_property_with_value
#
# Matches if item, which could be a directory, target or anything which
# can have properties, has a property with the type PROPERTY_TYPE
# which satisfies the expression
# if (VARIABLE ${PROPERTY_TYPE}${COMPARATOR} ${VALUE}).
#
# If you need to match a property on the GLOBAL scope, the value of
# the ITEM variable does not matter, but by convention, GLOBAL is used.
function (cmake_unit_item_has_property_with_value)

    list (GET CALLER_ARGN 0 ITEM)
    list (GET CALLER_ARGN 1 ITEM_TYPE)
    list (GET CALLER_ARGN 2 PROPERTY)
    list (GET CALLER_ARGN 3 PROPERTY_TYPE)
    list (GET CALLER_ARGN 4 COMPARATOR)
    list (GET CALLER_ARGN 5 VALUE)
    list (GET CALLER_ARGN 6 RESULT_VARIABLE)

    set (${RESULT_VARIABLE}
         "${ITEM_TYPE} ${ITEM} to have property ${PROPERTY} "
         " of type ${PROPERTY_TYPE} with value ${VALUE}"
         PARENT_SCOPE)

    # GLOBAL scope is special, in that case we don't really
    # have an item, so we need to get rid of it.
    if (ITEM_TYPE STREQUAL "GLOBAL")

        set (ITEM)

    endif ()

    get_property (_PROPERTY_VALUE ${ITEM_TYPE} ${ITEM}
                  PROPERTY ${PROPERTY})

    cmake_unit_eval_matcher (_PROPERTY_VALUE
                             compare_as
                             ${PROPERTY_TYPE}
                             ${COMPARATOR}
                             "${VALUE}"
                             RESULT)

    if (RESULT STREQUAL "TRUE")

        set (${RESULT_VARIABLE} "TRUE" PARENT_SCOPE)

    endif ()

endfunction ()

# cmake_unit_list_contains_value
#
# Matches if the provided list contains a value satisfying the if-expression
# if (${LIST_VALUE} ${TYPE}${COMPARATOR} ${VALUE}).
function (cmake_unit_list_contains_value)

    list (GET CALLER_ARGN 0 LIST_VARIABLE)
    list (GET CALLER_ARGN 1 TYPE)
    list (GET CALLER_ARGN 2 COMPARATOR)
    list (GET CALLER_ARGN 3 VALUE)
    list (GET CALLER_ARGN 4 RESULT_VARIABLE)

    set (${RESULT_VARIABLE}
         "${LIST_VARIABLE} contains a value ${COMPARATOR} ${VALUE}"
         PARENT_SCOPE)

    foreach (LIST_VALUE ${${LIST_VARIABLE}})

        set (_CHILD_VALUE ${LIST_VALUE})
        cmake_unit_eval_matcher (_CHILD_VALUE
                                 compare_as
                                 ${TYPE}
                                 ${COMPARATOR}
                                 "${VALUE}"
                                 RESULT)

        if (RESULT STREQUAL "TRUE")

            set (${RESULT_VARIABLE} TRUE PARENT_SCOPE)

        endif ()

    endforeach ()

endfunction ()

# cmake_unit_item_has_property_containing_value
#
# Like cmake_unit_list_contains_value, but matches on the value
# of a property, instead of a variable.
function (cmake_unit_item_has_property_containing_value)

    list (GET CALLER_ARGN 0 ITEM)
    list (GET CALLER_ARGN 1 ITEM_TYPE)
    list (GET CALLER_ARGN 2 PROPERTY)
    list (GET CALLER_ARGN 3 PROPERTY_TYPE)
    list (GET CALLER_ARGN 4 COMPARATOR)
    list (GET CALLER_ARGN 5 VALUE)
    list (GET CALLER_ARGN 6 RESULT_VARIABLE)

    set (${RESULT_VARIABLE}
         "${ITEM_TYPE} ${ITEM} to have property ${PROPERTY_TYPE} ${PROPERTY} "
         "containing value ${VALUE}"
         PARENT_SCOPE)

    # GLOBAL scope is special, in that case we don't really
    # have an item, so we need to get rid of it.
    if (ITEM_TYPE STREQUAL "GLOBAL")

        set (ITEM)

    endif ()

    get_property (_PROPERTY_VALUES ${ITEM_TYPE} ${ITEM}
                  PROPERTY ${PROPERTY})

    cmake_unit_eval_matcher (_PROPERTY_VALUES
                             list_contains_value
                             ${PROPERTY_TYPE}
                             ${COMPARATOR}
                             "${VALUE}"
                             RESULT)

    if (RESULT STREQUAL "TRUE")

        set (${RESULT_VARIABLE} TRUE PARENT_SCOPE)

    endif ()

endfunction ()

# cmake_unit_exists_as_file
#
# Matches if the file name provided exists on the filesystem.
function (cmake_unit_exists_as_file)

    list (GET CALLER_ARGN 0 FILE)
    list (GET CALLER_ARGN 1 RESULT_VARIABLE)

    set (${RESULT_VARIABLE} "(file) to exist" PARENT_SCOPE)

    if (EXISTS "${FILE}")

        set (${RESULT_VARIABLE} TRUE PARENT_SCOPE)

    endif ()

endfunction ()

# cmake_unit_file_contents
#
# Matches if the contents of the provided file match the second provided
# matcher and its arguments.
#
# A common pattern is to combine this with the any_line matches_regex
# matcher, to read log files for certain lines.
function (cmake_unit_file_contents)

    list (GET CALLER_ARGN 0 FILE)
    list (GET CALLER_ARGN 1 MATCHER)

    _cmake_unit_extract_result_from_argn (SLICE_FROM 2
                                          RESULT_VAR RESULT_VARIABLE
                                          ARGN_VAR REMAINING_ARGN
                                          ARGN ${CALLER_ARGN})

    cmake_spacify_list (REMAINING_ARGN_SPACIFIED
                        LIST ${REMAINING_ARGN}
                        NO_QUOTES)
    set (${RESULT_VARIABLE}
         "contents of ${FILE} to match ${MATCHER} ${REMAINING_ARGN_SPACIFIED}"
         PARENT_SCOPE)

    file (READ "${FILE}" FILE_CONTENTS)

    cmake_unit_eval_matcher (FILE_CONTENTS
                             ${MATCHER}
                             ${REMAINING_ARGN}
                             RESULT)

    if (RESULT STREQUAL "TRUE")

        set (${RESULT_VARIABLE} TRUE PARENT_SCOPE)

    endif ()

endfunction ()

# cmake_unit_any_line
#
# Matches if any line of the provided string matches the provided matcher.
#
# A common pattern is to combine this with the file_contents and matches_regex
# matchers, to read log files for certain lines.
function (cmake_unit_any_line)

    list (GET CALLER_ARGN 0 CONTENTS_VARIABLE)
    list (GET CALLER_ARGN 1 MATCHER)

    _cmake_unit_extract_result_from_argn (SLICE_FROM 2
                                          RESULT_VAR RESULT_VARIABLE
                                          ARGN_VAR REMAINING_ARGN
                                          ARGN ${CALLER_ARGN})

    cmake_spacify_list (REMAINING_ARGN_SPACIFIED
                        LIST ${REMAINING_ARGN}
                        NO_QUOTES)
    set (${RESULT_VARIABLE}
         "any line of contents to match ${MATCHER} ${REMAINING_ARGN_SPACIFIED}"
         PARENT_SCOPE)

    # Split the string into individual lines
    set (CONTENTS "${${CONTENTS_VARIABLE}}")
    string (REGEX REPLACE ";" "\\\;" CONTENTS "${CONTENTS}")
    string (REGEX REPLACE "\n" ";" CONTENTS "${CONTENTS}")

    # Now loop over each line and check if there's a match against PATTERN
    foreach (LINE ${CONTENTS})

        set (_LINE_VARIABLE "${LINE}")
        cmake_unit_eval_matcher (_LINE_VARIABLE
                                 ${MATCHER}
                                 ${REMAINING_ARGN}
                                 RESULT)

        if (RESULT STREQUAL "TRUE")

            set (${RESULT_VARIABLE} TRUE PARENT_SCOPE)
            break ()

        endif ()

    endforeach ()

endfunction ()
