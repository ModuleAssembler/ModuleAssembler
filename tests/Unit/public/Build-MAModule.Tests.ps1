BeforeAll {
    $script:projectRoot = Split-Path -Path (Split-Path -Path (Split-Path -Path $PSScriptRoot -Parent) -Parent) -Parent
    . (Join-Path -Path $script:projectRoot -ChildPath 'src/public/Build-MAModule.ps1')
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
}
