[CmdletBinding(DefaultParameterSetName = 'PSGallery')]
param (
    [Parameter(Mandatory = $true, ParameterSetName = 'FileShare')]
    [ValidateNotNullOrEmpty()]
    [string] $FileSharePath,

    [Parameter(Mandatory = $false, ParameterSetName = 'FileShare')]
    [PSCredential] $FileShareCredential,

    [Parameter(Mandatory = $true, ParameterSetName = 'NuGetFeed')]
    [ValidatePattern('^https://')]
    [string] $NuGetFeedUrl,

    [Parameter(Mandatory = $false, ParameterSetName = 'NuGetFeed')]
    [SecureString] $NuGetApiKey,

    [Parameter(Mandatory = $false, ParameterSetName = 'PSGallery')]
    [SecureString] $PowerShellGalleryApiKey,

    [Parameter(Mandatory = $false)]
    [ValidateSet('FunctionQA', 'Build', 'ModuleQA', 'Unit', 'Docs', 'Compliance', 'Publish')]
    [string] $StartStage = 'FunctionQA',

    [Parameter(Mandatory = $false)]
    [ValidateSet('FunctionQA', 'Build', 'ModuleQA', 'Unit', 'Docs', 'Compliance', 'Publish')]
    [string] $EndStage = 'Publish',

    [Parameter(Mandatory = $false)]
    [ValidateNotNullOrEmpty()]
    [string] $ArtifactsPath = (Join-Path -Path $PSScriptRoot -ChildPath 'artifacts/self-publish'),

    [Parameter(Mandatory = $false)]
    [ValidateRange(1, 1000)]
    [int] $ArtifactMaxRetention = 3,

    [Parameter(Mandatory = $false)]
    [switch] $SkipDependenciesCheck,

    [Parameter(Mandatory = $false)]
    [switch] $SkipPrePublishValidation,

    [Parameter(Mandatory = $false)]
    [switch] $UpdateVersion,

    [Parameter(Mandatory = $false)]
    [ValidateSet('Major', 'Minor', 'Patch')]
    [string] $VersionLabel,

    [Parameter(Mandatory = $false)]
    [ValidateSet('alpha', 'beta', 'preview', 'rc')]
    [string] $VersionPrereleaseType,

    [Parameter(Mandatory = $false)]
    [switch] $PromoteChangelogRelease,

    [Parameter(Mandatory = $false)]
    [datetime] $ChangelogReleaseDate
)

