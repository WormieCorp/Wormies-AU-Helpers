<#
.SYNOPSIS
    Validates the passed version to be valid as a chocolatey version

.DESCRIPTION
    This functions takes the specified $version variable, and first test
    if it is a valid stable version '0.4.3.2', if it isn't it then tries
    to check if it is a valid pre-release version '0.5.4-beta'

.PARAMETER version
    The version to test if it is valid.

.PARAMETER stableOnly
    Only test if the specified version is a stable version.

.PARAMETER preReleaseOnly
    Only test if the specified version is a pre-release version.

.OUTPUTS
    Outputs $true if the version is valid; otherwise $false
#>

function Test-ValidVersion {
    param(
        [Parameter(Mandatory = $true, ValueFromPipeline = $true, ParameterSetName = "All")]
        [Parameter(Mandatory = $true, ValueFromPipeline = $true, ParameterSetName = "Stable")]
        [Parameter(Mandatory = $true, ValueFromPipeline = $true, ParameterSetName = "PreRelease")]
        [string]$version,
        [Parameter(Mandatory = $true, ParameterSetName = 'Stable')]
        [switch]$stableOnly,
        [Parameter(Mandatory = $true, ParameterSetName = 'PreRelease')]
        [switch]$preReleaseOnly
    )

    $stableFormat = '\d+(\.\d+){1,3}'
    if (!$preReleaseOnly -and $version -match "^$stableFormat$") {
        return $true
    }

    if (!$stableOnly -and $version -match "^${stableFormat}(\-[a-z\d]+){1,2}$") {
        return $true
    }

    return $false
}
