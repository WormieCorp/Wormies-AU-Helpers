param(
    [string]$Version = $null,
    [switch]$Install,
    [switch]$Clean,
    [switch]$NoChocoPackage
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
        Version    = $Version -split '\-' | select -first 1
    }

    & $PSScriptRoot/scripts/Create-ModuleManifest.ps1 @params
}

function CreateHelp {
    "Creating module help"

    $helpDir = "$PSScriptRoot/docs/en-US"
    $buildHelpDir = "$modulePath"
    mkdir -Force $buildHelpDir | Out-Null
    Get-Content $PSScriptRoot/README.md -Encoding UTF8 | Select-Object -Skip 4 | Set-Content "$helpDir/about_${module_name}.help.txt" -Encoding Ascii

    Get-ChildItem $modulePath/public -Filter "*.ps1" -Recurse | ForEach-Object {
        $content = Get-Content $_.FullName -Encoding UTF8
        $startRead = $false
        $sb = New-Object System.Text.StringBuilder
        foreach ($line in $content) {
            if ($line -match "\<#" -and $line -match "AUTHOR") { continue }
            elseif ($line -match "\<#") { $startRead = $true ; continue }
            elseif ($line -match "#\>") { break }

            $sb.AppendLine($line) | Out-Null
        }

        $sb.ToString() | Set-Content "$helpDir/about_$($_.BaseName).help.txt" -Encoding Ascii
    }

    $helpDir = Split-Path -Parent $helpDir

    Get-ChildItem $helpDir -Filter "*.json" -Recurse | ForEach-Object {
        $content = Get-Content $_.FullName -Encoding UTF8 | ConvertFrom-Json
        $dirName = (Split-Path -Parent $_.FullName) -replace ("^" + [regex]::Escape($helpDir) + '(\\|\/)')
        mkdir -Force "$buildHelpDir/$dirName" | Out-Null
        Set-Content -Path "$buildHelpDir/$dirName/$($_.BaseName).psd1" -Encoding UTF8 -Value $content
    }

    Copy-Item -Recurse -Force $helpDir/* $buildHelpDir -Exclude "*.json"
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
#$installerPath = "$PSScriptRoot/install.ps1"
$removeOld = $true

"`n==| Building $moduleName $version`n"
init

$modulePath = "$buildDir/$moduleName"
CreateManifest
CreateHelp
