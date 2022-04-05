################################################################################
# BuildTool : 04/05/2022 17:36:30


#region enum Section
#endregion enum Section
#region classes Section
#endregion classes Section
#region private Section
#endregion private Section
#region public Section

function Get-BuildConfiguration {
    <#
    .SYNOPSIS
        Read the configuration from the default file and return the object
    .LINK
        Get-BuildConfigurationFile
    #>
    [CmdletBinding(
        DefaultParameterSetName = 'asPsd'
    )]
    param(
        # Optionally load a different configuration
        [Parameter(
            Mandatory = $false,
            ValueFromPipeline = $true
        )]
        [string]$Path,

        # Optionally provide a "key path" to the item in the configuration
        # Example:
        # if the config is like:
        # @{
        #    'github' = @{
        #        'repository = @{
        #            ...
        #        }
        #    }
        #    ....
        # then 'github.repository' will return an object starting at
        # the repository "key"
        [Parameter(
            Mandatory = $false,
            ValueFromPipeline = $false,
            ParameterSetName = 'asPsd'
        )]
        [string]$Key,

        # Optionally return the configuration as a PsdXml object
        # ```powershell
        # $xml = Get-BuildConfiguration -Xml
        # ```
        [Parameter(
            Mandatory = $false,
            ValueFromPipeline = $false,
            ParameterSetName = 'asXml'
        )]
        [switch]$Xml,

        # Optionally return the configuration as a hash table
        [Parameter(
            Mandatory = $false,
            ValueFromPipeline = $false,
            ParameterSetName = 'asPsd'
        )]
        [switch]$AsHashTable

    )
    begin {
        $configFile = Get-BuildConfigurationFile -Path:$Path
    }
    process {
        if (Test-Path $configFile) {
            if ($Xml) {
                $config = Import-PsdXml $configFile
            } else {
                if ($PSBoundParameters['Key']) {
                    $itemTokens = $Key.split('.')
                    if ($itemTokens.Count -gt 0) {
                        $xPath = '/Data'
                        foreach ($key in $itemTokens) {
                            $xPath += ('/Table/Item[@Key="', $key, '"]') -join ''
                        }
                        Write-Verbose "Getting configuration item at '$xPath'"
                        $xmlDoc = Import-PsdXml $configFile
                        $configHash = Get-Psd $xmlDoc $xPath
                    } else {
                        Write-Error "'$Key' did not return any config items"
                    }
                } else {
                    $configHash = Import-Psd $configFile
                }

                if ($AsHashTable) {
                    $config = $configHash
                } else {
                    $configHash['PSTypeName'] = 'PowerShell.Profile.Configuration'
                    $config = [PSCustomObject]$configHash
                }
            } # end not xml
        } else {
            Write-Error "'$configFile' could not be found"
        }

    }
    end {
        $config
    }
}

Function Get-BuildConfigurationFile {
    <#
    .SYNOPSIS
        Determine the path to the file based on several factors
    .DESCRIPTION
        `Get-BuildConfigurationFile` uses:
        1. The value passed in to the Path Parameter
        2. The PS_BUILDTOOL_CONFIG environment variable
        3. The default location: <projectroot>\.buildtool.config.psd1
    #>
    [CmdletBinding()]
    param(
        # Optionally load a different configuration
        [Parameter(
            Mandatory = $false,
            ValueFromPipeline = $true
        )]
        [string]
        $Path
    )
    begin {
        if ($PSBoundParameters['Path']) {
            $configFile = $Path
        } elseif ([System.Environment]::GetEnvironmentVariable('PS_BUILDTOOL_CONFIG', 'User')) {
            $configFile = $env:PS_BUILDTOOL_CONFIG
        } else {
            $pathSplat = @{
                Path                = Get-ProjectRoot
                ChildPath           = '.buildtool/config.psd1'
            }
            $configFile = Join-Path @pathSplat
        }
    }
    process {
        try {
            $conf = Get-Item $configFile -ErrorAction Stop
        } catch {
            Write-Error "Could not get '$configFile'`n$_"
        }
    }
    end {
        $conf
    }
}

Function Get-BuildVersion {
    <#
    .SYNOPSIS
        Return the current version field of the given Manifest.
    #>
    [OutputType([System.Version])]
    [CmdletBinding()]
    param(
        # The path to the Module Manifest (.psd1)
        [Parameter(
            Mandatory,
            ValueFromPipeline
        )]
        [string]$Path
    )
    begin {
        try {
            $manifest = Test-ModuleManifest $Path
        }
        catch {
            Write-Error "Error loading the manifest at '$Path'`n$_"
        }
    }
    process {
        try {
            [System.Version]$version = $manifest.Version

        }
        catch {
            Write-Error "There was an error getting the Module Version from the Configuration`n$_"
        }
    }
    end {
        $version
    }
}

function Get-ModuleList {
    <#
    .SYNOPSIS
        Return a list of modules in the project configuration.
    #>
    [CmdletBinding()]
    param(

    )
    begin {
        $c = Get-BuildConfiguration
    }
    process {
        $r = $c.Project.Modules.Root
        $r['Root'] = $true

        New-Object psobject -property $r | Write-Output

        foreach ($n in $c.Project.Modules.Nested) {
            $n['Root'] = $false
            New-Object psobject -property $n | Write-Output
        }
    }
    end {}
}

