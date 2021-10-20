
# synopsis: Create the module file in staging from source files
task generate_module_file {
    Write-Build Yellow "Creating the staging module from source files"
},
    write_file_header,
    copy_source_content_to_psm1


# synopsis: Write a file header for the module file
task write_file_header {
    Set-Content -Path $Staging.Module -Value ("#" * 80)
    Add-Content -Path $Staging.Module -Value "# $ModuleName : $([datetime]::Now)`n`n"
}

# synopsis: Assemble the contents of individual source files into the psm1 file
task copy_source_content_to_psm1 {
    # keep track of how many files were imported
    $file_count = 0
    if (Test-Path $Source.CustomLoadOrder) {
        foreach ($line in (Get-Content $Source.CustomLoadOrder)) {
            switch ($line) {
                '\s*$' {
                    # blank line, skip
                    continue
                 }
                '^\s*#$' {
                    # Comment line, skip
                    continue
                }
                '^.*\.ps1' {
                    # load these
                    $file = "$($Source.Path)\$file"
                    if (Test-Path $file) {
                        $file_count++
                        Get-Content $file | Add-Content -Path $Staging.Module
                    } else {
                        Write-Build Red "Can't find $file listed in $($Source.CustomLoadOrder)"
                    }
                    continue
                }
                default {
                    #unrecognized, skip
                    continue
                }
            }
        }
    } else {
        foreach ($type in $Source.Types ) {
            $src_path = Join-Path -Path $Source.Path -ChildPath $type
            if (Test-Path $src_path) {
                # Create a section header
                Add-Content -Path $Staging.Module -Value ("#" * 80)
                Add-Content -Path $Staging.Module -Value "# $type Section`n`n"

                Get-ChildItem -Path $src_path -Include "*.ps1" -Recurse | Foreach-Object {
                    Write-Build Blue "Adding $($_.BaseName) to $($ModuleName)"
                    Get-Content -Path $_ | Add-Content -Path $Staging.Module
                    $file_count++
                }
            }
        }
    }
    Write-Build Green "( $file_count ) files assembled into $target_module"
}
