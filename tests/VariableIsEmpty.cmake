# /tests/VariableIsEmpty.cmake
#
# Check the _cmake_unit_variable_is matcher with empty values
#
# See LICENCE.md for Copyright information

include (CMakeUnit)

set (STRING_VARIABLE "")

_cmake_unit_variable_is ("${STRING_VARIABLE}" STRING EQUAL "" EXPECT_EQUAL)

cmake_unit_assert_true (${EXPECT_EQUAL})
