
Set-Alias test Add-PesterTestTask

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
        Mandatory = $true
    )]
    $Name,

    # The Module file to load (and test against)
    [Parameter(
    )]
    [string]
    $Module,

    # A file path pointing to a psd1 file with fields and values
    # according to https://pester.dev/docs/commands/New-PesterConfiguration
    [Parameter(
    )]
    [string]
    $PesterConfig

)
    task $Name -Data $PSBoundParameters -Source:$MyInvocation {
        try {
            Import-Module $Task.Data.Module -Force
            $PesterConfiguration = New-PesterConfiguration -HashTable (Import-Psd $Task.Data.PesterConfig)
            Invoke-Pester -Configuration $PesterConfiguration
        } catch {
            Write-Error "$($Task.Name) Couldn't run Pester tests:`
            `nModule: $($Task.Data.Module)`
            `nConfiguration: $($Task.Data.PesterConfig)`n$_"
        }
    }
}
