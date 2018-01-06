Remove-Module wormies-au-helpers -ea ignore
Import-Module "$PSScriptRoot/../../Wormies-AU-Helpers"

Describe "Expand-Aliases" {
    Import-Module "$env:ChocolateyInstall\helpers\chocolateyInstaller.psm1" -Force
    It "Should return same text if text is used" {
        $text = "Remove-Item sometext.txt; Get-ChildItem directory"
        Expand-Aliases -Text $text | Should Be $text
    }

    It "Should expand aliases in text" {
        $text = "rm sometext.txt; gci directory"
        $expectedText = "Remove-Item sometext.txt; Get-ChildItem directory"
        Expand-Aliases -Text $text | Should Be $expectedText
    }

    It "Should transform all powershell files in directory" {
        $directory = "$PSScriptRoot\aliasTestFiles"
        $outputDirectory = "$PSScriptRoot\..\.build\aliasTests"
        if (![System.IO.Directory]::Exists($outputDirectory)) {
            [System.IO.Directory]::CreateDirectory($outputDirectory)
        }
        Get-ChildItem $directory -Filter "*.ps1" | ForEach-Object {
            Copy-Item $_.FullName $outputDirectory
        }


        $expectedDirectory = "$PSScriptRoot\aliasResultFiles"
        Expand-Aliases -Directory $outputDirectory

        Get-ChildItem $outputDirectory -Filter "*.ps1" | ForEach-Object {
            $expected = Get-Content -Raw "$expectedDirectory/$($_.Name)"
            $actual = Get-Content -Raw $_.FullName
            $actual | Should Be $expected
        }
    }

    It "Should transform the file(s) explicitly passed" {
        $text = "rm item ; cat item"
        $expected = "Remove-Item item ; Get-Content item"
        $file = "$PSScriptRoot/../.build/test.txt"
        $text | Out-File $file -Encoding utf8 -NoNewline

        Expand-Aliases -Files $file
        Get-Content $file -Raw | Should Be $expected
    }

    It "Should expand chocolatey aliases" {
        $testText = "Invoke-ChocolateyProcess -Statements 'does','not','matter' -ExeToRun 'non-existant.exe'"
        $expectedText = "Start-ChocolateyProcessAsAdmin -Statements 'does','not','matter' -ExeToRun 'non-existant.exe'"

        Expand-Aliases -Text $testText | Should Be $expectedText
    }

    It "Should remove chocolateyInstaller module when done" {
        # Make sure that chocolateyInstaller module is removed before we start
        Remove-Module chocolateyInstaller -ErrorAction SilentlyContinue -Force
        $text = "ls ."

        Expand-Aliases -Text $text
        Get-Module chocolateyInstaller -All | Should Be $null
    }

    It "Should not remove chocolateyInstaller module if imported before calling function" {
        Import-Module "$env:ChocolateyInstall\helpers\chocolateyInstaller.psm1" -Force
        $text = "ls ."

        Expand-Aliases -Text $text

        Get-Module chocolateyInstaller -All | Should -Not -Be $null
    }
}
