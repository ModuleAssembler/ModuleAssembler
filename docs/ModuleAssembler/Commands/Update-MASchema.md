# Update-MASchema

## Synopsis

Downloads and updates the local ModuleAssembler JSON schema.

## Syntax

```powershell
Update-MASchema
    [[-SchemaVersion] <string>]
    [-Force]
    [-UpdateSource]
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
PS > Update-MASchema
```

Downloads the latest ModuleAssembler schema if the local copy is outdated or missing.

### EXAMPLE 2

```powershell
PS > Update-MASchema -SchemaVersion 'v1.0.0'
```

Downloads a specific version of the ModuleAssembler schema if the local copy is outdated or missing.

### EXAMPLE 3

```powershell
PS > Update-MASchema -Force
```

Downloads and overwrites the local schema regardless of whether it is already current.

### EXAMPLE 4

```powershell
PS > Update-MASchema -UpdateSource
```

Downloads the latest ModuleAssembler schema then saves it to .moduleasssembler/schema and src/resources/schemas/.
Updates the $schema references in moduleproject.json and ModuleProjectTemplate.json.

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
