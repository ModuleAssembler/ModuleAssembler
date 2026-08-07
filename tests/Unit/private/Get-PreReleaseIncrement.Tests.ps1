BeforeAll {
    $script:projectRoot = Split-Path -Path (Split-Path -Path (Split-Path -Path $PSScriptRoot -Parent) -Parent) -Parent
    . (Join-Path -Path $script:projectRoot -ChildPath 'src/private/Get-PreReleaseIncrement.ps1')
}

Describe 'Get-PreReleaseIncrement' -Tag 'Unit' {
    It 'increments a two-digit trailing prerelease number' {
        Get-PreReleaseIncrement -PreReleaseLabel 'preview01' | Should-Be 'preview02'
    }

    It 'increments a trailing number without truncation when it exceeds two digits' {
        Get-PreReleaseIncrement -PreReleaseLabel 'beta99' | Should-Be 'beta100'
    }

    It 'appends 01 when the label has no trailing digits' {
        Get-PreReleaseIncrement -PreReleaseLabel 'rc' | Should-Be 'rc01'
    }
}
