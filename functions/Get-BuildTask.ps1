Function Get-BuildTask {
    [CmdletBinding()]
    param(
        # Path to the files containing tasks
        [Parameter(
            Mandatory = $false,
            ValueFromPipeline = $true,
            ValueFromPipelineByPropertyName = $true
        )]
        [Alias("PSPath")]
        [string[]]
        $Path,

        # Optionally, recurse into subdirectories
        [Parameter(
            Mandatory = $false,
            ValueFromPipeline = $false
        )]
        [switch]
        $Recurse
    )
    begin {
        $buildtask_file_pattern = "*.Tasks.ps1"
        $task_files = [System.Collections.ArrayList]::new()
    }

    process {
        foreach ($currentPath in ($Path | Resolve-Path | Convert-Path )) {
            if ((Test-Path $currentPath -PathType Leaf) -and
                ($currentPath -like $buildtask_file_pattern )) {
                    $task_files.Add((Get-Item $currentPath)) | Out-Null
            } elseif (Test-Path $currentPath -PathType Container) {
                Get-ChildItem -Path $currentPath -Include $buildtask_file_pattern -Recurse:$Recurse | ForEach-Object {
                    $task_files.Add($_) | Out-Null
                }
            } else {
                Write-Verbose "Skipping $currentPath"
            }
        }
        Write-Verbose "Found $($task_files.Count) task files"
    }
    end {
        $task_files
    }
}
