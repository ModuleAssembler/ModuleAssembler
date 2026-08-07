BeforeAll {
    $script:projectRoot = Split-Path -Path (Split-Path -Path (Split-Path -Path $PSScriptRoot -Parent) -Parent) -Parent
    . (Join-Path -Path $script:projectRoot -ChildPath 'src/private/Test-JsonSchema.ps1')

    $script:schemaFile = Get-ChildItem -Path (Join-Path -Path $script:projectRoot -ChildPath 'src/resources/schemas') -Filter 'moduleassembler.v*.schema.json' -ErrorAction SilentlyContinue | Select-Object -First 1
    $script:schemaFileName = $script:schemaFile.Name
}

Describe 'Test-JsonSchema' -Tag 'Unit' {
    BeforeEach {
        $script:originalLocation = Get-Location
        $script:testRoot = Join-Path -Path ([System.IO.Path]::GetTempPath()) -ChildPath ([System.Guid]::NewGuid().ToString('N'))
        $script:moduleAssemblerDir = Join-Path -Path $script:testRoot -ChildPath '.moduleassembler'
        $script:schemasDir = Join-Path -Path $script:moduleAssemblerDir -ChildPath 'schemas'

        New-Item -Path $script:schemasDir -ItemType Directory -Force | Out-Null
        Set-Location -Path $script:testRoot
    }

    AfterEach {
        Set-Location -Path $script:originalLocation
        if (Test-Path -Path $script:testRoot) {
            Remove-Item -Path $script:testRoot -Recurse -Force
        }
    }

    It 'src/resources/schemas contains a versioned moduleassembler schema file' {
        $script:schemaFile | Should-NotBeNull
    }

    It 'throws when moduleproject.json is missing' {
        Remove-Item -Path (Join-Path -Path $script:moduleAssemblerDir -ChildPath 'moduleproject.json') -ErrorAction SilentlyContinue

        { Test-JsonSchema } | Should-Throw -ExceptionMessage '*moduleproject.json not found*'
    }

    It 'throws when $schema is missing from moduleproject.json' {
        '{"ProjectName":"DemoModule"}' | Set-Content -Path (Join-Path -Path $script:moduleAssemblerDir -ChildPath 'moduleproject.json') -Encoding 'utf8NoBOM'

        { Test-JsonSchema } | Should-Throw -ExceptionMessage '*does not contain a $schema reference*'
    }

    It 'throws when schema file name does not match expected version naming' {
        '{"$schema":"./schemas/custom.schema.json","ProjectName":"DemoModule"}' | Set-Content -Path (Join-Path -Path $script:moduleAssemblerDir -ChildPath 'moduleproject.json') -Encoding 'utf8NoBOM'

        { Test-JsonSchema } | Should-Throw -ExceptionMessage '*Cannot determine schema version*'
    }

    It 'returns true for a valid project json and matching local schema' {
        $projectJsonPath = Join-Path -Path $script:moduleAssemblerDir -ChildPath 'moduleproject.json'
        $schemaPath = Join-Path -Path $script:schemasDir -ChildPath $script:schemaFileName

        @"
{
  "`$schema": "./schemas/$script:schemaFileName",
  "ProjectName": "DemoModule"
}
"@ | Set-Content -Path $projectJsonPath -Encoding 'utf8NoBOM'

        @'
{
  "type": "object",
  "properties": {
    "$schema": { "type": "string" },
    "ProjectName": { "type": "string" }
  },
  "required": ["$schema", "ProjectName"]
}
'@ | Set-Content -Path $schemaPath -Encoding 'utf8NoBOM'

        Test-JsonSchema | Should-BeTrue
    }
}
