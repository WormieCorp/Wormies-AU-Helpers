$ErrorActionPreference = 'Stop'

function Get-NuspecMetadata {
    param(
        [ValidateScript( { Test-Path $_ })]
        [Parameter(Mandatory = $true)]
        [string]$nuspecFile
    )

    $nuspecFile = Resolve-path $nuspecFile

    $nu = New-Object xml
    $nu.PSBase.PreserveWhitespace = $true
    $nu.Load($nuspecFile)

    $result = @{}

    $nu.package.metadata.ChildNodes | ForEach-Object {
        if ($_.NodeType -eq "Element") {
            $result[$_.Name] = $_.InnerText
        }
    } | Out-Null

    return $result
}
