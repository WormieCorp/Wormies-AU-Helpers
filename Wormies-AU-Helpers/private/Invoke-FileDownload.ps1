function Invoke-FileDownload {
    param(
        [uri]$URL32,
        [uri]$URL64,
        [hashtable]$Options = @{},
        [switch]$WhatIf
    )

    $filePath32 = [System.IO.Path]::GetTempFileName()
    $filePath64 = [System.IO.Path]::GetTempFileName()

    $result = @{}

    $existingModule = Get-Module "chocolateyInstaller" -ea 0
    if (!$existingModule) {
        if ($WhatIf) {
            Write-Host "Would import the chocolateyInstaller module..."
        }
        else {
            Import-Module $env:ChocolateyInstall\helpers\chocolateyInstaller.psm1
        }
    }

    if (![string]::IsNullOrEmpty($URL32)) {
        if ($WhatIf) {
            Write-Host "Would download 32bit binary file..."
        }
        else {
            Write-Host "Downloading 32bit binary file..."
            Get-WebFile -url $URL32 -fileName $filePath32 -Options $Options
        }
        $result["FilePath32"] = $filePath32
        $result["URL32"] = $URL32
    }

    if (![string]::IsNullOrEmpty($URL64)) {
        if ($WhatIf) {
            Write-Host "Would download 64bit binary file..."
        }
        else {
            Write-Host "Downloading 64bit binary file..."
            Get-WebFile -url $URL64 -fileName $filePath64 -Options $Options
        }
        $result["FilePath64"] = $filePath64
        $result["URL64"] = $URL64
    }

    return $result
}
