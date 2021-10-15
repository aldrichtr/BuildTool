
<#
.SYNOPSIS
    Invoke-Build scripts and utilities
.DESCRIPTION
    BuildTools is a collection of functions, tasks and templates that can be
    used to build PowerShell modules and scripts
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
    $BuildRoot = $BuildRoot,

    # This is the module name used in many directory, file and script
    # functions
    [Parameter()]
    [string]
    $ModuleName = ((Get-Item -Path $BuildRoot).BaseName),

    # Define specific tests to be run, empty string runs all tests
    [Parameter()]
    [string[]]
    $TestTags = "",

    # Define tests to be excluded
    [Parameter()]
    [Alias("Exclude")]
    [string[]]
    $ExcludeTestTags = @("ignore", "exclude"),

    # Test output verbosity
    [Parameter()]
    [ValidateSet("None", "Minimal", "Normal", "Detailed", "Diagnostic")]
    [string]
    $TestOutput = "Minimal",

    # Module component types
    [Parameter()]
    [string[]]
    $SourceTypes = @('enum', 'classes', 'private', 'public'),

    # Load source files in a custom order
    # list filepaths in a file, one per line
    [Parameter()]
    [string]
    $CustomLoadOrder = '',

    # Default directory conventions, used throughout tasks and functions
    [Parameter()]
    [Hashtable]
    $Path = @{
        'Staging'            = "$BuildRoot\stage\$ModuleName"
        'Tools'              = "$BuildRoot\tools"
        'Source'             = "$BuildRoot\$ModuleName"
        'SourceModule'       = "$BuildRoot\$ModuleName\$ModuleName.psm1"
        'SourceManifest'     = "$BuildRoot\$ModuleName\$ModuleName.psd1"
        'Test'               = "$BuildRoot\test"
        'Build'              = "$BuildRoot\build"
        'BuildOutput'        = "$BuildRoot\artifact"
        'Artifact'           = "$BuildRoot\artifact"
        'TestResultFile'     = "$BuildRoot\artifact\pester.xml"
        'ModuleFile'         = "$BuildRoot\stage\$ModuleName\$ModuleName.psm1"
        'ModuleManifestFile' = "$BuildRoot\stage\$ModuleName\$ModuleName.psd1"
    },

    # Build Type
    [Parameter()]
    [ValidateSet("Testing", "Debug", "Release")]
    [string]
    $Type = "Testing"
)


Get-ChildItem -Path "$BuildRoot\build\functions" -Filter "*.ps1" -Recurse | ForEach-Object {
    try {
         . $_.FullName
    }
    catch {
        $PSCmdlet.ThrowTerminatingError($PSItem)
    }
}
Get-BuildTask -Path "$BuildRoot\build\tasks" -Recurse | ForEach-Object {
    try {
        . $_
   }
   catch {
       $PSCmdlet.ThrowTerminatingError($PSItem)
   }
}

. "$BuildRoot\build\phases.ps1"

# write helpful output
task help {
    Write-Build Gray ('=' * 80)
    Write-Build Gray "# `u{E7A2} PowerShell BuildTools "
    Write-Build Gray "# BuildTools project running in '$BuildRoot'"
    Write-Build Gray ('=' * 80)
}

# synopsis: If no task is defined, run this
task . help
