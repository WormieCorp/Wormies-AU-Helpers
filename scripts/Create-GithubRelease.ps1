param(
    [string]$version,
    [string]$user = $env:GITHUB_USERNAME,
    [string]$token = $env:GITHUB_TOKEN,
    [switch]$publishRelease
)

$ErrorActionPreference = 'Stop'

$gitReleaseManager = Get-Command "gitreleasemanager.exe" -ErrorAction Ignore
if (!$gitReleaseManager) {
    throw "git release manager executable was not found"
}

$args = "-t '$version' -u '$user' -p '$token'"
$splits = ("git remote get-url origin" | Invoke-Expression) -split '\/|\.git$'
$repoUser = $splits | Select-Object -Last 1 -Skip 2
$repoName = $splits | Select-Object -Last 1 -Skip 1
$args += " -o '$repoUser' -r '$repoName'"

$assets = Get-ChildItem $PSScriptRoot/.. -Include "*.7z", "*.nupkg" -Recurse | % FullName

"Uploading the followings assets to $repoName for version $version"
$assets | % { "  - " + (Split-Path -Leaf $_) }

"& '$gitReleaseManager' addasset $args --assets $assets" | Invoke-Expression

if ($publishRelease) {
    $args = $args -replace '\-t', '-m'
    "Closing $version milestone"
    "& '$gitReleaseManager' close $args" | Invoke-Expression
    $args = $args -replace '\-m', '-t'
    "Publishing $version release"
    "& '$gitReleaseManager' publish $args" | Invoke-Expression
}

"Exporting Release Notes..."
"& '$gitReleaseManager' export $args --fileOutputPath $PSScriptRoot\..\chocolatey\CHANGELOG.md" | Invoke-Expression
