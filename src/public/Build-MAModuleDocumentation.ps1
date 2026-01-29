function Build-MAModuleDocumentation {
    <#
    .SYNOPSIS
        Creates module documentation in Markdown, based on the Comment-based Help in the functions.

    .DESCRIPTION
        Generates Markdown documentation files for the module's public functions, from the Comment-based Help specified in each function.

    .EXAMPLE
        Build-MAModuleDocumentation

        Create module Markdown documentation.
    #>

    [CmdletBinding()]
    [Alias('MADocs')]
    param ()

    begin {
        Write-Verbose 'START: Generating documentation.'
        $data = Get-MAProjectInfo
        $docsDir = [System.IO.Path]::Combine($data.ProjectRoot, 'docs', $data.ProjectName)

        Write-Verbose 'Importing module.'
        try {
            Import-Module $data.ManifestFilePSD1 -Force -ErrorAction Stop
        } catch {
            throw "Import of the built module failed with message:  $($_.Exception.Message)"
        }

        Write-Verbose 'Initialize docs directory.'
        if (Test-Path -Path $docsDir) {
            Remove-Item -Path $docsDir -Include '*.md' -Recurse -Force | Out-Null
        } else {
            New-Item -Path $docsDir -ItemType Directory -Force | Out-Null
        }
    }

    process {
        $moduleCommands = Get-Command -Module $data.ProjectName

        foreach ($command in $moduleCommands) {
            Write-Verbose "Generating documentation for function $command."
            $helpContent = Get-Help $command -Full
            $commandContent = Get-Command -Name $command

            $fileContent = "# $($command)`n`n"

            # Validate the minimum required sections are present in the Comment-based Help.
            if (!($helpContent.synopsis)) {
                throw "The Comment-based Help for $($command) must contain a .SYNOPSIS section."
            }

            if (!($helpContent.description)) {
                throw "The Comment-based Help for $($command) must contain a .DESCRIPTION section."
            }

            if (!($helpContent.examples)) {
                throw "The Comment-based Help for $($command) must contain at least one .EXAMPLE section."
            }

            # Synopsis Section
            $fileContent += "## Synopsis`n`n"
            $fileContent += ($helpContent.synopsis | Out-String).Trim()
            $fileContent += "`n`n"

            # Syntax Section
            $syntax = Get-Command -Name $command -Syntax
            $formattedSyntax = $syntax -replace '(\s+\[)', "`n   `$1"

            $fileContent += "## Syntax`n`n"
            $fileContent += "``````powershell"
            $fileContent += $formattedSyntax
            $fileContent += "```````n`n"

            # Description Section
            $fileContent += "## Description`n`n"
            $fileContent += ($helpContent.description | Out-String).Trim()
            $fileContent += "`n"

            # Alias section
            $funcAlias = Get-Alias -Definition $command -ErrorAction SilentlyContinue
            if ($funcAlias) {
                $fileContent += "`n## Aliases`n`n"
                $fileContent += $funcAlias.Name -join ', '
                $fileContent += "`n"
            }

            # Examples Section
            $fileContent += "`n## Examples`n"

            foreach ($example in $helpContent.examples.example) {
                if (Test-DescriptionLine $example.code) {
                    throw "An example for $($command) has the description before the code, which does not follow the order required by Get-Help. Place the example code followed by the description on a new line, optionally with an empty line between the two."
                }

                $fileContent += "`n### " + (($example.title | Out-String).Replace('-', '')).Trim()
                $fileContent += "`n`n``````powershell`n"
                $fileContent += ($example.introduction | Out-String).Trim() + ' ' + ($example.code | Out-String).Trim()
                $fileContent += "`n```````n`n"
                $fileContent += ($example.remarks | Out-String).Trim() + "`n"
            }

            # Parameters Section
            if ($helpContent.Parameters -or $commandContent.CmdletBinding) {
                $fileContent += "`n## Parameters`n`n"

                foreach ($param in $helpContent.Parameters.parameter) {
                    $nameParam = ($param.name | Out-String).Trim()
                    $fileContent += '### -' + $nameParam + "`n`n"

                    $descriptionParm = ($param.description | Out-String).Trim()
                    if (-not [string]::IsNullOrEmpty($descriptionParm)) {
                        $fileContent += $descriptionParm + "`n`n"
                    }

                    $fileContent += "| Property | Value |`n"
                    $fileContent += "| --- | --- |`n"
                    $fileContent += "| Type | $(($param.parameterValue | Out-String).Trim()) |`n"
                    $fileContent += "| Required | $(($param.required | Out-String).Trim()) |`n"

                    $defaultValue = ($param.defaultValue | Out-String).Trim()
                    if ($defaultValue) {
                        $fileContent += "| Default Value | $($defaultValue) |`n"
                    }

                    $delimitedValidValues = $commandContent.Parameters.$($nameParam).Attributes.ValidValues -join ', '
                    if ($delimitedValidValues) {
                        $fileContent += "| Valid Values | $($delimitedValidValues) |`n"
                    }

                    $delimitedAlias = $commandContent.Parameters.$($nameParam).Aliases -join ', '
                    if ($delimitedAlias) {
                        $fileContent += "| Alias | $($delimitedAlias) |`n"
                    }

                    $fileContent += "| Accept Pipeline Input | $(($param.pipelineInput | Out-String).Trim()) |`n"
                    $fileContent += "| Accept Wildcards | $(($param.globbing | Out-String).Trim()) |`n"

                    $positionParam = ($param.position | Out-String).Trim()
                    if ($positionParam) {
                        $fileContent += "| Position | $($positionParam) |`n"
                    }
                    $fileContent += "`n"
                }

                if ($commandContent.CmdletBinding) {
                    $fileContent += "### \<CommonParameters\>`n`n"
                    $fileContent += "This cmdlet supports the common parameters: Verbose, Debug, ErrorAction, ErrorVariable, WarningAction, WarningVariable, OutBuffer, PipelineVariable, and OutVariable.`n`n"
                    $fileContent += "For more information, see about_CommonParameters [https://go.microsoft.com/fwlink/?LinkID=113216].`n"
                }
            }

            # Inputs Section

            # Outputs Section
            if ($helpContent.returnValues) {
                $fileContent += "`n## Outputs`n`n"
                $returnValueCount = @($helpContent.returnValues.returnValue).Count
                $currentIndex = 0

                foreach ($returnValue in $helpContent.returnValues.returnValue) {
                    $currentIndex++
                    $typeContent = ($returnValue.type.name | Out-String).Trim()
                    if ($typeContent) {
                        $lines = @($typeContent -split "`n" | ForEach-Object { $_.Trim() } | Where-Object { $_ -ne '' })

                        if ($lines.Count -gt 0) {
                            # First line is the type
                            if (Test-DescriptionLine $lines[0]) {
                                throw "An Output type for $($command) has the description before the type definition, which does not follow the order required. Place the type followed by the description on a new line, optionally with an empty line between the two."
                            }
                            $fileContent += '### ' + $lines[0]

                            # Remaining lines are the description
                            if ($lines.Count -gt 1) {
                                $fileContent += "`n`n" + ($lines[1..($lines.Count - 1)] -join "`n") + "`n"
                            } else {
                                $fileContent += "`n"
                            }

                            # Add blank line between outputs, but not after the last one
                            if ($currentIndex -lt $returnValueCount) {
                                $fileContent += "`n"
                            }
                        }
                    }
                }
            }

            # Notes Section
            if ($helpContent.alertSet) {
                $fileContent += "`n## Notes`n`n"
                $fileContent += ($helpContent.alertSet | Out-String).Trim() + "`n"
            }

            # Export to Markdown
            $mdFilePath = Join-Path $docsDir -ChildPath "$($command).md"
            $fileContent | Out-File -FilePath $mdFilePath -Encoding UTF8NoBOM -NoNewline
        }
    }

    end {
        Write-Verbose 'COMPLETE: Generating documentation.'
    }
}
