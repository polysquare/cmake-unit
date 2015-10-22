# /util/InvokeIfExists.cmake
#
# Invoke a specified script, if it exists. This file exists to work around
# a bug in MSBuild which re-generates files if they are on multiple targets
# (which breaks if the generator process deletes the input file, being what
#  what cmake_unit_generate_source_file_during_build).
#
# See /LICENCE.md for Copyright information

set (SCRIPT "" CACHE STRING "")
set (ARGS "" CACHE STRING "")

if ("${SCRIPT}" STREQUAL "")

    message (FATAL_ERROR "SCRIPT must be specified")

endif ()

if (EXISTS "${SCRIPT}")

    execute_process (COMMAND "${CMAKE_COMMAND}"
                             -P
                             "${SCRIPT}"
                             ${ARGS})

endif ()
