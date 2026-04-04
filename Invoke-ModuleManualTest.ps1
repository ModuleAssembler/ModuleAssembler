# Script to provide a method to perform manual testing, and to provide a method for ModuleAssembler to build itself.
function Get-FunctionName {
    [CmdletBinding()]
    [OutputType([string])]
    param (
        [Parameter(
            Mandatory = $true,
            Position = 0)]
        [ValidateNotNullOrEmpty()]
        [string] $Path
    )

    try {
        $ast = [System.Management.Automation.Language.Parser]::ParseFile($Path, [ref]$null, [ref]$null)
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
    $files = Get-ChildItem -Path $classesPath -Filter *.ps1 -ErrorAction SilentlyContinue | Sort-Object Name
    $files | ForEach-Object {
        Write-Verbose "   Appending Class: $($_.Name)"
        $sb.AppendLine("# source: $($_.Name)") | Out-Null
        $sb.AppendLine([IO.File]::ReadAllText($_.FullName, [System.Text.Encoding]::UTF8)) | Out-Null
        $sb.AppendLine('') | Out-Null
    }

    # Private Folder
    $files = Get-ChildItem -Path $privatePath -Filter *.ps1 -ErrorAction SilentlyContinue | Sort-Object Name
    if ($files) {
        $files | ForEach-Object {
            Write-Verbose "   Appending Private Function: $($_.Name)"
            $sb.AppendLine("# source: $($_.Name)") | Out-Null
            $sb.AppendLine([IO.File]::ReadAllText($_.FullName, [System.Text.Encoding]::UTF8)) | Out-Null
            $sb.AppendLine('') | Out-Null
        }
    }

    # Public Folder
    $files = Get-ChildItem -Path $publicPath -Filter *.ps1 | Sort-Object Name
    $files | ForEach-Object {
        Write-Verbose "   Appending Public Function: $($_.Name)"
        $sb.AppendLine("# source: $($_.Name)") | Out-Null
        $sb.AppendLine([IO.File]::ReadAllText($_.FullName, [System.Text.Encoding]::UTF8)) | Out-Null
        $sb.AppendLine('') | Out-Null
    }

    try {
        Set-Content -Path $moduleFilePath -Value $sb.ToString() -Encoding 'utf8NoBOM' -ErrorAction Stop
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
            try {
                Remove-Item $tempDir -Recurse -Force -ErrorAction Stop
            } catch {
                throw "Failed to clean up temp directory '$tempDir': $($_.Exception.Message)"
            }
        }
        New-Item -ItemType Directory -Path $tempDir | Out-Null
    }

    process {
        # Build test version of module
        Build-ModuleManualTest -Path $tempDir -Verbose

        # Copy resources to temp location
        if (Test-Path $resourcesSourcePath) {
            Write-Verbose "Copying resources from $resourcesSourcePath to $tempDir"
            Copy-Item -Path $resourcesSourcePath -Destination $tempDir -Recurse -Force
            if (Test-Path (Join-Path $tempDir 'resources')) {
                Write-Verbose 'Resources copied successfully'
            } else {
                Write-Warning 'Failed to copy resources'
            }
        } else {
            Write-Verbose "Resources path not found: $resourcesSourcePath"
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


        # Write a startup script to the temp directory to initialise the test session.
        # Using a script file rather than -EncodedCommand keeps initialisation readable,
        # avoids the Base64 size limit, and allows defining stateful helper functions.
        $safeRoot = [System.Management.Automation.Language.CodeGeneration]::EscapeSingleQuotedStringContent($PSScriptRoot)
        $safeManifestPath = [System.Management.Automation.Language.CodeGeneration]::EscapeSingleQuotedStringContent($manifestPath)
        $startupScriptPath = Join-Path $tempDir -ChildPath 'Start-MATestSession.ps1'

        $startupScript = @"
Set-Location -LiteralPath '$safeRoot'

`$env:MA_PROJECT_ROOT    = '$safeRoot'
`$env:MA_MODULE_MANIFEST = '$safeManifestPath'

function Restore-MASession {
    # Re-import the test module unconditionally to guarantee a clean scope.
    # This is necessary because several operations corrupt session state:
    #   - Test-TestMAModule  : Test-ModuleManifest imports and releases the dist
    #                          module, which removes Get-MAProjectInfo from global scope
    #                          and may disturb module-internal function resolution.
    #   - Build-TestMAModuleDocumentation : imports the dist module with -Force,
    #                          then its end block removes it, wiping Get-MAProjectInfo.
    # Re-importing with -Force ensures both the module's internal scope and all
    # exported bindings are in a known-good state before the next command runs.
    Remove-Module -Name 'ModuleAssemblerTest' -Force -ErrorAction SilentlyContinue
    Import-Module -Name `$env:MA_MODULE_MANIFEST -Force -ErrorAction Stop
    Set-Location -LiteralPath `$env:MA_PROJECT_ROOT
}

function Reset-MARoot {
    <#
    .SYNOPSIS
        Forcibly restores the working directory and module bindings for the ModuleAssembler test session.
    .DESCRIPTION
        The prompt function automatically calls Restore-MASession after every command,
        so manual invocation of Reset-MARoot is not normally required. Use it if the
        prompt auto-restore itself encountered an error, or to force a known-clean state.
    #>
    Restore-MASession
    Write-Host 'Session forcibly restored: module reloaded and location reset.' -ForegroundColor Cyan
}

function prompt {
    Restore-MASession
    "PS `$(Get-Location)> "
}

Write-Host ''
Write-Host 'ModuleAssembler test session ready.' -ForegroundColor Green
Write-Host "Project root : `$env:MA_PROJECT_ROOT" -ForegroundColor Cyan
Write-Host ''
Write-Host 'Recommended command order:' -ForegroundColor Cyan
Write-Host '  1. Build-TestMAModule                  - Build the module' -ForegroundColor Cyan
Write-Host '  2. Test-TestMAModule                   - Run Pester tests' -ForegroundColor Cyan
Write-Host '  3. Build-TestMAModuleDocumentation     - Generate documentation' -ForegroundColor Cyan
Write-Host ''
Write-Host 'NOTE: The module is automatically reloaded after each command.' -ForegroundColor Cyan
Write-Host '  Run Reset-MARoot to force a manual reload if needed.' -ForegroundColor Cyan
Write-Host ''
"@

        Set-Content -Path $startupScriptPath -Value $startupScript -Encoding utf8NoBOM

        Write-Host 'Launching new PowerShell session with imported test module ...' -ForegroundColor Green
        Start-Process pwsh -ArgumentList '-NoExit', '-File', $startupScriptPath -Wait
    }

    clean {
        Write-Host 'Session closed. Cleaning up temp directory...' -ForegroundColor Green
        try {
            Remove-Item $tempDir -Recurse -Force -ErrorAction Stop
        } catch {
            Write-Warning "Failed to clean up temp directory '$tempDir': $($_.Exception.Message)"
        }

        Write-Host 'Cleanup temp directory complete.' -ForegroundColor Green
    }
}


# Launch main function
Invoke-TestModuleBuild -Verbose
