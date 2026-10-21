# Export-MAModuleQABundle

## Synopsis

Export the bundled ModuleAssembler QA tests to a project.

## Syntax

```powershell
Export-MAModuleQABundle
    [[-Path] <string>]
    [-Force]
    [-WhatIf]
    [-Confirm]
    [<CommonParameters>]
```

## Description

Copies all current ModuleAssembler Quality Assurance (QA) test files to tests/QualityAssurance in a
ModuleAssembler project. Existing files are preserved unless -Force is specified.

## Examples

### EXAMPLE 1

```powershell
Export-MAModuleQABundle
```

Exports the bundled QA tests to the current project.

### EXAMPLE 2

```powershell
Export-MAModuleQABundle -Path 'C:\Work\DemoModule' -Force
```

Replaces the local bundled QA tests in the specified project.

## Parameters

### -Path

Path to the root of an existing ModuleAssembler project.

| Property | Value |
| --- | --- |
| Type | String |
| Required | false |
| Default Value | $PWD.Path |
| Accept Pipeline Input | false |
| Accept Wildcards | false |
| Position | 1 |

### -Force

Replace any bundled QA test file that already exists locally.

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

For more information, see [about_CommonParameters](https://learn.microsoft.com/en-us/powershell/module/microsoft.powershell.core/about/about_commonparameters).

## Outputs

### System.Void
