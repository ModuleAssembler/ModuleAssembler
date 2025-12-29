function Write-MarkdownFileContent {
    <#
    .SYNOPSIS
        Writes the provided content to a Markdown file in the given Path.

    .DESCRIPTION
        Writes the provided content to a Markdown file in the given Path, with automatic retry attempts.

    .PARAMETER Path
        Path where the Markdown file should be written.

     .PARAMETER Content
        Content to write to Markdown file.

     .PARAMETER MaxAttempts
        The maximum number of retry attempts.

     .PARAMETER BaseDelayMs
        The starting delay in Milliseconds between retry attempts.

    .EXAMPLE
        Example description
        Verb-Noun -ParameterName "Value"
    #>

    [CmdletBinding()]
    param (
        [Parameter(
            Mandatory = $true,
            Position = 0)]
        [ValidateNotNullOrEmpty()]
        [string] $Path,

        [Parameter(
            Mandatory = $true,
            Position = 1)]
        [ValidateNotNullOrEmpty()]
        [string] $Content,

        [Parameter(
            Mandatory = $false,
            Position = 2)]
        [int] $MaxAttempts = 6,

        [Parameter(
            Mandatory = $false,
            Position = 3)]
        [int] $BaseDelayMs = 250
    )

    begin {
        $dir = Split-Path -Path $Path
        $temp = Join-Path -Path $dir -ChildPath ('tmp-' + [guid]::NewGuid().ToString() + '.md')
    }

    process {
        $Content | Out-File -FilePath $temp -Encoding utf8 -Force

        $attempt = 0
        while ($true) {
            try {
                Move-Item -Path $temp -Destination $Path -Force -ErrorAction Stop
                break
            } catch {
                $attempt++
                if ($attempt -ge $MaxAttempts) {
                    Remove-Item -Path $temp -ErrorAction SilentlyContinue
                    throw "Failed to write file '$Path' after $MaxAttempts attempts. Last error: $($_.Exception.Message)"
                }
                Start-Sleep -Milliseconds ([int]($BaseDelayMs * [math]::Pow(2, $attempt)))
            }
        }
    }

    end {
        # Cleanup code
    }
}
