---
applyTo: '**/*.Tests.ps1'
description: 'PowerShell Pester v6 testing best practices and conventions'
---

# PowerShell Pester v6 Testing Guidelines

This guide defines conventions for writing automated tests with Pester v6.
Follow [powershell.instructions.md](./powershell.instructions.md) for
general PowerShell style.

## File Naming and Structure

- **File convention:** Use `*.Tests.ps1`.
- **Placement:** Keep tests next to source files or in a dedicated `tests`
  folder.
- **Import pattern:** Dot-source scripts in `BeforeAll`.
- **No top-level runtime logic:** Keep setup and execution inside Pester
  blocks.

```powershell
BeforeAll {
    . "$PSScriptRoot\FunctionName.ps1"
}
```

## Version Guard

Use a fast-fail check to enforce Pester major version 6.

```powershell
BeforeAll {
    $pester = Get-Module Pester -ListAvailable |
        Sort-Object Version -Descending |
        Select-Object -First 1

    Should-Be $pester.Version.Major 6
}
```

Also ensure test runners use supported PowerShell versions for Pester v6
(`Windows PowerShell 5.1` or `PowerShell 7.4+`).

## Test Structure Hierarchy

```powershell
BeforeAll {
    # Import tested functions
}

Describe 'FunctionName' {
    Context 'When condition is true' {
        BeforeEach {
            # Setup
        }

        It 'Returns expected result' {
            # Arrange
            $input = 'value'

            # Act
            $result = FunctionName -Input $input

            # Assert
            Should-Be $result 'expected'
        }

        AfterEach {
            # Cleanup
        }
    }
}
```

## Core Keywords

- `Describe`: Top-level grouping, usually one function/feature.
- `Context`: Scenario grouping within `Describe`.
- `It`: Individual test case.
- `BeforeDiscovery`: Build test case data during discovery.
- `BeforeAll` / `AfterAll`: One-time setup/teardown per block.
- `BeforeEach` / `AfterEach`: Setup/teardown per test.

## Setup and Teardown

- Use `BeforeAll` for expensive shared setup.
- Use `BeforeEach` for isolated test setup.
- Use `AfterEach` / `AfterAll` for cleanup.
- Keep tests independent and repeatable.

## Discovery and Execution Rules (v6)

- Keep discovery side-effect free.
- Do not create external resources at top level.
- Use `BeforeDiscovery` for generating test case data only.
- Use `BeforeAll` / `BeforeEach` for runtime setup.

```powershell
BeforeDiscovery {
    $cases = @(
        @{ Input = 1; Expected = 2 }
        @{ Input = 2; Expected = 3 }
    )
}

Describe 'Add-One' {
    It 'Returns <Expected> for <Input>' -ForEach $cases {
        Should-Be (Add-One -Value $Input) $Expected
    }
}
```

## Assertions (Should / Should-*)

Pester v6 supports both styles:

- Classic operator style: `$actual | Should -Be $expected`
- Native command style: `$actual | Should-Be $expected`

For this repository, prefer **Should-\*** command style in tests.

### Common Should-* Assertions

- Equality: `Should-Be`, `Should-NotBe`
- Null and boolean: `Should-BeNull`, `Should-NotBeNull`, `Should-BeTrue`,
  `Should-BeFalse`, `Should-BeTruthy`, `Should-BeFalsy`
- Numeric: `Should-BeGreaterThan`, `Should-BeLessThan`,
  `Should-BeGreaterThanOrEqual`, `Should-BeLessThanOrEqual`
- Strings: `Should-BeString`, `Should-NotBeString`,
  `Should-BeLikeString`, `Should-NotBeLikeString`,
  `Should-MatchString`, `Should-NotMatchString`,
  `Should-BeEmptyString`, `Should-NotBeEmptyString`,
  `Should-NotBeWhiteSpaceString`
- Collections: `Should-BeCollection`, `Should-ContainCollection`,
  `Should-NotContainCollection`, `Should-All`, `Should-Any`
- Types and objects: `Should-HaveType`, `Should-NotHaveType`,
  `Should-BeEquivalent`, `Should-BeHashtable`
