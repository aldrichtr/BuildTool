
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
            Position = 1,
            Mandatory = $true
        )]
        $Name,

        # The module manifest file to update
        [Parameter(
            Position = 2
        )]
        [string]
        $Module,

        # the property to update
        [Parameter(
            Position = 3
        )]
        [string]
        $Property,

        # the new value
        [Parameter(
            Position = 4
        )]
        [string]
        $Value
    )

    task $Name -Data $PSBoundParameters -Source:$MyInvocation {
        try {
            Update-Metadata -Path $Task.Data.Module -PropertyName $Task.Data.Property -Value $Task.Data.Value
        }
        catch {
            $PSCmdlet.ThrowTerminatingError($PSItem)
        }
    }
}
