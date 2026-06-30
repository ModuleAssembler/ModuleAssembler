# Changelog

All notable changes to this project will be documented in this file.

> This ChangeLog format is based on [Keep a Changelog](https://keepachangelog.com/en/1.1.0/).
>
> This module project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [Unreleased]

### Added

- Added JSON schema.
- Added `Build-MAModuleDocumentation` to automatically generate Markdown based documentation, with function comment-based help as the source of truth.
- Added `Update-MAChangelogRelease` to promote CHANGELOG.md [Unreleased] content into a versioned release section and recreate a fresh [Unreleased] section.

### Changed

- Moved json data for ModuleAssembler to `.moduleassembler` directory.
- Refactor of all private and public functions, to conform with ModuleAssembler naming and coding standards.

## [0.1.0] - 2025-11-22

### Added

- Initialize Fork from [ModuleTools](https://github.com/belibug/ModuleTools).
- Added vscode settings.

### Changed

- Renaming of public functions, to use the MA (ModuleAssembler) prefix.
