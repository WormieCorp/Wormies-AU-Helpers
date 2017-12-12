<#
.SYNOPSIS
    Parse the specified version and create a fix version when needed.

.DESCRIPTION
    When a 4-part version number is used by the software authors, there
    may be a little hard at times to push out an updated version by manually
    creating the fix version.
    This script helps out with this when both a 4-part version is used, and
    when a prerelease have been passed.

.PARAMETER Version
    The version number to parse for a fix version

.PARAMETER OnlyFixBelowVersion
    The version to stop adding fix versions to
    (in case of padding revision number)

.PARAMETER AppendRevisionLength
    The number of zeros to append the revision number with, before adding the
    fix number
    (defaults to 1).

.PARAMETER NuspecFile
    The nuspec metadata file to parse for the existing version information
    (defaults to '.\*.nuspec')

.OUTPUTS
    Will output the full version number with a fix number when a 4-part version
    have been specified.

.OUTPUTS
    Will append the date to any pre-release versions.

.OUTPUTS
    Will just return the same version number if no fix is needed, or when the
    version number isn't a 4-part version.

.EXAMPLE
    Get-FixVersion -Version '24.0.0.195'

    will output `24.0.0.19501` if the
    nuspec version is equal to `24.0.0.195` or `24.0.0.19500` and
    `$global:au_Force` is set to `$true`

.EXAMPLE
    Get-FixVersion -Version '5.0-beta'

    will output `5.0-beta-20171123` (the current date)

.NOTES
    While the parameter `NuspecFile` accepts globbing patterns,
    it is expected to only match a single file.

.LINK
    https://wormiecorp.github.io/Wormies-AU-Helpers/docs/functions/get-fixversion
#>
function Get-FixVersion() {
    param(
        [ValidateScript( { Test-ValidVersion -Version $_ })]
        [parameter(Mandatory = $true)]
        [string]$Version,

        [string]$OnlyFixBelowVersion = $null,
        [Alias("AppendZeroes")]
        [int]$AppendRevisionLength = 1,
        [SupportsWildcards()]
        [string]$NuspecFile = "./*.nuspec"
    )
    function appendRevision {
        param($version, [int]$appendRevisionLength, [int]$existingRevision)

        [string]$newVersion = $version

        for ($i = $appendRevisionLength; $i -gt 0; $i--) {
            $newVersion += "0"
        }

        [int]$revision = $existingRevision + 1

        return $newVersion + $revision
    }

    function getExistingRevision {
        param($version, $existingVersion)

        $revision = $existingVersion -replace "^$version"
        if ($revision -match '^\d+$' -and $global:au_Force -eq $true) {
            return [int]$revision
        }
        elseif ($revision -match "^\d+$") {
            return ([int]$revision) - 1
        }
        elseif ($version -eq $existingVersion) {
            return 0
        }
        else {
            return -1
        }
    }

    if ($Version -match "^\d+(\.\d+){1,2}$") {
        return $Version
    }

    $NuspecFile = Resolve-Path $NuspecFile

    $existingVersion = Get-NuspecMetadata -nuspecFile $NuspecFile | ForEach-Object version

    if ($existingVersion -eq $Version -and $global:au_Force -ne $true) {
        return $Version
    }

    if ($Version -like '*-*') {
        [version]$mainVersion = $Version -split "-" | Select-Object -First 1
        $preRelease = "-" + ($Version -split "-" | Select-Object -First 1 -Skip 1)
    }
    else {
        [version]$mainVersion = $Version
        $preRelease = ""
    }

    if ($OnlyFixBelowVersion) {
        if ($OnlyFixBelowVersion -like '*-*') {
            [version]$belowVersion = $OnlyFixBelowVersion -split "-" | Select-Object -First 1
            $belowPreRelease = "-" + ($OnlyFixBelowVersion -split "-" | Select-Object -First 1 -Skip 1)
        }
        else {
            [version]$belowVersion = $OnlyFixBelowVersion
            $belowPreRelease = ""
        }

        if ($mainVersion -ge $belowVersion -and ($preRelease -ge $belowPreRelease)) {
            return $Version
        }
        elseif ($mainVersion -eq $belowVersion -and !$preRelease -and $belowVersion) {
            return $Version
        }
    }

    if (!($preRelease)) {
        $existingRevision = getExistingRevision -version $Version -existingVersion $existingVersion
        return appendRevision `
            -version $mainVersion `
            -existingRevision $existingRevision `
            -appendRevisionLength $AppendRevisionLength
    }
    else {
        return ([string]$mainVersion) + $preRelease + "-" + (Get-Date -UFormat "{0:yyyyMMdd}")
    }
}
