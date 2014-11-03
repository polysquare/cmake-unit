# /CMakeUnit.cmake
# A Simple CMake Unit Testing Framework - assertions
# library.
#
# This file provides some simple assertions for CMakeUnit
# which test scripts can use to verify certain details about
# what CMake knows about targets and properties set up.
#
# Most of the assertions take the form
#  - assert_invariant
#  - assert_not_invariant
#
# Usually the assertions would use the same determination
# as thier backend.
#
# The library isn't really designed for total flexibility
# but rather should be modified (and patches sent upstream!).
# This is due to a lack of polymorphism or support for
# first class functions in CMake .
#
# See LICENCE.md for Copyright information

include (CMakeParseArguments)

function (assert_true VARIABLE)

    if (NOT VARIABLE)

        message (SEND_ERROR
                 "Expected ${VARIABLE} to be true")

    endif (NOT VARIABLE)

endfunction ()

function (assert_false VARIABLE)

    if (VARIABLE)

        message (SEND_ERROR
                 "Expected ${VARIABLE} to be false")

    endif (VARIABLE)

endfunction ()

function (_target_exists TARGET_NAME RESULT_VARIABLE)

    set (${RESULT_VARIABLE} FALSE PARENT_SCOPE)

    if (TARGET ${TARGET_NAME})

        set (${RESULT_VARIABLE} TRUE PARENT_SCOPE)

    endif (TARGET ${TARGET_NAME})

endfunction (_target_exists)

# assert_target_exists
#
# Throws a non-fatal error if the target specified
# by TARGET_NAME is not a target known by CMake.
function (assert_target_exists TARGET_NAME)

    _target_exists (${TARGET_NAME} RESULT)

    if (NOT RESULT)

        message (SEND_ERROR
                 "Expected ${TARGET_NAME} to be a target")

    endif (NOT RESULT)

endfunction (assert_target_exists)


# assert_target_does_not_exist
#
# Throws a non-fatal error if the target specified
# by TARGET_NAME is a target known by CMake.
function (assert_target_does_not_exist TARGET_NAME)

    _target_exists (${TARGET_NAME} RESULT)

    if (RESULT)

        message (SEND_ERROR
                 "Expected ${TARGET_NAME} not to be a target")

    endif (RESULT)

endfunction (assert_target_does_not_exist)

function (_string_contains MAIN_STRING SUBSTRING RESULT_VARIABLE)

    set (${RESULT_VARIABLE} FALSE PARENT_SCOPE)

    string (FIND ${MAIN_STRING} ${SUBSTRING} POSITION)

    if (NOT POSITION EQUAL -1)

        set (${RESULT_VARIABLE} TRUE PARENT_SCOPE)

    endif (NOT POSITION EQUAL -1)

endfunction (_string_contains)

# assert_string_contains
#
# Throws a non-fatal error if the string SUBSTRING
# is not a substring of MAIN_STRING.
function (assert_string_contains MAIN_STRING SUBSTRING)

    _string_contains (${MAIN_STRING} ${SUBSTRING} RESULT)

    if (NOT RESULT)

        message (SEND_ERROR
                 "Substring ${SUBSTRING} not found in ${MAIN_STRING}")

    endif (NOT RESULT)

endfunction (assert_string_contains)

# assert_string_does_not_contain
#
# Throws a non-fatal error if the string SUBSTRING
# is a substring of MAIN_STRING.
function (assert_string_does_not_contain MAIN_STRING SUBSTRING)

    _string_contains (${MAIN_STRING} ${SUBSTRING} RESULT)

    if (RESULT)

        message (SEND_ERROR
                 "Substring ${SUBSTRING} not found in ${MAIN_STRING}")

    endif (RESULT)

endfunction (assert_string_does_not_contain)

