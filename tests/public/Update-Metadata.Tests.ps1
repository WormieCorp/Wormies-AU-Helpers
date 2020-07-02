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
          <dependency id="SomeText" version="SomeVersion" />
        </dependencies>
    </metadata>
  <files>
    <file src="**" target="Content" />
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

    It "Can update dependency with id of 'WindowsNewKB' and the version of '0.20.7.2" {
        Update-Metadata -key "dependency" -value "WindowsNewKB,0.20.7.2" -NuspecFile $nuspecFile

        $nuspecFile | Should -FileContentMatchExactly "\<dependency id=`"WindowsNewKB`" version=`"0.20.7.2`" \/\>"
    }

    It "Can update file with src of 'tools\**' and the target of 'tools" {
        Update-Metadata -key "file" -value "tools\**,tools" -NuspecFile $nuspecFile

        $nuspecFile | Should -FileContentMatchExactly "\<file src=`"tools\\\*\*`" target=`"tools`" \/\>"
    }

    It "Throws exception when if file or dependency values are not strings" {
        { Update-Metadata -data @{ dependency = 'kb2919355,1.0.20190915,9' } -NuspecFile $nuspecFile } | Should -Throw "kb2919355 or 1.0.20190915 9 is not a valid string"
        { Update-Metadata -data @{ file = 'tools\**,content\any\any,87' }  -NuspecFile $nuspecFile } | Should -Throw "tools\** or content\any\any 87 is not a valid string"
    }

    It "Throws execption when file or dependency is not present or more than One is found in the nuspec file" {
        $xmlData = Get-Content $nuspecFile; $xmlData = $xmlData -replace('(\<dependency).+(\/>)|(\<file).+(\/>)','');
        $utf8NoBomEncoding = New-Object System.Text.UTF8Encoding($false); [System.IO.File]::WriteAllText($nuspecFile, $xmlData, $utf8NoBomEncoding)
        { Update-Metadata -data @{ dependency = 'kb2919355,1.0.20190915' } -NuspecFile $nuspecFile } | Should -Throw "Zero or more than one dependencies Child Node found"
        { Update-Metadata -data @{ file = 'tools\**,content\any\any' }  -NuspecFile $nuspecFile } | Should -Throw "Zero or more than one Files Child Node found"
    }

    It "Throws exception when item doesn't exist" {
        { Update-Metadata -key "rlsNotes" -value "I'm the new item" -NuspecFile $nuspecFile } | Should -Throw "rlsNotes does not exist on the metadata element in the nuspec file"
        
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
}
