BeforeAll {
    $script:projectRoot = Split-Path -Path (Split-Path -Path (Split-Path -Path $PSScriptRoot -Parent) -Parent) -Parent
    . (Join-Path -Path $script:projectRoot -ChildPath 'src/private/Test-DescriptionLine.ps1')
}

Describe 'Test-DescriptionLine' -Tag 'Unit' {
    It 'returns false for blank lines' {
        Test-DescriptionLine -Line '   ' | Should-BeFalse
    }

    It 'returns false for cmdlet-style code lines' {
        Test-DescriptionLine -Line 'Get-ChildItem -Path ./' | Should-BeFalse
    }

    It 'returns false for code-like variable assignment' {
        Test-DescriptionLine -Line '$name = "value"' | Should-BeFalse
    }

    It 'returns false for .NET type signatures' {
        Test-DescriptionLine -Line 'System.Management.Automation.PSCustomObject' | Should-BeFalse
    }

    It 'returns true for sentence-style descriptions with punctuation' {
        Test-DescriptionLine -Line 'This example creates a new module project.' | Should-BeTrue
    }

    It 'returns true for sentence-style descriptions without ending punctuation' {
        Test-DescriptionLine -Line 'This example updates the module version' | Should-BeTrue
    }
}
