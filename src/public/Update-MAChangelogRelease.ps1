function Update-MAChangelogRelease {
    <#
    .SYNOPSIS
        Promotes CHANGELOG.md [Unreleased] content into a versioned release section.

    .DESCRIPTION
        Reads CHANGELOG.md from the current module project root, moves the current [Unreleased]
        section content into a new versioned section, and recreates a fresh [Unreleased] section
        with standard placeholder headings.

        The target version defaults to the current project version from Get-MAProjectInfo when
        -Version is not specified.

    .PARAMETER Version
        Semantic version label for the new changelog section (for example 1.2.3 or 1.2.3-rc01).
        Defaults to the current project version.

    .PARAMETER ReleaseDate
        Release date for the versioned changelog heading. Defaults to today.

    .EXAMPLE
        Update-MAChangelogRelease

        Promotes [Unreleased] content into the current project version using today's date.

    .EXAMPLE
        Update-MAChangelogRelease -Version '1.4.0' -ReleaseDate (Get-Date '2026-05-24')

        Promotes [Unreleased] content into version 1.4.0 with the specified release date.
    #>

    [CmdletBinding(SupportsShouldProcess = $true)]
    [OutputType([void])]
    [Alias('MAChangelogRelease')]
    param (
        [Parameter(Mandatory = $false)]
        [ValidateNotNullOrEmpty()]
        [string] $Version,

        [Parameter(Mandatory = $false)]
        [datetime] $ReleaseDate = (Get-Date)
    )

    begin {
        $ErrorActionPreference = 'Stop'
        $data = Get-MAProjectInfo

        if (-not $PSBoundParameters.ContainsKey('Version')) {
            $Version = $data.Version
        }

        if ([string]::IsNullOrWhiteSpace($Version)) {
            throw 'Version is required. Provide -Version or ensure Get-MAProjectInfo returns a valid version.'
        }

        $changelogPath = Join-Path -Path $data.ProjectRoot -ChildPath 'CHANGELOG.md'
        if (-not (Test-Path -Path $changelogPath)) {
            throw "CHANGELOG.md not found at '$changelogPath'."
        }
    }

    process {
        $lines = Get-Content -Path $changelogPath
        $unreleasedIndex = -1

        for ($index = 0; $index -lt $lines.Count; $index++) {
            if ($lines[$index] -match '^## \[Unreleased\]\s*$') {
                $unreleasedIndex = $index
                break
            }
        }

        if ($unreleasedIndex -lt 0) {
            throw "CHANGELOG.md does not contain a '## [Unreleased]' section."
        }

        $nextSectionIndex = $lines.Count
        for ($index = $unreleasedIndex + 1; $index -lt $lines.Count; $index++) {
            if ($lines[$index] -match '^## \[') {
                $nextSectionIndex = $index
                break
            }
        }

        $versionPattern = "^## \[$([regex]::Escape($Version))\](\s+-\s+\d{4}-\d{2}-\d{2})?\s*$"
        if ($lines | Where-Object { $_ -match $versionPattern }) {
            throw "CHANGELOG.md already contains an entry for version [$Version]."
        }

        $unreleasedContent = @()
        if ($nextSectionIndex -gt ($unreleasedIndex + 1)) {
            $unreleasedContent = $lines[($unreleasedIndex + 1)..($nextSectionIndex - 1)]
        }

        $releaseHeader = "## [$Version] - $($ReleaseDate.ToString('yyyy-MM-dd'))"

        $newLines = @()

        if ($unreleasedIndex -gt 0) {
            $newLines += $lines[0..($unreleasedIndex - 1)]
        }

        $newLines += @(
            '## [Unreleased]',
            '',
            '### Added',
            '',
            '### Changed',
            '',
            '### Deprecated',
            '',
            '### Removed',
            '',
            '### Fixed',
            '',
            '### Security',
            '',
            $releaseHeader,
            ''
        )

        if ($unreleasedContent.Count -gt 0) {
            $newLines += $unreleasedContent
            if (-not [string]::IsNullOrWhiteSpace($newLines[$newLines.Count - 1])) {
                $newLines += ''
            }
        }

        if ($nextSectionIndex -lt $lines.Count) {
            $newLines += $lines[$nextSectionIndex..($lines.Count - 1)]
        }

        if ($PSCmdlet.ShouldProcess($changelogPath, "Promote [Unreleased] content to version [$Version]")) {
            Set-Content -Path $changelogPath -Value $newLines -Encoding 'utf8NoBOM'
            Write-Verbose -Message "Promoted [Unreleased] content to version [$Version] in '$changelogPath'."
        }
    }
}
