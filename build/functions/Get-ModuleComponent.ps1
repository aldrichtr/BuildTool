<#
.SYNOPSIS
    Provide a list of components base on the filenames
    in the source directory provided
.DESCRIPTION
    This function depends on the current module conforming to the convention
    of putting one function per file in folders 'public' or 'private' and
    classes and enums in files similarly named.
#>
Function Get-ModuleComponent {
    [CmdletBinding()]
    param(
        # The path to the module source directory
        [Parameter(
            Position = 1,
            Mandatory = $true,
            ValueFromPipeline = $true
        )]
        [string]
        $Path,

        # The type of component to get
        [Parameter(
            Mandatory = $false,
            ValueFromPipeline = $true
        )]
        [ValidateSet('public', 'private', 'classes', 'enum', 'data')]
        [string]
        $Type = 'public'
    )
    begin {
        $components = [System.Collections.ArrayList]::new()
    }
    process {
        Get-ChildItem "$Path\$Type" -File -Filter "*.ps1" -Recurse | ForEach-Object {
            $name = $_.BaseName -replace '^\d*_', ''
            $components.Add($name) | Out-Null
        }
    }
    end {
        $components
    }
}
