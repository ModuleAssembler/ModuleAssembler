function Import-MAFunction {
    <#
    .SYNOPSIS
        Launches a new PowerShell session with all module functions imported for manual testing.

    .DESCRIPTION
        Launches a new PowerShell session and imports the module functions using dot sourcing, to provide manual testing without affecting the current session.

    .EXAMPLE
        Launches a new session with all functions imported.
        Import-MAFunction

    .EXAMPLE
        Launches a new session with all functions imported, with Verbose output.
        Import-MAFunction -Verbose
    #>

    [CmdletBinding()]
    param ()

    begin {
        $data = Get-MAProjectInfo
    }

    process {
        try {
            $privatePath = $data.PrivateDir
            $publicPath = $data.PublicDir
            $resourcesPath = $data.ResourcesDir

            $functionFiles = Get-ChildItem -Path $privatePath, $publicPath -Filter '*.ps1' -File

            # Create temp directory for flattened module
            $tempDir = [System.IO.Path]::Combine([System.IO.Path]::GetTempPath(), "$($data.ProjectName).Test")
            if (Test-Path $tempDir) {
                Remove-Item $tempDir -Recurse -Force
            }
            New-Item -ItemType Directory -Path $tempDir | Out-Null

            # Copy function files to temp root
            $functionFiles | Copy-Item -Destination $tempDir

            # Copy module assembler setting folder
            $madataDir = [System.IO.Path]::Combine($PSScriptRoot, '.moduleassembler')
            if (Test-Path $madataDir) {
                Copy-Item -Path $madataDir -Destination $tempDir -Recurse -Force
            }

            # Copy resources to temp
            if (Test-Path $resourcesPath) {
                Write-Verbose "Copying resources from $resourcesPath to $tempDir"
                Copy-Item -Path $resourcesPath -Destination $tempDir -Recurse -Force
                if (Test-Path (Join-Path $tempDir 'resources')) {
                    Write-Verbose 'Resources copied successfully'
                } else {
                    Write-Warning 'Failed to copy resources'
                }
            } else {
                Write-Verbose "Resources path not found: $resourcesPath"
            }

            # Prepare import commands from temp
            $tempFunctionFiles = Get-ChildItem -Path $tempDir -Filter '*.ps1' -File
            $importCommands = foreach ($file in $tempFunctionFiles) {
                Write-Verbose "Preparing to import function from: $($file.FullName)"
                ". '$($file.FullName)'"
            }

            $command = "Set-Location $tempDir; Write-Host 'Flattened module loaded at: $tempDir'; " + ($importCommands -join '; ')

            Write-Host 'Launching new PowerShell session with imported functions ...' -ForegroundColor Green
            Start-Process pwsh -ArgumentList '-NoExit', '-Command', $command -Wait
            Write-Host 'Session closed. Cleaning up temp directory...' -ForegroundColor Yellow
            Remove-Item $tempDir -Recurse -Force
        } catch {
            $PSCmdlet.ThrowTerminatingError($_)
        }
    }

    end {
        # Cleanup code
    }
}
