
$Script:BuildVersion = "0.5.1"

<#
.SYNOPSIS
    Create the files, folders and variables necessary to use BuildTool.
.DESCRIPTION
    This script will bootstrap a folder into a BuildTool project.
    It has two purposes.  The first is to create a blank project with all the "stuff"
    setup.  The second would be to "convert" an old project to the new format.

    There are multiple environments the bootstrap might find itself in:
    - There's nothing here yet, just an empty folder and an idea
    - There's some sort of source here, but no buildtools
    - There's source and buildtools, but it's not a submodule
    - There's older buildtools here
#>


function Write-BootstrapHeader {
    <#
    .SYNOPSIS
        Output a friendly outline of the bootstrap process
    #>
    [CmdletBinding()]
    param()
    begin {}
    process {
        Write-Host -ForegroundColor DarkBlue ('=' * 80)
        Write-Host -ForegroundColor DarkBlue "= `u{e7ae} BuildTool Bootstrap script"
        Write-Host -ForegroundColor DarkBlue "= This script will:"
        Write-Host -ForegroundColor DarkBlue "= 0. Configure the git repository"
        Write-Host -ForegroundColor DarkBlue "=    a. If there isn't a git repository yet, initialize a new one"
        Write-Host -ForegroundColor DarkBlue "= 1. Install BuildTool"
        Write-Host -ForegroundColor DarkBlue "=    a. If there is a BuildTool here already but older, upgrade it"
        Write-Host -ForegroundColor DarkBlue "=    b. If it is not present, install it"
        Write-Host -ForegroundColor DarkBlue "=    c. Add BuildTool as a submodule of the current project"
        Write-Host -ForegroundColor DarkBlue "=       2. Add BuildTool as a submodule"

        Write-Host -ForegroundColor DarkBlue "= 2.  Configure BuildTool"
        Write-Host -ForegroundColor DarkBlue "=    a. Ask about the project name, modules, type etc."
        Write-Host -ForegroundColor DarkBlue "=    b. Create the folders, files and settings"
        Write-Host -ForegroundColor DarkBlue ('=' * 80)

        Write-Host -ForegroundColor DarkBlue "+ Step 0: Configure the git repository"
        $currentDir = Get-Item (Get-Location)
        Write-Host -ForegroundColor DarkBlue "|       Project directory name: $($currentDir.BaseName)"
    }
    end {
    }
}

function Build-GitEnvironment {
    <#
    .SYNOPSIS
        Test for a git repository, if there is not one already, create it
    #>
    [CmdletBinding()]
    param(
    )
    begin {
        $git_config = ".\.git\config"
    }
    process {
        Write-Host -ForegroundColor DarkBlue "|       Checking for a git repository ... " -NoNewline
        if (-not(Test-Path $git_config)) {
            Write-Host -ForegroundColor Red "`u{f00d}"
            Write-Host -ForegroundColor Gray "|       It doesn't look like this is a git repository yet"
            $ans = Read-Host -Prompt "|       Do you want to create one now? (y)"
            if ([string]::IsNullOrWhiteSpace($ans)) {
                $createGit = $true
            } elseif ($ans -match '^[yY]') {
                $createGit = $true
            } else {
                $createGit = $false
            }
        } else {
            Write-Host -ForegroundColor Green "`u{f00c}"
        }

        if ($createGit) {
            Write-Host -ForegroundColor Gray "|       Initializing git repository with readme file"
            if (-not(Test-Path ".\README*" )) {
                "# project readme" | set-content "README.md"
            }
            git init | Out-Null

            git add ".\README*" | Out-Null
            git commit -m"Initial import of project" | Out-Null
        }

    }
    end {}
}