- Exceptions: `Should-Throw`
- Mocks: `Should-Invoke`, `Should-NotInvoke`

```powershell
# String assertions
$string | Should-MatchString 'pattern'
$string | Should-BeLikeString 'wildcardvalue *'
$string | Should-BeString 'expectedvalue'
$string.Length | Should-Be 5

# Collection assertions
$users = Get-UserInfo
$users | Should-ContainCollection 'AdminUser'

$array = 1, 2, 3, 4, 5
$array | Should-BeCollection -Count 5

# Exception assertions
{ Get-InvalidUser -ErrorAction Stop } | Should-Throw
```

### No-Throw Assertions In Native Should-* Style

`Should-*` has no `Should-NotThrow` command. Use explicit error capture:

```powershell
$caughtError = $null
try {
    Get-ValidUser -ErrorAction Stop | Out-Null
} catch {
    $caughtError = $_
}

$caughtError | Should-BeNull
```

### Pipeline vs. -Actual

Prefer `-Actual` when exact input shape matters (for example collection
type/shape checks) because PowerShell pipeline unwrapping can alter values.

### Custom Assertions

When needed, define custom `Should` operators with `New-ShouldOperator`.

```powershell
BeforeAll {
    $ShouldOperators = @{
        ValidPhoneFormat = @{
            Test = {
                param($ActualValue)
                $isValid = $ActualValue -match '^\d{3}-\d{3}-\d{4}$'
                @{
                    Succeeded = $isValid
                    FailureMessage = "Expected phone format XXX-XXX-XXXX but got '$ActualValue'"
                }
            }
        }
    }

    $ShouldOperators | New-ShouldOperator
}

It 'Validates phone number format' {
    '555-123-4567' | Should -ValidPhoneFormat
}
```

## Mocking

- `Mock CommandName { ScriptBlock }` replaces command behavior.
- Use `-ParameterFilter` to constrain a mock.
- Use `-Verifiable` when call verification is required.
- Use `Should-Invoke`, `Should-NotInvoke`, and
    `Should-Invoke -Verifiable` for mock-call checks.

```powershell
Mock Get-Service { [pscustomobject]@{ Status = 'Running' } } `
    -ParameterFilter { $Name -eq 'TestService' }

