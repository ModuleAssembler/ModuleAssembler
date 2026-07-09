# Update-MAChangelogRelease

## Synopsis

Promotes CHANGELOG.md [Unreleased] content into a versioned release section.

## Syntax

```powershell
Update-MAChangelogRelease
    [[-Version] <string>]
    [[-ReleaseDate] <datetime>]
    [-WhatIf]
    [-Confirm]
    [<CommonParameters>]
```

## Description

Reads CHANGELOG.md from the current module project root, moves the current [Unreleased]
section content into a new versioned section, and recreates a fresh [Unreleased] section.

The target version defaults to the current project version from Get-MAProjectInfo when
-Version is not specified.

## Aliases

MAChangelogRelease

## Examples

### EXAMPLE 1

```powershell
PS > Update-MAChangelogRelease
```

Promotes [Unreleased] content into the current project version using today's date.

### EXAMPLE 2

```powershell
PS > Update-MAChangelogRelease -Version '1.4.0' -ReleaseDate (Get-Date '2026-05-24')
```

Promotes [Unreleased] content into version 1.4.0 with the specified release date.

## Parameters

### -Version

Semantic version label for the new changelog section (for example 1.2.3 or 1.2.3-rc01).
Defaults to the current project version.

| Property | Value |
| --- | --- |
| Type | String |
| Required | false |
| Accept Pipeline Input | false |
| Accept Wildcards | false |
| Position | 1 |

### -ReleaseDate

Release date for the versioned changelog heading. Defaults to today.

| Property | Value |
| --- | --- |
| Type | DateTime |
| Required | false |
| Default Value | (Get-Date) |
| Accept Pipeline Input | false |
| Accept Wildcards | false |
| Position | 2 |

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
