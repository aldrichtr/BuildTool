<#
.SYNOPSIS
    PowerShell module that loads all source files in the same directory
.DESCRIPTION
    This module file will "dot-source" the files in its parent folder, provided they follow the community convention
    of "public", "private", etc.

    This module "exposes" (that is, make public) all functions, classes and enums which makes them easy to unit
    test, however a production module file "should" contain the source code of the module, not "dot-source" other
    files.

    When modules use more than one enum and/or class, the order in which they are "dot-sourced" is important.
    Therefore, the load order can be controlled by adding relative paths to the source files to a text file named
    'LoadOrder.txt' in the same directory as this file.  blank lines and lines starting with '#' are ignored

    an example text file would look like:

    ```text
    # load the base class before the derived classes
    ./classes/MammalBaseClass.ps1
    ./classes/DogClass.ps1
    ./classes/CatClass.ps1
    ```
    .NOTES
        If you use a LoadOrder.txt file, **only the files listed in the file will be loaded**
#>


$source_directories = @(
    'enum',
    'classes',
    'private',
    'public'
)

$import_options = @{
    Path        = $PSScriptRoot
    Filter      = '*.ps1'
    Recurse     = $true
    ErrorAction = 'Stop'
}


if (Test-Path "$PSScriptRoot\LoadOrder.txt") {
    Write-Host 'Using custom load order'
    $custom = Get-Content "$PSScriptRoot\LoadOrder.txt"
    Get-ChildItem @import_options -Recurse | ForEach-Object {
        $rel = $_.FullName -replace [regex]::Escape("$PSScriptRoot\") , ''
        if ($rel -notin $custom) {
            Write-Warning "$rel is not listed in custom"
        }
    }
    try {
        Get-Content "$PSScriptRoot\LoadOrder.txt" | ForEach-Object {
            switch -Regex ($_) {
                '^\s*$' {
                    # blank line, skip
                    continue
                }
                '^\s*#$' {
                    # Comment line, skip
                    continue
                }
                '^.*\.ps1' {
                    # load these
                    . "$PSScriptRoot\$_"
                    continue
                }
                default {
                    #unrecognized, skip
                    continue
                }
            }
        }
    } catch {
        Write-Error "Custom load order $_"
    }
} else {
    try {
        foreach ($dir in $source_directories) {
            $import_options.Path = (Join-Path $PSScriptRoot $dir)

            Get-ChildItem @import_options | ForEach-Object {
                $currentFile = $_.FullName
                . $currentFile
            }
        }
    } catch {
        throw "An error occured during the dot-sourcing of module .ps1 file '$currentFile':`n$_"
    }
}
