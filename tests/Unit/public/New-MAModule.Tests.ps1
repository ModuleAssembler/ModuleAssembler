BeforeAll {
    $script:projectRoot = Split-Path -Path (Split-Path -Path (Split-Path -Path $PSScriptRoot -Parent) -Parent) -Parent
    . (Join-Path -Path $script:projectRoot -ChildPath 'src/private/Initialize-GitRepo.ps1')
    . (Join-Path -Path $script:projectRoot -ChildPath 'src/private/Read-HostResponse.ps1')
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

    It 'creates a new module subdirectory when the directory name does not match the module name using <Invocation>' -ForEach @(
        @{ Invocation = 'Path' }
        @{ Invocation = 'Current' }
    ) {
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

        if ($Invocation -eq 'Current') {
            Set-Location -Path $script:testRoot
            New-MAModule -Confirm:$false
        } else {
            New-MAModule -Path $script:testRoot -Confirm:$false
        }

        $projectDir = Join-Path -Path $script:testRoot -ChildPath 'DemoModule'
        $projectJson = Join-Path -Path $projectDir -ChildPath '.moduleassembler/moduleproject.json'

        (Test-Path -Path $projectDir) | Should-BeTrue
        (Test-Path -Path $projectJson) | Should-BeTrue
        (Test-Path -Path (Join-Path -Path $script:testRoot -ChildPath '.moduleassembler')) | Should-BeFalse

        $projectData = [System.IO.File]::ReadAllText($projectJson) | ConvertFrom-Json
        $projectData.ProjectName | Should-Be 'DemoModule'
        $projectData.Manifest.PowerShellVersion | Should-Be '7.6'
        $projectData.Pester | Should-BeNull
    }

    It 'scaffolds an acceptable directory using <Invocation> with existing metadata: <ExistingMetadata>' -ForEach @(
        @{ Invocation = 'Parent'; ExistingMetadata = $true }
        @{ Invocation = 'Current'; ExistingMetadata = $false }
        @{ Invocation = 'Current'; ExistingMetadata = $true }
        @{ Invocation = 'Explicit'; ExistingMetadata = $false }
        @{ Invocation = 'Explicit'; ExistingMetadata = $true }
        @{ Invocation = 'Relative'; ExistingMetadata = $true }
    ) {
        $projectDir = Join-Path -Path $script:testRoot -ChildPath 'DemoModule'
        New-Item -Path $projectDir -ItemType Directory | Out-Null
        if ($ExistingMetadata) {
            New-Item -Path (Join-Path -Path $projectDir -ChildPath '.git') -ItemType Directory | Out-Null
            Set-Content -Path (Join-Path -Path $projectDir -ChildPath '.git/config') -Value 'Existing git config'
            Set-Content -Path (Join-Path -Path $projectDir -ChildPath 'README.md') -Value 'Existing README'
        }

        $answers = @('DemoModule', 'Description', '0.1.0', 'Author', '', '7.6', 'MIT', 'No', 'No', 'No')
        $script:answerIndex = 0

        Mock Read-HostResponse {
            $value = $answers[$script:answerIndex]
            $script:answerIndex++
            $value
        }

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

        switch ($Invocation) {
            'Parent' {
                New-MAModule -Path $script:testRoot -Confirm:$false
            }
            'Current' {
                Set-Location -Path $projectDir
                New-MAModule -Confirm:$false
            }
            'Explicit' {
                New-MAModule -Path "$projectDir/" -Confirm:$false
            }
            'Relative' {
                Set-Location -Path $script:testRoot
                New-MAModule -Path './DemoModule' -Confirm:$false
            }
        }

        Test-Path -Path (Join-Path -Path $projectDir -ChildPath '.moduleassembler/moduleproject.json') | Should-BeTrue
        Test-Path -Path (Join-Path -Path $projectDir -ChildPath 'src/public') | Should-BeTrue
        Test-Path -Path (Join-Path -Path $projectDir -ChildPath 'DemoModule') | Should-BeFalse
        if ($ExistingMetadata) {
            [System.IO.File]::ReadAllText((Join-Path -Path $projectDir -ChildPath 'README.md')).Trim() | Should-Be 'Existing README'
            [System.IO.File]::ReadAllText((Join-Path -Path $projectDir -ChildPath '.git/config')).Trim() | Should-Be 'Existing git config'
        }
    }

    It 'rejects an occupied project directory using <Invocation>' -ForEach @(
        @{ Invocation = 'Parent' }
        @{ Invocation = 'Current' }
        @{ Invocation = 'Explicit' }
    ) {
        $projectDir = Join-Path -Path $script:testRoot -ChildPath 'DemoModule'
        New-Item -Path $projectDir -ItemType Directory | Out-Null
        New-Item -Path (Join-Path -Path $projectDir -ChildPath 'LICENSE') -ItemType File | Out-Null

        $answers = @('DemoModule', 'Description', '0.1.0', 'Author', '', '7.6', 'MIT', 'No', 'No', 'No')
        $script:answerIndex = 0

        Mock Read-HostResponse {
            $value = $answers[$script:answerIndex]
            $script:answerIndex++
            $value
        }

        $invokeParameters = @{ Confirm = $false; Path = $script:testRoot }
        if ($Invocation -eq 'Current') {
            Set-Location -Path $projectDir
            $invokeParameters.Remove('Path')
        } elseif ($Invocation -eq 'Explicit') {
            $invokeParameters.Path = $projectDir
        }

        { New-MAModule @invokeParameters } | Should-Throw -ExceptionMessage '*is not empty*'

        Test-Path -Path (Join-Path -Path $projectDir -ChildPath 'LICENSE') | Should-BeTrue
        Test-Path -Path (Join-Path -Path $projectDir -ChildPath 'DemoModule') | Should-BeFalse
        Test-Path -Path (Join-Path -Path $projectDir -ChildPath '.moduleassembler') | Should-BeFalse
    }

    It 'leaves a matching directory unchanged when run with -WhatIf' {
        $projectDir = Join-Path -Path $script:testRoot -ChildPath 'DemoModule'
        New-Item -Path $projectDir -ItemType Directory | Out-Null
        Set-Location -Path $projectDir

        $answers = @('DemoModule', 'Description', '0.1.0', 'Author', '', '7.6', 'MIT', 'No', 'No', 'No')
        $script:answerIndex = 0
        Mock Read-HostResponse {
            $value = $answers[$script:answerIndex]
            $script:answerIndex++
            $value
        }

        New-MAModule -WhatIf

        Test-Path -LiteralPath $projectDir -PathType Container | Should-BeTrue
        @(Get-ChildItem -LiteralPath $projectDir -Force).Count | Should-Be 0
    }

    It 'cleans generated contents from a pre-existing matching directory when scaffolding fails' {
        $projectDir = Join-Path -Path $script:testRoot -ChildPath 'DemoModule'
        New-Item -Path $projectDir -ItemType Directory | Out-Null
        New-Item -Path (Join-Path -Path $projectDir -ChildPath '.git') -ItemType Directory | Out-Null
        Set-Content -Path (Join-Path -Path $projectDir -ChildPath '.git/config') -Value 'Existing git config'
        Set-Content -Path (Join-Path -Path $projectDir -ChildPath 'README.md') -Value 'Existing README'
        Set-Location -Path $projectDir

        $answers = @('DemoModule', 'Description', '0.1.0', 'Author', '', '7.6', 'MIT', 'No', 'No', 'Yes')
        $script:answerIndex = 0
        Mock Read-HostResponse {
            $value = $answers[$script:answerIndex]
            $script:answerIndex++
            $value
        }
        Mock Initialize-GitRepo { throw 'Simulated git failure' }
        Mock Get-Content { 'MIT template <YEAR> <COPYRIGHT HOLDER>' } -ParameterFilter { $Path -like '*LicenseTemplates*' }
        Mock Get-Content { '# Changelog' } -ParameterFilter { $Path -like '*CHANGELOG.md' }

        { New-MAModule -Confirm:$false } | Should-Throw -ExceptionMessage '*Simulated git failure*'

        Test-Path -LiteralPath $projectDir -PathType Container | Should-BeTrue
        [System.IO.File]::ReadAllText((Join-Path -Path $projectDir -ChildPath 'README.md')).Trim() | Should-Be 'Existing README'
        [System.IO.File]::ReadAllText((Join-Path -Path $projectDir -ChildPath '.git/config')).Trim() | Should-Be 'Existing git config'
        Test-Path -LiteralPath (Join-Path -Path $projectDir -ChildPath 'LICENSE') | Should-BeFalse
        Test-Path -LiteralPath (Join-Path -Path $projectDir -ChildPath '.moduleassembler') | Should-BeFalse
        Test-Path -LiteralPath (Join-Path -Path $projectDir -ChildPath 'src') | Should-BeFalse
    }

    It 'removes a newly created subdirectory when scaffolding fails' {
        $answers = @('DemoModule', 'Description', '0.1.0', 'Author', '', '7.6', 'MIT', 'No', 'No', 'Yes')
        $script:answerIndex = 0
        Mock Read-HostResponse {
            $value = $answers[$script:answerIndex]
            $script:answerIndex++
            $value
        }
        Mock Initialize-GitRepo { throw 'Simulated git failure' }
        Mock Get-Content { 'MIT template <YEAR> <COPYRIGHT HOLDER>' } -ParameterFilter { $Path -like '*LicenseTemplates*' }
        Mock Get-Content { '# Changelog' } -ParameterFilter { $Path -like '*CHANGELOG.md' }

        { New-MAModule -Path $script:testRoot -Confirm:$false } | Should-Throw -ExceptionMessage '*Simulated git failure*'

        Test-Path -LiteralPath $script:testRoot -PathType Container | Should-BeTrue
        Test-Path -LiteralPath (Join-Path -Path $script:testRoot -ChildPath 'DemoModule') | Should-BeFalse
    }
}