function Invoke-ModuleSelfPublish {
    [CmdletBinding(DefaultParameterSetName = 'PSGallery')]
    [OutputType([void])]
    param (
        [Parameter(Mandatory = $true, ParameterSetName = 'FileShare')]
        [ValidateNotNullOrEmpty()]
        [string] $FileSharePath,

        [Parameter(Mandatory = $false, ParameterSetName = 'FileShare')]
        [PSCredential] $FileShareCredential,

        [Parameter(Mandatory = $true, ParameterSetName = 'NuGetFeed')]
        [ValidatePattern('^https://')]
        [string] $NuGetFeedUrl,

        [Parameter(Mandatory = $false, ParameterSetName = 'NuGetFeed')]
        [SecureString] $NuGetApiKey,

        [Parameter(Mandatory = $false, ParameterSetName = 'PSGallery')]
        [SecureString] $PowerShellGalleryApiKey,

        [Parameter(Mandatory = $false)]
        [ValidateSet('FunctionQA', 'Build', 'ModuleQA', 'Unit', 'Docs', 'Compliance', 'Publish')]
        [string] $StartStage = 'FunctionQA',

        [Parameter(Mandatory = $false)]
        [ValidateSet('FunctionQA', 'Build', 'ModuleQA', 'Unit', 'Docs', 'Compliance', 'Publish')]
        [string] $EndStage = 'Publish',

        [Parameter(Mandatory = $false)]
        [ValidateNotNullOrEmpty()]
        [string] $ArtifactsPath = (Join-Path -Path $PSScriptRoot -ChildPath 'artifacts/self-publish'),

        [Parameter(Mandatory = $false)]
        [ValidateRange(1, 1000)]
        [int] $ArtifactMaxRetention = 3,

        [Parameter(Mandatory = $false)]
        [switch] $SkipDependenciesCheck,

        [Parameter(Mandatory = $false)]
        [switch] $SkipPrePublishValidation,

        [Parameter(Mandatory = $false)]
        [switch] $UpdateVersion,

        [Parameter(Mandatory = $false)]
        [ValidateSet('Major', 'Minor', 'Patch')]
        [string] $VersionLabel,

        [Parameter(Mandatory = $false)]
        [ValidateSet('alpha', 'beta', 'preview', 'rc')]
        [string] $VersionPrereleaseType,

        [Parameter(Mandatory = $false)]
        [switch] $PromoteChangelogRelease,

        [Parameter(Mandatory = $false)]
        [datetime] $ChangelogReleaseDate
    )

    begin {
        $ErrorActionPreference = 'Stop'

        if (($PSBoundParameters.ContainsKey('VersionLabel') -or $PSBoundParameters.ContainsKey('VersionPrereleaseType')) -and -not $UpdateVersion.IsPresent) {
            throw 'VersionLabel and VersionPrereleaseType require -UpdateVersion.'
        }

        if ($PSBoundParameters.ContainsKey('ChangelogReleaseDate') -and -not $PromoteChangelogRelease.IsPresent) {
            throw 'ChangelogReleaseDate requires -PromoteChangelogRelease.'
        }

        $stageOrder = @('FunctionQA', 'Build', 'ModuleQA', 'Unit', 'Docs', 'Compliance', 'Publish')
        $startIndex = [Array]::IndexOf($stageOrder, $StartStage)
        $endIndex = [Array]::IndexOf($stageOrder, $EndStage)
        if ($startIndex -lt 0 -or $endIndex -lt 0) {
            throw 'Invalid stage selection.'
        }
        if ($startIndex -gt $endIndex) {
            throw "StartStage '$StartStage' must be before or equal to EndStage '$EndStage'."
        }

        $stagesToRun = $stageOrder[$startIndex..$endIndex]

        if ($UpdateVersion.IsPresent -and -not ($stagesToRun -contains 'Build')) {
            throw 'UpdateVersion requires the selected stage range to include Build.'
        }

        if ($PromoteChangelogRelease.IsPresent -and -not ($stagesToRun -contains 'Compliance')) {
            throw 'PromoteChangelogRelease requires the selected stage range to include Compliance.'
        }

        $projectRoot = $PSScriptRoot
        $versionUpdated = $false
        $changelogPromoted = $false

        $artifactsRootPath = $ArtifactsPath
        $previousRunsRootPath = Join-Path -Path $artifactsRootPath -ChildPath 'previous_runs'
        $latestArtifactsPath = Join-Path -Path $artifactsRootPath -ChildPath 'latest'

        foreach ($dirPath in @($artifactsRootPath, $previousRunsRootPath)) {
            if (-not (Test-Path -Path $dirPath)) {
                New-Item -Path $dirPath -ItemType Directory -Force | Out-Null
            }
        }

        if (Test-Path -Path $latestArtifactsPath) {
            $previousRunId = 'run_{0}' -f ([datetime]::UtcNow.ToString('yyyyMMddTHHmmssZ'))
            $previousSummaryPath = Join-Path -Path $latestArtifactsPath -ChildPath 'bootstrap/run-summary.json'
            if (Test-Path -Path $previousSummaryPath) {
                try {
                    $previousSummary = Get-Content -Path $previousSummaryPath -Raw | ConvertFrom-Json
                    if ($null -ne $previousSummary.RunStartedUtc) {
                        $previousRunStarted = [datetime]$previousSummary.RunStartedUtc
                        $previousRunId = 'run_{0}' -f $previousRunStarted.ToUniversalTime().ToString('yyyyMMddTHHmmssZ')
                    }
                } catch {
                    Write-Warning "Failed to parse prior run summary '$previousSummaryPath'. Falling back to timestamp-based run id."
                }
            }

            $archivePath = Join-Path -Path $previousRunsRootPath -ChildPath $previousRunId
            $suffix = 1
            while (Test-Path -Path $archivePath) {
                $archivePath = Join-Path -Path $previousRunsRootPath -ChildPath ('{0}_{1}' -f $previousRunId, $suffix)
                $suffix++
            }

            Move-Item -Path $latestArtifactsPath -Destination $archivePath -Force
        }

        $testsArtifactPath = Join-Path -Path $latestArtifactsPath -ChildPath 'tests'
        $logsArtifactPath = Join-Path -Path $latestArtifactsPath -ChildPath 'logs'
        $bootstrapArtifactPath = Join-Path -Path $latestArtifactsPath -ChildPath 'bootstrap'
        $tempArtifactPath = Join-Path -Path $latestArtifactsPath -ChildPath 'tmp'

        foreach ($dirPath in @($latestArtifactsPath, $testsArtifactPath, $logsArtifactPath, $bootstrapArtifactPath, $tempArtifactPath)) {
            if (-not (Test-Path -Path $dirPath)) {
                New-Item -Path $dirPath -ItemType Directory -Force | Out-Null
            }
        }

        $existingRunDirs = Get-ChildItem -Path $previousRunsRootPath -Directory -ErrorAction SilentlyContinue | Sort-Object LastWriteTimeUtc -Descending
        if ($existingRunDirs.Count -gt $ArtifactMaxRetention) {
            $dirsToRemove = $existingRunDirs | Select-Object -Skip $ArtifactMaxRetention
            foreach ($dirToRemove in $dirsToRemove) {
                Remove-Item -Path $dirToRemove.FullName -Recurse -Force
            }
        }

        $runStartedUtc = [datetime]::UtcNow
        $stageResults = [System.Collections.Generic.List[object]]::new()

        $writeStageStart = {
            param (
                [string] $StageName
            )

            Write-Host ''
            Write-Host ('=== STAGE START: {0} ===' -f $StageName) -ForegroundColor Cyan
            Write-Host ('Timestamp (UTC): {0}' -f ([datetime]::UtcNow.ToString('o'))) -ForegroundColor DarkCyan
        }

        $writeStageEnd = {
            param (
                [string] $StageName,
                [string] $Result,
                [timespan] $Duration
            )

            $color = if ($Result -eq 'Passed') {
                'Green'
            } else {
                'Red'
            }
            Write-Host ('=== STAGE END: {0} | Result: {1} | Duration: {2:N2}s ===' -f $StageName, $Result, $Duration.TotalSeconds) -ForegroundColor $color
        }

        function Copy-PesterResultArtifact {
            [CmdletBinding()]
            param (
                [Parameter(Mandatory = $true)]
                [ValidateNotNullOrEmpty()]
                [string] $RootPath,

                [Parameter(Mandatory = $true)]
                [ValidateNotNullOrEmpty()]
                [string] $DestinationFilePath
            )

            $defaultPesterPath = Join-Path -Path $RootPath -ChildPath 'dist/PesterTestResults.xml'
            if (Test-Path -Path $defaultPesterPath) {
                Copy-Item -Path $defaultPesterPath -Destination $DestinationFilePath -Force
            } else {
                Write-Warning "Expected Pester result file not found at '$defaultPesterPath'."
            }
        }

        function Copy-CoverageArtifact {
            [CmdletBinding()]
            param (
                [Parameter(Mandatory = $true)]
                [ValidateNotNullOrEmpty()]
                [string] $RootPath,

                [Parameter(Mandatory = $true)]
                [ValidateNotNullOrEmpty()]
                [string] $DestinationFilePath
            )

            $defaultCoveragePath = Join-Path -Path $RootPath -ChildPath 'dist/coverage.xml'
            if (Test-Path -Path $defaultCoveragePath) {
                Copy-Item -Path $defaultCoveragePath -Destination $DestinationFilePath -Force
            } else {
                Write-Warning "Expected code coverage file not found at '$defaultCoveragePath'."
            }
        }

        function Invoke-IsolatedModuleStage {
            [CmdletBinding()]
            param (
                [Parameter(Mandatory = $true)]
                [ValidateNotNullOrEmpty()]
                [string] $StageName,

                [Parameter(Mandatory = $true)]
                [ValidateNotNullOrEmpty()]
                [string] $RootPath,

                [Parameter(Mandatory = $true)]
                [ValidateNotNullOrEmpty()]
                [string] $CommandName,

                [Parameter(Mandatory = $true)]
                [ValidateNotNullOrEmpty()]
                [string] $LogFilePath,

                [Parameter(Mandatory = $false)]
                [hashtable] $CommandParameters,

                [Parameter(Mandatory = $false)]
                [string] $PesterResultDestinationFilePath,

                [Parameter(Mandatory = $false)]
                [string] $CoverageDestinationFilePath,

                [Parameter(Mandatory = $true)]
                [ValidateNotNullOrEmpty()]
                [string] $TempPath
            )

            $paramsPath = Join-Path -Path $TempPath -ChildPath ('{0}-params.clixml' -f $StageName)
            $runnerPath = Join-Path -Path $TempPath -ChildPath ('{0}-runner.ps1' -f $StageName)

            if ($CommandParameters) {
                Export-Clixml -Path $paramsPath -InputObject $CommandParameters -Force
            }

            $safeRootPath = [System.Management.Automation.Language.CodeGeneration]::EscapeSingleQuotedStringContent($RootPath)
            $safeCommandName = [System.Management.Automation.Language.CodeGeneration]::EscapeSingleQuotedStringContent($CommandName)
            $safeParamsPath = [System.Management.Automation.Language.CodeGeneration]::EscapeSingleQuotedStringContent($paramsPath)
            $safePesterDestinationPath = [System.Management.Automation.Language.CodeGeneration]::EscapeSingleQuotedStringContent($PesterResultDestinationFilePath)
            $safeCoverageDestinationPath = [System.Management.Automation.Language.CodeGeneration]::EscapeSingleQuotedStringContent($CoverageDestinationFilePath)

            $runnerScript = @"
`$ErrorActionPreference = 'Stop'
Set-Location -LiteralPath '$safeRootPath'

# Source-load all module functions so no dist module instance is pre-loaded.
# This ensures stages that import/remove the dist module (e.g. ModuleQA, Docs)
# work against exactly one module instance and Remove-Module cleans up completely.
Remove-Module -Name ModuleAssembler -Force -ErrorAction SilentlyContinue
Get-ChildItem -Path (Join-Path -Path '$safeRootPath' -ChildPath 'src/classes') -Filter '*.ps1' -File -ErrorAction SilentlyContinue | Sort-Object Name | ForEach-Object { . `$_.FullName }
Get-ChildItem -Path (Join-Path -Path '$safeRootPath' -ChildPath 'src/private') -Filter '*.ps1' -File | Sort-Object Name | ForEach-Object { . `$_.FullName }
Get-ChildItem -Path (Join-Path -Path '$safeRootPath' -ChildPath 'src/public') -Filter '*.ps1' -File | Sort-Object Name | ForEach-Object { . `$_.FullName }

`$commandName = '$safeCommandName'
`$paramsPath = '$safeParamsPath'
`$pesterDestinationPath = '$safePesterDestinationPath'
`$coverageDestinationPath = '$safeCoverageDestinationPath'

`$commandParameters = @{}
if (Test-Path -Path `$paramsPath) {
    `$commandParameters = Import-Clixml -Path `$paramsPath
}

& `$commandName @commandParameters

if (`$pesterDestinationPath -and (Test-Path -Path './dist/PesterTestResults.xml')) {
    Copy-Item -Path './dist/PesterTestResults.xml' -Destination `$pesterDestinationPath -Force
}

if (`$coverageDestinationPath -and (Test-Path -Path './dist/coverage.xml')) {
    Copy-Item -Path './dist/coverage.xml' -Destination `$coverageDestinationPath -Force
}
"@

            $normalizedRunnerScript = $runnerScript
            if (Get-Command -Name Invoke-Formatter -ErrorAction SilentlyContinue) {
                $normalizedRunnerScript = Invoke-Formatter -ScriptDefinition $normalizedRunnerScript
            }

            $normalizedRunnerScript = $normalizedRunnerScript -replace '(\))\s{2,}(-Filter)', '$1 $2'
            $normalizedRunnerScript = (($normalizedRunnerScript -split '\r?\n') | ForEach-Object { $_.TrimEnd() }) -join [System.Environment]::NewLine
            Set-Content -Path $runnerPath -Value $normalizedRunnerScript -Encoding utf8NoBOM -NoNewline

            & pwsh -NoProfile -File $runnerPath 2>&1 | Tee-Object -FilePath $LogFilePath -Append | Write-Host
            if ($LASTEXITCODE -ne 0) {
                throw "Stage '$StageName' failed in isolated process with exit code $LASTEXITCODE. See '$LogFilePath'."
            }
        }

        Set-Location -LiteralPath $projectRoot
        Remove-Module -Name ModuleAssembler -Force -ErrorAction SilentlyContinue

        $classesPath = Join-Path -Path $projectRoot -ChildPath 'src/classes'
        $privatePath = Join-Path -Path $projectRoot -ChildPath 'src/private'
        $publicPath = Join-Path -Path $projectRoot -ChildPath 'src/public'

        foreach ($sourcePath in @($classesPath, $privatePath, $publicPath)) {
            if (-not (Test-Path -Path $sourcePath)) {
                throw "Required source path '$sourcePath' does not exist."
            }
        }

        Get-ChildItem -Path $classesPath -Filter '*.ps1' -File | Sort-Object Name | ForEach-Object {
            . $_.FullName
        }

        Get-ChildItem -Path $privatePath -Filter '*.ps1' -File | Sort-Object Name | ForEach-Object {
            . $_.FullName
        }

        Get-ChildItem -Path $publicPath -Filter '*.ps1' -File | Sort-Object Name | ForEach-Object {
            . $_.FullName
        }

        $distManifestPath = Join-Path -Path $projectRoot -ChildPath 'dist/ModuleAssembler/ModuleAssembler.psd1'
    }

    process {
        foreach ($stageName in $stagesToRun) {
            $stageStartedUtc = [datetime]::UtcNow
            $stageLogPath = Join-Path -Path $logsArtifactPath -ChildPath ('{0}.log' -f $stageName)
            $stageResult = 'Passed'
            $stageError = $null

            & $writeStageStart -StageName $stageName

            try {
                switch ($stageName) {
                    'FunctionQA' {
                        Test-MAModule -TagFilter 'FunctionQA'
                        Copy-PesterResultArtifact -RootPath $projectRoot -DestinationFilePath (Join-Path -Path $testsArtifactPath -ChildPath 'FunctionQA.xml')
                        Copy-CoverageArtifact -RootPath $projectRoot -DestinationFilePath (Join-Path -Path $testsArtifactPath -ChildPath 'FunctionQA.coverage.xml')
                    }
                    'Build' {
                        if ($UpdateVersion.IsPresent -and -not $versionUpdated) {
                            $updateVersionParams = @{}
                            if ($PSBoundParameters.ContainsKey('VersionLabel')) {
                                $updateVersionParams['Label'] = $VersionLabel
                            }
                            if ($PSBoundParameters.ContainsKey('VersionPrereleaseType')) {
                                $updateVersionParams['PrereleaseType'] = $VersionPrereleaseType
                            }

                            Update-MAModuleVersion @updateVersionParams
                            $versionUpdated = $true
                        }

                        Build-MAModule
                        if (-not (Test-Path -Path $distManifestPath)) {
                            throw "Expected built manifest not found at '$distManifestPath'."
                        }
                    }
                    'ModuleQA' {
                        Invoke-IsolatedModuleStage -StageName 'ModuleQA' -RootPath $projectRoot -CommandName 'Test-MAModule' -CommandParameters @{ TagFilter = @('ModuleQA') } -LogFilePath $stageLogPath -PesterResultDestinationFilePath (Join-Path -Path $testsArtifactPath -ChildPath 'ModuleQA.xml') -CoverageDestinationFilePath (Join-Path -Path $testsArtifactPath -ChildPath 'ModuleQA.coverage.xml') -TempPath $tempArtifactPath
                    }
                    'Unit' {
                        Invoke-IsolatedModuleStage -StageName 'Unit' -RootPath $projectRoot -CommandName 'Test-MAModule' -CommandParameters @{ TagFilter = @('Unit') } -LogFilePath $stageLogPath -PesterResultDestinationFilePath (Join-Path -Path $testsArtifactPath -ChildPath 'Unit.xml') -CoverageDestinationFilePath (Join-Path -Path $testsArtifactPath -ChildPath 'Unit.coverage.xml') -TempPath $tempArtifactPath
                    }
                    'Docs' {
                        Invoke-IsolatedModuleStage -StageName 'Docs' -RootPath $projectRoot -CommandName 'Build-MAModuleDocumentation' -CommandParameters @{} -LogFilePath $stageLogPath -TempPath $tempArtifactPath
                    }
                    'Compliance' {
                        if ($PromoteChangelogRelease.IsPresent -and -not $changelogPromoted) {
                            $updateChangelogParams = @{}
                            if ($PSBoundParameters.ContainsKey('ChangelogReleaseDate')) {
                                $updateChangelogParams['ReleaseDate'] = $ChangelogReleaseDate
                            }

                            Update-MAChangelogRelease @updateChangelogParams
                            $changelogPromoted = $true
                        }

                        Invoke-IsolatedModuleStage -StageName 'Compliance' -RootPath $projectRoot -CommandName 'Test-MAModule' -CommandParameters @{ TagFilter = @('ChangeLog', 'License') } -LogFilePath $stageLogPath -PesterResultDestinationFilePath (Join-Path -Path $testsArtifactPath -ChildPath 'Compliance.xml') -CoverageDestinationFilePath (Join-Path -Path $testsArtifactPath -ChildPath 'Compliance.coverage.xml') -TempPath $tempArtifactPath
                    }
                    'Publish' {
                        $publishParameters = @{}

                        switch ($PSCmdlet.ParameterSetName) {
                            'PSGallery' {
                                if ($PSBoundParameters.ContainsKey('PowerShellGalleryApiKey')) {
                                    $publishParameters['PowerShellGalleryApiKey'] = $PowerShellGalleryApiKey
                                }
                            }
                            'NuGetFeed' {
                                $publishParameters['NuGetFeedUrl'] = $NuGetFeedUrl
                                if ($PSBoundParameters.ContainsKey('NuGetApiKey')) {
                                    $publishParameters['NuGetApiKey'] = $NuGetApiKey
                                }
                            }
                            'FileShare' {
                                $publishParameters['FileSharePath'] = $FileSharePath
                                if ($PSBoundParameters.ContainsKey('FileShareCredential')) {
                                    $publishParameters['FileShareCredential'] = $FileShareCredential
                                }
                            }
                        }

                        if ($SkipDependenciesCheck.IsPresent) {
                            $publishParameters['SkipDependenciesCheck'] = $true
                        }

                        if ($SkipPrePublishValidation.IsPresent) {
                            $publishParameters['SkipPrePublishValidation'] = $true
                        }

                        Invoke-IsolatedModuleStage -StageName 'Publish' -RootPath $projectRoot -CommandName 'Publish-MAModule' -CommandParameters $publishParameters -LogFilePath $stageLogPath -TempPath $tempArtifactPath
                    }
                }
            } catch {
                $stageResult = 'Failed'
                $stageError = $_.Exception.Message
            }

            $stageEndedUtc = [datetime]::UtcNow
            $stageDuration = $stageEndedUtc - $stageStartedUtc

            $stageResults.Add([PSCustomObject]@{
                    StageName       = $stageName
                    StartedUtc      = $stageStartedUtc
                    EndedUtc        = $stageEndedUtc
                    DurationSeconds = [math]::Round($stageDuration.TotalSeconds, 2)
                    Result          = $stageResult
                    LogFilePath     = $stageLogPath
                    ErrorMessage    = $stageError
                }) | Out-Null

            & $writeStageEnd -StageName $stageName -Result $stageResult -Duration $stageDuration

            if ($stageResult -eq 'Failed') {
                throw "Stopping at stage '$stageName'. $stageError"
            }
        }
    }

    end {
        $runEndedUtc = [datetime]::UtcNow
        $runDuration = $runEndedUtc - $runStartedUtc

        $runResult = if ($stageResults.Where({ $_.Result -eq 'Failed' }).Count -gt 0) {
            'Failed'
        } else {
            'Passed'
        }
        $summaryObject = [PSCustomObject]@{
            RunStartedUtc           = $runStartedUtc
            RunEndedUtc             = $runEndedUtc
            DurationSeconds         = [math]::Round($runDuration.TotalSeconds, 2)
            Result                  = $runResult
            StartStage              = $StartStage
            EndStage                = $EndStage
            ParameterSetName        = $PSCmdlet.ParameterSetName
            ArtifactsPath           = $latestArtifactsPath
            ArtifactsRootPath       = $artifactsRootPath
            UpdateVersion           = $UpdateVersion.IsPresent
            VersionLabel            = if ($PSBoundParameters.ContainsKey('VersionLabel')) { $VersionLabel } else { $null }
            VersionPrereleaseType   = if ($PSBoundParameters.ContainsKey('VersionPrereleaseType')) { $VersionPrereleaseType } else { $null }
            PromoteChangelogRelease = $PromoteChangelogRelease.IsPresent
            ChangelogReleaseDate    = if ($PSBoundParameters.ContainsKey('ChangelogReleaseDate')) { $ChangelogReleaseDate } else { $null }
            Stages                  = $stageResults
        }

        $summaryPath = Join-Path -Path $bootstrapArtifactPath -ChildPath 'run-summary.json'
        $summaryObject | ConvertTo-Json -Depth 6 | Set-Content -Path $summaryPath -Encoding utf8NoBOM

        Write-Host ''
        Write-Host '=== RUN SUMMARY ===' -ForegroundColor Cyan
        $stageResults |
            Select-Object StageName, Result, DurationSeconds, LogFilePath |
            Format-Table -AutoSize |
            Out-String |
            Write-Host

        Write-Host ('Summary JSON: {0}' -f $summaryPath) -ForegroundColor Cyan
        Write-Host ('Artifacts Path: {0}' -f $latestArtifactsPath) -ForegroundColor Cyan
        Write-Host ('Artifacts Root: {0}' -f $artifactsRootPath) -ForegroundColor Cyan
    }
}

Invoke-ModuleSelfPublish @PSBoundParameters
