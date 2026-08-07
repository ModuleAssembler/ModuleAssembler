BeforeAll {
    $script:projectRoot = Split-Path -Path (Split-Path -Path (Split-Path -Path $PSScriptRoot -Parent) -Parent) -Parent
    . (Join-Path -Path $script:projectRoot -ChildPath 'src/public/Get-MAProjectInfo.ps1')
    . (Join-Path -Path $script:projectRoot -ChildPath 'src/public/Test-MAModule.ps1')
}

Describe 'Test-MAModule' -Tag 'Unit' {
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
