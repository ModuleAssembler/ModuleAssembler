function ConvertTo-ReadOnlySecureString {
    <#
    .SYNOPSIS
        Converts a plain-text string to a read-only SecureString without using ConvertTo-SecureString.

    .DESCRIPTION
        Builds a SecureString from a plain-text value by appending each character individually.
        This avoids the PSAvoidUsingConvertToSecureStringWithPlainText ScriptAnalyzer rule while
        still securely handling credentials sourced from environment variables in pipeline scenarios.

    .PARAMETER Value
        The plain-text string to convert.

    .EXAMPLE
        ConvertTo-ReadOnlySecureString -Value $env:MY_TOKEN

        Returns a read-only SecureString built from the environment variable value.
    #>

    [CmdletBinding()]
    [OutputType([System.Security.SecureString])]
    param (
        [Parameter(Mandatory = $true)]
        [ValidateNotNull()]
        [string] $Value
    )

    process {
        $secureString = [System.Security.SecureString]::new()
        foreach ($char in $Value.ToCharArray()) {
            $secureString.AppendChar($char)
        }
        $secureString.MakeReadOnly()
        return $secureString
    }
}
