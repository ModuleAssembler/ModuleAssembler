# ModuleAssembler

> [ModuleAssembler Commands](docs/ModuleAssembler/index.md)

## Description

ModuleAssembler is a PowerShell module that provides scaffolding, build, test, documentation, versioning, and publishing utilities for PowerShell module development. It is suited for both interactive development workflows and CI/CD pipelines.

Key capabilities:

- Scaffold new modules with a standardised source layout, license templates, and VS Code configuration.
- Build distribution-ready modules from source.
- Run Pester unit and quality assurance tests with configurable output formats.
- Generate Markdown documentation from comment-based help.
- Manage semantic versioning, including pre-release labels.
- Promote `CHANGELOG.md` entries from `[Unreleased]` to versioned releases.
- Publish modules to registries such as PowerShell Gallery.
- Execute a complete release sequence with a single command.

## Requirements

ModuleAssembler requires PowerShell 7.4 or later. Modules scaffolded and built with ModuleAssembler can still target older PowerShell versions; the requirement applies only to the ModuleAssembler tooling itself.

## New Module Scaffold Structure

The following structure shows the full structure if all optional selections are used (Pester Tests, VS Code, git).

```text
ExampleModule/
|-- .moduleassembler/
|   |-- schemas/
|       |-- moduleassembler.v1.0.0.schema.json
|   |-- moduleproject.json
|-- .vscode/
|   |-- extensions.json
|   |-- powershell-function.code-snippets
|   |-- settings.json
|-- src/
|   |-- classes/
|   |-- private/
|   |-- public/
|   |-- resources/
|-- tests/
|   |-- QualityAssurance/
|   |   |-- ProjectCompliance.Tests.ps1
|   |   |-- QA.Tests.ps1
|   |-- Unit/
|       |-- classes/
|       |-- private/
|       |-- public/
|-- .gitignore
|-- .markdownlint.json
|-- CHANGELOG.md
|-- LICENSE
|-- PSScriptAnalyzerSettings.psd1
```

## Module Metadata

All Metadata for your module is stored in `/.moduleassember/moduleproject.json`, any manual edits requred on your module properties may be done there.

## Module Development Process

ModuleAssembler templated modules are developed as a collection of focused source files.
The source files are the authoritative code; the `dist` directory contains generated build output and should not be edited directly.

- Create each public cmdlet in its own `src/public/<FunctionName>.ps1` file.
- Create each private helper in its own `src/private/<FunctionName>.ps1` file.
- Define classes in `src/classes/`. Class filenames use numeric prefixes to control load order; for example, `src/classes/01-MAConfiguration.ps1` defines the `MAConfiguration` class.
- Keep the filename matched to the function or class name.
- Add unit tests under `tests/Unit/`.
- Include comment-based help for public functions. ModuleAssembler uses that help to generate command documentation.

A typical development cycle is:

1. Create or update a source file under `src/`.
2. Add or update the corresponding tests.
3. Run `Test-MAModule` from the module project directory.
4. Run `Build-MAModule` to create the distributable module in `dist/`.
5. Run `Build-MAModuleDocumentation` when public command help changes.
6. Update `CHANGELOG.md` for user-facing changes.
7. Use `Invoke-MARelease` when the module is ready to version, validate, build, and publish.

## Coding Standards and Comment-Based Help

ModuleAssembler applies consistent coding standards so that source files are easy to test, assemble, and document. Follow these guidelines when creating or modifying a module:

- Use one function per `.ps1` file, with the filename matching the function name.
- Use `[CmdletBinding()]` for public functions.
- Validate parameters with built-in validation attributes where applicable.
- Add `SupportsShouldProcess` and `-WhatIf` support to functions that modify state.
- Use terminating errors when a function cannot safely continue.
- Add `[OutputType()]` and strongly typed output to public functions where practical.
- Follow the project's PSScriptAnalyzer settings and formatting conventions.
- It is recommended to add unit tests for new public functions.

Every function must include comment-based help with a `.SYNOPSIS`, `.DESCRIPTION`, and at least one `.EXAMPLE`. Add a `.PARAMETER` entry for every declared parameter. Public function help is used by `Build-MAModuleDocumentation` to generate command documentation.

```powershell
<#
.SYNOPSIS
Briefly describes the function.

.DESCRIPTION
Explains what the function does.

.PARAMETER Name
Describes the parameter.

.EXAMPLE
Invoke-Example -Name 'Sample'

Demonstrates a typical use case.
#>
function Invoke-Example {
[CmdletBinding()]
param(
[Parameter(Mandatory)]
[ValidateNotNullOrEmpty()]
[string]$Name
)

"Hello, $Name"
}
```

### VS Code Snippets

When a module is scaffolded with Visual Studio Code support enabled, ModuleAssembler adds two VS Code snippets to the project.
These snippets create PowerShell function templates that follow the module’s coding and comment-based help standards.

Open a new .ps1 file under **public** or **private**, enter **`psfunc`** or **`psfunction`**, and press **Tab** to expand the template.
Review and complete the generated help, parameters, validation, and function logic before committing the file.

#### psfunc

Creates a minimal PowerShell advanced function with basic help and error handling.

#### psfunction

Creates a PowerShell function following best practices with OTBS formatting, comprehensive help, and proper CmdletBinding.

## Recommended Git Pipeline Process

Configure the Git pipeline with separate validation and release stages. The exact YAML depends on the CI provider, but the stages below provide a recommended baseline for development branches and the main branch.

### Development Branches

Run these stages for pull requests and development branch pushes:

1. Check out the repository.
2. Set up PowerShell 7.4 or later and install the required dependencies.
3. Run `Test-MAModule -TagFilter 'FunctionQA'` to validate source files and project conventions.
4. Run `Test-MAModule -TagFilter 'Unit'` to run the unit tests.
5. Run `Build-MAModule` once to assemble the module.
6. Run `Test-MAModule -TagFilter 'ModuleQA'` against that build output.
7. Publish the `dist/` directory as a pipeline artifact for inspection or downstream jobs.

Development pipelines should not publish to a module repository or change the module version.

### Main Branch

Run these stages after changes are merged into the main branch:

1. Run `Test-MAModule -TagFilter 'FunctionQA'` and `Test-MAModule -TagFilter 'Unit'`.
2. Run `Build-MAModuleDocumentation` to generate current command documentation.
3. Promote the `[Unreleased]` changelog entry and update the module version, either in separate controlled stages or as part of the release process.
4. Run `Build-MAModule` once after all documentation, version, and changelog changes are complete.
5. Run `Test-MAModule -TagFilter 'ModuleQA'` against the final build output.
6. Run `Test-MAModule -TagFilter 'ChangeLog','License'` to verify release metadata and licensing.
7. Publish `dist/` as a release artifact.
8. After an approval or release-tag check, run `Publish-MAModule` to publish the module to the configured repository.

Store API keys and other credentials in the CI provider's secret store, and never commit them to the repository.
