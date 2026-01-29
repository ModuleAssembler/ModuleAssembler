function Get-MAProjectInfo {
    <#
    .SYNOPSIS
        Retrieves information about a project by reading data from project.json file in the project folder.

    .DESCRIPTION
        Retrieves information about a project by reading data from project.json file located in the root directory.
        Ensure you navigate to a module directory which has project.json in root directory.
        Most variables are already defined in output of this command which can be used in pester tests and other configs.

    .EXAMPLE
        Get-MAProjectInfo

        Get a hashtable output of all module project metadata.

    .OUTPUTS
        System.Collections.Hashtable

        A hashtable with the module project metadata.
    #>

    [CmdletBinding()]
    [Alias('MAInfo')]
    param ()

    begin {
        Write-Verbose 'Getting project metadata.'
    }

    process {
        $Out = @{}
        $ProjectRoot = Get-Location | Convert-Path
        $Out['ProjectJSON'] = [System.IO.Path]::Combine($ProjectRoot, '.moduleassembler', 'moduleproject.json')

        if (-not (Test-Path $Out.ProjectJSON)) {
            Write-Error 'Not a Module Assembler project, moduleproject.json not found.' -ErrorAction Stop
        }

        ## Metadata, Import all json data
        $jsonData = Get-Content -Path $Out.ProjectJSON | ConvertFrom-Json -AsHashtable
        foreach ($key in $jsonData.Keys) {
            $Out[$key] = $jsonData[$key]
        }
        $ProjectName = $Out.ProjectName
        ## Folders
        $Out['ProjectRoot'] = $ProjectRoot
        $Out['PublicDir'] = [System.IO.Path]::Combine($ProjectRoot, 'src', 'public')
        $Out['PrivateDir'] = [System.IO.Path]::Combine($ProjectRoot, 'src', 'private')
        $Out['ClassesDir'] = [System.IO.Path]::Combine($ProjectRoot, 'src', 'classes')
        $Out['ResourcesDir'] = [System.IO.Path]::Combine($ProjectRoot, 'src', 'resources')
        $Out['OutputDir'] = [System.IO.Path]::Combine($ProjectRoot, 'dist')
        $Out['OutputModuleDir'] = [System.IO.Path]::Combine($Out.OutputDir, $ProjectName)
        $Out['ModuleFilePSM1'] = [System.IO.Path]::Combine($Out.OutputModuleDir, "$ProjectName.psm1")
        $Out['ManifestFilePSD1'] = [System.IO.Path]::Combine($Out.OutputModuleDir, "$ProjectName.psd1")

        $outSortedByKey = [ordered]@{}
        $Out.GetEnumerator() | Sort-Object Name | ForEach-Object { $outSortedByKey[$_.Name] = $_.Value }
        $Output = [pscustomobject]$outSortedByKey | Add-Member -TypeName MAProjectInfo -PassThru
        return $Output
    }

    end {
        # Cleanup code
    }
}
