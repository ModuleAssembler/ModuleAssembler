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
        Write-Verbose 'Fetching ModuleAssembler schema.'
        $schemaUrl = "https://raw.githubusercontent.com/ModuleAssembler/ModuleAssembler/refs/heads/main/src/resources/schema/$($SchemaVersion)/moduleassembler.schema.json"

        try {
            $schemaContent = (Invoke-WebRequest -UseBasicParsing -Uri $schemaUrl -ErrorAction Stop).Content
        } catch {
            throw "Failed to download the schema from $($schemaUrl): $_"
        }

        Write-Verbose 'Running Schema Validation against moduleproject.json using ModuleAssembler schema.'
        $result = Test-Json -Path $data.ProjectJSON -Schema $schemaContent -ErrorAction Stop

        Write-Verbose "Is moduleproject.json passing validation: $result"
        return $result
    }

    end {
        # Cleanup code
    }
}
