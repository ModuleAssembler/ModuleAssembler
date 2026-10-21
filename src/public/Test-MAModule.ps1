function Test-MAModule {
    <#
    .SYNOPSIS
        Runs project tests and the bundled ModuleAssembler QA suite.

    .DESCRIPTION
        Runs project tests from the project's "tests" directory and the QA suite bundled
        with ModuleAssembler. The Pester configuration is loaded from the "Pester" section
        of ".moduleassembler/moduleproject.json".

        Run this command from the module project directory. Tests are discovered from the
        project's "tests" directory. The bundled QA suite is run separately unless an
        identical local copy is already present.

        TagFilter and ExcludeTagFilter apply to both project tests and bundled QA tests.

        The bundled QA tests use the following tags:

        - FunctionQA: Checks source syntax, ScriptAnalyzer results, comment-based help, and function-to-file naming.
        - ModuleQA: Checks built module files, manifest metadata, exports, and module import and removal.
        - ChangeLog: Checks the changelog file and its structure and release references.
        - License: Checks that the license file is present, non-empty, and a recognized supported license.

        Test results and code coverage reports are written to the project's "dist"
        directory. The command throws an error if the project configuration is invalid
        or if one or more tests fail.

    .PARAMETER TagFilter
        One or more Pester tags. Only tests with at least one matching tag are run.
        If omitted, all tests are eligible to run unless excluded with ExcludeTagFilter.

    .PARAMETER ExcludeTagFilter
        One or more Pester tags. Tests with any matching tag are excluded.
        Exclusions are applied together with TagFilter when both parameters are specified.

    .PARAMETER SkipBundledQA
        Skip the ModuleAssembler QA suite bundled with the installed module. Project tests,
        including an exported local QA suite, continue to run.

    .EXAMPLE
        Test-MAModule

        Execute all Pester tests.

    .EXAMPLE
        Test-MAModule -TagFilter 'unit','FunctionQA'

        Execute only Pester tests with the tags unit or FunctionQA.

    .EXAMPLE
        Test-MAModule -ExcludeTagFilter 'unit'

        Runs the Pester tests, excludes any test with tag unit.

    .EXAMPLE
        Test-MAModule -SkipBundledQA

        Runs project tests without the ModuleAssembler bundled QA suite.
    #>

    [CmdletBinding(PositionalBinding = $false)]
    [OutputType([void])]
    [Alias('MATest')]
    param (
        [Parameter(Mandatory = $false)]
        [ValidateNotNullOrEmpty()]
        [string[]] $TagFilter,

        [Parameter(Mandatory = $false)]
        [ValidateNotNullOrEmpty()]
        [string[]] $ExcludeTagFilter,

        [Parameter(Mandatory = $false)]
        [switch] $SkipBundledQA
    )

    begin {
        if ((Get-Host).Name -eq 'Visual Studio Code Host') {
            throw 'Test-MAModule must be run from a pwsh terminal, not the PowerShell Extension''s integrated console, which cannot reliably resolve some binary module commands (e.g. Invoke-ScriptAnalyzer).'
        }

        if (!(Test-JsonSchema)) {
            throw 'The JSON in moduleproject.json did not pass validation.'
        }

        $data = Get-MAProjectInfo
        if ($null -ne $data.Pester.CodeCoverage.CoveragePercentTarget) {
            $data.Pester.CodeCoverage.CoveragePercentTarget = [decimal] $data.Pester.CodeCoverage.CoveragePercentTarget
        }

        $pesterConfig = New-PesterConfiguration -Hashtable $data.Pester
    }

    process {
        $localQaDirectory = Join-Path -Path $data.ProjectRoot -ChildPath 'tests/QualityAssurance'
        $qaRelativeDirectory = [System.IO.Path]::Combine('PesterTests', 'QualityAssurance')
        $bundledQaDirectoryCandidates = @()
        $moduleBase = $PSCmdlet.MyInvocation.MyCommand.Module.ModuleBase

        if ($moduleBase) {
            $bundledQaDirectoryCandidates += Join-Path -Path $moduleBase -ChildPath (Join-Path -Path 'resources' -ChildPath $qaRelativeDirectory)
            $bundledQaDirectoryCandidates += Join-Path -Path $moduleBase -ChildPath $qaRelativeDirectory
        }

        $bundledQaDirectoryCandidates += Join-Path -Path $data.ResourcesDir -ChildPath $qaRelativeDirectory
        $bundledQaDirectory = $bundledQaDirectoryCandidates |
            Where-Object { Test-Path -LiteralPath $_ -PathType Container } |
            Select-Object -First 1

        $bundledQaFiles = if ($bundledQaDirectory) {
            @(Get-ChildItem -LiteralPath $bundledQaDirectory -Filter '*.Tests.ps1' -File | Sort-Object Name)
        } else {
            @()
        }

        $qaFileComparisons = @(
            foreach ($bundledQaFile in $bundledQaFiles) {
                $localQaPath = Join-Path -Path $localQaDirectory -ChildPath $bundledQaFile.Name
                $localQaExists = Test-Path -LiteralPath $localQaPath -PathType Leaf
                $qaFilesMatch = $false
                if ($localQaExists) {
                    $localQaContent = [System.IO.File]::ReadAllText($localQaPath).Replace("`r`n", "`n").Replace("`r", "`n")
                    $bundledQaContent = [System.IO.File]::ReadAllText($bundledQaFile.FullName).Replace("`r`n", "`n").Replace("`r", "`n")
                    $sha256 = [System.Security.Cryptography.SHA256]::Create()
                    try {
                        $localQaHash = [System.BitConverter]::ToString(
                            $sha256.ComputeHash([System.Text.Encoding]::UTF8.GetBytes($localQaContent))
                        ).Replace('-', '')
                        $bundledQaHash = [System.BitConverter]::ToString(
                            $sha256.ComputeHash([System.Text.Encoding]::UTF8.GetBytes($bundledQaContent))
                        ).Replace('-', '')
                        $qaFilesMatch = $localQaHash -eq $bundledQaHash
                    } finally {
                        $sha256.Dispose()
                    }
                }

                [PSCustomObject]@{
                    BundledPath = $bundledQaFile.FullName
                    LocalPath   = $localQaPath
                    LocalExists = $localQaExists
                    Matches     = $qaFilesMatch
                }
            }
        )

        $isModuleAssemblerSourceProject = $data.ProjectName -eq 'ModuleAssembler' -and
        (Test-Path -LiteralPath (Join-Path -Path $data.ProjectRoot -ChildPath 'src/public/Test-MAModule.ps1'))

        $testPaths = @('./tests')
        if ($SkipBundledQA.IsPresent) {
            $mismatchedLocalPaths = @($qaFileComparisons | Where-Object { $_.LocalExists -and -not $_.Matches } | ForEach-Object LocalPath)
            if ($mismatchedLocalPaths.Count -gt 0) {
                Write-Warning "Local QA tests differ from bundled templates and may be customized or outdated: $($mismatchedLocalPaths -join ', '). They remain enabled because -SkipBundledQA was specified."
            }
        } elseif ($bundledQaFiles.Count -eq 0) {
            throw 'The bundled ModuleAssembler QA test files could not be found. Use -SkipBundledQA to run project tests only.'
        } else {
            $bundledPathsToRun = @(
                $qaFileComparisons |
                    Where-Object {
                        (-not $isModuleAssemblerSourceProject -or -not $_.LocalExists) -and
                        (-not $_.LocalExists -or -not $_.Matches)
                    } |
                    ForEach-Object BundledPath
            )
            $divergentLocalPaths = @(
                $qaFileComparisons |
                    Where-Object {
                        -not $isModuleAssemblerSourceProject -and $_.LocalExists -and -not $_.Matches
                    } |
                    ForEach-Object LocalPath
            )

            $testPaths += $bundledPathsToRun
            if ($divergentLocalPaths.Count -gt 0) {
                $pesterConfig.Run.ExcludePath = @($pesterConfig.Run.ExcludePath.Value) + $divergentLocalPaths
                Write-Warning "Local QA tests differ from bundled templates and were excluded: $($divergentLocalPaths -join ', '). Move custom assertions to separate project test files; bundled QA will run instead."
            }
        }

        $pesterConfig.Run.Path = $testPaths
        $pesterConfig.Run.PassThru = $true
        $pesterConfig.Run.Exit = $false
        $pesterConfig.Run.Throw = $false
        $pesterConfig.Filter.Tag = $TagFilter
        $pesterConfig.Filter.ExcludeTag = $ExcludeTagFilter
        $pesterConfig.TestResult.OutputPath = [System.IO.Path]::Combine('.', 'dist', 'PesterTestResults.xml')
        $pesterConfig.CodeCoverage.OutputPath = [System.IO.Path]::Combine('.', 'dist', 'coverage.xml')

        $TestResult = Invoke-Pester -Configuration $pesterConfig
        if ($TestResult.Result -ne 'Passed') {
            Write-Error "$($TestResult.FailedCount) of $($TestResult.TotalCount) tests failed." -ErrorAction Stop
        }
    }
}
