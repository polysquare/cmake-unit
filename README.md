# CMake Unit #

A unit testing framework for CMake.

## Status ##

| Travis-CI (Ubuntu) | AppVeyor (Windows) | Coveralls |
|--------------------|--------------------|-----------|
|[![Travis](https://travis-ci.org/polysquare/cmake-unit.svg?branch=master)](https://travis-ci.org/polysquare/cmake-unit)|[![AppVeyor](https://ci.appveyor.com/api/projects/status/7ntnxx783cr627hm/branch/master?svg=true)](https://ci.appveyor.com/project/smspillaz/cmake-unit-724/branch/master)|[![Coveralls](https://coveralls.io/repos/polysquare/cmake-unit/badge.png)](https://coveralls.io/r/polysquare/cmake-unit)|

## Why have a unit-testing framework for CMake ##

Because CMake is a powerful and battle-tested language for writing build systems
for large-scale C++ projects, but its dynamic nature makes it easy to make
undetectable errors which later ship as bugs that either you, or the users of
your macros, need to work around.  We have to put a lot of logic inside out
CMake scripts sometimes, like propogation of global state, if conditions for
various options and host system configurations and loops over variable argument
lists.

It is something you want to get right the first time rather than having to
scratch your head about later with the lack of debugging tools for CMake
scripts.

### Platforms ###

`cmake-unit` is written entirely using the CMake language and should work across
all platforms where CMake is supported.  It had been tested on:
 * Windows (Visual Studio 2010, 2012, 2013, NMake)
 * Mac OS X (XCode, Ninja,
 Make)
 * Ubuntu (Ninja, Make)

## Usage ##

cmake-unit should be included as a submodule in your project and comes with
three files.

### CMakeUnitRunner ###

`CMakeUnitRunner` contains the main "runner" script for loading and executing
test scripts.  Include this file in the `CMakeLists.txt` which is in the same
directory as your test scripts.

`bootstrap_cmake_unit` must be called before calling either `add_cmake_test` or
`add_cmake_build_test`.  This performs some initial internal intialization for
the test system.  `bootstrap_cmake_unit` has two multi-variable argument lists:
 1.  `VARIABLES`: A list of variables whose current value at the time of the
call to `bootstrap_cmake_unit` will be available in each test's configure and
verify stages
 2.  `COVERAGE_FILES`: A list of absolute paths to files which should be
considered candidates for code coverage reporting.  If a file is not specified
here, no coverage statistics will be reocorded for it.

`add_cmake_test` create a CTest test which will load the specified script (with
the `.cmake` extension removed) as though it were an actual CMake project, so
that you have full access to the cache.  From here, you can include your other
macros and set up a small project in order to exercise them.  Your project will
not be built, only configured.

`add_cmake_build_test` is the slightly more heavyweight version of
`add_cmake_test`.  It takes both the name of a script to perform the configure
step and the name of a script which is executed *as a script* (not as a project)
after the build completes.  This can be used to check that a project was built
in the expected way.

### CMakeUnit ###

`CMakeUnit` contains matchers and assertions.  They aren't written in true xUnit
style due to the inability to capture function names in variables and later call
them in CMake.  You can use them in both the configure and verify stages.  If
the script hits an assertion failure, it will call `message (SEND_ERROR)`.

The following assertions are available at the time of writing this documentation

* `assert_target_exists`, `assert_target_does_not_exist`: Asserts that the
target provided as the first argument exists or does not exist.
* `assert_string_contains`, `assert_string_does_not_contain`: Asserts that the
second string is a substring of the first.
* `assert_variable_is`, `assert_variable_is_not`: Asserts that the variable
specified matches some of the parameters provided.  A variable name, type,
comparator statement (`EQUAL` `LESS` `GREATER`) and value to compare against can
be provided.
* `assert_variable_matches_regex`, `assert_variable_does_not_match_regex`:
Asserts that the value provided when treated as a string matches the regex
provided in the second argument.
* `assert_variable_is_defined`, `assert_variable_is_not_defined`: Asserts that
a variable was or was not defined
* `assert_command_executes_with_success`,
`assert_command_does_not_execute_with_sucess`: For a command `COMMAND` and each
of its arguments encapsulated in the list passed-by-variable (as opposed to by
value), check if it executed with success.
* `assert_target_is_linked_to`, `assert_target_is_not_linked_to`: Asserts that
the target has a link library that matches the name specified by the second
argument.  It does regex matching to ensure that in the default case, libraries
with slightly inexact names between platforms are still matched against.
* `assert_has_property_with_value`, `assert_does_not_have_property_with_value`:
Asserts that the item specified with the item type specified has property with
a value and type specified which matches the provided comparator.
* `assert_has_property_containing_value`,
 `assert_does_not_have_property_containing_value`: Like
 `assert_has_property_with_value` but looks inside items in a list held by the
 proeprty.
* `assert_file_exists`, `assert_file_does_not_exist`: Asserts that a
 file exists on the filesystem.
* `assert_file_contains`, `assert_file_does_not_contain`: Asserts that a file
contains the substring specified.

#### Utility Functions ####

`cmake-unit` also provides a few utility functions to make writing tests easier.

##### Strings #####

###### `cmake_unit_escape_string` ######

Escape all characters from INPUT and store in OUTPUT_VARIABLE

##### Source File Generation #####

###### `cmake_unit_write_out_source_file_before_build` ######

Writes out a source file, for use with `add_library`, `add_executable` or source
scanners during the configure phase.

If the source is detected as a header based on the `NAME` property such that it
does not have a C or C++ extension, then header guards will be written and
function definitions will not be included.
* [Optional] `NAME`: Name of the source file.  May include slashes which will
  be interpreted as a subdirectory relative to `CMAKE_CURRENT_SOURCE_DIR`.
  The default is Source.cpp
* [Optional] `FUNCTIONS_EXPORT_TARGET`: The target that this source file is
  built for.  Generally this is used if it is necessary to export functions
  from this source file. cmake_unit_create_simple_library uses
  this argument for instance.
* [Optional] `INCLUDES`: A list of files, relative or absolute paths, to
  `#include`
* [Optional] `DEFINES`: A list of `#define`s (macro name only)
* [Optional] `FUNCTIONS`: A list of functions.
* [Optional] `PREPEND_CONTENTS`: Contents to include in the file after
  `INCLUDES`, `DEFINES` and Function Declarations, but before Function
  Definitions
* [Optional] `INCLUDE_DIRECTORIES`: A list of directories such that, if an
  entry in the INCLUDES list has the same directory name as an entry in
  `INCLUDE_DIRECTORIES` then the entry will be angle-brackets <include> with
  the path relative to that include directory.

###### `cmake_unit_generate_source_file_during_build` ######

Generates a source file, for use with `add_library`, `add_executable`
or source scanners during the build phase.

If the source is detected as a header based on the `NAME` property such that
it does not have a C or C++ extension, then header guards will be written
and function definitions will not be included.

* `TARGET_RETURN`: Variable to store the name of the target this source file
  will be generated on
* [Optional] `NAME`: Name of the source file.  May include slashes which will
  be interpreted as a subdirectory relative to `CMAKE_CURRENT_SOURCE_DIR`.
  The default is Source.cpp
* [Optional] `FUNCTIONS_EXPORT_TARGET`: The target that this source file is
  built for.  Generally this is used if it is necessary to export functions
  from this source file. cmake_unit_create_simple_library uses
  this argument for instance.
* [Optional] `INCLUDES`: A list of files, relative or absolute paths, to
  `#include`
* [Optional] `DEFINES`: A list of `#define`s (macro name only)
* [Optional] `FUNCTIONS`: A list of functions.
* [Optional] `PREPEND_CONTENTS`: Contents to include in the file after
  `INCLUDES`, `DEFINES` and Function Declarations, but before Function
  Definitions
* [Optional] `INCLUDE_DIRECTORIES`: A list of directories such that, if an
  entry in the INCLUDES list has the same directory name as an entry in
  `INCLUDE_DIRECTORIES` then the entry will be angle-brackets <include> with
  the path relative to that include directory.

##### Binary target generation #####

These functions can be used to generate binary targets such as simple
executables and libraries.  There will only be a single source file per
executable or library generated.

###### `cmake_unit_create_simple_executable` ######

Creates a simple executable by the name "NAME" which will always have a "main"
function.
* `NAME`: Name of executable
* [Optional] `INCLUDES`: A list of files, relative or absolute paths, to
  `#include`
* [Optional] `DEFINES`: A list of `#define`s (macro name only)
* [Optional] `FUNCTIONS`: A list of functions.
* [Optional] `PREPEND_CONTENTS`: Contents to include in the file after
  `INCLUDES`, `DEFINES` and Function Declarations, but before Function
  Definitions
* [Optional] `INCLUDE_DIRECTORIES`: A list of directories such that, if an
  entry in the INCLUDES list has the same directory name as an entry in
  `INCLUDE_DIRECTORIES` then the entry will be angle-brackets <include> with
  the path relative to that include directory.

###### `cmake_unit_create_simple_library` ######

Creates a simple executable by the name "NAME" which will always have a "main"
function.
* `NAME`: Name of executable
* [Optional] `INCLUDES`: A list of files, relative or absolute paths, to
  `#include`
* [Optional] `DEFINES`: A list of `#define`s (macro name only)
* [Optional] `FUNCTIONS`: A list of functions.
* [Optional] `PREPEND_CONTENTS`: Contents to include in the file after
  `INCLUDES`, `DEFINES` and Function Declarations, but before Function
  Definitions
* [Optional] `INCLUDE_DIRECTORIES`: A list of directories such that, if an
  entry in the INCLUDES list has the same directory name as an entry in
  `INCLUDE_DIRECTORIES` then the entry will be angle-brackets <include> with
  the path relative to that include directory.

##### Working with Built Projects #####

###### `cmake_unit_get_target_location_from_exports` ######

For an exports file `EXPORTS` and target `TARGET`, finds the location of a
target from an already generated `EXPORTS` file.

This function should be run in the verify stage in order to determine the
location of a binary or library built by CMake. The initial configure
step should run `export (TARGETS ...)` in order to generate this file.

This function should alwyas be used where a binary or library needs to
be invoked after build. Different platforms put the completed binaries
in different places and also give them a different name. This function
will resolve all those issues.

* `EXPORTS`: Full path to `EXPORTS` file to read
* `TARGET`: Name of `TARGET` as it will be found in the `EXPORTS` file
* `LOCATION_RETURN`: Variable to write target's `LOCATION` property into.

###### `cmake_unit_export_cfg_int_dir` ######

Exports the current `CMAKE_CFG_INTDIR` variable (known at configure-time)
and writes it into the file specified at `LOCATION`. This file could be read
after the build to determine the `CMAKE_CFG_INTDIR` property

* `LOCATION`: Filename to write `CMAKE_CFG_INTDIR` variable to.

###### `cmake_unit_import_cfg_int_dir` ######

Reads `OUTPUT_FILE` to import the value of the `CMAKE_CFG_INTDIR` property
and stores the value inside of `LOCATION_RETURN`. This should be run in the
verify phase to get the `CMAKE_CFG_INTDIR` property for the configure phase
generator. Use `cmake_unit_export_cfg_int_dir` in the configure phase
to export the `CMAKE_CFG_INTDIR` property.

* `OUTPUT_FILE`: Filename to read `CMAKE_CFG_INTDIR` variable from.
* `LOCATION_RETURN`: Variable to store `CMAKE_CFG_INTDIR` value into.

### CMakeTraceToLCov ###

`CMakeTraceToLCov` is a script that converts a tracefile generated by using
`CMAKE_UNIT_LOG_COVERAGE=ON` into a Linux Test Project Coverage (LCov)
compatible file.

`CMakeTraceToLCov` should be run in script mode from the toplevel source
directory where CMake scripts are to be kept.

There are two cache options which must be set prior to use:
 1. `TRACEFILE`: Path to a tracefile generated by using
    `CMAKE_UNIT_LOG_COVERAGE=ON`
 2. `LCOV_OUTPUT`: Path to filename where LCov output file should be stored.

## Known Issues ##

The following issues are known at the time of writing
 * polysquare/cmake-unit#55 : Custom Command output on Visual Studio Generators
                              not available
 * polysquare/cmake-unit#56 : cmake-unit overrides add_custom_command
 * polysquare/cmake-unit#57 : Coverage file paths may not contain square
                              brackets ([])

## Example ##

Here is an example using an assumed `CustomTool` macro that you might want to
test.  We assume that it contains a function called `custom_tool_run_on_source`
which runs an executable called `custom-tool` at build time.  We also assume
that `cmake-unit` is checked out as a submodule in the root directory of your
project and that you have a directory called `test` in the root directory of
your project.

First you should create a `CMakeLists.txt`.  This must contain a small amount of
boilerplate to include everything and bootstrap cmake-unit:

    project (CustomToolTests)
    cmake_minimum_required (VERSION 2.8)

    get_filename_component (CUSTOM_TOOL_DIRECTORY
                            "${CMAKE_CURRENT_SOURCE_DIR}/.."
                            ABSOLUTE)
    set (CMAKE_UNIT_DIRECTORY ("${CUSTOM_TOOL_DIRECTORY}/cmake-unit")

    set (CMAKE_MODULE_PATH
         "${CMAKE_UNIT_DIRECTORY}"
         "${CUSTOM_TOOL_DIRECTORY}"
         ${CMAKE_MODULE_PATH})

    include (CMakeUnitRunner)

    bootstrap_cmake_unit (VARIABLES CMAKE_MODULE_PATH
                          COVERAGE_FILES
                          "${CUSTOM_TOOL_DIRECTORY}/CustomTool.cmake")

This code will set up CMake module paths, include `CMakeUnitRunner` and tell
`cmake-unit` that `CMAKE_MODULE_PATH` should be "forwarded" with its current
value to the tests and that execution of `CustomTool.cmake` should be watched in
order to log coverage.

Next, you'll want to create some tests.  These tests should be created in the
same directory as the `CMakeLists.txt`.  We'll call our test
`CustomToolRunsOnCode` and create a `CustomToolRunsOnCode.cmake` and
`CustomToolRunsOnCodeVerify.cmake`.

We'll add the test to our `CMakeLists.txt`

    add_cmake_build_test (CustomToolRunsOnCode
                          CustomToolRunsOnCodeVerify)

This is what is known as a "build test".  Build tests include the first named
file during the configure phase, then build and test the project.  Each step
will have its standard output logged to `STEP.output` and `STEP.error` in the
`CMAKE_CURRENT_BINARY_DIR`.  `STEP` can be either one of `CONFIGURE`, `BUILD`,
`TEST` and `VERIFY`.

During the configure phase, you have complete access to all CMake commands.  You
can create targets, add custom commands and even add tests.

For this configure phase, we'll generate a source file and then run our tool
over it:

    include (CMakeUnit)
    include (CustomTool)

    cmake_unit_generate_source_file_during_build (TARGET
                                                  NAME CustomSource.cpp
                                                  DEFINES CUSTOM_DEFINE
                                                  INCLUDES vector
                                                  FUNCTIONS custom_function)
    custom_tool_run_on_source (${TARGET}
                               "${CMAKE_CURRENT_SOURCE_DIR}/CustomSource.cpp")

 During the verify phase, the script will only run in CMake 'script mode'.
 Certain commands associated with configuring and building projects will be
 unavailable.

 For this verify phase, we'll read the build output to make sure our
 `custom-tool` actually ran on `CustomSource.cpp`

     include (CMakeUnit)

     set (BUILD_OUTPUT "${CMAKE_CURRENT_BINARY_DIR}/BUILD.output")
     assert_file_has_line_matching ("${BUILD_OUTPUT}"
                                    "^.*custom-tool.*CustomSource.cpp.*$")