function (_variable_is VARIABLE TYPE COMPARATOR VALUE RESULT_VARIABLE)

    set (${RESULT_VARIABLE} FALSE PARENT_SCOPE)

    if ("${TYPE}" MATCHES "STRING")

        if ("${${VARIABLE}}" STR${COMPARATOR} "${VALUE}")

            set (${RESULT_VARIABLE} TRUE PARENT_SCOPE)

        endif ("${${VARIABLE}}" STR${COMPARATOR} "${VALUE}")

    elseif ("${TYPE}" MATCHES "INTEGER" OR
            "${TYPE}" MATCHES "BOOL")

        if ("${${VARIABLE}}" ${COMPARATOR} ${VALUE})

            set (${RESULT_VARIABLE} TRUE PARENT_SCOPE)

        endif ("${${VARIABLE}}" ${COMPARATOR} ${VALUE})

    else ("${TYPE}" MATCHES "STRING")

        message (FATAL_ERROR
                 "Asked to match unknown type ${TYPE}")

    endif ("${TYPE}" MATCHES "STRING")

endfunction (_variable_is)

# assert_variable_is
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
function (assert_variable_is VARIABLE TYPE COMPARATOR VALUE)

    _variable_is (${VARIABLE} ${TYPE} ${COMPARATOR} "${VALUE}" RESULT)

    if (NOT RESULT)

        message (SEND_ERROR
                 "Expected type ${TYPE} with value ${VALUE}"
                 " but was ${${VARIABLE}}")

    endif (NOT RESULT)

endfunction (assert_variable_is)

# assert_variable_is_not
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
function (assert_variable_is_not VARIABLE TYPE COMPARATOR VALUE)

    _variable_is (${VARIABLE} ${TYPE} ${COMPARATOR} "${VALUE}" RESULT)

    if (RESULT)

        message (SEND_ERROR
                 "Expected type ${TYPE} with value ${VALUE}"
                 " but was ${${VARIABLE}}")

    endif (RESULT)

endfunction (assert_variable_is_not)

# assert_variable_matches_regex
#
# The variable VARIABLE will be coerced into a string
# matched against the REGEX provided. Throws a non-fatal
# error if VARIABLE does not match REGEX.
function (assert_variable_matches_regex VARIABLE REGEX)

    if (NOT ${VARIABLE} MATCHES ${REGEX})

        message (SEND_ERROR
                 "Expected ${VARIABLE} to match ${REGEX}")

    endif (NOT ${VARIABLE} MATCHES ${REGEX})

endfunction (assert_variable_matches_regex)

# assert_variable_does_not_match_regex
#
# The variable VARIABLE will be coerced into a string
# matched against the REGEX provided. Throws a non-fatal
# error if VARIABLE does matches REGEX.
function (assert_variable_does_not_match_regex VARIABLE REGEX)

    if (${VARIABLE} MATCHES ${REGEX})

        message (SEND_ERROR
                 "Expected ${VARIABLE} to not match ${REGEX}")

    endif (${VARIABLE} MATCHES ${REGEX})

endfunction (assert_variable_does_not_match_regex)

# assert_variable_is_defined
#
# Throws a non-fatal error if the variable specified by VARIABLE
# is not defined. Note that the variable name itself and not
# its value must be passed to this function.
function (assert_variable_is_defined VARIABLE)

    if (NOT DEFINED ${VARIABLE})

        message (SEND_ERROR
                 "${VARIABLE} is not defined")

    endif (NOT DEFINED ${VARIABLE})

endfunction (assert_variable_is_defined)

# assert_variable_is_not_defined
#
# Throws a non-fatal error if the variable specified by VARIABLE
# is defined. Note that the variable name itself and not
# its value must be passed to this function.
function (assert_variable_is_not_defined VARIABLE)

    if (DEFINED ${VARIABLE})

        message (SEND_ERROR
                 "${VARIABLE} is defined")

    endif (DEFINED ${VARIABLE})

endfunction (assert_variable_is_not_defined)

