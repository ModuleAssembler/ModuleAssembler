# New-MAModule

## Synopsis

Create module scaffolding along with project.json file to build and manage modules.

## Syntax

```powershell
New-MAModule
    [[-Path] <string>]
    [-WhatIf]
    [-Confirm]
    [<CommonParameters>]
```

## Description

Creates module project folder structure and project.json file. Use this to quickly setup a ModuleAssembler compatible module.

## Aliases

MANew

## Examples

### EXAMPLE 1

```powershell
PS > New-MAModule -Path 'C:\work'
```

Creates module project inside c:\work folder.

### EXAMPLE 2

```powershell
PS > New-MAModule
```

Creates module project in the current folder.

## Parameters

### -Path

Path where module will be created. Provide root folder path, module folder will be created as a subdirectory.

| Property | Value |
| --- | --- |
| Type | String |
| Required | false |
| Default Value | $PWD.Path |
| Accept Pipeline Input | false |
| Accept Wildcards | false |
| Position | 1 |

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
