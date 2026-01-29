function Read-HostResponse {
    <#
    .SYNOPSIS
        Read the response selected for the provided question.

    .DESCRIPTION
        Prompts the user with the provided question, then reads the response from the host.

    .PARAMETER Ask
        An object which contains a question to prompt the user with.

    .EXAMPLE
        $question = @{
            Caption = 'Module Name'
            Message = 'Enter Module name of your choice, should be single word with no special characters'
            Prompt  = 'Name'
            Default = 'MANDATORY'
        }
        Read-HostResponse -Ask $question

        Prompt the user with a question and read the result.
    #>

    [CmdletBinding()]
    param (
        [Parameter(
            Mandatory = $true,
            Position = 0)]
        [pscustomobject] $Ask
    )

    begin {
        # Initialization code
    }

    process {
        ## For standard questions
        if ($null -eq $Ask.Choice) {
            do {
                $response = $Host.UI.Prompt($Ask.Caption, $Ask.Message, $Ask.Prompt)
            } while ($Ask.Default -eq 'MANDATORY' -and [string]::IsNullOrEmpty($response.Values))

            if ([string]::IsNullOrEmpty($response.Values)) {
                $result = $Ask.Default
            } else {
                $result = ($response.Values).Trim()
            }
        }
        ## For Choice based
        if ($Ask.Choice) {
            $Cs = @()
            $Ask.Choice.Keys | ForEach-Object {
                $Cs += New-Object System.Management.Automation.Host.ChoiceDescription "&$_", $($Ask.Choice.$_)
            }
            $options = [System.Management.Automation.Host.ChoiceDescription[]]($Cs)
            $IndexOfDefault = $Cs.Label.IndexOf('&' + $Ask.Default)
            $response = $Host.UI.PromptForChoice($Ask.Caption, $Ask.Message, $options, $IndexOfDefault)
            $result = $Cs.Label[$response] -replace '&'
        }
        return $result
    }

    end {
        # Cleanup code
    }
}
