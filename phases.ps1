
# synopsis: `compile` the module and manifest file
task Stage Clean,
    Test,
    generate_module_file

# synopsis: Create a release build of the module
task Release Stage,
    generate_documentation,
    run_script_analyzer_tests,
    run_performance_tests,
    update_version_information,
    update_release_notes,
    update_changelog

# synopsis: Default testing task
task Test run_unit_tests
