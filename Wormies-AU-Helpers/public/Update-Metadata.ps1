$ErrorActionPreference = 'Stop'

<#
.SYNOPSIS
Updates the metadata nuspec file with the specified information.

.DESCRIPTION
When a key and value is specified, update the metadata element with the specified key
and the corresponding value in the specified NuspecFile.

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

.NOTES
Will throw an exception if the specified key doesn't exist in the nuspec file.
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
        [string]$NuspecFile = ".\*.nuspec"
    )

    $NuspecFile = Resolve-Path $NuspecFile

    $nu = New-Object xml
    $nu.PSBase.PreserveWhitespace = $true
    $nu.Load($NuspecFile)
    $data.Keys | % {
        if ($nu.package.metadata."$_") {
            $nu.package.metadata."$_" = $data[$_]
        }
        else {
            throw "$_ does not exist on the metadata element in the nuspec file"
        }
    }

    $nu.Save($NuspecFile)
}
