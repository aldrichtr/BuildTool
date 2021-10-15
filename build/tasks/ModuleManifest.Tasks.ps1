
# synopsis: Update the 'FunctionsToExport' using the names of the files in the Public folder
manifest update_exported_functions `
    -Module $Path.ModuleManifestFile `
    -Property 'FunctionsToExport' `
    -Value (Get-ModuleComponent -Type public -Path $Path.Source -ErrorAction SilentlyContinue)




# synopsis: Update the 'AliasesToExport' using the public/Aliases.ps1
manifest update_exported_aliases `
    -Module $Path.ModuleManifestFile `
    -Property 'AliasesToExport' `
    -Value (Get-Content "$($Path.Source)\public\Aliases.ps1" -ErrorAction SilentlyContinue)
