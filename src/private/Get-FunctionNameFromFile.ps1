
function Get-FunctionNameFromFile {
    <#
    .SYNOPSIS
        Get function names to add to the module manifest.

    .DESCRIPTION
        Gather all function names from the ps1 files, so the information can be added to the module manifest.

    .PARAMETER Path
        Path to the function ps1 file.

    .EXAMPLE
        Get-FunctionNameFromFile -Path '.\Verb-Noun.ps1'

        Gather function names for the given file.

    .EXAMPLE
        Get-FunctionNameFromFile '.\Verb-Noun.ps1'

        Gather function names for the given file, using positional parameter.
    #>

    [CmdletBinding()]
    [OutputType([string])]
    param (
        [Parameter(
            Mandatory = $true,
            Position = 0)]
        [ValidateNotNullOrEmpty()]
        [string] $Path
    )

    process {
        try {
            $ast = [System.Management.Automation.Language.Parser]::ParseFile($Path, [ref]$null, [ref]$null)
            $functionName = $ast.FindAll({ $args[0] -is [System.Management.Automation.Language.FunctionDefinitionAst] }, $false) | ForEach-Object { $_.Name }
            return $functionName
        } catch {
            return ''
        }
    }
}
