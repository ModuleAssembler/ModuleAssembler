BeforeAll {
    $script:projectRoot = Split-Path -Path (Split-Path -Path (Split-Path -Path $PSScriptRoot -Parent) -Parent) -Parent
    . (Join-Path -Path $script:projectRoot -ChildPath 'src/public/Get-MAProjectInfo.ps1')
    . (Join-Path -Path $script:projectRoot -ChildPath 'src/public/Publish-MAModule.ps1')
    . (Join-Path -Path $script:projectRoot -ChildPath 'src/private/Resolve-ApiKey.ps1')
    . (Join-Path -Path $script:projectRoot -ChildPath 'src/private/Invoke-PrePublishValidation.ps1')

    function ConvertTo-TestSecureString {
        param(
            [Parameter(Mandatory)]
            [string]$Value
        )

        $secureString = [System.Security.SecureString]::new()
        foreach ($character in $Value.ToCharArray()) {
            $secureString.AppendChar($character)
        }
        $secureString.MakeReadOnly()
        return $secureString
    }
}

Describe 'Publish-MAModule' -Tag 'Unit' {
    BeforeEach {
        $script:testRoot = Join-Path -Path ([System.IO.Path]::GetTempPath()) -ChildPath ([System.Guid]::NewGuid().ToString('N'))
        New-Item -Path $script:testRoot -ItemType Directory -Force | Out-Null
        $script:outputModuleDir = Join-Path -Path $script:testRoot -ChildPath 'dist/DemoModule'
        New-Item -Path $script:outputModuleDir -ItemType Directory -Force | Out-Null
        $script:manifestPath = Join-Path -Path $script:outputModuleDir -ChildPath 'DemoModule.psd1'
        Set-Content -Path $script:manifestPath -Value '@{}' -Encoding 'utf8NoBOM'
    }

    AfterEach {
        if (Test-Path -Path $script:testRoot) {
            Remove-Item -Path $script:testRoot -Recurse -Force
        }
    }

    AfterAll {
        Remove-Item -Path Function:\ConvertTo-TestSecureString -ErrorAction SilentlyContinue
    }

    It 'throws when PSResourceGet module is not available' {
        Mock Get-Module { $null } -ParameterFilter { $Name -eq 'Microsoft.PowerShell.PSResourceGet' -and $ListAvailable }

        { Publish-MAModule -Confirm:$false } | Should-Throw -ExceptionMessage '*PSResourceGet is required*'
    }

    It 'throws when built module manifest is missing' {
        Mock Get-Module {
            [PSCustomObject]@{ Name = 'Microsoft.PowerShell.PSResourceGet' }
        } -ParameterFilter { $Name -eq 'Microsoft.PowerShell.PSResourceGet' -and $ListAvailable }

        Mock Get-MAProjectInfo {
            [PSCustomObject]@{
                ProjectName      = 'DemoModule'
                Version          = '1.0.0'
                OutputModuleDir  = $script:outputModuleDir
                ManifestFilePSD1 = (Join-Path -Path $script:testRoot -ChildPath 'dist/DemoModule/missing.psd1')
            }
        }

        { Publish-MAModule -Confirm:$false } | Should-Throw -ExceptionMessage '*Run Build-MAModule before publishing*'
    }

    It 'rejects unsupported GitLab group feed URL for NuGet publish' {
        Mock Get-Module {
            [PSCustomObject]@{ Name = 'Microsoft.PowerShell.PSResourceGet' }
        } -ParameterFilter { $Name -eq 'Microsoft.PowerShell.PSResourceGet' -and $ListAvailable }

        Mock Get-MAProjectInfo {
            [PSCustomObject]@{
                ProjectName      = 'DemoModule'
                Version          = '1.0.0'
                OutputModuleDir  = $script:outputModuleDir
                ManifestFilePSD1 = $script:manifestPath
            }
        }

        Mock Resolve-ApiKey {
            ConvertTo-TestSecureString -Value 'token'
        }

        $feed = 'https://gitlab.example.com/api/v4/groups/mygroup/-/packages/nuget/index.json'
        { Publish-MAModule -NuGetFeedUrl $feed -Confirm:$false } | Should-Throw -ExceptionMessage '*group NuGet feed URLs are not supported*'
    }

    It 'publishes to PowerShell Gallery when API key is provided' {
        Mock Get-Module {
            [PSCustomObject]@{ Name = 'Microsoft.PowerShell.PSResourceGet' }
        } -ParameterFilter { $Name -eq 'Microsoft.PowerShell.PSResourceGet' -and $ListAvailable }

        Mock Get-MAProjectInfo {
            [PSCustomObject]@{
                ProjectName      = 'DemoModule'
                Version          = '1.0.0'
                OutputModuleDir  = $script:outputModuleDir
                ManifestFilePSD1 = $script:manifestPath
            }
        }

        Mock Resolve-ApiKey {
            ConvertTo-TestSecureString -Value 'token'
        }

        Mock Invoke-PrePublishValidation {}
        Mock Publish-PSResource {}
        Mock Register-PSResourceRepository {}
        Mock Unregister-PSResourceRepository {}

        $apiKey = ConvertTo-TestSecureString -Value 'abcd'
        Publish-MAModule -PowerShellGalleryApiKey $apiKey -Confirm:$false

        Should-Invoke Invoke-PrePublishValidation -Exactly 1 -ParameterFilter { $Repository -eq 'PSGallery' }
        Should-Invoke Publish-PSResource -Exactly 1 -ParameterFilter {
            $Path -eq $script:outputModuleDir -and
            $Repository -eq 'PSGallery' -and
            $ApiKey -eq 'token'
        }
        Should-Invoke Register-PSResourceRepository -Exactly 0
        Should-Invoke Unregister-PSResourceRepository -Exactly 0
    }

    It 'publishes to NuGet feed using a temporary repository and unregisters it' {
        Mock Get-Module {
            [PSCustomObject]@{ Name = 'Microsoft.PowerShell.PSResourceGet' }
        } -ParameterFilter { $Name -eq 'Microsoft.PowerShell.PSResourceGet' -and $ListAvailable }

        Mock Get-MAProjectInfo {
            [PSCustomObject]@{
                ProjectName      = 'DemoModule'
                Version          = '1.0.0'
                OutputModuleDir  = $script:outputModuleDir
                ManifestFilePSD1 = $script:manifestPath
            }
        }

        Mock Resolve-ApiKey {
            ConvertTo-TestSecureString -Value 'nuget-token'
        }

        Mock Invoke-PrePublishValidation {}
        Mock Register-PSResourceRepository {
            $script:registeredNuGetRepository = $Name
        }
        Mock Publish-PSResource {}
        Mock Unregister-PSResourceRepository {}

        $feed = 'https://nuget.pkg.github.com/myorg/index.json'
        Publish-MAModule -NuGetFeedUrl $feed -Confirm:$false

        $script:registeredNuGetRepository | Should-NotBeNull
        $script:registeredNuGetRepository | Should-MatchString '^MAPublish_NuGetFeed_'

        Should-Invoke Register-PSResourceRepository -Exactly 1 -ParameterFilter {
            $Name -eq $script:registeredNuGetRepository -and
            $Uri -eq $feed -and
            $Trusted
        }
        Should-Invoke Invoke-PrePublishValidation -Exactly 1 -ParameterFilter { $Repository -eq $script:registeredNuGetRepository }
        Should-Invoke Publish-PSResource -Exactly 1 -ParameterFilter {
            $Path -eq $script:outputModuleDir -and
            $Repository -eq $script:registeredNuGetRepository -and
            $ApiKey -eq 'nuget-token'
        }
        Should-Invoke Unregister-PSResourceRepository -Exactly 1 -ParameterFilter { $Name -eq $script:registeredNuGetRepository }
    }

    It 'publishes to file share with credential and without API key' {
        Mock Get-Module {
            [PSCustomObject]@{ Name = 'Microsoft.PowerShell.PSResourceGet' }
        } -ParameterFilter { $Name -eq 'Microsoft.PowerShell.PSResourceGet' -and $ListAvailable }

        Mock Get-MAProjectInfo {
            [PSCustomObject]@{
                ProjectName      = 'DemoModule'
                Version          = '1.0.0'
                OutputModuleDir  = $script:outputModuleDir
                ManifestFilePSD1 = $script:manifestPath
            }
        }

        Mock Invoke-PrePublishValidation {}
        Mock Register-PSResourceRepository {
            $script:registeredFileShareRepository = $Name
        }
        Mock Publish-PSResource {}
        Mock Unregister-PSResourceRepository {}

        $fileSharePath = Join-Path -Path $script:testRoot -ChildPath 'PSModules'
        New-Item -Path $fileSharePath -ItemType Directory -Force | Out-Null

        $securePass = ConvertTo-TestSecureString -Value 'password'
        $credential = [PSCredential]::new('build-user', $securePass)

        Publish-MAModule -FileSharePath $fileSharePath -FileShareCredential $credential -Confirm:$false

        $script:registeredFileShareRepository | Should-NotBeNull
        $script:registeredFileShareRepository | Should-MatchString '^MAPublish_FileShare_'

        Should-Invoke Register-PSResourceRepository -Exactly 1 -ParameterFilter {
            $Name -eq $script:registeredFileShareRepository -and
            $Uri -eq $fileSharePath -and
            $Trusted
        }
        Should-Invoke Invoke-PrePublishValidation -Exactly 1 -ParameterFilter { $Repository -eq $script:registeredFileShareRepository }
        Should-Invoke Publish-PSResource -Exactly 1 -ParameterFilter {
            $Path -eq $script:outputModuleDir -and
            $Repository -eq $script:registeredFileShareRepository -and
            $Credential.UserName -eq 'build-user' -and
            -not $PSBoundParameters.ContainsKey('ApiKey')
        }
        Should-Invoke Unregister-PSResourceRepository -Exactly 1 -ParameterFilter { $Name -eq $script:registeredFileShareRepository }
    }

    It 'does not call Publish-PSResource when run with -WhatIf' {
        Mock Get-Module {
            [PSCustomObject]@{ Name = 'Microsoft.PowerShell.PSResourceGet' }
        } -ParameterFilter { $Name -eq 'Microsoft.PowerShell.PSResourceGet' -and $ListAvailable }

        Mock Get-MAProjectInfo {
            [PSCustomObject]@{
                ProjectName      = 'DemoModule'
                Version          = '1.0.0'
                OutputModuleDir  = $script:outputModuleDir
                ManifestFilePSD1 = $script:manifestPath
            }
        }

        Mock Resolve-ApiKey {
            ConvertTo-TestSecureString -Value 'token'
        }

        Mock Invoke-PrePublishValidation {}
        Mock Publish-PSResource {}

        $apiKey = ConvertTo-TestSecureString -Value 'abcd'
        Publish-MAModule -PowerShellGalleryApiKey $apiKey -WhatIf

        Should-Invoke Invoke-PrePublishValidation -Exactly 1
        Should-Invoke Publish-PSResource -Exactly 0
    }
}
