function Get-RemoteHeaders {
    param([string]$uri, [string[]]$OnlyUseHeaders = $null)

    $req = [System.Net.WebRequest]::CreateDefault($uri)

    $resp = $req.GetResponse()

    $headers = @{}

    $resp.Headers.AllKeys | ? {
        $key = $_
        (!$OnlyUseHeaders -or ($OnlyUseHeaders | ? { $_ -eq $key }))
    } | % {
        $value = ([System.Net.WebResponse]$resp).Headers.GetValues($_)
        if ($value.Count -eq 1) { $headers[$_] = $value | select -first 1 }
        elseif ($value.Count -gt 1) { $headers[$_] = $value }
    }

    return $headers
}
