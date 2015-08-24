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
* Mac OS X (XCode, Ninja, Make)
* Ubuntu (Ninja, Make)

## Usage ##

cmake-unit should be included as a submodule in your project and comes with
three files.

### CMakeUnitRunner ###

`CMakeUnitRunner` contains the main "runner" script for loading and executing
test scripts.  Include this file in the `/CMakeLists.txt`.

Tests are defined inline as functions. They are automatically discovered by
cmake-unit and the name of the function must be in the format of
`${your_namespace}_test_{test_name}`. Within each test function are
function definitions used to control each "phase" of the test's build. After
these functions are called, a call to `cmake_unit_configure_test` ties all
the phases functions together into a single test.

Test functions are subdivided into "phases", each phase having its own
script that can be run in place of the default. Usually you will want to
override the CONFIGURE or VERIFY phases in order to provide your own
project set-up and verification scripts. The build of each project goes
through the following phases, in order:

* `PRECONFIGURE`
* `CLEAN`
* `INVOKE_CONFIGURE`
* `CONFIGURE`
* `INVOKE_BUILD`
* `INVOKE_TEST`
* `VERIFY`
* `COVERAGE`

For each phase, a name of a function can be provided which will "override"
the default function called for that phase. Some phases are called within
different CMake invocations, so you shouldn't assume that state can be
shared between the phase functions.

The name of each phase is a keyword argument to `cmake_unit_configure_test`.
Following the phase name, further options can be specified for each phase.
Some common options are:

* `COMMAND`: The name of a function to run when this phase is encountered.
* `ALLOW_FAIL`: A keyword specifying that this phase is permitted to fail
                (and further, that no phase after this one should be run).

#### The `PRECONFIGURE` phase ####

This is the first phase that is run for the test. It cannot be overridden.
It does some initial setup for the test itself, including writing out
a special driver script which will be used to invoke this test at CTest time.

#### The `CLEAN` phase ####

This phase is responsible for cleaning the build directory of the test. By
default, it calls `cmake_unit_invoke_clean`, which just removes the test
project's `CMAKE_BINARY_DIR`.

#### The `INVOKE_CONFIGURE` phase ####

This phase is responsible for writing out a stub `/CMakeLists.txt` and jumping
invoking `cmake` on the resulting project folder. By default it will call
`cmake_unit_invoke_configure`. The written out `/CMakeLists.txt` will do some
setup for the test project, including calling the `project` command.

`cmake_unit_invoke_configure` will not configure any languages by default. This
is to prevent unnecessary overhead when testing on platforms where configuring
language support is quite slow (for instance, Visual Studio and XCode). Instead
of overriding the command, usually the only action you will need to take if
you need language support is to set the `LANGUAGES` option (eg, to `C CXX`).

#### The `CONFIGURE` phase ####

This phase is responsible for actually configuring the project. Any commands
run inside this phase are effectively run as though CMake was configuring
a project by processing a `/CMakeLists.txt`, so the full range of commands
are available. Usually you will want to override the `COMMAND` and configure
your project as required (or make assertions).

#### The `INVOKE_BUILD` phase ####

This phase is responsible for invoking `cmake --build`. Usually the `COMMAND`
will not need to be overridden, but if the build can fail or if the project
should not be built at all, then `ALLOW_FAIL` or `COMMAND NONE` should be
specified respectively.

The `TARGET` option allows you to specify a custom target to build instead
of the default one.

#### The `INVOKE_TEST` phase ####

This phase is responsible for invoking `ctest`. Usually the `COMMAND` will
not need to be overridden, unless you need to invoke `ctest`in a special way.

#### The `VERIFY` phase ####

This phase is responsible for verifying that the configure, build and test
steps went the way you expected. It is executed after the final step of the
configure-build-test cycle is completed for this project.

You can inspect the standard output and error of each of these steps. Use the
`cmake_unit_get_log_for` command in order to fetch the path to these log files.

#### The `COVERAGE` phase ####

This phase is responsible for collecting tracefile output and turning it into
line-coverage statistics. It is not overridable.

#### An example of a test ####

Here is an example of how a test looks in practice:

    function (namespace_test_one)

        function (_namespace_configure)

            cmake_unit_create_simple_library (library SHARED FUNCTIONS function)
            cmake_unit_create_simple_executable (executable)
            target_link_libraries (executable library)

            cmake_unit_assert_that (executable is_linked_to library)

        endfunction ()

        function (_namespace_verify)

            cmake_unit_get_log_for (INVOKE_BUILD OUTPUT BUILD_OUTPUT)

            cmake_unit_assert_that ("${BUILD_OUTPUT}"
                                    file_contents any_line
                                    matches_regex
                                    "^.*executable.*$")

        endfunction ()

        cmake_unit_configure_test (INVOKE_CONFIGURE LANGUAGES C CXX
                                   CONFIGURE COMMAND _namespace_configure
                                   VERIFY COMMAND _namespace_verify)

    endfunction ()

