function Test-JsonSchema {
    <#
    .SYNOPSIS
        Test JSON against a specified schema.

    .DESCRIPTION
        Test the validity of JSON against a set of permitted schema.

    .PARAMETER Schema
        Parameter description

    .EXAMPLE
        Test the JSON using the Build schema.
        Test-JsonSchema -Schema Build

    .EXAMPLE
        Test the JSON using the Pester schema.
        Test-JsonSchema -Schema Pester
    #>

    [CmdletBinding()]
    param (
        [Parameter(
            Mandatory = $true,
            Position = 0)]
        [ValidateSet('Build', 'Pester')]
        [string] $Schema
    )

    begin {
        # Initialization code
    }

    process {
        Write-Verbose "Running Schema test against JSON using $Schema schema."
        $SchemaPath = @{
            Build  = [System.IO.Path]::Combine($PSScriptRoot, 'resources', 'schema', 'moduleassembler-data.schema.json')
            Pester = [System.IO.Path]::Combine($PSScriptRoot, 'resources', 'Schema-Pester.json')
        }
        $result = switch ($Schema) {
            'Build' {
                Test-Json -Path 'moduleproject.madata.json' -Schema (Get-Content $SchemaPath.Build -Raw) -ErrorAction Stop
            }
            'Pester' {
                Test-Json -Path 'moduleproject.madata.json' -Schema (Get-Content $SchemaPath.Pester -Raw) -ErrorAction Stop
            }
            default {
                $false
            }
        }
        return $result
    }

    end {
        # Cleanup code
    }
}
