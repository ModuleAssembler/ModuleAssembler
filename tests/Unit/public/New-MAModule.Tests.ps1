BeforeAll {
    $script:projectRoot = Split-Path -Path (Split-Path -Path (Split-Path -Path $PSScriptRoot -Parent) -Parent) -Parent
    . (Join-Path -Path $script:projectRoot -ChildPath 'src/public/New-MAModule.ps1')
}

Describe 'New-MAModule' -Tag 'Unit' {
    BeforeEach {
        $script:originalLocation = Get-Location
        $script:testRoot = Join-Path -Path ([System.IO.Path]::GetTempPath()) -ChildPath ([System.Guid]::NewGuid().ToString('N'))
        New-Item -Path $script:testRoot -ItemType Directory -Force | Out-Null
    }

    AfterEach {
        Set-Location -Path $script:originalLocation
        if (Test-Path -Path $script:testRoot) {
            Remove-Item -Path $script:testRoot -Recurse -Force
        }
    }

    It 'throws when provided path is invalid' {
        { New-MAModule -Path (Join-Path -Path $script:testRoot -ChildPath 'missing') -Confirm:$false } | Should-Throw -ExceptionMessage '*Not a valid path*'
    }

    It 'throws when project name is invalid' {
        $answers = @('1InvalidName', 'Description', '0.1.0', 'Author', '', '7.6', 'MIT', 'No', 'No', 'No')
        $script:answerIndex = 0

        Mock Read-HostResponse {
            $value = $answers[$script:answerIndex]
            $script:answerIndex++
            $value
        }

        { New-MAModule -Path $script:testRoot -Confirm:$false } | Should-Throw -ExceptionMessage '*Module Name invalid*'
    }

    It 'does not create the project when run with -WhatIf' {
        $answers = @('DemoModule', 'Description', '0.1.0', 'Author', '', '7.6', 'MIT', 'No', 'No', 'No')
        $script:answerIndex = 0

        Mock Read-HostResponse {
            $value = $answers[$script:answerIndex]
            $script:answerIndex++
            $value
        }

        New-MAModule -Path $script:testRoot -WhatIf

        (Test-Path -Path (Join-Path -Path $script:testRoot -ChildPath 'DemoModule')) | Should-BeFalse
    }

    It 'creates scaffold and moduleproject.json when confirmed' {
        $answers = @('DemoModule', 'Description', '0.1.0', 'Author', '', '7.6', 'MIT', 'No', 'No', 'No')
        $script:answerIndex = 0

        Mock Read-HostResponse {
            $value = $answers[$script:answerIndex]
            $script:answerIndex++
            $value
        }

        Mock Initialize-GitRepo {}
        Mock Copy-Item {}
        Mock Get-Content {
            @'
{
    "$schema": "./schemas/moduleassembler.v1.0.0.schema.json",
    "ProjectName": "Template",
    "Description": "Template",
    "Version": "0.1.0",
    "Manifest": {
        "Author": "",
        "CompanyName": "",
        "PowerShellVersion": "7.6",
        "GUID": "00000000-0000-0000-0000-000000000000"
    },
    "Pester": {
        "Run": {},
        "Output": {},
        "Filter": {},
        "TestResult": {}
    }
}
'@
        } -ParameterFilter { $Path -like '*ModuleProjectTemplate.json' }

        Mock Get-Content {
            'MIT template <YEAR> <COPYRIGHT HOLDER>'
        } -ParameterFilter { $Path -like '*LicenseTemplates*' }

        Mock Get-Content {
            '# Changelog'
        } -ParameterFilter { $Path -like '*CHANGELOG.md' }

        New-MAModule -Path $script:testRoot -Confirm:$false

        $projectDir = Join-Path -Path $script:testRoot -ChildPath 'DemoModule'
        $projectJson = Join-Path -Path $projectDir -ChildPath '.moduleassembler/moduleproject.json'

        (Test-Path -Path $projectDir) | Should-BeTrue
        (Test-Path -Path $projectJson) | Should-BeTrue

        $projectData = [System.IO.File]::ReadAllText($projectJson) | ConvertFrom-Json
        $projectData.ProjectName | Should-Be 'DemoModule'
        $projectData.Manifest.PowerShellVersion | Should-Be '7.6'
        $projectData.Pester | Should-BeNull
    }
}
