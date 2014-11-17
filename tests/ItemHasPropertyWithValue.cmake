# /tests/ItemHasPropertyWithValue.cmake
#
# Check the _item_has_property_with_value matcher.
#
# See LICENCE.md for Copyright information

include (CMakeUnit)

set (TARGET_PROPERTY_VALUE "value")
add_custom_target (target)
set_property (TARGET target
              PROPERTY TARGET_PROPERTY
              ${TARGET_PROPERTY_VALUE})

_item_has_property_with_value (TARGET target
                               TARGET_PROPERTY
                               STRING
                               EQUAL
                               ${TARGET_PROPERTY_VALUE}
                               EXPECT_EQUAL)

_item_has_property_with_value (TARGET target
                               TARGET_PROPERTY
                               STRING
                               EQUAL
                               "something_else"
                               EXPECT_NOT_EQUAL)

_item_has_property_with_value (TARGET target
                               TARGET_NON_EXISTENT_PROPERTY
                               STRING
                               EQUAL
                               ${TARGET_PROPERTY_VALUE}
                               EXPECT_DOESNT_EXIST)

assert_true (${EXPECT_EQUAL})
assert_false (${EXPECT_NOT_EQUAL})
assert_false (${EXPECT_DOESNT_EXIST})
