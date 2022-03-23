# PowerShell module conventions

This template uses several conventions for directory structure, build scripts
and testing.

## Directory structure


### Source files

A directory named `<modulename>` holds all of the source code for the module.  The
rest of the files and directories are for the tools and processes to develop,
build, test, deploy and maintain the module.

Each function, class, and enum that is part of the module is in it's own file,
and the files are organized into directories that denote the type.

- Public: Functions that should be exported at build time
- Private: Functions that are part of the module, but are not exported
- Enum: Enum types and flags
- Class: Powershell Classes
- Module file (.psm1): When imported, the module file dot-sources all the .ps1
  files in the sub-directories.  All functions are exported so that tests can
  access the function.
- Module Manifest (.psd1): Contains the basic information for the module, and
  is used to populate some metadata about the module once it is built, such as
  the version, tags, author, etc.

### Tests

the `test` directory contains Pester tests, contained in files named .Tests.ps1
tests can be included or excluded using tags and parameters given to
Invoke-Build at run-time.

### Build

The build system uses Invoke-Build, `modulename.build.ps1` defines the
parameters used by the build, and the major tasks such as Clean, Test, Build,
etc.  These tasks are made up of individual tasks found in .\build\*.Tasks.ps1

the `.build.ps1` file is called by Invoke-Build.  There are several
parameters that can be passed to the build:

- BuildRoot: Provides the ability to override the default build root for
  hierarchical builds.
- ModuleName: Used in several Tasks for paths, file names, etc.
- TestTags: If set, Invoke-Pester will only run tests that have the given tags.
- ExcludeTestTags: If set, Invoke-Pester will skip tests with the given tags (
  'ignore', 'exclude' are set by default.
- TestOutput: Control the verbosity of Invoke-Pester
- Path: A hashtable of standard path conventions.  Tasks are written to look in
  these paths for input, output, and naming.
- Type: The build type, can be Testing, Debug or Release.  Tasks can use this to
  decide on additional steps, such as additional output on a Debug build, or
  additional tests for formating, documentation, etc in a Release.

## Development workflow

1. Create a module project
2. Add code
3. Test the code
4. Stage the code
5. Run additional tests
6. Build
7. Publish

During development and testing, the files in the source directory are used. When
the module has the desired functionality, Stage the code.  Do any additional
testing, formatting, analysis, etc.  When the staged code has the desired
functionality and quality, Build it into a nuget package.  Publish the nuget
package to the repository.

### Create a module project

To start on a new PowerShell module, run the Plaster template, providing answers
as required.  This will create the directory structure outlined above.

### Add code

Write your .ps1 files and Tests.ps1 files in the appropriate directories

### Test the code

Run `Invoke-Build Test`

### Stage the code

Create a `stage\<modulename>` directory, create a "built" module file.  That is,
copy all of the source files into a new .psm1 file (a production module
shouldn't dot-source).  Create the module manifest (.psd1) set the functions in the 'public' directory as exported.  This is the dir

## A note about 'ModuleName' Directories

There are a lot of directories named after the module.  The first design
decision was to name the 'source' directory `modulename` instead of Source,
source or src.  The main influence behind that was the potential that one
project might have more than one module's source in it.  I could have used
src\module_one, src\module_two, etc. but it seems cleaner to have the name there
in the root directory.  You could just pull that one directory out, and you'd
have the source of the module, already well named and packaged for inclusion in
another project.

Next is the stage\modulename folder.  Same concept here... the resulting module,
manifest and binaries etc are all packaged in a well named directory.  Also,
this makes it an easy target for the packaging of the module using nuget.

A lot of this redundant naming should be hidden from the developer in the
majority of the dev-cycle anyway.  It's only when you have to go poking around
inside the project that you run into them.
