@{
    IncludeDefaultRules = $true
    Severity            = @('Warning', 'Error')
    ExcludeRules        = @(
        'PSAvoidUsingWriteHost',   # Acceptable in interactive/UI-facing scripts
        'PSAlignAssignmentStatement' # Formatter cannot auto-correct; produces permanent squiggles
    )
    Rules               = @{

        # Require comment-based help on all exported functions, placed inside
        # the function body before the param block ("begin")
        PSProvideCommentHelp                      = @{
            Enable                  = $true
            ExportedOnly            = $true
            BlockComment            = $true
            VSCodeSnippetCorrection = $false
            Placement               = 'begin'
        }

        # Line length
        PSAvoidLongLines                          = @{
            Enable            = $false
            MaximumLineLength = 120
        }

        # Indentation — maps to: editor.tabSize=4, editor.insertSpaces=true,
        # powershell.codeFormatting.pipelineIndentationStyle
        PSUseConsistentIndentation                = @{
            Enable              = $true
            IndentationSize     = 4
            PipelineIndentation = 'IncreaseIndentationForFirstPipeline'
            Kind                = 'space'
        }

        # Whitespace — maps to all powershell.codeFormatting.whitespace* settings
        PSUseConsistentWhitespace                 = @{
            Enable                          = $true
            CheckInnerBrace                 = $true   # whitespaceInsideBrace
            CheckOpenBrace                  = $true   # whitespaceBeforeOpenBrace
            CheckOpenParen                  = $true   # whitespaceBeforeOpenParen
            CheckOperator                   = $false  # disabled: conflicts with alignPropertyValuePairs
            # which pads = in hashtables for alignment
            CheckPipe                       = $true   # addWhitespaceAroundPipe
            CheckPipeForRedundantWhitespace = $true   # trimWhitespaceAroundPipe
            CheckSeparator                  = $true   # whitespaceAfterSeparator
            CheckParameter                  = $true   # whitespaceBetweenParameters
        }

        # Align hashtable assignment operators — maps to: alignPropertyValuePairs
        # Note: PSAlignAssignmentStatement is excluded in ExcludeRules above.
        # Hashtable alignment is handled by the VS Code formatter (alignPropertyValuePairs) on save.

        # Open brace placement — maps to: preset=OTBS, openBraceOnSameLine,
        # newLineAfterOpenBrace, ignoreOneLineBlock
        PSPlaceOpenBrace                          = @{
            Enable             = $true
            OnSameLine         = $true   # openBraceOnSameLine
            NewLineAfter       = $true   # newLineAfterOpenBrace
            IgnoreOneLineBlock = $false  # ignoreOneLineBlock
        }

        # Close brace placement — maps to: newLineAfterCloseBrace, ignoreOneLineBlock
        PSPlaceCloseBrace                         = @{
            Enable             = $true
            NewLineAfter       = $false  # newLineAfterCloseBrace
            IgnoreOneLineBlock = $false  # ignoreOneLineBlock
            NoEmptyLineBefore  = $false
        }

        # Correct casing for cmdlets and keywords — maps to: useCorrectCasing
        PSUseCorrectCasing                        = @{
            Enable = $true
        }

        # Enforce constant strings use single quotes — maps to: useConstantStrings
        # Not included in IncludeDefaultRules, must be declared explicitly
        PSAvoidUsingDoubleQuotesForConstantString = @{
            Enable = $true
        }
    }
}
