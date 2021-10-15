
# synopsis: create a temporary repository named after the Module
task register_local_artifact_repository {
    $local_repo = @{
        Name         = $ModuleName
        Location     = $Path.Artifact
        Trusted      = $true
        ProviderName = "PowerShellGet"
    }
    Register-PackageSource @local_repo | Out-Null
}

# synopsis: unregister the temporary repo
task remove_temp_repository {
    Unregister-PackageSource -Name $ModuleName -ErrorAction SilentlyContinue
}

# synopsis: a nuget package from the files in $Path.Staging.  At a minimum,
task publish_to_temp_repository {
    $psd_file = Join-Path -Path $Path.Staging -ChildPath "$ModuleName.psd1"
    $psm_file = Join-Path -Path $Path.Staging -ChildPath "$ModuleName.psm1"

    if ((Test-Path $psd_file) -and (Test-Path $psm_file)) {
        Write-Build Yellow "- Packaging the $ModuleName module"
        Publish-Module -Path $Path.Staging -Repository $ModuleName
    } else {
        Write-Build Red "Required files for packaging were not found"
    }
}

# synopsis: remove the module from memory and delete from disk
task uninstall_module {
    Remove-Module -Name $ModuleName -Confirm
    Uninstall-Module -Name $ModuleName
}
