BeforeAll {
    $script:projectRoot = Split-Path -Path (Split-Path -Path (Split-Path -Path $PSScriptRoot -Parent) -Parent) -Parent
    . (Join-Path -Path $script:projectRoot -ChildPath 'src/public/Get-MAProjectInfo.ps1')
}

Describe 'Get-MAProjectInfo' -Tag 'Unit' {
    BeforeEach {
        $script:originalLocation = Get-Location
        $script:testRoot = Join-Path -Path ([System.IO.Path]::GetTempPath()) -ChildPath ([System.Guid]::NewGuid().ToString('N'))
        $script:moduleAssemblerDir = Join-Path -Path $script:testRoot -ChildPath '.moduleassembler'
        New-Item -Path $script:moduleAssemblerDir -ItemType Directory -Force | Out-Null
    }

    AfterEach {
        Set-Location -Path $script:originalLocation
        if (Test-Path -Path $script:testRoot) {
            Remove-Item -Path $script:testRoot -Recurse -Force
        }
    }

    It 'returns MAProjectInfo with expected paths' {
        $projectJsonPath = Join-Path -Path $script:moduleAssemblerDir -ChildPath 'moduleproject.json'
        @'
{
  "ProjectName": "DemoModule",
  "Description": "Demo Description",
  "Version": "1.2.3",
  "Manifest": {
    "Author": "Author",
    "CompanyName": "Company",
    "PowerShellVersion": "7.4",
    "GUID": "11111111-1111-1111-1111-111111111111"
  }
}
'@ | Set-Content -Path $projectJsonPath -Encoding 'utf8NoBOM'

        Set-Location -Path $script:testRoot
        $result = Get-MAProjectInfo

        $result.PSObject.TypeNames | Should-ContainCollection 'MAProjectInfo'
        $result.ProjectName | Should-Be 'DemoModule'
        $result.PublicDir | Should-Be (Join-Path -Path $script:testRoot -ChildPath 'src/public')
        $result.PrivateDir | Should-Be (Join-Path -Path $script:testRoot -ChildPath 'src/private')
        $result.OutputModuleDir | Should-Be (Join-Path -Path $script:testRoot -ChildPath 'dist/DemoModule')
        $result.ManifestFilePSD1 | Should-Be (Join-Path -Path $script:testRoot -ChildPath 'dist/DemoModule/DemoModule.psd1')
    }

    It 'throws when moduleproject.json is missing' {
        Set-Location -Path $script:testRoot
        Remove-Item -Path (Join-Path -Path $script:moduleAssemblerDir -ChildPath 'moduleproject.json') -ErrorAction SilentlyContinue

        { Get-MAProjectInfo } | Should-Throw -ExceptionMessage '*moduleproject.json not found*'
    }
}
