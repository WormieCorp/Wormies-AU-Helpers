$ErrorActionPreference = 'Stop'

<#
.SYNOPSIS
Updates the metadata nuspec file with the specified information.

.DESCRIPTION
When a key and value is specified, update the metadata element with the specified key
and the corresponding value in the specified NuspecFile.
Updating a file/dependency key must have at least one attribute defined.
( EX: <file src="" /> -or- <dependency id="" /> )
The updating of file/dependency key uses a pipe delimiter instead of comma. 
When updating file/dependency key that has multiple file/dependency key requires
a change value. This value is counted from one. The value must follow the values of
the attributes being changed. The Attributes for File are src, target, & exclude.
The Attributes for Dependency are id, version, exclude, & include.

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
This is an example of changing the Title of the nuspec file
Update-Metadata -data @{ title = 'My Awesome Title' }
- or -
@{ title = 'My Awesome Title' } | Update-Metadata

.EXAMPLE
This is an example of changing the id and version attributes for the dependency key
Update-Metadata -data @{ dependency = 'kb2919355|1.0.20160915' }
- or -
@{ dependency = 'kb2919355|1.0.20160915' } | Update-Metadata

.EXAMPLE
This is an example of changing the id and include attributes at the second dependency key
Without changing the values for attributes version or exclude (if present)
Update-Metadata -data @{ dependency = 'kb2919355||1.0.20160915,2' }
- or -
@{ dependency = 'kb2919355||1.0.20160915,2' } | Update-Metadata

.EXAMPLE
This is an example of changing the src and target attributes for the file key
Update-Metadata -data @{ file = 'tools\**|tools' }
- or -
@{ file = 'tools\**|tools' } | Update-Metadata

.EXAMPLE
This is an example of changing the src and exclude attributes at the second file key
Without changing the values for attribute target
Update-Metadata -data @{ file = 'tools\**||tools,2' }
- or -
@{ file = 'tools\**||tools,2' } | Update-Metadata

.NOTES
    Will now show a warning if the specified key doesn't exist in the nuspec file.
    Will now show a warning when the change value for file/dependency key is greater than currently in the nuspec file.
    Will now show a warning when file/dependency key doesn't have any defined attributes.
    Will now show a warning when the change value has been omitted due to nodes not allowing change at that key.

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
        [hashtable]$data = [ordered] @{$key = $value},
        [ValidateScript( { Test-Path $_ })]
        [SupportsWildcards()]
        [string]$NuspecFile = ".\*.nuspec"
    )

    $NuspecFile = Resolve-Path $NuspecFile

    $nu = New-Object xml
    $nu.PSBase.PreserveWhitespace = $true
    $nu.Load($NuspecFile)
    $data.Keys | ForEach-Object {
        switch -Regex ($_) {
            '^(file)$' {
                $metaData = "files"; $NodeGroup = $nu.package.$metaData
                $NodeData,[int]$change = $data[$_] -split (",")
                $NodeCount = $nu.package.$metaData.ChildNodes.Count; $src,$target,$exclude = $NodeData -split ("\|")
                $NodeAttributes = [ordered] @{"src" = $src;"target" = $target;"exclude" = $exclude}
                $change = @{$true="0";$false=($change - 1)}[ ([string]::IsNullOrEmpty($change)) ]
                if ($NodeCount -eq 3) { $NodeGroup = $NodeGroup."$_"; $omitted = $true } else { $NodeGroup = $NodeGroup.$_[$change] }
            }
            '^(dependency)$' {
                $MetaNode = $_ -replace("y","ies"); $metaData = "metadata"
                $NodeData,[int]$change = $data[$_] -split (",")
                $NodeGroup = $nu.package.$metaData.$MetaNode; $NodeCount = $nu.package.$metaData.$MetaNode.ChildNodes.Count
                $id,$version,$include,$exclude = $NodeData -split ("\|")
                $NodeAttributes = [ordered] @{"id" = $id;"version" = $version;"include" = $include;"exclude" = $exclude}
                $change = @{$true="0";$false=($change - 1)}[ ([string]::IsNullOrEmpty($change)) ]
                if ($NodeCount -eq 3) { $NodeGroup = $NodeGroup."$_"; $omitted = $true } else { $NodeGroup = $NodeGroup.$_[$change] }
            }
            default {
                if ( $nu.package.metadata."$_" ) {
                    $nu.package.metadata."$_" = $data[$_]
                }
                else {
                    Write-Warning "$_ does not exist on the metadata element in the nuspec file"
                }
            }
        }
        if ($_ -match '^(dependency)$|^(file)$') {
            if (($change -gt $NodeCount)) {
                Write-Warning "$change is greater than $NodeCount of $_ Nodes"
            }
            if ($omitted) {
                Write-Warning "Change has been omitted due to $_ not having that number of Nodes"
            }
            foreach ( $attrib in $NodeAttributes.keys ) {
                if (!([string]::IsNullOrEmpty($NodeAttributes[$attrib])) ) {
                    if (![string]::IsNullOrEmpty( $NodeGroup.Attributes ) ) {
                        $NodeGroup.SetAttribute($attrib, $NodeAttributes[$attrib] )
                    } else { 
                        Write-Warning "Attribute $attrib not defined for $_ in the nuspec file"
                    }
                }
            }
        } 
    }

    $utf8NoBom = New-Object System.Text.UTF8Encoding($false)
    [System.IO.File]::WriteAllText($NuspecFile, $nu.InnerXml, $utf8NoBom)
}
