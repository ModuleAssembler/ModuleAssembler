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
        Write-Verbose 'Running dist folder reset'
        if (Test-Path $data.OutputDir) {
            if ($PSCmdlet.ShouldProcess($data.OutputDir, 'Remove dist folder')) {
                try {
                    Remove-Item -Path $data.OutputDir -Recurse -Force
                } catch {
                    Write-Error "Failed to remove dist folder '$($data.OutputDir)'. Ensure no files are locked (e.g. module loaded in another session): $_"
                }
            }
        }

        if ($PSCmdlet.ShouldProcess($data.OutputDir, 'Create dist output folders')) {
            try {
                New-Item -Path $data.OutputModuleDir -ItemType Directory -Force | Out-Null
            } catch {
                Write-Error "Failed to create dist output folders under '$($data.OutputDir)': $_"
            }
        }
    }
}
