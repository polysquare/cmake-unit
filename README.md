 CMake Unit
==========

A unit testing framework for CMake.

Why?
====

Because CMake is a powerful and battle-tested language for writing build systems for large-scale C++ projects, but its dynamic nature makes it easy to make undetectable errors which later ship as bugs that either you, or the users of your macros, need to work around. We have to put a lot of logic inside out CMake scripts sometimes, like propogation of global state, if conditions for various options and host system configurations and loops over variable argument lists.

It is something you want to get right the first time rather than having to scratch your head about it later with the lack of debugging tools for CMake scripts.

Usage
=====

cmake-unit should be included as a submodule in your project and comes with two macros.

CMakeUnitRunner
-----------

`CMakeUnitRunner` contains the main "runner" script for loading and executing test scripts. Include this file in the `CMakeLists.txt` which is in the same directory as your test scripts.

`add_cmake_test` create a CTest test which will load the specified script (with the `.cmake` extension removed) as though it were an actual CMake project, so that you have full access to the cache. From here, you can include your other macros and set up a small project in order to exercise them. Your project will not be built, only configured.

`add_cmake_build_test` is the slightly more heavyweight version of `add_cmake_test`. It takes both the name of a script to perform the configure step and the name of a script which is executed *as a script* (not as a project) after the build completes. This can be used to check that a project was built in the expected way.

CMakeUnit
---------

`CMakeUnit` contains matchers and assertions. They aren't written in true xUnit style due to the inability to capture function names in variables in later call them in CMake. You can use them in both the configure and verify stages. If the script hits an assertion failure, it will call `message (SEND_ERROR)`.

The following assertions are available at the time of writing this documentation

 - `assert_target_exists`, `assert_target_does_not_exist`: Asserts that the target provided as the first argument exists or does not exist.
 - `assert_string_contains`, `assert_string_does_not_contain`: Asserts that the second string is a substring of the first.
 - `assert_variable_is`, `assert_variable_is_not`: Asserts that the variable specified matches some of the parameters provided. A variable name, type, comparator statement (`EQUAL` `LESS` `GREATER`) and value to compare against can be provided.
 - `assert_variable_matches_regex`, `assert_variable_does_not_match_regex`: Asserts that the value provided when treated as a string matches the regex provided in the second argument.
 - `assert_variable_is_defined`, `assert_variable_is_not_defined`: Asserts that a variable was or was not defined
 - `assert_command_executes_with_success`, `assert_command_does_not_execute_with_sucess`: For a command and each of its arguments encapsulated in the list passed-by-variable (as opposed to by value), check if it executed with success.
 - `assert_target_is_linked_to`, `assert_target_is_not_linked_to`: Asserts that the target has a link library that matches the name specified by the second argument. It does regex matching to ensure that in the default case, libraries with slightly inexact names between platforms are still matched against.
 - `assert_has_property_with_value`, `assert_does_not_have_property_with_value`: Asserts that the item specified with the item type specified has property with a value and type specified which matches the provided comparator.
 - `assert_has_property_containing_value`, `assert_does_not_have_property_containing_value`: Like `assert_has_property_with_value` but looks inside items in a list held by the proeprty.
 - `assert_file_exists`, `assert_file_does_not_exist`: Asserts that a file exists on the filesystem.
 - `assert_file_contains`, `assert_file_does_not_contain`: Asserts that a file contains the substring specified.
