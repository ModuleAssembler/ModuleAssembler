---
applyTo: '**/*.ps1,**/*.psm1'
description: 'PowerShell cmdlet and scripting best practices based on Microsoft guidelines'
---

# PowerShell Cmdlet Development Guidelines

This guide provides PowerShell-specific instructions to help GitHub Copilot generate idiomatic,
safe, and maintainable scripts. It aligns with Microsoft’s PowerShell cmdlet development guidelines.

## Naming Conventions

- **Verb-Noun Format:**
  - Use approved PowerShell verbs (Get-Verb)
  - Use singular nouns
  - PascalCase for both verb and noun
  - Avoid special characters and spaces

- **Approved Verbs:**
  - Use only PowerShell-approved verbs from `Get-Verb`
  - Approved verbs ensure consistency across the PowerShell ecosystem
  - Use the most specific verb available (e.g., `Set-` for modification, `New-` for creation)
  - Avoid custom verbs unless absolutely necessary
  - Document any non-standard verbs with justification

- **Parameter Names:**
  - Use PascalCase
  - Choose clear, descriptive names
  - Use singular form unless always multiple
  - Follow PowerShell standard names (e.g., `Name` for name of an object, `Path` for location of files or directories, `Credential` for a PSCredeintial object)

- **Variable Names:**
  - Use **PascalCase** for public variables
  - Use **camelCase** for private variables
  - Avoid abbreviations
  - Use meaningful names

- **Alias Avoidance:**
  - Use full cmdlet names
  - Avoid using aliases in scripts (e.g., use `Get-ChildItem` instead of `gci`)
  - Document any custom aliases
  - Use full parameter names

### Example - Naming Conventions

```powershell
function Get-UserProfile {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [string]$Username,

        [Parameter()]
        [ValidateSet('Basic', 'Detailed')]
        [string]$ProfileType = 'Basic'
    )

    process {
        $outputString = "Searching for: '$($Username)'"
        Write-Verbose -Message $outputString
        Write-Verbose -Message "Profile type: $ProfileType"
        # Logic here
    }
}
```

## Parameter Design

- **Standard Parameters:**
  - Use common parameter names (`Path`, `Name`, `Force`)
  - Follow built-in cmdlet conventions
  - Use aliases for specialized terms
  - Document parameter purpose

- **Parameter Names:**
  - Use singular form unless always multiple
  - Choose clear, descriptive names
  - Follow PowerShell conventions
  - Use PascalCase formatting

- **Type Selection:**
  - Use common .NET types
  - Implement proper validation
  - Consider ValidateSet for limited options
  - Enable tab completion where possible

- **Switch Parameters:**
  - **ALWAYS** use `[switch]` for boolean flags, never `[bool]`
  - **NEVER** use `[bool]$Parameter` or assign default values
  - Switch parameters default to `$false` when omitted
  - Use clear, action-oriented names
  - Test presence with `.IsPresent`
  - Using `$true`/`$false` in parameter attributes (e.g., `Mandatory = $true`) is acceptable

- **Parameter Validation:**
  - Use `[ValidateNotNullOrEmpty()]` to ensure required data
  - Use `[ValidateScript()]` for complex validation logic
  - Use `[ValidateRange()]` for numeric constraints
  - Use `[ValidateLength()]` for string length constraints
  - Use `[ValidatePattern()]` for regex pattern matching
  - Use `[ValidateSet()]` for predefined options
  - Provide clear error messages in validation logic

- **Positional Parameters:**
  - Limit positional parameters to the most commonly used parameter
  - Use `Position = 0` for the primary parameter
  - Use `Position = 1` only for secondary parameters in common scenarios
  - Always provide parameter names for clarity in scripts
  - Document positional parameter behavior in comment-based help

- **Credential Parameters:**
  - Use `[System.Management.Automation.PSCredential]` type for credentials
  - Use `-Credential` as standard parameter name
  - Never log or display credential values
  - Implement `Get-Credential` prompting when credentials are required

