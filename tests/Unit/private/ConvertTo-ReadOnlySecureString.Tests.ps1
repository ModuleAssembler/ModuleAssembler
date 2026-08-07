BeforeAll {
    $script:projectRoot = Split-Path -Path (Split-Path -Path (Split-Path -Path $PSScriptRoot -Parent) -Parent) -Parent
    . (Join-Path -Path $script:projectRoot -ChildPath 'src/private/ConvertTo-ReadOnlySecureString.ps1')
}

Describe 'ConvertTo-ReadOnlySecureString' -Tag 'Unit' {
    It 'returns a read-only SecureString' {
        $result = ConvertTo-ReadOnlySecureString -Value 'token123'

        $result | Should-HaveType ([System.Security.SecureString])
        $result.IsReadOnly() | Should-BeTrue
    }

    It 'preserves the input text content when converted' {
        $secure = ConvertTo-ReadOnlySecureString -Value 'alpha42'

        $bstr = [System.Runtime.InteropServices.Marshal]::SecureStringToBSTR($secure)
        try {
            $plain = [System.Runtime.InteropServices.Marshal]::PtrToStringBSTR($bstr)
        } finally {
            [System.Runtime.InteropServices.Marshal]::ZeroFreeBSTR($bstr)
        }

        $plain | Should-Be 'alpha42'
    }
}
