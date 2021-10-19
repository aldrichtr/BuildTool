# synopsis: Copy the source manifest file to staging
task stage_source_manifest {
    Copy-Item -Path $Source.Path -Destination $Staging.Path
}

# synopsis: Update the 'FunctionsToExport' using the names of the files in the Public folder
manifest update_exported_functions `
    -Module $Source.Manifest `
    -Property 'FunctionsToExport' `
    -Value (Get-ModuleComponent -Type public -Path $Source.Path -ErrorAction SilentlyContinue)




# synopsis: Update the 'AliasesToExport' using the public/Aliases.ps1
manifest update_exported_aliases `
    -Module $Staging.Manifest `
    -Property 'AliasesToExport' `
    -Value (Get-Content "$($Source.Path)\public\Aliases.ps1" -ErrorAction SilentlyContinue)
