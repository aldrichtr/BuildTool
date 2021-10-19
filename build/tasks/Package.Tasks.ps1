
# synopsis: create a temporary repository named after the Module
task register_local_artifact_repository {
    $local_repo = @{
        Name         = $ModuleName
        Location     = $Artifact.Path
        Trusted      = $true
        ProviderName = "PowerShellGet"
    }
    Register-PackageSource @local_repo | Out-Null
}

# synopsis: unregister the temporary repo
task remove_temp_repository {
    Unregister-PackageSource -Name $ModuleName -ErrorAction SilentlyContinue
}

# synopsis: a nuget package from the files in Staging.
task publish_to_temp_repository {
    Publish-Module -Path $Staging.Path -Repository $ModuleName
}

# synopsis: remove the module from memory and delete from disk
task uninstall_module {
    Remove-Module -Name $ModuleName -Confirm
    Uninstall-Module -Name $ModuleName
}
