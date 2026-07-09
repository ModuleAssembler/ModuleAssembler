# Update-MAModuleVersion

## Synopsis

Updates the version number of a module in moduleproject.json file. Uses [semver] object type.

## Syntax

```powershell
Update-MAModuleVersion
    [[-Label] <string>]
    [[-PreReleaseType] <string>]
    [-WhatIf]
    [-Confirm]
    [<CommonParameters>]
```

## Description

This function updates the version number of the PowerShell module by modifying the moduleproject.json file, which gets written into module manifest file (.psd1). [semver] is supported only for PowerShell 7 and above.
It increments the version number based on the specified version part (Major, Minor, Patch). Allows for pre-release labels of (alpha, beta, preview, rc).

## Aliases

MAVersion

## Examples

### EXAMPLE 1

```powershell
PS > Update-MAModuleVersion -Label Major
```

Updates the Major version part of the module. Version 2.1.3 will become 3.0.0.

### EXAMPLE 2

```powershell
PS > Update-MAModuleVersion -Label Minor
```

Updates the Minor version part of the module. Version 2.1.3 will become 2.2.0.

### EXAMPLE 3

```powershell
PS > Update-MAModuleVersion -Label Patch
```

Updates the Patch version part of the module. Version 2.1.3 will become 2.1.4.

### EXAMPLE 4

```powershell
PS > Update-MAModuleVersion
```

Updates the Patch version part of the module. Version 2.1.3 will become 2.1.4.

### EXAMPLE 5

```powershell
PS > Update-MAModuleVersion -PreReleaseType preview
```

Adds a specified PreReleaseLabel to the module version. Version 1.0.0 will become 1.0.0-preview01.
If the same PreReleaseType was previously used, it will increment the number. Version 1.0.0-preview01 will become 1.0.0-preview02.

### EXAMPLE 6

```powershell
PS > Update-MAModuleVersion -Label Major -PreReleaseType rc
```

Sets a new version and specify it as a PreRelease. Version 0.1.0 will become 1.0.0-rc01.

## Parameters

### -Label

The part of the version number to increment (Major, Minor, Patch). Default is Patch.

| Property | Value |
| --- | --- |
| Type | String |
| Required | false |
| Valid Values | Major, Minor, Patch |
| Accept Pipeline Input | false |
| Accept Wildcards | false |
| Position | 1 |

### -PreReleaseType

Specify the prerelease type to use (alpha, beta, preview, rc).
If executed again with no Label and the same PrereleaseType type, the prerelease number will increment.

| Property | Value |
| --- | --- |
| Type | String |
| Required | false |
| Valid Values | alpha, beta, preview, rc |
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

## Notes

Ensure you are in the project directory when running this command.
