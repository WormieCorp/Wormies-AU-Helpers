Remove-Module wormies-au-helpers -ea ignore
Import-Module "$PSScriptRoot/../../Wormies-AU-Helpers"

Describe "Parsing" {

    Context "Version Parsing" {
        $trueVersions = @("0.1"; "1.0"; "0.1.2"; "1.5.3"; "0.5.6.2"; "2.5.6.3"; "0.1-beta"; "1.0-alpha"; "5.2.4-unstable"; "2.4.6.7-rc5"; "0.4-preview1-untested")
        $falseVersions = @('0'; '1'; '5.7.2.4.7'; '0.20.3.45.1'; "5.3-beta.1"; "5.7.2.4.6-beta"; "65.3-alpha-beta-charlie")

        $trueVersions | ForEach-Object {
            $version = $_
            It "returns $true when '$version' is passed as version" {
                Test-ValidVersion -version $version | Should Be $true
            }
        }

        $falseVersions | ForEach-Object {
            $version = $_
            It "returns $false when '$version' is passed as version" {
                Test-ValidVersion -version $version | Should Be $false
            }
        }

        It "returns $false when 'stableOnly' switch is used and parsing pre-releases" {
            Test-ValidVersion -version "0.5-beta" -stableOnly | Should Be $false
        }

        It "returns $false when 'preReleaseOnly' switch is used and parsing stable releases" {
            Test-ValidVersion -version "0.6.2" -preReleaseOnly | Should Be $false
        }

        It "throws exception when both 'stableOnly' and 'preReleaseOnly' switch is used" {
            { Test-ValidVersion -version "doesn't matter" -stableOnly -preReleaseOnly } | Should Throw
        }
    }
}
