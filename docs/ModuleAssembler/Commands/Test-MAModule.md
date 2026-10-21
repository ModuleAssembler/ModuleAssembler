# Test-MAModule

## Synopsis

Runs project tests and the bundled ModuleAssembler QA suite.

## Syntax

```powershell
Test-MAModule
    [-TagFilter <string[]>]
    [-ExcludeTagFilter <string[]>]
    [-SkipBundledQA]
    [<CommonParameters>]
```

## Description

Runs project tests from the project's "tests" directory and the QA suite bundled
with ModuleAssembler. The Pester configuration is loaded from the "Pester" section
of ".moduleassembler/moduleproject.json".

Run this command from the module project directory. Tests are discovered from the
project's "tests" directory. The bundled QA suite is run separately unless an
identical local copy is already present.

TagFilter and ExcludeTagFilter apply to both project tests and bundled QA tests.

The bundled QA tests use the following tags:

- FunctionQA: Checks source syntax, ScriptAnalyzer results, comment-based help, and function-to-file naming.
- ModuleQA: Checks built module files, manifest metadata, exports, and module import and removal.
- ChangeLog: Checks the changelog file and its structure and release references.
- License: Checks that the license file is present, non-empty, and a recognized supported license.

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

### EXAMPLE 4

```powershell
Test-MAModule -SkipBundledQA
```

Runs project tests without the ModuleAssembler bundled QA suite.

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

### -SkipBundledQA

Skip the ModuleAssembler QA suite bundled with the installed module. Project tests,
including an exported local QA suite, continue to run.

| Property | Value |
| --- | --- |
| Type | SwitchParameter |
| Required | false |
| Default Value | False |
| Accept Pipeline Input | false |
| Accept Wildcards | false |
| Position | named |

### \<CommonParameters\>

This cmdlet supports the common parameters: Verbose, Debug, ErrorAction, ErrorVariable, WarningAction, WarningVariable, OutBuffer, PipelineVariable, and OutVariable.

For more information, see [about_CommonParameters](https://learn.microsoft.com/en-us/powershell/module/microsoft.powershell.core/about/about_commonparameters).

## Outputs

### System.Void
