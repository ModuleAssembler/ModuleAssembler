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
|       |-- ProjectCompliance.Tests.ps1
|       |-- QA.Tests.ps1
|   |-- Unit/
|   |   |-- classes/
|   |   |-- private/
|   |   |-- public/
|-- .gitignore
|-- .markdownlint.json
|-- CHANGELOG.md
|-- LICENSE
|-- PSScriptAnalyzerSettings.psd1
```

## VS Code Snippets

If you specify you will be using Visual Studio Code during new module creation, the following two snippets will be provided.
They can be utilized to quickly scaffold a new PowerShell function, that conforms to the Module Assembler opinionated best practices.

To use the snippet in Visual Studio Code, type the snippet name in your new ps1 file then press Tab.

### psfunc

Creates a minimal PowerShell advanced function with basic help and error handling.

### psfunction

Creates a PowerShell function following best practices with OTBS formatting, comprehensive help, and proper CmdletBinding.
