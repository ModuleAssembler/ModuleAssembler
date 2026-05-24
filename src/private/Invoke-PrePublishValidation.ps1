function Invoke-PrePublishValidation {
    <#
    .SYNOPSIS
        Runs pre-publish validation checks against the changelog and target repository.

    .DESCRIPTION
        Performs two pre-publish validation checks:
          1. Verifies the [Unreleased] section in CHANGELOG.md contains no staged content.
          2. Verifies the current version from moduleproject.json does not already exist as
             an entry in CHANGELOG.md.
          3. Verifies the current version has not already been published to the target repository
             using Find-PSResource.

    .EXAMPLE
        Invoke-PrePublishValidation -Repository 'PSGallery'

        Validates changelog state and confirms the current version is not already on PSGallery.
    #>

    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true)]
        [ValidateNotNullOrEmpty()]
        [string] $Repository
    )

    begin {
        $ErrorActionPreference = 'Stop'
        $data = Get-MAProjectInfo
        $changelogPath = Join-Path -Path $data.ProjectRoot -ChildPath 'CHANGELOG.md'
        $version = $data.Version
    }

    process {
        # --- Check 1: [Unreleased] section must be empty ---
        if (Test-Path -Path $changelogPath) {
            $lines = Get-Content -Path $changelogPath
            $inUnreleased = $false
            $unreleasedHasContent = $false
            $allowedUnreleasedHeadingPattern = '^###\s+(Added|Changed|Deprecated|Removed|Fixed|Security)\s*$'

            foreach ($line in $lines) {
                if ($line -match '^## \[Unreleased\]') {
                    $inUnreleased = $true
                    continue
                }
                if ($inUnreleased) {
                    if ($line -match '^## \[') {
                        break
                    }
                    if ([string]::IsNullOrWhiteSpace($line)) {
                        continue
                    }

                    if ($line -match $allowedUnreleasedHeadingPattern) {
                        continue
                    }

                    if (-not [string]::IsNullOrWhiteSpace($line)) {
                        $unreleasedHasContent = $true
                        break
                    }
                }
            }

            if ($unreleasedHasContent) {
                throw "CHANGELOG.md has staged content under [Unreleased]. Promote these changes to version [$version] before publishing."
            }
            Write-Verbose 'CHANGELOG.md [Unreleased] section is empty. OK.'

            # --- Check 2: Current version must not already exist in the changelog ---
            $versionPattern = "^## \[$([regex]::Escape($version))\]"
            $versionEntryExists = $lines | Where-Object { $_ -match $versionPattern }

            if (-not $versionEntryExists) {
                throw "CHANGELOG.md does not contain an entry for version [$version]. Document this release in the changelog before publishing."
            }
            Write-Verbose "CHANGELOG.md contains an entry for version [$version]. OK."
        } else {
            throw "CHANGELOG.md not found at '$changelogPath'. A changelog is required before publishing."
        }

        # --- Check 3: Version must not already exist on the target repository ---
        Write-Verbose "Checking if $($data.ProjectName) version $version is already published to '$Repository'."
        try {
            $existing = Find-PSResource -Name $data.ProjectName -Version $version -Repository $Repository -ErrorAction SilentlyContinue
        } catch {
            throw "Could not query repository '$Repository'. Verify the repository is registered and reachable: $_"
        }

        if ($existing) {
            throw "$($data.ProjectName) version $version is already published to '$Repository'. Increment the version before publishing."
        }
        Write-Verbose "$($data.ProjectName) version $version is not yet on '$Repository'. OK."
    }
}
