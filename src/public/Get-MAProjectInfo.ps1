function Get-MAProjectInfo {
    <#
    .SYNOPSIS
        Retrieves information about a project by reading data from project.json file in the project folder.

    .DESCRIPTION
        Retrieves information about a project by reading data from project.json file located in the root directory.
        Ensure you navigate to a module directory which has project.json in root directory.
        Most variables are already defined in output of this command which can be used in pester tests and other configs.

    .EXAMPLE
        Get a hashtable output of all module project metadata.
        Get-MAProjectInfo
    #>

    [CmdletBinding()]
    param ()

    begin {
        Write-Verbose 'Getting project metadata.'
    }

    process {
        $Out = @{}
        $ProjectRoot = Get-Location | Convert-Path
        $Out['ProjecJSON'] = Join-Path -Path $ProjectRoot -ChildPath 'project.json'

        if (-not (Test-Path $Out.ProjecJSON)) {
            Write-Error 'Not a Project folder, project.json not found' -ErrorAction Stop
        }

        ## Metadata, Import all json data
        $jsonData = Get-Content -Path $Out.ProjecJSON | ConvertFrom-Json -AsHashtable
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

        $Output = [pscustomobject]$Out | Add-Member -TypeName MTProjectInfo -PassThru
        return $Output
    }

    end {
        # Cleanup code
    }
}
