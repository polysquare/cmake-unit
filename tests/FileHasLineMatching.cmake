# /tests/FileHasLineMatching.cmake
# Check the _file_has_line_matching matcher.

include (CMakeUnit)

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

set (FILE_WITH_FOO ${CMAKE_CURRENT_BINARY_DIR}/FileWithFoo)
set (FILE_WITH_BOTH_INDEPENDENTLY
     ${CMAKE_CURRENT_BINARY_DIR}/FileWithBothIndependently)
set (FILE_WITH_BOTH ${CMAKE_CURRENT_BINARY_DIR}/FileWithBoth)
set (FILE_WITH_ALL ${CMAKE_CURRENT_BINARY_DIR}/FileWithAll)

file (WRITE ${FILE_WITH_FOO} ${MAIN_STRING_WITH_FOO})
file (WRITE ${FILE_WITH_BOTH_INDEPENDENTLY}
      ${MAIN_STRING_WITH_BOTH_INDEPENDENTLY})
file (WRITE ${FILE_WITH_BOTH} ${MAIN_STRING_WITH_BOTH})
file (WRITE ${FILE_WITH_ALL} ${MAIN_STRING_WITH_ALL})

_file_has_line_matching (${FILE_WITH_FOO}
                         ${MATCH_FOO_LINE}
                         MATCH_FOO_IN_FOO)
_file_has_line_matching (${FILE_WITH_FOO}
                         ${MATCH_FOO_SUBSTRING_LINE}
                         NO_MATCH_SUBSTRING_IN_FOO)
_file_has_line_matching (${FILE_WITH_FOO}
                          ${MATCH_FOO_SUBSTRING_LINE}
                          NO_MATCH_BOTH_IN_FOO)

_file_has_line_matching (${FILE_WITH_BOTH_INDEPENDENTLY}
                          ${MATCH_FOO_LINE}
                         MATCH_FOO_IN_BOTH_INDEPENDENTLY)
_file_has_line_matching (${FILE_WITH_BOTH_INDEPENDENTLY}
                          ${MATCH_SUBSTRING_LINE}
                         MATCH_SUBSTRING_IN_BOTH_INDEPENDENTLY)
_file_has_line_matching (${FILE_WITH_BOTH_INDEPENDENTLY}
                          ${MATCH_FOO_SUBSTRING_LINE}
                         NO_MATCH_BOTH_IN_BOTH_INDEPENDENTLY)

_file_has_line_matching (${FILE_WITH_BOTH}
                         ${MATCH_FOO_LINE}
                         MATCH_FOO_IN_BOTH)
_file_has_line_matching (${FILE_WITH_BOTH}
                         ${MATCH_SUBSTRING_LINE}
                         MATCH_SUBSTRING_IN_BOTH)
_file_has_line_matching (${FILE_WITH_BOTH}
                         ${MATCH_FOO_SUBSTRING_LINE}
                         MATCH_BOTH_IN_BOTH)

_file_has_line_matching (${FILE_WITH_ALL}
                         ${MATCH_FOO_LINE}
                         MATCH_FOO_IN_ALL)
_file_has_line_matching (${FILE_WITH_ALL}
                         ${MATCH_SUBSTRING_LINE}
                         MATCH_SUBSTRING_IN_ALL)
_file_has_line_matching (${FILE_WITH_ALL}
                         ${MATCH_FOO_SUBSTRING_LINE}
                         MATCH_BOTH_IN_ALL)

assert_true (${MATCH_FOO_IN_FOO})
assert_false (${NO_MATCH_SUBSTRING_IN_FOO})
assert_false (${NO_MATCH_BOTH_IN_FOO})

assert_true (${MATCH_FOO_IN_BOTH_INDEPENDENTLY})
assert_true (${MATCH_SUBSTRING_IN_BOTH_INDEPENDENTLY})
assert_false (${NO_MATCH_BOTH_IN_BOTH_INDEPENDENTLY})

assert_true (${MATCH_FOO_IN_BOTH})
assert_true (${MATCH_SUBSTRING_IN_BOTH})
assert_true (${MATCH_BOTH_IN_BOTH})

assert_true (${MATCH_FOO_IN_ALL})
assert_true (${MATCH_SUBSTRING_IN_ALL})
assert_true (${MATCH_BOTH_IN_ALL})