- **Advanced Parameter Patterns:**
  - Use `ValueFromRemainingArguments` for variadic parameters (accepting multiple values)
  - Declare as array type: `[string[]]$Values` with `ValueFromRemainingArguments = $true`
  - Useful for parameters accepting arbitrary lists of items
  - Always document expected number and type of values

- **OutputType Attribute:**
  - Declare `[OutputType()]` attribute on functions that return objects
  - Specify the .NET type(s) returned by the function
  - Enables IntelliSense and assists tooling (e.g., tab completion, static analysis)
  - ⚠️ `[OutputType()]` is **metadata only** — PowerShell does not enforce the declared
    type at runtime; actual output type is the developer's responsibility
  - Example: `[OutputType([System.Management.Automation.PSCustomObject])]`
  - Use multiple `[OutputType()]` attributes if function returns different types conditionally

### Example - Parameter Design

```powershell
function Set-ResourceConfiguration {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [string]$Name,

        [Parameter()]
        [ValidateSet('Dev', 'Test', 'Prod')]
        [string]$Environment = 'Dev',

        # ✔️ CORRECT: Use `[switch]` with no default value
        [Parameter()]
        [switch]$Force,

        # ❌ WRONG: Never assign default values to [switch] parameters.
        # Switch parameters are always $false when omitted; assigning a default defeats their purpose
        # and creates confusing behavior for callers.
        [Parameter()]
        [switch]$Quiet = [switch]$true,

        [Parameter()]
        [ValidateNotNullOrEmpty()]
        [string[]]$Tags
    )

    process {
        # Use .IsPresent to check switch state
        if ($Quiet.IsPresent) {
            Write-Verbose 'Quiet mode enabled'
        }
    }
}
```

## Pipeline and Output

- **Pipeline Input:**
  - Use `ValueFromPipeline` for direct object input
  - Use `ValueFromPipelineByPropertyName` for property mapping
  - Implement Begin/Process/End blocks for pipeline handling
  - Document pipeline input requirements

- **Output Objects:**
  - Return rich objects, not formatted text
  - Use PSCustomObject for structured data
  - Avoid Write-Host for data output
  - Enable downstream cmdlet processing

- **Output Type Consistency:**
  - Return consistent object types from a function
  - Avoid returning different types based on conditions (use properties instead)
  - Wrap scalar values in custom objects for pipeline consistency
  - Use `[PSTypeName()]` attribute to add custom type names for deserialization
  - Enable custom formatting via `.ps1xml` files for complex types

- **Pipeline Streaming:**
  - Output one object at a time
  - Use process block for streaming
  - Avoid collecting large arrays
  - Enable immediate processing

- **PassThru Pattern:**
  - Default to no output for action cmdlets
  - Implement `-PassThru` switch for object return
  - Return modified/created object with `-PassThru`
  - Use verbose/warning for status updates

### Example - Pipeline and Output

```powershell
function Update-ResourceStatus {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory, ValueFromPipeline, ValueFromPipelineByPropertyName)]
        [string]$Name,

        [Parameter(Mandatory)]
        [ValidateSet('Active', 'Inactive', 'Maintenance')]
        [string]$Status,

        [Parameter()]
        [switch]$PassThru
    )

    begin {
        Write-Verbose 'Starting resource status update process'
        $timestamp = Get-Date
    }

    process {
        # Process each resource individually
        Write-Verbose "Processing resource: $Name"

        $resource = [PSCustomObject]@{
            Name        = $Name
            Status      = $Status
            LastUpdated = $timestamp
            UpdatedBy   = "$($env:USERNAME)"
        }

        # Only output if PassThru is specified
        if ($PassThru.IsPresent) {
            Write-Output $resource
        }
    }

    end {
        Write-Verbose 'Resource status update process completed'
    }
}
```

## Error Handling and Safety

