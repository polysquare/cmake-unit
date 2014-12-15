# /tests/StringContains.cmake
#
# Check the _cmake_unit_string_contains matcher.
#
# See LICENCE.md for Copyright information

include (CMakeUnit)

set (SUBSTRING "substring")
set (MAIN_STRING "main_${SUBSTRING}_string")

_cmake_unit_string_contains (${MAIN_STRING} ${SUBSTRING} RESULT)
_cmake_unit_string_contains (${MAIN_STRING} "other" NOT_RESULT)

cmake_unit_assert_true (${RESULT})
cmake_unit_assert_false (${NOT_RESULT})
