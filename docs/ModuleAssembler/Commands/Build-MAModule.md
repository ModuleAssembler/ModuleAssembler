# Build-MAModule

## Synopsis

Invokes the process to build a module in ModuleAssembler format.

## Syntax

```powershell
Build-MAModule
    [<CommonParameters>]
```

## Description

Invokes the process to build by cleaning up the dist folder, building the module, and copying all necessary resource files.

## Aliases

MABuild

## Examples

### EXAMPLE 1

```powershell
PS > Build-MAModule
```

Execute a module build.

## Parameters

### \<CommonParameters\>

This cmdlet supports the common parameters: Verbose, Debug, ErrorAction, ErrorVariable, WarningAction, WarningVariable, OutBuffer, PipelineVariable, and OutVariable.

For more information, see about_CommonParameters [https://go.microsoft.com/fwlink/?LinkID=113216].

## Outputs

### System.Void
