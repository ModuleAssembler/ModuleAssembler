function Test-ExampleDescriptionLine {
    <#
    .SYNOPSIS
        Tests to determine if a line in a function's Example is the description or code.

    .DESCRIPTION
        Tests using Regex to determine if a line in a function's Example is the description or code.

    .PARAMETER Line
        The string to evaluate if it is a description or code.

    .EXAMPLE
        Example description
        Test-ExampleDescriptionLine -ParameterName "Value"
    #>

    [CmdletBinding()]
    param (
        [Parameter(
            Mandatory = $true,
            Position = 0)]
        [string] $Line
    )

    begin {
        $trimLine = $Line.Trim()

        if (-not $trimLine) {
            return $false
        }
    }

    process {
        # If it looks like a verb-noun cmdlet at start (Test-Cmdlet or Get-Item2) treat as code
        if ($trimLine -match '^[A-Za-z]+-[A-Za-z0-9]') {
            return $false
        }

        # Lines that start with common code characters are code
        if ($trimLine -match '^(?:\$|@|\{|\}|\(|\)|#|<|>|\.|\s{2,})') {
            return $false
        }

        # If it contains obvious code tokens (operators or splatting), treat as code
        if ($trimLine -match '(=|\@\{|\@\w+)') {
            return $false
        }
        # If the line starts with a code keyword (case-sensitive check), treat as code
        if ($trimLine -cmatch '^(?:param|function|for|foreach|if|switch|while)\b') {
            return $false
        }

        # Word count heuristic: single-word lines are likely code or headings; need at least two words for description
        $wordCount = ($trimLine -split '\s+').Count
        if ($wordCount -lt 2) {
            return $false
        }

        # If ends with punctuation it's very likely description
        if ($trimLine -match '[.!?]$') {
            return $true
        }

        # If starts with a capital letter it's likely description (covers sentences without final punctuation)
        if ($trimLine -match '^[A-Z]') {
            return $true
        }

        # If the line contains only letters, numbers, spaces and common punctuation and is reasonably long, treat as description
        if ($trimLine -match '^[\w\s"''\-:,/\\]+$' -and $wordCount -ge 3) {
            return $true
        }

        return $false
    }

    end {
        # Cleanup code
    }
}
