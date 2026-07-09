# Invoke-MARelease

## Synopsis

Executes the full release cycle for a ModuleAssembler module project.

## Syntax

```powershell
Invoke-MARelease
    [-PowerShellGalleryApiKey <securestring>]
    [-SkipPrePublishValidation]
    [-UpdateVersion]
    [-VersionLabel <string>]
    [-VersionPrereleaseType <string>]
    [-PromoteChangelogRelease]
    [-ChangelogReleaseDate <datetime>]
    [-WhatIf]
    [-Confirm]
    [<CommonParameters>]

Invoke-MARelease -NuGetFeedUrl <string>
    [-NuGetApiKey <securestring>]
    [-SkipPrePublishValidation]
    [-UpdateVersion]
    [-VersionLabel <string>]
    [-VersionPrereleaseType <string>]
    [-PromoteChangelogRelease]
    [-ChangelogReleaseDate <datetime>]
    [-WhatIf]
    [-Confirm]
    [<CommonParameters>]

Invoke-MARelease -FileSharePath <string>
    [-FileShareCredential <pscredential>]
    [-SkipPrePublishValidation]
    [-UpdateVersion]
    [-VersionLabel <string>]
    [-VersionPrereleaseType <string>]
    [-PromoteChangelogRelease]
    [-ChangelogReleaseDate <datetime>]
    [-WhatIf]
    [-Confirm]
    [<CommonParameters>]
```

## Description

Runs the complete release pipeline in sequence as a local convenience wrapper:

1. Test-MAModule -TagFilter 'FunctionQA'
2. (Optional) Update-MAModuleVersion
3. Build-MAModule
4. Test-MAModule -TagFilter 'ModuleQA'
5. Test-MAModule -TagFilter 'Unit'
6. Build-MAModuleDocumentation
7. (Optional) Update-MAChangelogRelease
8. Test-MAModule -TagFilter 'ChangeLog','License'
9. Publish-MAModule

Any step failure halts the release immediately. This function is intended for manual
local releases. For automated pipeline releases, invoke each step as a discrete
pipeline stage to get per-step failure visibility.

All credential parameters are passed through to Publish-MAModule. See
Get-Help Publish-MAModule for full credential and environment variable documentation.

## Aliases

MARelease

## Examples

### EXAMPLE 1

```powershell
PS > Invoke-MARelease
```

Runs the full release cycle and publishes to PowerShell Gallery using $env:PSGALLERY_API_KEY.

### EXAMPLE 2

```powershell
PS > Invoke-MARelease -PowerShellGalleryApiKey (Read-Host -AsSecureString 'PSGallery API Key')
```

Runs the full release cycle and publishes to PowerShell Gallery using a provided API key.

### EXAMPLE 3

```powershell
PS > Invoke-MARelease -NuGetFeedUrl 'https://nuget.pkg.github.com/myorg/index.json'
```

Runs the full release cycle and publishes to a NuGet-compatible feed using $env:NUGET_API_KEY.

### EXAMPLE 4

```powershell
PS > Invoke-MARelease -NuGetFeedUrl 'https://gitlab.com/api/v4/projects/12345678/packages/nuget/index.json'
```

Runs the full release cycle and publishes to a GitLab package feed using $env:NUGET_API_KEY.

### EXAMPLE 5

```powershell
PS > Invoke-MARelease -FileSharePath '\\server\PSModules'
```

Runs the full release cycle and publishes to a file share repository.

### EXAMPLE 6

```powershell
PS > Invoke-MARelease -UpdateVersion -VersionLabel Patch -PromoteChangelogRelease
```

Runs the full release cycle, increments the module version before build,
promotes changelog content before compliance tests, and publishes.

## Parameters

### -PowerShellGalleryApiKey

API key for PowerShell Gallery. If omitted, falls back to $env:PSGALLERY_API_KEY.

| Property | Value |
| --- | --- |
| Type | SecureString |
| Required | false |
| Accept Pipeline Input | false |
| Accept Wildcards | false |
| Position | named |

