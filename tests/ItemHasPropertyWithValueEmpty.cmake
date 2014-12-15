# /tests/ItemHasPropertyWithValueEmpty.cmake
#
# Check the _cmake_unit_item_has_property_with_value matcher with empty values.
#
# See LICENCE.md for Copyright information

include (CMakeUnit)

set (TARGET_PROPERTY_VALUE "")
add_custom_target (target)
set_property (TARGET target
              PROPERTY TARGET_PROPERTY
              "${TARGET_PROPERTY_VALUE}")

_cmake_unit_item_has_property_with_value (TARGET target
                                          TARGET_PROPERTY
                                          STRING EQUAL
                                          "${TARGET_PROPERTY_VALUE}"
                                          EXPECT_EQUAL)

cmake_unit_assert_true (${EXPECT_EQUAL})