- **ShouldProcess Implementation:**
  - Use `[CmdletBinding(SupportsShouldProcess = $true)]`
  - Set appropriate `ConfirmImpact` level based on operation severity:
    - `'Low'` — minor, easily reversible changes (e.g., reading/refreshing cache)
    - `'Medium'` — default level; moderate changes (e.g., modifying a file or setting)
    - `'High'` — destructive or irreversible changes (e.g., deleting accounts or data)
    - PowerShell automatically prompts for confirmation when `ConfirmImpact` meets or exceeds `$ConfirmPreference`
    - The default value of `$ConfirmPreference` is `'High'`, meaning only `ConfirmImpact = 'High'` triggers automatic prompts out of the box
    - To trigger prompts for `'Medium'` operations, the user must set `$ConfirmPreference = 'Medium'` or pass `-Confirm` explicitly
  - Call `$PSCmdlet.ShouldProcess()` as close the the changes action
  - Use `$PSCmdlet.ShouldContinue()` for secondary confirmation on high-impact operations
    - ⚠️ `ShouldContinue()` is **not** suppressed by `-WhatIf`; it always prompts unless guarded
    - Always guard `ShouldContinue()` with a `-Force` switch to allow unattended/automation bypass
    - The pattern `if ($Force -or $PSCmdlet.ShouldContinue(...))` is the recommended approach

- **Message Streams:**
  - `Write-Verbose` for operational details with `-Verbose`
  - `Write-Warning` for warning conditions
  - `Write-Error` for non-terminating errors
  - `throw` for terminating errors
  - Avoid `Write-Host` except for user interface text

- **Error Handling Pattern:**
  - Use try/catch blocks for error management
  - Set appropriate ErrorAction preferences
  - Return meaningful error messages
  - Use ErrorVariable when needed
  - Include proper terminating vs non-terminating error handling
  - In advanced functions with `[CmdletBinding()]`, prefer `$PSCmdlet.WriteError()` over `Write-Error`
    - `Write-Error` attributes the error to the internal function scope, not the caller
    - `$PSCmdlet.WriteError()` correctly attributes the error to the calling scope, improving debuggability
  - In advanced functions with `[CmdletBinding()]`, prefer `$PSCmdlet.ThrowTerminatingError()` over `throw`
    - `throw` produces a script-terminating error; `ThrowTerminatingError()` produces a
      cmdlet-terminating error that respects the pipeline and caller's error handling
  - Construct proper ErrorRecord objects with category, target, and exception details

- **Non-Interactive Design:**
  - Accept input via parameters
  - Avoid `Read-Host` in scripts
  - Support automation scenarios
  - Document all required inputs

- **Preference Variable Management:**
  - Save original `$ErrorActionPreference` in `begin` block
  - Set to `'Stop'` for try/catch effectiveness
  - Restore original value in `end` block (even on error)
  - Use `$VerbosePreference` to control verbose output
  - Use `$WarningPreference` to control warning display
  - Use `$ProgressPreference = 'SilentlyContinue'` to suppress progress bars in scripts
  - Document any preference variable changes in comments

- **Terminating vs Non-Terminating Errors:**
  - Use **terminating errors** (`throw` or `$PSCmdlet.ThrowTerminatingError()`) for conditions that prevent function continuation
  - Use **non-terminating errors** (`$PSCmdlet.WriteError()`) to report errors while allowing processing to continue
  - Terminating errors stop the pipeline; non-terminating errors allow the pipeline to process remaining items
  - Document expected error scenarios in comment-based help
  - Non-terminating errors are preferred for cmdlets processing multiple items

- **Common Parameters Support:**
  - Use `[CmdletBinding()]` to automatically support common parameters:
    - `-Verbose` / `-VerbosePreference`
    - `-Debug` / `-DebugPreference`
    - `-ErrorAction` / `-ErrorActionPreference`
    - `-WarningAction` / `-WarningPreference`
    - `-InformationAction` / `-InformationPreference`
    - `-OutVariable`, `-OutBuffer`, `-PipelineVariable`
  - These parameters are automatically available in advanced functions
  - Respect user-provided preferences over script defaults

### Example - Error Handling and Safety

