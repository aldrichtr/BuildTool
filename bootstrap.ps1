
$Script:BuildVersion = "0.4"

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
        Write-Host -ForegroundColor DarkGray ('=' * 80)
        Write-Host -ForegroundColor DarkGray "= BuildTool Bootstrap script"
        Write-Host -ForegroundColor DarkGray ('=' * 80)
    }
    process {
        Write-Host -ForegroundColor DarkGray "Setting up the build environment"
        <#------------------------------------------------------------------
         # Step 1: Is BuildTool already here?
        ------------------------------------------------------------------#>
        Write-Host -ForegroundColor DarkGray "Looking for BuildTools"
        if (Test-Path $buildtool_manifest ) {
            #TODO: maybe if it's already here we need to redo something?
            Write-Host -ForegroundColor Green "BuildTool is already here"
            Import-Module $buildtool_manifest -Force
            $btVersion = (Get-Module "BuildTool").Version
            Write-Host -ForegroundColor Green " `u{E7A2} BuildTools version $btVersion"
            $btExists = $true
        } else {
            Write-Host -ForegroundColor Red "BuildTool is not installed"
            $btExists = $false
        }


        if (-not(Test-Path ".\.git\config")) {
            Write-Host -ForegroundColor Red "It doesn't look like this is a git repository yet"
            $ans = Read-Host -Prompt "Do you want to create one now? (y)"
            if ([string]::IsNullOrWhiteSpace($ans)) {
                $gitExists = $true
            } elseif ($ans -match '^[yY]') {
                $gitExists = $true
            } else {
                $gitExists = $false
            }
        }

        if (-not($gitExists)) {
            Write-Host -ForegroundColor Gray "Initializing git repository with readme file"
            if (-not(Test-Path ".\README*" )) {
                "# project readme" | set-content "README.md"
            }
            git init

            git add ".\README*"
            git commit -m"Initial import of project"
        }

        if (-not($btExists)) {
            Write-Host -ForegroundColor Gray "Adding BuildTool as a submodule in 'build' directory"
            git submodule add 'https://github.com/aldrichtr/BuildTool.git' 'build'
            $btExists = (Test-Path ".\build\BuildTool.psd1")
        }

        if ($btExists) {
            Write-Host -ForegroundColor DarkGray "Repository and BuildTools are ready, Loading BuildTools"
            Import-Module $buildtool_manifest -Force

            Write-Host -ForegroundColor Green " `u{E7A2} BuildTools version $((Get-Module "BuildTool").Version)"

            Write-Host -ForegroundColor DarkGray "Now, let's configure this project to use buildtool"

            New-BuildConfiguration

            $config = Get-BuildConfiguration -Verbose
            Write-Host -ForegroundColor DarkGray "Creating Directories"
            foreach ($f in @('Source', 'Docs', 'Tests', 'Staging', 'Artifact')) {
                $p = $config.$f.Path
                Write-Host -ForegroundColor Gray " .. $f directory : ./$p"
                if (-not(Test-Path $p)) { mkdir $p -Force }
            }

            Write-Host -ForegroundColor DarkGray "Adding default config files"
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
"@
            $buildScript = ".\.build.ps1"
            Write-Host -ForegroundColor DarkGray "Creating a template build script"
            $build_content | Set-Content $buildScript
            Get-Content ".\build\BuildTool.ps1" | Add-Content $buildScript


        } else {
            Write-Error "Couldn't get BuildTools setup in this folder`n$_"
        }
    }
    end {
    }
}

New-BuildEnvironment
