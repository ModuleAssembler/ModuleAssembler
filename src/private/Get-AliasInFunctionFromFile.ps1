function Get-AliasInFunctionFromFile {
    <#
    .SYNOPSIS
        Get any alias names for functions so they can be added to the module manifest.

    .DESCRIPTION
        Gather alias information from the Comment Based Help ALIAS section if present, so the alias information can be added to the module manifest.

    .PARAMETER Path
        Path to the function ps1 file.

    .EXAMPLE
        Gather alias names for the given function file.
        Get-AliasInFunctionFromFile -Path '.\Verb-Noun.ps1'

    .EXAMPLE
        Gather alias names for the given function file, using positional parameter.
        Get-AliasInFunctionFromFile '.\Verb-Noun.ps1'
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
            $ast = [System.Management.Automation.Language.Parser]::ParseFile($Path, [ref]$null, [ref]$null)

            $functionNodes = $ast.FindAll({
                    param($node)
                    $node -is [System.Management.Automation.Language.FunctionDefinitionAst]
                }, $true)

            $function = $functionNodes[0]
            $paramsAttributes = $function.Body.ParamBlock.Attributes

            $aliases = ($paramsAttributes | Where-Object { $_.TypeName -like 'Alias' } | ForEach-Object PositionalArguments).Value
            return $aliases
        } catch {
            return
        }
    }

    end {
        # Cleanup code
    }
}
