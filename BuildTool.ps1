
<#
.SYNOPSIS
    Invoke-Build scripts and utilities
.DESCRIPTION
    BuildTools is a collection of functions, tasks and templates that can be
    used to build PowerShell modules and scripts.  BuildTool has several
    components:
    - functions : Traditional PowerShell functions that extend or supplement
                  Invoke-Build tasks.
    - tasks : Invoke-Build tasks defined in Tasks.ps1 files are loaded at run-
              time, and are available to other tasks.
    - templates : Plaster templates and basic file templates for use in making
                  build artifacts.
    - tools : additional functions and scripts, not loaded at runtime, but
              available to run.
    - config : configuration settings for functions and tasks.

    To use BuildTools in your project, simply add it as a submodule like so:
    git submodule add <buildtools-repo> build
    # create a <projectname>.build.ps1 in the root directory
    #  with '. ./build/BuildTools.ps1' at the top
.EXAMPLE
    > Invoke-Build ?
    > lists all tasks available
#>
[CmdletBinding()]
param(
    # BuildRoot is automatically set by Invoke-Build, but it could
    # be modified here so that hierarchical builds can be done
    [Parameter()]
    [string]
    $BuildRoot = (property BuildRoot $BuildRoot),

    # BuildTools is ./build by default (if you followed the README)
    [Parameter()]
    [string]
    $BuildTools = (property BuildTools "$BuildRoot\build"),

    # BuildTools header output
    [Parameter()]
    [ValidateSet('minimal', 'normal', 'verbose')]
    [string]
    $Header = (property Header 'verbose'),

    # Custom configuration settings file
    [Parameter()]
    [string]
    $ConfigFile = (property ConfigFile ""),

    # an array of paths to additional task files
    [Parameter()]
    [string[]]
    $TaskFiles = (property TaskFiles @("$BuildTools\tasks")),

    # This is the module name used in many directory, file and script
    # functions
    [Parameter()]
    [string]
    $ModuleName = (property ModuleName (Get-Item -Path $BuildRoot).BaseName),

    # Build Type
    [Parameter()]
    [ValidateSet("Testing", "Debug", "Release")]
    [string]
    $Type = (property Type "Testing"),

    # Name of the module file (<modulename>.psm1 by default)
    # this name is added to path parameters such as Source.Path, etc.
    # Relies on $ModuleName being set prior to invocation.
    [Parameter()]
    [string]
    $ModuleFile = (property ModuleFile "$ModuleName.psm1"),

    # Name of the module manifest file (<modulename>.psd1 by default)
    # this name is added to path parameters such as Source.Path, etc.
    # Relies on $ModuleName being set prior to invocation.
    [Parameter()]
    [string]
    $ModuleManifestFile = (property ModuleManifestFile "$ModuleName.psd1"),

    # A hash of values related to the source files.
    # - Path : by default looks in './<modulename>'
    # - Module : the path to the Source psm1
    # - Manifest : the path to the Source psd1
    # - Types :  an array of source types which assumes the convention of
    #           one function or type per file, organized in directories.
    #           'enum', 'classes', 'private', 'public' by default
    # - CustomLoadOrder : path to a file containing the source file paths in the
    #                     order to be loaded (one file path per line)
    [Parameter()]
    [Hashtable]
    $Source = (property Source @{
            Path            = "$BuildRoot\$ModuleName"
            Module          = ""
            Manifest        = ""
            Types           = @('enum', 'classes', 'private', 'public')
            CustomLoadOrder = '$BuildRoot\$ModuleName\LoadOrder.txt'
        }),

    # A hash of values related to the documentation
    # - Path : ./docs by default
    [Parameter()]
    [hashtable]
    $Docs = (property Docs @{
            Path = "$BuildRoot\docs"
        }),

    # A hash of values related to the additional tools and scripts
    # - Path : ./tools by default
    [Parameter()]
    [hashtable]
    $Tools = (property Tools @{
            Path = "$BuildRoot\tools"
        }),

    # A hash of values related to the test harness
    # - Path : ./tests by default
    # - Config : A hash of paths to the pester configuration files (.psd1)
    #   - Unit : the basic unit tests to validate code.
    #   - Analyzer : the tests that analyze code according to the
    #                PSScriptAnalyzer rules
    #   - Performance : the tests that analyze performance metrics of the code
    #   - Coverage : generate a code coverage report
    [Parameter()]
    [hashtable]
    $Tests = (property Tests @{
            Path   = "$BuildRoot\tests"
            Config = @{
                Unit        = "$BuildTools\config\pester.config.unittests.psd1"
                Analyzer    = "$BuildTools\config\pester.config.analyzertests.psd1"
                Performance = "$BuildTools\config\pester.config.performancetests.psd1"
                Coverage    = "$BuildTools\config\pester.config.codecoverage.psd1"
            }
        }),

    # A hash of values related to staging. (merging source files, updating the
    # manifest, additional testing, etc.)
    # - Path : by default looks in './stage'
    # - Module : the path to the staged psm1
    # - Manifest : the path to the staged psd1
    [Parameter()]
    [hashtable]
    $Staging = (property Staging @{
            Path     = "$BuildRoot\stage"
            Module   = ""
            Manifest = ""
        }),

    # A hash of values related to the artifact directory.
    # the nuget package, additional documentation, test results, etc.
    # - Path : ./artifact by default
    [Parameter()]
    [hashtable]
    $Artifact = (property Artifact @{
            Path = "$BuildRoot\artifact"
        })
)
## fixup some self referencing hash keys
if ($Source.Module -eq '') {$Source.Module = "$($Source.Path)\$ModuleFile"}
if ($Source.Manifest -eq '') {$Source.Manifest = "$($Source.Path)\$ModuleManifestFile"}
if ($Staging.Module -eq '') {$Staging.Module = "$($Staging.Path)\$ModuleFile"}
if ($Staging.Manifest -eq '') {$Staging.Manifest = "$($Staging.Path)\$ModuleManifestFile"}