The `_namespace_configure` and `_namespace_verify` functions are defined within
the `namespace_test_one` function. They are passed to the `COMMAND` keyword for
the `CONFIGURE` and `VERIFY` phases on `cmake_unit_configure_test`.

`LANGUAGES C CXX` is passed to `INVOKE_CONFIGURE`. This ensures that compilers
are tested and CMake is set up to build and link C and C++ binary code.

#### Shortcut to skip the build phase ####

If there's no need to build and test the test project, or to verify it, you
can use `cmake_unit_configure_config_only_test` in place of
`cmake_unit_configure_test`. This will pass `INVOKE_BUILD COMMAND NONE` and
`INVOKE_TEST COMMAND NONE` to `cmake_unit_configure_test` along with whatever
options you specify.

#### Discovering tests and running them ####

`cmake_unit_init` is what handles the registration and running of each
discovered test function. It takes a namespace as the argument to the keyword
NAMESPACE. This is the name each test is prefixed with (followed by _test).
Any function matching the pattern ^${namespace}_test_.*$ will be automatically
registered. It also takes a list of files considered to be candidates for
code coverage as `COVERAGE_FILES`.

As an example, see the following:

    cmake_unit_init (NAMESPACE namespace
                     COVERAGE_FILES "${PROJECT_DIR}/Module.cmake")

### CMakeUnit ###

`CMakeUnit` contains matchers and a general `cmake_unit_assert_that` function.
You can use them in both the configure and verify stages.  If
the script hits an assertion failure, it will call `message (SEND_ERROR)`.

#### Built-in matchers ####

The following matchers are available at the time of writing this documentation

* `is_true`: Matches if the passed variable name has a value that is boolean
  true.
* `is_false`: Matches if the passed variable name has a value that is boolean
  false.
* `target_exists`: Matches if the target provided as the first argument
  exists.
* `variable_contains`: Matches if a substring is present in the value of
  the value of the variable name.
* `compare_as`: Matches if the variable specified satisfies the
  parameters provided.  A variable name, type, comparator statement
  (`EQUAL` `LESS` `GREATER`) and value to compare against can be provided.
* `matches_regex`: Matches if the value of the variable provided, when
  treated as a string matches the regex provided in the second argument.
* `is_defined`: Matches any variable that is defined
* `executes_with_success`: For a command and each of its arguments encapsulated
  in the list passed-by-variable-name (as opposed to by value), check if it
  executed with success.
* `is_linked_to`: Matches if the target has a link library that matches
  the name specified by the second argument.  It does regex matching to ensure
  that in the default case, libraries with slightly inexact names between
  platforms are still matched against.
* `list_contains_value`: Checks inside specified variable name containing
  a list to see if any item contains a value satisfying the criteria.
* `has_property_with_value`: Matches if the item specified with the item type
  specified has property with a value and type specified which matches the
  provided comparator.
* `has_property_containing_value`: Like `has_property_with_value` but looks
  inside items in a list held by the property.
* `exists_as_file`: Matches if file exists on the filesystem.
* `file_contents`: Matches if the contents of a file match the matcher
  and arguments provided afterwards.
* `any_line`: Matches if any line of a multi-line string matches the following
  matcher and its arguments.
* `not`: Matches if the item specified does not match the following matcher.

#### Writing your own matchers ####

`cmake-unit` can be extended with your own matchers. To do this, you will
need to write a "callable" function in your project's namespace, for example

    function (my_namespace_equal_to_seven)

        list (GET CALLER_ARGN 0 VARIABLE)
        list (GET CALLER_ARGN -1 RESULT_VALUE)

        set (${RESULT_VALUE} "to be equal to 7" PARENT_SCOPE)

        if ("${${VARIABLE}}" EQUAL 7)

            set (${RESULT_VALUE} TRUE PARENT_SCOPE)

        endif ()

    endfunction ()

Then you will need to register your project's namespace as a namespace
containing matchers

    cmake_unit_register_matcher_namespace (my_namespace)

You can start using your matcher like so:

    cmake_unit_assert_that (VARIABLE equal_to_seven)

The function `my_namespace_equal_to_seven` is a `callable` function abiding
by the calling convention set out below. Its first argument will always be
the variable-to-be-matched. Depending on what your matcher does, this may be
a value or a variable name. The last variable is always the "result variable",
which is the name of the variable that you will need to set in the parent
scope to indicate the matcher status. By convention, matchers should
set this variable to a sentence fragment that would provide a sensible
explanation of what happened in the sentence "Expected VARIABLE ..." in
case there was a mismatch. Otherwise, the variable should be set to TRUE.

#### Overridable Phase Functions ####

Each of these functions is a default for a phase of a cmake-unit test's build
cycle. If they are overridden, they can be "chained up" to. `CALLER_ARGN` will
be passed implicitly.

