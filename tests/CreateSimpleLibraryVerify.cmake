# /tests/CreateSimpleLibraryVerify.cmake
#
# Checks the build output to make sure a "simple" executable is linked to
# the "simple" library.
#
# See LICENCE.md for Copyright information

include (CMakeUnit)

set (BUILD_OUTPUT "${CMAKE_CURRENT_BINARY_DIR}/BUILD.output")

# There's not too much particularly useful to verify here, other than
# the executable and the library being mentioned because the order
# in which they are mentioned is generator specific
assert_file_has_line_matching ("${BUILD_OUTPUT}" "^.*library.*$")
assert_file_has_line_matching ("${BUILD_OUTPUT}" "^.*executable.*$")
