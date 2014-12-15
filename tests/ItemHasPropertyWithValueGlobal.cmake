# /tests/ItemHasPropertyWithValueGlobal.cmake
#
# Check the _cmake_unit_item_has_property_with_value matcher with GLOBAL
# properties.
#
# See LICENCE.md for Copyright information

include (CMakeUnit)

set (GLOBAL_PROPERTY_VALUE "value")
set_property (GLOBAL
              PROPERTY GLOBAL_PROPERTY
              ${GLOBAL_PROPERTY_VALUE})

_cmake_unit_item_has_property_with_value (GLOBAL GLOBAL
                                          GLOBAL_PROPERTY
                                          STRING EQUAL
                                          ${GLOBAL_PROPERTY_VALUE}
                                          EXPECT_EQUAL)

_cmake_unit_item_has_property_with_value (GLOBAL GLOBAL
                                          GLOBAL_PROPERTY
                                          STRING EQUAL
                                          "something_else"
                                          EXPECT_NOT_EQUAL)

_cmake_unit_item_has_property_with_value (GLOBAL GLOBAL
                                          GLOBAL_NON_EXISTENT_PROPERTY
                                          STRING EQUAL
                                          ${GLOBAL_PROPERTY_VALUE}
                                          EXPECT_DOESNT_EXIST)

cmake_unit_assert_true (${EXPECT_EQUAL})
cmake_unit_assert_false (${EXPECT_NOT_EQUAL})
cmake_unit_assert_false (${EXPECT_DOESNT_EXIST})
