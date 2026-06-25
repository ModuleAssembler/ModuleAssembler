# Changelog

All notable changes to this project will be documented in this file.

> This ChangeLog format is based on [Keep a Changelog](https://keepachangelog.com/en/1.1.0/).
>
> This module project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [Unreleased]

### Added

- Added JSON schema.
- Added Update-MAChangelogRelease to promote CHANGELOG.md [Unreleased] content into a versioned release section and recreate standard [Unreleased] placeholders.
- Added `-SkipDependenciesCheck` parameter to `Publish-MAModule` to bypass repository dependency validation when publishing to repositories that do not host module dependencies such as file shares.

### Changed

- `Build-Manifest` now post-processes the generated `.psd1` through `Invoke-Formatter` and trailing-whitespace trimming to produce a clean file that passes PSScriptAnalyzer.
- `Initialize-GitRepo` warning text now clarifies that Git lookup failed in PATH for the current session and points to a typical Windows Git path.
- Moved json data for ModuleAssembler to .moduleassembler directory.
- Refactor of all private and public functions.

## [0.1.0] - 2025-11-22

### Added

- Initialize Fork from [ModuleTools](https://github.com/belibug/ModuleTools).
- Added vscode settings.

### Changed

- Renaming of public functions, to use the MA (ModuleAssembler) prefix.
