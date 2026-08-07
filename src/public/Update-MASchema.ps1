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

    .PARAMETER ApplyNewSchemaDefaults
        When specified, applies defaults from the active schema to project JSON files.
        For moduleproject.json, only missing properties with schema defaults are added.
        Existing properties are never overwritten. If an existing value differs from the
        schema default, a warning is written and the existing value is preserved.
        When used together with -UpdateSource, ModuleProjectTemplate.json also receives
        missing defaulted properties and any existing defaulted properties are updated to
        match the schema default values.

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

        Downloads the latest ModuleAssembler schema then saves it to .moduleasssembler/schema and src/resources/schemas/.
        Updates the $schema references in moduleproject.json and ModuleProjectTemplate.json.

    .EXAMPLE
        Update-MASchema -ApplyNewSchemaDefaults

        Updates the local $schema reference and adds any missing schema-defaulted properties to moduleproject.json.

    .EXAMPLE
        Update-MASchema -UpdateSource -ApplyNewSchemaDefaults

        Updates local and source schema assets, adds missing defaults in moduleproject.json,
        and synchronizes ModuleProjectTemplate.json defaults with the active schema.
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
        [switch] $UpdateSource,

        [Parameter(Mandatory = $false)]
        [switch] $ApplyNewSchemaDefaults
    )

    begin {
        $projectRoot = Get-Location | Convert-Path
        $schemasDir = [System.IO.Path]::Combine($projectRoot, '.moduleassembler', 'schemas')
        $projectJsonPath = [System.IO.Path]::Combine($projectRoot, '.moduleassembler', 'moduleproject.json')
        $utf8NoBomEncoding = [System.Text.UTF8Encoding]::new($false)

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

                $normalizedSchemaContent = $schemaContent.TrimEnd("`r", "`n") + [System.Environment]::NewLine
                [System.IO.File]::WriteAllText($schemaFilePath, $normalizedSchemaContent, $utf8NoBomEncoding)
                Write-Verbose "Schema saved to: $schemaFilePath"
            }
        }

        $schemaDefaultEntries = @()
        $schemaDefaultEntriesLoaded = $false

        if ($ApplyNewSchemaDefaults.IsPresent) {
            $schemaContentForDefaults = $schemaContent
            if ($null -eq $schemaContentForDefaults) {
                if (Test-Path $schemaFilePath) {
                    $schemaContentForDefaults = Get-Content -Path $schemaFilePath -Raw
                } else {
                    throw "Cannot apply schema defaults because schema file '$schemaFilePath' is not available. Run Update-MASchema with -Force first."
                }
            }

            $schemaRoot = $schemaContentForDefaults | ConvertFrom-Json -AsHashtable
            $schemaTraversalStack = [System.Collections.Generic.Stack[hashtable]]::new()
            $schemaTraversalStack.Push(@{
                    Node = $schemaRoot
                    Path = @()
                })

            while ($schemaTraversalStack.Count -gt 0) {
                $currentSchemaNode = $schemaTraversalStack.Pop()
                $schemaNode = $currentSchemaNode.Node
                $schemaPath = [string[]]$currentSchemaNode.Path

                if (-not ($schemaNode -is [System.Collections.IDictionary])) {
                    continue
                }

                if (-not $schemaNode.Contains('properties')) {
                    continue
                }

                $schemaProperties = $schemaNode['properties']
                if (-not ($schemaProperties -is [System.Collections.IDictionary])) {
                    continue
                }

                foreach ($propertyName in $schemaProperties.Keys) {
                    $propertySchema = $schemaProperties[$propertyName]
                    if (-not ($propertySchema -is [System.Collections.IDictionary])) {
                        continue
                    }

                    $propertyPath = @($schemaPath + $propertyName)
                    if ($propertySchema.Contains('default')) {
                        $schemaDefaultEntries += [PSCustomObject]@{
                            Path         = $propertyPath
                            DefaultValue = $propertySchema['default']
                        }
                    }

                    if ($propertySchema.Contains('properties')) {
                        $schemaTraversalStack.Push(@{
                                Node = $propertySchema
                                Path = $propertyPath
                            })
                    }
                }
            }

            $schemaDefaultEntriesLoaded = $true
            Write-Verbose "Loaded $($schemaDefaultEntries.Count) schema default entries."
        }

        # Update $schema reference in moduleproject.json to point to the local file
        $localSchemaRef = "./schemas/$schemaFileName"
        if ($PSCmdlet.ShouldProcess($projectJsonPath, "Update `$schema reference to '$localSchemaRef'")) {
            $projectJsonObject = Get-Content -Path $projectJsonPath -Raw | ConvertFrom-Json -AsHashtable
            $projectJsonObject['$schema'] = $localSchemaRef

            $projectDefaultsAdded = 0
            $projectNonDefaultPaths = @()

            if ($ApplyNewSchemaDefaults.IsPresent -and $schemaDefaultEntriesLoaded) {
                foreach ($defaultEntry in $schemaDefaultEntries) {
                    $pathSegments = [string[]]$defaultEntry.Path
                    if ($pathSegments.Count -eq 0) {
                        continue
                    }

                    $pathConflict = $false
                    $targetNode = [System.Collections.IDictionary]$projectJsonObject
                    for ($index = 0; $index -lt ($pathSegments.Count - 1); $index++) {
                        $segment = $pathSegments[$index]
                        if ($targetNode.Contains($segment)) {
                            $nextNode = $targetNode[$segment]
                            if (-not ($nextNode -is [System.Collections.IDictionary])) {
                                $pathConflict = $true
                                break
                            }

                            $targetNode = [System.Collections.IDictionary]$nextNode
                        } else {
                            $newNode = @{}
                            $targetNode[$segment] = $newNode
                            $targetNode = [System.Collections.IDictionary]$newNode
                        }
                    }

                    if ($pathConflict) {
                        Write-Verbose ("Skipping schema default path '{0}' because an intermediate value is not an object." -f ($pathSegments -join '.'))
                        continue
                    }

                    $leafKey = $pathSegments[-1]
                    if ($targetNode.Contains($leafKey)) {
                        $existingValue = $targetNode[$leafKey]
                        $existingJson = $existingValue | ConvertTo-Json -Depth 100 -Compress
                        $defaultJson = $defaultEntry.DefaultValue | ConvertTo-Json -Depth 100 -Compress
                        if ($existingJson -ne $defaultJson) {
                            $projectNonDefaultPaths += ($pathSegments -join '.')
                        }
                    } else {
                        $defaultValue = $defaultEntry.DefaultValue
                        if (($defaultValue -is [System.Collections.IDictionary]) -or ($defaultValue -is [System.Collections.IList])) {
                            $defaultValue = $defaultValue | ConvertTo-Json -Depth 100 -Compress | ConvertFrom-Json -AsHashtable
                        }

                        $targetNode[$leafKey] = $defaultValue
                        $projectDefaultsAdded++
                    }
                }

                Write-Verbose "Added $projectDefaultsAdded missing schema default properties to moduleproject.json."
                if ($projectNonDefaultPaths.Count -gt 0) {
                    Write-Warning ("moduleproject.json contains existing values that differ from schema defaults and were left unchanged: {0}" -f ($projectNonDefaultPaths -join ', '))
                }
            }

            $projectJsonJson = $projectJsonObject | ConvertTo-Json -Depth 10
            $normalizedProjectJson = $projectJsonJson.TrimEnd("`r", "`n") + [System.Environment]::NewLine
            [System.IO.File]::WriteAllText($projectJsonPath, $normalizedProjectJson, $utf8NoBomEncoding)
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

                    $normalizedSourceContent = $sourceContent.TrimEnd("`r", "`n") + [System.Environment]::NewLine
                    [System.IO.File]::WriteAllText($resourceSchemaFilePath, $normalizedSourceContent, $utf8NoBomEncoding)
                    Write-Verbose "Schema saved to module resources: $resourceSchemaFilePath"
                }

                if (-not (Test-Path $templatePath)) {
                    Write-Warning "ModuleProjectTemplate.json not found at '$templatePath'. Skipping template update."
                } elseif ($PSCmdlet.ShouldProcess($templatePath, "Update `$schema reference to '$localSchemaRef'")) {
                    $templateJsonObject = Get-Content -Path $templatePath -Raw | ConvertFrom-Json -AsHashtable
                    $templateJsonObject['$schema'] = $localSchemaRef

                    $templateDefaultsAdded = 0
                    $templateDefaultsUpdated = 0
                    if ($ApplyNewSchemaDefaults.IsPresent -and $schemaDefaultEntriesLoaded) {
                        foreach ($defaultEntry in $schemaDefaultEntries) {
                            $pathSegments = [string[]]$defaultEntry.Path
                            if ($pathSegments.Count -eq 0) {
                                continue
                            }

                            $pathConflict = $false
                            $targetNode = [System.Collections.IDictionary]$templateJsonObject
                            for ($index = 0; $index -lt ($pathSegments.Count - 1); $index++) {
                                $segment = $pathSegments[$index]
                                if ($targetNode.Contains($segment)) {
                                    $nextNode = $targetNode[$segment]
                                    if (-not ($nextNode -is [System.Collections.IDictionary])) {
                                        $pathConflict = $true
                                        break
                                    }

                                    $targetNode = [System.Collections.IDictionary]$nextNode
                                } else {
                                    $newNode = @{}
                                    $targetNode[$segment] = $newNode
                                    $targetNode = [System.Collections.IDictionary]$newNode
                                }
                            }

                            if ($pathConflict) {
                                Write-Verbose ("Skipping template default path '{0}' because an intermediate value is not an object." -f ($pathSegments -join '.'))
                                continue
                            }

                            $leafKey = $pathSegments[-1]
                            $defaultValue = $defaultEntry.DefaultValue
                            if (($defaultValue -is [System.Collections.IDictionary]) -or ($defaultValue -is [System.Collections.IList])) {
                                $defaultValue = $defaultValue | ConvertTo-Json -Depth 100 -Compress | ConvertFrom-Json -AsHashtable
                            }

                            if ($targetNode.Contains($leafKey)) {
                                $existingJson = $targetNode[$leafKey] | ConvertTo-Json -Depth 100 -Compress
                                $defaultJson = $defaultValue | ConvertTo-Json -Depth 100 -Compress
                                if ($existingJson -ne $defaultJson) {
                                    $targetNode[$leafKey] = $defaultValue
                                    $templateDefaultsUpdated++
                                }
                            } else {
                                $targetNode[$leafKey] = $defaultValue
                                $templateDefaultsAdded++
                            }
                        }

                        Write-Verbose "Added $templateDefaultsAdded and updated $templateDefaultsUpdated schema default properties in ModuleProjectTemplate.json."
                    }

                    $templateJsonJson = $templateJsonObject | ConvertTo-Json -Depth 10
                    $normalizedTemplateJson = $templateJsonJson.TrimEnd("`r", "`n") + [System.Environment]::NewLine
                    [System.IO.File]::WriteAllText($templatePath, $normalizedTemplateJson, $utf8NoBomEncoding)
                    Write-Verbose "Updated `$schema in ModuleProjectTemplate.json to '$localSchemaRef'."
                }
            }
        }
    }
}
