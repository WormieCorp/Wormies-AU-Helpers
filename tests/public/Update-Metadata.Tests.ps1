Remove-Module wormies-au-helpers -ea ignore
Import-Module "$PSScriptRoot/../../Wormies-AU-Helpers"

function Get-FileEncoding {
    # <https://vertigion.com/2015/02/04/powershell-get-fileencoding/>
    [CmdletBinding()]
    param (
        [Alias("PSPath")]
        [Parameter(Mandatory = $True, ValueFromPipelineByPropertyName = $True)]
        [String]$Path
        ,
        [Parameter(Mandatory = $False)]
        [System.Text.Encoding]$DefaultEncoding = [System.Text.Encoding]::ASCII
    )

    process {
        [Byte[]]$bom = Get-Content -Encoding Byte -ReadCount 4 -TotalCount 4 -Path $Path

        $encoding_found = $false

        foreach ($encoding in [System.Text.Encoding]::GetEncodings().GetEncoding()) {
            if ($encoding_found) { break }
            $preamble = $encoding.GetPreamble()
            if ($preamble) {
                foreach ($i in 0..$preamble.Length) {
                    if ($preamble[$i] -ne $bom[$i]) {
                        break
                    }
                    elseif ($i -eq $preable.Length) {
                        $encoding_found = $encoding
                        break
                    }
                }
            }
        }

        if (!$encoding_found) {
            $encoding_found = $DefaultEncoding
        }

        $encoding_found
    }
}

Describe "Update-Metadata" {
    $nuspecFile = "$PSScriptRoot\test.nuspec"
    BeforeEach {
        $xml = @'
<?xml version="1.0" encoding="utf-8"?>
<!-- Do not remove this test for UTF-8: if “Ω” doesn’t appear as greek uppercase omega letter enclosed in quotation marks, you should use an editor that supports UTF-8, not this one. -->
<package xmlns="http://schemas.microsoft.com/packaging/2010/07/nuspec.xsd">
    <metadata>
        <id>ValidNuspec</id>
        <title>Valid Test Nuspec</title>
        <version>1.0.3</version>
        <dependencies>
          <dependency id="" />
        </dependencies>
  </metadata>
  <files>
    <file src="" />
  </files>
</package>
'@
        $utf8NoBomEncoding = New-Object System.Text.UTF8Encoding($false)
        [System.IO.File]::WriteAllText($nuspecFile, $xml, $utf8NoBomEncoding)
    }

    AfterEach {
        Remove-Item $nuspecFile -Force
    }

    It "Can update id with value 'new-id'" {
        Update-Metadata -key 'id' -value 'new-id' -NuspecFile $nuspecFile

        $nuspecFile | Should -FileContentMatchExactly "\<id\>new\-id\<\/id\>"
    }

    It "Can update version with value '6.2.12'" {
        Update-Metadata -key "version" -value "6.2.12" -NuspecFile $nuspecFile

        $nuspecFile | Should -FileContentMatchExactly "\<version\>6\.2\.12\<\/version\>"
    }

    It "Can update title with value 'Let me test out changing the title'" {
        Update-Metadata -key "title" -value "Let me test out changing the title" -NuspecFile $nuspecFile

        $nuspecFile | Should -FileContentMatchExactly "\<title\>Let me test out changing the title\<\/title\>"
    }

    It "Can update dependency with id of 'WindowsNewKB' and the version of '0.20.8.1" {
        ( Update-Metadata -key "dependency" -value "WindowsNewKB|0.20.8.1" -NuspecFile $nuspecFile 3>&1 ) -match "Change has been omitted due to dependency Nodes not having -1 Nodes" | Should Be $true

        $nuspecFile | Should -FileContentMatchExactly "\<dependency id=`"WindowsNewKB`" version=`"0.20.8.1`" \/\>"
    }

    It "Can update file with src of 'tools\**' and the target of 'tools" {
        ( Update-Metadata -key "file" -value "tools\**|tools" -NuspecFile $nuspecFile 3>&1 ) -match "Change has been omitted due to file Nodes not having -1 Nodes" | Should Be $true

        $nuspecFile | Should -FileContentMatchExactly "\<file src=`"tools\\\*\*`" target=`"tools`" \/\>"
    }

    It "Shows Warning when item doesn't exist" {
        ( Update-Metadata -key "rlsNotes" -value "I'm the new item" -NuspecFile $nuspecFile 3>&1 ) -match "rlsNotes does not exist on the metadata element in the nuspec file" | Should Be $true        
    }

    It "Should update multiple values" {
        Update-Metadata -data @{ "title" = "Yuppie"; Version = "0.5.3"; id = "yuppie" } -NuspecFile $nuspecFile
        $nuspecFile | Should -FileContentMatchExactly "\<title\>Yuppie\<\/title\>"
        $nuspecFile | Should -FileContentMatchExactly "\<version\>0\.5\.3\<\/version\>"
        $nuspecFile | Should -FileContentMatchExactly "\<id\>yuppie\<\/id\>"
    }

    It "Should create file without UTF8 BOM encoding" {
        Update-Metadata -key "title" -value "NO BOM TEST" -NuspecFile $nuspecFile

        $expectedEncoding = New-Object System.Text.UTF8Encoding($false)

        Get-FileEncoding -Path $nuspecFile -DefaultEncoding $expectedEncoding | Should Be $expectedEncoding
    }

    Context 'Test Group of passing change number clearly outside of the number of file/dependency nodes' {
        It "Shows Warning when dependency 2 is not present in the nuspec file" {
            ( Update-Metadata -data @{ dependency = 'kb2020813|0.20.8.13,2' } -NuspecFile $nuspecFile 3>&1 ) -match "Change has been omitted due to dependency Nodes not having 1 Nodes" | Should Be $true
            $nuspecFile | Should -FileContentMatchExactly "\<dependency id=`"kb2020813`" version=`"|0.20.8.13`" \/\>"
        }
        It "Shows Warning when file 87 is not present in the nuspec file" {
            ( Update-Metadata -data @{ file = 'tools\**|content\any\any,87' }  -NuspecFile $nuspecFile 3>&1 ) -match "86 is greater than 3 of file Nodes" -and "Change has been omitted due to file Nodes not having 86 Nodes" | Should Be $true
            $nuspecFile | Should -FileContentMatchExactly "\<file src=`"tools\\\*\*`" target=`"content\\any\\any`" \/\>"
        }
        It "Shows Warning when dependency 10 is not present in the nuspec file" {
            ( Update-Metadata -data @{ dependency = 'kb2020812|0.20.8.12,10' } -NuspecFile $nuspecFile 3>&1 ) -match "9 is greater than 3 of dependency Nodes" -and "Change has been omitted due to dependency Nodes not having -1 Nodes" | Should Be $true
            $nuspecFile | Should -FileContentMatchExactly "\<dependency id=`"kb2020812`" version=`"0.20.8.12`" \/\>"
        }
    }
}
