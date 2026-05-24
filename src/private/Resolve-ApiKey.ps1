function Resolve-ApiKey {
    <#
    .SYNOPSIS
        Resolves a SecureString API key from a bound parameter or an environment variable.

    .DESCRIPTION
        Returns the caller-supplied SecureString if provided, otherwise converts the given
        environment variable value to a SecureString via ConvertTo-ReadOnlySecureString.
        Throws a caller-supplied error message if neither source yields a value.

        This helper centralises the "bound parameter takes precedence over environment variable"
        pattern used by Publish-MAModule, eliminating duplication across parameter sets.

    .PARAMETER BoundKey
        The SecureString passed directly by the caller. When present, it is returned as-is.
        Pass $null or omit this parameter to indicate that no bound key was supplied.

    .PARAMETER EnvVarValue
        The raw plain-text value read from an environment variable (e.g. $env:PSGALLERY_API_KEY).
        Used only when BoundKey is $null or not supplied.

    .PARAMETER ErrorMessage
        The message passed to 'throw' when neither BoundKey nor EnvVarValue yields a usable key.

    .EXAMPLE
        Resolve-ApiKey -BoundKey $PSBoundParameters['PowerShellGalleryApiKey'] `
                       -EnvVarValue $env:PSGALLERY_API_KEY `
                       -ErrorMessage 'No API key provided. Supply -PowerShellGalleryApiKey or set $env:PSGALLERY_API_KEY.'

        Returns the caller-supplied SecureString if given, otherwise converts $env:PSGALLERY_API_KEY
        to a SecureString. Throws if neither is available.
    #>

    [CmdletBinding()]
    [OutputType([System.Security.SecureString])]
    param (
        [Parameter(Mandatory = $false)]
        [AllowNull()]
        [SecureString] $BoundKey,

        [Parameter(Mandatory = $false)]
        [AllowNull()]
        [AllowEmptyString()]
        [string] $EnvVarValue,

        [Parameter(Mandatory = $true)]
        [ValidateNotNullOrEmpty()]
        [string] $ErrorMessage
    )

    process {
        if ($null -ne $BoundKey) {
            return $BoundKey
        }
        if (-not [string]::IsNullOrEmpty($EnvVarValue)) {
            return ConvertTo-ReadOnlySecureString -Value $EnvVarValue
        }
        throw $ErrorMessage
    }
}
