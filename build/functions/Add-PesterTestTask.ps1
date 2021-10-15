
<#
.SYNOPSIS
    Run Pester tests with the given configuration file
.DESCRIPTION
    the pConfig is a path to a psd1 file in the PesterConfiguration schema

    it is meant to be used in conjunction with the test alias.
.EXAMPLE
    test run_unit_tests <module> <path/to/config.psd1>
#>
function Add-PesterTestTask {
    [CmdletBinding()]
    param(
    # The name of the Task
    [Parameter(
        Position = 1,
        Mandatory = $true
    )]
    $Name,

    # The Module file to load (and test against)
    [Parameter(
        Position = 2
    )]
    [string]
    $Module,

    # A file path pointing to a psd1 file with fields and values
    # according to https://pester.dev/docs/commands/New-PesterConfiguration
    [Parameter(
        Position = 2
    )]
    [string]
    $PesterConfig

)
    task $Name -Data $PSBoundParameters -Source:$MyInvocation {
        Import-Module $Task.Data.Module -Force -ErrorAction Stop
        $PesterConfiguration = New-PesterConfiguration -HashTable (Import-Psd $Task.Data.PesterConfig)
        Invoke-Pester -Configuration $PesterConfiguration
    }
}

Set-Alias test Add-PesterTestTask
