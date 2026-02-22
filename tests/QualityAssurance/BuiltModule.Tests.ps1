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
            $script:psmPresent | Should -Be $true
        }

        It "$($data.ProjectName).psd1 should exist" {
            $script:psdPresent | Should -Be $true
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

            "$($data.ProjectName).psm1" -eq $script:manifest.RootModule | Should -Be $true
        }

        It 'is ModuleVersion correct' {
            if (-not $script:psdPresent) {
                Set-ItResult -Skip
                return
            }

            [version]$sv = [semver]$data.Version
            $sv -eq $script:manifest.ModuleVersion | Should -Be $true
        }

        It 'is Prerelease correct' {
            if (-not $script:psdPresent) {
                Set-ItResult -Skip
                return
            }

            $sv = [semver]$data.Version
            $sv.PreReleaseLabel -eq $script:manifest.PrivateData.PSData.Prerelease | Should -Be $true
        }

        It 'is GUID correct' {
            if (-not $script:psdPresent) {
                Set-ItResult -Skip
                return
            }

            $data.Manifest.GUID -eq $script:manifest.GUID | Should -Be $true
        }

        It 'is Author correct' {
            if (-not $script:psdPresent) {
                Set-ItResult -Skip
                return
            }

            $data.Manifest.Author -eq $script:manifest.Author | Should -Be $true
        }

        It 'is CompanyName correct' {
            if (-not $script:psdPresent) {
                Set-ItResult -Skip
                return
            }

            if ([string]::IsNullOrEmpty($data.Manifest.CompanyName)) {
                $company = 'Unknown'
            } else {
                $company = $data.Manifest.CompanyName
            }

            $company -eq $script:manifest.CompanyName | Should -Be $true
        }

        It 'is Copyright correct' {
            if (-not $script:psdPresent) {
                Set-ItResult -Skip
                return
            }

            if ([string]::IsNullOrEmpty($data.Manifest.CompanyName)) {
                $copyright = "(c) $($data.Manifest.Author). All rights reserved."
            } else {
                $copyright = "(c) $($data.Manifest.CompanyName). All rights reserved."
            }

            $copyright -eq $script:manifest.Copyright | Should -Be $true
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
