function Update-OnHeaderChanged {
    param(
        [string] $URL32,
        [string] $URL64,
        [hashtable] $DownloadOptions,
        [switch] $UseFileVersion,
        [string[]] $AcceptedHeaders = @('etag'),
        [string] $FilePath = "$PSScriptRoot\info",
        [scriptblock] $DownloadFiles = $null,
        [scriptblock] $ParseVersion = $null,
        [scriptblock] $OnVersionMismatch = $null,
        [scriptblock] $ParseStoredInfo = $null,
        [scriptblock] $SaveStoredInfo = $null
    )

    function compareHeaders {
        param($existingHeaders, $remoteHeaders)

        foreach ($key in $remoteHeaders.Keys) {
            $value = $remoteHeaders.$key
            if (!($existingHeaders.$key -eq $value)) {
                Write-Debug "The $key in remote headers and existing headers did not match."
                Write-Debug "Actual values:`nRemote: $value`nLocal: $($existingHeaders.$key)"
                return $true
            } else {
                Write-Debug "The $key in remote headers and existing headers matched."
            }
        }

        return $false
    }

    function parseJsonInfo {
        param($filePath)

        if (!(Test-Path $filePath)) { return $null }

        return Get-Content -Path $filePath -Encoding Ascii | ConvertFrom-Json
    }

    function saveJsonInfo {
        param(
            $filePath,
            $package,
            $headers32,
            $headers64
        )

        $infoToSave = @{
            Version = $package.Version
        }

        if ($headers32) { $infoToSave['URL32'] = $headers32 }
        if ($headers64) { $infoToSave['URL64'] = $headers64 }

        $infoToSave | ConvertTo-Json -Compress | Out-File -Encoding ascii -FilePath $filePath -Force -NoNewline
    }

    if (!$URL32 -and !$URL64) { throw "Either 32bit or 64bit version needs to be specified." }

    if (!$DownloadFiles) { $DownloadFiles = ${function:Invoke-FileDownload} }
    if (!$ParseVersion) { $ParseVersion = ${function:Update-VersionInformation} }
    if (!$ParseStoredInfo) { $ParseStoredInfo = ${function:parseJsonInfo} }
    if (!$SaveStoredInfo) { $SaveStoredInfo = ${function:saveJsonInfo} }
    if (!$OnVersionMismatch) {
        $OnVersionMismatch = {
            throw ("The 32bit and 64bit version do not match`nActual versions are as follows:`n" +
                "32bit: $($result.Version32)`n" +
                "64bit: $($result.Version64)")
        }
    }

    $existingHeaders = . $ParseStoredInfo -filePath $FilePath
    $update = $global:au_Force -or !$existingHeaders

    $remoteHeaders32 = if ($URL32) { Get-RemoteHeaders -uri $URL32 -OnlyUseHeaders $AcceptedHeaders } else { $null }
    $remoteHeaders64 = if ($URL64) { Get-RemoteHeaders -uri $URL64 -OnlyUseHeaders $AcceptedHeaders } else { $null }

    if (!$update -and $remoteHeaders32) { $update = compareHeaders -existingHeaders $existingHeaders.URL32 -remoteHeaders $remoteHeaders32 }
    if (!$update -and $remoteHeaders64) { $update = compareHeaders -existingHeaders $existingHeaders.URL64 -remoteHeaders $remoteHeaders64 }

    if (!$update) {
        $result = @{
            Version = $existingHeaders.Version
        }
        if ($URL32) {
            $result["URL32"] = $URL32
        }
        if ($URL64) {
            $result["URL64"] = $URL64
        }

        return $result
    }
    else {

        $result = . $DownloadFiles -URL32 $URL32 -URL64 $URL64 -Options $DownloadOptions

        if (!(. $ParseVersion -Package $result -UseFileVersion:$UseFileVersion)) {
            . $OnVersionMismatch -Package $result
            return
        }

        $result["Version"] = if ($URL32) { $result["Version32"] } else { $result["Version64"] }

        . $SaveStoredInfo -filePath $filePath -package $result -headers32 $remoteHeaders32 -headers64 $remoteHeaders64

        return $result
    }
}
