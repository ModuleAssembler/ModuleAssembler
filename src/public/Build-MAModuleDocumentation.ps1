function Build-MAModuleDocumentation {
    <#
    .SYNOPSIS
        Creates module help in Markdown, based on the Comment-based Help in the functions.

    .DESCRIPTION
        Generates Markdown help files for the module's public functions, from the Comment-based Help specified in each function.

    .EXAMPLE
        Create module Markdown documentation.
        Build-MAModuleDocumentationVerb
    #>

    [CmdletBinding()]
    param ()

    begin {
        $data = Get-MAProjectInfo
        $docsDir = Join-Path $data.ProjectRoot -ChildPath 'docs'

        Write-Verbose 'Initialize Docs directory.'
        if (Test-Path -Path $docsDir) {
            Remove-Item -Path $docsDir -Include '*.md' -Recurse -Force
        } else {
            New-Item -Path $docsDir -ItemType Directory -Force
        }
    }

    process {
        Write-Verbose 'Generating documentation...'

        # Import required modules
        Import-Module $data.ManifestFilePSD1 -Force
        Import-Module -Name Microsoft.PowerShell.PlatyPS -Force

        $moduleCommands = Get-Command -Module $data.ProjectName
        $moduleCommandHelp = @()

        foreach ($command in $moduleCommands) {
            Write-Verbose "Processing command: $($command.Name)"
            $commandHelp = New-CommandHelp $command

            $commandHelp.Examples | ForEach-Object {
                $example = $_
                $lines = $example.Remarks -split '\r\n|\n' | ForEach-Object { $_.Trim() } | Where-Object { $_ }

                $formattedLines = [System.Collections.ArrayList]::new()
                $codeBuffer = [System.Collections.ArrayList]::new()

                for ($i = 0; $i -lt $lines.Count; $i++) {
                    $line = $lines[$i]

                    # If this is a description line (heuristic), add it as text
                    if (Test-ExampleDescriptionLine $line) {
                        # If we were in a code block, flush it first
                        if ($codeBuffer.Count -gt 0) {
                            [void]$formattedLines.Add("``````powershell")
                            $formattedLines.AddRange($codeBuffer)
                            [void]$formattedLines.Add("``````")
                            $codeBuffer.Clear()
                        }
                        # Add description with proper spacing
                        if ($formattedLines.Count -gt 0 -and -not $formattedLines[-1].Equals('')) {
                            [void]$formattedLines.Add('')
                        }
                        [void]$formattedLines.Add($line)
                    }
                    # Otherwise treat it as code
                    else {
                        if ($formattedLines.Count -gt 0 -and -not $formattedLines[-1].Equals('')) {
                            [void]$formattedLines.Add('')
                        }
                        [void]$codeBuffer.Add($line)
                    }
                }

                # Flush any remaining code buffer
                if ($codeBuffer.Count -gt 0) {
                    [void]$formattedLines.Add("``````powershell")
                    $formattedLines.AddRange($codeBuffer)
                    [void]$formattedLines.Add("``````")
                }

                # Join everything with proper spacing
                $example.Remarks = $formattedLines -join [System.Environment]::NewLine
            }

            Export-MarkdownCommandHelp -CommandHelp $commandHelp -OutputFolder $docsDir
            $moduleCommandHelp += $commandHelp
        }

        # Generate module file
        $newMarkdownCommandHelpSplat = @{
            CommandHelp  = $moduleCommandHelp
            OutputFolder = $docsDir
            Force        = $true
        }
        New-MarkdownModuleFile @newMarkdownCommandHelpSplat

        Write-Verbose 'Documentation generation completed successfully'

        # Remove unwanted sections from generated markdown files
        # Define the section headers (case-insensitive) you want to remove from generated markdown files.
        # Example: @('ALIASES','RELATED LINKS')
        $SectionsToRemove = @('ALIASES')

        # Build a regex that matches any of the section names after the "##" header
        $escaped = $SectionsToRemove | ForEach-Object { [regex]::Escape($_) }
        $removeHeaderRegex = '^(?i)\s*##\s*(?:' + ($escaped -join '|') + ')\b'

        $mdFiles = Get-ChildItem -Path '.\docs' -Recurse -Filter '*.md' -File -ErrorAction SilentlyContinue
        foreach ($md in $mdFiles) {
            $path = $md.FullName
            Write-Verbose "Processing removal of sections ($($SectionsToRemove -join ', ')): $path"

            $inSection = $false
            $linesOut = New-Object System.Collections.Generic.List[string]
            Get-Content -Path $path | ForEach-Object {
                $line = $_

                if (-not $inSection -and $line -match $removeHeaderRegex) {
                    # start skipping lines until the next "## " header
                    $inSection = $true
                    return
                }

                if ($inSection -and $line -match '^\s*##\s+') {
                    # end skipping and emit this header line
                    $inSection = $false
                    [void]$linesOut.Add($line)
                    return
                }

                if (-not $inSection) {
                    [void]$linesOut.Add($line)
                }
            }

            Write-MarkdownFileContent -Path $path -Content ($linesOut -join [System.Environment]::NewLine)
        }

    }

    end {
        # Cleanup code
    }
}
