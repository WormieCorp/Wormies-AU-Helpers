Remove-Module wormies-au-helpers -ea ignore
Import-Module "$PSScriptRoot/../../Wormies-AU-Helpers"

Describe "Networking" {
    It "Should get all headers if not overridden" {
        $expectedHeaders = @{
            'accept-ranges'  = 'bytes'
            'content-length' = 5433008
            'etag'           = '0x8D5B46C90EED410'
            'content-md5'    = '5BeA69heva5evcojv495sQ=='
            # There is alot more headers, but this should be enough for a test
        }

        $actualHeaders = Get-RemoteHeaders -uri 'https://dist.nuget.org/win-x86-commandline/v4.7.0/nuget.exe'

        $expectedHeaders.Keys | % {
            $key = $_
            $value = $expectedHeaders[$key]
            $actualHeaders.ContainsKey($key) | Should -Be $true
            $actualHeaders[$key] | Should -Be $value
        }
    }

    It "Should only return headers we want" {
        $expectedHeader = "etag"

        $actualHeaders = Get-RemoteHeaders -uri 'https://dist.nuget.org/win-x86-commandline/v4.7.0/nuget.exe' -OnlyUseHeaders @('etag')

        $actualHeaders.Keys | % { $_ | Should -Be $expectedHeader }
    }
}
