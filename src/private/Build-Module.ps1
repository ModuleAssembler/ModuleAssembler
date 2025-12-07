function Build-Module {
    <#
    .SYNOPSIS
        Build the PowerShell module psm1 file.

    .DESCRIPTION
        The ps1 files contained in the folders classes, private, and public are transferred into a single psm1 file.

    .PARAMETER ParameterName
        Parameter description

    .EXAMPLE
        Execute the module build.
        Build-Module
    #>

    [CmdletBinding()]
    param ()

    begin {
        $data = Get-MAProjectInfo
        Write-Verbose 'START: Building Module.'
        Test-JsonSchema -Schema Build | Out-Null
    }

    process {
        $sb = [System.Text.StringBuilder]::new()

        # Classes Folder
        $files = Get-ChildItem -Path $data.ClassesDir -Filter *.ps1 -ErrorAction SilentlyContinue
        $files | ForEach-Object {
            Write-Verbose "Appending Class: $($_.Name)"
            $sb.AppendLine("# source: $($_.Name)") | Out-Null
            $sb.AppendLine([IO.File]::ReadAllText($_.FullName)) | Out-Null
            $sb.AppendLine('') | Out-Null
        }

        # Public Folder
        $files = Get-ChildItem -Path $data.PublicDir -Filter *.ps1
        $files | ForEach-Object {
            Write-Verbose "Appending Public Function: $($_.Name)"
            $sb.AppendLine("# source: $($_.Name)") | Out-Null
            $sb.AppendLine([IO.File]::ReadAllText($_.FullName)) | Out-Null
            $sb.AppendLine('') | Out-Null
        }

        # Private Folder
        $files = Get-ChildItem -Path $data.PrivateDir -Filter *.ps1 -ErrorAction SilentlyContinue
        if ($files) {
            $files | ForEach-Object {
                Write-Verbose "Appending Private Function: $($_.Name)"
                $sb.AppendLine("# source: $($_.Name)") | Out-Null
                $sb.AppendLine([IO.File]::ReadAllText($_.FullName)) | Out-Null
                $sb.AppendLine('') | Out-Null
            }
        }
        try {
            Set-Content -Path $data.ModuleFilePSM1 -Value $sb.ToString() -Encoding 'UTF8' -ErrorAction Stop
        } catch {
            Write-Error 'Failed to create psm1 file' -ErrorAction Stop
        }
    }

    end {
        Write-Verbose 'COMPLETE: Building Module.'
    }
}
