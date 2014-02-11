# /tests/ItemHasPropertyWithValueGlobal.cmake
# Check the _item_has_property_with_value matcher with GLOBAL properties.
#
# See LICENCE.md for Copyright information.

include (${CMAKE_UNIT_DIRECTORY}/CMakeUnit.cmake)

set (GLOBAL_PROPERTY_VALUE "value")
set_property (GLOBAL
              PROPERTY GLOBAL_PROPERTY
              ${GLOBAL_PROPERTY_VALUE})

_item_has_property_with_value (GLOBAL GLOBAL
                               GLOBAL_PROPERTY
                               STRING
                               EQUAL
                               ${GLOBAL_PROPERTY_VALUE}
                               EXPECT_EQUAL)

_item_has_property_with_value (GLOBAL GLOBAL
                               GLOBAL_PROPERTY
                               STRING
                               EQUAL
                               "something_else"
                               EXPECT_NOT_EQUAL)

_item_has_property_with_value (GLOBAL GLOBAL
                               GLOBAL_NON_EXISTENT_PROPERTY
                               STRING
                               EQUAL
                               ${GLOBAL_PROPERTY_VALUE}
                               EXPECT_DOESNT_EXIST)

assert_true (${EXPECT_EQUAL})
assert_false (${EXPECT_NOT_EQUAL})
assert_false (${EXPECT_DOESNT_EXIST})
