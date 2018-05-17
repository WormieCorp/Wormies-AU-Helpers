Remove-Module wormies-au-helpers -ea ignore
Import-Module "$PSScriptRoot/../../Wormies-AU-Helpers"

Describe "Versioning" {
    $url32 = 'https://www.7-zip.org/a/7z1805.exe'
    $url64 = 'https://www.7-zip.org/a/7z1805-x64.exe'
    $fileName32 = "$env:TEMP\7z1805.exe"
    $fileName64 = "$env:TEMP\7z1805-x64.exe"
    if (!(Test-Path $fileName32)) { iwr -Uri $url32 -OutFile $fileName32 -UseBasicParsing }
    if (!(Test-Path $fileName64)) { iwr -Uri $url64 -OutFile $fileName64 -UseBasicParsing }

    It "Should get correct 32bit version from executable" {
        $package = @{ FilePath32 = $fileName32 }
        $result = Update-VersionInformation $package

        $package["Version32"] | Should -Be "18.05"
        $result | Should -Be $true
    }

    It "Should get correct 64bit version from executable" {
        $package = @{ FilePath64 = $fileName32 }
        $result = Update-VersionInformation $package

        $package["Version64"] | Should -Be "18.05"
        $result | Should -Be $true
    }

    It "Should get correct 32 and 64bit version from executable" {
        $package = @{ FilePath32 = $fileName32; FilePath64 = $fileName64 }
        $result = Update-VersionInformation $package

        $package["Version32"] | Should -Be "18.05"
        $package["Version64"] | Should -Be "18.05"
        $result | Should -Be $true
    }
}
