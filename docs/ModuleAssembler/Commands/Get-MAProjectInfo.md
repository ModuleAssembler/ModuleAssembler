# Get-MAProjectInfo

## Synopsis

Gets metadata and derived paths for the current ModuleAssembler project.

## Syntax

```powershell
Get-MAProjectInfo
    [<CommonParameters>]
```

## Description

Reads the project's .moduleassembler/moduleproject.json file and returns its module metadata
together with commonly used project, source, resource, build output, module, manifest, and module file paths.

Run this command from the module project directory.
The command does not search parent directories for a project configuration file and throws an error if
.moduleassembler/moduleproject.json is not found.

The returned object has the custom type name MAProjectInfo and can be used by
ModuleAssembler commands, Pester tests, and project configuration scripts.

## Aliases

MAInfo

## Examples

### EXAMPLE 1

```powershell
Get-MAProjectInfo
```

Returns metadata and derived paths for the current ModuleAssembler project.

## Parameters

### \<CommonParameters\>

This cmdlet supports the common parameters: Verbose, Debug, ErrorAction, ErrorVariable, WarningAction, WarningVariable, OutBuffer, PipelineVariable, and OutVariable.

For more information, see [about_CommonParameters](https://learn.microsoft.com/en-us/powershell/module/microsoft.powershell.core/about/about_commonparameters).

## Outputs

### System.Management.Automation.PSCustomObject

A PSCustomObject with the custom type name MAProjectInfo containing the project metadata and derived paths.