Function New-BuildConfiguration {
    <#
    .SYNOPSIS
        Generate a new configuration file for a build based on inputs from the user

    #>
    [CmdletBinding()]
    param(

    )
    begin {
        $sourceRoot = 'source'

        $config = @{
            Build   = @{
                Path   = 'build'
                Tasks  = 'build/Tasks'
                Rules  = 'build/Rules'
                Tools  = 'build/Tools'
                Config = 'build/Config'
            }

            Plaster = @{
                Path = 'build/PlasterTemplates'
            }

            Docs    = @{
                Path = 'docs'
            }
            Tests   = @{
                Path   = "tests"
                Config = @{
                    Unit        = 'pester.config.unittests.psd1'
                    Analyzer    = 'pester.config.analyzertests.psd1'
                    Performance = 'pester.config.performancetests.psd1'
                    Coverage    = 'pester.config.codecoverage.psd1'
                }
            }
        }

        $dir = ((Get-Location).Path -split [regex]::Escape([IO.Path]::DirectorySeparatorChar))[-1]

    }
    process {
        $projectName = Read-Host -Prompt "What is the name of the project ($dir)"
        if ([string]::IsNullOrWhiteSpace($projectName)) {
            $projectName = $dir
        }
        $multi = Read-Host -Prompt "Is this a multi-module project? (n)"
        if ([string]::IsNullOrWhiteSpace($multi)) {
            $multi = $false
        } elseif ($multi -match '^[yY]') {
            $multi = $true
        } else {
            $multi = $false
        }

        $config['Project'] = @{
            Name = $projectName
            Path = (Get-Location).Path
            Type = $multi ? 'multi' : 'single'
        }


        if ($multi) {
            $r = Read-Host -Prompt "What is the name of the root module? ($projectName)"
            if ([string]::IsNullOrWhiteSpace($r)) {
                $r = $projectName
            }
            $nested = @()
            do {
                $n_mod = Read-Host -Prompt "Add a nested module? (blank to complete the list)"
                if (-not([string]::IsNullOrWhiteSpace($n_mod))) { $nested += $n_mod }

            } until ([string]::IsNullOrWhiteSpace($n_mod))
        } else {
            $r = Read-Host -Prompt "What is the name of the module? ($projectName)"
            if ([string]::IsNullOrWhiteSpace($r)) {
                $r = $projectName
            }
        }

        $config.Project['Modules'] = @{
            Root = [ordered]@{
                Name            = $r
                Path            = "$sourceRoot\$r"
                Module          = "$sourceRoot\$r\$r.psm1"
                Manifest        = "$sourceRoot\$r\$r.psd1"
                Types           = @('enum', 'classes', 'private', 'public')
                CustomLoadOrder = ''
            }
        }

        if ($nested.count -gt 0) {
            $config.Project.Modules['Nested'] = @()
            foreach ($n in $nested) {
                $config.Project.Modules.Nested += [ordered]@{
                    Name            = $n
                    Path            = "$sourceRoot\$n"
                    Module          = "$sourceRoot\$n\$n.psm1"
                    Manifest        = "$sourceRoot\$n\$n.psd1"
                    Types           = @('enum', 'classes', 'private', 'public')
                    CustomLoadOrder = ''
                }
            }
        }

    }
    end {
        $config | ConvertTo-Psd | Set-Content ".buildtool.config.psd1"
    }
}
Function Set-BuildConfiguration {
    <#
    .SYNOPSIS
    Set a configuration item in the profile config
    .EXAMPLE
    PS C:\> $repos | Set-BuildConfiguration 'github.repos'
    .EXAMPLE
    PS C:\> Set-BuildConfiguration 'github.repos' $repos
    #>
    [CmdletBinding()]
    param(
        # Optionally load a different configuration
        [Parameter(
            Mandatory = $false,
            ValueFromPipeline = $false
        )]
        [string]
        $Path,

        # Provide a "key path" to the item in the configuration
        # Example:
        # if the config is like:
        # @{
        #    'github' = @{
        #        'repository = @{
        #            ...
        #        }
        #    }
        #    ....
        # then 'github.repository' will return an object starting at
        # the repository "key"
        [Parameter(
            Position = 0,
            Mandatory = $false,
            ValueFromPipeline = $true
        )]
        [string]
        $Key,

        # A hashtable to set the key to
        [Parameter(
            Position = 1,
            Mandatory = $true,
            ValueFromPipeline = $true
        )]
        [Hashtable]
        $Value
    )
    begin {
        $configFile = Get-BuildConfigurationFile -Path:$Path
        $xml = Import-PsdXml -Path $configFile
    }
    process {
        if ($PSBoundParameters['Key']) {
            Write-Debug "Key is set to '$Key'"
            $itemTokens = $Key.split('.')
            if ($itemTokens.Count -gt 0) {
                $xPath = '/Data'
                foreach ($key in $itemTokens) {
                    $xPath += ('/Table/Item[@Key="', $key, '"]') -join ''
                }
                Write-Verbose "Getting configuration item at '$xPath'"
                $xmlDoc = Import-PsdXml $configFile
                Set-Psd -Xml $xmlDoc -Value $Value -XPath $xPath
                Export-PsdXml -Path $configFile -Xml $xmlDoc
            }
        }
    }
    end {}
}

Function Set-BuildVersion {
    <#
    .SYNOPSIS
        Return the current version of the project
    .NOTES
        major.minor[.build[.revision]]

        The components are used by convention as follows:

        - Major: Assemblies with the same name but different major versions are not interchangeable. A higher
                 version number might indicate a major rewrite of a product where backward compatibility cannot be
                 assumed.
        - Minor: If the name and major version number on two assemblies are the same, but the minor version number
                 is different, this indicates significant enhancement with the intention of backward compatibility.
                 This higher minor version number might indicate a point release of a product or a fully
                 backward-compatible new version of a product.

        - Build: A difference in build number represents a recompilation of the same source. Different build numbers
                 might be used when the processor, platform, or compiler changes.

        - Revision: Assemblies with the same name, major, and minor version numbers but different revisions are
                    intended to be fully interchangeable. A higher revision number might be used in a build that
                    fixes a security hole in a previously released assembly.

        Subsequent versions of an assembly that differ only by build or revision numbers are considered to be Hotfix
        updates of the prior version.
    #>
    [CmdletBinding()]
    param(
        # Set the 'Major' Component of the Version
        [Parameter(
        )]
        [int]$Major = 0,

        # Set the 'Minor' Component of the Version
        [Parameter(
        )]
        [int]$Minor = 0,

        # Set the 'Build' Component of the Version
        [Parameter(
        )]
        [int]$Build = 0,

        # Set the 'Revision' Component of the Version
        [Parameter(
        )]
        [int]$Revision = 0,

        # Optionally return the new version to the pipeline
        [Parameter()]
        [switch]$PassThru
    )

    begin {
        $module_version_xpath = 'Data/Table/Item[@Key="Manifest"]/Table/Item[@Key="ModuleVersion"]'
        $xml = Get-BuildConfiguration -Xml
        $current_version = [System.Version](Get-Psd -Xml $xml -XPath $module_version_xpath)
        Write-Verbose "The version in the configuration is $($current_version.ToString())"

    }
    process {
        try {
                $new_version = [System.Version]::new(
                    $Major, $Minor, $Build, $Revision
                )
                Set-Psd -Xml $xml -Value $new_version.ToString() -XPath $module_version_xpath
                Export-PsdXml -Path (Get-BuildConfigurationFile) -Xml $xml -Indent 4
        }
        catch {
            Write-Error "There was an error getting the Module Version from the Configuration`n$_"
        }
    }
    end {
        if($PassThru) { $new_version }
    }
}

