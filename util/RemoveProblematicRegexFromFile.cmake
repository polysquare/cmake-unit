# /util/RemoveProblematicRegexFromFile.cmake
#
# Read INPUT_FILE, replace [ or ] with an empty string and write result to
# OUTPUT_FILE
#
# For some inexplicable reason, this regex (which appears in
# CMakeCheckCompilerId) causes ";" based list separation to break
# completely. It cannot appear in any file where we need to read
# the contents of that file in order to appear in a coverage report
# (which is also why this file should NOT be listed as a coverage
#  candidate).
#
# See /LICENCE.md for Copyright information

set (INPUT_FILE "" CACHE STRING "")
set (OUTPUT_FILE "" CACHE STRING "")

foreach (VAR IN ITEMS INPUT_FILE OUTPUT_FILE)

    if (NOT ${VAR})

        message (FATAL_ERROR "${VAR} must be set")

    endif ()

endforeach ()

file (READ "${INPUT_FILE}" CONTENTS)
string (REPLACE "[" "" CONTENTS "${CONTENTS}")
string (REPLACE "]" "" CONTENTS "${CONTENTS}")
file (WRITE "${OUTPUT_FILE}" "${CONTENTS}")
