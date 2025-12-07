function Invoke-MABuild {
    <#
    .SYNOPSIS
        Invokes the process to build a module in ModuleAssembler format.

    .DESCRIPTION
        Invokes the process to build by cleaning up the dist folder, building the module. and copies all necessary resource files.

    .EXAMPLE
        Execute a module build.
        Invoke-MABuild
    #>

    [CmdletBinding()]
    param ()

    begin {
        $MTBuildVersion = (Get-Command Invoke-MABuild).Version
        Write-Verbose "Running ModuleAssembler Version: $MTBuildVersion"
    }

    process {
        $ErrorActionPreference = 'Stop'
        Reset-ProjectDist
        Build-Module
        Build-Manifest
        Copy-ProjectResource
    }

    end {
        # Cleanup code
    }
}