function (_command_executes_with_success RESULT_VARIABLE
                                         ERROR_VARIABLE
                                         CODE_VARIABLE)

    set (COMMAND_EXECUTES_WITH_SUCCESS_MULTIVAR_ARGS COMMAND)
    cmake_parse_arguments (COMMAND_EXECUTES_WITH_SUCCESS
                           ""
                           ""
                           "${COMMAND_EXECUTES_WITH_SUCCESS_MULTIVAR_ARGS}"
                           ${ARGN})

    set (${RESULT_VARIABLE} FALSE PARENT_SCOPE)

    execute_process (COMMAND
                     ${COMMAND_EXECUTES_WITH_SUCCESS_COMMAND}
                     RESULT_VARIABLE RESULT
                     ERROR_VARIABLE ERROR)

    if (RESULT EQUAL 0)

        set (${RESULT_VARIABLE} TRUE PARENT_SCOPE)

    endif (RESULT EQUAL 0)

    set (${ERROR_VARIABLE} ${ERROR} PARENT_SCOPE)
    set (${CODE_VARIABLE} ${RESULT} PARENT_SCOPE)

endfunction (_command_executes_with_success)

# assert_command_executes_with_success
#
# Throws a non-fatal error if the command and argument
# list specified by COMMAND does not execute with
# success. Note that the name of the variable containing
# the command and the argument list must be provided
# as opposed to the command and argument list itself.
#
# COMMAND: Command to execute
function (assert_command_executes_with_success)

    _command_executes_with_success (RESULT ERROR CODE ${ARGN})

    if (NOT RESULT)

        message (SEND_ERROR
                 "The command ${ARGN} failed with result "
                 " ${CODE} : ${ERROR}\n")

    endif (NOT RESULT)

endfunction (assert_command_executes_with_success)

# assert_command_does_not_execute_with_success
#
# Throws a non-fatal error if the command and argument
# list specified by COMMAND executes with
# success. Note that the name of the variable containing
# the command and the argument list must be provided
# as opposed to the command and argument list itself.
function (assert_command_does_not_execute_with_success)

    _command_executes_with_success (RESULT ERROR CODE ${ARGN})

    if (RESULT)

        message (SEND_ERROR
                 "The command ${ARGN} succeeded with result "
                 " ${RESULT}\n")

    endif (RESULT)

endfunction (assert_command_does_not_execute_with_success)

function (_lib_found_in_libraries LIBRARY RESULT_VARIABLE)

    set (LIB_FOUND_IN_LIBRARIES_MULTIVAR_ARGS LIBRARIES)

    cmake_parse_arguments (LIB_FOUND
                           ""
                           ""
                           "${LIB_FOUND_IN_LIBRARIES_MULTIVAR_ARGS}"
                           ${ARGN})

    foreach (_lib ${LIB_FOUND_LIBRARIES})

        if (_lib MATCHES "(^.*${LIBRARY}.*$)")

            set (${RESULT_VARIABLE} TRUE PARENT_SCOPE)

        endif (_lib MATCHES "(^.*${LIBRARY}.*$)")

    endforeach ()

endfunction (_lib_found_in_libraries)

function (_print_all_target_libraries TARGET)

    get_property (INTERFACE_LIBRARIES
                  TARGET ${TARGET}
                  PROPERTY INTERFACE_LINK_LIBRARIES)
    get_property (LINK_LIBRARIES
                  TARGET ${TARGET}
                  PROPERTY LINK_LIBRARIES)

    foreach (_lib ${INTERFACE_LIBRARIES})

        message (STATUS "Part of link interface: " ${_lib})

    endforeach (${_lib})

    foreach (_lib ${LINK_LIBRARIES})

        message (STATUS "Link library: " ${_lib})

    endforeach (${_lib})

endfunction (_print_all_target_libraries)

