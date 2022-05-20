#region Module tasks

# synopsis: Create the module file in staging from source files
task make_staging_module copy_source_content_to_psm1

# synopsis: Assemble the contents of individual source files into the psm1 file
task copy_source_content_to_psm1 {
    # keep track of how many files were imported
    $c = Get-BuildConfiguration
    $modules = Get-ModuleList
    New-Item -itemtype Directory -Path "$($c.Staging.Path)\$($c.Project.Name)" -Force
    foreach ($m in $modules) {
        $staging_module = "$($c.Staging.Path)\$($c.Project.Name)\$($m.Name).psm1"
        Set-Content -Path $staging_module -Value ("#" * 80)
        Add-Content -Path $staging_module -Value "# $($m.Name) : $([datetime]::Now)`n`n"
        $sources = Get-SourceItem "$($c.Project.Path)\$($m.Path)"
        foreach ($t in $m.Types) {
            "#region $t Section" | Add-Content $staging_module
            $sources | Where-Object -Property Visibility -eq $t | Add-ModuleContent $staging_module
            "#endregion $t Section" | Add-Content $staging_module
        }
    }
}
#endregion Module tasks


#region Manifest tasks

# synopsis: Create a module manifest in the staging directory.
task make_staging_manifest {
    $c       = Get-BuildConfiguration
    $modules = Get-ModuleList
    $r       = $modules | Where-Object -Property Root -eq $true
    $nested  = $modules | Where-Object -Property Root -eq $false

    $ex_functions = @()

    $staging_manifest = (Join-Path $c.Project.Path ($r.Manifest -replace $c.Source.Path, $c.Staging.Path))
    copy-item (Join-Path $c.Project.Path $r.Manifest) $staging_manifest
    Write-Build Blue "Staging Manifest : $staging_manifest"

#    $mani = Test-ModuleManifest $staging_manifest

    foreach ($m in $modules) {
        $ex_functions += Get-SourceItem (Join-Path $c.Project.Path $m.Path) | where-object {
            $_.Visibility -like 'public' } | Select -ExpandProperty Name
    }

    $module_options = @{
        Path              = $staging_manifest
        RootModule        = "$($r.Name).psm1"
        FunctionsToExport = $ex_functions
    }
    if ($nested.Length -gt 0) {
        $n_mod = ($nested | select -Property Name -ExpandProperty Name) | Foreach-Object { "$_.psm1" }
        $module_options.NestedModules     = $n_mod
    }
    Update-ModuleManifest @module_options
}
