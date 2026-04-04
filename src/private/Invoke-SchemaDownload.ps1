function Invoke-SchemaDownload {
    <#
    .SYNOPSIS
        Downloads a ModuleAssembler JSON schema from the remote source.

    .DESCRIPTION
        Resolves the URL for the specified ModuleAssembler schema version and downloads the content
        with automatic retry on failure. Returns the raw schema content as a string.

    .PARAMETER SchemaVersion
        The version of the ModuleAssembler JSON schema to download.

    .EXAMPLE
        Invoke-SchemaDownload -SchemaVersion 'v1.0.0'

        Downloads the v1.0.0 ModuleAssembler schema and returns its content.
    #>

    [CmdletBinding()]
    [OutputType([string])]
    param (
        [Parameter(
            Mandatory = $true,
            Position = 0)]
        [ValidateSet('v1.0.0')]
        [string] $SchemaVersion
    )

    process {
        $schemaUrlTable = @{
            'v1.0.0' = 'https://raw.githubusercontent.com/ModuleAssembler/ModuleAssembler-Schema/refs/tags/v1.0.0/schema/moduleassembler.schema.json'
        }

        # Expected SHA-256 hashes of the UTF-8 encoded content served by the remote source.
        # Computed from: [System.Text.Encoding]::UTF8.GetBytes($content) after Invoke-WebRequest.
        $schemaHashTable = @{
            'v1.0.0' = '0347F330077694DB6B060CF1C7CFBB7BE7BD37F50672C50C48C2E4E78FB3DE3A'
        }

        if (-not $schemaUrlTable.ContainsKey($SchemaVersion)) {
            throw "No schema URL is defined for version '$SchemaVersion'."
        }

        $schemaUrl = $schemaUrlTable[$SchemaVersion]
        $expectedHash = $schemaHashTable[$SchemaVersion]
        $maxRetries = 3
        $retryDelay = 2

        for ($attempt = 1; $attempt -le $maxRetries; $attempt++) {
            try {
                $content = (Invoke-WebRequest -UseBasicParsing -Uri $schemaUrl -SslProtocol Tls12, Tls13 -TimeoutSec 30 -ErrorAction Stop).Content
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

        # Verify integrity of downloaded content against the known SHA-256 hash.
        # Normalise to LF before hashing so the result is identical across all platforms
        # regardless of any OS-level or PowerShell-version line-ending handling.
        $normalised = $content -replace '\r\n', "`n" -replace '\r', "`n"
        $contentBytes = [System.Text.Encoding]::UTF8.GetBytes($normalised)
        $sha256 = [System.Security.Cryptography.SHA256]::Create()
        try {
            $actualHash = [System.BitConverter]::ToString($sha256.ComputeHash($contentBytes)) -replace '-', ''
        } finally {
            $sha256.Dispose()
        }

        if ($actualHash -ne $expectedHash) {
            throw "Schema integrity check failed for '$SchemaVersion'. Expected SHA-256 '$expectedHash' but computed '$actualHash'. The downloaded content may be corrupt or tampered with. Aborting."
        }

        Write-Verbose "Schema '$SchemaVersion' passed integrity check."
        return $content
    }
}