It 'Calls Get-Service once for TestService' {
    $null = Get-ServiceState -Name 'TestService'
    Should-Invoke Get-Service -Exactly 1 `
        -ParameterFilter { $Name -eq 'TestService' }
}
```

## Data-Driven Tests

Use `-ForEach` as the primary parameterization mechanism in v6.

```powershell
It 'Returns <Expected> for <Input>' -ForEach @(
    @{ Input = 'value1'; Expected = 'result1' }
    @{ Input = 'value2'; Expected = 'result2' }
) {
    $result = Get-Function -Input $Input
    Should-Be $result $Expected
}
```

### Notes

- `-ForEach` is available on `Describe`, `Context`, and `It`.
- `-TestCases` is supported, but `-ForEach` is preferred in v6.
- In v6, `$null` or empty `-ForEach` data throws by default. Use
    `-AllowNullOrEmptyForEach` where empty data is expected.
- Use `<PropertyName>` placeholders in test names.

## Isolation and Determinism

- Use `TestDrive:` for file-system tests.
- Save and restore environment variables in `BeforeEach` / `AfterEach`.
- Mock time, randomness, and external dependencies in unit tests.
- Avoid network or service dependencies in unit tests.

```powershell
It 'Writes output file in TestDrive' {
    $path = Join-Path TestDrive: 'out.txt'
    Set-Content -Path $path -Value 'ok'
    (Test-Path -Path $path) | Should-BeTrue
}
```

## Module and Private Function Testing

Use `Import-Module` and `InModuleScope` when testing module internals.

```powershell
BeforeAll {
    Import-Module "$PSScriptRoot\..\MyModule.psd1" -Force
}

Describe 'Convert-InternalValue' {
    InModuleScope MyModule {
        It 'Normalizes input' {
            $result = Convert-InternalValue -Input ' A '
            Should-Be $result 'A'
        }
    }
}
```

## Tags

- Tags are supported on `Describe`, `Context`, and `It`.
- Use filtering for selective runs.
- Tag tests that are not parallel-safe with `Serial`.

```powershell
Describe 'Function' -Tag 'Unit' {
    It 'Handles fast path' -Tag 'Fast' {
        Should-BeTrue $true
    }

    It 'Handles slow path' -Tag 'Slow', 'Integration', 'Serial' {
        Should-BeTrue $true
    }
}
```

## Skip

- Use `-Skip` for static or conditional exclusion.
- Use `Set-ItResult -Skipped` for runtime skip when needed.

```powershell
It 'Runs only on Windows' -Skip:(-not $IsWindows) {
    Should-BeTrue $IsWindows
}
```

## Parallel Safety

When `Run.Parallel = $true`:

- Do not share mutable global state across tests.
- Use unique temp paths and isolated data per test.
- Exclude `Serial`-tagged tests from parallel runs.

## Configuration

Define execution behavior outside test files with `New-PesterConfiguration`.

```powershell
$config = New-PesterConfiguration
$config.Run.Path = '.\Tests'
$config.Run.Exit = $true
$config.Run.Parallel = $true
$config.Filter.ExcludeTag = 'Serial'
$config.Output.Verbosity = 'Detailed'
$config.TestResult.Enabled = $true
$config.TestResult.OutputFormat = 'NUnitXml'
$config.TestResult.OutputPath = '.\artifacts\test-results.xml'
$config.CodeCoverage.Enabled = $true
$config.CodeCoverage.Path = '.\src\*.ps1'
$config.CodeCoverage.CoveragePercentTarget = 80
Invoke-Pester -Configuration $config
```

## Running Tests

### Basic execution

```powershell
Invoke-Pester
Invoke-Pester -Path '.\Tests\Get-UserInfo.Tests.ps1'
Invoke-Pester -Path '.\Tests'
```

### Filtered execution

```powershell
$config = New-PesterConfiguration
$config.Run.Path = '.\Tests'
$config.Filter.Tag = 'Unit'
$config.Filter.ExcludeTag = 'Slow', 'Serial'
Invoke-Pester -Configuration $config
```

### CI execution (Windows)

```powershell
pwsh -NoProfile -Command "$config = New-PesterConfiguration; $config.Run.Path = '.\Tests'; $config.Run.Exit = $true; $config.TestResult.Enabled = $true; $config.TestResult.OutputFormat = 'NUnitXml'; $config.TestResult.OutputPath = '.\artifacts\test-results.xml'; Invoke-Pester -Configuration $config"
```

### Exit codes

- `0`: All tests passed.
- `1`: One or more tests failed.

## Anti-Patterns (Do Not Use)

- Top-level setup with side effects.
- `Start-Sleep` in tests.
- Real network calls in unit tests.
- Order-dependent tests.
- Shared mutable state across `It` blocks.
- Assertions based only on unstable/localized message text.

## Example Test Pattern

```powershell
BeforeAll {
    . "$PSScriptRoot\Get-UserInfo.ps1"
}

Describe 'Get-UserInfo' -Tag 'Unit' {
    Context 'When user exists' {
        BeforeEach {
            Mock Get-ADUser {
                [pscustomobject]@{
                    Name = 'TestUser'
                    Enabled = $true
                }
            }
        }

        It 'Returns user object' {
            $result = Get-UserInfo -Username 'TestUser'
            $result | Should-NotBeNull
            $result.Name | Should-BeString 'TestUser'
            $result.Enabled | Should-BeTrue
        }

        It 'Calls Get-ADUser once' {
            $null = Get-UserInfo -Username 'TestUser'
            Should-Invoke Get-ADUser -Exactly 1
        }
    }

    Context 'When user does not exist' {
        BeforeEach {
            Mock Get-ADUser { throw 'User not found' }
        }

        It 'Throws not found error' {
            { Get-UserInfo -Username 'NonExistent' } | Should-Throw `
                -ExceptionMessage '*not found*'
        }
    }
}
```

---

<!-- End of PowerShell Pester v6 Testing Guidelines Instructions -->