function Add-BuildTool {
    <#
    .SYNOPSIS
        Add BuildTool as a submodule
    .DESCRIPTION
        BuildTool is either:
        |Present|Current|Submodule|
        |     0 |     0 |       0 |
        |     1 |     1 |       0 |
        |     1 |     0 |       1 |
        |     1 |     1 |       1 |
        if it isn't present, just add it as a submodule (because we already verified git ... right?)
        if it is present but older, just update it:
    #>
    [CmdletBinding()]
    param(
    )
    begin {
        $buildtool_manifest = ".\build\BuildTool.psd1"
    }
    process {
        Write-Host -ForegroundColor DarkBlue "|       Looking for BuildTools ... " -NoNewline
        if (Test-Path $buildtool_manifest ) {
            Write-Host -ForegroundColor Green "`u{f00c}"
            Write-Host -ForegroundColor DarkBlue "|       Checking the version ... " -NoNewline
            $m = Test-ModuleManifest $buildtool_manifest
            if ($m.Version -lt $Script:BuildToolVersion) {
                Write-Host -ForegroundColor Yellow "`u{f00d}"
                $ans = Read-Host -Prompt "|       $($m.Version) BuildTools is older than $Script:BuildToolVersion.  Upgrade? (y)"
                if ([string]::IsNullOrWhiteSpace($ans)) {
                    $upgradeBT = $true
                } elseif ($ans -match '^[yY]') {
                    $upgradeBT = $true
                } else {
                    $upgradeBT = $false
                }
            } elseif ($m.Version -eq $Script:BuildToolVersion) {
                Write-Host -ForegroundColor Green "`u{f00c}"
                $loadBT = $true
            } else {
                Write-Host -ForegroundColor DarkRed "I think you are using an older bootstrap script"
                Write-Host -ForegroundColor DarkRed "you can get the latest from github at:"
                Write-Host -ForegroundColor White " https://github.com/aldrichtr/BuildTool/blob/main/bootstrap.ps1"
                throw "BuildTool version mismatch"
            }


            Write-Host -ForegroundColor DarkBlue "|       Checking for submodule ... " -NoNewline
            if (git submodule 2>&1 | Select-String 'build') {
                Write-Host -ForegroundColor Green "`u{f00c}"
                Write-Host -ForegroundColor DarkBlue "|       It's already a submodule"
            } else {
                Write-Host -ForegroundColor DarkBlue "|       It's not a submodule yet, so we'll import it"
                git submodule absorbgitdirs 2>&1 | Out-Null
            }

            if ($upgradeBT) {
                Write-Host -ForegroundColor DarkBlue "|       Upgrading BuildTools"
                git submodule update --remote --merge 2>&1 | Out-Null
            }
        } else {
            Write-Host -ForegroundColor Red "`u{f00d}"
            Write-Host -ForegroundColor Gray "|       Adding BuildTool as a submodule in 'build' directory"
            git submodule add 'https://github.com/aldrichtr/BuildTool.git' 'build' 2>&1 | Out-Null
        }

    }
    end {}
}

function Initialize-BuildTool {
    <#
    .SYNOPSIS
        Install or upgrade buildtool and add configuration files
    #>
    [CmdletBinding()]
    param(
    )
    begin {
        $buildtool_manifest = ".\build\BuildTool.psd1"
    }
    process {



        Write-Host -ForegroundColor DarkBlue "+ Step 1: Install BuildTool"
        try {
            Add-BuildTool
        } catch {
            throw $_
        }

        Import-Module $buildtool_manifest -Force
        $btVersion = (Get-Module "BuildTool").Version
        Write-Host -ForegroundColor DarkBlue "|       Repository and BuildTools are ready, Loading BuildTools"
        Write-Host -ForegroundColor Green "|       Loaded `u{E7A2} BuildTools version $btVersion"

        Write-Host -ForegroundColor DarkBlue "+ Step 2: Configure BuildTool"
        Write-Host -ForegroundColor DarkBlue "|       Adding default config files"
        $buildtool_config_dir = ".\.buildtool"
        if (-not (Test-Path $buildtool_config_dir)) {
            Write-Host -ForegroundColor DarkBlue "|       Adding default config directory"
            mkdir $buildtool_config_dir | Out-Null
            Copy-Item ".\build\config\*" $buildtool_config_dir | Out-Null
        } else {
            Write-Host -ForegroundColor DarkRed "|       $buildtool_config_dir already exists"
            Copy-Item ".\build\config\*" ".\.buildtool" -Confirm

        }


    }
    end {
    }
}

