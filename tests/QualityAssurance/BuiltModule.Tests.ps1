BeforeAll {
    $script:data = Get-MAProjectInfo
    $script:files = Get-ChildItem $data.OutputModuleDir
    $script:psmPresent = Test-Path -Path $data.ModuleFilePSM1
    $script:psdPresent = Test-Path -Path $data.ManifestFilePSD1
    $script:ScriptAnalyzerSettings = @{
        IncludeDefaultRules = $true

        Severity            = @('Warning', 'Error')
        ExcludeRules        = @('PSAvoidUsingWriteHost')
    }
}

Describe 'Module Testing' -Tag 'Module' {
    Context 'Module files exist' {
        It "$($data.ProjectName).psm1 should exist" {
            $script:psmPresent | Should -BeTrue
        }

        It "$($data.ProjectName).psd1 should exist" {
            $script:psdPresent | Should -BeTrue
        }
    }

    Context 'PowerShell Script Module (psm1) file' {
        It 'is valid PowerShell Code' {
            if (-not $script:psmPresent) {
                Set-ItResult -Skip
                return
            }

            $psFile = Get-Content -Path $data.ModuleFilePSM1 -ErrorAction Stop
            $errors = $null
            $null = [System.Management.Automation.PSParser]::Tokenize($psFile, [ref]$errors)
            $errors.Count | Should -Be 0
        }

        It 'passess ScriptAnalyzer' {
            if (-not $script:psmPresent) {
                Set-ItResult -Skip
                return
            }

            $saResults = Invoke-ScriptAnalyzer -Path $data.ModuleFilePSM1 -Settings $ScriptAnalyzerSettings
            $saResults | Should -BeNullOrEmpty -Because $($saResults.Message -join ';')
        }
    }

    Context 'Manifest (psd1) file' {
        BeforeAll {
            if (Test-Path -Path $data.ManifestFilePSD1) {
                $script:manifest = Import-PowerShellDataFile -Path $data.ManifestFilePSD1
            }
        }

        It 'passes Test-ModuleManifest validation' {
            if (-not $script:psdPresent) {
                Set-ItResult -Skip
                return
            }

            { Test-ModuleManifest -Path $data.ManifestFilePSD1 -ErrorAction Stop } | Should -Not -Throw
        }

        It 'is RootModule correct' {
            if (-not $script:psdPresent) {
                Set-ItResult -Skip
                return
            }

            "$($data.ProjectName).psm1" | Should -Be $script:manifest.RootModule
        }

        It 'should have ModuleVersion matching moduleproject.json' {
            if (-not $script:psdPresent) {
                Set-ItResult -Skip
                return
            }

            [version]$sv = [semver]$data.Version
            $sv | Should -Be $script:manifest.ModuleVersion
        }

        It 'should have Prerelease matching moduleproject.json' {
            if (-not $script:psdPresent) {
                Set-ItResult -Skip
                return
            }

            $sv = [semver]$data.Version
            $sv.PreReleaseLabel | Should -Be $script:manifest.PrivateData.PSData.Prerelease
        }

        It 'should have GUID matching moduleproject.json' {
            if (-not $script:psdPresent) {
                Set-ItResult -Skip
                return
            }

            $data.Manifest.GUID | Should -Be $script:manifest.GUID
        }

        It 'should have Author matching moduleproject.json' {
            if (-not $script:psdPresent) {
                Set-ItResult -Skip
                return
            }

            $data.Manifest.Author | Should -Be $script:manifest.Author
        }

        It 'should have CompanyName matching moduleproject.json' {
            if (-not $script:psdPresent) {
                Set-ItResult -Skip
                return
            }

            if ([string]::IsNullOrEmpty($data.Manifest.CompanyName)) {
                $company = 'Unknown'
            } else {
                $company = $data.Manifest.CompanyName
            }

            $company | Should -Be $script:manifest.CompanyName
        }

        It 'should have Copyright matching moduleproject.json' {
            if (-not $script:psdPresent) {
                Set-ItResult -Skip
                return
            }

            if ([string]::IsNullOrEmpty($data.Manifest.CompanyName)) {
                $copyright = "(c) $($data.Manifest.Author). All rights reserved."
            } else {
                $copyright = "(c) $($data.Manifest.CompanyName). All rights reserved."
            }

            $copyright -eq $script:manifest.Copyright | Should -BeTrue
        }

        It 'should have PowerShellVersion matching moduleproject.json' {
            if (-not $script:psdPresent) {
                Set-ItResult -Skip
                return
            }

            $data.Manifest.PowerShellVersion | Should -Be $script:manifest.PowerShellVersion
        }

        It 'should have RequiredModules matching moduleproject.json' {
            if (-not $script:psdPresent) {
                Set-ItResult -Skip
                return
            }

            $manifestModules = @($script:manifest.RequiredModules)
            $projectModules = @($data.Manifest.RequiredModules)

            $manifestModules.Count | Should -Be $projectModules.Count -Because 'manifest should have same number of required modules as moduleassember.json'

            if ($projectModules.Count -gt 0) {
                foreach ($i in 0..($projectModules.Count - 1)) {
                    $projectModule = $projectModules[$i]
                    $manifestModule = $manifestModules[$i]

                    $manifestName = if ($manifestModule -is [string]) {
                        $manifestModule
                    } else {
                        $manifestModule.ModuleName
                    }
                    $manifestName | Should -Be $projectModule.ModuleName

                    if ($projectModule.ModuleVersion) {
                        $manifestModule.ModuleVersion | Should -Be $projectModule.ModuleVersion
                    }

                    if ($projectModule.MaximumVersion) {
                        $manifestModule.MaximumVersion | Should -Be $projectModule.MaximumVersion
                    }

                    if ($projectModule.RequiredVersion) {
                        $manifestModule.RequiredVersion | Should -Be $projectModule.RequiredVersion
                    }

                    if ($projectModule.GUID) {
                        $manifestModule.GUID | Should -Be $projectModule.GUID
                    }
                }
            }
        }
    }
}

Describe 'General Module Control' -Tag 'Module' {
    It 'should import without errors' {
        if (-not $script:psmPresent -or -not $script:psdPresent) {
            Set-ItResult -Skip
            return
        }
        { Import-Module -Name $data.OutputModuleDir -ErrorAction Stop } | Should -Not -Throw
        Get-Module -Name $data.ProjectName | Should -Not -BeNullOrEmpty
    }
}
