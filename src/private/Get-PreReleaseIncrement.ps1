function Get-PreReleaseIncrement {
    <#
    .SYNOPSIS
        Bumps the PreReleaseLabel number.

    .DESCRIPTION
        Takes the current PreReleaseLabel and increments the two digit number at the end.

    .PARAMETER PreReleaseLabel
        The PreReleaseLabel for the Symantic Version.

    .EXAMPLE
        Get-PrereleaseIncrement -PreReleaseLabel 'preview01'

        Bump the PreReleaseLabel from preview01 to preview02.
    #>

    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true)]
        [ValidateNotNullOrEmpty()]
        [string] $PreReleaseLabel
    )

    begin {
        # Initialization code
    }

    process {
        # Match any prefix followed by one or more digits at the end
        if ($PreReleaseLabel -match '^(.*?)(\d+)$') {
            $prefix = $matches[1]
            $numStr = $matches[2]
            $newNum = [int]$numStr + 1

            $newNumStr = $newNum.ToString().PadLeft(2, '0')

            return "$prefix$newNumStr"
        } else {
            return "$($PreReleaseLabel)01"
        }
    }

    end {
        # Cleanup code
    }
}