function Step-BuildVersion {
    <#
    .SYNOPSIS
*        Step the project version, write it to the config file.  When no Parameters are given, Step
        'Revision'
    .EXAMPLE
        Get-BuildVersion
        1.0.2
        Step-BuildVersion -Major
        2.0.0
    .EXAMPLE
        Get-BuildVersion
        1.0.2
        Step-BuildVersion
        1.0.2.1
    .NOTES
        major.minor[.build[.revision]]

        The components are used by convention as follows:

        - Major: Assemblies with the same name but different major versions are not interchangeable. A higher
                 version number might indicate a major rewrite of a product where backward compatibility cannot be
                 assumed.
        - Minor: If the name and major version number on two assemblies are the same, but the minor version number
                 is different, this indicates significant enhancement with the intention of backward compatibility.
                 This higher minor version number might indicate a point release of a product or a fully
                 backward-compatible new version of a product.

        - Build: A difference in build number represents a recompilation of the same source. Different build numbers
                 might be used when the processor, platform, or compiler changes.

        - Revision: Assemblies with the same name, major, and minor version numbers but different revisions are
                    intended to be fully interchangeable. A higher revision number might be used in a build that
                    fixes a security hole in a previously released assembly.

        Subsequent versions of an assembly that differ only by build or revision numbers are considered to be Hotfix
        updates of the prior version.
    #>
    [OutputType([System.Version])]
    [CmdletBinding()]
    param(
        # Path to the module manifest
        [Parameter(
            Mandatory,
            ValueFromPipeline
        )]
        [string]
        $Path,

        # Step the 'Major' Component of the Version
        [Parameter(
        )]
        [switch]
        $Major,

        # Step the 'Minor' Component of the Version
        [Parameter(
        )]
        [switch]
        $Minor,

        # Step the 'Build' Component of the Version
        [Parameter(
        )]
        [switch]
        $Build,

        # Step the 'Revision' Component of the Version
        [Parameter(
        )]
        [switch]
        $Revision,

        # Optionally, return the new version
        [Parameter(
        )]
        [switch]
        $PassThru
    )
    begin {
        try {
            $current_version = Get-BuildVersion $Path
            Write-Verbose "The version in the configuration is $($current_version.ToString())"
        }
        catch {
            Write-Error "Could not read the version in the manifest at '$Path'`n$_"
        }

    }
    process {
        switch ($PSBoundParameters.Keys) {
            Major {
                Write-Verbose "Incrementing Major version"
                $new_version = [System.Version]::new(
                    ($current_version.Major + 1),
                    0, 0, 0 # reset the rest to zero
                )
            }
            Minor {
                Write-Verbose "Incrementing Minor version"
                $new_version = [System.Version]::new(
                    ($current_version.Major),
                    ($current_version.Minor + 1),
                    0, # Build
                    0  # Revision
                )
            }
            Build {
                Write-Verbose "Incrementing Build version"
                $new_version = [System.Version]::new(
                    ($current_version.Major),
                    ($current_version.Minor),
                    ($current_version.Build + 1 ),
                    0 # Revision
                )
            }
            Revision {
                Write-Verbose "Incrementing Revision version"
                $new_version = [System.Version]::new(
                    ($current_version.Major), # Major
                    ($current_version.Minor), # Minor
                    ($current_version.Build), # Build
                    ($current_version.Revision + 1) # Revision
                )
            }
            Default {
                Write-Verbose "Incrementing Revision version"
                $new_version = [System.Version]::new(
                    ($current_version.Major), # Major
                    ($current_version.Minor), # Minor
                    ($current_version.Build), # Build
                    ($current_version.Revision + 1) # Revision
                )
            }
        }

    }
    end {
        try {
            Update-ModuleManifest -Path $Path -ModuleVersion $new_version
        }
        catch {
            Write-Error "There was an error writing the new version to '$Path'`n$_"
        }
        if ($PassThru) { $new_version }
    }
}

function Add-ModuleContent {
    <#
    .SYNOPSIS
        Add a Source file's content to the Module.
    #>
    [CmdletBinding()]
    param(
        # SourceInfo object to add to the Module file
        [Parameter(
            ValueFromPipeline
        )]
        [Object[]]$SourceItem,

        # Path to the Module file
        [Parameter(
            Mandatory,
            Position = 0
        )]
        [string]$Path
    )
    begin {
    }
    process {
        $source = $PSItem
        if (-not(Test-Path $source.Path)) {
            throw "Could not get the source content for $($source.Name)"
        }
        Get-Content $source.Path | Add-Content $Path

    }
    end {}
}
<#
.SYNOPSIS
    Custom assertion for PSScriptAnalyzer tests
.DESCRIPTION
    `FollowRule` is a convenience function for Pester tests using the PSSA.
    While there are many patterns that can be used to analyze a code block and
    wrap it in a Pester "It block", this function makes the "Should" assertion
    more like a natural-language test. So, rather than something like:
    ``` powershell
    if ($analysis.RuleName -contains $rule) {
        # gather failures
    }
    $failures.Count | Should -Be 0
    ```
    A much more succinct test looks like:
    ``` powershell
    $analysis | Should -Pass $rule
    ```
    Additionally, this assertion "pretty formats" the error messages a bit.
    A Pester Should function will output 'Expected foo but got bar' followed by
    a very poorly formatted dump of the rule output.
    `FollowRule` does a decent job of collecting the relevant properties of the
    DiagnosticRecord properties.  It will print:
    ```
    Rule violation: <rule name>
    <rule message>
    <file:line:column>
    <file:line:column>
    <file:line:column>
    ```
.NOTES
    this function gets added to Pester using the `Add-AssertionOperator` which
    is in this file below the function
.EXAMPLE
     $analysis | Should -Pass $rule
#>
Function FollowRule {
    [CmdletBinding()]
    param(
        $ActualValue,
        $PSSARule,
        $CallerSessionState,
        [Switch]$Negate
    )
    begin {
        $AssertionResult = [PSCustomObject]@{
            Succeeded      = $false
            FailureMessage = ""
        }
    }
    process {
        if ( $ActualValue.RuleName -contains $PSSARule.RuleName) {
            $AssertionResult.Succeeded = $false
            $AssertionResult.FailureMessage = @"
`n$($PSSARule.Severity) - $($PSSARule.CommonName)
$($ActualValue.Message)
$($PSSARule.SuggestedCorrections)
"@
            # there may be several
            # lines that do not Rule$rule the rule, collect them all into one
            # error message
            $ActualValue | Where-Object {
                $_.RuleName -eq $PSSARule.RuleName
            } | ForEach-Object {
                $AssertionResult.FailureMessage += "'{0}' at {1}:{2}:{3}`n" -f
                $_.Extent.Text,
                $_.Extent.File,
                $_.Extent.StartLineNumber,
                $_.Extent.StartColumnNumber
            }
        } else {
            $AssertionResult.Succeeded = $true
        }
    }
    end {
        if ($Negate) {
            $AssertionResult.Succeeded = -not($AssertionResult.Succeeded)
        }
        $AssertionResult
    }
}

