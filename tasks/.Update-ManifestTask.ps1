
Set-Alias manifest Update-ManifestTask

<#
.SYNOPSIS
    Set the value specified in the Manifest file
.DESCRIPTION
    `Update-ManifestTask` is meant to be used in conjunction
    with the `manifest` alias.
.EXAMPLE
    manifest update_exported_functions <module> <property> <value>
#>
function Update-ManifestTask {
    [CmdletBinding()]
    param(
        # The name of the Task
        [Parameter(
            Mandatory = $true
        )]
        $Name,

        # The module manifest file to update
        [Parameter()]
        [string]
        $Manifest,

        # the property to update
        [Parameter()]
        [string]
        $Property,

        # the new value
        [Parameter()]
        [string[]]
        $Value
    )

    task $Name -Data $PSBoundParameters -Source:$MyInvocation {
        if ( -not(Test-Path $Task.Data.Manifest)) {
            Write-Error "Can't find $($Task.Data.Manifest)"
        }
        try {
            Update-Metadata -Path $Task.Data.Manifest -PropertyName $Task.Data.Property -Value $Task.Data.Value
        }
        catch {
            $PSCmdlet.ThrowTerminatingError( ("Updating manifest",
            $Task.Data.Manifest,
            $Task.Data.Property, "to", $Task.Data.Value, "`n",
            $PSItem) -join ' ')
        }
    }
}
