Remove-Module wormies-au-helpers -ea ignore
Import-Module "$PSScriptRoot/../../Wormies-AU-Helpers"

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
    </metadata>
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

        $nuspecFile | Should -FileContentMatch "\<id\>new\-id\<\/id\>"
    }

    It "Can update version with value '6.2.12'" {
        Update-Metadata -key "version" -value "6.2.12" -NuspecFile $nuspecFile

        $nuspecFile | Should -FileContentMatch "\<version\>6\.2\.12\<\/version\>"
    }

    It "Can update title with value 'Let me test out changing the title'" {
        Update-Metadata -key "title" -value "Let me test out changing the title" -NuspecFile $nuspecFile

        $nuspecFile | Should -FileContentMatch "\<title\>Let me test out changing the title\<\/title\>"
    }

    It "Throws exception when item doesn't exist" {
        { Update-Metadata -key "rlsNotes" -value "I'm the new item" -NuspecFile $nuspecFile } | Should -Throw "rlsNotes does not exist on the metadata element in the nuspec file"
    }
}