Add-AssertionOperator -Name 'Pass' -Test $Function:FollowRule


<#
.SYNOPSIS
    Run Invoke-Pester with parameters to modify the tests or output
.NOTES
    Test options could be:
    - just 'this' test
    - just tests with tag
    - just unit tests
    - only tests that failed last run
    - code format, standards conformance, etc
#>
Function Invoke-Test {
    [CmdletBinding(
        DefaultParameterSetName = 'Module'
    )]
    param(
        # Either a list of paths or the result of a `Get-SourceItem`
        [Parameter(
            Mandatory = $true,
            ParameterSetName = 'File',
            ValueFromPipeline = $true
        )]
        [Object[]]
        $Name,

        # The name of the Module to test
        [Parameter(
            Mandatory = $true,
            ParameterSetName = 'Module',
            ValueFromPipeline = $true
        )]
        [string]
        $Module,

        # Optional root directory to start in
        [Parameter(
            Mandatory = $false,
            ValueFromPipeline = $false
        )]
        [string]
        $Root = (Get-Item $MyInvocation.PSCommandPath).Directory,

        # A pester configuration file (psd1) to use
        [Parameter(
            Mandatory = $false,
            ValueFromPipeline = $true
        )]
        [string]
        $Configuration
    )
    begin {
        if ($PSBoundParameters['Configuration']) {
            if (Test-Path $Configuration) {
                try {
                    $configHash = Import-Metadata $Configuration
                } catch {
                    Write-Error "'$Configuration' could not be used as "
                }
            } else {
                Write-Error "'$Configuration' is not a valid path"
            }
        } else {
            $configHash = @{
                Run = @{
                    Path = @('./tests')
                    TestExtension = '.Tests.ps1'
                }
            }
        }

        $pesterConfiguration = New-PesterConfiguration -Hashtable $configHash
    }
    process {
        if ($PSBoundParameters['Module']) {
            try {
                Import-Module $Module -Force
            }
            catch {
                Write-Error "Could not load '$Module'`n$_"
            }
            Write-Verbose "Running Pester tests for '$Module' in $($pesterConfiguration.Run.Path)"
            Invoke-Pester -Configuration $pesterConfiguration
        }
        if ($PSBoundParameters['Name']) {
            foreach ($n in $Name) {
                if ($n -is [string]) {
                    if (Test-Path $n) {
                        $sourceItem = Get-Item $n
                    } else {
                        Write-Error "Could not find '$n'"
                    }
                } elseif ($n -is [BuildTool.SourceItem]) {
                    $sourceItem = Get-Item $n.Path
                }

                Write-Debug "`r`nLooking for Pester tests:`
                    Source:`n`tGiven: $n`n`tItem: '$($sourceItem.Name)'`
                    Tests:`n`tIn $Root`n`tFilter: $($sourceItem.BaseName)*.Tests.ps1"
                $tests = Get-ChildItem "$Root" -Filter "$($sourceItem.BaseName)*.Tests.ps1" -Recurse
                if ($tests.Count -gt 0) {
                    . $sourceItem.FullName
                    Write-Verbose "Running Pester tests for '$($sourceItem.Name)' in $($tests -join ', ')"
                    Invoke-Pester -Path $tests
                } else {
                    Write-Output "No tests were found for '$n'"
                }
            }
        }
    }
    end {}
}

Function Test-PesterTestHasTag {
    <#
    .SYNOPSIS
        Test for the existence of tags on the pester test
    .NOTES
        Currently this only tests the 'Describe' Command
    #>
    [CmdletBinding()]
    [OutputType([bool])]
    param(
        # Specifies a path to one or more locations.
        [Parameter(
            Mandatory = $true,
            ValueFromPipeline = $true
        )]
        [Alias('PSPath')]
        [ValidateNotNullOrEmpty()]
        [string[]]
        $Path
    )
    begin {
        $tokens = @()
        $parse_errors = @()
        [scriptblock]$predicate = {
            param($node)
            $node -is [System.Management.Automation.Language.CommandAst] -and
            $node.CommandElements[0].Value -eq 'Describe'
        }
    }
    process {
        foreach ($p in $Path) {
            $ast = [System.Management.Automation.Language.Parser]::ParseFile($p, [ref]$tokens, [ref]$parse_errors)
            if ($parse_errors.Length -gt 0) {
                Write-Error $parse_errors
            }
            $describeBlock = $ast.FindAll( $predicate , $true )
            if ($describeBlock.Count -gt 0) {
                if (($describeBlock.CommandElements[2] -is [System.Management.Automation.Language.CommandParameterAst]) -and
                ($describeBlock.CommandElements[2].ParameterName -match '^Tag(s)*$')) {
                    $Tags = [scriptblock]::create($describeBlock.CommandElements[3].ToString()).Invoke()
                    $return = ($Tags.Count -gt 0)
                } else {
                    $return = $false
                } # Match tag
            } #
        } # for each path processing
    } # end process block
    end {
        $return
    }
}
Function Export-FunctionFromFile {
    [cmdletbinding(SupportsShouldProcess)]
    [alias("eff")]
    [OutputType("None", "System.IO.FileInfo")]
    Param(
        [Parameter(Position = 0, Mandatory, HelpMessage = "Specify the .ps1 or .psm1 file with defined functions.")]
        [ValidateScript({
                If (Test-Path $_ ) {
                    $True
                } Else {
                    Throw "Can't validate that $_ exists. Please verify and try again."
                    $False
                }
            })]
        [ValidateScript({
                If ($_ -match "\.ps(m)?1$") {
                    $True
                } Else {
                    Throw "The path must be to a .ps1 or .psm1 file."
                    $False
                }
            })]
        [string]$Path,
        [Parameter(HelpMessage = "Specify the output path. The default is the same directory as the .ps1 file.")]
        [ValidateScript({ Test-Path $_ })]
        [string]$OutputPath,
        [Parameter(HelpMessage = "Export all detected functions.")]
        [switch]$All,
        [Parameter(HelpMessage = "Pass the output file to the pipeline.")]
        [switch]$Passthru
    )
    Write-Verbose "Starting $($MyInvocation.MyCommand)"

    #always create these variables
    New-Variable astTokens -Force -WhatIf:$False
    New-Variable astErr -Force -WhatIf:$False

    if (-Not $OutputPath) {
        #use the parent path of the file unless the user specifies a different path
        $OutputPath = Split-Path -Path $Path -Parent
    }

    Write-Verbose "Processing $path for functions"
    #the file will always be parsed regardless of WhatIfPreference
    $AST = [System.Management.Automation.Language.Parser]::ParseFile($Path, [ref]$astTokens, [ref]$astErr)

    #parse out functions using the AST
    $functions = $ast.FindAll({ $args[0] -is [System.Management.Automation.Language.FunctionDefinitionAst] }, $true)

    if ($functions.count -gt 0) {
        Write-Verbose "Found $($functions.count) functions"
        Write-Verbose "Creating files in $outputpath"
        Foreach ($item in $functions) {
            Write-Verbose "Detected function $($item.name)"
            #only export functions with standard namees or if -All is detected.
            if ($All -OR (Test-FunctionName -name $item.name)) {
                $newfile = Join-Path -Path $OutputPath -ChildPath "$($item.name).ps1"
                Write-Verbose "Creating new file $newFile"
                Set-Content -Path $newFile -Value $item.ToString() -Force
                if ($Passthru -AND (-Not $WhatIfPreference)) {
                    Get-Item -Path $newfile
                }
            } else {
                Write-Verbose "Skipping $($item.name)"
            }
        } #foreach item
    } else {
        Write-Warning "No functions detected in $Path."
    }
    Write-Verbose "Ending $($MyInvocation.MyCommand)"
} #end function

Function Format-Changelog {
    [CmdletBinding()]
    param()
    begin {
        $header = "# Changelog $(Get-Date -UFormat '%d %B %Y')`n`n"
        $output = $header
    }
    process {
        $commits = Get-GitCommit -Until (Get-GitCommit -Revision 'main').Sha
        foreach ($commit in $commits) {
            [System.Collections.ArrayList]$lines = $commit.Message -split '\n'
            $output += "## $($lines[0])`n"
            $lines.RemoveAt(0)

            foreach ($line in $lines) {
                switch -Regex ($line) {
                    '^\s*$' {
                        continue
                    }
                    '^\*\s+(.*)$' {
                        $output += "- [X] $($Matches.1)`n"
                        continue
                    }
                    '^\*{2}\s+(.*)$' {
                        $output += "  - [X] $($Matches.1)`n"
                        continue
                    }
                    Default {
                        $output += "$line`n"
                        continue
                    }
                }
            }
            $output += "`n"
        }
    }
    end {
        $output
    }
}
Function Get-BuildTask {
    [CmdletBinding()]
    param(
        # Path to the files containing tasks
        [Parameter(
            Mandatory = $false,
            ValueFromPipeline = $true,
            ValueFromPipelineByPropertyName = $true
        )]
        [Alias("PSPath")]
        [string[]]
        $Path,

        # Optionally, recurse into subdirectories
        [Parameter(
            Mandatory = $false,
            ValueFromPipeline = $false
        )]
        [switch]
        $Recurse
    )
    begin {
        $buildtask_file_pattern = "*.ps1"
        $task_files = [System.Collections.ArrayList]::new()
        if (-not($PSBoundParameters['Path'])) {
            $Path = "$PSScriptRoot\tasks"
        }
    }

    process {
        foreach ($currentPath in ($Path | Resolve-Path | Convert-Path )) {
            if ((Test-Path $currentPath -PathType Leaf) -and
                ($currentPath -like $buildtask_file_pattern )) {
                    $task_files.Add((Get-Item $currentPath)) | Out-Null
            } elseif (Test-Path $currentPath -PathType Container) {
                Get-ChildItem -Path $currentPath -Include $buildtask_file_pattern -Recurse:$Recurse | ForEach-Object {
                    $task_files.Add($_) | Out-Null
                }
            } else {
                Write-Verbose "Skipping $currentPath"
            }
        }
        Write-Verbose "Found $($task_files.Count) task files"
    }
    end {
        $task_files
    }
}
<#
.SYNOPSIS
    Provide a list of components base on the filenames
    in the source directory provided
.DESCRIPTION
    This function depends on the current module conforming to the convention
    of putting one function per file in folders 'public' or 'private' and
    classes and enums in files similarly named.
#>
Function Get-ModuleComponent {
    [CmdletBinding()]
    param(
        # The path to the module source directory
        [Parameter(
            Position = 1,
            Mandatory = $true,
            ValueFromPipeline = $true
        )]
        [string]
        $Path,

        # The type of component to get
        [Parameter(
            Mandatory = $false,
            ValueFromPipeline = $true
        )]
        [ValidateSet('public', 'private', 'classes', 'enum', 'data')]
        [string]
        $Type = 'public'
    )
    begin {
        $components = [System.Collections.ArrayList]::new()
    }
    process {
        Get-ChildItem "$Path\$Type" -File -Filter "*.ps1" -Recurse | ForEach-Object {
            try {
                $name = $_.BaseName
                $components.Add($name) | Out-Null
            } catch {
                Write-Error "Couldn't add $name`$_"
            }
        }
    }
    end {
        $components
    }
}
function Get-ProjectName {
    <#
    .SYNOPSIS
        Get the name for this project.
    .DESCRIPTION
        The most reliable way to get the project name is using the git repository name, so we start with that.  If
        that fails, the next most reliable way is to see if the 'source' directory is found, then it's parent is
        the project root.
    #>
    [cmdletbinding()]
    param(
    )
    begin {
        if (-not(Get-Command Get-GitRepository)) {
            Write-Error "No Git module is loaded. Please install either 'PowerGit' or 'posh-git'"
        }
    }
    process {
        Write-Output (Get-GitRepository).RepositoryName
    }
}

Function Get-ProjectRoot {
    <#
    .SYNOPSIS
        Find the root of the current project
    #>
    [CmdletBinding()]
    param(
        # Optionally set the starting path to search from
        [Parameter(
        )]
        [string]$Path = (Get-Location).ToString(),

        # Maximum number of levels to search
        [Parameter(
        )]
        [int]$Depth = 16
    )
    begin {
        $current_location = $Path | Get-Item
        $location_root = $current_location.Root

        Write-Debug "Current location: $($current_location.FullName)"
        Write-Debug "Current root: $($location_root.FullName)"
    }
    process {
        foreach ($level in 1..$Depth) {
            if (Test-Path (join-path $current_location '.git' )) {
                Write-Debug "Current location: $($current_location.FullName)"
                break
            }
            $current_location = $current_location.Parent
            if ($current_location -eq $location_root) {
                Write-Error "Could not find the project root"
                break
            }
        }

    }
    end {
        $current_location.FullName
    }
}

Function Get-ScriptAst {
    <#
    .SYNOPSIS
        Get the Abstract Syntax Tree of a scriptblock
    .DESCRIPTION
        The AST parser library is complex and powerfull.  However, what we need
        is a "basic" object that represents the function, class, or enum in the
        file we provide.
    .NOTES
        `Get-ScriptAst` is mostly a convenience wrapper around the more sophisticated
        Language.Parser class.

    #>
    [CmdletBinding()]
    [OutputType([System.Management.Automation.Language.Ast])]
    param(
        # The path to the file to parse
        [Parameter(
            Mandatory = $true,
            ValueFromPipeline = $true
        )]
        [string]
        $Path,

        # a scriptblock to send to the findall function
        [Parameter(
            Mandatory = $false,
            ValueFromPipeline = $true
        )]
        [scriptblock]
        $Predicate
    )

    begin {
        $tokens = @()
        $parse_errors = @()
        try {
            $scriptFile = Get-Item $Path -ErrorAction Stop
        } catch {
            Write-Error "Couldn't load '$Path'`n$_"
        }
    }

    process {
        try {
            $ast = [System.Management.Automation.Language.Parser]::ParseFile(
                $scriptFile.FullName, [ref]$tokens, [ref]$parse_errors
            )
            if ($parse_errors.Count -gt 0) {
                throw $parse_errors.Message
            }
            if ($PSBoundParameters['Predicate']) {
                $returnAst = $ast.FindAll( $Predicate, $true )
            } else {
                $returnAst = $ast
            }
        } catch {
            throw "There was an error parsing the input`n$_"
        } # end try-catch
    } # end process block

    end {
        $returnAst
    }
}
<#
.SYNOPSIS
    Return a list of Aliases set in files listed in path
 #>

Function Get-SourceAlias {
    [CmdletBinding()]
    param(
        # The path to search for aliases
        [Parameter(
            Mandatory = $true,
            ValueFromPipeline = $true
        )]
        [string[]]
        $Path,

        # Optionally recurse subdirectories
        [Parameter(
            Mandatory = $false,
            ValueFromPipeline = $false
        )]
        [switch]
        $Recurse,

        # Optionally return the names only.  Useful for generating a list
        [Parameter(
            Mandatory = $false,
            ValueFromPipeline = $false
        )]
        [switch]
        $NameOnly
    )

    begin {
        $aliases = @()
    }

    process {
        foreach ($p in $Path) {
            $m = Get-ChildItem -Path $p -Recurse:$Recurse |
            Select-String  -AllMatches -Pattern '^Set-Alias\s+(?<name>\w+)\s+(?<to>\S+)\s*$'
            foreach ($a in $m.Matches) {
                if ($NameOnly) {
                    $alias = $a.Groups['name'].Value
                } else {
                    $alias = [PSCustomObject]@{
                        'Name' = $a.Groups['name'].Value
                        'To'   = $a.Groups['to'].Value
                    }
                }
                $aliases += $alias
            }
        }
    }
    end {
        $aliases
    }
}

<#
.SYNOPSIS
    Returns component information based on the directory names of the input
.DESCRIPTION
    Gather metadata about source files in the given folder.
.EXAMPLE
     PS C:\> "my/source/folder" | Get-sourceItem
     Visibility    Name    Sub    Verb    Noun
     public        Engine         Set     Thrust
     public        Engine         Get     Temperature
#>
Function Get-SourceItem {
    [CmdletBinding()]
    param(
        # Specifies a path to one or more locations.
        [Parameter(
            Mandatory = $true,
            Position = 0,
            ValueFromPipeline = $true,
            ValueFromPipelineByPropertyName = $true
        )]
        [Alias('PSPath')]
        [ValidateNotNullOrEmpty()]
        [string[]]
        $Path,

        # How many folders to "walk" in order to determine component attributes
        # default is 3 (Visibility/Component/Item)
        # over 5 is not supported
        [Parameter(
            Mandatory = $false,
            ValueFromPipeline = $false
        )]
        [ValidateRange(3, 5)]
        [Int]
        $Depth = 3,

        # The root directory of the source, if not the directory supplied.
        [Parameter(
            Mandatory = $false,
            ValueFromPipeline = $false
        )]
        [string]
        $Root

    )

    begin {
        if (-not($PSBoundParameters['Root'])) { $Root = (Get-Location) }
        $sourceItems = [System.Collections.ArrayList]::new()

    }

    process {
        foreach ($p in $Path) {
            try {
                $item = Get-Item $p -ErrorAction Stop
                switch (($item.GetType()).Name) {
                    'FileInfo' {
                        if ($item.Extension -eq '.ps1') {
                            $sourceItems += $item | Get-SourceItemInfo -Root $Root
                        }
                        continue
                    }
                    'DirectoryInfo' {
                        $sourceItems += Get-ChildItem $item.FullName -Recurse:$Recurse | Get-sourceItemInfo -Root $item.FullName
                        continue
                    }
                }
            } catch {
                Write-Warning "$p is not a valid path`n$_"
            }
        }
    }
    end {
        $sourceItems
    }
}

Function Get-SourceItemInfo {
    <#
    .SYNOPSIS
        Returns component information based on the directory names of the input
    .DESCRIPTION
        `Get-SourceItemInfo` makes some assumptions about your source directory
        in order to create the `BuildTool.SourceItem` object

        - You follow the "one function/object definition per file" convention.
        - You name the file "<function/object name>.ps1"
        - You organize files into folders based on the visibility ('public',
          'private',  etc.)
        - When the module is large or complex, you organize like items into
          folders representing "components".

        **Note** here that a "component" in this context doesn't necessarily
        correlate with submodules, nested modules, or any "code", it is just a
        logical grouping of files.

        ### Components and Visibility

        If you use both "component" folders and "visibility" folders, there are
        two strategies; "Component First" and "Visibility First".
        `Get-SourceItemInfo` tries to determine which one based on the
        standard names ['public', 'private', 'enum', ('class' or 'classes'),
        'data', 'resource']

    .EXAMPLE
    # When looking at the source directory, Components are used to organize the
    # files like:

    # PSRocketShip
    #   - Engine
    #     - public
    #       - Set-Thrust.ps1
    #       - Get-Temperature.ps1
    #   - Capsule
    #     - public
    #       - Set-FloorLighting.ps1
    #   - OxygenGenerator
    #     - public
    #       - Get-FilterStatus.ps1

    "./PSRocketShip" | Get-SourceItemInfo | ft -property Visibility, Name, Component, Noun
    .EXAMPLE
         # When looking at the source directory, visibility is used to organize the files
    # with the components folders nested under them.

    # PSRocketShip
    #   - public
    #     - Engine
    #       - Set-Thrust.ps1
    #       - Get-Temperature.ps1
    #     - Capsule
    #       - Set-FloorLighting.ps1
    #     - OxygenGenerator
    #       - Get-FilterStatus.ps1

    "./PSRocketShip" | Get-SourceItemInfo | ft -property Visibility, Name, Component, Noun
    #>
    [CmdletBinding()]
    param(
        # The directory to look in for template files
        [Parameter(
            Mandatory = $true,
            ValueFromPipeline = $true,
            ValueFromPipelineByPropertyName = $true
        )]
        [Alias('PSPath')]
        [ValidateNotNullOrEmpty()]
        [string[]]
        $Path,

        # The root directory of the source
        [Parameter(
            Mandatory = $true,
            ValueFromPipeline = $false
        )]
        [string]
        $Root
    )
    begin {
        $sourceTypeMap = @{
            # directory name => visibility
            'public'   = @{ Visibility = 'public'; Type = 'function' }
            'class'    = @{ Visibility = 'private'; Type = 'class' }
            'classes'  = @{ Visibility = 'private'; Type = 'class' }
            'enum'     = @{ Visibility = 'private'; Type = 'enum' }
            'private'  = @{ Visibility = 'private'; Type = 'function' }
            'resource' = @{ Visibility = 'private'; Type = 'resource' }
            'data'     = @{ Visibility = 'private'; Type = 'resource' }
        }
        $sourceItems = [System.Collections.ArrayList]::new()
        try {
            if (-not
            ( ($Root.ToCharArray())[-1] -like [System.IO.Path]::DirectorySeparatorChar)
            ) {
                $Root += [System.IO.Path]::DirectorySeparatorChar
            } # Add a '/' if not present

            $rootItem = Get-Item $Root -ErrorAction Stop
            if (-not ($rootItem -is [System.IO.DirectoryInfo])) { Write-Error "$Root is not a Directory" }
        } catch {
            Write-Error "Couldn't set root directory '$Root'`n$_"
        } # end try-catch

    }
    process {
        foreach ($p in $Path) {
            try {
                $item = Get-Item $p -ErrorAction Stop
                if ($item.Extension -notlike '.ps1') { continue }

                Write-Debug "Getting relative path from root '$($rootItem.FullName)'"
                $adjustedPath = $item.FullName -replace [regex]::Escape($rootItem.FullName), ''
                Write-Debug "`n'$($item.FullName)' adjusted path is '$adjustedPath'"
                [System.Collections.ArrayList]$pathItems = $adjustedPath -split [regex]::Escape([System.IO.Path]::DirectorySeparatorChar)
                Write-Debug "`nItems found in adjusted path:`n'$($pathItems -join ';')'"
                # reverse the order, so we can walk "up" the directories
                $pathItems.Reverse()
                $pathItems.RemoveAt(0)
                Write-Debug "`nReversed and filename removed:`n'$($pathItems -join ';')'"

                $sourceItem = [PSCustomObject]@{
                    PSTypeName   = 'BuildTool.SourceItem'
                    Path         = $item.FullName
                    Name         = $item.BaseName
                    Type         = ''
                    Component    = ''
                    SubComponent = @()
                    Visibility   = ''
                    Verb         = ''
                    Noun         = ''
                }

                if ($item.BaseName -match '(?<verb>\w+)-(?<noun>\w+)') {
                    $sourceItem.Verb = $Matches.verb
                    $sourceItem.Noun = $Matches.noun
                } else {
                    $sourceItem.Noun = $item.BaseName
                }

                # find set and remove the visibility if we can find it...
                foreach ($pathItem in $pathItems) {
                    if ($sourceTypeMap.Keys -contains $pathItem) {
                        $sourceItem.Visibility = $sourceTypeMap[$pathItem].Visibility
                        $sourceItem.Type = $sourceTypeMap[$pathItem].Type
                        # We will cause an error if we try to remove an item
                        # while in a foreach, so store it for after
                        $visibility = $pathItem
                    }
                }
                $pathItems.Remove($visibility)

                Write-Debug "after removing visibility, remaining is $($pathItems -join ';')"

                # the only thing left must be components
                $sourceItem.Component = $pathItems[-1]
                $pathItems.Remove($sourceItem.Component)
                if ($pathItems.Length -gt 0) {
                    $sourceItem.SubComponent += $pathItems
                }
                $sourceItems += $sourceItem
            } catch {
                Write-Warning "$p is not a valid path`n$_"
            } # nested try
        } # end foreach
    } # end process block
    end {
        $sourceItems
    }
}

Function Get-SourceModule {
    <#
    .SYNOPSIS
        Get the Module hierarchy of the source files
    #>
    [CmdletBinding()]
    param(
        # Path to the source root module manifest
        [Parameter(
            Mandatory,
            ValueFromPipeline
        )]
        [string]
        $Path
    )

    begin {
        if (Test-Path $Path) {
            $m = Test-ModuleManifest $Path
        } else {
            Write-Error "$Path could not be found"
        }
    }
    process {
        $root = $m.RootModule
        $null = $root -match '^.*(\w+)\.psm1$'


    }
    end {}
}
Function Test-FunctionName {
    [CmdletBinding()]
    [OutputType("boolean")]
    Param(
    [Parameter(Position = 0,Mandatory,HelpMessage = "Specify a function name.")]
    [ValidateNotNullOrEmpty()]
    [string]$Name
    )

    Write-Verbose "Validating function name $Name"
    #Function name must first follow Verb-Noun pattern
    if ($Name -match "^\w+-\w+$") {
        #validate the standard verb
        $verb = ($Name -split "-")[0]
        Write-Verbose "Validating detected verb $verb"
        if ((Get-Verb).verb -contains $verb ) {
            $True
        }
        else {
            Write-Verbose "$($Verb.ToUpper()) is not an approved verb."
            $False
        }
    }
    else {
        Write-Verbose "$Name does not match the regex pattern ^\w+-\w+$"
        $False
    }
}
Function Resolve-GitRepository {
    <#
    .SYNOPSIS
        Find the root of the current repository
    #>
    [CmdletBinding()]
    param(
        # Optionally set the starting path to search from
        [Parameter(
        )]
        [string]
        $Path = (Get-Location).ToString(),

        # Optionally limit the number of levels to seach
        [Parameter()]
        [int]
        $Depth = 8
    )
    begin {
        $level = 1
        $current_location = $Path | Get-Item
        $drive_root = $current_location.Root
        $repository_root = ''
        $root_reached = $false

        Write-Debug "Current location: $($current_location.FullName)"
        Write-Debug "Current root: $($drive_root.FullName)"
    }
    process {
        do {
            if (Test-GitRepository $current_location.FullName) {
                $repository_root = $current_location.FullName
                $root_reached = $true
            } elseif ($level -eq $Depth) {
                $root_reached = $true
            } elseif ($current_location -eq $drive_root) {
                $root_reached = $true
            } else {
                Write-Debug "Level: $level - $($current_location.Name) is not a repository root"
            }
            $current_location = $current_location.Parent
            $level++
        } until ($root_reached)
    }
    end {
        if ($repository_root.Length -gt 0) {
            $current_location.FullName
        } else {
            Write-Error "Could not find a git repository from $Path"
        }
    }
}

Function Test-GitRepository {
    <#
    .SYNOPSIS
        Test if the given directory is a git repository
    #>
    [CmdletBinding()]
    param(
        # Optionally give a path to start in
        [Parameter(
            ValueFromPipeline
        )]
        [ValidateScript(
            {
                if (-not($_ | Test-Path)) {
                    throw "$_ does not exist"
                }
                return $true
            }
        )]
        [string]
        $Path = (Get-Location).ToString()
    )
    $git_config = '.git\config'
    $git_path = Join-Path $Path -ChildPath $git_config
    Test-Path $git_path
}
<#
.SYNOPSIS
    Retrieve a list of Source Templates
#>

Function Get-SourceTemplate {
    [CmdletBinding()]
    param(
        # The directory to look in for template files
        [Parameter(
            Mandatory = $true,
            ValueFromPipeline = $true,
            ValueFromPipelineByPropertyName = $true
        )]
        [Alias('PSPath')]
        [ValidateNotNullOrEmpty()]
        [string[]]
        $Path,

        # Recurse subdirectories
        [Parameter(
            Mandatory = $false,
            ValueFromPipeline = $false
        )]
        [switch]
        $Recurse
    )
    begin {
        $templateExtension = '.eps'
        $templates = [System.Collections.ArrayList]::new()

    }
    process {
        foreach ($p in $Path) {
            try {
                $pItem = Get-Item $p -ErrorAction Stop
                Write-Debug "Checking '$($pItem.Name)' for template info"
                switch (($pItem.GetType()).Name) {
                    'DirectoryInfo' {
                        $templates += Get-ChildItem $pItem.FullName -Recurse:$Recurse | Get-SourceTemplate
                        continue
                    }
                    'FileInfo' {
                        if ($pItem.Extension -like $templateExtension) {
                            Write-Verbose "Found template '$($pItem.Name)'"
                            $template = Get-Content $pItem.FullName | Get-TemplateInfo
                            Write-Verbose "Adding path '$($pItem.Name)' to template $($template.Name)"
                            $template | Add-Member -NotePropertyName 'Path' -NotePropertyValue $pItem.FullName
                            $null = $templates.Add($template)
                        }
                        continue
                    }
                    Default {
                        Write-Verbose "Skipping $($pItem.Name)"
                        continue
                    }
                }
            } catch {
                Write-Warning "$p is not a valid path`n$_"
            }
        }
    }
    end {
        $templates
    }
}
<#
.SYNOPSIS
    Retrieve metadata from a template file
 #>
Function Get-TemplateInfo {
    [CmdletBinding()]
    param(
        # Path to template file
        [Parameter(
            Mandatory = $true,
            ValueFromPipeline = $true
        )]
        [AllowEmptyString()]
        [string[]]
        $Content
    )
    begin {
        $line = 0
        $isMetaData = $false
        $template = [PSCustomObject]@{
            'Name' = '(none)'
        }
    }
    process {
        $line++
        Write-Debug "$line : '$Content'"
        switch -Regex ($Content) {
            '<%#' {
                Write-Debug "${line}: template comment start"
                $isMetaData = $true
                continue
            }
            '-%>' {
                Write-Debug "${line}: template comment end"
                $isMetaData = $false
                break
            }
            '^\s*#\+(?<key>[A-Z0-9_]+):\s+(?<body>.*)$' {
                if ($isMetaData) {
                    Write-Debug "${line}: Matched a metadata key"
                    $textInfo = (Get-Culture).TextInfo
                    # Titlecase upcases the first letter, but does not lower
                    # case the rest, so we need to lower it first, then titlecase
                    $key = $textInfo.ToTitleCase($textInfo.ToLower($Matches.key))
                    if ($key -like "Tag*") {
                        Write-Verbose "Adding template metadata '$key' with '$($Matches.body)'"
                        $template | Add-Member -NotePropertyName 'Tags' -NotePropertyValue ($Matches.body -split ',')
                    } else {
                        Write-Verbose "Adding template metadata '$key' with '$($Matches.body)'"
                        $template | Add-Member -NotePropertyName $key -NotePropertyValue $Matches.body -Force # add it even if it already exists
                    }
                }
                continue
            }
        }
    }

    end {
        $template
    }
}
Function New-TestItem {
    [CmdletBinding()]
    param(
        # The SourceItem to create a test file for
        [Parameter(
            Mandatory = $true,
            ValueFromPipeline = $true
        )]
        [Object]
        $Source,

        # The destination (test) folder to create the file in
        [Parameter(
            Mandatory = $true,
            ValueFromPipeline = $true
        )]
        [string]
        $Destination,

        # Overwrite an existing file
        [Parameter(
            Mandatory = $false,
            ValueFromPipeline = $false
        )]
        [switch]
        $Force
    )
    begin {
        $templateDirectory = 'BuildTool\templates'
        if (-not(Test-Path $Destination)) {
            Write-Error "$Destination directory does not exist`n$_"
        }
    }
    process {
        try {
            $outputDirectory = (Join-Path $Destination -ChildPath $Source.Component -AdditionalChildPath $Source.SubComponent)
            Write-Debug "Output directory set to '$outputDirectory'"
            if (-not(Test-Path $outputDirectory)) {
                Write-Debug "Output directory doesn't exist, creating"
                New-Item $outputDirectory -ItemType Directory -Force
            }
            $testFile = (Join-Path $outputDirectory -ChildPath "$($Source.Name).Tests.ps1")
            Write-Debug "New test file path : $testFile"
            $template = (Join-Path $templateDirectory -ChildPath "$($Source.Type)_test.eps")
            Write-Debug "Using template '$template'"
            # if the file doesn't exist or if -Force was specified
            # write the template
            if ( (-not(Test-Path $testFile)) -or
                ($Force)) {

                Invoke-EpsTemplate -Path $template -Binding @{
                    Visibility = $Source.Visibility
                    Type       = $Source.Type
                    Name       = $Source.Name
                    Noun       = $Source.Noun
                    Verb       = $Source.Verb
                } | Set-Content $testFile -Force
            } else {
                Write-Error "$testFile already exists (-Force to overwrite)"
            }
        } catch {
            Write-Error "Could not create test item`n$_"
        }
    }
    end {}
}
#endregion public Section
