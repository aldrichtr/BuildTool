param(
    [Parameter()]
    [string]
    $ProjectName = 'BuildTools'
)


. ./build/BuildTool.ps1


# synopsis: the top level task
task top help, {
    Write-Build Gray "$($Task.Name) called looking for $($Path.Source)"
}
