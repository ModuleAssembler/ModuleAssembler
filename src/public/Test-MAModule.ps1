function Test-MAModule {
    <#
    .SYNOPSIS
        Runs Pester tests using settings from project.json file.

    .DESCRIPTION
        Runs the Pester tests for the current ModuleAssembler project.

        Run this command from the module project directory. Tests are discovered from the
        project's "tests" directory, and the Pester configuration is loaded from the
        "Pester" section of ".moduleassembler/moduleproject.json".

        Test results and code coverage reports are written to the project's "dist"
        directory. The command throws an error if the project configuration is invalid
        or if one or more tests fail.

    .PARAMETER TagFilter
        One or more Pester tags. Only tests with at least one matching tag are run.
        If omitted, all tests are eligible to run unless excluded with ExcludeTagFilter.

    .PARAMETER ExcludeTagFilter
        One or more Pester tags. Tests with any matching tag are excluded.
        Exclusions are applied together with TagFilter when both parameters are specified.

    .EXAMPLE
        Test-MAModule

        Execute all Pester tests.

    .EXAMPLE
        Test-MAModule -TagFilter 'unit','FunctionQA'

        Execute only Pester tests with the tags unit or FunctionQA.

    .EXAMPLE
        Test-MAModule -ExcludeTagFilter 'unit'

        Runs the Pester tests, excludes any test with tag unit.
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
        [string[]] $ExcludeTagFilter
    )

    begin {
        if ($Host.Name -eq 'Visual Studio Code Host') {
            throw 'Test-MAModule must be run from a pwsh terminal, not the PowerShell Extension''s integrated console, which cannot reliably resolve some binary module commands (e.g. Invoke-ScriptAnalyzer).'
        }

        if (!(Test-JsonSchema)) {
            throw 'The JSON in moduleproject.json did not pass validation.'
        }

        $data = Get-MAProjectInfo
        $pesterConfig = New-PesterConfiguration -Hashtable $data.Pester
    }

    process {
        $testPath = './tests'
        $pesterConfig.Run.Path = $testPath
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