function Build-ProjectConfiguration {
    <#
    .SYNOPSIS
        Generate a new configuration file for a build based on inputs from the user
    #>
    [CmdletBinding()]
    param(

    )
    begin {
        $sourceRoot = 'source'

        $config = @{
            Build    = @{
                Path   = 'build'
                Tasks  = 'build/Tasks'
                Rules  = 'build/Rules'
                Tools  = 'build/Tools'
                Config = 'build/Config'
            }

            Plaster  = @{
                Path = 'build/PlasterTemplates'
            }

            Source   = @{
                Path = $sourceRoot
            }

            Docs     = @{
                Path = 'docs'
            }

            Staging  = @{
                Path = 'stage'
            }

            Artifact = @{
                Path = 'out'
            }

            Tests    = @{
                Path   = "tests"
                Config = @{
                    Unit        = './.buildtool/pester.config.unittests.psd1'
                    Analyzer    = './.buildtool/pester.config.analyzertests.psd1'
                    Performance = './.buildtool/pester.config.performancetests.psd1'
                    Coverage    = './.buildtool/pester.config.codecoverage.psd1'
                }
            }
        }

        $dir = ((Get-Location).Path -split [regex]::Escape([IO.Path]::DirectorySeparatorChar))[-1]

    }
    process {
        $projectName = Read-Host -Prompt "|       What is the name of the project ($dir)"
        if ([string]::IsNullOrWhiteSpace($projectName)) {
            $projectName = $dir
        }
        $r = Read-Host -Prompt "|       Is this a multi-module project? (n)"
        if ([string]::IsNullOrWhiteSpace($r)) {
            $multi = $false
        } elseif ($r -match '^[yY]') {
            $multi = $true
        } else {
            $multi = $false
        }
        Remove-Variable -Name r

        $config['Project'] = @{
            Name = $projectName
            Path = (Get-Location).Path
            Type = $multi ? 'multi' : 'single'
        }


        $r = Read-Host -Prompt "|       What is the name of the root module? ($projectName)"
        if ([string]::IsNullOrWhiteSpace($r)) {
            $r = $projectName
        }
        $root = $r

        if ($multi) {
            $nested = @()
            do {
                $n_mod = Read-Host -Prompt "|       Add a nested module to $root : (blank to complete the list)"
                if (-not([string]::IsNullOrWhiteSpace($n_mod))) { $nested += $n_mod }

            } until ([string]::IsNullOrWhiteSpace($n_mod))

            $a = Read-Host -Prompt "|       Any other modules besides $root ?(n)"
            if ([string]::IsNullOrWhiteSpace($a)) {
                $add = $false
            } elseif ($a -match '^[nN]') {
                $add = $false
            } else {
                $add = $true
            }

            if ($add) {
                $additional = @()
                do {
                    $a_mod = Read-Host -Prompt "|       Add an additional module to $root ? (blank to complete the list)"
                    if (-not([string]::IsNullOrWhiteSpace($a_mod))) { $additional += $a_mod }

                } until ([string]::IsNullOrWhiteSpace($a_mod))
            }
        }

        $config.Project['Modules'] = @{
            Root = [ordered]@{
                Name            = $root
                Path            = "$sourceRoot\$root"
                Module          = "$sourceRoot\$root\$root.psm1"
                Manifest        = "$sourceRoot\$root\$root.psd1"
                Types           = @('enum', 'classes', 'private', 'public')
                CustomLoadOrder = ''
            }
        }

        if ($nested.count -gt 0) {
            $config.Project.Modules['Nested'] = @()
            foreach ($n in $nested) {
                $config.Project.Modules.Nested += [ordered]@{
                    Name            = $n
                    Path            = "$sourceRoot\$n"
                    Module          = "$sourceRoot\$n\$n.psm1"
                    Manifest        = "$sourceRoot\$n\$n.psd1"
                    Types           = @('enum', 'classes', 'private', 'public')
                    CustomLoadOrder = ''
                }
            }
        }
        if ($additional.count -gt 0) {
            foreach ($a in $additional) {
                $config.Project.Modules[$a] = [ordered]@{
                    Name            = $a
                    Path            = "$sourceRoot\$a"
                    Module          = "$sourceRoot\$a\$a.psm1"
                    Manifest        = "$sourceRoot\$a\$a.psd1"
                    Types           = @('enum', 'classes', 'private', 'public')
                    CustomLoadOrder = ''
                }
            }
        }

    }
    end {
        $config | ConvertTo-Psd | Set-Content '.\.buildtool\config.psd1'
    }
}

