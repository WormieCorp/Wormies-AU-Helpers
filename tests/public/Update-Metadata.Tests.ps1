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

Describe "Update-Metadata Test With Attributes" {
    $nuspecFile = Join-Path "$PSScriptRoot" "test.nuspec"
    BeforeEach {
        $xml = @'
<?xml version="1.0" encoding="utf-8"?>
<!-- Do not remove this test for UTF-8: if “Ω” doesn’t appear as greek uppercase omega letter enclosed in quotation marks, you should use an editor that supports UTF-8, not this one. -->
<package xmlns="http://schemas.microsoft.com/packaging/2010/07/nuspec.xsd">
  <metadata>
        <id>ValidNuspec</id>
        <title>Valid Test Nuspec</title>
        <version>1.0.3</version>
        <releaseNotes>https://something.com</releaseNotes>
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
        ( Update-Metadata -key "dependency" -value "WindowsNewKB|0.20.8.1" -NuspecFile $nuspecFile 3>&1 ) -match "Change has been omitted due to dependency not having that number of Nodes" | Should Be $true

        $nuspecFile | Should -FileContentMatchExactly "\<dependency id=`"WindowsNewKB`" version=`"0.20.8.1`" \/\>"
    }

    It "Can update file with src of 'tools\**' and the target of 'tools" {
        ( Update-Metadata -key "file" -value "tools\**|tools" -NuspecFile $nuspecFile 3>&1 ) -match "Change has been omitted due to file not having that number of Nodes" | Should Be $true

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

    It "Should update metadata when passed a uri string" {
        [uri]$url = "https://chocolatey.org"
        Update-Metadata -key "releaseNotes" -value $url -NuspecFile $nuspecFile
        $nuspecFile | Should -FileContentMatchExactly "\<releaseNotes\>https://chocolatey.org\/\<\/releaseNotes\>"
    }

    It "Should update metadata when passed a uri in data hashtable" {
        [uri]$url = "https://chocolatey.org/path"
        Update-Metadata -data @{ releaseNotes = $url } -NuspecFile $nuspecFile
        $nuspecFile | Should -FileContentMatchExactly "\<releaseNotes\>https://chocolatey.org\/path\<\/releaseNotes\>"
    }

    It "Shows Warning when dependency 2 is not present in the nuspec file" {
        ( Update-Metadata -data @{ dependency = 'kb2020813|0.20.8.13,2' } -NuspecFile $nuspecFile 3>&1 ) -match "Change has been omitted due to dependency not having that number of Nodes" | Should Be $true
        $nuspecFile | Should -FileContentMatchExactly "\<dependency id=`"kb2020813`" version=`"|0.20.8.13`" \/\>"
    }
    It "Shows Warning when file 87 is not present in the nuspec file" {
        ( Update-Metadata -data @{ file = 'tools\**|content\any\any,87' }  -NuspecFile $nuspecFile 3>&1 ) -match "86 is greater than 3 of file Nodes" -and "Change has been omitted due to file not having that number of Nodes" | Should Be $true
        $nuspecFile | Should -FileContentMatchExactly "\<file src=`"tools\\\*\*`" target=`"content\\any\\any`" \/\>"
    }
    It "Shows Warning when dependency 10 is not present in the nuspec file" {
        ( Update-Metadata -data @{ dependency = 'kb2020812|0.20.8.12,10' } -NuspecFile $nuspecFile 3>&1 ) -match "9 is greater than 3 of dependency Nodes" -and "Change has been omitted due to dependency not having that number of Nodes" | Should Be $true
        $nuspecFile | Should -FileContentMatchExactly "\<dependency id=`"kb2020812`" version=`"0.20.8.12`" \/\>"
    }
}

Describe "Update-Metadata Test Multiple File/Dependency Keys" {
    $nuspecFile = Join-Path "$PSScriptRoot" "test.nuspec"
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
          <dependency id="identity" />
          <dependency exclude="exclude" />
        </dependencies>
  </metadata>
  <files>
    <file target="target" />
    <file src="source" />
  </files>
</package>
'@
        $utf8NoBomEncoding = New-Object System.Text.UTF8Encoding($false)
        [System.IO.File]::WriteAllText($nuspecFile, $xml, $utf8NoBomEncoding)
    }

    AfterEach {
        Remove-Item $nuspecFile -Force
    }

    It "Testing for reading file attributes" {
        $nuspecFile | Should -FileContentMatchExactly "\<file src=`"source`" \/\>"
        $nuspecFile | Should -FileContentMatchExactly "\<file target=`"target`" \/\>"
    }

    It "Testing for changing only src attribute of second file key" {
        Update-Metadata -data @{ file = 'new source,2' } -NuspecFile $nuspecFile
        $nuspecFile | Should -FileContentMatchExactly "\<file src=`"new source`" \/\>"
    }

    It "Testing for changing only target attribute of first file key" {
        Update-Metadata -data @{ file = '|new target,1' } -NuspecFile $nuspecFile
        $nuspecFile | Should -FileContentMatchExactly "\<file target=`"new target`" \/\>"
    }

    It "Testing for changing only src attribute of second file key target attribute of first file key" {
        Update-Metadata -data @{ file = 'third_source,2' } -NuspecFile $nuspecFile
        $nuspecFile | Should -FileContentMatchExactly "\<file src=`"third_source`" \/\>"
        Update-Metadata -data @{ file = '|third target,1' } -NuspecFile $nuspecFile
        $nuspecFile | Should -FileContentMatchExactly "\<file target=`"third target`" \/\>"
    }

    It "Testing for changing only exclude attribute of second dependency key" {
        Update-Metadata -data @{ dependency = '|||second exclude,2' } -NuspecFile $nuspecFile
        $nuspecFile | Should -FileContentMatchExactly "\<dependency exclude=`"second exclude`" \/\>"
    }

    It "Testing for changing only id attribute of first dependency key" {
        Update-Metadata -data @{ dependency = 'first identity,1' } -NuspecFile $nuspecFile
        $nuspecFile | Should -FileContentMatchExactly "\<dependency id=`"first identity`" \/\>"
    }

    It "Testing for changing only exclude attribute of second dependency key id attribute of first dependency key" {
        Update-Metadata -data @{ dependency = 'third_identity,1' } -NuspecFile $nuspecFile
        $nuspecFile | Should -FileContentMatchExactly "\<dependency id=`"third_identity`" \/\>"
        Update-Metadata -data @{ dependency = '|||third exclude,2' } -NuspecFile $nuspecFile
        $nuspecFile | Should -FileContentMatchExactly "\<dependency exclude=`"third exclude`" \/\>"
    }

    It "Testing for changing only exclude attribute of second dependency and target attribute of first file key" {
        Update-Metadata -data @{ dependency = '|||second exclude,2' } -NuspecFile $nuspecFile
        $nuspecFile | Should -FileContentMatchExactly "\<dependency exclude=`"second exclude`" \/\>"
        Update-Metadata -data @{ file = '|new target,1' } -NuspecFile $nuspecFile
        $nuspecFile | Should -FileContentMatchExactly "\<file target=`"new target`" \/\>"
    }

    It "Testing for changing all attributes of second dependency and first file key" {
        Update-Metadata -data @{ dependency = 'ident|versions|includes|second exclude,2' } -NuspecFile $nuspecFile
        $nuspecFile | Should -FileContentMatchExactly "\<dependency exclude=`"second exclude`" id=`"ident`" version=`"versions`" include=`"includes`" \/\>"
        Update-Metadata -data @{ file = 'sources|new target|excludes,1' } -NuspecFile $nuspecFile
        $nuspecFile | Should -FileContentMatchExactly "\<file target=`"new target`" src=`"sources`" exclude=`"excludes`" \/\>"
    }

    It "Testing for changing all attributes except exclude of second dependency and target of first file key" {
        Update-Metadata -data @{ dependency = 'ident|versions|includes,2' } -NuspecFile $nuspecFile
        $nuspecFile | Should -FileContentMatchExactly "\<dependency exclude=`"exclude`" id=`"ident`" version=`"versions`" include=`"includes`" \/\>"
        Update-Metadata -data @{ file = 'sources||excludes,1' } -NuspecFile $nuspecFile
        $nuspecFile | Should -FileContentMatchExactly "\<file target=`"target`" src=`"sources`" exclude=`"excludes`" \/\>"
    }

}

