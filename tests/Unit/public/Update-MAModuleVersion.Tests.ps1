BeforeAll {
    $script:projectRoot = Split-Path -Path (Split-Path -Path (Split-Path -Path $PSScriptRoot -Parent) -Parent) -Parent
    . (Join-Path -Path $script:projectRoot -ChildPath 'src/public/Get-MAProjectInfo.ps1')
    . (Join-Path -Path $script:projectRoot -ChildPath 'src/public/Update-MAModuleVersion.ps1')
    . (Join-Path -Path $script:projectRoot -ChildPath 'src/private/Get-PreReleaseIncrement.ps1')
}

Describe 'Update-MAModuleVersion' -Tag 'Unit' {
    BeforeEach {
        $script:testRoot = Join-Path -Path ([System.IO.Path]::GetTempPath()) -ChildPath ([System.Guid]::NewGuid().ToString('N'))
        $script:moduleAssemblerDir = Join-Path -Path $script:testRoot -ChildPath '.moduleassembler'
        $script:projectJsonPath = Join-Path -Path $script:moduleAssemblerDir -ChildPath 'moduleproject.json'
        New-Item -Path $script:moduleAssemblerDir -ItemType Directory -Force | Out-Null
    }

    AfterEach {
        if (Test-Path -Path $script:testRoot) {
            Remove-Item -Path $script:testRoot -Recurse -Force
        }
    }

    It 'increments patch version by default when no label is supplied' {
        '{"Version":"1.2.3"}' | Set-Content -Path $script:projectJsonPath -Encoding 'utf8NoBOM'

        Mock Get-MAProjectInfo {
            [PSCustomObject]@{
                ProjectJSON = $script:projectJsonPath
            }
        }

        Update-MAModuleVersion -Confirm:$false

        $updated = Get-Content -Path $script:projectJsonPath -Raw | ConvertFrom-Json
        $updated.Version | Should-Be '1.2.4'
    }

    It 'increments prerelease using current label when same prerelease type is provided without label' {
        '{"Version":"1.2.3-preview01"}' | Set-Content -Path $script:projectJsonPath -Encoding 'utf8NoBOM'

        Mock Get-MAProjectInfo {
            [PSCustomObject]@{
                ProjectJSON = $script:projectJsonPath
            }
        }

        Mock Get-PreReleaseIncrement { 'preview02' } -ParameterFilter { $PreReleaseLabel -eq 'preview01' }

        Update-MAModuleVersion -PreReleaseType preview -Confirm:$false

        Should-Invoke Get-PreReleaseIncrement -Exactly 1 -ParameterFilter { $PreReleaseLabel -eq 'preview01' }

        $updated = Get-Content -Path $script:projectJsonPath -Raw | ConvertFrom-Json
        $updated.Version | Should-Be '1.2.3-preview02'
    }

    It 'removes prerelease without incrementing base version when PreReleaseRemove is used' {
        '{"Version":"1.2.3-rc01"}' | Set-Content -Path $script:projectJsonPath -Encoding 'utf8NoBOM'

        Mock Get-MAProjectInfo {
            [PSCustomObject]@{
                ProjectJSON = $script:projectJsonPath
            }
        }

        Update-MAModuleVersion -PreReleaseRemove -Confirm:$false

        $updated = Get-Content -Path $script:projectJsonPath -Raw | ConvertFrom-Json
        $updated.Version | Should-Be '1.2.3'
    }

    It 'throws when PreReleaseRemove is combined with Label' {
        '{"Version":"1.2.3-rc01"}' | Set-Content -Path $script:projectJsonPath -Encoding 'utf8NoBOM'

        Mock Get-MAProjectInfo {
            [PSCustomObject]@{
                ProjectJSON = $script:projectJsonPath
            }
        }

        { Update-MAModuleVersion -PreReleaseRemove -Label Patch -Confirm:$false } | Should-Throw
    }

    It 'throws when PreReleaseRemove is combined with PreReleaseType' {
        '{"Version":"1.2.3-rc01"}' | Set-Content -Path $script:projectJsonPath -Encoding 'utf8NoBOM'

        Mock Get-MAProjectInfo {
            [PSCustomObject]@{
                ProjectJSON = $script:projectJsonPath
            }
        }

        { Update-MAModuleVersion -PreReleaseRemove -PreReleaseType rc -Confirm:$false } | Should-Throw
    }

    It 'switches prerelease type when a different prerelease type is provided without label' {
        '{"Version":"1.2.3-beta01"}' | Set-Content -Path $script:projectJsonPath -Encoding 'utf8NoBOM'

        Mock Get-MAProjectInfo {
            [PSCustomObject]@{
                ProjectJSON = $script:projectJsonPath
            }
        }

        Mock Get-PreReleaseIncrement { 'preview01' } -ParameterFilter { $PreReleaseLabel -eq 'preview' }

        Update-MAModuleVersion -PreReleaseType preview -Confirm:$false

        Should-Invoke Get-PreReleaseIncrement -Exactly 1 -ParameterFilter { $PreReleaseLabel -eq 'preview' }

        $updated = Get-Content -Path $script:projectJsonPath -Raw | ConvertFrom-Json
        $updated.Version | Should-Be '1.2.3-preview01'
    }

    It 'increments label and applies prerelease type when both are provided' {
        '{"Version":"0.1.0"}' | Set-Content -Path $script:projectJsonPath -Encoding 'utf8NoBOM'

        Mock Get-MAProjectInfo {
            [PSCustomObject]@{
                ProjectJSON = $script:projectJsonPath
            }
        }

        Mock Get-PreReleaseIncrement { 'rc01' } -ParameterFilter { $PreReleaseLabel -eq 'rc' }

        Update-MAModuleVersion -Label Major -PreReleaseType rc -Confirm:$false

        Should-Invoke Get-PreReleaseIncrement -Exactly 1 -ParameterFilter { $PreReleaseLabel -eq 'rc' }

        $updated = Get-Content -Path $script:projectJsonPath -Raw | ConvertFrom-Json
        $updated.Version | Should-Be '1.0.0-rc01'
    }

    It 'keeps base version unchanged when PreReleaseRemove is used on a non-prerelease version' {
        '{"Version":"1.2.3"}' | Set-Content -Path $script:projectJsonPath -Encoding 'utf8NoBOM'

        Mock Get-MAProjectInfo {
            [PSCustomObject]@{
                ProjectJSON = $script:projectJsonPath
            }
        }

        Update-MAModuleVersion -PreReleaseRemove -Confirm:$false

        $updated = Get-Content -Path $script:projectJsonPath -Raw | ConvertFrom-Json
        $updated.Version | Should-Be '1.2.3'
    }

    It 'does not modify moduleproject.json when run with -WhatIf' {
        '{"Version":"2.0.0"}' | Set-Content -Path $script:projectJsonPath -Encoding 'utf8NoBOM'

        Mock Get-MAProjectInfo {
            [PSCustomObject]@{
                ProjectJSON = $script:projectJsonPath
            }
        }

        $before = Get-Content -Path $script:projectJsonPath -Raw

        Update-MAModuleVersion -Label Major -WhatIf

        $after = Get-Content -Path $script:projectJsonPath -Raw
        $after | Should-BeString $before -CaseSensitive
    }
}
