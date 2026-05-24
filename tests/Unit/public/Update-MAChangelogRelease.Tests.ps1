BeforeAll {
    $script:projectRoot = Split-Path -Path (Split-Path -Path (Split-Path -Path $PSScriptRoot -Parent) -Parent) -Parent
    . (Join-Path -Path $script:projectRoot -ChildPath 'src/public/Get-MAProjectInfo.ps1')
    . (Join-Path -Path $script:projectRoot -ChildPath 'src/public/Update-MAChangelogRelease.ps1')
}

Describe 'Update-MAChangelogRelease' -Tag 'Unit' {
    BeforeEach {
        $script:testRoot = Join-Path -Path ([System.IO.Path]::GetTempPath()) -ChildPath ([System.Guid]::NewGuid().ToString('N'))
        New-Item -Path $script:testRoot -ItemType Directory -Force | Out-Null
        $script:changelogPath = Join-Path -Path $script:testRoot -ChildPath 'CHANGELOG.md'
    }

    AfterEach {
        if (Test-Path -Path $script:testRoot) {
            Remove-Item -Path $script:testRoot -Recurse -Force
        }
    }

    It 'promotes [Unreleased] content and recreates placeholders' {
        @(
            '# Changelog',
            '',
            '## [Unreleased]',
            '',
            '### Added',
            '',
            '- New capability.',
            '',
            '### Changed',
            '',
            '## [1.2.2] - 2026-05-01',
            '',
            '### Added',
            '',
            '- Existing release note.'
        ) | Set-Content -Path $script:changelogPath -Encoding 'utf8NoBOM'

        Mock Get-MAProjectInfo {
            [PSCustomObject]@{
                ProjectRoot = $script:testRoot
                Version     = '1.2.3'
            }
        }

        Update-MAChangelogRelease -ReleaseDate ([datetime]'2026-05-24') -Confirm:$false

        $updated = Get-Content -Path $script:changelogPath -Raw
        $unreleasedStart = $updated.IndexOf('## [Unreleased]')
        $releaseStart = $updated.IndexOf('## [1.2.3] - 2026-05-24')
        $previousReleaseStart = $updated.IndexOf('## [1.2.2] - 2026-05-01')

        $unreleasedStart | Should -BeGreaterThan -1
        $releaseStart | Should -BeGreaterThan -1
        $previousReleaseStart | Should -BeGreaterThan -1
        $unreleasedStart | Should -BeLessThan $releaseStart
        $releaseStart | Should -BeLessThan $previousReleaseStart

        $unreleasedBlock = $updated.Substring($unreleasedStart, $releaseStart - $unreleasedStart)
        $unreleasedBlock | Should -Match '### Added'
        $unreleasedBlock | Should -Match '### Changed'
        $unreleasedBlock | Should -Match '### Deprecated'
        $unreleasedBlock | Should -Match '### Removed'
        $unreleasedBlock | Should -Match '### Fixed'
        $unreleasedBlock | Should -Match '### Security'
        $unreleasedBlock | Should -Not -Match 'New capability'

        $promotedBlock = $updated.Substring($releaseStart, $previousReleaseStart - $releaseStart)
        $promotedBlock | Should -Match 'New capability'
    }

    It 'throws when the target version already exists' {
        @(
            '# Changelog',
            '',
            '## [Unreleased]',
            '',
            '### Added',
            '',
            '- New capability.',
            '',
            '## [1.2.3] - 2026-05-24',
            '',
            '### Added',
            '',
            '- Existing entry.'
        ) | Set-Content -Path $script:changelogPath -Encoding 'utf8NoBOM'

        Mock Get-MAProjectInfo {
            [PSCustomObject]@{
                ProjectRoot = $script:testRoot
                Version     = '1.2.3'
            }
        }

        { Update-MAChangelogRelease -Confirm:$false } | Should -Throw '*already contains an entry for version*'
    }

    It 'does not modify the file when run with -WhatIf' {
        @(
            '# Changelog',
            '',
            '## [Unreleased]',
            '',
            '### Added',
            '',
            '- New capability.'
        ) | Set-Content -Path $script:changelogPath -Encoding 'utf8NoBOM'

        Mock Get-MAProjectInfo {
            [PSCustomObject]@{
                ProjectRoot = $script:testRoot
                Version     = '1.2.3'
            }
        }

        $before = Get-Content -Path $script:changelogPath -Raw
        Update-MAChangelogRelease -WhatIf
        $after = Get-Content -Path $script:changelogPath -Raw

        $after | Should -BeExactly $before
    }
}