Describe "Update-Metadata Test No Attributes Defined in File/Dependency Keys" {
    $nuspecFile = Join-Path "$PSScriptRoot" "test.nuspec"
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
          <dependency />
        </dependencies>
  </metadata>
  <files>
    <file />
  </files>
</package>
'@
        $utf8NoBomEncoding = New-Object System.Text.UTF8Encoding($false)
        [System.IO.File]::WriteAllText($nuspecFile, $xml, $utf8NoBomEncoding)
    }

    AfterEach {
        Remove-Item $nuspecFile -Force
    }

    It "Testing for updating file when no attributes defined and a change of 87" {
        ( Update-Metadata -data @{ file = 'tools\**,87' } -NuspecFile $nuspecFile 3>&1 ) -match "Attribute src not defined for file in the nuspec file" -and "Change has been omitted due to file not having that number of Nodes" | Should Be $true
        $nuspecFile | Should -FileContentMatchExactly "\<file \/\>"
    }

    It "Testing for updating dependency when no attributes defined and a change of 10" {
        ( Update-Metadata -data @{ dependency = 'kb2020812,10' } -NuspecFile $nuspecFile 3>&1 ) -match "Attribute id not defined for dependency in the nuspec file" -and "Change has been omitted due to dependency not having that number of Nodes" | Should Be $true
        $nuspecFile | Should -FileContentMatchExactly "\<dependency \/\>"
    }

    It "Testing for updating file when no attributes defined without change stated" {
        ( Update-Metadata -data @{ file = 'tools\**' } -NuspecFile $nuspecFile 3>&1 ) -match "Attribute src not defined for file in the nuspec file" | Should Be $true
        $nuspecFile | Should -FileContentMatchExactly "\<file \/\>"
    }

    It "Testing for updating dependency when no attributes defined without change stated" {
        ( Update-Metadata -data @{ dependency = 'kb2020812' } -NuspecFile $nuspecFile 3>&1 ) -match "Attribute id not defined for dependency in the nuspec file"  | Should Be $true
        $nuspecFile | Should -FileContentMatchExactly "\<dependency \/\>"
    }

}