$BuildToolsDefaultConfig = (Get-Item "$BuildTools\config\buildtools.defaults.ps1")
$LoadStatus = @{
    Configs   = @{
        Path    = @()
        Success = $false
        Custom  = $false
    }
    Functions = @{
        Path    = @()
        Success = $false
    }
    Tasks     = @{
        Path    = @()
        Success = $false
    }
}

# Before we do anything else, load the default parameters, and the custom
# configuration file if specified
try {
    . $BuildToolsDefaultConfig.FullName
    $LoadStatus.Configs.Path += $BuildToolsDefaultConfig

    if (Test-Path $ConfigFile) {
        $Custom = Get-Item $ConfigFile
        $LoadStatus.Configs.Custom = $true
        $LoadStatus.Configs.Path += $Custom
        . $Custom.FullName
        $LoadStatus.Configs.Success = $true
    }
    $LoadStatus.Configs.Success = $true
} catch {
    $LoadStatus.Configs.Success = $false
}

# Now, Load all the functions that are used by tasks
Get-ChildItem -Path "$BuildTools\functions" -Filter "*.ps1" -Recurse | ForEach-Object {
    try {
        $LoadStatus.Functions.Path += $_
        . $_.FullName
        $LoadStatus.Functions.Success = $true
    } catch {
        $LoadStatus.Functions.Success = $false
    }
}


Get-BuildTask -Path $TaskFiles -Recurse | ForEach-Object {
    try {
        $LoadStatus.Tasks.Path += $_
        . $_.FullName
        $LoadStatus.Tasks.Success = $true
    } catch {
        $LoadStatus.Tasks.Success = $false
    }
}

# TODO: Move this into the TaskFiles array, or into the tasks folder.
. "$BuildTools\phases.ps1"

Enter-Build {
    Write-Build Gray ('=' * 80)
    Write-Build Gray "# `u{E7A2} PowerShell BuildTools "
    Write-Build Gray "# BuildTools project running in '$BuildRoot'"
    if ($Header -ne 'minimal') {
        if ($LoadStatus.Configs.Success) {
            Write-Build Gray "Configured from:"
            $LoadStatus.Configs.Path | ForEach-Object {
                Write-Build Gray " - $($_ | Resolve-Path -Relative)"
            }
        }
        if ($LoadStatus.Functions.Success) {
            Write-Build Gray "Additional functions:"
            $LoadStatus.Functions.Path | ForEach-Object {
                Write-Build Gray " - $($_ | Resolve-Path -Relative)"
            }
        }
        if ($LoadStatus.Tasks.Success) {
            Write-Build Gray "Tasks loaded from:"
            $LoadStatus.Tasks.Path | ForEach-Object {
                Write-Build Gray " - $($_ | Resolve-Path -Relative)"
            }
        }
    }
    if ($Header -like 'verbose') {
        Write-Build Gray "Project directories:"
        ("Source", "Tests", "Docs", "Staging", "Artifact") | ForEach-Object {
            $projPath = (Get-Variable $_ -ValueOnly)['Path']
            if (Test-Path $projPath) {
                Write-Build Gray (" - {0,-16} {1}" -f $_, ((Get-Item $projPath) |
                        Resolve-Path -Relative -ErrorAction SilentlyContinue))
            } else {
                Write-Build DarkGray (" - {0,-16} {1}" -f $_, "(missing) $projPath" )
            }
        }
    }
    Write-Build Gray ('=' * 80)
}
Exit-Build { Write-Build DarkBlue "Exit-Build after the last task`n$('.' * 78) $Result`n$('.' * 78)" }
# Enter-BuildTask { Write-Build DarkBlue "Enter-BuildTask - before each task"}
# Exit-BuildTask { Write-Build DarkBlue "Exit-BuildTask - after each task" }
# Enter-BuildJob { Write-Build DarkBlue "Enter-BuildJob - before each task action"}
# Exit-BuildJob { Write-Build DarkBlue "Exit-BuildJob - after each task action"}
Set-BuildHeader { param($Path) Write-Build DarkBlue "[X] Task $Path --- $(Get-BuildSynopsis $Task)" }
# Set-BuildFooter {param($Path)}


# write helpful output
task help {
    Write-Build Red "The build type: $Type"
    # $all = Invoke-Build ??
    # foreach ($t in $all.Keys) {
    #     Write-Build DarkBlue "$t"
    # }
}
