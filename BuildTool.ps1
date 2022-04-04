

$config = "$PSScriptRoot\config\buildtool.defaults.ps1"

try {
    . $config
    # Now, Load all the functions that are used by tasks
    Import-Module "$BuildRoot\source\BuildTool\BuildTool.psd1" -Force -ErrorAction Stop
} catch {
    Write-Error "Couldn't load BuildTool"
}

$c = Get-BuildConfiguration

Get-BuildTask -Path "$BuildTools\tasks" -Recurse | ForEach-Object {
    $fileName = $_.Name
    try {
        . $_.FullName
    } catch {
        Write-Error "Couldn't load $fileName`n$_"
    }
}

Enter-Build {
    Write-Build Gray ('=' * 80)
    Write-Build Gray "# `u{E7A2} PowerShell BuildTools "
    Write-Build Gray "# BuildTools project running in '$BuildRoot'"
    if ($Header -notlike 'minimal') {
        Write-Build Gray "Project directories:"
        ("Source", "Tests", "Docs", "Staging", "Artifact") | ForEach-Object {
            $projPath = (Get-Variable $_ -ValueOnly)['Path']
            if (Test-Path $projPath) {
                Write-Build Gray (" - {0,-16} {1}" -f $_, ((Get-Item $projPath) |
                        Resolve-Path -Relative -ErrorAction SilentlyContinue))
            } else {
                Write-Build DarkGray (" - {0,-16} {1}" -f $_, "(missing) $projPath" )
            }
        }
    }
    Write-Build Gray ('=' * 80)
}
# Exit-Build { Write-Build DarkBlue "Exit-Build after the last task`n$('.' * 78) $Result`n$('.' * 78)" }
# Enter-BuildTask { Write-Build DarkBlue "Enter-BuildTask - before each task"}
# Exit-BuildTask { Write-Build DarkBlue "Exit-BuildTask - after each task" }
# Enter-BuildJob { Write-Build DarkBlue "Enter-BuildJob - before each task action"}
# Exit-BuildJob { Write-Build DarkBlue "Exit-BuildJob - after each task action"}
# Set-BuildHeader { param($Path) Write-Build DarkBlue "[X] Task $Path --- $(Get-BuildSynopsis $Task)" }
# Set-BuildFooter {param($Path)}


# write helpful output
task Help {
    Write-Build Red "The build type: $Type"
    Write-Build DarkBlue "A total of $(${*}.All.Count) tasks"
    foreach( $t in ${*}.All.Keys) {
        $hasSubTasks = $false
        $sub = @()
        $currentTask = ${*}.All[$t]
        $syn = Get-BuildSynopsis $currentTask
        foreach ($j in $currentTask.Jobs) {
            if ($j -is [string] ) {
                $hasSubTasks = $true
                $sub += ("  {0}: {1}" -f $j, (Get-BuildSynopsis ${*}.All[$j]))
            }
        }
        if ($hasSubTasks) {
            "{0}: {1}" -f $t, $syn
            $sub
        }
    }
}
