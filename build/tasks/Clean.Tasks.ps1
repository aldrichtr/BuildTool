

# synopsis: Remove generated files in output directories
task Clean {
    @(
        $Artifact.Path,
        $Staging.Path
    ) | ForEach-Object {
        remove "$_/*"
    }
}
