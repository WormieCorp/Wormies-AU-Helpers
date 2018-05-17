Remove-Module wormies-au-helpers -ea ignore
Import-Module "$PSScriptRoot/../../Wormies-AU-Helpers"

Describe "Downloading" {
    It "Can download 32bit binary file" {
        $result = Invoke-FileDownload -URL32 'https://www.7-zip.org/a/7z1805.exe'

        $result["FilePath32"] | Should -Not -Be $null

        $itemName = Get-Item $result["FilePath32"] | % { $_.VersionInfo.ProductName }

        $itemName | Should -Be '7-Zip'
    }

    It "Should return 32bit info when download 32bit file" {
        $expectedUrl = "https://www.7-zip.org/a/7z1805.exe"
        $result = Invoke-FileDownload -URL32 $expectedUrl -WhatIf
        $result["URL32"] | Should -Be $expectedUrl
        $result["FilePath32"] | Should -not -Be $null
    }

    It "Can download 64bit binary file" {
        $result = Invoke-FileDownload -URL64 'https://www.7-zip.org/a/7z1805-x64.exe'

        $result["FilePath64"] | Should -Not -Be $null

        $itemName = Get-Item $result["FilePath64"] | % { $_.VersionInfo.ProductName }

        $itemName | Should -Be '7-Zip'
    }

    It "Should return 64bit info when download 64bit file" {
        $expectedUrl = "https://www.7-zip.org/a/7z1805-x64.exe"
        $result = Invoke-FileDownload -URL64 $expectedUrl -WhatIf
        $result["URL64"] | Should -Be $expectedUrl
        $result["FilePath64"] | Should -not -Be $null
    }
}
