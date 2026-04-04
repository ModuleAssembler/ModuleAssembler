function Test-JsonSchema {
    <#
    .SYNOPSIS
        Test JSON against a specified schema.

    .DESCRIPTION
        Validates moduleproject.json against the schema declared in its own $schema key.
        The schema version and local file path are derived automatically from the $schema reference.
        The local schema file must be present; run Update-MASchema to download it if missing.

    .EXAMPLE
        Test-JsonSchema

        Validate moduleproject.json against the schema it declares.
    #>

    [CmdletBinding()]
    param ()

    begin {
        $projectRoot = Get-Location | Convert-Path
        $moduleAssemblerDir = [System.IO.Path]::Combine($projectRoot, '.moduleassembler')
        $projectJson = [System.IO.Path]::Combine($moduleAssemblerDir, 'moduleproject.json')

        if (-not (Test-Path $projectJson)) {
            throw 'Not a Module Assembler project, moduleproject.json not found.'
        }

        # Derive the local schema path from the $schema key in moduleproject.json
        $projectJsonData = Get-Content -Path $projectJson -Raw | ConvertFrom-Json
        $schemaRef = $projectJsonData.'$schema'

        if ([string]::IsNullOrEmpty($schemaRef)) {
            throw 'moduleproject.json does not contain a $schema reference. Run Update-MASchema to add one.'
        }

        # Resolve the path relative to the .moduleassembler directory
        $localSchemaPath = [System.IO.Path]::GetFullPath([System.IO.Path]::Combine($moduleAssemblerDir, $schemaRef))

        # Validate the schema reference follows the expected filename convention
        $schemaFileName = [System.IO.Path]::GetFileName($localSchemaPath)
        if ($schemaFileName -notmatch 'moduleassembler\.(v[\d.]+)\.schema\.json') {
            throw "Cannot determine schema version from schema reference '$schemaRef'."
        }
    }

    process {
        $schemaContent = $null

        if (Test-Path $localSchemaPath) {
            Write-Verbose "Using local schema: $localSchemaPath"
            $schemaContent = Get-Content -Path $localSchemaPath -Raw
        } else {
            throw "Local schema file '$schemaFileName' not found. Run 'Update-MASchema' to download it before building."
        }

        if (-not ($schemaContent | Test-Json -ErrorAction SilentlyContinue)) {
            throw 'Schema content is not valid JSON and cannot be used for validation.'
        }

        Write-Verbose 'Running Schema Validation against moduleproject.json using ModuleAssembler schema.'
        $result = Test-Json -Path $projectJson -Schema $schemaContent -ErrorAction Stop

        Write-Verbose "Is moduleproject.json passing validation: $result"
        return $result
    }
}
