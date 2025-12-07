
function Get-FunctionNameFromFile {
    <#
    .SYNOPSIS
        Get function names to add to the module manifest.

    .DESCRIPTION
        Gather all function names from the ps1 files, so the information can be added to the module manifest.

    .PARAMETER Path
        Path to the function ps1 file.

    .EXAMPLE
        Gather function names for the given file.
        Get-FunctionNameFromFile -Path '.\Verb-Noun.ps1'

    .EXAMPLE
        Gather function names for the given file, using positional parameter.
        Get-FunctionNameFromFile '.\Verb-Noun.ps1'
    #>

    [CmdletBinding()]
    param (
        [Parameter(
            Mandatory = $true,
            Position = 0)]
        [ValidateNotNullOrEmpty()]
        [string] $Path
    )

    begin {
        # Initialization code
    }

    process {
        try {
            $moduleContent = Get-Content -Path $filePath -Raw
            $ast = [System.Management.Automation.Language.Parser]::ParseInput($moduleContent, [ref]$null, [ref]$null)
            $functionName = $ast.FindAll({ $args[0] -is [System.Management.Automation.Language.FunctionDefinitionAst] }, $false) | ForEach-Object { $_.Name }
            return $functionName
        } catch {
            return ''
        }
    }

    end {
        # Cleanup code
    }
}
