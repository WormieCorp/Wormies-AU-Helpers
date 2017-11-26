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
`Update-Metadata -key releaseNotes -value "https://github.com/majkinetor/AU/releases/latest"`

.EXAMPLE
`Update-Metadata -key releaseNotes -value "https://github.com/majkinetor/AU/releases/latest" -NuspecFile ".\package.nuspec"`

.NOTES
Will throw an exception if the specified key doesn't exist in the nuspec file.
#>
function Update-Metadata {
    param(
        [Parameter(Mandatory = $true)]
        [string]$key,
        [Parameter(Mandatory = $true)]
        [string]$value,
        [ValidateScript( { Test-Path $_ })]
        [string]$NuspecFile = ".\*.nuspec"
    )

    $NuspecFile = Resolve-Path $NuspecFile

    $nu = New-Object xml
    $nu.PSBase.PreserveWhitespace = $true
    $nu.Load($NuspecFile)
    if ($nu.package.metadata."$key") {
        $nu.package.metadata."$key" = "$value"
    }
    else {
        throw "$key does not exist on the metadata element in the nuspec file"
    }
    $nu.Save($NuspecFile)
}
