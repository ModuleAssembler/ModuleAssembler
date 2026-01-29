function Test-JsonSchema {
    <#
    .SYNOPSIS
        Test JSON against a specified schema.

    .DESCRIPTION
        Test the validity of JSON against a set of permitted schema.

    .PARAMETER SchemaVersion
        The version of the ModuleAssembler JSON schema to utilize for validation. Default is the latest vesion.

    .EXAMPLE
        Test the JSON using the latest ModuleAssembler schema.
        Test-JsonSchema

    .EXAMPLE
        Test-JsonSchema SchemaVersion 'v1.0.0'

        Test the JSON using a specific version of the ModuleAssembler schema.
    #>

    [CmdletBinding()]
    param (
        [Parameter(
            Mandatory = $false,
            Position = 0)]
        [ValidateSet('v1.0.0')]
        [string] $SchemaVersion = 'v1.0.0'
    )


    begin {
        $data = Get-MAProjectInfo
    }

    process {
        Write-Verbose 'Running Schema Validation against JSON using ModuleAssembler schema.'
        $SchemaPath = [System.IO.Path]::Combine($PSScriptRoot, 'resources', 'schema', $SchemaVersion , 'moduleassembler.schema.json')

        $result = Test-Json -Path $data.ProjectJSON -SchemaFile $SchemaPath -ErrorAction Stop

        return $result
    }

    end {
        # Cleanup code
    }
}
