param(
    [string]$version,
    [string]$user = $env:GITHUB_USERNAME,
    [string]$token = $env:GITHUB_TOKEN,
    [switch]$preRelease
)

$gitReleaseManager = Get-Command "gitreleasemanager.exe" -ErrorAction Ignore
if (!$gitReleaseManager) {
    throw "git release manager executable was not found"
}

$cmd = "'$gitReleaseManager' create -c master -m '$version' -n '$version Release' -u '$user' -p '$token'"
$splits = ("git remote get-url origin" | Invoke-Expression) -split '\/|\.git$'
$repoUser = $splits | Select-Object -Last 1 -Skip 2
$repoName = $splits | Select-Object -Last 1 -Skip 1
$cmd += " -o '$repoUser' -r '$repoName'"

if ($preRelease) { $cmd += ' --pre' }

if ($preRelease) {
    "Drafting $version pre-release release for $reponame"
}
else {
    "Drafting $version release for $repoName"
}
"& $cmd" | Invoke-Expression
