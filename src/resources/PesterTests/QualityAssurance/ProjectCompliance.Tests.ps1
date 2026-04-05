BeforeDiscovery {
    $data = Get-MAProjectInfo
    $changeLogPath = Join-Path -Path $data.ProjectRoot -ChildPath 'CHANGELOG.md'

    $script:versionBlocks = @()

    if (Test-Path -Path $changeLogPath) {
        $lines = Get-Content -Path $changeLogPath
        $current = $null
        $blocks = [System.Collections.Generic.List[hashtable]]::new()

        foreach ($line in $lines) {
            if ($line -match '^## \[') {
                if ($null -ne $current) {
                    $blocks.Add(@{ Header = $current.Header; Lines = $current.Lines.ToArray() })
                }
                $current = @{
                    Header = $line
                    Lines  = [System.Collections.Generic.List[string]]::new()
                }
                $null = $current.Lines.Add($line)
            } elseif ($null -ne $current) {
                $null = $current.Lines.Add($line)
            }
        }

        if ($null -ne $current) {
            $blocks.Add(@{ Header = $current.Header; Lines = $current.Lines.ToArray() })
        }

        $script:versionBlocks = $blocks.ToArray()
    }
}

BeforeAll {
    $script:data = Get-MAProjectInfo
    $script:changeLogPath = Join-Path -Path $script:data.ProjectRoot -ChildPath 'CHANGELOG.md'
    $script:changeLogExists = Test-Path -Path $script:changeLogPath

    if ($script:changeLogExists) {
        $script:content = Get-Content -Path $script:changeLogPath -Raw
        $script:lines = Get-Content -Path $script:changeLogPath
    }
}

