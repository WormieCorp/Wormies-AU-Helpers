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
    PS> Update-Metadata -key releaseNotes -value "https://github.com/majkinetor/AU/releases/latest"

.EXAMPLE
    PS> Update-Metadata -key releaseNotes -value "https://github.com/majkinetor/AU/releases/latest" -NuspecFile ".\package.nuspec"

.EXAMPLE
    PS> @{ title = 'My Awesome Title' } | Update-Metadata

    This is an example of changing the Title of the nuspec file
    Update-Metadata -data @{ title = 'My Awesome Title' }

.EXAMPLE
    PS> Update-Metadata -data @{ dependency = 'kb2919355|1.0.20160915' }

    This is an example of changing the id and version attributes for the dependency key

.EXAMPLE
    PS> @{ dependency = 'kb2919355|1.0.20160915' } | Update-Metadata

.EXAMPLE
    PS> Update-Metadata -data @{ file = 'tools\**,tools' }

    This is an example of changing the src and target attributes

.EXAMPLE
    PS> @{ file = 'tools\**|tools' } | Update-Metadata

.EXAMPLE
    PS> @{ file = 'tools\**|tools,1' } | Update-Metadata

    This is an example of changing the file src and target attributes for the first file element in the nuspec file.
    If only one file element is found the change value is omitted.

.INPUTS
    A hashtable of key+value pairs can be used instead of specifically use an argument.

.NOTES
    Will now show a warning if the specified key doesn't exist in the nuspec file.
    Will now show a warning when change for file/dependency key is greater than currently in the nuspec file.
    Will now show a warning when change has been omitted due to nodes not allowing change at that key.
    Will now show a warning when file/dependency doesn't have any attributes defined to be updated.

    While the parameter `NuspecFile` accepts globbing patterns,
    it is expected to only match a single file.

    The ability to update the file and dependency metadata was included in version 0.4.0.

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
        [hashtable]$data = @{ $key = $value },
        [ValidateScript( { Test-Path $_ })]
        [SupportsWildcards()]
        [string]$NuspecFile = ".\*.nuspec"

    )

    $NuspecFile = Resolve-Path $NuspecFile

    $nu = New-Object xml
    $nu.PSBase.PreserveWhitespace = $true
    $nu.Load($NuspecFile)
    $omitted = $true
    $data.Keys | ForEach-Object {
        switch -Regex ($_) {
            '^(file)$' {
                $metaData = "files"
                $NodeGroup = $nu.package.$metaData
                $NodeData, [int]$change = $data[$_] -split (",")
                $NodeCount = $nu.package.$metaData.ChildNodes.Count
                $src, $target, $exclude = $NodeData -split ("\|")
                $NodeAttributes = [ordered] @{
                    "src"     = $src
                    "target"  = $target
                    "exclude" = $exclude
                }
                $change = @{$true = "0"; $false = ($change - 1) }[ ([string]::IsNullOrEmpty($change)) ]
                if ($NodeCount -eq 3) {
                    $NodeGroup = $NodeGroup."$_"
                }
                else {
                    $NodeGroup = $NodeGroup.$_[$change]
                }
            }
            '^(dependency)$' {
                $MetaNode = $_ -replace ("y", "ies")
                $metaData = "metadata"
                $NodeData, [int]$change = $data[$_] -split (",")
                $NodeGroup = $nu.package.$metaData.$MetaNode
                $NodeCount = $nu.package.$metaData.$MetaNode.ChildNodes.Count
                $id, $version, $include, $exclude = $NodeData -split ("\|")
                $NodeAttributes = [ordered] @{
                    "id"      = $id
                    "version" = $version
                    "include" = $include
                    "exclude" = $exclude
                }
                $change = @{$true = "0"; $false = ($change - 1) }[ ([string]::IsNullOrEmpty($change)) ]
                if ($NodeCount -eq 3) {
                    $NodeGroup = $NodeGroup."$_"
                }
                else {
                    $NodeGroup = $NodeGroup.$_[$change]
                }
            }
            default {
                if ( $nu.package.metadata."$_" ) {
                    $nu.package.metadata."$_" = [string]$data[$_]
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
                    }
                    else {
                        Write-Warning "Attribute $attrib not defined for $_ in the nuspec file"
                    }
                }
            }
        }
    }

    $utf8NoBom = New-Object System.Text.UTF8Encoding($false)
    [System.IO.File]::WriteAllText($NuspecFile, $nu.InnerXml, $utf8NoBom)
}
