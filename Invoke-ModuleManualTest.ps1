# Script to provide a method to perform manual testing, and to provid a method for ModuleAssembler to build itself.
function Get-FunctionName {
    [CmdletBinding()]
    param (
        [Parameter(
            Mandatory = $true,
            Position = 0)]
        [ValidateNotNullOrEmpty()]
        [string] $Path
    )

    try {
        $moduleContent = Get-Content -Path $Path -Raw
        $ast = [System.Management.Automation.Language.Parser]::ParseInput($moduleContent, [ref]$null, [ref]$null)
        $functionName = $ast.FindAll({ $args[0] -is [System.Management.Automation.Language.FunctionDefinitionAst] }, $false) | ForEach-Object { $_.Name }
        return $functionName
    } catch {
        return ''
    }
}

function Build-ModuleManualTest {
    [CmdletBinding()]
    param (
        [Parameter(
            Mandatory = $true,
            Position = 0)]
        [ValidateNotNullOrEmpty()]
        [string] $Path
    )

    $classesPath = [System.IO.Path]::Combine($PSScriptRoot, 'src', 'classes')
    $privatePath = [System.IO.Path]::Combine($PSScriptRoot, 'src', 'private')
    $publicPath = [System.IO.Path]::Combine($PSScriptRoot, 'src', 'public')
    $moduleFilePath = Join-Path $Path -ChildPath "$(Split-Path -Path $PSScriptRoot -Leaf)Test.psm1"

    $sb = [System.Text.StringBuilder]::new()
    Write-Verbose 'Processing classes and functions into psm1 file ...'
    # Classes Folder
    $files = Get-ChildItem -Path $classesPath -Filter *.ps1 -ErrorAction SilentlyContinue
    $files | ForEach-Object {
        Write-Verbose "   Appending Class: $($_.Name)"
        $sb.AppendLine("# source: $($_.Name)") | Out-Null
        $sb.AppendLine([IO.File]::ReadAllText($_.FullName)) | Out-Null
        $sb.AppendLine('') | Out-Null
    }

    # Private Folder
    $files = Get-ChildItem -Path $privatePath -Filter *.ps1 -ErrorAction SilentlyContinue
    if ($files) {
        $files | ForEach-Object {
            Write-Verbose "   Appending Private Function: $($_.Name)"
            $sb.AppendLine("# source: $($_.Name)") | Out-Null
            $sb.AppendLine([IO.File]::ReadAllText($_.FullName)) | Out-Null
            $sb.AppendLine('') | Out-Null
        }
    }

    # Public Folder
    $files = Get-ChildItem -Path $publicPath -Filter *.ps1
    $files | ForEach-Object {
        Write-Verbose "   Appending Public Function: $($_.Name)"
        $sb.AppendLine("# source: $($_.Name)") | Out-Null
        $sb.AppendLine([IO.File]::ReadAllText($_.FullName)) | Out-Null
        $sb.AppendLine('') | Out-Null
    }

    try {
        Set-Content -Path $moduleFilePath -Value $sb.ToString() -Encoding 'UTF8' -ErrorAction Stop
        Write-Verbose 'Processing of classes and functions complete.'
    } catch {
        Write-Error 'Failed to create psm1 file' -ErrorAction Stop
    }
}


function Invoke-TestModuleBuild {
    [CmdletBinding()]
    param ()

    begin {
        $tempModuleName = "$(Split-Path -Path $PSScriptRoot -Leaf)Test"
        $moduleFilename = "$(Split-Path -Path $PSScriptRoot -Leaf)Test.psm1"
        $manifestFilename = "$($tempModuleName).psd1"
        $tempDir = [System.IO.Path]::Combine([System.IO.Path]::GetTempPath(), $tempModuleName)
        $resourcesSourcePath = [System.IO.Path]::Combine($PSScriptRoot, 'src', 'resources')
        $manifestPath = Join-Path $tempDir -ChildPath $manifestFilename
        $publicPath = [System.IO.Path]::Combine($PSScriptRoot, 'src', 'public')

        if (Test-Path $tempDir) {
            Remove-Item $tempDir -Recurse -Force
        }
        New-Item -ItemType Directory -Path $tempDir | Out-Null
    }

    process {
        # Build test version of module
        Build-ModuleManualTest -Path $tempDir -Verbose

        # Copy resources to temp location
        if (Test-Path $resourcesSourcePath) {
            Write-Verbose "Copying resources from $resourcesPath to $tempDir"
            Copy-Item -Path $resourcesSourcePath -Destination $tempDir -Recurse -Force
            if (Test-Path (Join-Path $tempDir 'resources')) {
                Write-Verbose 'Resources copied successfully'
            } else {
                Write-Warning 'Failed to copy resources'
            }
        } else {
            Write-Verbose "Resources path not found: $resourcesPath"
        }

        # # Copy module assembler setting folder
        # $madataDir = [System.IO.Path]::Combine($PSScriptRoot, '.moduleassembler')
        # if (Test-Path $madataDir) {
        #     Copy-Item -Path $madataDir -Destination $tempDir -Recurse -Force
        # }

        $functionToExport = @()
        (Get-ChildItem -Path $publicPath -Filter *.ps1).FullName | ForEach-Object {
            $functionToExport += Get-FunctionName -Path $_
        }

        # Import Formatting (if any)
        $formatsToProcess = @()
        Get-ChildItem -Path $tempDir -Recurse -File -Filter '*.ps1xml' -ErrorAction SilentlyContinue | ForEach-Object {
            $formatsToProcess += $_.Name
        }

        # Create Manifest
        $ParmsManifest = @{
            Path                 = $manifestPath
            Description          = 'Temporary Module for Manual Testing.'
            FunctionsToExport    = $functionToExport
            CmdletsToExport      = @()
            VariablesToExport    = @()
            AliasesToExport      = @()
            RootModule           = $moduleFilename
            FormatsToProcess     = $FormatsToProcess
            DefaultCommandPrefix = 'Test'
        }

        Write-Verbose 'Create test module manifest.'
        try {
            New-ModuleManifest @ParmsManifest -ErrorAction Stop
        } catch {
            'Failed to create Manifest: {0}' -f $_.Exception.Message | Write-Error -ErrorAction Stop
        }


        # Launch new PowerShell session and load the test module
        $command = "Set-Location '$PSScriptRoot'; Import-Module -Name $manifestPath; Write-Host `"Manual testing module generated at: $tempDir`""

        Write-Host 'Launching new PowerShell session with imported test module ...' -ForegroundColor Green
        Start-Process pwsh -ArgumentList '-NoExit', '-Command', $command -Wait
    }

    clean {
        Write-Host 'Session closed. Cleaning up temp directory...' -ForegroundColor Yellow
        Remove-Item $tempDir -Recurse -Force
    }
}


# Launch main function
Invoke-TestModuleBuild -Verbose
