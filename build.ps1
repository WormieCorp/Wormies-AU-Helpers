param(
    [string]$Version = $null,
    [switch]$Install,
    [switch]$Clean,
    [switch]$NoChocoPackage
)
$ErrorActionPreference = "Stop"

if ($Clean) { git clean -Xfd -e vars.ps1; return }
if (!$Version) {
    "Finding installed GitVersion executable"
    $gitVersion = Get-Command GitVersion.exe | ForEach-Object Source
    if ($env:APPVEYOR -eq $true) {
        $cmd = ". '$gitVersion' /output buildserver"
        Write-Information "Running $cmd"
        $cmd | Invoke-Expression
    }
    $cmd = ". '$gitVersion' /output json /showvariable NuGetVersionV2"
    Write-Verbose "Running $cmd"
    Write-Information "Calculating version using gitversion"
    $Version = $cmd | Invoke-Expression
    "Version found: $Version"
}