function (_target_is_linked_to TARGET_NAME
                               LIBRARY
                               RESULT_VARIABLE)

    get_property (INTERFACE_LIBS
                  TARGET ${TARGET_NAME}
                  PROPERTY INTERFACE_LINK_LIBRARIES)
    get_property (LINK_LIBS
                  TARGET ${TARGET_NAME}
                  PROPERTY LINK_LIBRARIES)

    _lib_found_in_libraries (${LIBRARY} FOUND_IN_INTERFACE
                             LIBRARIES ${INTERFACE_LIBS})
    _lib_found_in_libraries (${LIBRARY} FOUND_IN_LINK
                             LIBRARIES ${LINK_LIBS})

    if (FOUND_IN_INTERFACE OR FOUND_IN_LINK)

        set (${RESULT_VARIABLE} TRUE PARENT_SCOPE)

    else (FOUND_IN_INTERFACE OR FOUND_IN_LINK)

        set (${RESULT_VARIABLE} FALSE PARENT_SCOPE)

    endif (FOUND_IN_INTERFACE OR FOUND_IN_LINK)

endfunction (_target_is_linked_to)

# assert_target_is_linked_to
#
# Throws a non-fatal error if the target specified by
# TARGET_NAME is not linked to a library which matches
# the name LIBRARY. Note that this function does regex
# matching under the hood, matching a whole line which
# contains anything matching LIBRARY.
function (assert_target_is_linked_to TARGET_NAME LIBRARY)

    _target_is_linked_to (${TARGET_NAME} ${LIBRARY} RESULT LIBRARIES)

    if (NOT RESULT)

        message (SEND_ERROR
                 "Expected ${LIBRARY} to be a link-library to ${TARGET_NAME}")

        _print_all_target_libraries (${TARGET_NAME})

    endif (NOT RESULT)

endfunction (assert_target_is_linked_to)

# assert_target_is_not_linked_to
#
# Throws a non-fatal error if the target specified by
# TARGET_NAME is linked to a library which matches
# the name LIBRARY. Note that this function does regex
# matching under the hood, matching a whole line which
# contains anything matching LIBRARY.
function (assert_target_is_not_linked_to TARGET_NAME LIBRARY)

    _target_is_linked_to (${TARGET_NAME} ${LIBRARY} RESULT LIBRARIES)

    if (RESULT)

        message (SEND_ERROR
                 "Expected ${LIBRARY} not to be a link-library "
                 "to ${TARGET_NAME}")

        _print_all_target_libraries (${TARGET_NAME})

    endif (RESULT)

endfunction (assert_target_is_not_linked_to)