```powershell
function Remove-CacheFiles {
    [CmdletBinding(SupportsShouldProcess, ConfirmImpact = 'High')]
    param(
        [Parameter(Mandatory)]
        [string]$Path
    )

    try {
        $files = Get-ChildItem -Path $Path -Filter "*.cache" -ErrorAction Stop

        # Demonstrates WhatIf support
        if ($PSCmdlet.ShouldProcess($Path, 'Remove cache files')) {
            $files | Remove-Item -Force -ErrorAction Stop
            Write-Verbose "Removed $($files.Count) cache files from $Path"
        }
    } catch {
        $errorRecord = [System.Management.Automation.ErrorRecord]::new(
            $_.Exception,
            'RemovalFailed',
            [System.Management.Automation.ErrorCategory]::NotSpecified,
            $Path
        )
        $PSCmdlet.WriteError($errorRecord)
    }
}
```

## Logging and Telemetry

- **Write-Information Stream:**
  - Use `Write-Information` for informational messages intended for end users
  - Use `-InformationAction` to control behavior
  - Distinct from verbose output; not controlled by `-Verbose`
  - Preferred for user-facing status messages

- **Write-Debug Stream:**
  - Use `Write-Debug` for diagnostic information for script developers
  - Enable with `-Debug` or `$DebugPreference = 'Continue'`
  - Include detailed variable state and decision logic
  - Use `$PSCmdlet.GetVariableValue()` to access caller's scope variables

- **Avoiding Write-Host:**
  - Never use `Write-Host` in advanced functions or cmdlets
  - `Write-Host` cannot be captured, piped, or redirected
  - Use appropriate output streams: `Write-Output`, `Write-Verbose`, `Write-Warning`, `Write-Information`
  - Use `Write-Host` only for simple interactive scripts without piping requirements

## Documentation and Style

- **Comment-Based Help:** Include comment-based help for any public-facing function or cmdlet. Inside the function, add a `<# ... #>` help comment with at least:
  - `.SYNOPSIS` Brief description (one line)
  - `.DESCRIPTION` Detailed explanation (1-3 paragraphs)
  - `.PARAMETER` descriptions for each parameter
  - `.EXAMPLE` sections with practical usage (at least one)
  - `.OUTPUTS` Type of output returned
  - `.INPUTS` Type of input accepted

  - **Help Format Details:**
    - `.EXAMPLE` — Provide a code example followed by a blank line and a description of what the example does
    - `.OUTPUTS` — Specify the .NET type on the first line, followed by a blank line and a description of the output
    - `.INPUTS` — Specify the .NET type on the first line, followed by a blank line and a description of accepted input
    - This format ensures compatibility with `Get-Help` cmdlet display and enables proper documentation parsing
    - Example:
      ```powershell
      .EXAMPLE
          Get-UserComputerName

          Gets the name of the user's computer.

      .OUTPUTS
          System.String

          A string containing the name of the computer.

      .INPUTS
          None

          This cmdlet does not accept pipeline input.
      ```

- **Consistent Formatting:**
  - **Follow OTBS (One True Brace Style)** — the PowerShell community standard
    - Opening braces on the same line as the statement
    - Closing braces on their own line
    - New line after opening brace
    - New line after closing brace
  - Use proper indentation (4 spaces recommended)
  - Opening braces on same line as statement
  - Closing braces on new line
  - Use line breaks after pipeline operators
  - Pipeline indentation style: place the `|` operator at the **end of the line** and indent
    continuation lines by one level
    - Single-stage pipelines (one `|`) may remain on one line when readable
    - Example of multi-stage pipeline formatting:
      ```powershell
      $results = Get-ChildItem -Path $Path |
          Where-Object { $_.Extension -eq '.log' } |
          Sort-Object -Property LastWriteTime |
          Select-Object -First 10
      ```
  - One-liner blocks are acceptable only for simple, single-statement operations with immediate clarity. Multi-line format is required for complex logic or nested structures.
  - Prefer single quotes for strings that do not require interpolation or variable expansion
    - Double quotes are only appropriate when the string contains variables (`"Hello, $Name"`)
    or escape sequences (`` `n ``, `` `t ``)
  - Parameters must have whitespace between them
  - PascalCase for function and parameter names
  - Avoid unnecessary whitespace
  - Align property-value pairs in hashtables and `[PSCustomObject]` definitions:
    - Example:
      ```powershell
      $resource = [PSCustomObject]@{
          Name        = $Name
          Status      = $Status
          LastUpdated = $timestamp
      }
      ```

