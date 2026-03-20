BeforeDiscovery {
    $script:files = Get-ChildItem -Path .\src -Filter '*.ps1' -Recurse
}

BeforeAll {
    $script:ScriptAnalyzerSettings = @{
        IncludeDefaultRules = $true
        Severity            = @('Warning', 'Error')
        ExcludeRules        = @('PSAvoidUsingWriteHost')
    }

    $script:data = Get-MAProjectInfo
    $script:psmPresent = Test-Path -Path $data.ModuleFilePSM1
    $script:psdPresent = Test-Path -Path $data.ManifestFilePSD1
    $script:publicFunctions = Get-ChildItem -Path $script:data.PublicDir -Filter '*.ps1'
    $script:privateFunctions = Get-ChildItem -Path $script:data.PrivateDir -Filter '*.ps1'
}

Describe 'File: <_.basename>' -ForEach $files -Tag 'FunctionQA' {
    Context 'Code Quality Check' {
        It 'is valid PowerShell Code' {
            $psFile = Get-Content -Path $_ -ErrorAction Stop
            $errors = $null
            $null = [System.Management.Automation.PSParser]::Tokenize($psFile, [ref]$errors)
            $errors.Count | Should -Be 0
        }

        It 'passess ScriptAnalyzer' {
            $saResults = Invoke-ScriptAnalyzer -Path $_ -Settings $ScriptAnalyzerSettings
            $saResults | Should -BeNullOrEmpty -Because $($saResults.Message -join ';')
        }
    }
}

Describe 'Function and File Name Consistency' -Tag 'FunctionQA' {
    Context 'Public Function and File Naming Consistency' {
        It 'public functions should have matching file and function names' {
            if ($script:publicFunctions.Count -eq 0) {
                Set-ItResult -Skip -Because 'No public functions found'
                return
            }

            $results = @()
            foreach ($file in $script:publicFunctions) {
                try {
                    $content = Get-Content -Path $file.FullName -Raw
                    $ast = [System.Management.Automation.Language.Parser]::ParseInput($content, [ref]$null, [ref]$null)
                    $functionDefs = $ast.FindAll({ $args[0] -is [System.Management.Automation.Language.FunctionDefinitionAst] }, $false)

                    if ($functionDefs.Count -eq 0) {
                        $results += "File '$($file.Name)' - no function declaration found"
                    } else {
                        $functionName = $functionDefs[0].Name
                        $fileName = $file.BaseName

                        if ($functionName -ne $fileName) {
                            $results += "File '$($file.Name)' contains function '$functionName' (expected '$fileName')"
                        }
                    }
                } catch {
                    $results += "File '$($file.Name)' - failed to parse: $($_.Exception.Message)"
                }
            }

            $results.Count | Should -Be 0 -Because ($results -join '; ')
        }
    }

    Context 'Private Function and File Naming Consistency' {
        It 'private functions should have matching file and function names' {
            if ($script:privateFunctions.Count -eq 0) {
                Set-ItResult -Skip -Because 'No private functions found'
                return
            }

            $results = @()
            foreach ($file in $script:privateFunctions) {
                try {
                    $content = Get-Content -Path $file.FullName -Raw
                    $ast = [System.Management.Automation.Language.Parser]::ParseInput($content, [ref]$null, [ref]$null)
                    $functionDefs = $ast.FindAll({ $args[0] -is [System.Management.Automation.Language.FunctionDefinitionAst] }, $false)

                    if ($functionDefs.Count -eq 0) {
                        $results += "File '$($file.Name)' - no function declaration found"
                    } else {
                        $functionName = $functionDefs[0].Name
                        $fileName = $file.BaseName

                        if ($functionName -ne $fileName) {
                            $results += "File '$($file.Name)' contains function '$functionName' (expected '$fileName')"
                        }
                    }
                } catch {
                    $results += "File '$($file.Name)' - failed to parse: $($_.Exception.Message)"
                }
            }

            $results.Count | Should -Be 0 -Because ($results -join '; ')
        }
    }
}

Describe 'Built Module Testing' -Tag 'ModuleQA' {
    Context 'Module files exist' {
        It "$($data.ProjectName).psm1 should exist" {
            if (-not $script:psmPresent) {
                Set-ItResult -Skip
                return
            }

            $script:psmPresent | Should -BeTrue
        }

        It "$($data.ProjectName).psd1 should exist" {
            if (-not $script:psmPresent) {
                Set-ItResult -Skip
                return
            }

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

        It 'should have FunctionsToExport matching the public function names' {
            if (-not $script:psdPresent) {
                Set-ItResult -Skip
                return
            }

            $expectedFunctions = $script:publicFunctions.BaseName | Sort-Object
            $exportedFunctions = @($script:manifest.FunctionsToExport) | Sort-Object

            $exportedFunctions | Should -Not -Contain '*' -Because 'wildcard FunctionsToExport harms module load performance'
            $exportedFunctions.Count | Should -Be $expectedFunctions.Count -Because 'manifest FunctionsToExport count should match public function count'
            if ($expectedFunctions.Count -gt 0) {
                $exportedFunctions | Should -Be $expectedFunctions
            }
        }

        It 'should have AliasesToExport matching public function aliases' {
            if (-not $script:psdPresent) {
                Set-ItResult -Skip
                return
            }

            $expectedAliases = @(
                foreach ($file in $script:publicFunctions) {
                    $ast = [System.Management.Automation.Language.Parser]::ParseFile($file.FullName, [ref]$null, [ref]$null)
                    $functionNode = $ast.FindAll({
                            $args[0] -is [System.Management.Automation.Language.FunctionDefinitionAst]
                        }, $true)[0]
                    if ($functionNode) {
                        ($functionNode.Body.ParamBlock.Attributes |
                            Where-Object { $_.TypeName -like 'Alias' } |
                            ForEach-Object PositionalArguments).Value
                        }
                    }
                ) | Sort-Object

                $rawAliasesToExport = @($script:manifest.AliasesToExport) | Sort-Object

                $rawAliasesToExport | Should -Not -Contain '*' -Because 'wildcard AliasesToExport harms module load performance'
                $rawAliasesToExport.Count | Should -Be $expectedAliases.Count -Because 'manifest AliasesToExport count should match aliases defined in public functions'
                if ($expectedAliases.Count -gt 0) {
                    $rawAliasesToExport | Should -Be $expectedAliases
                }
            }
        }
    }

    Describe 'General Module Control' -Tag 'ModuleQA' {
        It 'should import without errors' {
            if (-not $script:psmPresent -or -not $script:psdPresent) {
                Set-ItResult -Skip
                return
            }
            { Import-Module -Name $data.OutputModuleDir -ErrorAction Stop } | Should -Not -Throw
            Get-Module -Name $data.ProjectName | Should -Not -BeNullOrEmpty
        }
    }
