BeforeDiscovery {
    $script:files = Get-ChildItem -Path .\src -Filter '*.ps1' -Recurse
}
BeforeAll {
    $script:ScriptAnalyzerSettings = @{
        IncludeDefaultRules = $true
        Severity            = @('Warning', 'Error')
        ExcludeRules        = @('PSAvoidUsingWriteHost')
    }
}
Describe 'File: <_.basename>' -ForEach $files -Tag 'Function' {
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

Describe 'Function and File Name Consistency' -Tag 'Function' {
    BeforeAll {
        $script:data = Get-MAProjectInfo
        $publicFunctions = Get-ChildItem -Path $data.PublicDir -Filter '*.ps1'
        $privateFunctions = Get-ChildItem -Path $data.PrivateDir -Filter '*.ps1'
    }

    Context 'Public Function and File Naming Consistency' {
        It 'public functions should have matching file and function names' {
            if ($publicFunctions.Count -eq 0) {
                Set-ItResult -Skip -Because 'No public functions found'
                return
            }

            $results = @()
            foreach ($file in $publicFunctions) {
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
            if ($privateFunctions.Count -eq 0) {
                Set-ItResult -Skip -Because 'No private functions found'
                return
            }

            $results = @()
            foreach ($file in $privateFunctions) {
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
