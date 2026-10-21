BeforeAll {
    $script:projectRoot = Split-Path -Path (Split-Path -Path (Split-Path -Path $PSScriptRoot -Parent) -Parent) -Parent
    . (Join-Path -Path $script:projectRoot -ChildPath 'src/public/Export-MAModuleQABundle.ps1')
    $script:qaSourceDirectory = Join-Path -Path $script:projectRoot -ChildPath 'src/resources/PesterTests/QualityAssurance'
}

Describe 'Export-MAModuleQABundle' -Tag 'Unit' {
    BeforeEach {
        $script:targetProject = Join-Path -Path $TestDrive -ChildPath 'DemoModule'
        if (Test-Path -LiteralPath $script:targetProject) {
            Remove-Item -LiteralPath $script:targetProject -Recurse -Force
        }
        New-Item -Path (Join-Path -Path $script:targetProject -ChildPath '.moduleassembler') -ItemType Directory -Force | Out-Null
        Set-Content -Path (Join-Path -Path $script:targetProject -ChildPath '.moduleassembler/moduleproject.json') -Value '{}'
    }

    It 'exports the bundled QA suite into the project' {
        Export-MAModuleQABundle -Path $script:targetProject

        $sourceFiles = @(Get-ChildItem -LiteralPath $script:qaSourceDirectory -Filter '*.Tests.ps1' -File)
        $destinationDirectory = Join-Path -Path $script:targetProject -ChildPath 'tests/QualityAssurance'
        $destinationFiles = @(Get-ChildItem -LiteralPath $destinationDirectory -Filter '*.Tests.ps1' -File)
        $destinationFiles.Name | Should-BeCollection -Expected $sourceFiles.Name

        foreach ($sourceFile in $sourceFiles) {
            $destinationPath = Join-Path -Path $destinationDirectory -ChildPath $sourceFile.Name
            [System.IO.File]::ReadAllText($destinationPath) | Should-Be ([System.IO.File]::ReadAllText($sourceFile.FullName))
        }
    }

    It 'preserves an existing local test file unless Force is specified' {
        $destinationPath = Join-Path -Path $script:targetProject -ChildPath 'tests/QualityAssurance/QA.Tests.ps1'
        New-Item -Path (Split-Path -Path $destinationPath -Parent) -ItemType Directory -Force | Out-Null
        Set-Content -Path $destinationPath -Value 'custom QA'

        { Export-MAModuleQABundle -Path $script:targetProject } | Should-Throw -ExceptionMessage '*Use -Force to replace them*'
        Get-Content -Path $destinationPath -Raw | Should-Be ('custom QA' + [System.Environment]::NewLine)
        Test-Path -LiteralPath (Join-Path -Path $script:targetProject -ChildPath 'tests/QualityAssurance/ProjectCompliance.Tests.ps1') | Should-BeFalse
    }

    It 'replaces an existing local test file with Force' {
        $destinationPath = Join-Path -Path $script:targetProject -ChildPath 'tests/QualityAssurance/QA.Tests.ps1'
        New-Item -Path (Split-Path -Path $destinationPath -Parent) -ItemType Directory -Force | Out-Null
        Set-Content -Path $destinationPath -Value 'custom QA'

        Export-MAModuleQABundle -Path $script:targetProject -Force

        [System.IO.File]::ReadAllText($destinationPath) | Should-Be ([System.IO.File]::ReadAllText((Join-Path -Path $script:qaSourceDirectory -ChildPath 'QA.Tests.ps1')))
        [System.IO.File]::ReadAllText(
            (Join-Path -Path $script:targetProject -ChildPath 'tests/QualityAssurance/ProjectCompliance.Tests.ps1')
        ) | Should-Be ([System.IO.File]::ReadAllText((Join-Path -Path $script:qaSourceDirectory -ChildPath 'ProjectCompliance.Tests.ps1')))
    }

    It 'honors WhatIf when exporting a new file' {
        Export-MAModuleQABundle -Path $script:targetProject -WhatIf

        Test-Path -LiteralPath (Join-Path -Path $script:targetProject -ChildPath 'tests/QualityAssurance') | Should-BeFalse
    }

    It 'honors WhatIf when replacing an existing file' {
        $destinationPath = Join-Path -Path $script:targetProject -ChildPath 'tests/QualityAssurance/QA.Tests.ps1'
        New-Item -Path (Split-Path -Path $destinationPath -Parent) -ItemType Directory -Force | Out-Null
        Set-Content -Path $destinationPath -Value 'custom QA'

        Export-MAModuleQABundle -Path $script:targetProject -Force -WhatIf

        Get-Content -Path $destinationPath -Raw | Should-Be ('custom QA' + [System.Environment]::NewLine)
        Test-Path -LiteralPath (Join-Path -Path $script:targetProject -ChildPath 'tests/QualityAssurance/ProjectCompliance.Tests.ps1') | Should-BeFalse
    }

    It 'throws when the target is not a ModuleAssembler project' {
        { Export-MAModuleQABundle -Path $TestDrive } | Should-Throw -ExceptionMessage '*moduleproject.json was not found*'
    }
}
