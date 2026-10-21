BeforeAll {
    $script:data = Get-MAProjectInfo
}

Describe 'Project-to-resource mirrors' -Tag 'ResourceMirror' {
    It 'mirrors canonical project QA tests into resources' {
        $qaFileNames = @('QA.Tests.ps1', 'ProjectCompliance.Tests.ps1')

        foreach ($qaFileName in $qaFileNames) {
            $canonicalQaPath = Join-Path -Path $script:data.ProjectRoot -ChildPath (Join-Path -Path 'tests/QualityAssurance' -ChildPath $qaFileName)
            $packagedQaPath = Join-Path -Path $script:data.ResourcesDir -ChildPath (Join-Path -Path 'PesterTests/QualityAssurance' -ChildPath $qaFileName)

            Test-Path -LiteralPath $canonicalQaPath -PathType Leaf | Should-BeTrue
            Test-Path -LiteralPath $packagedQaPath -PathType Leaf | Should-BeTrue

            $canonicalContent = [System.IO.File]::ReadAllText($canonicalQaPath).Replace("`r`n", "`n").Replace("`r", "`n")
            $packagedContent = [System.IO.File]::ReadAllText($packagedQaPath).Replace("`r`n", "`n").Replace("`r", "`n")
            $packagedContent | Should-Be $canonicalContent -Because "the packaged QA test '$qaFileName' must mirror its canonical project source"
        }
    }

    It 'mirrors the project .vscode files into resources/vscode' {
        $resourceDirectory = Join-Path -Path $script:data.ResourcesDir -ChildPath 'vscode'
        $projectDirectory = Join-Path -Path $script:data.ProjectRoot -ChildPath '.vscode'
        $resourceFiles = @(Get-ChildItem -LiteralPath $resourceDirectory -File -Recurse)
        $projectFiles = @(Get-ChildItem -LiteralPath $projectDirectory -File -Recurse)
        $resourceRelativePaths = @($resourceFiles | ForEach-Object {
                [System.IO.Path]::GetRelativePath($resourceDirectory, $_.FullName).Replace('\', '/')
            } | Sort-Object)
        $projectRelativePaths = @($projectFiles | ForEach-Object {
                [System.IO.Path]::GetRelativePath($projectDirectory, $_.FullName).Replace('\', '/')
            } | Sort-Object)

        $resourceRelativePaths | Should-BeCollection -Expected $projectRelativePaths `
            -Because 'src/resources/vscode must mirror the canonical project .vscode file set'

        foreach ($relativePath in $resourceRelativePaths) {
            if ($relativePath -eq 'settings.json') {
                continue
            }

            $resourcePath = Join-Path -Path $resourceDirectory -ChildPath $relativePath
            $projectPath = Join-Path -Path $projectDirectory -ChildPath $relativePath
            $resourceContent = [System.IO.File]::ReadAllText($resourcePath).Replace("`r`n", "`n").Replace("`r", "`n")
            $projectContent = [System.IO.File]::ReadAllText($projectPath).Replace("`r`n", "`n").Replace("`r", "`n")

            $resourceContent | Should-Be $projectContent -Because "the vscode resource '$relativePath' must mirror its canonical project file"
        }
    }

    It 'mirrors project VS Code settings except project-specific associations and AI co-author settings' {
        $projectSettingsPath = Join-Path -Path $script:data.ProjectRoot -ChildPath '.vscode/settings.json'
        $resourceSettingsPath = Join-Path -Path $script:data.ResourcesDir -ChildPath 'vscode/settings.json'
        $jsonOptions = [System.Text.Json.JsonDocumentOptions]::new()
        $jsonOptions.CommentHandling = [System.Text.Json.JsonCommentHandling]::Skip
        $jsonOptions.AllowTrailingCommas = $true

        $projectSettings = [System.Text.Json.Nodes.JsonNode]::Parse(
            [System.IO.File]::ReadAllText($projectSettingsPath),
            $null,
            $jsonOptions
        )
        $resourceSettings = [System.Text.Json.Nodes.JsonNode]::Parse(
            [System.IO.File]::ReadAllText($resourceSettingsPath),
            $null,
            $jsonOptions
        )

        foreach ($excludedSetting in @('files.associations', 'git.addAICoAuthor')) {
            $resourceSettings.AsObject().ContainsKey($excludedSetting) | Should-BeFalse `
                -Because "the resource template must omit project-specific setting '$excludedSetting'"
            $null = $projectSettings.AsObject().Remove($excludedSetting)
        }

        $resourceSettings.ToJsonString() | Should-Be $projectSettings.ToJsonString() `
            -Because 'all other project VS Code settings must be mirrored to resources/vscode'
    }

    It 'mirrors the project moduleassembler schemas into resources/schemas' {
        $resourceDirectory = Join-Path -Path $script:data.ResourcesDir -ChildPath 'schemas'
        $projectDirectory = Join-Path -Path $script:data.ProjectRoot -ChildPath '.moduleassembler/schemas'
        $resourceFiles = @(Get-ChildItem -LiteralPath $resourceDirectory -File -Recurse)
        $projectFiles = @(Get-ChildItem -LiteralPath $projectDirectory -File -Recurse)
        $resourceRelativePaths = @($resourceFiles | ForEach-Object {
                [System.IO.Path]::GetRelativePath($resourceDirectory, $_.FullName).Replace('\', '/')
            } | Sort-Object)
        $projectRelativePaths = @($projectFiles | ForEach-Object {
                [System.IO.Path]::GetRelativePath($projectDirectory, $_.FullName).Replace('\', '/')
            } | Sort-Object)

        $resourceRelativePaths | Should-BeCollection -Expected $projectRelativePaths `
            -Because 'src/resources/schemas must mirror the canonical project schema file set'

        foreach ($relativePath in $resourceRelativePaths) {
            $resourcePath = Join-Path -Path $resourceDirectory -ChildPath $relativePath
            $projectPath = Join-Path -Path $projectDirectory -ChildPath $relativePath
            $resourceContent = [System.IO.File]::ReadAllText($resourcePath).Replace("`r`n", "`n").Replace("`r", "`n")
            $projectContent = [System.IO.File]::ReadAllText($projectPath).Replace("`r`n", "`n").Replace("`r", "`n")

            $resourceContent | Should-Be $projectContent -Because "the schema resource '$relativePath' must mirror its canonical project file"
        }
    }

    It 'mirrors the project .gitignore into resources/gitignore' {
        $resourcePath = Join-Path -Path $script:data.ResourcesDir -ChildPath 'gitignore'
        $projectPath = Join-Path -Path $script:data.ProjectRoot -ChildPath '.gitignore'
        $resourceContent = [System.IO.File]::ReadAllText($resourcePath).Replace("`r`n", "`n").Replace("`r", "`n")
        $projectContent = [System.IO.File]::ReadAllText($projectPath).Replace("`r`n", "`n").Replace("`r", "`n")

        $resourceContent | Should-Be $projectContent -Because 'src/resources/gitignore must mirror the canonical project .gitignore'
    }
}
