function Get-MAProjectInfo {
    <#
    .SYNOPSIS
        Gets metadata and derived paths for the current ModuleAssembler project.

    .DESCRIPTION
        Reads the project's .moduleassembler/moduleproject.json file and returns its module metadata
        together with commonly used project, source, resource, build output, module, manifest, and module file paths.

        Run this command from the module project directory.
        The command does not search parent directories for a project configuration file and throws an error if
        .moduleassembler/moduleproject.json is not found.

        The returned object has the custom type name MAProjectInfo and can be used by
        ModuleAssembler commands, Pester tests, and project configuration scripts.

    .EXAMPLE
        Get-MAProjectInfo

        Returns metadata and derived paths for the current ModuleAssembler project.

    .OUTPUTS
        System.Management.Automation.PSCustomObject

        A PSCustomObject with the custom type name MAProjectInfo containing the project metadata and derived paths.
    #>

    [CmdletBinding()]
    [OutputType([pscustomobject])]
    [Alias('MAInfo')]
    param ()

    process {
        Write-Verbose 'Getting project metadata.'

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
}
