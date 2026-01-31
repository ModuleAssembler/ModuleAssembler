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
    }

    process {
        ## TODO - DO schema check

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
            if ($data.copyResourcesToModuleRoot) {
                $FormatsToProcess += $_.Name
            } else {
                $FormatsToProcess += Join-Path -Path 'resources' -ChildPath $_.Name
            }
        }

        $ManfiestAllowedParams = (Get-Command New-ModuleManifest).Parameters.Keys
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

        ## Release label
        if ($sv.PreReleaseLabel) {
            $ParmsManifest['Prerelease'] = $sv.PreReleaseLabel
        }

        # Accept only valid Manifest Parameters
        $data.Manifest.Keys | ForEach-Object {
            if ( $ManfiestAllowedParams -contains $_) {
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
    }

    end {
        Write-Verbose 'COMPLETE: Building Module Manifest.'
    }
}
