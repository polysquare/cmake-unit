# /tests/ItemHasPropertyContainingValueGlobal.cmake
# Check the _item_has_property_with_value matcher with GLOBAL properties
#
# See LICENCE.md for Copyright information.

include (${CMAKE_UNIT_DIRECTORY}/CMakeUnit.cmake)

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

_item_has_property_containing_value (TARGET target
                                     TARGET_PROPERTY
                                     STRING
                                     EQUAL
                                     ${TARGET_PROPERTY_VALUE}
                                     EXPECT_EQUAL_FIRST)

_item_has_property_containing_value (TARGET target
                                     TARGET_PROPERTY
                                     STRING
                                     EQUAL
                                     ${TARGET_PROPERTY_OTHER_VALUE}
                                     EXPECT_EQUAL_SECOND)

_item_has_property_containing_value (TARGET target
                                     TARGET_PROPERTY
                                     STRING
                                     EQUAL
                                     "property_does_not_contain_this"
                                     EXPECT_NOT_EQUAL)

_item_has_property_containing_value (TARGET target
                                     TARGET_NON_EXISTENT_PROPERTY
                                     STRING
                                     EQUAL
                                     ${TARGET_PROPERTY_VALUE}
                                     EXPECT_DOESNT_EXIST)

assert_true (${EXPECT_EQUAL_FIRST})
assert_true (${EXPECT_EQUAL_SECOND})
assert_false (${EXPECT_NOT_EQUAL})
assert_false (${EXPECT_DOESNT_EXIST})