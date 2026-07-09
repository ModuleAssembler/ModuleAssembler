# Publish-MAModule

## Synopsis

Publishes a built module to a target package repository.

## Syntax

```powershell
Publish-MAModule
    [-PowerShellGalleryApiKey <securestring>]
    [-SkipDependenciesCheck]
    [-SkipPrePublishValidation]
    [-WhatIf]
    [-Confirm]
    [<CommonParameters>]

Publish-MAModule -NuGetFeedUrl <string>
    [-NuGetApiKey <securestring>]
    [-SkipDependenciesCheck]
    [-SkipPrePublishValidation]
    [-WhatIf]
    [-Confirm]
    [<CommonParameters>]

Publish-MAModule -FileSharePath <string>
    [-FileShareCredential <pscredential>]
    [-SkipDependenciesCheck]
    [-SkipPrePublishValidation]
    [-WhatIf]
    [-Confirm]
    [<CommonParameters>]
```

## Description

Publishes the built module artifact from the dist folder to a target package repository.
Supports PowerShell Gallery (default), any NuGet-compatible feed (GitHub Packages,
GitLab Packages, Azure Artifacts, Forgejo, etc.), and file share paths.

Credentials are accepted as parameters for manual use or resolved from masked pipeline environment variables
for pipeline execution:

- PSGallery: $env:PSGALLERY_API_KEY
- NuGetFeed: $env:NUGET_API_KEY
- FileShare: $env:FILESHARE_USERNAME and $env:FILESHARE_PASSWORD

SECURITY NOTE: Environment variable secrets are plain-text and readable by any process
running in the same user context. For interactive or developer use, prefer passing
credentials via the dedicated parameters rather than environment variables, or protect
secrets with the Microsoft.PowerShell.SecretManagement module and a local vault.

## Aliases

MAPublish

## Examples

### EXAMPLE 1

```powershell
PS > Publish-MAModule
```

Publishes to PowerShell Gallery using $env:PSGALLERY_API_KEY.

### EXAMPLE 2

```powershell
PS > Publish-MAModule -PowerShellGalleryApiKey (Read-Host -AsSecureString 'PSGallery API Key')
```

Publishes to PowerShell Gallery using a provided API key.

### EXAMPLE 3

```powershell
PS > Publish-MAModule -NuGetFeedUrl 'https://nuget.pkg.github.com/myorg/index.json'
```

Publishes to GitHub Packages using $env:NUGET_API_KEY.

### EXAMPLE 4

```powershell
PS > Publish-MAModule -NuGetFeedUrl 'https://gitlab.com/api/v4/projects/12345678/packages/nuget/index.json'
```

Publishes to GitLab Packages using $env:NUGET_API_KEY.

### EXAMPLE 5

```powershell
Publish-MAModule -NuGetFeedUrl 'https://forgejo.example.com/api/packages/<owner> /nuget/index.json'
```

Publishes to a Forgejo package registry using $env:NUGET_API_KEY.

### EXAMPLE 6

```powershell
Publish-MAModule -NuGetFeedUrl 'https://pkgs.dev.azure.com/<organization> /<project>/_packaging/<feed>/nuget/v3/index.json'
```

Publishes to an Azure Artifacts feed using $env:NUGET_API_KEY.

### EXAMPLE 7

```powershell
PS > Publish-MAModule -FileSharePath '\\server\PSModules'
```

Publishes to a file share repository using $env:FILESHARE_USERNAME and $env:FILESHARE_PASSWORD.

### EXAMPLE 8

```powershell
PS > Publish-MAModule -FileSharePath '\\server\PSModules' -FileShareCredential (Get-Credential)
```

Publishes to a file share repository using an explicit credential.

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

The full NuGet v3 feed URL for any compatible registry.

Examples:
  GitHub:  https://nuget.pkg.github.com/<owner>/index.json
  GitLab:  https://gitlab.com/api/v4/projects/<project-id>/packages/nuget/index.json

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

### -SkipDependenciesCheck

Skips the repository dependency availability check performed by Publish-PSResource.
Useful when publishing to a file share or private feed that does not host the module's
dependencies (e.g. Pester, PSScriptAnalyzer). Consumers are responsible for satisfying
dependencies when they install the module.

| Property | Value |
| --- | --- |
| Type | SwitchParameter |
| Required | false |
| Default Value | False |
| Accept Pipeline Input | false |
| Accept Wildcards | false |
| Position | named |

### -SkipPrePublishValidation

Skips changelog state and version uniqueness checks. Not recommended for production use.

| Property | Value |
| --- | --- |
| Type | SwitchParameter |
| Required | false |
| Default Value | False |
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
