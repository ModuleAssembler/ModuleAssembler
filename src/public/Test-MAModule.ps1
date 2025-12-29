function Test-MAModule {
    <#
    .SYNOPSIS
        Runs Pester tests using settings from project.json file.

    .DESCRIPTION
        This function runs Pester tests using the specified configuration and settings in project.json.
        Place all module tests in "tests" folder.

    .PARAMETER TagFilter
        Array of Pester tags to run.

    .PARAMETER ExcludeTagFilter
        Array of Pester tags to run.

    .EXAMPLE
        Execute all Pester tests.
        Test-MAModule

    .EXAMPLE
        Execute only Pester tests with the tags unit or integrate.
        Test-MAModule -TagFilter 'unit','integrate'

    .EXAMPLE
        Runs the Pester tests, excludes any test with tag unit
        Test-MAModule -ExcludeTagFilter 'unit'
    #>

    [CmdletBinding(PositionalBinding = $false)]
    param (
        [Parameter(Mandatory = $false)]
        [ValidateNotNullOrEmpty()]
        [string[]] $TagFilter,

        [Parameter(Mandatory = $false)]
        [ValidateNotNullOrEmpty()]
        [string[]] $ExcludeTagFilter
    )

    begin {
        Test-JsonSchema | Out-Null
        $data = Get-MAProjectInfo
        $pesterConfig = New-PesterConfiguration -Hashtable $data.Pester
    }

    process {
        $testPath = './tests'
        $pesterConfig.Run.Path = $testPath
        $pesterConfig.Run.PassThru = $true
        $pesterConfig.Run.Exit = $true
        $pesterConfig.Run.Throw = $true
        $pesterConfig.Filter.Tag = $TagFilter
        $pesterConfig.Filter.ExcludeTag = $ExcludeTagFilter
        $pesterConfig.TestResult.OutputPath = [System.IO.Path]::Combine('.', 'dist', 'PesterTestResults.xml')

        $TestResult = Invoke-Pester -Configuration $pesterConfig
        if ($TestResult.Result -ne 'Passed') {
            Write-Error 'Tests failed' -ErrorAction Stop
            return $LASTEXITCODE
        }
    }

    end {
        # Cleanup code
    }
}
