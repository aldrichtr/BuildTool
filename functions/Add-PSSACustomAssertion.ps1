<#
.SYNOPSIS
    Custom assertion for PSScriptAnalyzer tests
.DESCRIPTION
    A Pester Should function will output 'Expected foo but got bar'
    We want nicer messages like:
    Rule violation: <rule name>
    <rule message>
    <file:line:column>
    <file:line:column>
    <file:line:column>
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
