# /tests/VariableIs.cmake
# Check the _variable_is matcher with empty values

include (CMakeUnit)

set (STRING_VARIABLE "")

_variable_is ("${STRING_VARIABLE}" STRING EQUAL "" EXPECT_EQUAL)

assert_true (${EXPECT_EQUAL})