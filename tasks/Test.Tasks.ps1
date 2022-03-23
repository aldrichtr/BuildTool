#region Tests against Source module

# synopsis: Run Pester tests tagged with 'unit' against source
test unit_test_source -Module $Source.Module -PesterConfig $Tests.Config.Unit

# synopsis: Run Pester tests tagged with 'pssa' or 'analyze' against stage
test analyzer_test_source -Module $Source.Module -PesterConfig $Tests.Config.Analyzer

# synopsis: Run Pester tests tagged with 'perf' against stage
test performance_test_source -Module $Source.Module -PesterConfig $Tests.Config.Performance

#endregion

#region Tests against Staging module

# synopsis: Run Pester tests tagged with 'unit' against Staging
test unit_test_staging -Module $Staging.Module -PesterConfig $Tests.Config.Unit

# synopsis: Run Pester tests tagged with 'pssa' or 'analyze' against stage
test analyzer_test_staging -Module $Staging.Module -PesterConfig $Tests.Config.Analyzer

# synopsis: Run Pester tests tagged with 'perf' against stage
test performance_test_staging -Module $Staging.Module -PesterConfig $Tests.Config.Performance

#endregion
