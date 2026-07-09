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

This function runs Pester tests using the specified configuration and settings in project.json.
Place all module tests in "tests" folder.

## Aliases

MATest

## Examples

### EXAMPLE 1

```powershell
PS > Test-MAModule
```

Execute all Pester tests.

### EXAMPLE 2

```powershell
PS > Test-MAModule -TagFilter 'unit','FunctionQA'
```

Execute only Pester tests with the tags unit or FunctionQA.

### EXAMPLE 3

```powershell
PS > Test-MAModule -ExcludeTagFilter 'unit'
```

Runs the Pester tests, excludes any test with tag unit.

## Parameters

### -TagFilter

Array of Pester tags to run.

| Property | Value |
| --- | --- |
| Type | String[] |
| Required | false |
| Accept Pipeline Input | false |
| Accept Wildcards | false |
| Position | named |

### -ExcludeTagFilter

Array of Pester tags to exclude.

| Property | Value |
| --- | --- |
| Type | String[] |
| Required | false |
| Accept Pipeline Input | false |
| Accept Wildcards | false |
| Position | named |

### \<CommonParameters\>

This cmdlet supports the common parameters: Verbose, Debug, ErrorAction, ErrorVariable, WarningAction, WarningVariable, OutBuffer, PipelineVariable, and OutVariable.

For more information, see about_CommonParameters [https://go.microsoft.com/fwlink/?LinkID=113216].

## Outputs

### System.Void
