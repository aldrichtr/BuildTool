
<#
.SYNOPSIS
    Returns component information based on the directory names of the input
.DESCRIPTION
    `Get-SourceComponent` makes some assumptions about your source directory
    first, you name the top level folder the visibility (private, public, etc.)
    and second, you organize files into "components" like:
    PSRocketShip
      - public
        - Engine
          - Set-Thrust.ps1
          - Get-Temperature.ps1
.NOTES
    This is useful in organizing source files in other functions, such as pester
    tests.
.EXAMPLE
     PS C:\> Get-ChildItem -Path "my/source/folder" -Filter "*.ps1" | Get-SourceComponent
     Visibility    Name    Sub    Verb    Noun
     public        Engine         Set     Thrust
     public        Engine         Get     Temperature
#>
Function Get-SourceComponent {
    [CmdletBinding()]
    param(
        # Item object of source file
        [Parameter(
            Mandatory = $true,
            ValueFromPipeline = $true
        )]
        [System.IO.FileInfo[]]
        $Path
    )
    begin {
        $Components = [System.Collections.ArrayList]::new()
    }
    process {
        foreach ($item in $Path) {
            $relPath = $item.DirectoryName -replace [regex]::Escape("$($Source.Path)\"), ''
            $elements = $relPath -split '\\'
            $Component = [PSCustomObject]@{
                Path       = $item.FullName
                Name       = $item.BaseName
                Visibility = $elements[0]
                Type       = $elements[1]
                Sub        = ''
                Verb       = ''
                Noun       = ''
            }
            if ($elements.Length -gt 2) {
                $Component.Sub = $elements[2..($elements.Length)] -join '\'
            }
            if ($item.BaseName.IndexOf('-') -gt -1) {
                $Component.Verb, $Component.Noun = $item.BaseName -split '-'
            } else {
                $Component.Noun = $item.BaseName
            }
            $Components += $Component
        }
    }
    end {
        $Components
    }
}
