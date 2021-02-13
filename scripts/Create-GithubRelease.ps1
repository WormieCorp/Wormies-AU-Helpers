param(
    [string]$version,
    [string]$user = $env:GITHUB_USERNAME,
    [string]$token = $env:GITHUB_TOKEN,
    [switch]$publishRelease
)

$ErrorActionPreference = 'Stop'

$useDotnet = $false
$gitReleaseManager = Get-Command "gitreleasemanager.exe" -ErrorAction Ignore | ForEach-Object Source
if (!$gitReleaseManager) {
    $gitReleaseManager = "gitreleasemanager"
    $useDotnet = $true
}

$args = "-t '$version' --token '$token'"
$splits = ("git remote get-url origin" | Invoke-Expression) -split '\/|\.git$'
$repoUser = $splits | Select-Object -Last 1 -Skip 2
$repoName = $splits | Select-Object -Last 1 -Skip 1
$args += " -o '$repoUser' -r '$repoName'"

$assets = Get-ChildItem $PSScriptRoot/../.build -Include "*.7z", "*.nupkg" -Recurse | ForEach-Object FullName

"Uploading the followings assets to $repoName for version $version"
$assets | ForEach-Object { "  - " + (Split-Path -Leaf $_) }

$cmd = if ($useDotnet) { "& dotnet" } else { "&" }
"$cmd '$gitReleaseManager' addasset $args --assets $assets" | Invoke-Expression

if ($publishRelease) {
    $args = $args -replace '\-t', '-m'
    "Closing $version milestone"
    "$cmd '$gitReleaseManager' close $args" | Invoke-Expression
    $args = $args -replace '\-m', '-t'
    "Publishing $version release"
    "$cmd '$gitReleaseManager' publish $args" | Invoke-Expression
}

"Exporting Release Notes..."
"$cmd '$gitReleaseManager' export $args --fileOutputPath '$PSScriptRoot\..\chocolatey\CHANGELOG.md'" | Invoke-Expression
