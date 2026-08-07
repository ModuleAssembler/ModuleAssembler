BeforeAll {
    $script:projectRoot = Split-Path -Path (Split-Path -Path (Split-Path -Path $PSScriptRoot -Parent) -Parent) -Parent
    . (Join-Path -Path $script:projectRoot -ChildPath 'src/public/Update-MASchema.ps1')
}

Describe 'Update-MASchema' -Tag 'Unit' {
    BeforeEach {
        $script:originalLocation = Get-Location
        $script:testRoot = Join-Path -Path ([System.IO.Path]::GetTempPath()) -ChildPath ([System.Guid]::NewGuid().ToString('N'))
        New-Item -Path $script:testRoot -ItemType Directory -Force | Out-Null
        Set-Location -Path $script:testRoot
    }

    AfterEach {
        Set-Location -Path $script:originalLocation
        if (Test-Path -Path $script:testRoot) {
            Remove-Item -Path $script:testRoot -Recurse -Force
        }
    }

    It 'throws when moduleproject.json is not present' {
        { Update-MASchema -Confirm:$false } | Should-Throw -ExceptionMessage '*moduleproject.json not found*'
    }

    It 'downloads schema and updates project schema reference when missing' {
        $moduleAssemblerDir = Join-Path -Path $script:testRoot -ChildPath '.moduleassembler'
        New-Item -Path $moduleAssemblerDir -ItemType Directory -Force | Out-Null

        $projectJsonPath = Join-Path -Path $moduleAssemblerDir -ChildPath 'moduleproject.json'
        '{"$schema":"./schemas/old.schema.json","ProjectName":"Demo"}' | Set-Content -Path $projectJsonPath -Encoding 'utf8NoBOM'

        Mock Invoke-SchemaDownload { '{"type":"object"}' }

        Update-MASchema -SchemaVersion 'v1.0.0' -Confirm:$false

        $schemaFilePath = Join-Path -Path $moduleAssemblerDir -ChildPath 'schemas/moduleassembler.v1.0.0.schema.json'
        (Test-Path -Path $schemaFilePath) | Should-BeTrue

        $updatedProject = Get-Content -Path $projectJsonPath -Raw | ConvertFrom-Json
        $updatedProject.'$schema' | Should-Be './schemas/moduleassembler.v1.0.0.schema.json'
    }

    It 'does not write schema files or update project JSON when run with -WhatIf' {
        $moduleAssemblerDir = Join-Path -Path $script:testRoot -ChildPath '.moduleassembler'
        New-Item -Path $moduleAssemblerDir -ItemType Directory -Force | Out-Null

        $projectJsonPath = Join-Path -Path $moduleAssemblerDir -ChildPath 'moduleproject.json'
        '{"$schema":"./schemas/original.schema.json","ProjectName":"Demo"}' | Set-Content -Path $projectJsonPath -Encoding 'utf8NoBOM'

        Mock Invoke-SchemaDownload { '{"type":"object"}' }

        Update-MASchema -Force -WhatIf

        $schemaFilePath = Join-Path -Path $moduleAssemblerDir -ChildPath 'schemas/moduleassembler.v1.0.0.schema.json'
        (Test-Path -Path $schemaFilePath) | Should-BeFalse

        $after = Get-Content -Path $projectJsonPath -Raw | ConvertFrom-Json
        $after.'$schema' | Should-Be './schemas/original.schema.json'
    }
}
