$ErrorActionPreference = 'Stop'

<#
.SYNOPSIS
Updates the metadata nuspec file with the specified information.

.DESCRIPTION
When a key and value is specified, update the metadata element with the specified key
and the corresponding value in the specified NuspecFile.
Singlular metadata elements are the only ones changed at this time.

.PARAMETER key
The element that should be updated in the metadata section.

.PARAMETER value
The value to update with.

.PARAMETER NuspecFile
The metadata/nuspec file to update

.EXAMPLE
Update-Metadata -key releaseNotes -value "https://github.com/majkinetor/AU/releases/latest"

.EXAMPLE
Update-Metadata -key releaseNotes -value "https://github.com/majkinetor/AU/releases/latest" -NuspecFile ".\package.nuspec"

.EXAMPLE
Update-Metadata -data @{ title = 'My Awesome Title' }

.EXAMPLE
@{ title = 'My Awesome Title' } | Update-Metadata

.EXAMPLE
Update-Metadata -data @{ dependency = 'kb2919355,1.0.20160915' }

.EXAMPLE
@{ dependency = 'kb2919355,1.0.20160915' } | Update-Metadata

.EXAMPLE
Update-Metadata -data @{ file = 'tools\**,tools' }

.EXAMPLE
@{ file = 'tools\**,tools' } | Update-Metadata

.NOTES
    Will throw an exception if the specified key doesn't exist in the nuspec file.
    Will throw an exception if zero/more file/dependency key exist in the nuspec file.

    While the parameter `NuspecFile` accepts globbing patterns,
    it is expected to only match a single file.

.LINK
    https://wormiecorp.github.io/Wormies-AU-Helpers/docs/functions/update-metadata
#>
function Update-Metadata {
    param(
        [Parameter(Mandatory = $true, ParameterSetName = "Single")]
        [string]$key,
        [Parameter(Mandatory = $true, ParameterSetName = "Single")]
        [string]$value,
        [Parameter(Mandatory = $true, ParameterSetName = "Multiple", ValueFromPipeline = $true)]
        [hashtable]$data = @{$key = $value},
        [ValidateScript( { Test-Path $_ })]
        [SupportsWildcards()]
        [string]$NuspecFile = ".\*.nuspec"
    )

    $NuspecFile = Resolve-Path $NuspecFile

    $nu = New-Object xml
    $nu.PSBase.PreserveWhitespace = $true
    $nu.Load($NuspecFile)
    $data.Keys | ForEach-Object {
        switch -regex ($_) {
            '^(file|files)$' {
                $src, $target = $data[$_] -split (",")
                if (($src -isnot [string]) -or ($target -isnot [string])) {
                    Write-Verbose "$src or $target is not a valid string";
                }
                else {
                    if ( ($nu.package.files.ChildNodes.Count) -eq 3 ) {
                       $nu.package.files.file.src = $src
                       $nu.package.files.file.target = $target
                    }
                    else {
                       Write-Verbose "Zero or more than one Files Child Node found"
                    }
                }
            }
            '^(dependency|dependencies)$' {
                $id, $version = $data[$_] -split (",")
                if (($id -isnot [string]) -or ($version -isnot [string]))  {
                    Write-Verbose "$id or $version is not a valid string";
                }
                else {
                    if ( ($nu.package.metadata.dependencies.ChildNodes.Count) -eq 3 ) {
                       $nu.package.metadata.dependencies.dependency.id = $id
                       $nu.package.metadata.dependencies.dependency.version = $version
                    }
                    else {
                       Write-Verbose "Zero or more than one dependencies Child Node found"
                    }
                }
            }
            default {
                if ( $nu.package.metadata."$_" ) {
                    $nu.package.metadata."$_" = $data[$_]
                }
                else {
                    Write-Verbose "$_ does not exist on the metadata element in the nuspec file"
                }
            }
            
        }
    }

    $utf8NoBom = New-Object System.Text.UTF8Encoding($false)
    [System.IO.File]::WriteAllText($NuspecFile, $nu.InnerXml, $utf8NoBom)
}