function (_item_has_property_with_value ITEM_TYPE
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

    endif (ITEM_TYPE STREQUAL "GLOBAL")

    get_property (_property_value
                  ${ITEM_TYPE} ${ITEM}
                  PROPERTY ${PROPERTY})

    _variable_is (_property_value
                  ${PROPERTY_TYPE}
                  ${COMPARATOR}
                  "${VALUE}"
                  RESULT)

    set (${RESULT_VARIABLE} ${RESULT} PARENT_SCOPE)

endfunction (_item_has_property_with_value)

# assert_has_property_with_value
#
# Throws a non-fatal error if the ITEM with ITEM_TYPE specified does not
# have a PROPERTY of PROPERTY_TYPE which satisfies COMPARATOR with
# the VALUE specified.
function (assert_has_property_with_value ITEM_TYPE
                                         ITEM
                                         PROPERTY
                                         PROPERTY_TYPE
                                         COMPARATOR
                                         VALUE)

    _item_has_property_with_value (${ITEM_TYPE}
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

    endif (NOT RESULT)

endfunction (assert_has_property_with_value)

# assert_does_not_have_property_with_value
#
# Throws a non-fatal error if the ITEM with ITEM_TYPE specified
# has a PROPERTY of PROPERTY_TYPE which satisfies COMPARATOR with
# the VALUE specified.
function (assert_does_not_have_property_with_value ITEM_TYPE
                                                   ITEM
                                                   PROPERTY
                                                   PROPERTY_TYPE
                                                   COMPARATOR
                                                   VALUE)


    _item_has_property_with_value (${ITEM_TYPE}
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

    endif (RESULT)

endfunction (assert_does_not_have_property_with_value)

function (_list_contains_value LIST_VARIABLE
                               TYPE
                               COMPARATOR
                               VALUE
                               RESULT_VARIABLE)

    set (${RESULT_VARIABLE} FALSE PARENT_SCOPE)

    foreach (LIST_VALUE ${${LIST_VARIABLE}})

        set (_child_value ${LIST_VALUE})
        _variable_is (_child_value
                      ${TYPE}
                      ${COMPARATOR}
                      "${VALUE}"
                      RESULT)

        if (RESULT)

            set (${RESULT_VARIABLE} TRUE PARENT_SCOPE)

        endif (RESULT)

    endforeach ()

endfunction (_list_contains_value)

# assert_list_contains_value
#
# Throws a non-fatal error if the list specified by LIST_VARIABLE
# does not contain a value which satisfies COMPARATOR with
# VALUE
function (assert_list_contains_value LIST_VARIABLE
                                     TYPE
                                     COMPARATOR
                                     VALUE)

    _list_contains_value (${LIST_VARIABLE}
                          ${TYPE}
                          ${COMPARATOR}
                          ${VALUE}
                          RESULT)

    if (NOT RESULT)

        message (SEND_ERROR "List ${LIST_VARIABLE} does not contain a value "
                            "${COMPARATOR} ${VALUE}")

    endif (NOT RESULT)

endfunction (assert_list_contains_value)

# assert_list_contains_value
#
# Throws a non-fatal error if the list specified by LIST_VARIABLE
# contains a value which satisfies COMPARATOR with VALUE
function (assert_list_does_not_contain_value LIST_VARIABLE
                                             TYPE
                                             COMPARATOR
                                             VALUE)

    _list_contains_value (${LIST_VARIABLE}
                          ${TYPE}
                          ${COMPARATOR}
                          ${VALUE}
                          RESULT)

    if (RESULT)

        message (SEND_ERROR "List ${LIST_VARIABLE} contains a value "
                            "${COMPARATOR} ${VALUE}")

    endif (RESULT)

endfunction (assert_list_does_not_contain_value)

function (_item_has_property_containing_value ITEM_TYPE
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

    endif (ITEM_TYPE STREQUAL "GLOBAL")

    get_property (_property_values
                  ${ITEM_TYPE} ${ITEM}
                  PROPERTY ${PROPERTY})

    _list_contains_value (_property_values
                          ${PROPERTY_TYPE}
                          ${COMPARATOR}
                          "${VALUE}"
                          RESULT)

    if (RESULT)

        set (${RESULT_VARIABLE} TRUE PARENT_SCOPE)

    endif (RESULT)

endfunction (_item_has_property_containing_value)

# assert_has_property_containing_value
#
# Throws a non-fatal error if the ITEM with ITEM_TYPE specified does not
# have a PROPERTY of PROPERTY_TYPE of which one of the items in the property
# value's list satisfies COMPARATOR
function (assert_has_property_containing_value ITEM_TYPE
                                               ITEM
                                               PROPERTY
                                               PROPERTY_TYPE
                                               COMPARATOR
                                               VALUE)

    _item_has_property_containing_value (${ITEM_TYPE}
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

    endif (NOT RESULT)

endfunction (assert_has_property_containing_value)

# assert_does_not_have_property_containing_value
#
# Throws a non-fatal error if the ITEM with ITEM_TYPE specified does not
# have a PROPERTY of PROPERTY_TYPE of which one of the items in the property
# value's list satisfies COMPARATOR
function (assert_does_not_have_property_containing_value ITEM_TYPE
                                                         ITEM
                                                         PROPERTY
                                                         PROPERTY_TYPE
                                                         COMPARATOR
                                                         VALUE)

    _item_has_property_containing_value (${ITEM_TYPE}
                                         ${ITEM}
                                         ${PROPERTY}
                                         ${PROPERTY_TYPE}
                                         ${COMPARATOR}
                                         ${VALUE}
                                         RESULT)

    if (RESULT)

        message (SEND_ERROR
                 "Expected ${ITEM_TYPE} ${ITEM} not to have property "
                 "${PROPERTY} of type ${PROPERTY_TYPE} containing "
                 "value ${VALUE}")

    endif (RESULT)

endfunction (assert_does_not_have_property_containing_value)

function (_file_exists FILE RESULT_VARIABLE)

    set (${RESULT_VARIABLE} TRUE PARENT_SCOPE)

    if (NOT EXISTS ${FILE})

        set (${RESULT_VARIABLE} FALSE PARENT_SCOPE)

    endif (NOT EXISTS ${FILE})

endfunction (_file_exists)

# assert_file_exists:
#
# Throws a non-fatal error if the file specified by FILE
# does not exist on the filesystem
function (assert_file_exists FILE)

    _file_exists (${FILE} RESULT)

    if (NOT RESULT)

        message (SEND_ERROR "The file ${FILE} does not exist")

    endif (NOT RESULT)

endfunction (assert_file_exists)

# assert_file_does_not_exist:
#
# Throws a non-fatal error if the file specified by FILE
# exists the filesystem
function (assert_file_does_not_exist FILE)

    _file_exists (${FILE} RESULT)

    if (RESULT)

        message (SEND_ERROR "The file ${FILE} does exist")

    endif (RESULT)

endfunction (assert_file_does_not_exist)

function (_file_contains_substring FILE SUBSTRING RESULT_VARIABLE)

    file (READ ${FILE} CONTENTS)

    _string_contains (${CONTENTS} ${SUBSTRING} RESULT)

    # PARENT_SCOPE only propogates up one level so we need to
    # propogate the result here too
    set (${RESULT_VARIABLE} ${RESULT} PARENT_SCOPE)

endfunction (_file_contains_substring)

# assert_file_contains:
#
# Throws a non-fatal error if the file specified by FILE
# does not contain the substring SUBSTRING
function (assert_file_contains FILE SUBSTRING)

    _file_contains_substring (${FILE} ${SUBSTRING} RESULT)

    if (NOT RESULT)

        message (SEND_ERROR "The file ${FILE} does not contain the string "
                 " ${SUBSTRING}")

    endif (NOT RESULT)

endfunction (assert_file_contains)

# assert_file_does_not_contain:
#
# Throws a non-fatal error if the file specified by FILE
# contains the substring SUBSTRING
function (assert_file_does_not_contain FILE SUBSTRING)

    _file_contains_substring (${FILE} ${SUBSTRING} RESULT)

    if (RESULT)

        message (SEND_ERROR "The file ${FILE} contains the string ${SUBSTRING}")

    endif (RESULT)

endfunction (assert_file_does_not_contain)

function (_file_has_line_matching FILE PATTERN RESULT_VARIABLE)

    set (${RESULT_VARIABLE} FALSE PARENT_SCOPE)

    file (READ ${FILE} CONTENTS)

    # Split the string into individual lines
    string (REGEX REPLACE ";" "\\\;" CONTENTS "${CONTENTS}")
    string (REGEX REPLACE "\n" ";" CONTENTS "${CONTENTS}")

    # Now loop over each line and check if there's a match against PATTERN
    foreach (LINE ${CONTENTS})

        if (LINE MATCHES ${PATTERN})

            set (${RESULT_VARIABLE} TRUE PARENT_SCOPE)
            break ()

        endif (LINE MATCHES ${PATTERN})

    endforeach ()

endfunction (_file_has_line_matching)

# assert_file_has_line_matching
#
# Throws a non-fatal error if the file specified by FILE
# does not have a line that matches PATTERN
function (assert_file_has_line_matching FILE PATTERN)

    _file_has_line_matching (${FILE} ${PATTERN} RESULT)

    if (NOT RESULT)

        message (SEND_ERROR "The file ${FILE} does not have "
                 "a line matching ${PATTERN}")

    endif (NOT RESULT)

endfunction ()

# assert_file_does_not_have_line_matching
#
# Throws a non-fatal error if the file specified by FILE
# has a line that matches PATTERN
function (assert_file_does_not_have_line_matching FILE PATTERN)

    _file_has_line_matching (${FILE} ${PATTERN} RESULT)

    if (RESULT)

        message (SEND_ERROR "The file ${FILE} has "
                 "a line matching ${PATTERN}")

    endif (RESULT)

endfunction ()
