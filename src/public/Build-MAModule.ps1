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
    [OutputType([void])]
    [Alias('MABuild')]
    param ()

    begin {
        $ErrorActionPreference = 'Stop'
        $MAVersion = (Get-Module -Name ModuleAssembler).Version
        Write-Verbose "Running ModuleAssembler Version: $MAVersion"
    }

    process {
        Reset-ProjectDist
        Build-Module
        Build-Manifest
        Copy-ProjectResource
    }
}
