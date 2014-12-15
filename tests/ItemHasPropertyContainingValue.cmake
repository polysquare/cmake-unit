# /tests/ItemHasPropertyContainingValue.cmake
#
# Check the _cmake_unit_item_has_property_with_value matcher.
#
# See LICENCE.md for Copyright information

include (CMakeUnit)

set (TARGET_PROPERTY_VALUE "value")
set (TARGET_PROPERTY_OTHER_VALUE "other_value")
add_custom_target (target)
set_property (TARGET target
              APPEND
              PROPERTY TARGET_PROPERTY
              ${TARGET_PROPERTY_VALUE})
set_property (TARGET target
              APPEND
              PROPERTY TARGET_PROPERTY
              ${TARGET_PROPERTY_OTHER_VALUE})

_cmake_unit_item_has_property_containing_value (TARGET target
                                                TARGET_PROPERTY
                                                STRING EQUAL
                                                ${TARGET_PROPERTY_VALUE}
                                                EXPECT_EQUAL_FIRST)

_cmake_unit_item_has_property_containing_value (TARGET target
                                                TARGET_PROPERTY
                                                STRING EQUAL
                                                ${TARGET_PROPERTY_OTHER_VALUE}
                                                EXPECT_EQUAL_SECOND)

_cmake_unit_item_has_property_containing_value (TARGET target
                                                TARGET_PROPERTY
                                                STRING EQUAL
                                                "property_does_not_contain_this"
                                                EXPECT_NOT_EQUAL)

_cmake_unit_item_has_property_containing_value (TARGET target
                                                TARGET_NON_EXISTENT_PROPERTY
                                                STRING EQUAL
                                                ${TARGET_PROPERTY_VALUE}
                                                EXPECT_DOESNT_EXIST)

cmake_unit_assert_true (${EXPECT_EQUAL_FIRST})
cmake_unit_assert_true (${EXPECT_EQUAL_SECOND})
cmake_unit_assert_false (${EXPECT_NOT_EQUAL})
cmake_unit_assert_false (${EXPECT_DOESNT_EXIST})
