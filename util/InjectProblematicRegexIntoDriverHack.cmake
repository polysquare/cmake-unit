# /util/InjectProblematicRejectIntoDriverHack.cmake
#
# Reads a driver script as indicated by DRIVER_SCRIPT and replaces
# all instances of @PROBLEMATIC_REGEX_ONE@ and @PROBLEMATIC_REGEX_TWO@ with
# \\\\\\\\] and \\\\\\\\[ respectively.
#
# For some inexplicable reason, this regex (which appears in
# CMakeCheckCompilerId) causes ";" based list separation to break
# completely. It cannot appear in any file where we need to read
# the contents of that file in order to appear in a coverage report
# (which is also why this file should NOT be listed as a coverage
#  candidate).
#
# This string can be injected into our "driver" scripts which can
# then be used as a mechanism to replace instances of the problematic
# regex with nothing.
#
# See LICENCE.md for Copyright information

set (DRIVER_SCRIPT_FILE "" CACHE STRING "")
file (READ "${DRIVER_SCRIPT_FILE}" DRIVER_SCRIPT_CONTENTS)
string (REPLACE "@PROBLEMATIC_REGEX_ONE@" "]"
        DRIVER_SCRIPT_CONTENTS
        "${DRIVER_SCRIPT_CONTENTS}")
string (REPLACE "@PROBLEMATIC_REGEX_TWO@" "["
        DRIVER_SCRIPT_CONTENTS
        "${DRIVER_SCRIPT_CONTENTS}")
file (WRITE "${DRIVER_SCRIPT_FILE}" "${DRIVER_SCRIPT_CONTENTS}")
