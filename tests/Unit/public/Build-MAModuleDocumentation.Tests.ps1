BeforeAll {
    $script:projectRoot = Split-Path -Path (Split-Path -Path (Split-Path -Path $PSScriptRoot -Parent) -Parent) -Parent
    . (Join-Path -Path $script:projectRoot -ChildPath 'src/public/Get-MAProjectInfo.ps1')
    . (Join-Path -Path $script:projectRoot -ChildPath 'src/public/Build-MAModuleDocumentation.ps1')
}

Describe 'Build-MAModuleDocumentation' -Tag 'Unit' {
    BeforeEach {
        $script:testRoot = Join-Path -Path ([System.IO.Path]::GetTempPath()) -ChildPath ([System.Guid]::NewGuid().ToString('N'))
        New-Item -Path $script:testRoot -ItemType Directory -Force | Out-Null

        Mock Test-DescriptionLine { $false }

        function Get-Demo {
            <#
            .SYNOPSIS
                Demo synopsis
            .DESCRIPTION
                Demo description
            .EXAMPLE
                Get-Demo

                Example description text.
            #>
            [CmdletBinding()]
            param()
        }

        $script:demoCommand = Get-Command -Name Get-Demo
    }

    AfterEach {
        Remove-Item -Path Function:\Get-Demo -ErrorAction SilentlyContinue
        if (Test-Path -Path $script:testRoot) {
            Remove-Item -Path $script:testRoot -Recurse -Force
        }
    }

    It 'throws when module import fails' {
        Mock Get-MAProjectInfo {
            [PSCustomObject]@{
                ProjectRoot      = $script:testRoot
                ProjectName      = 'DemoModule'
                ManifestFilePSD1 = 'C:\does-not-exist\DemoModule.psd1'
                Version          = '1.0.0'
                Description      = 'Demo module'
            }
        }

        Mock Import-Module { throw 'boom' }

        { Build-MAModuleDocumentation } | Should-Throw -ExceptionMessage '*Import of the built module failed*'
    }

    It 'creates command markdown and index files from help content' {
        Mock Get-MAProjectInfo {
            [PSCustomObject]@{
                ProjectRoot      = $script:testRoot
                ProjectName      = 'DemoModule'
                ManifestFilePSD1 = 'C:\temp\DemoModule.psd1'
                Version          = '1.0.0'
                Description      = 'Demo module'
            }
        }

        Mock Import-Module {}
        Mock Remove-Module {}
        Mock Get-Command {
            param(
                $Name,
                $Module,
                [switch]$Syntax
            )

            if ($PSBoundParameters.ContainsKey('Module')) {
                return @($script:demoCommand)
            }

            if ($Syntax.IsPresent) {
                return 'Get-Demo'
            }

            return $script:demoCommand
        }

        Build-MAModuleDocumentation

        $commandDoc = Join-Path -Path $script:testRoot -ChildPath 'docs/DemoModule/Commands/Get-Demo.md'
        $indexDoc = Join-Path -Path $script:testRoot -ChildPath 'docs/DemoModule/index.md'

        (Test-Path -Path $commandDoc) | Should-BeTrue
        (Test-Path -Path $indexDoc) | Should-BeTrue

        $indexContent = Get-Content -Path $indexDoc -Raw
        $indexContent | Should-MatchString 'Get-Demo'
    }

    It 'throws when required help synopsis is missing' {
        Mock Get-MAProjectInfo {
            [PSCustomObject]@{
                ProjectRoot      = $script:testRoot
                ProjectName      = 'DemoModule'
                ManifestFilePSD1 = 'C:\temp\DemoModule.psd1'
                Version          = '1.0.0'
                Description      = 'Demo module'
            }
        }

        Mock Import-Module {}
        Mock Remove-Module {}
        Mock Get-Command {
            param(
                $Name,
                $Module,
                [switch]$Syntax
            )

            if ($PSBoundParameters.ContainsKey('Module')) {
                return @($script:demoCommand)
            }

            if ($Syntax.IsPresent) {
                return 'Get-Demo'
            }

            return $script:demoCommand
        }
        Mock Get-Help {
            [PSCustomObject]@{
                synopsis    = $null
                description = 'x'
                examples    = [PSCustomObject]@{
                    example = @([PSCustomObject]@{ title = 'Example 1'; introduction = ''; code = 'Get-Demo'; remarks = 'desc' })
                }
            }
        } -ParameterFilter { $Name -eq 'Get-Demo' }

        { Build-MAModuleDocumentation } | Should-Throw -ExceptionMessage '*.SYNOPSIS section*'
    }
}