##### `cmake_unit_invoke_clean` #####

Cleans the project `BINARY_DIRECTORY` (as specified in `CALLER_ARGN`).

##### `cmake_unit_invoke_configure` #####

Creates a `/CMakeLists.txt` for this project which does some initial setup and
then jumps to the function defined for `CONFIGURE`. `cmake` is invoked on a
build directory for the folder containing the created `/CMakeLists.txt`.

##### `cmake_unit_invoke_build` #####

Invokes `cmake --build` on this project.

##### `cmake_unit_invoke_test` #####

Invokes `ctest -C Debug` on this project.

#### Utility Functions ####

`cmake-unit` also provides a few utility functions to make writing tests easier.

##### Strings #####

###### `cmake_unit_escape_string` ######

Escape all characters from INPUT and store in OUTPUT_VARIABLE

##### Test data #####

###### `cmake_unit_get_dirs` ######

Reliably returns the binary and source directories for this test. You should
use this instead of `CMAKE_CURRENT_SOURCE_DIR` and `CMAKE_CURRENT_BINARY_DIR`
where possible, as it will be correct in every phase.

##### Source File Generation #####

###### `cmake_unit_create_source_file_before_build` ######

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
  `INCLUDE_DIRECTORIES` then the entry will be angle-brackets `<include>` with
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
  `INCLUDE_DIRECTORIES` then the entry will be angle-brackets `<include>` with
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
  `INCLUDE_DIRECTORIES` then the entry will be angle-brackets `<include>` with
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
  `INCLUDE_DIRECTORIES` then the entry will be angle-brackets `<include>` with
  the path relative to that include directory.

##### Working with Built Projects #####

###### `cmake_unit_get_target_location_from_exports` ######

For an exports file `EXPORTS` and target `TARGET`, finds the location of a
target from an already generated `EXPORTS` file.

This function should be run in the verify stage in order to determine the
location of a binary or library built by CMake. The initial configure
step should run `export (TARGETS ...)` in order to generate this file.

This function should always be used where a binary or library needs to
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

###### `cmake_unit_get_log_for` ######

Gets the `LOG_TYPE` log for `PHASE` and stores it in the variable specified
in `LOG_FILE_RETURN`. The returned log is a path to a file. Valid values
for the `LOG_TYPE` parameter are  `ERROR` and `OUTPUT`.

### CMakeTraceToLCov ###

`CMakeTraceToLCov` is a script that converts a tracefile generated by using
`CMAKE_UNIT_LOG_COVERAGE=ON` into a Linux Test Project Coverage (LCov)
compatible file.

`CMakeTraceToLCov` should be run in script mode from the toplevel source
directory where CMake scripts are to be kept.

There are two cache options which must be set prior to use:

* `TRACEFILE`: Path to a tracefile generated by using
  `CMAKE_UNIT_LOG_COVERAGE=ON`
* `LCOV_OUTPUT`: Path to filename where LCov output file should be stored.

## Known Issues ##

The following issues are known at the time of writing:

* polysquare/cmake-unit#55 : Custom Command output on Visual Studio Generators
                             not available
* polysquare/cmake-unit#56 : cmake-unit overrides add_custom_command
* polysquare/cmake-unit#57 : Coverage file paths may not contain square
                             brackets ([])

## Technical Implementation Notes ##

`cmake-unit` uses some clever hacks under the hood in order to achieve its
"streamlined" test definition syntax.

### Calling arbitrary functions ###

Test auto-discovery, dynamic test loading and custom phase specification is
all achieved through the ability to call arbitrary functions. CMake doesn't
offer any syntax to do so, but there is a back door using a debugging feature
called [`variable_watch`](http://www.cmake.org/cmake/help/v3.1/command/variable_watch.html?highlight=variable_watch).

Obviously, `variable_watch` provides its own arguments to the called function,
which is not entirely what we want. However, CMake makes it relatively easy to
establish a kind of "calling convention" for these called functions. Usage of
keyword arguments with [`CMakeParseArguments`](http://www.cmake.org/cmake/help/v3.1/module/CMakeParseArguments.html?highlight=cmakeparsearguments)
is pretty common for most modules. We defined a variable called `CALLER_ARGN`
which functions just like `ARGN` would in a normal function call. All arguments
are passed as keywords.

`variable_watch` can only be used to register a callback for one variable at a
time, so if a function is to be called multiple times, then a register needs
to be maintained mapping function names to variable names.

All of this is encapsulated within the `cmake_call_function` command. This is
hosted as a separate block on biicode. It is hoped that eventually this can
become part of the core CMake syntax.

### Discovering test functions ###

Test function discovery is by using the "hidden" `COMMANDS` property of
`GLOBAL` scope. This provides a list of all defined commands at the time
of retrieving the property.