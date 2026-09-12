# Test-MAModule

## Synopsis

Runs Pester tests using settings from project.json file.

## Syntax

```powershell
Test-MAModule
    [-TagFilter <string[]>]
    [-ExcludeTagFilter <string[]>]
    [<CommonParameters>]
```

## Description

Runs the Pester tests for the current ModuleAssembler project.

Run this command from the module project directory. Tests are discovered from the
project's "tests" directory, and the Pester configuration is loaded from the
"Pester" section of ".moduleassembler/moduleproject.json".

Test results and code coverage reports are written to the project's "dist"
directory. The command throws an error if the project configuration is invalid
or if one or more tests fail.

## Aliases

MATest

## Examples

### EXAMPLE 1

```powershell
Test-MAModule
```

Execute all Pester tests.

### EXAMPLE 2

```powershell
Test-MAModule -TagFilter 'unit','FunctionQA'
```

Execute only Pester tests with the tags unit or FunctionQA.

### EXAMPLE 3

```powershell
Test-MAModule -ExcludeTagFilter 'unit'
```

Runs the Pester tests, excludes any test with tag unit.

## Parameters

### -TagFilter

One or more Pester tags. Only tests with at least one matching tag are run.
If omitted, all tests are eligible to run unless excluded with ExcludeTagFilter.

| Property | Value |
| --- | --- |
| Type | String[] |
| Required | false |
| Accept Pipeline Input | false |
| Accept Wildcards | false |
| Position | named |

### -ExcludeTagFilter

One or more Pester tags. Tests with any matching tag are excluded.
Exclusions are applied together with TagFilter when both parameters are specified.

| Property | Value |
| --- | --- |
| Type | String[] |
| Required | false |
| Accept Pipeline Input | false |
| Accept Wildcards | false |
| Position | named |

### \<CommonParameters\>

This cmdlet supports the common parameters: Verbose, Debug, ErrorAction, ErrorVariable, WarningAction, WarningVariable, OutBuffer, PipelineVariable, and OutVariable.

For more information, see [about_CommonParameters](https://learn.microsoft.com/en-us/powershell/module/microsoft.powershell.core/about/about_commonparameters).

## Outputs

### System.Void
