

# synopsis: Remove generated files in output directories
task Clean {
    $c = Get-BuildConfiguration
    $targets = $c.Clean.Targets

    foreach ($t in $targets) {
        Remove-Item @t
    }

}
