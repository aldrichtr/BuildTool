
# synopsis: Run Pester tests tagged with 'unit' against source
test run_unit_tests -Module $Path.SourceModule -PesterConfig $Path.Pester.UnitTests

# synopsis: Run Pester tests tagged with 'pssa' or 'analyze' against stage
test run_script_analyzer_tests -Module $Path.StagingModule -PesterConfig $Path.Pester.AnalysisTests

# synopsis: Run Pester tests tagged with 'perf' against stage
test run_performance_tests -Module $Path.StagingModule -PesterConfig $Path.Pester.PerformanceTests

# synopsis: generate code coverage report against stage
test generate_coverage_report -Module $Path.StagingModule -PesterConfig $Path.Pester.CodeCoverage
