<#
.SYNOPSIS
    Invokes the process to build a module in ModuleAssembler format.

.DESCRIPTION
    This function is used to build a module, dist folder is cleaned up and whole module is build from scracth. copies all necessary resource files.

.PARAMETER None
    This function does not accept any parameters.

.EXAMPLE
    Invoke-MABuild
    Invokes the process to build a module.
#>
function Invoke-MABuild {
    [CmdletBinding()]
    param (
    )

    $MTBuildVersion = (Get-Command Invoke-MABuild).Version
    Write-Verbose "Running ModuleAssembler Version: $MTBuildVersion"

    $ErrorActionPreference = 'Stop'
    Reset-ProjectDist
    Build-Module
    Build-Manifest
    Copy-ProjectResource
}
