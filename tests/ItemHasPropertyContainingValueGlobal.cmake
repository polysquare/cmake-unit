# /tests/ItemHasPropertyWithValue.cmake
# Check the _item_has_property_with_value matcher with GLOBAL properties.

include (CMakeUnit)

set (GLOBAL_PROPERTY_VALUE "value")
set (GLOBAL_PROPERTY_OTHER_VALUE "other_value")
set_property (GLOBAL
              APPEND
              PROPERTY GLOBAL_PROPERTY
              ${GLOBAL_PROPERTY_VALUE})
set_property (GLOBAL
              APPEND
              PROPERTY GLOBAL_PROPERTY
              ${GLOBAL_PROPERTY_OTHER_VALUE})

_item_has_property_containing_value (GLOBAL GLOBAL
                                     GLOBAL_PROPERTY
                                     STRING
                                     EQUAL
                                     ${GLOBAL_PROPERTY_VALUE}
                                     EXPECT_EQUAL)

_item_has_property_containing_value (GLOBAL GLOBAL
                                     GLOBAL_PROPERTY
                                     STRING
                                     EQUAL
                                     "something_else"
                                     EXPECT_NOT_EQUAL)

_item_has_property_containing_value (GLOBAL GLOBAL
                                     GLOBAL_NON_EXISTENT_PROPERTY
                                     STRING
                                     EQUAL
                                     ${GLOBAL_PROPERTY_VALUE}
                                     EXPECT_DOESNT_EXIST)

assert_true (${EXPECT_EQUAL})
assert_false (${EXPECT_NOT_EQUAL})
assert_false (${EXPECT_DOESNT_EXIST})
