function Build-MAModule {
    <#
    .SYNOPSIS
        Invokes the process to build a module in ModuleAssembler format.

    .DESCRIPTION
        Builds the current ModuleAssembler project in the project's dist directory.

        Run this command from the module project directory. The build removes any existing
        dist output, combines the class, private, and public source files into the module
        PSM1 file, creates the module manifest, and copies the project resource files into
        the build output according to the project configuration.

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
