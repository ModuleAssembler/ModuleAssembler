BeforeAll {
    $script:projectRoot = Split-Path -Path (Split-Path -Path (Split-Path -Path $PSScriptRoot -Parent) -Parent) -Parent
    . (Join-Path -Path $script:projectRoot -ChildPath 'src/private/Invoke-SchemaDownload.ps1')
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

    It 'writes schema and project JSON files with a trailing blank line' {
        $moduleAssemblerDir = Join-Path -Path $script:testRoot -ChildPath '.moduleassembler'
        New-Item -Path $moduleAssemblerDir -ItemType Directory -Force | Out-Null

        $projectJsonPath = Join-Path -Path $moduleAssemblerDir -ChildPath 'moduleproject.json'
        '{"$schema":"./schemas/original.schema.json","ProjectName":"Demo"}' | Set-Content -Path $projectJsonPath -Encoding 'utf8NoBOM'

        Mock Invoke-SchemaDownload { '{"type":"object"}' }

        Update-MASchema -Force -Confirm:$false

        $schemaFilePath = Join-Path -Path $moduleAssemblerDir -ChildPath 'schemas/moduleassembler.v1.0.0.schema.json'
        $schemaContent = Get-Content -Path $schemaFilePath -Raw
        $schemaContent.EndsWith([System.Environment]::NewLine) | Should-BeTrue
        $schemaContent.EndsWith([System.Environment]::NewLine + [System.Environment]::NewLine) | Should-BeFalse

        $projectContent = Get-Content -Path $projectJsonPath -Raw
        $projectContent.EndsWith([System.Environment]::NewLine) | Should-BeTrue
        $projectContent.EndsWith([System.Environment]::NewLine + [System.Environment]::NewLine) | Should-BeFalse
    }

    It 'adds missing schema defaults to moduleproject.json and preserves existing non-default values' {
        $moduleAssemblerDir = Join-Path -Path $script:testRoot -ChildPath '.moduleassembler'
        New-Item -Path $moduleAssemblerDir -ItemType Directory -Force | Out-Null

        $projectJsonPath = Join-Path -Path $moduleAssemblerDir -ChildPath 'moduleproject.json'
        $projectSeed = [ordered]@{
            '$schema'   = './schemas/original.schema.json'
            ProjectName = 'Demo'
            Pester      = [ordered]@{
                Output = [ordered]@{
                    Verbosity = 'Diagnostic'
                }
            }
        }
        $projectSeed | ConvertTo-Json -Depth 10 | Set-Content -Path $projectJsonPath -Encoding 'utf8NoBOM'

        $schemaWithDefaultsObject = [ordered]@{
            type       = 'object'
            properties = [ordered]@{
                Pester = [ordered]@{
                    type       = 'object'
                    properties = [ordered]@{
                        Output = [ordered]@{
                            type       = 'object'
                            properties = [ordered]@{
                                Verbosity = [ordered]@{
                                    type    = 'string'
                                    default = 'Detailed'
                                }
                            }
                        }
                        Should = [ordered]@{
                            type       = 'object'
                            properties = [ordered]@{
                                DisableV5 = [ordered]@{
                                    type    = 'boolean'
                                    default = $true
                                }
                            }
                        }
                    }
                }
            }
        }
        $schemaWithDefaults = $schemaWithDefaultsObject | ConvertTo-Json -Depth 20

        Mock Invoke-SchemaDownload { $schemaWithDefaults }

        $warnings = @()
        Update-MASchema -Force -ApplyNewSchemaDefaults -Confirm:$false -WarningVariable warnings -WarningAction SilentlyContinue

        $updatedProject = Get-Content -Path $projectJsonPath -Raw | ConvertFrom-Json
        $updatedProject.Pester.Should.DisableV5 | Should-BeTrue
        $updatedProject.Pester.Output.Verbosity | Should-Be 'Diagnostic'
        $warningText = $warnings -join [System.Environment]::NewLine
        $warningText.Contains('Pester.Output.Verbosity') | Should-BeTrue
    }

    It 'updates template defaults when used with -UpdateSource and -ApplyNewSchemaDefaults' {
        $moduleAssemblerDir = Join-Path -Path $script:testRoot -ChildPath '.moduleassembler'
        $resourceDir = Join-Path -Path $script:testRoot -ChildPath 'src/resources'
        New-Item -Path $moduleAssemblerDir -ItemType Directory -Force | Out-Null
        New-Item -Path $resourceDir -ItemType Directory -Force | Out-Null

        $projectJsonPath = Join-Path -Path $moduleAssemblerDir -ChildPath 'moduleproject.json'
        $projectSeed = [ordered]@{
            '$schema'   = './schemas/original.schema.json'
            ProjectName = 'Demo'
            Pester      = [ordered]@{
                Output = [ordered]@{
                    Verbosity = 'Normal'
                }
            }
        }
        $projectSeed | ConvertTo-Json -Depth 10 | Set-Content -Path $projectJsonPath -Encoding 'utf8NoBOM'

        $templatePath = Join-Path -Path $resourceDir -ChildPath 'ModuleProjectTemplate.json'
        $templateSeed = [ordered]@{
            '$schema'   = './schemas/original.schema.json'
            ProjectName = ''
            Pester      = [ordered]@{
                Output = [ordered]@{
                    Verbosity = 'Normal'
                }
            }
        }
        $templateSeed | ConvertTo-Json -Depth 10 | Set-Content -Path $templatePath -Encoding 'utf8NoBOM'

        $schemaWithDefaultsObject = [ordered]@{
            type       = 'object'
            properties = [ordered]@{
                Pester = [ordered]@{
                    type       = 'object'
                    properties = [ordered]@{
                        Output = [ordered]@{
                            type       = 'object'
                            properties = [ordered]@{
                                Verbosity = [ordered]@{
                                    type    = 'string'
                                    default = 'Detailed'
                                }
                            }
                        }
                        Should = [ordered]@{
                            type       = 'object'
                            properties = [ordered]@{
                                DisableV5 = [ordered]@{
                                    type    = 'boolean'
                                    default = $true
                                }
                            }
                        }
                    }
                }
            }
        }
        $schemaWithDefaults = $schemaWithDefaultsObject | ConvertTo-Json -Depth 20

        Mock Invoke-SchemaDownload { $schemaWithDefaults }

        Update-MASchema -Force -UpdateSource -ApplyNewSchemaDefaults -Confirm:$false -WarningAction SilentlyContinue

        $updatedTemplate = Get-Content -Path $templatePath -Raw | ConvertFrom-Json
        $updatedTemplate.Pester.Output.Verbosity | Should-Be 'Detailed'
        $updatedTemplate.Pester.Should.DisableV5 | Should-BeTrue

        $updatedProject = Get-Content -Path $projectJsonPath -Raw | ConvertFrom-Json
        $updatedProject.Pester.Output.Verbosity | Should-Be 'Normal'
        $updatedProject.Pester.Should.DisableV5 | Should-BeTrue
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
