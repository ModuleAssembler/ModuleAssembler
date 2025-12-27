function Update-MAModuleVersion {
    <#
    .SYNOPSIS
        Updates the version number of a module in project.json file. Uses [semver] object type.

    .DESCRIPTION
        This script updates the version number of the PowerShell module by modifying the project.json file, which gets written into module manifest file (.psd1). [semver] is supported only for PowerShell 7 and above.
        It increments the version number based on the specified version part (Major, Minor, Patch). Can also attach preview/stable to Release property.

    .PARAMETER Label
        The part of the version number to increment (Major, Minor, Patch). Default is Patch.

    .PARAMETER PrereleaseType
        Specify the prerelease type to use (alpha, beta, preview, rc).
        If executed again with no Label and the same PrereleaseType type, the prerelease number will increment.

    .EXAMPLE
        Updates the Major version part of the module. Version 2.1.3 will become 3.1.3.
        Update-MAModuleVersion -Label Major

    .EXAMPLE
        Updates the Patch version part of the module. Version 2.1.3 will become 2.1.4.
        Update-MAModuleVersion

    .EXAMPLE
        Adds a specified PreReleaseLabel to the module version. Version 1.0.0 will become 1.0.0-preview01.
        Update-MAModuleVersion -PreReleaseType preview

    .EXAMPLE
        Increment a pre-existing PreReleaseLabel. Version 1.0.0-preview01 will become 1.0.0-preview02.
        Update-MAModuleVersion -PreReleaseType preview

    .EXAMPLE
        Sets a new version and specify it as a PreRelease. Version 0.1.0 will become 1.0.0-rc01.
        Update-MAModuleVersion -Label Major -PreReleaseType rc

    .NOTES
        Ensure you are in project directory when you run this command.
    #>

    [CmdletBinding(SupportsShouldProcess = $true)]
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
            $CurrentVersion.PreReleaseLabel -imatch '^((?:alpha|beta|preview|rc))(\d+)?$' | Out-Null
            try {
                $currentPreReleaseType = $matches[1]
            } catch {
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

        if ($PSCmdlet.ShouldProcess("Setting module version in JSON from $CurrentVersion to $newVersion", $data.ProjectJSON, 'Version Update')) {
            # Update the version in the JSON object
            $jsonContent.Version = $newVersion.ToString()
            Write-Host "Version bumped $CurrentVersion -> $newVersion"

            # Convert the JSON object back to JSON format
            $newJsonContent = $jsonContent | ConvertTo-Json

            # Write the updated JSON back to the file
            $newJsonContent | Set-Content -Path $data.ProjecJSON
        }
    }

    end {
        # Cleanup code
    }
}
