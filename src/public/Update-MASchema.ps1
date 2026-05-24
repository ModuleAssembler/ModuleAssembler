function Update-MASchema {
    <#
    .SYNOPSIS
        Downloads and updates the local ModuleAssembler JSON schema.

    .DESCRIPTION
        Downloads the ModuleAssembler JSON schema from the remote source and saves it to the
        .moduleassembler/schemas directory of the current project. The local schema is used
        by editors for IntelliSense and validation via the $schema key in moduleproject.json.
        The $schema reference in moduleproject.json is updated to point to the downloaded file.

    .PARAMETER SchemaVersion
        The version of the ModuleAssembler JSON schema to download. Default is the latest version.

    .PARAMETER Force
        When specified, downloads and overwrites the local schema regardless of whether the
        local version is already current.

    .PARAMETER UpdateSource
        Intended for ModuleAssembler development use only, when updating the bundled resources for a new release.
        When specified, saves the schema to src/resources/schemas/ and updates the $schema
        reference in ModuleProjectTemplate.json to the local relative path. This ensures new
        projects receive a bundled copy of the schema at creation time.

    .EXAMPLE
        Update-MASchema

        Downloads the latest ModuleAssembler schema if the local copy is outdated or missing.

    .EXAMPLE
        Update-MASchema -SchemaVersion 'v1.0.0'

        Downloads a specific version of the ModuleAssembler schema if the local copy is outdated or missing.

    .EXAMPLE
        Update-MASchema -Force

        Downloads and overwrites the local schema regardless of whether it is already current.

    .EXAMPLE
        Update-MASchema -UpdateSource

        Downloads the latest ModuleAssembler schema, saves it locally, saves it
        to src/resources/schemas/, and updates the $schema references in moduleproject.json and ModuleProjectTemplate.json.
    #>

    [CmdletBinding(SupportsShouldProcess)]
    [OutputType([void])]
    [Alias('MASchema')]
    param (
        [Parameter(
            Mandatory = $false,
            Position = 0)]
        [ValidateSet('v1.0.0')]
        [string] $SchemaVersion = 'v1.0.0',

        [Parameter(Mandatory = $false)]
        [switch] $Force,

        [Parameter(Mandatory = $false)]
        [switch] $UpdateSource
    )

    begin {
        $projectRoot = Get-Location | Convert-Path
        $schemasDir = [System.IO.Path]::Combine($projectRoot, '.moduleassembler', 'schemas')
        $projectJsonPath = [System.IO.Path]::Combine($projectRoot, '.moduleassembler', 'moduleproject.json')

        if (-not (Test-Path $projectJsonPath)) {
            throw 'Not a Module Assembler project, moduleproject.json not found.'
        }

        $schemaFileName = "moduleassembler.$SchemaVersion.schema.json"
        $schemaFilePath = [System.IO.Path]::Combine($schemasDir, $schemaFileName)
    }

    process {
        # Determine if a download is needed by comparing local and requested versions
        $requestedVersion = [System.Version]($SchemaVersion -replace '^v', '')
        $needsDownload = $Force.IsPresent

        if (-not $needsDownload) {
            $existingFiles = Get-ChildItem -Path $schemasDir -Filter 'moduleassembler.*.schema.json' -ErrorAction SilentlyContinue
            if ($existingFiles) {
                $highestLocal = $existingFiles | ForEach-Object {
                    if ($_.Name -match 'moduleassembler\.(v[\d.]+)\.schema\.json') {
                        [System.Version]($Matches[1] -replace '^v', '')
                    }
                } | Sort-Object -Descending | Select-Object -First 1

                if ($null -ne $highestLocal -and $highestLocal -ge $requestedVersion) {
                    Write-Verbose "Local schema version ($SchemaVersion) is already current. Use -Force to overwrite."
                } else {
                    Write-Verbose "Local schema version ($highestLocal) is older than requested ($requestedVersion). Updating."
                    $needsDownload = $true
                }
            } else {
                Write-Verbose "No local schema found. Downloading schema $SchemaVersion."
                $needsDownload = $true
            }
        } else {
            Write-Verbose "Force specified. Downloading schema $SchemaVersion regardless of local version."
        }

        $schemaContent = $null

        if ($needsDownload) {
            Write-Verbose "Fetching ModuleAssembler schema $SchemaVersion from remote."
            $schemaContent = Invoke-SchemaDownload -SchemaVersion $SchemaVersion

            if (-not ($schemaContent | Test-Json -ErrorAction SilentlyContinue)) {
                throw "Downloaded content for schema '$SchemaVersion' is not valid JSON and cannot be saved as a schema."
            }

            if ($PSCmdlet.ShouldProcess($schemaFilePath, "Save schema $SchemaVersion")) {
                if (-not (Test-Path $schemasDir)) {
                    $null = New-Item -ItemType Directory -Path $schemasDir -Force
                    Write-Verbose "Created schemas directory: $schemasDir"
                }

                Set-Content -Path $schemaFilePath -Value $schemaContent -Encoding utf8NoBOM -Force
                Write-Verbose "Schema saved to: $schemaFilePath"
            }
        }

        # Update $schema reference in moduleproject.json to point to the local file
        $localSchemaRef = "./schemas/$schemaFileName"
        if ($PSCmdlet.ShouldProcess($projectJsonPath, "Update `$schema reference to '$localSchemaRef'")) {
            $projectJsonObject = Get-Content -Path $projectJsonPath -Raw | ConvertFrom-Json
            $projectJsonObject.'$schema' = $localSchemaRef
            $projectJsonObject | ConvertTo-Json -Depth 10 | Set-Content -Path $projectJsonPath -Encoding utf8NoBOM -NoNewline
            Write-Verbose "Updated `$schema in moduleproject.json to '$localSchemaRef'."
        }

        # Optionally update module source resources for a new release
        if ($UpdateSource) {
            $resourceSchemasDir = [System.IO.Path]::Combine($projectRoot, 'src', 'resources', 'schemas')
            $resourceSchemaFilePath = [System.IO.Path]::Combine($resourceSchemasDir, $schemaFileName)
            $templatePath = [System.IO.Path]::Combine($projectRoot, 'src', 'resources', 'ModuleProjectTemplate.json')

            # Use already-downloaded content or fall back to the local project schema file
            $sourceContent = if ($null -ne $schemaContent) {
                $schemaContent
            } elseif (Test-Path $schemaFilePath) {
                Get-Content -Path $schemaFilePath -Raw
            } else {
                $null
            }

            if ($null -eq $sourceContent) {
                Write-Warning 'No schema content available for resource update. Run Update-MASchema without -UpdateSource first, or use -Force.'
            } else {
                if ($PSCmdlet.ShouldProcess($resourceSchemaFilePath, "Save schema $SchemaVersion to module resources")) {
                    if (-not (Test-Path $resourceSchemasDir)) {
                        $null = New-Item -ItemType Directory -Path $resourceSchemasDir -Force
                        Write-Verbose "Created resource schemas directory: $resourceSchemasDir"
                    }

                    Set-Content -Path $resourceSchemaFilePath -Value $sourceContent -Encoding utf8NoBOM -Force
                    Write-Verbose "Schema saved to module resources: $resourceSchemaFilePath"
                }

                if (-not (Test-Path $templatePath)) {
                    Write-Warning "ModuleProjectTemplate.json not found at '$templatePath'. Skipping template update."
                } elseif ($PSCmdlet.ShouldProcess($templatePath, "Update `$schema reference to '$localSchemaRef'")) {
                    $templateJsonObject = Get-Content -Path $templatePath -Raw | ConvertFrom-Json
                    $templateJsonObject.'$schema' = $localSchemaRef
                    $templateJsonObject | ConvertTo-Json -Depth 10 | Set-Content -Path $templatePath -Encoding utf8NoBOM -NoNewline
                    Write-Verbose "Updated `$schema in ModuleProjectTemplate.json to '$localSchemaRef'."
                }
            }
        }
    }
}
