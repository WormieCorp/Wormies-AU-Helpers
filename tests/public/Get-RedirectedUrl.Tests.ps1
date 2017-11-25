Remove-Module wormies-au-helpers -ea ignore
Import-Module "$PSScriptRoot/../../Wormies-AU-Helpers"

Describe "Get-RedirectedUrl" {
    It "Should return redirected url on success" {
        Get-RedirectedUrl "https://chocolatey.org/api/v2/package/chocolatey/0.10.8" | Should Be "https://packages.chocolatey.org/chocolatey.0.10.8.nupkg"
    }

    It "Should return same url when no redirect happens" {
        Get-RedirectedUrl "https://chocolatey.org/" | Should Be "https://chocolatey.org/"
    }
}
