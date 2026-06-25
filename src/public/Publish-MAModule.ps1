function Publish-MAModule {
    <#
    .SYNOPSIS
        Publishes a built module to a target package repository.

    .DESCRIPTION
        Publishes the built module artifact from the dist folder to a target package repository.
        Supports PowerShell Gallery (default), any NuGet-compatible feed (GitHub Packages,
        GitLab Packages, Azure Artifacts, Forgejo, etc.), and file share paths.

        Credentials are accepted as parameters for manual use or resolved from masked pipeline environment variables
        for pipeline execution:

        - PSGallery: $env:PSGALLERY_API_KEY
        - NuGetFeed: $env:NUGET_API_KEY
        - FileShare: $env:FILESHARE_USERNAME and $env:FILESHARE_PASSWORD

        SECURITY NOTE: Environment variable secrets are plain-text and readable by any process
        running in the same user context. For interactive or developer use, prefer passing
        credentials via the dedicated parameters rather than environment variables, or protect
        secrets with the Microsoft.PowerShell.SecretManagement module and a local vault.

    .PARAMETER PowerShellGalleryApiKey
        API key for PowerShell Gallery. If omitted, falls back to $env:PSGALLERY_API_KEY.

    .PARAMETER NuGetFeedUrl
        The full NuGet v3 feed URL for any compatible registry.

        Examples:
          GitHub:  https://nuget.pkg.github.com/<owner>/index.json
          GitLab:  https://gitlab.com/api/v4/projects/<project-id>/packages/nuget/index.json

    .PARAMETER NuGetApiKey
        API key or token for the NuGet feed. If omitted, falls back to $env:NUGET_API_KEY.

    .PARAMETER FileSharePath
        UNC or local path to a file share acting as a PSResource repository.

    .PARAMETER FileShareCredential
        PSCredential for authenticating to the file share. If omitted, falls back to
        $env:FILESHARE_USERNAME and $env:FILESHARE_PASSWORD.

    .PARAMETER SkipDependenciesCheck
        Skips the repository dependency availability check performed by Publish-PSResource.
        Useful when publishing to a file share or private feed that does not host the module's
        dependencies (e.g. Pester, PSScriptAnalyzer). Consumers are responsible for satisfying
        dependencies when they install the module.

    .PARAMETER SkipPrePublishValidation
        Skips changelog state and version uniqueness checks. Not recommended for production use.

    .EXAMPLE
        Publish-MAModule

        Publishes to PowerShell Gallery using $env:PSGALLERY_API_KEY.

    .EXAMPLE
        Publish-MAModule -PowerShellGalleryApiKey (Read-Host -AsSecureString 'PSGallery API Key')

        Publishes to PowerShell Gallery using a provided API key.

    .EXAMPLE
        Publish-MAModule -NuGetFeedUrl 'https://nuget.pkg.github.com/myorg/index.json'

        Publishes to GitHub Packages using $env:NUGET_API_KEY.

    .EXAMPLE
        Publish-MAModule -NuGetFeedUrl 'https://gitlab.com/api/v4/projects/12345678/packages/nuget/index.json'

        Publishes to GitLab Packages using $env:NUGET_API_KEY.

    .EXAMPLE
        Publish-MAModule -NuGetFeedUrl 'https://forgejo.example.com/api/packages/<owner>/nuget/index.json'

        Publishes to a Forgejo package registry using $env:NUGET_API_KEY.

    .EXAMPLE
        Publish-MAModule -NuGetFeedUrl 'https://pkgs.dev.azure.com/<organization>/<project>/_packaging/<feed>/nuget/v3/index.json'

        Publishes to an Azure Artifacts feed using $env:NUGET_API_KEY.

    .EXAMPLE
        Publish-MAModule -FileSharePath '\\server\PSModules'

        Publishes to a file share repository using $env:FILESHARE_USERNAME and $env:FILESHARE_PASSWORD.

    .EXAMPLE
        Publish-MAModule -FileSharePath '\\server\PSModules' -FileShareCredential (Get-Credential)

        Publishes to a file share repository using an explicit credential.
    #>

    [CmdletBinding(SupportsShouldProcess = $true, DefaultParameterSetName = 'PSGallery')]
    [OutputType([void])]
    [Alias('MAPublish')]
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
        [switch] $SkipPrePublishValidation
    )

    begin {
        $ErrorActionPreference = 'Stop'

        if (-not (Get-Module -Name 'Microsoft.PowerShell.PSResourceGet' -ListAvailable)) {
            throw 'Microsoft.PowerShell.PSResourceGet is required. Install it with: Install-Module Microsoft.PowerShell.PSResourceGet'
        }

        $data = Get-MAProjectInfo

        if (-not (Test-Path -Path $data.ManifestFilePSD1)) {
            throw "Built module manifest not found at '$($data.ManifestFilePSD1)'. Run Build-MAModule before publishing."
        }
    }

    process {
        $tempRepositoryName = $null
        $tempRepositoryUri = $null
        $tempRepositoryPrefix = $null
        $resolvedCredential = $null
        $resolvedApiKey = $null

        switch ($PSCmdlet.ParameterSetName) {

            'PSGallery' {
                $repositoryName = 'PSGallery'
                $apiKeyParams = @{
                    BoundKey     = $PSBoundParameters['PowerShellGalleryApiKey']
                    EnvVarValue  = $env:PSGALLERY_API_KEY
                    ErrorMessage = 'No API key provided. Supply -PowerShellGalleryApiKey or set $env:PSGALLERY_API_KEY.'
                }

                $resolvedApiKey = Resolve-ApiKey @apiKeyParams
            }

            'NuGetFeed' {
                $apiKeyParams = @{
                    BoundKey     = $PSBoundParameters['NuGetApiKey']
                    EnvVarValue  = $env:NUGET_API_KEY
                    ErrorMessage = 'No API key provided. Supply -NuGetApiKey or set $env:NUGET_API_KEY.'
                }

                $resolvedApiKey = Resolve-ApiKey @apiKeyParams
                $tempRepositoryUri = $NuGetFeedUrl
                $tempRepositoryPrefix = 'NuGetFeed'
            }

            'FileShare' {
                if (-not (Test-Path -Path $FileSharePath)) {
                    throw "File share path '$FileSharePath' is not accessible."
                }

                if ($PSBoundParameters.ContainsKey('FileShareCredential')) {
                    $resolvedCredential = $FileShareCredential
                } elseif (-not [string]::IsNullOrEmpty($env:FILESHARE_USERNAME) -and -not [string]::IsNullOrEmpty($env:FILESHARE_PASSWORD)) {
                    try {
                        $securePass = ConvertTo-ReadOnlySecureString -Value $env:FILESHARE_PASSWORD
                        $resolvedCredential = [PSCredential]::new($env:FILESHARE_USERNAME, $securePass)
                    } finally {
                        Remove-Variable -Name securePass -ErrorAction SilentlyContinue
                    }
                }

                $tempRepositoryUri = $FileSharePath
                $tempRepositoryPrefix = 'FileShare'
            }
        }

        # Register a temporary repository for NuGetFeed and FileShare parameter sets.
        if ($null -ne $tempRepositoryUri) {
            $tempRepositoryName = "MAPublish_${tempRepositoryPrefix}_$([System.Guid]::NewGuid().ToString('N'))"
            $repositoryName = $tempRepositoryName

            Write-Verbose "Registering temporary repository '$tempRepositoryName'"
            # The registration will be removed by the finally block.
            Register-PSResourceRepository -Name $tempRepositoryName -Uri $tempRepositoryUri -Trusted
        }

        try {
            # Pre-publish validation
            if (-not $SkipPrePublishValidation) {
                Write-Verbose 'Running pre-publish validation.'
                Invoke-PrePublishValidation -Repository $repositoryName
            }

            # Publish
            if ($PSCmdlet.ShouldProcess($data.OutputModuleDir, "Publish $($data.ProjectName) v$($data.Version) to '$repositoryName'")) {

                $publishParams = @{
                    Path       = $data.OutputModuleDir
                    Repository = $repositoryName
                }

                if ($null -ne $resolvedCredential) {
                    $publishParams['Credential'] = $resolvedCredential
                }

                Write-Verbose "Publishing $($data.ProjectName) v$($data.Version) to '$repositoryName'."

                if ($SkipDependenciesCheck.IsPresent) {
                    $publishParams['SkipDependenciesCheck'] = $true
                }

                if ($PSCmdlet.ParameterSetName -ne 'FileShare') {
                    # Publish-PSResource requires a plain-text [string] for -ApiKey; no SecureString overload exists.
                    # SecureStringToBSTR copies the secret into an unmanaged BSTR; ZeroFreeBSTR destroys that copy.
                    $bstr = [System.Runtime.InteropServices.Marshal]::SecureStringToBSTR($resolvedApiKey)
                    try {
                        Publish-PSResource @publishParams -ApiKey ([System.Runtime.InteropServices.Marshal]::PtrToStringAuto($bstr))
                    } finally {
                        [System.Runtime.InteropServices.Marshal]::ZeroFreeBSTR($bstr)
                    }
                } else {
                    Publish-PSResource @publishParams
                }

                Write-Verbose "$($data.ProjectName) v$($data.Version) published successfully."
            }
        } finally {
            # Always clean up the temporary repository registration
            if ($null -ne $tempRepositoryName) {
                Write-Verbose "Unregistering temporary repository '$tempRepositoryName'."
                try {
                    Unregister-PSResourceRepository -Name $tempRepositoryName -ErrorAction Stop
                } catch {
                    Write-Warning "Failed to unregister temporary repository '$tempRepositoryName'. To remove it manually: Unregister-PSResourceRepository -Name '$tempRepositoryName'"
                }
            }
        }
    }
}
