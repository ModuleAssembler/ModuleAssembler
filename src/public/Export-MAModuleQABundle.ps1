function Export-MAModuleQABundle {
    <#
    .SYNOPSIS
        Export the bundled ModuleAssembler QA tests to a project.

    .DESCRIPTION
        Copies all current ModuleAssembler Quality Assurance (QA) test files to tests/QualityAssurance in a
        ModuleAssembler project. Existing files are preserved unless -Force is specified.

    .PARAMETER Path
        Path to the root of an existing ModuleAssembler project.

    .PARAMETER Force
        Replace any bundled QA test file that already exists locally.

    .EXAMPLE
        Export-MAModuleQABundle

        Exports the bundled QA tests to the current project.

    .EXAMPLE
        Export-MAModuleQABundle -Path 'C:\Work\DemoModule' -Force

        Replaces the local bundled QA tests in the specified project.
    #>

    [CmdletBinding(SupportsShouldProcess = $true)]
    [OutputType([void])]
    param (
        [Parameter(Mandatory = $false)]
        [ValidateNotNullOrEmpty()]
        [string] $Path = $PWD.Path,

        [Parameter(Mandatory = $false)]
        [switch] $Force
    )

    process {
        if (-not (Test-Path -LiteralPath $Path -PathType Container)) {
            throw "Project path '$Path' does not exist or is not a directory."
        }

        $projectRoot = (Resolve-Path -LiteralPath $Path).Path
        $projectConfigPath = Join-Path -Path $projectRoot -ChildPath '.moduleassembler/moduleproject.json'
        if (-not (Test-Path -LiteralPath $projectConfigPath -PathType Leaf)) {
            throw "Path '$projectRoot' is not a ModuleAssembler project; moduleproject.json was not found."
        }

        $qaRelativeDirectory = [System.IO.Path]::Combine('PesterTests', 'QualityAssurance')
        $sourceDirectoryCandidates = @()
        $moduleBase = $PSCmdlet.MyInvocation.MyCommand.Module.ModuleBase
        if ($moduleBase) {
            $sourceDirectoryCandidates += Join-Path -Path $moduleBase -ChildPath (Join-Path -Path 'resources' -ChildPath $qaRelativeDirectory)
            $sourceDirectoryCandidates += Join-Path -Path $moduleBase -ChildPath $qaRelativeDirectory
        }

        $sourceRoot = Split-Path -Path $PSScriptRoot -Parent
        $sourceDirectoryCandidates += Join-Path -Path $sourceRoot -ChildPath (Join-Path -Path 'resources' -ChildPath $qaRelativeDirectory)
        $sourceDirectory = $sourceDirectoryCandidates |
            Where-Object { Test-Path -LiteralPath $_ -PathType Container } |
            Select-Object -First 1

        if (-not $sourceDirectory) {
            throw 'The bundled ModuleAssembler QA test directory could not be found.'
        }

        $sourceFiles = @(Get-ChildItem -LiteralPath $sourceDirectory -Filter '*.Tests.ps1' -File | Sort-Object Name)
        if ($sourceFiles.Count -eq 0) {
            throw "No bundled QA tests were found in '$sourceDirectory'."
        }

        $qaDirectory = Join-Path -Path $projectRoot -ChildPath 'tests/QualityAssurance'
        $destinationPaths = @($sourceFiles | ForEach-Object { Join-Path -Path $qaDirectory -ChildPath $_.Name })
        $existingDestinationPaths = @($destinationPaths | Where-Object { Test-Path -LiteralPath $_ })
        if ($existingDestinationPaths.Count -gt 0 -and -not $Force.IsPresent) {
            throw "Local QA test file(s) already exist: $($existingDestinationPaths -join ', '). Use -Force to replace them."
        }

        if ($PSCmdlet.ShouldProcess($qaDirectory, 'Export bundled QA tests')) {
            New-Item -Path $qaDirectory -ItemType Directory -Force -ErrorAction Stop | Out-Null
            foreach ($sourceFile in $sourceFiles) {
                $destinationPath = Join-Path -Path $qaDirectory -ChildPath $sourceFile.Name
                if ($Force.IsPresent) {
                    Copy-Item -LiteralPath $sourceFile.FullName -Destination $destinationPath -Force -ErrorAction Stop
                } else {
                    Copy-Item -LiteralPath $sourceFile.FullName -Destination $destinationPath -ErrorAction Stop
                }
            }
        }
    }
}
