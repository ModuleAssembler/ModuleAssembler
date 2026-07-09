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
