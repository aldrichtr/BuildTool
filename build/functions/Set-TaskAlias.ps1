
<#
.SYNOPSIS
    Extend the Invoke-Build DSL using the PowerShell Alias functionality
.DESCRIPTION
    Invoke-Build uses several aliases to make a build DSL, such as:
    task      ->  Add-BuildTask
    exec      -> Invoke-BuildExec
    assert    -> Assert-Build
    equals    -> Assert-BuildEquals
    remove    -> Remove-BuildItem
    property  -> Get-BuildProperty
    requires  -> Test-BuildAsset
    use       -> Use-BuildAlias
    error     -> Get-BuildError
#>

Set-Alias test Add-PesterTestTask

Set-Alias manifest Update-ManifestTask
