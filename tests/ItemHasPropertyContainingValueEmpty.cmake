# /tests/ItemHasPropertyContainingValueEmpty.cmake
#
# Check the _item_has_property_with_value matcher with empty values.
#
# See LICENCE.md for Copyright information

include (CMakeUnit)

set (TARGET_PROPERTY_VALUE "")
add_custom_target (target)
set_property (TARGET target
              APPEND
              PROPERTY TARGET_PROPERTY
              "${TARGET_PROPERTY_VALUE}")

_item_has_property_containing_value (TARGET target
                                     TARGET_PROPERTY
                                     STRING
                                     EQUAL
                                     "${TARGET_PROPERTY_VALUE}"
                                     EXPECT_EQUAL)

# Empty variables never stored in lists
assert_false (${EXPECT_EQUAL})
