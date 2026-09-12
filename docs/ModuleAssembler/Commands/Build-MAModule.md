# Build-MAModule

## Synopsis

Invokes the process to build a module in ModuleAssembler format.

## Syntax

```powershell
Build-MAModule
    [<CommonParameters>]
```

## Description

Builds the current ModuleAssembler project in the project's dist directory.

Run this command from the module project directory. The build removes any existing
dist output, combines the class, private, and public source files into the module
PSM1 file, creates the module manifest, and copies the project resource files into
the build output according to the project configuration.

## Aliases

MABuild

## Examples

### EXAMPLE 1

```powershell
Build-MAModule
```

Execute a module build.

## Parameters

### \<CommonParameters\>

This cmdlet supports the common parameters: Verbose, Debug, ErrorAction, ErrorVariable, WarningAction, WarningVariable, OutBuffer, PipelineVariable, and OutVariable.

For more information, see [about_CommonParameters](https://learn.microsoft.com/en-us/powershell/module/microsoft.powershell.core/about/about_commonparameters).

## Outputs

### System.Void
