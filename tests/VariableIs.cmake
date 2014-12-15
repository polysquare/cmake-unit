# /tests/VariableIs.cmake
#
# Check the _cmake_unit_variable_is matcher.
#
# See LICENCE.md for Copyright information

include (CMakeUnit)

set (STRING_VARIABLE "value")

_cmake_unit_variable_is (STRING_VARIABLE STRING EQUAL "value" EXPECT_EQUAL)
_cmake_unit_variable_is (STRING_VARIABLE STRING EQUAL "nvalue" EXPECT_UNEQUAL)
_cmake_unit_variable_is (STRING_VARIABLE STRING GREATER "valud" EXPECT_LESS)
_cmake_unit_variable_is (STRING_VARIABLE STRING GREATER "valuf" EXPECT_NOT_LESS)
_cmake_unit_variable_is (STRING_VARIABLE STRING LESS "valuf" EXPECT_GREATER)
_cmake_unit_variable_is (STRING_VARIABLE STRING LESS "valud" EXPECT_NOT_GREATER)

cmake_unit_assert_true (${EXPECT_EQUAL})
cmake_unit_assert_false (${EXPECT_UNEQUAL})
cmake_unit_assert_true (${EXPECT_LESS})
cmake_unit_assert_false (${EXPECT_NOT_LESS})
cmake_unit_assert_true (${EXPECT_GREATER})
cmake_unit_assert_false (${EXPECT_NOT_GREATER})

set (INTEGER_VARIABLE 1)

# Integers
_cmake_unit_variable_is (INTEGER_VARIABLE INTEGER EQUAL 1 EXPECT_EQUAL)
_cmake_unit_variable_is (INTEGER_VARIABLE INTEGER EQUAL 2 EXPECT_UNEQUAL)
_cmake_unit_variable_is (INTEGER_VARIABLE INTEGER GREATER 0 EXPECT_LESS)
_cmake_unit_variable_is (INTEGER_VARIABLE INTEGER GREATER 2 EXPECT_NOT_LESS)
_cmake_unit_variable_is (INTEGER_VARIABLE INTEGER LESS 2 EXPECT_GREATER)
_cmake_unit_variable_is (INTEGER_VARIABLE INTEGER LESS 0 EXPECT_NOT_GREATER)

cmake_unit_assert_true (${EXPECT_EQUAL})
cmake_unit_assert_false (${EXPECT_UNEQUAL})
cmake_unit_assert_true (${EXPECT_LESS})
cmake_unit_assert_false (${EXPECT_NOT_LESS})
cmake_unit_assert_true (${EXPECT_GREATER})
cmake_unit_assert_false (${EXPECT_NOT_GREATER})

set (BOOL_VARIABLE ON)

# Bool
_cmake_unit_variable_is (BOOL_VARIABLE BOOL EQUAL ON EXPECT_EQUAL)
_cmake_unit_variable_is (BOOL_VARIABLE BOOL EQUAL OFF EXPECT_UNEQUAL)

cmake_unit_assert_true (${EXPECT_EQUAL})
cmake_unit_assert_false (${EXPECT_UNEQUAL})
