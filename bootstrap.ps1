

function New-BuildEnvironment {
    <#
    .SYNOPSIS
        Create the files, folders and variables necessary to use BuildTool.
    .DESCRIPTION
        This function is part of the bootstrap process.  It can be part of buildtool, but
        I would need to grab it separately (from the "blob url"?) and run it.

        It has two purposes.  The first is to create a blank project with all the "stuff"
        setup.  The second would be to "convert" an old project to the new format.
    #>
    [CmdletBinding()]
    param(
    )
    begin {
        $buildtool_manifest = ".\build\BuildTool.psd1"
    }
    process {
        Write-Host -ForegroundColor Gray "Setting up the build environment"
        Write-Host -ForegroundColor Gray "Looking for BuildTools"

        if (-not(Test-Path $buildtool_manifest )) {

            Write-Host -ForegroundColor Red "BuildTool is not installed"
            if (-not(Test-Path ".\.git\config")) {
                Write-Host -ForegroundColor Red "It doesn't look like this is a git repository yet"
                $ans = Read-Host -Prompt "Do you want to create one now? (y)"
                if ([string]::IsNullOrWhiteSpace($ans)) {
                    $init = $true
                } elseif ($ans -match '^[yY]') {
                    $init = $true
                } else {
                    $init = $false
                }
            }

            if ($init) {
                Write-Host Gray "Initializing git repository with readme file"
                if (-not(Test-Path ".\readme*" )) {
                    "# project readme" | set-content "README.md"
                }
                git add ".\readme*"
                git commit -m"Initial import of project"
            }

            Write-Host -ForegroundColor Gray "Adding BuildTool as a submodule in 'build' directory"
            git submodule add 'https://github.com/aldrichtr/BuildTool.git' 'build'
        }

        Import-Module $buildtool_manifest -Force
        Write-Host -ForegroundColor Green " `u{E7A2} BuildTools version $((Get-Module "BuildTool").Version)"

        Write-Host -ForegroundColor Gray "Configure buildtool"

        New-BuildConfiguration

        $config = Get-BuildConfiguration
        Write-Host -ForegroundColor Gray "Creating Directories"
        foreach ($f in @('Source', 'Docs', 'Tests', 'Staging', 'Artifact')) {
            $p = $config.$f.Path
            Write-Host -ForegroundColor Gray " .. $f directory : $p"
            mkdir $p -Force
        }

        Write-Host -ForegroundColor Gray "Adding default config files"
        Copy-Item ".\build\config\*" ".\.buildtool"

        $build_content = @"
        param (
            # BuildRoot is automatically set by Invoke-Build, but it could
            # be modified here so that hierarchical builds can be done
            [Parameter()]
            [string]`$BuildRoot = `$BuildRoot,

            [Parameter()]
            [string]`$BuildTools = `"`$BuildRoot\build`",

            # This is the module name used in many directory, file and script
            # functions
            [Parameter()]
            [string]`$ModuleName = "`"$($config.Project.Name)`""
        )

        . `"`$BuildTools\BuildTool.ps1`"
"@

        $build_content | Set-Content ".\.build.ps1"
    }
    end {
    }
}

New-BuildEnvironment
