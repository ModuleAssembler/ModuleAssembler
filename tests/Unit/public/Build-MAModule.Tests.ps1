BeforeAll {
    $script:projectRoot = Split-Path -Path (Split-Path -Path (Split-Path -Path $PSScriptRoot -Parent) -Parent) -Parent
    . (Join-Path -Path $script:projectRoot -ChildPath 'src/public/Build-MAModule.ps1')
    . (Join-Path -Path $script:projectRoot -ChildPath 'src/public/Get-MAProjectInfo.ps1')
    . (Join-Path -Path $script:projectRoot -ChildPath 'src/private/Reset-ProjectDist.ps1')
    . (Join-Path -Path $script:projectRoot -ChildPath 'src/private/Build-Module.ps1')
    . (Join-Path -Path $script:projectRoot -ChildPath 'src/private/Build-Manifest.ps1')
    . (Join-Path -Path $script:projectRoot -ChildPath 'src/private/Copy-ProjectResource.ps1')
}

Describe 'Build-MAModule' -Tag 'Unit' {
    It 'invokes all build helper commands once' {
        Mock Get-Module {
            [PSCustomObject]@{ Version = [version]'1.0.0' }
        } -ParameterFilter { $Name -eq 'ModuleAssembler' }

        Mock Reset-ProjectDist {}
        Mock Build-Module {}
        Mock Build-Manifest {}
        Mock Copy-ProjectResource {}

        Build-MAModule

        Should-Invoke Reset-ProjectDist -Exactly 1
        Should-Invoke Build-Module -Exactly 1
        Should-Invoke Build-Manifest -Exactly 1
        Should-Invoke Copy-ProjectResource -Exactly 1
    }

    It 'surfaces helper errors' {
        Mock Get-Module {
            [PSCustomObject]@{ Version = [version]'1.0.0' }
        } -ParameterFilter { $Name -eq 'ModuleAssembler' }

        Mock Reset-ProjectDist { throw 'Reset failed.' }
        Mock Build-Module {}
        Mock Build-Manifest {}
        Mock Copy-ProjectResource {}

        { Build-MAModule } | Should-Throw -ExceptionMessage '*Reset failed*'
    }

    Context 'when copying project resources' {
        BeforeEach {
            $script:testRoot = Join-Path -Path $TestDrive -ChildPath ([System.Guid]::NewGuid().ToString('N'))
            $script:resourcesPath = Join-Path -Path $script:testRoot -ChildPath 'project/src/resources'
            $script:outputModuleDir = Join-Path -Path $script:testRoot -ChildPath 'output'
            New-Item -Path $script:resourcesPath -ItemType Directory -Force | Out-Null
            New-Item -Path $script:outputModuleDir -ItemType Directory -Force | Out-Null

            $script:projectInfo = [PSCustomObject]@{
                ProjectRoot               = (Join-Path -Path $script:testRoot -ChildPath 'project')
                OutputModuleDir           = $script:outputModuleDir
                CopyResourcesToModuleRoot = $false
            }

            Mock Get-Module {
                [PSCustomObject]@{ Version = [version]'1.0.0' }
            } -ParameterFilter { $Name -eq 'ModuleAssembler' }
            Mock Get-MAProjectInfo { $script:projectInfo }
            Mock Reset-ProjectDist {}
            Mock Build-Module {}
            Mock Build-Manifest {}
        }

        It 'does not create a resources destination when src/resources contains only .gitkeep' {
            New-Item -Path (Join-Path -Path $script:resourcesPath -ChildPath '.gitkeep') -ItemType File | Out-Null

            Build-MAModule

            (Test-Path -Path (Join-Path -Path $script:outputModuleDir -ChildPath 'resources')) | Should-BeFalse
        }

        It 'copies resources but excludes .gitkeep' {
            New-Item -Path (Join-Path -Path $script:resourcesPath -ChildPath '.gitkeep') -ItemType File | Out-Null
            Set-Content -Path (Join-Path -Path $script:resourcesPath -ChildPath 'asset.txt') -Value 'resource content'

            Build-MAModule

            $resourceDestination = Join-Path -Path $script:outputModuleDir -ChildPath 'resources'
            (Test-Path -Path (Join-Path -Path $resourceDestination -ChildPath 'asset.txt')) | Should-BeTrue
            (Test-Path -Path (Join-Path -Path $resourceDestination -ChildPath '.gitkeep')) | Should-BeFalse
        }

        It 'copies resources to the module root but excludes .gitkeep' {
            $script:projectInfo.CopyResourcesToModuleRoot = $true
            New-Item -Path (Join-Path -Path $script:resourcesPath -ChildPath '.gitkeep') -ItemType File | Out-Null
            Set-Content -Path (Join-Path -Path $script:resourcesPath -ChildPath 'asset.txt') -Value 'resource content'

            Build-MAModule

            (Test-Path -Path (Join-Path -Path $script:outputModuleDir -ChildPath 'asset.txt')) | Should-BeTrue
            (Test-Path -Path (Join-Path -Path $script:outputModuleDir -ChildPath '.gitkeep')) | Should-BeFalse
        }
    }
}
