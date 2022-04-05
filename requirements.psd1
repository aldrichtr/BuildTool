@{
    PSDependOptions = @{
        Target = 'CurrentUser'
    }
    # A "BuildTool Framework"
    InvokeBuild = @{
        Version = '5.8.8'
        Tags    = 'build', 'prod', 'ci'
    }

    # Testing Framework
    Pester      = @{
        Version = '5.3'
        Tags    = 'dev', 'prod', 'ci'
    }

    # Used to create new projects and files
    Plaster     = @{
        Version = '1.1.3'
        Tags    = 'dev', 'prod', 'ci'
    }

    # Template library
    EPS = @{
        Version = '1.0.0'
        Tags    = 'dev', 'prod', 'ci'
    }

    PSDKit = @{
        Version = '0.6.1'
        Tags = 'dev', 'prod', 'ci'
    }

}
