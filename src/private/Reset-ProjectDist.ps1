function Reset-ProjectDist {
    <#
    .SYNOPSIS
        Reset the project dist folder.

    .DESCRIPTION
        Resets the project distribution (dist) folder, which contains the built module.

    .EXAMPLE
        Reset-ProjectDist

        Reset the project dist folder.
    #>

    [CmdletBinding(SupportsShouldProcess = $true)]
    param ()

    begin {
        $ErrorActionPreference = 'Stop'
        $data = Get-MAProjectInfo
    }

    process {
        try {
            Write-Verbose 'Running dist folder reset'
            if (Test-Path $data.OutputDir) {
                if ($PSCmdlet.ShouldProcess($data.OutputDir)) {
                    Remove-Item -Path $data.OutputDir -Recurse -Force
                }
            }
            # Setup Folders
            if ($PSCmdlet.ShouldProcess($data.OutputDir)) {
                New-Item -Path $data.OutputDir -ItemType Directory -Force | Out-Null # Dist folder
            }

            if ($PSCmdlet.ShouldProcess($data.OutputModuleDir)) {
                New-Item -Path $data.OutputModuleDir -Type Directory -Force | Out-Null # Module Folder
            }
        } catch {
            Write-Error 'Failed to reset Dist folder'
        }
    }

    end {
        # Cleanup code
    }
}
