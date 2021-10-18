# BuildTools : Tools for building powershell modules using Invoke-Build

## Overview

By convention, PowerShell module source projects have the following structure:

 - <ModuleOrProjectName> # top level project folder
   - .vscode # VSCode settings and config
   - build   # the Invoke-Build source files (more on this later!)
   - stage   # a temporary directory to compile and arrange source files.
   - test    # functions and data to test the module.
   - <Module1..N>  # individual folders for each module in the project.

### The build directory

Invoke-Build looks for a `*.build.ps1` file where it is invoked, reads the tasks
and functions in that file, and then executes them according to parameters, command-line
arguments or task names (the default task is named '.' for example).

While the build directory can be the same for almost every project, there usually
tends to be something unique to each project.  BuildTool is an attempt to make
the things that are the same easy, and also provide a means of customizing things
that need to be unique.

It is intended to be used as a git submodule, like so:

``` sh
git submodule add https://github.com/aldrichtr/BuildTool.git ./build
```

### Using BuildTools

once the build directory has been added, just "dot source" BuildTools from your
project's build file like this:

``` powershell
# load all of BuildTools tasks, functions and parameters into the current session
. ./build/BuildTool.ps1

task MyTask {
    # do build things here
}
```

BuildTool comes with several predefined tasks, all of which are usable in your
project like this:

``` powershell
Invoke-Build ? # list all tasks and their synopsis
Invoke-Build Test # run the Test task
```
