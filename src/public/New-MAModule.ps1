function New-MAModule {
    <#
    .SYNOPSIS
        Create module scaffolding along with project.json file to build and manage modules.

    .DESCRIPTION
        Creates module project folder structure and project.json file. Use this to quikcly setup a ModuleAssembler compatible module.

    .PARAMETER Path
        Path where module will be created. Provide root folder path, module folder will be created as a subdirectory.

    .EXAMPLE
        New-MAModule -Path 'C:\work'

        Creates module project inside c:\work folder.

    .EXAMPLE
        New-MAModule

        Creates module project in the current folder.
    #>

    [CmdletBinding(SupportsShouldProcess = $true)]
    [Alias('MANew')]
    param (
        [Parameter(Mandatory = $false)]
        [ValidateNotNullOrEmpty()]
        [string] $Path = (Get-Location).Path
    )

    begin {
        # Initialization code
    }

    process {
        $ErrorActionPreference = 'Stop'

        Push-Location
        if (-not(Test-Path $Path)) {
            Write-Error 'Not a valid path.'
        }

        $Questions = [ordered]@{
            ProjectName       = @{
                Caption = 'Module Name'
                Message = 'Enter Module name of your choice. Should use PascalCase, be descriptive and unique. No special characters permitted, other than optionally an underscore or period (ex: MyCompany.Utilities)'
                Prompt  = 'Name'
                Default = 'MANDATORY'
            }
            Description       = @{
                Caption = 'Module Description'
                Message = 'What does your module do? Describe in simple words.'
                Prompt  = 'Description'
                Default = 'MANDATORY'
            }
            Version           = @{
                Caption = 'Semantic Version'
                Message = 'Starting Version of the module (Default: 0.0.1)'
                Prompt  = 'Version'
                Default = '0.0.1'
            }
            Author            = @{
                Caption = 'Module Author'
                Message = "Enter name of the Author or Development Team. (Default: $([Environment]::UserName))"
                Prompt  = 'Name'
                Default = [Environment]::UserName
            }
            Company           = @{
                Caption = 'Company Name'
                Message = 'Enter name of the Company this module belongs to. (Default is no company name)'
                Prompt  = 'Company Name'
                Default = ''
            }
            PowerShellVersion = @{
                Caption = 'Supported PowerShell Version'
                Message = 'What is the minimum supported version of PowerShell for this module?  Valid values are 5.1 or 7.4. (Default: 7.4)'
                Prompt  = 'Version'
                Default = '7.4'
            }
            ProjectLicense    = @{
                Caption = 'Project License'
                Message = 'What Open Source License will the project use? Choices are Apache 2.0, BSD 3-Clause, GPLv3, MIT. (Default: MIT)'
                Prompt  = 'License'
                Default = 'MIT'
                Choice  = @{
                    Apache2 = 'Apache 2.0'
                    BSD3    = 'BSD 3-Clause'
                    GPL3    = 'GPLv3'
                    MIT     = 'MIT'
                }
            }
            EnablePester      = @{
                Caption = 'Pester Testing'
                Message = 'Do you want to enable basic Pester Testing?'
                Prompt  = 'EnablePester'
                Default = 'Yes'
                Choice  = @{
                    Yes = 'Enable pester to perform testing'
                    No  = 'Skip pester testing'
                }
            }
            EnableVSCode      = @{
                Caption = 'Visual Studio Code'
                Message = 'Will you be developing with Visual Studio Code for this project?'
                Prompt  = 'EnableVSCodeStandards'
                Default = 'Yes'
                Choice  = @{
                    Yes = 'Enable Visual Studio Code Standards'
                    No  = 'Disable'
                }
            }
            EnableGit         = @{
                Caption = 'Git Version Control'
                Message = 'Will you be using Git version control?'
                Prompt  = 'EnableGit'
                Default = 'Yes'
                Choice  = @{
                    Yes = 'Enable Git'
                    No  = 'Skip Git initialization'
                }
            }
        }

        $Answer = @{}
        $Questions.Keys | ForEach-Object {
            $Answer.$_ = Read-HostResponse -Ask $Questions.$_
        }


        if ($Answer.ProjectName -notmatch '^[A-Za-z][A-Za-z0-9_.]*$') {
            Write-Error 'Module Name invalid. Module should be one word in PascalCase and contain only Letters, Numbers and optionally a period.'
        }

        if ($Answer.Version -notmatch '^(0|[1-9]\d*)\.(0|[1-9]\d*)\.(0|[1-9]\d*)') {
            Write-Error 'Version number is invalid. Please, follow Semantic Versioning (ex: 1.0.0).'
        }

        $supportedPowerShellVersions = @('5.1', '7.4')
        if ($Answer.PowerShellVersion -notin $supportedPowerShellVersions) {
            Write-Error 'The specified minimum supported PowerShell Version is invalid.  Please, select a supported PowerShell version.'
        }


        $DirProject = Join-Path -Path $Path -ChildPath $Answer.ProjectName
        $DirSrc = Join-Path -Path $DirProject -ChildPath 'src'
        $DirPrivate = Join-Path -Path $DirSrc -ChildPath 'private'
        $DirPublic = Join-Path -Path $DirSrc -ChildPath 'public'
        $DirResources = Join-Path -Path $DirSrc -ChildPath 'resources'
        $DirClasses = Join-Path -Path $DirSrc -ChildPath 'classes'
        $DirTests = Join-Path -Path $DirProject -ChildPath 'tests'
        $ModuleAssemblerSettings = Join-Path -Path $DirProject -ChildPath '.moduleassembler'
        $ProjectJSONFile = Join-Path $ModuleAssemblerSettings -ChildPath 'moduleproject.json'
        $ModuleProjectTemplate = [System.IO.Path]::Combine($PSScriptRoot, 'resources', 'ModuleProjectTemplate.json')

        if ((Test-Path $DirProject) -and -not ($null -eq (Get-ChildItem -LiteralPath $DirProject -Force -ErrorAction Ignore | Select-Object -First 1))) {
            Write-Error 'Project already exists, aborting.' | Out-Null
        } elseif (-not (Test-Path $DirProject)) {
            Write-Verbose 'Path is not empty project folder, creating directory $($Answer.ProjectName).'
            New-Item -ItemType Directory -Path $DirProject | Out-Null
        }

        # Setup Module
        Write-Host "`nStarted Module Scaffolding" -ForegroundColor Green
        Write-Host 'Setting up Directories'
        ($ModuleAssemblerSettings, $DirSrc, $DirPrivate, $DirPublic, $DirResources, $DirClasses) | ForEach-Object {
            'Creating Directory: {0}' -f $_ | Write-Verbose
            New-Item -ItemType Directory -Path $_ | Out-Null
        }

        switch ($Answer.ProjectLicense) {
            'Apache2' {
                $licenseTemplate = [System.IO.Path]::Combine($PSScriptRoot, 'resources', 'LicenseTemplates', 'Apache_v2')
            }
            'BSD3' {
                $licenseTemplate = [System.IO.Path]::Combine($PSScriptRoot, 'resources', 'LicenseTemplates', 'BSD_3-Clause')
            }
            'GPL3' {
                $licenseTemplate = [System.IO.Path]::Combine($PSScriptRoot, 'resources', 'LicenseTemplates', 'GPLv3')
            }
            default {
                $licenseTemplate = [System.IO.Path]::Combine($PSScriptRoot, 'resources', 'LicenseTemplates', 'MIT')
            }
        }
        Write-Host 'Setting Project License'
        $licensePath = Join-Path -Path $DirProject -ChildPath 'LICENSE'
        $licenseContent = Get-Content $licenseTemplate -Raw
        $licenseContent = $licenseContent -replace '<YEAR>', (Get-Date -Format yyyy)

        if ($Answer.Company -ne '') {
            $copyright = $Answer.Company
        } else {
            $copyright = $Answer.Author
        }
        $licenseContent = $licenseContent -replace '<COPYRIGHT HOLDER>', $copyright

        if ($Answer.License -eq 'GPL3') {
            $licenseContent = $licenseContent -replace '<PROGRAM>', $Answer.ProjectName
        }

        Set-Content -Path $licensePath -Value $licenseContent | Out-Null


        if ( $Answer.EnablePester -eq 'Yes') {
            Write-Host 'Include Pester Configs'
            New-Item -ItemType Directory -Path $DirTests | Out-Null
            $defaultTests = [System.IO.Path]::Combine($PSScriptRoot, 'resources', 'PesterTests', '*')
            Copy-Item -Path $defaultTests -Destination $DirTests -Recurse -Force | Out-Null
        }


        if ($Answer.EnableVSCode -eq 'Yes') {
            Write-Host 'Include Visual Studio Code Configs'
            $vsSource = [System.IO.Path]::Combine($PSScriptRoot, 'resources', 'vscode')
            $vsDestination = Join-Path -Path $DirProject -ChildPath '.vscode'
            Copy-Item -Path $vsSource -Destination $vsDestination -Recurse -Force | Out-Null
        }


        if ( $Answer.EnableGit -eq 'Yes') {
            Write-Host 'Initialize Git Repo'
            Initialize-GitRepo -DirectoryPath $DirProject
            $gitIgnoreSource = [System.IO.Path]::Combine($PSScriptRoot, 'resources', 'gitignore')
            $gitIgnoreDestination = Join-Path -Path $DirProject -ChildPath '.gitignore'
            Copy-Item -Path $gitIgnoreSource -Destination $gitIgnoreDestination -Force | Out-Null
        }


        ## Create ProjectJSON
        $JsonData = Get-Content $ModuleProjectTemplate -Raw | ConvertFrom-Json -AsHashtable

        $JsonData.ProjectName = $Answer.ProjectName
        $JsonData.Description = $Answer.Description
        $JsonData.Version = $Answer.Version
        $JsonData.Manifest.Author = $Answer.Author
        $JsonData.Manifest.CompanyName = $Answer.Company
        $JsonData.Manifest.PowerShellVersion = $Answer.PowerShellVersion
        $JsonData.Manifest.GUID = (New-Guid).GUID
        if ($Answer.EnablePester -eq 'No') {
            $JsonData.Remove('Pester')
        }

        Write-Verbose $JsonData
        $JsonData | ConvertTo-Json | Out-File $ProjectJSONFile

        'Module {0} scaffolding complete' -f $Answer.ProjectName | Write-Host -ForegroundColor Green
    }

    end {
        # Cleanup code
    }
}
