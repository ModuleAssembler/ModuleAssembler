function Invoke-MARelease {
    <#
    .SYNOPSIS
        Executes the full release cycle for a ModuleAssembler module project.

    .DESCRIPTION
        Runs the complete release pipeline in sequence as a local convenience wrapper:

        1. Test-MAModule -TagFilter 'FunctionQA'
        2. (Optional) Update-MAModuleVersion
        3. Build-MAModule
        4. Test-MAModule -TagFilter 'ModuleQA'
        5. Test-MAModule -TagFilter 'Unit'
        6. Build-MAModuleDocumentation
        7. (Optional) Update-MAChangelogRelease
        8. Test-MAModule -TagFilter 'ChangeLog','License'
        9. Publish-MAModule

        Any step failure halts the release immediately. This function is intended for manual
        local releases. For automated pipeline releases, invoke each step as a discrete
        pipeline stage to get per-step failure visibility.

        All credential parameters are passed through to Publish-MAModule. See
        Get-Help Publish-MAModule for full credential and environment variable documentation.

    .PARAMETER PowerShellGalleryApiKey
        API key for PowerShell Gallery. If omitted, falls back to $env:PSGALLERY_API_KEY.

    .PARAMETER NuGetFeedUrl
        Full NuGet v3 feed URL for any compatible registry.

    .PARAMETER NuGetApiKey
        API key or token for the NuGet feed. If omitted, falls back to $env:NUGET_API_KEY.

    .PARAMETER FileSharePath
        UNC or local path to a file share acting as a PSResource repository.

    .PARAMETER FileShareCredential
        PSCredential for authenticating to the file share. If omitted, falls back to
        $env:FILESHARE_USERNAME and $env:FILESHARE_PASSWORD.

    .PARAMETER SkipDependenciesCheck
        Skips the repository dependency availability check during publish. Passed through to
        Publish-MAModule. Useful when publishing to a feed that does not host the module's
        dependencies.

    .PARAMETER SkipPrePublishValidation
        Skips changelog state and version uniqueness checks during publish.

    .PARAMETER UpdateVersion
        When specified, executes Update-MAModuleVersion after FunctionQA and before build.

    .PARAMETER VersionLabel
        Label passed to Update-MAModuleVersion -Label. Valid values are Major, Minor, Patch.
        Requires -UpdateVersion.

    .PARAMETER VersionPrereleaseType
        Prerelease type passed to Update-MAModuleVersion -PrereleaseType.
        Valid values are alpha, beta, preview, rc. Requires -UpdateVersion.

    .PARAMETER PromoteChangelogRelease
        When specified, executes Update-MAChangelogRelease after documentation and before
        compliance and publish.

    .PARAMETER ChangelogReleaseDate
        Release date passed to Update-MAChangelogRelease -ReleaseDate.
        Requires -PromoteChangelogRelease.

    .EXAMPLE
        Invoke-MARelease

        Runs the full release cycle and publishes to PowerShell Gallery using $env:PSGALLERY_API_KEY.

    .EXAMPLE
        Invoke-MARelease -PowerShellGalleryApiKey (Read-Host -AsSecureString 'PSGallery API Key')

        Runs the full release cycle and publishes to PowerShell Gallery using a provided API key.

    .EXAMPLE
        Invoke-MARelease -NuGetFeedUrl 'https://nuget.pkg.github.com/myorg/index.json'

        Runs the full release cycle and publishes to a NuGet-compatible feed using $env:NUGET_API_KEY.

    .EXAMPLE
        Invoke-MARelease -NuGetFeedUrl 'https://gitlab.com/api/v4/projects/12345678/packages/nuget/index.json'

        Runs the full release cycle and publishes to a GitLab package feed using $env:NUGET_API_KEY.

    .EXAMPLE
        Invoke-MARelease -FileSharePath '\\server\PSModules'

        Runs the full release cycle and publishes to a file share repository.

    .EXAMPLE
        Invoke-MARelease -UpdateVersion -VersionLabel Patch -PromoteChangelogRelease

        Runs the full release cycle, increments the module version before build,
        promotes changelog content before compliance tests, and publishes.
    #>

    [CmdletBinding(SupportsShouldProcess = $true, DefaultParameterSetName = 'PSGallery')]
    [OutputType([void])]
    [Alias('MARelease')]
    param (
        # --- PSGallery ---
        [Parameter(Mandatory = $false, ParameterSetName = 'PSGallery')]
        [SecureString] $PowerShellGalleryApiKey,

        # --- Generic NuGet Feed (GitHub Packages, GitLab Packages, Azure Artifacts, etc.) ---
        [Parameter(Mandatory = $true, ParameterSetName = 'NuGetFeed')]
        [ValidatePattern('^https://')]
        [string] $NuGetFeedUrl,

        [Parameter(Mandatory = $false, ParameterSetName = 'NuGetFeed')]
        [SecureString] $NuGetApiKey,

        # --- File Share ---
        [Parameter(Mandatory = $true, ParameterSetName = 'FileShare')]
        [ValidateNotNullOrEmpty()]
        [string] $FileSharePath,

        [Parameter(Mandatory = $false, ParameterSetName = 'FileShare')]
        [PSCredential] $FileShareCredential,

        # --- Common ---
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
    }

    process {
        $data = Get-MAProjectInfo
        Write-Host "Starting release cycle for $($data.ProjectName) v$($data.Version)." -ForegroundColor Cyan

        $totalSteps = 7
        if ($UpdateVersion.IsPresent) {
            $totalSteps++
        }
        if ($PromoteChangelogRelease.IsPresent) {
            $totalSteps++
        }

        $stepNumber = 0
        $writeStep = {
            param ([string] $Message)
            $stepNumber++
            Write-Host "`n[$stepNumber/$totalSteps] $Message" -ForegroundColor Cyan
        }

        # Step 1 - Source quality and comment-based help
        & $writeStep 'Running FunctionQA tests.'
        Test-MAModule -TagFilter 'FunctionQA'

        # Step 2 - Optional version update
        if ($UpdateVersion.IsPresent) {
            & $writeStep 'Updating module version.'
            $updateVersionParams = @{}
            if ($PSBoundParameters.ContainsKey('VersionLabel')) {
                $updateVersionParams['Label'] = $VersionLabel
            }
            if ($PSBoundParameters.ContainsKey('VersionPrereleaseType')) {
                $updateVersionParams['PrereleaseType'] = $VersionPrereleaseType
            }

            if ($PSCmdlet.ShouldProcess($data.ProjectName, 'Update-MAModuleVersion')) {
                Update-MAModuleVersion @updateVersionParams
                $data = Get-MAProjectInfo
                Write-Verbose "Release version is now $($data.Version)."
            }
        }

        # Step 3 - Build
        & $writeStep 'Building module.'
        if ($PSCmdlet.ShouldProcess($data.ProjectName, 'Build-MAModule')) {
            Build-MAModule
        }

        # Step 4 - Artifact integrity
        & $writeStep 'Running ModuleQA tests.'
        Test-MAModule -TagFilter 'ModuleQA'

        # Step 5 - Unit tests
        & $writeStep 'Running Unit tests.'
        Test-MAModule -TagFilter 'Unit'

        # Step 6 - Documentation
        & $writeStep 'Building documentation.'
        if ($PSCmdlet.ShouldProcess($data.ProjectName, 'Build-MAModuleDocumentation')) {
            Build-MAModuleDocumentation
        }

        # Step 7 - Optional changelog promotion
        if ($PromoteChangelogRelease.IsPresent) {
            & $writeStep 'Promoting changelog release section.'
            $updateChangelogParams = @{}
            if ($PSBoundParameters.ContainsKey('ChangelogReleaseDate')) {
                $updateChangelogParams['ReleaseDate'] = $ChangelogReleaseDate
            }

            if ($PSCmdlet.ShouldProcess($data.ProjectName, 'Update-MAChangelogRelease')) {
                Update-MAChangelogRelease @updateChangelogParams
            }
        }

        # Step 8 - Project compliance
        & $writeStep 'Running compliance tests.'
        Test-MAModule -TagFilter 'ChangeLog', 'License'

        # Step 9 - Publish (includes pre-publish validation internally)
        & $writeStep 'Publishing.'
        $publishParams = @{}

        switch ($PSCmdlet.ParameterSetName) {
            'PSGallery' {
                if ($PSBoundParameters.ContainsKey('PowerShellGalleryApiKey')) {
                    $publishParams['PowerShellGalleryApiKey'] = $PowerShellGalleryApiKey
                }
            }
            'NuGetFeed' {
                $publishParams['NuGetFeedUrl'] = $NuGetFeedUrl
                if ($PSBoundParameters.ContainsKey('NuGetApiKey')) {
                    $publishParams['NuGetApiKey'] = $NuGetApiKey
                }
            }
            'FileShare' {
                $publishParams['FileSharePath'] = $FileSharePath
                if ($PSBoundParameters.ContainsKey('FileShareCredential')) {
                    $publishParams['FileShareCredential'] = $FileShareCredential
                }
            }
        }

        if ($SkipDependenciesCheck.IsPresent) {
            $publishParams['SkipDependenciesCheck'] = $true
        }

        if ($SkipPrePublishValidation.IsPresent) {
            $publishParams['SkipPrePublishValidation'] = $true
        }

        if ($PSCmdlet.ShouldProcess($data.ProjectName, "Publish-MAModule to '$($PSCmdlet.ParameterSetName)'")) {
            Publish-MAModule @publishParams
        }

        Write-Host "`nRelease cycle complete. $($data.ProjectName) v$($data.Version) published successfully." -ForegroundColor Green
    }
}
