BeforeAll {
    $script:projectRoot = Split-Path -Path (Split-Path -Path (Split-Path -Path $PSScriptRoot -Parent) -Parent) -Parent
    . (Join-Path -Path $script:projectRoot -ChildPath 'src/private/Test-JsonSchema.ps1')
    . (Join-Path -Path $script:projectRoot -ChildPath 'src/public/Get-MAProjectInfo.ps1')
    . (Join-Path -Path $script:projectRoot -ChildPath 'src/public/Test-MAModule.ps1')
}

Describe 'Test-MAModule' -Tag 'Unit' {
    BeforeEach {
        $script:testProjectRoot = Join-Path -Path $TestDrive -ChildPath 'DemoModule'
        $script:testResourcesDir = Join-Path -Path $script:testProjectRoot -ChildPath 'src/resources'
        $script:localQaDirectory = Join-Path -Path $script:testProjectRoot -ChildPath 'tests/QualityAssurance'
        $script:localQaPath = Join-Path -Path $script:localQaDirectory -ChildPath 'QA.Tests.ps1'
        $script:localCompliancePath = Join-Path -Path $script:localQaDirectory -ChildPath 'ProjectCompliance.Tests.ps1'

        $bundledQaDirectoryCandidates = @()
        $moduleBase = (Get-Command Test-MAModule -ErrorAction SilentlyContinue).Module.ModuleBase
        if ($moduleBase) {
            $bundledQaDirectoryCandidates += Join-Path -Path $moduleBase -ChildPath 'resources/PesterTests/QualityAssurance'
            $bundledQaDirectoryCandidates += Join-Path -Path $moduleBase -ChildPath 'PesterTests/QualityAssurance'
        }

        $script:bundledQaDirectory = $bundledQaDirectoryCandidates |
            Where-Object { Test-Path -LiteralPath $_ -PathType Container } |
            Select-Object -First 1
        if (-not $script:bundledQaDirectory) {
            $script:bundledQaDirectory = Join-Path -Path $script:testResourcesDir -ChildPath 'PesterTests/QualityAssurance'
            New-Item -Path $script:bundledQaDirectory -ItemType Directory -Force | Out-Null
            Set-Content -Path (Join-Path -Path $script:bundledQaDirectory -ChildPath 'QA.Tests.ps1') -Value 'Bundled QA content'
            Set-Content -Path (Join-Path -Path $script:bundledQaDirectory -ChildPath 'ProjectCompliance.Tests.ps1') -Value 'Bundled compliance content'
        }

        $script:bundledQaPath = Join-Path -Path $script:bundledQaDirectory -ChildPath 'QA.Tests.ps1'
        $script:bundledCompliancePath = Join-Path -Path $script:bundledQaDirectory -ChildPath 'ProjectCompliance.Tests.ps1'
        New-Item -Path $script:localQaDirectory -ItemType Directory -Force | Out-Null
        [System.IO.File]::WriteAllText($script:localQaPath, [System.IO.File]::ReadAllText($script:bundledQaPath))
        [System.IO.File]::WriteAllText($script:localCompliancePath, [System.IO.File]::ReadAllText($script:bundledCompliancePath))
    }

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
                ProjectName  = 'DemoModule'
                ProjectRoot  = $script:testProjectRoot
                ResourcesDir = $script:testResourcesDir
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
                ProjectName  = 'DemoModule'
                ProjectRoot  = $script:testProjectRoot
                ResourcesDir = $script:testResourcesDir
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
                ProjectName  = 'DemoModule'
                ProjectRoot  = $script:testProjectRoot
                ResourcesDir = $script:testResourcesDir
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

    It 'adds bundled QA and excludes a divergent legacy QA copy' {
        Set-Content -Path $script:localQaPath -Value 'Customized local QA'
        Mock Test-JsonSchema { $true }
        Mock Get-MAProjectInfo {
            [PSCustomObject]@{
                ProjectName  = 'DemoModule'
                ProjectRoot  = $script:testProjectRoot
                ResourcesDir = $script:testResourcesDir
                Pester       = @{ Run = @{}; Output = @{}; Filter = @{}; TestResult = @{} }
            }
        }
        $script:capturedConfiguration = $null
        $script:capturedWarning = $null
        Mock Invoke-Pester {
            param($Configuration)
            $script:capturedConfiguration = $Configuration
            [PSCustomObject]@{ Result = 'Passed'; FailedCount = 0; TotalCount = 1 }
        }
        Mock Write-Warning { $script:capturedWarning = $Message }

        Test-MAModule

        $script:capturedConfiguration.Run.Path.Value | Should-BeCollection -Expected @('./tests', $script:bundledQaPath)
        $script:capturedConfiguration.Run.ExcludePath.Value | Should-ContainCollection -Expected @($script:localQaPath)
        $script:capturedWarning | Should-MatchString 'Move custom assertions'
    }

    It 'adds every bundled QA file when the project has no local QA copies' {
        Remove-Item -LiteralPath $script:localQaDirectory -Recurse -Force
        Mock Test-JsonSchema { $true }
        Mock Get-MAProjectInfo {
            [PSCustomObject]@{
                ProjectName  = 'DemoModule'
                ProjectRoot  = $script:testProjectRoot
                ResourcesDir = $script:testResourcesDir
                Pester       = @{ Run = @{}; Output = @{}; Filter = @{}; TestResult = @{} }
            }
        }
        $script:capturedConfiguration = $null
        Mock Invoke-Pester {
            param($Configuration)
            $script:capturedConfiguration = $Configuration
            [PSCustomObject]@{ Result = 'Passed'; FailedCount = 0; TotalCount = 1 }
        }

        Test-MAModule

        $script:capturedConfiguration.Run.Path.Value | Should-BeCollection -Expected @('./tests', $script:bundledCompliancePath, $script:bundledQaPath)
    }

    It 'skips bundled QA but keeps a divergent local QA copy enabled' {
        Set-Content -Path $script:localQaPath -Value 'Customized local QA'
        Mock Test-JsonSchema { $true }
        Mock Get-MAProjectInfo {
            [PSCustomObject]@{
                ProjectName  = 'DemoModule'
                ProjectRoot  = $script:testProjectRoot
                ResourcesDir = $script:testResourcesDir
                Pester       = @{ Run = @{}; Output = @{}; Filter = @{}; TestResult = @{} }
            }
        }
        $script:capturedConfiguration = $null
        $script:capturedWarning = $null
        Mock Invoke-Pester {
            param($Configuration)
            $script:capturedConfiguration = $Configuration
            [PSCustomObject]@{ Result = 'Passed'; FailedCount = 0; TotalCount = 1 }
        }
        Mock Write-Warning { $script:capturedWarning = $Message }

        Test-MAModule -SkipBundledQA

        $script:capturedConfiguration.Run.Path.Value | Should-BeCollection -Expected @('./tests')
        $script:capturedConfiguration.Run.ExcludePath.Value.Count | Should-Be 0
        $script:capturedWarning | Should-MatchString 'may be customized or outdated'
    }

    It 'keeps the ModuleAssembler source QA suite canonical' {
        Set-Content -Path $script:localQaPath -Value 'Canonical source QA'
        Set-Content -Path $script:bundledQaPath -Value 'Stale packaged mirror'
        New-Item -Path (Join-Path -Path $script:testProjectRoot -ChildPath 'src/public') -ItemType Directory -Force | Out-Null
        New-Item -Path (Join-Path -Path $script:testProjectRoot -ChildPath 'src/public/Test-MAModule.ps1') -ItemType File -Force | Out-Null
        Mock Test-JsonSchema { $true }
        Mock Get-MAProjectInfo {
            [PSCustomObject]@{
                ProjectName  = 'ModuleAssembler'
                ProjectRoot  = $script:testProjectRoot
                ResourcesDir = $script:testResourcesDir
                Pester       = @{ Run = @{}; Output = @{}; Filter = @{}; TestResult = @{} }
            }
        }
        $script:capturedConfiguration = $null
        Mock Invoke-Pester {
            param($Configuration)
            $script:capturedConfiguration = $Configuration
            [PSCustomObject]@{ Result = 'Passed'; FailedCount = 0; TotalCount = 1 }
        }

        Test-MAModule

        $script:capturedConfiguration.Run.Path.Value | Should-BeCollection -Expected @('./tests')
        $script:capturedConfiguration.Run.ExcludePath.Value.Count | Should-Be 0
    }
}
