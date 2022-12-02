---
title: BuildTool Project
url: https://github.com/aldrichtr/buildtool
version: 0.1
status: pre-release
---

## Synopsis

BuildTool is a module, Invoke-Build tasks, and templates designed to help authors of PowerShell modules.

## Description

Most module projects are simple.  There are a set of scripts with functions, classes or enums defined in them, and
these are combined into a *module file* at build time, the manifest is copied (maybe updated a bit) and then they
are packaged into a nupkg file and uploaded to the gallery or internal feed.

For this, a simple build script with `Test`, `Build`, and `Publish` tasks will suffice.  Lately, I have had the need
to do some more complicated things with the build;  I want to organize my source into a root module and one or more
nested modules, or I want to build the module as part of a pipeline that uses the module once it's created...

Also, I have several "processes" that I routinely do as part of my growing collection of public, internal, and
private modules that are similar enough, but usually need some "state information" to complete... like:

- Manage the versioning of the module
- Handle the generation and inclusion of documentation
- Update changelogs, release notes, etc.
- Manage the installation / update of this and other modules upon release
- Manage the assemblies / binaries / included files as part of the module (but not the source)
- Act differently depending on the environment (Dev, QA, Prod) or Local vs CI/CD runner

I've tried several "Build System" modules that I have found, each has a subset of the features I'm looking for, and
many have unique features that I don't find anywhere else.

**Disclaimer**
This project is not meant to be "prescriptive" or a replacement for *your* build system... I'm just trying to make a
build tool that works for me and I'm sharing it with you if you want it...

## "Standards"

- As much as possible, try to follow the PowerShell community's de-facto standards.  This applies to naming,
  directory structure, and default values
- Prefer dynamic discovery over configuration files.  Anywhere `BuildTool` can programmatically find the answer
  (variable value, path, name, etc.), use that.  However,
  - use config files to handle the "non-standard" instances

    For example, the name of the project is most likely the name of the folder that the project is run in... right?
    (but, also sometimes it isn't, so if the config file contains `ProjectName`, use that otherwise, use the folder
    name)
- Only *fail the build* for good reasons.

  Some projects are internal, "behind the scenes" modules. They have a version (probably) but the Changelog /
  Release notes are not part of the workflow.  For these, a missing Changlog is maybe a build log entry, but the
  build doesn't ***fail***

  On the other hand, a module that I publish to PSGallery better have Release Notes or that build *should* fail...
