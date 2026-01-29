function Initialize-GitRepo {
    <#
    .SYNOPSIS
        Initialize a Git repository in the specified directory.

    .DESCRIPTION
        Initialize a Git repository in the specified directory.

    .PARAMETER DirectoryPath
        The directory path in which to initialize the Git repository.

    .EXAMPLE
        Initialize-GitRepo -DirectoryPath "C:\NewModule"

        Initializes the Git repository in the directory provided.
    #>

    [CmdletBinding(SupportsShouldProcess = $true)]
    param (
        [Parameter(
            Mandatory = $true,
            Position = 0)]
        [ValidateNotNullOrEmpty()]
        [string] $DirectoryPath
    )

    begin {
        if (-not (Get-Command git -ErrorAction SilentlyContinue)) {
            Write-Warning 'Git is not installed. Please install Git and initialize repo manually.'
            return
        }

        Push-Location -StackName 'GitInit'
    }

    process {
        Set-Location $DirectoryPath

        if (Test-Path -Path '.git') {
            Write-Warning 'A Git repository already exists in this directory. Skipping git init.'

            if ($PSCmdlet.ShouldProcess($DirectoryPath, ("Initiating git on $DirectoryPath"))) {
                try {
                    git init | Out-Null
                } catch {
                    Write-Error 'Failed to initialize Git repo.'
                }
            }
            Write-Verbose 'Git initialized successfully.'
        }
    }

    end {
        Pop-Location -StackName 'GitInit'
    }
}
