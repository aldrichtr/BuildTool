#region Local Repository

# synopsis: create a temporary repository named after the Module
task register_local_artifact_repository {
    $c = Get-BuildConfiguration
    $repo_path = (Join-Path (Join-Path $c.Project.path $c.Artifact.Path) $c.Project.Name)
    if (-not(Test-Path $repo_path)) { mkdir $repo_path -Force | Out-Null}
    $local_repo = @{
        Name         = $c.Project.Name
        Location     = $repo_path
        Trusted      = $true
        ProviderName = "PowerShellGet"
    }
    Register-PackageSource @local_repo | Out-Null
}

# synopsis: unregister the temporary repo
task remove_temp_repository {
    $c = Get-BuildConfiguration
    if ((Get-PackageSource | Select-Object -ExpandProperty Name) -contains $c.Project.Name) {
        Unregister-PackageSource -Name $c.Project.Name
    }
}

# synopsis: a nuget package from the files in Staging.
task publish_to_temp_repository {
    $c = Get-BuildConfiguration
    $staging_dir = Join-Path $c.Staging.Path $c.Project.Name
    Publish-Module -Path $staging_dir -Repository $c.Project.Name
}
#endregion Local Repository

#region Uninstall

# synopsis: remove the module from memory and delete from disk
task uninstall_module {
    $c = Get-BuildConfiguration
    Remove-Module -Name $c.Project.Name -Confirm
    Uninstall-Module -Name $c.Project.Name
}
#endregion Uninstall
