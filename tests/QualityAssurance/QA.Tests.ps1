BeforeDiscovery {
    $data = Get-MAProjectInfo
    $script:classFiles = Get-ChildItem -Path $data.ClassesDir -Filter '*.ps1'
    $script:files = @(
        Get-ChildItem -Path $data.PublicDir -Filter '*.ps1'
        Get-ChildItem -Path $data.PrivateDir -Filter '*.ps1'
    )
}

BeforeAll {
    $script:ScriptAnalyzerSettings = [System.IO.Path]::Combine($PSScriptRoot, '..', '..', 'PSScriptAnalyzerSettings.psd1')
    $script:data = Get-MAProjectInfo
    $script:psmPresent = Test-Path -Path $data.ModuleFilePSM1
    $script:psdPresent = Test-Path -Path $data.ManifestFilePSD1
    $script:publicFunctions = Get-ChildItem -Path $script:data.PublicDir -Filter '*.ps1'
    $script:privateFunctions = Get-ChildItem -Path $script:data.PrivateDir -Filter '*.ps1'
}

Describe 'Class File: <_.BaseName>' -ForEach $classFiles -AllowNullOrEmptyForEach -Tag 'FunctionQA' {
    Context 'Code Quality Check' {
        It 'is valid PowerShell Code' {
            $psFile = Get-Content -Path $_ -ErrorAction Stop
            $errors = $null
            $null = [System.Management.Automation.PSParser]::Tokenize($psFile, [ref]$errors)
            $errors.Count | Should-Be 0
        }

        It 'passes ScriptAnalyzer' {
            $saResults = Invoke-ScriptAnalyzer -Path $_ -Settings $ScriptAnalyzerSettings
            @($saResults).Count | Should-Be 0 -Because $($saResults.Message -join ';')
        }
    }
}

