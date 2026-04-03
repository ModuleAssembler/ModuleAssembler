function Test-JsonSchema {
    <#
    .SYNOPSIS
        Test JSON against a specified schema.

    .DESCRIPTION
        Test the validity of JSON against a set of permitted schema.

    .PARAMETER SchemaVersion
        The version of the ModuleAssembler JSON schema to utilize for validation. Default is the latest version.

    .EXAMPLE
        Test-JsonSchema

        Test the JSON using the latest ModuleAssembler schema.

    .EXAMPLE
        Test-JsonSchema -SchemaVersion 'v1.0.0'

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

        $schemaUrlTable = @{
            'v1.0.0' = 'https://raw.githubusercontent.com/ModuleAssembler/ModuleAssembler-Schema/refs/tags/v1.0.0/schema/moduleassembler.schema.json'
        }

        if (-not $schemaUrlTable.ContainsKey($SchemaVersion)) {
            throw "No schema URL is defined for version '$SchemaVersion'."
        }

        $schemaUrl = $schemaUrlTable[$SchemaVersion]
    }

    process {
        Write-Verbose 'Fetching ModuleAssembler schema.'
        $maxRetries = 3
        $retryDelay = 2
        $schemaContent = $null

        for ($attempt = 1; $attempt -le $maxRetries; $attempt++) {
            try {
                $schemaContent = (Invoke-WebRequest -UseBasicParsing -Uri $schemaUrl -SslProtocol Tls12, Tls13 -TimeoutSec 30 -ErrorAction Stop).Content
                break
            } catch {
                if ($attempt -eq $maxRetries) {
                    throw "Failed to download schema from '$schemaUrl' after $maxRetries attempts: $_"
                }
                Write-Verbose "Schema download attempt $attempt failed. Retrying in $retryDelay seconds..."
                Start-Sleep -Seconds $retryDelay
                $retryDelay *= 2
            }
        }

        if (-not ($schemaContent | Test-Json -ErrorAction SilentlyContinue)) {
            throw "Downloaded content from $($schemaUrl) is not valid JSON and cannot be used as a schema."
        }

        Write-Verbose 'Running Schema Validation against moduleproject.json using ModuleAssembler schema.'
        $result = Test-Json -Path $data.ProjectJSON -Schema $schemaContent -ErrorAction Stop

        Write-Verbose "Is moduleproject.json passing validation: $result"
        return $result
    }
}
