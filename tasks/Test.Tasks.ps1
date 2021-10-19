
# synopsis: Run Pester tests tagged with 'unit' against source
test run_unit_tests -Module $Source.Module -PesterConfig $Tests.Config.UnitTests

# synopsis: Run Pester tests tagged with 'pssa' or 'analyze' against stage
test run_script_analyzer_tests -Module $Staging.Module -PesterConfig $Tests.Config.Analyzer

# synopsis: Run Pester tests tagged with 'perf' against stage
test run_performance_tests -Module $Staging.Module -PesterConfig $Tests.Config.Performance

# synopsis: generate code coverage report against stage
test generate_coverage_report -Module $Staging.Module -PesterConfig $Test.Config.Coverage
