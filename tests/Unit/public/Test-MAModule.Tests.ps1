BeforeAll {
    $script:projectRoot = Split-Path -Path (Split-Path -Path (Split-Path -Path $PSScriptRoot -Parent) -Parent) -Parent
    . (Join-Path -Path $script:projectRoot -ChildPath 'src/private/Test-JsonSchema.ps1')
    . (Join-Path -Path $script:projectRoot -ChildPath 'src/public/Get-MAProjectInfo.ps1')
    . (Join-Path -Path $script:projectRoot -ChildPath 'src/public/Test-MAModule.ps1')
}

Describe 'Test-MAModule' -Tag 'Unit' {
    It 'throws when run from the Visual Studio Code PowerShell host' {
        Mock Get-Host { [pscustomobject]@{ Name = 'Visual Studio Code Host' } }

        { Test-MAModule } | Should-Throw -ExceptionMessage '*must be run from a pwsh terminal*'
    }

    It 'throws when moduleproject schema validation fails' {
        Mock Test-JsonSchema { $false }

        { Test-MAModule } | Should-Throw -ExceptionMessage '*did not pass validation*'
    }

    It 'passes configured filters and paths to Invoke-Pester' {
        Mock Test-JsonSchema { $true }
        Mock Get-MAProjectInfo {
            [PSCustomObject]@{
                Pester = @{
                    Run        = @{}
                    Output     = @{}
                    Filter     = @{}
                    TestResult = @{}
                }
            }
        }

        $script:capturedConfiguration = $null
        Mock Invoke-Pester {
            param($Configuration)
            $script:capturedConfiguration = $Configuration
            [PSCustomObject]@{
                Result      = 'Passed'
                FailedCount = 0
                TotalCount  = 3
            }
        }

        Test-MAModule -TagFilter @('Unit', 'ModuleQA') -ExcludeTagFilter @('Slow')

        $script:capturedConfiguration.Run.Path.Value | Should-BeCollection -Expected @('./tests')
        $script:capturedConfiguration.Filter.Tag.Value | Should-BeCollection -Expected @('Unit', 'ModuleQA')
        $script:capturedConfiguration.Filter.ExcludeTag.Value | Should-BeCollection -Expected @('Slow')
        $script:capturedConfiguration.TestResult.OutputPath.Value.Replace('\', '/') | Should-Be './dist/PesterTestResults.xml'
        ($script:capturedConfiguration.CodeCoverage.OutputPath.Value -replace '\\', '/') | Should-Be './dist/coverage.xml'
    }

    It 'accepts JSON-compatible Pester schema value types before creating Pester configuration' {
        Mock Test-JsonSchema { $true }
        Mock Get-MAProjectInfo {
            [PSCustomObject]@{
                Pester = @{
                    Run          = @{}
                    Output       = @{
                        Verbosity = 'Detailed'
                    }
                    Filter       = @{}
                    TestResult   = @{
                        Enabled      = $true
                        OutputFormat = 'JUnitXml'
                    }
                    Should       = @{
                        DisableV5 = $true
                    }
                    CodeCoverage = @{
                        Enabled               = $false
                        OutputFormat          = 'JaCoCo'
                        CoveragePercentTarget = [long] 75
                    }
                }
            }
        }

        $script:capturedConfiguration = $null
        Mock Invoke-Pester {
            param($Configuration)
            $script:capturedConfiguration = $Configuration
            [PSCustomObject]@{
                Result      = 'Passed'
                FailedCount = 0
                TotalCount  = 1
            }
        }

        Test-MAModule

        $script:capturedConfiguration.CodeCoverage.Enabled.Value | Should-BeFalse
        $script:capturedConfiguration.CodeCoverage.OutputFormat.Value | Should-Be 'JaCoCo'
        $script:capturedConfiguration.CodeCoverage.CoveragePercentTarget.Value | Should-HaveType ([decimal])
        $script:capturedConfiguration.CodeCoverage.CoveragePercentTarget.Value | Should-Be 75
        $script:capturedConfiguration.TestResult.Enabled.Value | Should-BeTrue
        $script:capturedConfiguration.TestResult.OutputFormat.Value | Should-Be 'JUnitXml'
        $script:capturedConfiguration.Should.DisableV5.Value | Should-BeTrue
        $script:capturedConfiguration.Output.Verbosity.Value | Should-Be 'Detailed'
    }

    It 'throws when any Pester test fails' {
        Mock Test-JsonSchema { $true }
        Mock Get-MAProjectInfo {
            [PSCustomObject]@{
                Pester = @{
                    Run        = @{}
                    Output     = @{}
                    Filter     = @{}
                    TestResult = @{}
                }
            }
        }

        Mock Invoke-Pester {
            [PSCustomObject]@{
                Result      = 'Failed'
                FailedCount = 2
                TotalCount  = 10
            }
        }

        { Test-MAModule } | Should-Throw -ExceptionMessage '*2 of 10 tests failed*'
    }
}
