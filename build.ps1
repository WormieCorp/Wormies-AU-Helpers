param(
    [string]$Version = $null,
    [switch]$Install,
    [switch]$Clean,
    [switch]$NoChocoPackage,
    [switch]$PullTranslations
)
$ErrorActionPreference = "Stop"

function init {
    if ($removeOld) {
        "Removing older builds"
        Remove-Item -Recurse (Split-path $buildDir) -ea Ignore
    }

    mkdir -Force $buildDir | Out-Null
    Copy-Item -Recurse $modulePath $buildDir
}

function CreateManifest {
    "Creating module manifest"
    $params = @{
        ModulePath = $modulePath
        Version    = $Version -split '\-' | Select-Object -first 1
    }

    & $PSScriptRoot/scripts/Create-ModuleManifest.ps1 @params
}

function ZipModule {
    "Creating 7z package"

    $zipPath = "$buildDir/${moduleName}_$version.7z"
    $exec = Get-Command "7z.exe" -ErrorAction Ignore | ForEach-Object Source
    if (!$exec) { $exec = "$Env:ChocolateyInstall/tools/7z.exe" }

    "& '$exec' a -m0=lzma2 -mx=9 '$zipPath' '$modulePath' '$installerPath'" | Invoke-Expression
    if (!(Test-Path $zipPath)) { throw "Failed to build 7z package" }
}

function BuildChocolateyPackage {
    if ($NoChocoPackage) { "Skipping chocolatey package build"; return }

    & $PSScriptRoot/chocolatey/Build-Package.ps1
    Move-Item "$PSScriptRoot/chocolatey/${moduleName}.${version}.nupkg" $buildDir
}

if ($Clean) { git clean -Xfd -e vars.ps1; return }
if (!$Version) {
    Write-Verbose "Finding installed GitVersion executable"
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
    Write-Information "Version found: $Version"
}

$modulePath = "$PSScriptRoot/Wormies-AU-Helpers"
$moduleName = Split-Path -Leaf $modulePath
$buildDir = "$PSScriptRoot/.build/$version"
$installerPath = "$PSScriptRoot/install.ps1"
$removeOld = $true

"`n==| Building $moduleName $version`n"
init

$modulePath = "$buildDir/$moduleName"
CreateManifest

Copy-Item $installerPath $buildDir
ZipModule
BuildChocolateyPackage
