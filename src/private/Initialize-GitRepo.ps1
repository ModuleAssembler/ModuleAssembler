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

    process {
        if (!(Get-Command git -ErrorAction SilentlyContinue)) {
            Write-Warning 'Git command was not found in PATH for the current session. Ensure Git is installed and available on PATH (for example, C:\Program Files\Git\cmd), then restart your terminal and initialize the repo manually if needed.'
            return
        }

        Push-Location -StackName 'GitInit'
        try {
            Set-Location $DirectoryPath

            if (!(Test-Path -Path '.git')) {
                if ($PSCmdlet.ShouldProcess($DirectoryPath, "Initializing git on $DirectoryPath")) {
                    $gitOutput = git init 2>&1
                    if ($LASTEXITCODE -ne 0) {
                        Write-Error "Failed to initialize Git repo in '$DirectoryPath' (exit code $LASTEXITCODE): $($gitOutput -join ' ')"
                    } else {
                        Write-Verbose 'Git initialized successfully.'
                    }
                }
            } else {
                Write-Warning 'A Git repository already exists in this directory. Skipping git init.'
            }
        } finally {
            Pop-Location -StackName 'GitInit'
        }
    }
}
