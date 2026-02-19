BeforeAll {
    $script:data = Get-MAProjectInfo
}

Describe 'General Module Control' {
    It 'Should import without errors' {
        ## PENDING
        { Import-Module -Name $data.OutputModuleDir -ErrorAction Stop } | Should -Not -Throw
        Get-Module -Name $data.ProjectName | Should -Not -BeNullOrEmpty
    }
}