function Initialize-ProjectDirectory {
    <#
    .SYNOPSIS
        Create the project folders
    #>
    [CmdletBinding()]
    param(

    )
    begin {
        $config = Get-BuildConfiguration
    }
    process {
        Write-Host -ForegroundColor DarkBlue "|       Creating Project Directories"
        foreach ($f in @('Source', 'Docs', 'Tests', 'Staging', 'Artifact')) {
            $p = $config.$f.Path
            if (-not(Test-Path $p)) {
                mkdir $p -Force | Out-Null
                Write-Host -ForegroundColor DarkBlue ("|        .. {0,-16} directory : {1}" -f $f, $p)
            } else {
                Write-Host -ForegroundColor DarkGray ("|        .. {0,-16} directory : {1}" -f $f, $p)
            }
        }

    }
    end {}
}

function Initialize-BuildScript {
    <#
    .SYNOPSIS
        Create a "buildtool standard" buildscript in the root of the project
    #>
    [CmdletBinding()]
    param()
    begin {
        $buildScript = ".\.build.ps1"
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
    }
    process {
        Write-Host -ForegroundColor DarkBlue "|       Creating a template build script"
        $build_content | Set-Content $buildScript
        Get-Content ".\build\BuildTool.ps1" | Add-Content $buildScript
    }
    end {
    }
}

function Initialize-ModuleSource {
    <#
    .SYNOPSIS
        Create the directories for Module source files
    #>
    [CmdletBinding()]
    param()
    begin {
        $config = Get-BuildConfiguration
        Write-Host -ForegroundColor DarkBlue "|       Creating Module Directories"
        $project_modules = @()

    }
    process {

        foreach ($k in $config.Project.Modules.Keys) {
            switch ($k) {
                'Root' {
                    $project_modules += [PSCustomObject]$config.Project.Modules.Root
                }
                'Nested' {
                    foreach ($m in $config.Project.Modules.Nested) {
                        $project_modules += [PSCustomObject]$m
                    }
                }
                Default {
                    $project_modules += [PSCustomObject]$config.Project.Modules[$k]
                }
            }
        }


        foreach ($current_module in $project_modules) {
            if (-not(Test-Path $current_module.Path)) {
                Write-Host -ForegroundColor DarkBlue "|        .. Module: $($current_module.Name)"
                mkdir $current_module.Path | Out-Null
            } else {
                Write-Host -ForegroundColor DarkGray "|        .. Module: $($current_module.Name)"
            }
            foreach ($t in $current_module.Types) {
                $typePath = join-path $current_module.Path $t
                if (-not(Test-Path $typePath)) {
                    Write-Host -ForegroundColor DarkBlue "|          .. $($typePath)"
                    mkdir $typePath | Out-Null
                } else {
                    Write-Host -ForegroundColor DarkGray "|          .. $($typePath)"
                }
            }
        }
    }
    end {
    }

}

function Write-BootstrapFooter {
    <#
    .SYNOPSIS
        Write a friendly completion message
    #>
    [CmdletBinding()]
    param()
    begin {}
    process {
        Write-Host -ForegroundColor DarkBlue ('=' * 80)
        Write-Host -ForegroundColor DarkGreen "BuildTool is ready.  type '" -NoNewline
        Write-Host -ForegroundColor White "ib ??" -NoNewline
        Write-Host -ForegroundColor DarkGreen "' to see what tasks are available"
        Write-Host -ForegroundColor DarkGreen "Add your own to '.\.build.ps1'"
    }
    end {}
}

try {
    Write-BootstrapHeader
    Build-GitEnvironment
    Initialize-BuildTool
    Build-ProjectConfiguration
    Initialize-ProjectDirectory
    Initialize-ModuleSource
    Initialize-BuildScript
    Set-Alias ib Invoke-Build
    Write-BootstrapFooter
} catch {
    Write-Error "Could not set up buildtool`n $_"
}
