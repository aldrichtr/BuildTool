
<#
.Synopsis
    Remove generated files in output directories
#>
task Clean {
    @(
        $Path.Artifact,
        $Path.Staging
    ) | ForEach-Object {
        remove "$_/*"
    }
}