Describe 'CHANGELOG.md' -Tag 'ChangeLog' {

    Context 'File' {

        It 'exists at the project root' {
            $script:changeLogExists | Should -BeTrue
        }
    }

    Context 'Document Structure' {

        It 'has "# Changelog" as the first H1 heading' {
            $firstH1 = $script:lines | Where-Object { $_ -match '^# \S' } | Select-Object -First 1
            $firstH1 | Should -Be '# Changelog'
        }

        It 'states that all notable changes are documented' {
            $script:content | Should -Match '(?i)notable\s+changes'
        }

        It 'references the Keep a Changelog specification' {
            $script:content | Should -Match 'https://keepachangelog\.com/en/1\.1\.0/'
        }

        It 'states adherence to Semantic Versioning' {
            $script:content | Should -Match 'https://semver\.org'
        }

        It 'contains at least one version entry' {
            @($script:lines | Where-Object { $_ -match '^## \[' }).Count | Should -BeGreaterThan 0
        }

        It 'places [Unreleased] as the first version entry when present' {
            $versionLines = @($script:lines | Where-Object { $_ -match '^## \[' })
            $hasUnreleased = $versionLines | Where-Object { $_ -match '(?i)unreleased' }
            if ($hasUnreleased) {
                $versionLines[0] | Should -Match '^## \[Unreleased\]'
            }
        }
    }

    Context 'Version Entry: <_.Header>' -ForEach $versionBlocks {

        BeforeAll {
            $script:header = $_.Header
            $script:blockLines = $_.Lines
            $script:isUnreleased = $script:header -match '^## \[Unreleased\]$'
        }

        It 'has a valid Keep a Changelog header format' {
            if ($script:isUnreleased) {
                $script:header | Should -Match '^## \[Unreleased\]$'
            } else {
                # ## [MAJOR.MINOR.PATCH] - YYYY-MM-DD  or  ## [x.y.z] - YYYY-MM-DD [YANKED]
                $script:header | Should -Match (
                    '^## \[[0-9]+\.[0-9]+\.[0-9][^\]]*\] - ' +
                    '\d{4}-(?:0[1-9]|1[0-2])-(?:0[1-9]|[12]\d|3[01])' +
                    '(?:\s+\[YANKED\])?$'
                )
            }
        }

        It 'has a parseable ISO 8601 release date' {
            if (-not $script:isUnreleased) {
                $dateMatch = [regex]::Match($script:header, '(\d{4}-\d{2}-\d{2})')
                $dateMatch.Success | Should -BeTrue -Because 'every released version requires a date'
                {
                    [datetime]::ParseExact(
                        $dateMatch.Groups[1].Value,
                        'yyyy-MM-dd',
                        [System.Globalization.CultureInfo]::InvariantCulture
                    )
                } | Should -Not -Throw -Because "$($dateMatch.Groups[1].Value) must be a valid calendar date"
            }
        }

        It 'contains at least one change-type section (### Added, Changed, etc.)' {
            if (-not $script:isUnreleased) {
                $sectionLines = @($script:blockLines | Where-Object { $_ -match '^### ' })
                $sectionLines.Count | Should -BeGreaterThan 0 `
                    -Because 'released versions must group changes under at least one ### <type> heading per Keep a Changelog 1.1.0'
            }
        }

        It 'groups all changes under a change-type heading (### <type>) — no ungrouped entries allowed' {
            # Every non-blank content line must appear after a ### heading, never directly under ## [version].
            $count = $script:blockLines.Count
            $firstSection = $null
            for ($i = 1; $i -lt $count; $i++) {
                if ($script:blockLines[$i] -match '^### ') {
                    $firstSection = $i
                    break
                }
            }
            # Lines between the ## header and the first ### (or end of block) must all be blank.
            $limit = if ($null -ne $firstSection) {
                $firstSection
            } else {
                $count
            }
            for ($i = 1; $i -lt $limit; $i++) {
                [string]::IsNullOrWhiteSpace($script:blockLines[$i]) |
                    Should -BeTrue `
                        -Because "'$($script:blockLines[$i])' must be grouped under a '### <type>' heading per Keep a Changelog 1.1.0"
            }
        }

        It 'uses only valid Keep a Changelog change-type headings (###)' {
            $validTypes = @('Added', 'Changed', 'Deprecated', 'Removed', 'Fixed', 'Security')
            $sectionLines = @($script:blockLines | Where-Object { $_ -match '^### ' })
            foreach ($sectionLine in $sectionLines) {
                ($sectionLine -replace '^### ').Trim() |
                    Should -BeIn $validTypes -Because "'$sectionLine' is not a valid Keep a Changelog change type"
            }
        }

        It 'has no empty change-type sections' {
            $count = $script:blockLines.Count
            for ($i = 0; $i -lt $count; $i++) {
                if ($script:blockLines[$i] -match '^### ') {
                    $next = $i + 1
                    while ($next -lt $count -and [string]::IsNullOrWhiteSpace($script:blockLines[$next])) {
                        $next++
                    }
                    ($next -ge $count -or $script:blockLines[$next] -match '^#') |
                        Should -BeFalse -Because "'$($script:blockLines[$i])' must not be an empty section"
                }
            }
        }

        It 'uses markdown list items for change entries' {
            $count = $script:blockLines.Count
            for ($i = 0; $i -lt $count; $i++) {
                if ($script:blockLines[$i] -match '^### ') {
                    $next = $i + 1
                    while ($next -lt $count -and [string]::IsNullOrWhiteSpace($script:blockLines[$next])) {
                        $next++
                    }
                    if ($next -lt $count -and $script:blockLines[$next] -notmatch '^#') {
                        $script:blockLines[$next] | Should -Match '^[-*] ' `
                            -Because "entries under '$($script:blockLines[$i])' must be markdown list items"
                    }
                }
            }
        }
    }

    Context 'Version Ordering and Uniqueness' {

        It 'lists released versions in reverse chronological order (newest first)' {
            $datePattern = '^## \[[^\]]+\] - (\d{4}-\d{2}-\d{2})'
            $dates = @(
                $script:lines |
                    Where-Object { $_ -match $datePattern } |
                    ForEach-Object {
                        [datetime]::ParseExact(
                            [regex]::Match($_, $datePattern).Groups[1].Value,
                            'yyyy-MM-dd',
                            [System.Globalization.CultureInfo]::InvariantCulture
                        )
                    }
            )
            if ($dates.Count -gt 1) {
                $dates | Should -Be ($dates | Sort-Object -Descending) `
                    -Because 'versions must be listed newest-first per the Keep a Changelog spec'
            }
        }

        It 'contains no duplicate version entries' {
            $versionPattern = '^## \[([^\]]+)\]'
            $versions = @(
                $script:lines |
                    Where-Object { $_ -match $versionPattern } |
                    ForEach-Object { [regex]::Match($_, $versionPattern).Groups[1].Value }
            )
            $versions.Count | Should -Be ($versions | Select-Object -Unique).Count `
                -Because 'each version label must appear exactly once'
        }
    }

    Context 'Version Reference Links' {

        It 'provides a reference link for every version entry when any links are defined' {
            $linkPattern = '^\[([^\]]+)\]:\s*https?://'
            $definedLinks = @(
                $script:lines |
                    Where-Object { $_ -match $linkPattern } |
                    ForEach-Object { [regex]::Match($_, $linkPattern).Groups[1].Value }
            )

            if ($definedLinks.Count -gt 0) {
                $versionPattern = '^## \[([^\]]+)\]'
                $versions = @(
                    $script:lines |
                        Where-Object { $_ -match $versionPattern } |
                        ForEach-Object { [regex]::Match($_, $versionPattern).Groups[1].Value }
                )
                foreach ($version in $versions) {
                    $version | Should -BeIn $definedLinks `
                        -Because "[$version] requires a reference link at the bottom of the file"
                }
            }
        }
    }
}

Describe 'LICENSE' -Tag 'License' {

    BeforeAll {
        $script:licensePath = Join-Path -Path $script:data.ProjectRoot -ChildPath 'LICENSE'
        $script:licenseExists = Test-Path -Path $script:licensePath
        $script:licenseContent = if ($script:licenseExists) {
            Get-Content -Path $script:licensePath -Raw
        }
    }

    Context 'File' {

        It 'exists at the project root' {
            $script:licenseExists | Should -BeTrue
        }
    }

    Context 'Content' {

        It 'is not empty' {
            $script:licenseContent | Should -Not -BeNullOrEmpty
        }

        It 'matches a recognised open-source license (MIT, Apache 2.0, BSD 3-Clause, or GPLv3)' {
            $isMIT = $script:licenseContent -match '(?i)\bMIT License\b'
            $isApache = ($script:licenseContent -match '(?i)Apache License') -and
            ($script:licenseContent -match 'Version 2\.0')
            $isBSD3 = $script:licenseContent -match '(?i)BSD 3-Clause License'
            $isGPL3 = ($script:licenseContent -match '(?i)GNU GENERAL PUBLIC LICENSE') -and
            ($script:licenseContent -match 'Version 3')

            ($isMIT -or $isApache -or $isBSD3 -or $isGPL3) | Should -BeTrue `
                -Because 'LICENSE must contain one of the four supported types: MIT, Apache 2.0, BSD 3-Clause, or GPLv3'
        }
    }
}