- **Code Organization:**
  - Use `#Requires` statements at the top of scripts to declare dependencies:
    - `#Requires -Version 5.1` — minimum PowerShell version required
    - `#Requires -Modules ModuleName` — required module(s) must be available
    - `#Requires -RunAsAdministrator` — script must run with elevated privileges
    - `#Requires` causes the script to fail with a clear message if requirements are not met
    - Multiple directives **can be combined on a single line**:
      ```powershell
      #Requires -Version 5.1 -Modules ActiveDirectory, SqlServer -RunAsAdministrator
      ```
    - Multiple `#Requires` lines are also valid and may improve readability:
      ```powershell
      #Requires -Version 5.1
      #Requires -Modules ActiveDirectory, SqlServer
      #Requires -RunAsAdministrator
      ```
    - `#Requires` statements are valid anywhere in a script but convention is at the top,
      before any code
  - Use `#region` and `#endregion` to organize large files
  - Structure: parameters, validation, initialization, processing, cleanup
  - Keep functions focused and under 100 lines when possible
  - Group related helper functions together
  - Place private functions before public functions, so they are available when public functions reference them

- **Pipeline Support:**
  - Implement Begin/Process/End blocks for pipeline functions
  - Use ValueFromPipeline where appropriate
  - Support pipeline input by property name
  - Return proper objects, not formatted text

- **Avoid Aliases:** Use full cmdlet names and parameters
  - Avoid using aliases in scripts (e.g., use Get-ChildItem instead of gci); aliases are acceptable for interactive shell use.
  - Use `Where-Object` instead of `?` or `where`
  - Use `ForEach-Object` instead of `%`
  - Use `Get-ChildItem` instead of `ls` or `dir`

- **Performance Considerations:**
  - Avoid string concatenation in loops; use `[System.Text.StringBuilder]` or `-join` operator
  - Use `Where-Object -FilterScript` with script blocks for efficient filtering
  - Avoid unnecessary pipeline operations; combine operations where possible
  - Initialize large collections with `@()` or `[System.Collections.Generic.List[T]]`
  - Avoid repeated property access in loops; cache values in variables
  - Use `-ErrorAction SilentlyContinue` judiciously; prefer explicit error handling
  - Profile code for performance bottlenecks before optimization

- **Internationalization and Culture:**
  - Use `[System.Globalization.CultureInfo]::InvariantCulture` for string comparisons and operations
  - Avoid culture-dependent operations for automation and scripting
  - Use `-CaseSensitive` parameter explicitly where appropriate
  - Document any locale-specific behavior

- **Return Values and Script Exit Codes:**
  - Prefer **implicit output** for normal returns — it is idiomatic PowerShell; any value written
    to the pipeline inside a function is automatically returned
  - Use explicit `return` statements for **early exits** and **flow control**, not as a default pattern
  - Use `return <value>` when you want to make intent explicit or prevent accidental pipeline output
  - Avoid mixing implicit output and `Write-Output` unnecessarily — it can confuse readers
  - Avoid using `return` for every function like C# or Java — it is not required in PowerShell
  - Return `$null` explicitly when a function produces no output object and early exit is needed
  - Set proper exit codes for script automation (`exit 0` for success, non-zero for failure)
  - Document expected return types in comment-based help `.OUTPUTS` section

---

## Full Example: End-to-End Cmdlet Pattern