### -NuGetFeedUrl

Full NuGet v3 feed URL for any compatible registry.

| Property | Value |
| --- | --- |
| Type | String |
| Required | true |
| Accept Pipeline Input | false |
| Accept Wildcards | false |
| Position | named |

### -NuGetApiKey

API key or token for the NuGet feed. If omitted, falls back to $env:NUGET_API_KEY.

| Property | Value |
| --- | --- |
| Type | SecureString |
| Required | false |
| Accept Pipeline Input | false |
| Accept Wildcards | false |
| Position | named |

### -FileSharePath

UNC or local path to a file share acting as a PSResource repository.

| Property | Value |
| --- | --- |
| Type | String |
| Required | true |
| Accept Pipeline Input | false |
| Accept Wildcards | false |
| Position | named |

### -FileShareCredential

PSCredential for authenticating to the file share. If omitted, falls back to
$env:FILESHARE_USERNAME and $env:FILESHARE_PASSWORD.

| Property | Value |
| --- | --- |
| Type | PSCredential |
| Required | false |
| Accept Pipeline Input | false |
| Accept Wildcards | false |
| Position | named |

### -SkipPrePublishValidation

Skips changelog state and version uniqueness checks during publish.

| Property | Value |
| --- | --- |
| Type | SwitchParameter |
| Required | false |
| Default Value | False |
| Accept Pipeline Input | false |
| Accept Wildcards | false |
| Position | named |

### -UpdateVersion

When specified, executes Update-MAModuleVersion after FunctionQA and before build.

| Property | Value |
| --- | --- |
| Type | SwitchParameter |
| Required | false |
| Default Value | False |
| Accept Pipeline Input | false |
| Accept Wildcards | false |
| Position | named |

### -VersionLabel

Label passed to Update-MAModuleVersion -Label. Valid values are Major, Minor, Patch.
Requires -UpdateVersion.

| Property | Value |
| --- | --- |
| Type | String |
| Required | false |
| Valid Values | Major, Minor, Patch |
| Accept Pipeline Input | false |
| Accept Wildcards | false |
| Position | named |

### -VersionPrereleaseType

Prerelease type passed to Update-MAModuleVersion -PrereleaseType.
Valid values are alpha, beta, preview, rc. Requires -UpdateVersion.

| Property | Value |
| --- | --- |
| Type | String |
| Required | false |
| Valid Values | alpha, beta, preview, rc |
| Accept Pipeline Input | false |
| Accept Wildcards | false |
| Position | named |

### -PromoteChangelogRelease

When specified, executes Update-MAChangelogRelease after documentation and before
compliance and publish.

| Property | Value |
| --- | --- |
| Type | SwitchParameter |
| Required | false |
| Default Value | False |
| Accept Pipeline Input | false |
| Accept Wildcards | false |
| Position | named |

### -ChangelogReleaseDate

Release date passed to Update-MAChangelogRelease -ReleaseDate.
Requires -PromoteChangelogRelease.

| Property | Value |
| --- | --- |
| Type | DateTime |
| Required | false |
| Accept Pipeline Input | false |
| Accept Wildcards | false |
| Position | named |

### -WhatIf

| Property | Value |
| --- | --- |
| Type | SwitchParameter |
| Required | false |
| Alias | wi |
| Accept Pipeline Input | false |
| Accept Wildcards | false |
| Position | named |

### -Confirm

| Property | Value |
| --- | --- |
| Type | SwitchParameter |
| Required | false |
| Alias | cf |
| Accept Pipeline Input | false |
| Accept Wildcards | false |
| Position | named |

### \<CommonParameters\>

This cmdlet supports the common parameters: Verbose, Debug, ErrorAction, ErrorVariable, WarningAction, WarningVariable, OutBuffer, PipelineVariable, and OutVariable.

For more information, see about_CommonParameters [https://go.microsoft.com/fwlink/?LinkID=113216].

## Outputs

### System.Void
