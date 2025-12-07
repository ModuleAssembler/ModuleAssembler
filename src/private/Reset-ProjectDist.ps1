function Reset-ProjectDist {
    <#
    .SYNOPSIS
        Reset the project dist folder.

    .DESCRIPTION
        Resets the project distribution (dist) folder, which contains the built module.

    .EXAMPLE
        Reset the project dist folder.
        Reset-ProjectDist
    #>

    [CmdletBinding()]
    param ()

    begin {
        $ErrorActionPreference = 'Stop'
        $data = Get-MAProjectInfo
    }

    process {
        try {
            Write-Verbose 'Running dist folder reset'
            if (Test-Path $data.OutputDir) {
                Remove-Item -Path $data.OutputDir -Recurse -Force
            }
            # Setup Folders
            New-Item -Path $data.OutputDir -ItemType Directory -Force | Out-Null # Dist folder
            New-Item -Path $data.OutputModuleDir -Type Directory -Force | Out-Null # Module Folder
        } catch {
            Write-Error 'Failed to reset Dist folder'
        }
    }

    end {
        # Cleanup code
    }
}
