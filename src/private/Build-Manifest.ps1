function Build-Manifest {
    <#
    .SYNOPSIS
        Build the PowerShell module manifest psd1 file.

    .DESCRIPTION
        The required module data is gathered, validated, and used to create the module manifest file.

    .EXAMPLE
        Build-Manifest

        Execute the module manifest build.
    #>

    [CmdletBinding()]
    param ()

    begin {
        $data = Get-MAProjectInfo
        Write-Verbose 'START: Building Module Manifest.'
        if (!(Test-JsonSchema)) {
            throw 'The JSON in moduleproject.json did not pass validation.'
        }
    }

    process {
        $PubFunctionFiles = Get-ChildItem -Path $data.PublicDir -Filter *.ps1
        $functionToExport = @()
        $aliasToExport = @()
        $PubFunctionFiles.FullName | ForEach-Object {
            $functionToExport += Get-FunctionNameFromFile -Path $_
            $aliasToExport += Get-AliasInFunctionFromFile -Path $_
        }

        ## Import Formatting (if any)
        $FormatsToProcess = @()
        Get-ChildItem -Path $data.ResourcesDir -File -Filter '*.ps1xml' -ErrorAction SilentlyContinue | ForEach-Object {
            if ($data.CopyResourcesToModuleRoot) {
                $FormatsToProcess += $_.Name
            } else {
                $FormatsToProcess += Join-Path -Path 'resources' -ChildPath $_.Name
            }
        }

        $ManifestAllowedParams = (Get-Command New-ModuleManifest).Parameters.Keys
        $sv = [semver]$data.Version
        $ParmsManifest = @{
            Path              = $data.ManifestFilePSD1
            Description       = $data.Description
            FunctionsToExport = $functionToExport
            CmdletsToExport   = @()
            VariablesToExport = @()
            AliasesToExport   = $aliasToExport
            RootModule        = "$($data.ProjectName).psm1"
            ModuleVersion     = [version]$sv
            FormatsToProcess  = $FormatsToProcess
        }

        # Release label
        if ($sv.PreReleaseLabel) {
            $ParmsManifest['Prerelease'] = $sv.PreReleaseLabel
        }

        # Copyright
        if ([string]::IsNullOrEmpty($data.Manifest.CompanyName)) {
            $ParmsManifest['Copyright'] = "(c) $($data.Manifest.Author). All rights reserved."
        } else {
            $ParmsManifest['Copyright'] = "(c) $($data.Manifest.CompanyName). All rights reserved."
        }

        # Accept only valid Manifest Parameters
        $data.Manifest.Keys | ForEach-Object {
            if ( $ManifestAllowedParams -contains $_) {
                if ($data.Manifest.$_) {
                    $ParmsManifest.add($_, $data.Manifest.$_ )
                }
            } else {
                Write-Warning "Unknown parameter $_ in Manifest"
            }
        }

        try {
            New-ModuleManifest @ParmsManifest -ErrorAction Stop
        } catch {
            'Failed to create Manifest: {0}' -f $_.Exception.Message | Write-Error -ErrorAction Stop
        }

        # New-ModuleManifest produces inconsistent indentation and trailing whitespace on
        # array continuation lines. Format then strip trailing whitespace so the output
        # is clean for PSScriptAnalyzer and editors.
        $manifestContent = Get-Content -Path $data.ManifestFilePSD1 -Raw
        $formattedContent = Invoke-Formatter -ScriptDefinition $manifestContent
        $cleanedLines = $formattedContent -split '\r?\n' | ForEach-Object { $_.TrimEnd() }
        $cleanedContent = $cleanedLines -join [System.Environment]::NewLine
        Set-Content -Path $data.ManifestFilePSD1 -Value $cleanedContent -Encoding utf8NoBOM -NoNewline

        Write-Verbose 'COMPLETE: Building Module Manifest.'
    }
}