```powershell
function Remove-UserAccount {
    [CmdletBinding(SupportsShouldProcess = $true, ConfirmImpact = 'High')]
    param(
        [Parameter(Mandatory, ValueFromPipeline)]
        [ValidateNotNullOrEmpty()]
        [string]$Username,

        [Parameter()]
        [switch]$Force
    )

    begin {
        Write-Verbose 'Starting user account removal process'
        $currentErrorActionValue = $ErrorActionPreference
        $currentProgressValue = $ProgressPreference
        $ErrorActionPreference = 'Stop'
        $ProgressPreference = 'SilentlyContinue'
    }

    process {
        try {
            # Validation
            if (-not (Test-UserExists -Username $Username)) {
                $errorRecord = [System.Management.Automation.ErrorRecord]::new(
                    [System.Exception]::new("User account '$Username' not found"),
                    'UserNotFound',
                    [System.Management.Automation.ErrorCategory]::ObjectNotFound,
                    $Username
                )
                $PSCmdlet.WriteError($errorRecord)
                return
            }

            # ShouldProcess enables -WhatIf and -Confirm support
            if ($PSCmdlet.ShouldProcess($Username, 'Remove user account')) {
                # ShouldContinue provides an additional confirmation prompt for high-impact operations
                # This prompt is bypassed when -Force is specified
                if ($Force -or $PSCmdlet.ShouldContinue("Are you sure you want to remove '$Username'?", "Confirm Removal")) {
                    Write-Verbose "Removing user account: $Username"

                    # Main operation
                    Remove-ADUser -Identity $Username -ErrorAction Stop
                    Write-Warning "User account '$Username' has been removed"
                }
            }
        } catch [Microsoft.ActiveDirectory.Management.ADException] {
            $errorRecord = [System.Management.Automation.ErrorRecord]::new(
                $_.Exception,
                'ActiveDirectoryError',
                [System.Management.Automation.ErrorCategory]::NotSpecified,
                $Username
            )
            $PSCmdlet.ThrowTerminatingError($errorRecord)
        } catch {
            $errorRecord = [System.Management.Automation.ErrorRecord]::new(
                $_.Exception,
                'UnexpectedError',
                [System.Management.Automation.ErrorCategory]::NotSpecified,
                $Username
            )
            $PSCmdlet.ThrowTerminatingError($errorRecord)
        }
    }

    end {
        Write-Verbose 'User account removal process completed'
        # Restore preference variables to their original values
        $ErrorActionPreference = $currentErrorActionValue
        $ProgressPreference = $currentProgressValue
    }
}
```

---

## Performance Example: String Building and Collections

```powershell
# ❌ INEFFICIENT: String concatenation in loop (creates new string each iteration)
$result = ''
foreach ($item in $largeCollection) {
    $result += "Item: $item`n"
}

# ✔️ EFFICIENT: Use -join operator (Join-String requires PowerShell 6.2+)
$result = $largeCollection | ForEach-Object { "Item: $_" } | Join-String -Separator "`n"

# ✔️ EFFICIENT: Use -join operator (compatible with PowerShell 5.1+)
$result = ($largeCollection | ForEach-Object { "Item: $_" }) -join "`n"

# ✔️ EFFICIENT: Use StringBuilder for complex operations
$stringBuilder = [System.Text.StringBuilder]::new()
foreach ($item in $largeCollection) {
    [void]$stringBuilder.AppendLine("Item: $item")
}
$result = $stringBuilder.ToString()

# ❌ INEFFICIENT: Accessing property repeatedly in loop
foreach ($user in $users) {
    $name = Get-UserDisplayName -UserId $user.Id
    $email = Get-UserEmail -UserId $user.Id
    Write-Output "$($user.Id): $name <$email>"
}

# ✔️ EFFICIENT: Cache property/method results
foreach ($user in $users) {
    $userId = $user.Id
    $name = Get-UserDisplayName -UserId $userId
    $email = Get-UserEmail -UserId $userId
    Write-Output "$userId`: $name <$email>"
}

# ✔️ EFFICIENT: Use List[T] for large collections
$userList = [System.Collections.Generic.List[PSObject]]::new()
foreach ($item in $sourceCollection) {
    $userList.Add($item)
}
```

## Additional Resources

- [Microsoft PowerShell Development Guidlines](https://learn.microsoft.com/en-us/powershell/scripting/developer/cmdlet/strongly-encouraged-development-guidelines)
- [PowerShell Best Practices](https://github.com/poshcode/powershellpracticeandstyle#the-powershell-best-practices-and-style-guide)

---

<!-- End of PowerShell Cmdlet Development Guidelines Instructions -->
