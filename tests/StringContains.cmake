# /tests/StringContains.cmake
# Check the _string_contains matcher.

include (${CMAKE_UNIT_DIRECTORY}/CMakeUnit.cmake)

set (SUBSTRING "substring")
set (MAIN_STRING "main_${SUBSTRING}_string")

_string_contains (${MAIN_STRING} ${SUBSTRING} RESULT)
_string_contains (${MAIN_STRING} "other" NOT_RESULT)

assert_true (${RESULT})
assert_false (${NOT_RESULT})