Describe 'File: <_.BaseName>' -ForEach $files -AllowNullOrEmptyForEach -Tag 'FunctionQA' {
    Context 'Code Quality Check' {
        It 'is valid PowerShell Code' {
            $psFile = Get-Content -Path $_ -ErrorAction Stop
            $errors = $null
            $null = [System.Management.Automation.PSParser]::Tokenize($psFile, [ref]$errors)
            $errors.Count | Should-Be 0
        }

        It 'passes ScriptAnalyzer' {
            $saResults = Invoke-ScriptAnalyzer -Path $_ -Settings $ScriptAnalyzerSettings
            @($saResults).Count | Should-Be 0 -Because $($saResults.Message -join ';')
        }

        It 'has comment-based help .SYNOPSIS' {
            $content = Get-Content -Path $_.FullName -Raw
            $ast = [System.Management.Automation.Language.Parser]::ParseInput($content, [ref]$null, [ref]$null)
            $functionDefs = $ast.FindAll({ $args[0] -is [System.Management.Automation.Language.FunctionDefinitionAst] }, $false)
            $functionHelp = $functionDefs.GetHelpContent()

            $functionHelp.Synopsis | Should-NotBeWhiteSpaceString
        }

        It 'has comment-based help .DESCRIPTION' {
            $content = Get-Content -Path $_.FullName -Raw
            $ast = [System.Management.Automation.Language.Parser]::ParseInput($content, [ref]$null, [ref]$null)
            $functionDefs = $ast.FindAll({ $args[0] -is [System.Management.Automation.Language.FunctionDefinitionAst] }, $false)
            $functionHelp = $functionDefs.GetHelpContent()

            $functionHelp.Description | Should-NotBeWhiteSpaceString
        }

        It 'has comment-based help with at least one .EXAMPLE' {
            $content = Get-Content -Path $_.FullName -Raw
            $ast = [System.Management.Automation.Language.Parser]::ParseInput($content, [ref]$null, [ref]$null)
            $functionDefs = $ast.FindAll({ $args[0] -is [System.Management.Automation.Language.FunctionDefinitionAst] }, $false)
            $functionHelp = $functionDefs.GetHelpContent()

            $functionHelp.Examples.Count | Should-BeGreaterThan 0
            $functionHelp.Examples[0] | Should-MatchString ([regex]::Escape($_.BaseName))
        }

        It 'has comment-based help examples with a blank line between code and description' {
            $content = Get-Content -Path $_.FullName -Raw
            $ast = [System.Management.Automation.Language.Parser]::ParseInput($content, [ref]$null, [ref]$null)
            $functionDefs = $ast.FindAll({ $args[0] -is [System.Management.Automation.Language.FunctionDefinitionAst] }, $false)
            $functionHelp = $functionDefs.GetHelpContent()

            foreach ($example in $functionHelp.Examples) {
                $exampleSections = @(
                    $example -split '\r?\n\s*\r?\n' |
                        ForEach-Object { $_.Trim() } |
                        Where-Object { $_ -ne '' }
                )

                $exampleSections.Count | Should-BeGreaterThanOrEqual 2 -Because ('the example in {0} must contain code, then a blank line, then a description paragraph' -f $_.BaseName)

                $descriptionLines = @(
                    $exampleSections[1] -split '\r?\n' |
                        ForEach-Object { $_.Trim() } |
                        Where-Object { $_ -ne '' }
                )

                $descriptionLines.Count | Should-BeGreaterThan 0 -Because ('the example description in {0} must not be empty' -f $_.BaseName)
            }
        }

        It 'has comment-based help with .PARAMETER for each declared parameter' {
            $content = Get-Content -Path $_.FullName -Raw
            $ast = [System.Management.Automation.Language.Parser]::ParseInput($content, [ref]$null, [ref]$null)
            $functionDefs = $ast.FindAll({ $args[0] -is [System.Management.Automation.Language.FunctionDefinitionAst] }, $false)
            $functionHelp = $functionDefs.GetHelpContent()

            $parameters = $functionDefs.Body.ParamBlock.Parameters.Name.VariablePath.ForEach({ $_.ToString() })

            foreach ($parameter in $parameters) {
                $functionHelp.Parameters.($parameter.ToUpper()) | Should-NotBeWhiteSpaceString -Because ('the parameter {0} must have a .PARAMETER definition' -f $parameter)
            }
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

            $results.Count | Should-Be 0 -Because ($results -join '; ')
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

            $results.Count | Should-Be 0 -Because ($results -join '; ')
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

            $script:psmPresent | Should-BeTrue
        }

        It "$($data.ProjectName).psd1 should exist" {
            if (-not $script:psmPresent) {
                Set-ItResult -Skip
                return
            }

            $script:psdPresent | Should-BeTrue
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
            $errors.Count | Should-Be 0
        }

        It 'passes ScriptAnalyzer' {
            if (-not $script:psmPresent) {
                Set-ItResult -Skip
                return
            }

            $saResults = Invoke-ScriptAnalyzer -Path $data.ModuleFilePSM1 -Settings $ScriptAnalyzerSettings
            @($saResults).Count | Should-Be 0 -Because $($saResults.Message -join ';')
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

            $caughtError = $null
            try {
                Test-ModuleManifest -Path $data.ManifestFilePSD1 -ErrorAction Stop | Out-Null
            } catch {
                $caughtError = $_
            }
            $caughtError | Should-BeNull
        }

        It 'is RootModule correct' {
            if (-not $script:psdPresent) {
                Set-ItResult -Skip
                return
            }

            "$($data.ProjectName).psm1" | Should-Be $script:manifest.RootModule
        }

        It 'should have ModuleVersion matching moduleproject.json' {
            if (-not $script:psdPresent) {
                Set-ItResult -Skip
                return
            }

            [version]$sv = [semver]$data.Version
            $sv | Should-Be $script:manifest.ModuleVersion
        }

        It 'should have Prerelease matching moduleproject.json' {
            if (-not $script:psdPresent) {
                Set-ItResult -Skip
                return
            }

            $sv = [semver]$data.Version
            $sv.PreReleaseLabel | Should-Be $script:manifest.PrivateData.PSData.Prerelease
        }

        It 'should have GUID matching moduleproject.json' {
            if (-not $script:psdPresent) {
                Set-ItResult -Skip
                return
            }

            $data.Manifest.GUID | Should-Be $script:manifest.GUID
        }

        It 'should have Author matching moduleproject.json' {
            if (-not $script:psdPresent) {
                Set-ItResult -Skip
                return
            }

            $data.Manifest.Author | Should-Be $script:manifest.Author
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

            $company | Should-Be $script:manifest.CompanyName
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

            ($copyright -eq $script:manifest.Copyright) | Should-BeTrue
        }

        It 'should have PowerShellVersion matching moduleproject.json' {
            if (-not $script:psdPresent) {
                Set-ItResult -Skip
                return
            }

            $data.Manifest.PowerShellVersion | Should-Be $script:manifest.PowerShellVersion
        }

        It 'should have RequiredModules matching moduleproject.json' {
            if (-not $script:psdPresent) {
                Set-ItResult -Skip
                return
            }

            $manifestModules = @($script:manifest.RequiredModules)
            $projectModules = @($data.Manifest.RequiredModules)

            $manifestModules.Count | Should-Be $projectModules.Count -Because 'manifest should have same number of required modules as moduleassember.json'

            if ($projectModules.Count -gt 0) {
                foreach ($i in 0..($projectModules.Count - 1)) {
                    $projectModule = $projectModules[$i]
                    $manifestModule = $manifestModules[$i]

                    $manifestName = if ($manifestModule -is [string]) {
                        $manifestModule
                    } else {
                        $manifestModule.ModuleName
                    }
                    $manifestName | Should-Be $projectModule.ModuleName

                    if ($projectModule.ModuleVersion) {
                        $manifestModule.ModuleVersion | Should-Be $projectModule.ModuleVersion
                    }

                    if ($projectModule.MaximumVersion) {
                        $manifestModule.MaximumVersion | Should-Be $projectModule.MaximumVersion
                    }

                    if ($projectModule.RequiredVersion) {
                        $manifestModule.RequiredVersion | Should-Be $projectModule.RequiredVersion
                    }

                    if ($projectModule.GUID) {
                        $manifestModule.GUID | Should-Be $projectModule.GUID
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

            $exportedFunctions | Should-NotContainCollection '*' -Because 'wildcard FunctionsToExport harms module load performance'
            $exportedFunctions.Count | Should-Be $expectedFunctions.Count -Because 'manifest FunctionsToExport count should match public function count'

            if ($expectedFunctions.Count -gt 0) {
                Should-BeCollection -Actual $exportedFunctions -Expected $expectedFunctions
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

                $rawAliasesToExport | Should-NotContainCollection '*' -Because 'wildcard AliasesToExport harms module load performance'
                $rawAliasesToExport.Count | Should-Be $expectedAliases.Count -Because 'manifest AliasesToExport count should match aliases defined in public functions'
                if ($expectedAliases.Count -gt 0) {
                    Should-BeCollection -Actual $rawAliasesToExport -Expected $expectedAliases
                }
            }

            It 'should have Tags without blank spaces' {
                if (-not $script:psdPresent) {
                    Set-ItResult -Skip
                    return
                }

                $tags = @($script:manifest.PrivateData.PSData.Tags)
                $invalidTags = @($tags | Where-Object { $_ -match '\s' })

                $invalidTags.Count | Should-Be 0 -Because ('PowerShell Gallery tags cannot contain spaces: {0}' -f ($invalidTags -join ', '))
            }

            It 'should have a combined Tags length of less than 4000 characters' {
                if (-not $script:psdPresent) {
                    Set-ItResult -Skip
                    return
                }

                $tags = @($script:manifest.PrivateData.PSData.Tags)
                $combinedLength = ($tags -join '').Length

                $combinedLength | Should-BeLessThan 4000 -Because 'PowerShell Gallery limits the combined length of all tags to 4000 characters'
            }

            It 'should have at least one PSEdition compatibility Tag' {
                if (-not $script:psdPresent) {
                    Set-ItResult -Skip
                    return
                }

                $tags = @($script:manifest.PrivateData.PSData.Tags)
                $editionTags = @($tags | Where-Object { $_ -in 'PSEdition_Desktop', 'PSEdition_Core' })

                $editionTags.Count | Should-BeGreaterThan 0 -Because 'Tags must denote PowerShell edition compatibility using PSEdition_Desktop and/or PSEdition_Core'
            }

            It 'should have at least one operating system compatibility Tag' {
                if (-not $script:psdPresent) {
                    Set-ItResult -Skip
                    return
                }

                $tags = @($script:manifest.PrivateData.PSData.Tags)
                $osTags = @($tags | Where-Object { $_ -in 'Windows', 'Linux', 'MacOS' })

                $osTags.Count | Should-BeGreaterThan 0 -Because 'Tags must denote operating system compatibility using Windows, Linux and/or MacOS'
            }
        }
    }

    Describe 'General Module Control' -Tag 'ModuleQA' {
        It 'should import without error' {
            if (-not $script:psmPresent -or -not $script:psdPresent) {
                Set-ItResult -Skip
                return
            }

            $caughtError = $null
            try {
                Import-Module -Name $data.OutputModuleDir -Force -ErrorAction Stop
            } catch {
                $caughtError = $_
            }

            $caughtError | Should-BeNull
            Get-Module -Name $data.ProjectName | Should-NotBeNull
        }

        It 'should remove without error' {
            if (-not $script:psmPresent -or -not $script:psdPresent) {
                Set-ItResult -Skip
                return
            }

            if (-not (Get-Module -Name $data.ProjectName)) {
                Import-Module -Name $data.OutputModuleDir -Force -ErrorAction Stop
            }

            $caughtError = $null
            try {
                Remove-Module -Name $data.ProjectName -ErrorAction Stop
            } catch {
                $caughtError = $_
            }

            $caughtError | Should-BeNull
            Get-Module $data.ProjectName | Should-BeNull
        }
    }
