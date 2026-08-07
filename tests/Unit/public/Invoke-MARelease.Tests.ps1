BeforeAll {
    $script:projectRoot = Split-Path -Path (Split-Path -Path (Split-Path -Path $PSScriptRoot -Parent) -Parent) -Parent
    . (Join-Path -Path $script:projectRoot -ChildPath 'src/public/Get-MAProjectInfo.ps1')
    . (Join-Path -Path $script:projectRoot -ChildPath 'src/public/Test-MAModule.ps1')
    . (Join-Path -Path $script:projectRoot -ChildPath 'src/public/Build-MAModule.ps1')
    . (Join-Path -Path $script:projectRoot -ChildPath 'src/public/Build-MAModuleDocumentation.ps1')
    . (Join-Path -Path $script:projectRoot -ChildPath 'src/public/Publish-MAModule.ps1')
    . (Join-Path -Path $script:projectRoot -ChildPath 'src/public/Update-MAModuleVersion.ps1')
    . (Join-Path -Path $script:projectRoot -ChildPath 'src/public/Update-MAChangelogRelease.ps1')
    . (Join-Path -Path $script:projectRoot -ChildPath 'src/public/Invoke-MARelease.ps1')
}

Describe 'Invoke-MARelease' -Tag 'Unit' {
    It 'throws when VersionLabel is used without -UpdateVersion' {
        { Invoke-MARelease -VersionLabel Patch -Confirm:$false } | Should-Throw -ExceptionMessage '*require -UpdateVersion*'
    }

    It 'throws when ChangelogReleaseDate is used without -PromoteChangelogRelease' {
        { Invoke-MARelease -ChangelogReleaseDate (Get-Date) -Confirm:$false } | Should-Throw -ExceptionMessage '*requires -PromoteChangelogRelease*'
    }

    It 'runs the baseline release flow and calls expected test tags' {
        Mock Get-MAProjectInfo {
            [PSCustomObject]@{
                ProjectName = 'DemoModule'
                Version     = '1.2.3'
            }
        }

        $script:tagsSeen = @()
        Mock Test-MAModule {
            param([string[]]$TagFilter)
            $script:tagsSeen += ($TagFilter -join ',')
        }

        Mock Build-MAModule {}
        Mock Build-MAModuleDocumentation {}
        Mock Publish-MAModule {}
        Mock Update-MAModuleVersion {}
        Mock Update-MAChangelogRelease {}

        Invoke-MARelease -Confirm:$false

        Should-Invoke Build-MAModule -Exactly 1
        Should-Invoke Build-MAModuleDocumentation -Exactly 1
        Should-Invoke Publish-MAModule -Exactly 1
        Should-Invoke Update-MAModuleVersion -Exactly 0
        Should-Invoke Update-MAChangelogRelease -Exactly 0

        $script:tagsSeen | Should-ContainCollection 'FunctionQA'
        $script:tagsSeen | Should-ContainCollection 'ModuleQA'
        $script:tagsSeen | Should-ContainCollection 'Unit'
        $script:tagsSeen | Should-ContainCollection 'ChangeLog,License'
    }

    It 'does not run ShouldProcess-protected mutation steps when using -WhatIf' {
        Mock Get-MAProjectInfo {
            [PSCustomObject]@{
                ProjectName = 'DemoModule'
                Version     = '1.2.3'
            }
        }

        Mock Test-MAModule {}
        Mock Build-MAModule {}
        Mock Build-MAModuleDocumentation {}
        Mock Publish-MAModule {}
        Mock Update-MAModuleVersion {}
        Mock Update-MAChangelogRelease {}

        Invoke-MARelease -UpdateVersion -VersionLabel Patch -PromoteChangelogRelease -WhatIf

        Should-Invoke Test-MAModule -Exactly 4
        Should-Invoke Build-MAModule -Exactly 0
        Should-Invoke Build-MAModuleDocumentation -Exactly 0
        Should-Invoke Publish-MAModule -Exactly 0
        Should-Invoke Update-MAModuleVersion -Exactly 0
        Should-Invoke Update-MAChangelogRelease -Exactly 0
    }
}
