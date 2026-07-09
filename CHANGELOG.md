# Changelog

All notable changes to this project will be documented in this file.

Types of changes, as level 3 headings:

- `Added` for new features.
- `Changed` for changes in existing functionality.
- `Deprecated` for soon-to-be removed features.
- `Removed` for now removed features.
- `Fixed` for bug fixes.
- `Security` for vulnerabilities.

> This ChangeLog format is based on [Keep a Changelog](https://keepachangelog.com/en/1.1.0/).
>
> This module project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [Unreleased]

### Added

- Added VSCode extensions, settings, and code snippet files.
- Added JSON schema for improved validation and manual editing.
- Added Project License templates for Apache v2, BSD 3-Clause, MIT.
- Added `Build-MAModuleDocumentation` to automatically generate Markdown based documentation, with function comment-based help as the source of truth.
- Added default QA Pester tests, to help ensure function and module quality.
- Added PSScriptAnalyzerSettings.
- Added ChangeLog template.
- Added `Update-MASchema` to provide a means to update the ModuleAssember schema for existing projects.
- Added `Update-MAChangelogRelease` to promote CHANGELOG.md [Unreleased] content into a versioned release section and recreate a fresh [Unreleased] section.
- Added `Publish-MAModule` to publish modules to a registry such as PowerShell Gallery.
- Added `Invoke-MARelease` for manually executing a full release sequence.

### Changed

- Refactor of all private and public functions, to conform with ModuleAssembler naming and coding standards.
- Updates to `Update-MAModuleVersion` to support pre-release versions.
- Updates to `New-MAModule` for additional options such as Company Name, Project License, Visual Studio Code standards, and scaffolding improvements.
- Expansion of items in JSON schema (ex: RequiredModules).
- Moved json data for ModuleAssembler to `.moduleassembler` directory.

## [0.1.0] - 2025-11-22

### Added

- Initialize Fork from [ModuleTools](https://github.com/belibug/ModuleTools).
- Added vscode settings.

### Changed

- Renaming of public functions, to use the MA (ModuleAssembler) prefix.
