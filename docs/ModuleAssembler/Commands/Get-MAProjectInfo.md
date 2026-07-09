# Get-MAProjectInfo

## Synopsis

Retrieves information about a project by reading data from project.json file in the project folder.

## Syntax

```powershell
Get-MAProjectInfo
    [<CommonParameters>]
```

## Description

Retrieves information about a project by reading data from project.json file located in the root directory.
Ensure you navigate to a module directory which has project.json in root directory.
Most variables are already defined in output of this command which can be used in pester tests and other configs.

## Aliases

MAInfo

## Examples

### EXAMPLE 1

```powershell
PS > Get-MAProjectInfo
```

Get a hashtable output of all module project metadata.

## Parameters

### \<CommonParameters\>

This cmdlet supports the common parameters: Verbose, Debug, ErrorAction, ErrorVariable, WarningAction, WarningVariable, OutBuffer, PipelineVariable, and OutVariable.

For more information, see about_CommonParameters [https://go.microsoft.com/fwlink/?LinkID=113216].

## Outputs

### System.Management.Automation.PSCustomObject

A PSCustomObject with the custom type name MAProjectInfo containing the module project metadata.
