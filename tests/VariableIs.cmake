# /tests/VariableIs.cmake
# Check the _variable_is matcher.

include (${CMAKE_UNIT_DIRECTORY}/CMakeUnit.cmake)

set (STRING_VARIABLE "value")

_variable_is (${STRING_VARIABLE} STRING EQUAL "value" EXPECT_EQUAL)
_variable_is (${STRING_VARIABLE} STRING EQUAL "nvalue" EXPECT_UNEQUAL)
_variable_is (${STRING_VARIABLE} STRING GREATER "valud" EXPECT_LESS)
_variable_is (${STRING_VARIABLE} STRING GREATER "valuf" EXPECT_NOT_LESS)
_variable_is (${STRING_VARIABLE} STRING LESS "valuf" EXPECT_GREATER)
_variable_is (${STRING_VARIABLE} STRING LESS "valud" EXPECT_NOT_GREATER)

assert_true (${EXPECT_EQUAL})
assert_false (${EXPECT_UNEQUAL})
assert_true (${EXPECT_LESS})
assert_false (${EXPECT_NOT_LESS})
assert_true (${EXPECT_GREATER})
assert_false (${EXPECT_NOT_GREATER})