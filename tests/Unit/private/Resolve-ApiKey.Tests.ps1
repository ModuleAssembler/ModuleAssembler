BeforeAll {
    $script:projectRoot = Split-Path -Path (Split-Path -Path (Split-Path -Path $PSScriptRoot -Parent) -Parent) -Parent
    . (Join-Path -Path $script:projectRoot -ChildPath 'src/private/ConvertTo-ReadOnlySecureString.ps1')
    . (Join-Path -Path $script:projectRoot -ChildPath 'src/private/Resolve-ApiKey.ps1')

    function ConvertTo-TestSecureString {
        param(
            [Parameter(Mandatory)]
            [string]$Value
        )

        $secureString = [System.Security.SecureString]::new()
        foreach ($character in $Value.ToCharArray()) {
            $secureString.AppendChar($character)
        }
        $secureString.MakeReadOnly()
        return $secureString
    }
}

Describe 'Resolve-ApiKey' -Tag 'Unit' {
    AfterAll {
        Remove-Item -Path Function:\ConvertTo-TestSecureString -ErrorAction SilentlyContinue
    }

    It 'returns the bound key when provided and does not convert env var text' {
        $boundKey = ConvertTo-TestSecureString -Value 'bound-token'
        Mock ConvertTo-ReadOnlySecureString { throw 'should not be called' }

        $result = Resolve-ApiKey -BoundKey $boundKey -EnvVarValue 'env-token' -ErrorMessage 'missing'

        $result | Should-Be $boundKey
        Should-Invoke ConvertTo-ReadOnlySecureString -Exactly 0
    }

    It 'converts env var text when bound key is not provided' {
        $converted = ConvertTo-TestSecureString -Value 'converted-token'
        Mock ConvertTo-ReadOnlySecureString { $converted } -ParameterFilter { $Value -eq 'env-token' }

        $result = Resolve-ApiKey -EnvVarValue 'env-token' -ErrorMessage 'missing'

        $result | Should-Be $converted
        Should-Invoke ConvertTo-ReadOnlySecureString -Exactly 1 -ParameterFilter { $Value -eq 'env-token' }
    }

    It 'throws the provided error message when no key source is available' {
        { Resolve-ApiKey -ErrorMessage 'No API key provided.' } | Should-Throw -ExceptionMessage 'No API key provided.'
    }
}
