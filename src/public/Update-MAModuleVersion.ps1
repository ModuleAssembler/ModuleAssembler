function Update-MAModuleVersion {
    <#
    .SYNOPSIS
        Updates the version number of a module in project.json file. Uses [semver] object type.

    .DESCRIPTION
        This script updates the version number of the PowerShell module by modifying the project.json file, which gets written into module manifest file (.psd1). [semver] is supported only for PowerShell 7 and above.
        It increments the version number based on the specified version part (Major, Minor, Patch). Can also attach preview/stable to Release property.

    .PARAMETER Label
        The part of the version number to increment (Major, Minor, Patch). Default is patch.

    .PARAMETER PreviewRelease
        A switch release name as 'preview' which is supported by PowerShell gallery, to remove it use stable release parameter

    .EXAMPLE
        Updates the Major version part of the module. Version 2.1.3 will become 3.1.3
        Update-MAModuleVersion -Label Major

    .EXAMPLE
        Updates the Patch version part of the module. Version 2.1.3 will become 2.1.4
        Update-MAModuleVersion

    .NOTES
        Ensure you are in project directory when you run this command.
    #>

    [CmdletBinding()]
    param (
        [Parameter(
            Mandatory = $false,
            Position = 0)]
        [ValidateSet('Major', 'Minor', 'Patch')]
        [string] $Label = 'Patch',

        [Parameter(
            Mandatory = $false,
            Position = 1)]
        [switch]$PreviewRelease
    )

    begin {
        Write-Verbose "Updating the $($Label) version number for the module."
    }

    process {
        $data = Get-MAProjectInfo
        $jsonContent = Get-Content -Path $data.ProjecJSON | ConvertFrom-Json

        [semver]$CurrentVersion = $jsonContent.Version
        $Major = $CurrentVersion.Major
        $Minor = $CurrentVersion.Minor

        if ($Label -eq 'Major') {
            $Major = $CurrentVersion.Major + 1
            $Minor = 0
            $Patch = 0
        } elseif ($Label -eq 'Minor') {
            $Minor = $CurrentVersion.Minor + 1
            $Patch = 0
        } elseif ($Label -eq 'Patch') {
            $Patch = $CurrentVersion.Patch + 1
        }

        if ($PreviewRelease) {
            $ReleaseType = 'preview'
        } elseif ($StableRelease) {
            $ReleaseType = $null
        } else {
            $ReleaseType = $CurrentVersion.PreReleaseLabel
        }

        $newVersion = [semver]::new($Major, $Minor, $Patch, $ReleaseType, $null)

        # Update the version in the JSON object
        $jsonContent.Version = $newVersion.ToString()
        Write-Host "Version bumped to : $newVersion"

        # Convert the JSON object back to JSON format
        $newJsonContent = $jsonContent | ConvertTo-Json

        # Write the updated JSON back to the file
        $newJsonContent | Set-Content -Path $data.ProjecJSON
    }

    end {
        # Cleanup code
    }
}
