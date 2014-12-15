# /tests/GeneratedAndCreatedSourceFilesEqualVerify.cmake
#
# Checks after build that our source file was generated and exists and is
# completely equal (eg, hash is equal) to a file created during configure
# time.
#
# See LICENCE.md for Copyright information

include (CMakeUnit)

file (SHA512 "${CMAKE_CURRENT_SOURCE_DIR}/CustomSource.cpp" CREATED_HASH)
file (SHA512 "${CMAKE_CURRENT_BINARY_DIR}/CustomSource.cpp" GENERATED_HASH)

cmake_unit_assert_variable_is (CREATED_HASH STRING EQUAL "${GENERATED_HASH}")
