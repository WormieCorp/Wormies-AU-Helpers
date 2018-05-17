function Update-VersionInformation {
    param(
        [hashtable]$Package,
        [switch]$UseFileVersion
    )


    function GetVersion {
        param($path)

        $version = if ($UseFileVersion) {
            Get-Item $path | % { $_.VersionInfo.FileVersion }
        }
        else {
            Get-Item $path | % { $_.VersionInfo.ProductVersion }
        }

        return $version -replace ',','.'
    }
    $has32Bit = $has64Bit = $false

    if ($Package["FilePath32"] -and (Test-Path $Package["FilePath32"])) {
        $Package["Version32"] = GetVersion $Package["FilePath32"]
        $has32Bit = $true
    }

    if ($Package["FilePath64"] -and (Test-Path $Package["FilePath64"])) {
        $Package["Version64"] = GetVersion $Package["FilePath64"]
        $has64Bit = $true
    }

    $versionMatches = (!$has32Bit -and $has64Bit) `
        -or ($has32Bit -and !$has64Bit) `
        -or $Package["Version32"] -eq $Package["Version64"]

    return $versionMatches
}
