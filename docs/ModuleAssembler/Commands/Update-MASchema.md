# Update-MASchema

## Synopsis

Downloads and updates the local ModuleAssembler JSON schema.

## Syntax

```powershell
Update-MASchema
    [[-SchemaVersion] <string>]
    [-Force]
    [-UpdateSource]
    [-ApplyNewSchemaDefaults]
    [-WhatIf]
    [-Confirm]
    [<CommonParameters>]
```

## Description

Downloads the ModuleAssembler JSON schema from the remote source and saves it to the
.moduleassembler/schemas directory of the current project. The local schema is used
by editors for IntelliSense and validation via the $schema key in moduleproject.json.
The $schema reference in moduleproject.json is updated to point to the downloaded file.

## Aliases

MASchema

## Examples

### EXAMPLE 1

```powershell
Update-MASchema
```

Downloads the latest ModuleAssembler schema if the local copy is outdated or missing.

### EXAMPLE 2

```powershell
Update-MASchema -SchemaVersion 'v1.0.0'
```

Downloads a specific version of the ModuleAssembler schema if the local copy is outdated or missing.

### EXAMPLE 3

```powershell
Update-MASchema -Force
```

Downloads and overwrites the local schema regardless of whether it is already current.

### EXAMPLE 4

```powershell
Update-MASchema -UpdateSource
```

Downloads the latest ModuleAssembler schema then saves it to .moduleasssembler/schema and src/resources/schemas/.
Updates the $schema references in moduleproject.json and ModuleProjectTemplate.json.

### EXAMPLE 5

```powershell
Update-MASchema -ApplyNewSchemaDefaults
```

Updates the local $schema reference and adds any missing schema-defaulted properties to moduleproject.json.

### EXAMPLE 6

```powershell
Update-MASchema -UpdateSource -ApplyNewSchemaDefaults
```

Updates local and source schema assets, adds missing defaults in moduleproject.json,
and synchronizes ModuleProjectTemplate.json defaults with the active schema.

## Parameters

### -SchemaVersion

The version of the ModuleAssembler JSON schema to download. Default is the latest version.

| Property | Value |
| --- | --- |
| Type | String |
| Required | false |
| Default Value | v1.0.0 |
| Valid Values | v1.0.0 |
| Accept Pipeline Input | false |
| Accept Wildcards | false |
| Position | 1 |

### -Force

When specified, downloads and overwrites the local schema regardless of whether the
local version is already current.

| Property | Value |
| --- | --- |
| Type | SwitchParameter |
| Required | false |
| Default Value | False |
| Accept Pipeline Input | false |
| Accept Wildcards | false |
| Position | named |

### -UpdateSource

Intended for ModuleAssembler development use only, when updating the bundled resources for a new release.
When specified, saves the schema to src/resources/schemas/ and updates the $schema
reference in ModuleProjectTemplate.json to the local relative path. This ensures new
projects receive a bundled copy of the schema at creation time.

| Property | Value |
| --- | --- |
| Type | SwitchParameter |
| Required | false |
| Default Value | False |
| Accept Pipeline Input | false |
| Accept Wildcards | false |
| Position | named |

### -ApplyNewSchemaDefaults

When specified, applies defaults from the active schema to project JSON files.
For moduleproject.json, only missing properties with schema defaults are added.
Existing properties are never overwritten. If an existing value differs from the
schema default, a warning is written and the existing value is preserved.
When used together with -UpdateSource, ModuleProjectTemplate.json also receives
missing defaulted properties and any existing defaulted properties are updated to
match the schema default values.

| Property | Value |
| --- | --- |
| Type | SwitchParameter |
| Required | false |
| Default Value | False |
| Accept Pipeline Input | false |
| Accept Wildcards | false |
| Position | named |

### -WhatIf

| Property | Value |
| --- | --- |
| Type | SwitchParameter |
| Required | false |
| Alias | wi |
| Accept Pipeline Input | false |
| Accept Wildcards | false |
| Position | named |

### -Confirm

| Property | Value |
| --- | --- |
| Type | SwitchParameter |
| Required | false |
| Alias | cf |
| Accept Pipeline Input | false |
| Accept Wildcards | false |
| Position | named |

### \<CommonParameters\>

This cmdlet supports the common parameters: Verbose, Debug, ErrorAction, ErrorVariable, WarningAction, WarningVariable, OutBuffer, PipelineVariable, and OutVariable.

For more information, see about_CommonParameters [https://go.microsoft.com/fwlink/?LinkID=113216].

## Outputs

### System.Void
