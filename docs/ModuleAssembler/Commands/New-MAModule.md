# New-MAModule

## Synopsis

Create module scaffolding along with moduleproject.json file to build and manage a module.

## Syntax

```powershell
New-MAModule
    [[-Path] <string>]
    [-WhatIf]
    [-Confirm]
    [<CommonParameters>]
```

## Description

Creates a ModuleAssembler compatible project directory structure.

The module directory is created as a subdirectory of the specified Path using the module name.
When Path is omitted, the current working directory is used as the parent directory.
For example, running New-MAModule from 'C:\Temp' and entering 'MyModule' creates the project in 'C:\Temp\MyModule'.

## Aliases

MANew

## Examples

### EXAMPLE 1

```powershell
New-MAModule -Path 'C:\work'
```

Creates module project inside c:\work directory.

### EXAMPLE 2

```powershell
New-MAModule
```

Creates the module project directory in the current working directory.

## Parameters

### -Path

Parent directory where the module directory will be created. If omitted, the current working directory is used.

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

For more information, see [about_CommonParameters](https://learn.microsoft.com/en-us/powershell/module/microsoft.powershell.core/about/about_commonparameters).

## Outputs

### System.Void
