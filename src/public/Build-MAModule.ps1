function Build-MAModule {
    <#
    .SYNOPSIS
        Invokes the process to build a module in ModuleAssembler format.

    .DESCRIPTION
        Invokes the process to build by cleaning up the dist folder, building the module, and copying all necessary resource files.

    .EXAMPLE
        Build-MAModule

        Execute a module build.
    #>

    [CmdletBinding()]
    [Alias('MABuild')]
    param ()

    begin {
        $ErrorActionPreference = 'Stop'
        $MABuildVersion = (Get-Command Build-MAModule).Version
        Write-Verbose "Running ModuleAssembler Version: $MABuildVersion"
    }

    process {
        Reset-ProjectDist
        Build-Module
        Build-Manifest
        Copy-ProjectResource
    }
}
