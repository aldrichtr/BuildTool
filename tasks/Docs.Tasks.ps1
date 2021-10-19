
# synopsis: Create all of the module and project documentation
task generate_documentation {}

# synopsis: extract the comment-based help to markdown docs
task generate_markdown_documents {
    Import-Module $Source.Path -Force
    New-MarkdownHelp -Module $ModuleName -OutputFolder $Docs.Path
}

# synopsis: format git log output into a changelog document
task update_changelog {
    Write-Build Red "generate commit log, format for changelog"
}

# synopsis: extract release information from git and issues
task update_release_notes {

}
