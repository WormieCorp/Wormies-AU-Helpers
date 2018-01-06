Remove-Module wormies-au-helpers -ea ignore
Import-Module "$PSScriptRoot/../../Wormies-AU-Helpers"

Describe "Expand-Aliases" {
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
        Get-ChildItem $directory -Filter "*.ps1" | % {
            Copy-Item $_.FullName $outputDirectory
        }


        $expectedDirectory = "$PSScriptRoot\aliasResultFiles"
        Expand-Aliases -Directory $outputDirectory

        Get-ChildItem $outputDirectory -Filter "*.ps1" | % {
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
}
