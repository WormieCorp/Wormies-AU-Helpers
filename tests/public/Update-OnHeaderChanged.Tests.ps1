Remove-Module wormies-au-helpers -ea ignore
Import-Module "$PSScriptRoot/../../Wormies-AU-Helpers"

$DebugPreference = 'Continue'
$VerbosePreference = 'Continue'

Describe "Updating" {

    Context "ScriptBlocks" {

        It "Calls DownloadFiles to download file when no existing info available" {
            $downloadCalled = $false
            Update-OnHeaderChanged -url32 'https://nuget.org' `
                -DownloadFiles { $downloadCalled = $true } `
                -ParseVersion {} `
                -OnVersionMismatch {} `
                -ParseStoredInfo {} `
                -SaveStoredInfo {}

            "$downloadCalled" | Should -Be "$true"
        }

        It "Calls ParseVersion to parse the file version when file is downloaded" {
            $downloadCalled = $false
            $parseVersionCalled = $false
            Update-OnHeaderChanged -url32 'https://nuget.org/policies/About' `
                -DownloadFiles { $downloadCalled = $true } `
                -ParseVersion { $parseVersionCalled = $true } `
                -OnVersionMismatch {} `
                -ParseStoredInfo {} `
                -SaveStoredInfo {}

            "$downloadCalled" | Should -Be "$true"
            "$parseVersionCalled" | Should -Be "$true"
        }

        It "Calls OnVersionMismatch when versions doesn't match" {
            $mismatchCalled = $false

            Update-OnHeaderChanged -url32 'https://chocolatey.org' -url64 'https://google.com' `
                -DownloadFiles { } `
                -ParseVersion { return $false } `
                -OnVersionMismatch { $mismatchCalled = $true } `
                -ParseStoredInfo {} `
                -SaveStoredInfo {}

            "$mismatchCalled" | Should -Be "$true"
        }

        It "Should not call OnVersionMismatch when versions match" {
            $mismatchCalled = $false

            Update-OnHeaderChanged -url32 'https://microsoft.com' -url64 'https://gitter.im' `
                -DownloadFiles { return @{} } `
                -ParseVersion {
                param($package)
                $package["Version32"] = '0.5.1'
                $package["Version64"] = '0.5.1'
                return $true
            } `
                -OnVersionMismatch { $mismatchCalled = $true } `
                -ParseStoredInfo {} `
                -SaveStoredInfo {}

            "$mismatchCalled" | Should -Be "$false"
        }

        It "Should not download file if no change is detected" {
            $downloadCalled = $false
            Update-OnHeaderChanged -url32 "https://packages.chocolatey.org/cmail.0.8.0-dev-2.nupkg" `
                -DownloadFiles { $downloadCalled = $true; @{} } `
                -ParseStoredInfo { @{ URL32 = @{ "ETag" = "`"7ecbeb8fed9d2d937ac21f42d8b71fb4`"" }} } `
                -SaveStoredInfo {}

            "$downloadCalled" | Should -Be "$false"
        }

        It "Should download file if changes is detected" {
            $downloadCalled = $false
            Update-OnHeaderChanged -url32 "https://chocolatey.org/api/v2/package/cmail/0.8.0-dev-2" `
                -DownloadFiles { $downloadCalled = $true; @{} } `
                -ParseStoredInfo { @{ URL32 = @{ "ETag" = "`"7ecbeb8fed9d2d937a71fb4`"" }} } `
                -ParseVersion { param($Package) ; $Package["Version32"] = "0.8.0-dev-2"; return $true } `
                -SaveStoredInfo {}

            "$downloadCalled" | Should -Be $true
        }
    }
}
