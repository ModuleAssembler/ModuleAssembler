function Update-MAModuleVersion {
    <#
    .SYNOPSIS
        Updates the version number of a module in project.json file. Uses [semver] object type.

    .DESCRIPTION
        This function updates the version number of the PowerShell module by modifying the project.json file, which gets written into module manifest file (.psd1). [semver] is supported only for PowerShell 7 and above.
        It increments the version number based on the specified version part (Major, Minor, Patch). Can also attach preview/stable to Release property.

    .PARAMETER Label
        The part of the version number to increment (Major, Minor, Patch). Default is Patch.

    .PARAMETER PrereleaseType
        Specify the prerelease type to use (alpha, beta, preview, rc).
        If executed again with no Label and the same PrereleaseType type, the prerelease number will increment.

    .EXAMPLE
        Update-MAModuleVersion -Label Major

        Updates the Major version part of the module. Version 2.1.3 will become 3.0.0.

    .EXAMPLE
        Update-MAModuleVersion -Label Minor

        Updates the Minor version part of the module. Version 2.1.3 will become 2.2.0.

    .EXAMPLE
        Update-MAModuleVersion -Label Patch

        Updates the Patch version part of the module. Version 2.1.3 will become 2.1.4.

    .EXAMPLE
        Update-MAModuleVersion

        Updates the Patch version part of the module. Version 2.1.3 will become 2.1.4.

    .EXAMPLE
        Update-MAModuleVersion -PreReleaseType preview

        Adds a specified PreReleaseLabel to the module version. Version 1.0.0 will become 1.0.0-preview01.
        If the same PreReleaseType was previously used, it will increment the number. Version 1.0.0-preview01 will become 1.0.0-preview02.

    .EXAMPLE
        Update-MAModuleVersion -Label Major -PreReleaseType rc

        Sets a new version and specify it as a PreRelease. Version 0.1.0 will become 1.0.0-rc01.

    .NOTES
        Ensure you are in the project directory when running this command.
    #>

    [CmdletBinding(SupportsShouldProcess = $true)]
    [Alias('MAVersion')]
    param (
        [Parameter(
            Mandatory = $false,
            Position = 0)]
        [ValidateSet('Major', 'Minor', 'Patch')]
        [string] $Label,

        [Parameter(
            Mandatory = $false,
            Position = 1)]
        [ValidateSet('alpha', 'beta', 'preview', 'rc')]
        [string] $PreReleaseType
    )

    begin {
        $data = Get-MAProjectInfo
        $jsonContent = Get-Content -Path $data.ProjectJSON | ConvertFrom-Json
        [semver]$CurrentVersion = $jsonContent.Version

        if (!($PreReleaseType) -and !($Label)) {
            $Label = 'Patch'
        }
    }

    process {
        $Major = $CurrentVersion.Major
        $Minor = $CurrentVersion.Minor
        $Patch = $CurrentVersion.Patch

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

        if ($PrereleaseType) {
            if ($CurrentVersion.PreReleaseLabel -imatch '^((?:alpha|beta|preview|rc))(\d+)?$') {
                $currentPreReleaseType = $Matches[1]
            } else {
                $currentPreReleaseType = $null
            }

            if ($PreReleaseType -eq $currentPreReleaseType -and !($Label)) {
                $ReleaseType = Get-PreReleaseIncrement -PreReleaseLabel $CurrentVersion.PreReleaseLabel
            } else {
                $ReleaseType = Get-PreReleaseIncrement -PreReleaseLabel $PrereleaseType
            }
        } else {
            $ReleaseType = $null
        }

        $newVersion = [semver]::new($Major, $Minor, $Patch, $ReleaseType, $null)

        if ($PSCmdlet.ShouldProcess($data.ProjectJSON, "Update version from $CurrentVersion to $newVersion")) {
            # Update the version in the JSON object
            $jsonContent.Version = $newVersion.ToString()
            Write-Host "Version updated $CurrentVersion -> $newVersion"

            # Convert the JSON object back to JSON format
            $newJsonContent = $jsonContent | ConvertTo-Json -Depth 10

            # Write the updated JSON back to the file
            $newJsonContent | Set-Content -Path $data.ProjectJSON -Encoding 'utf8NoBOM'
        }
    }
}
