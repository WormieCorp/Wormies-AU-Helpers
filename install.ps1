#requires -version 2
<#
.SYNOPSIS
    Wormies-AU-Helpers

.NOTES
    Always install Wormies-AU-Helpers versionless in Program Files to support older PowerShell versions (v < 5)
    Multiple AU versions can be installed using Install-Module if needed (on Posh 5+)
#>
param(
    #if given it is the path to the module to be installed.
    #If not given, use first build directory, and if it doesn't exist, try scripts folder.
    [string] $modulePath,

    # Remove module from system
    [switch] $Remove
)

$ErrorActionPreference = 'Stop'

$moduleName = "Wormies-AU-Helpers"
$moduleDst = "$Env:ProgramFiles\WindowsPowerShell\Modules"

Remove-Item -Force -Recurse "$moduleDst/$moduleName" -ErrorAction Ignore
if ($Remove) { Remove-Module $moduleName -ErrorAction Ignore; Write-Host "Module $moduleName removed"; return }

Write-Host "`n==| Starting $moduleName installation`n"

if (!$modulePath) {
    if (Test-Path $PSScriptRoot/.build/*) {
        $modulePath = (Get-ChildItem $PSScriptRoot/.build/* -ErrorAction Ignore | Sort-Object CreationDate -Descending | Select-Object -First 1 -Expand FullName) + "/" + $moduleName
    }
    else {
        $modulePath = "$PSScriptRoot/$moduleName"
        if (!(Test-Path $modulePath)) { throw "modulePath not specified and scripts directory doesn't contain the module" }
    }
}

if (!(Test-Path $modulePath)) { throw "Module path is invalid: '$modulePath'"}

$modulePath = Resolve-Path $modulePath

Write-Host "Module path: '$modulePath'"

Copy-Item -Recurse -Force $modulePath $moduleDst

$res = Get-Module $moduleName -ListAvailable | Where-Object { (Split-Path $_.ModuleBase) -eq $moduleDst }
if (!$res) { throw "Module installation failed" }

Write-Host "`n$($res.Name) version $($res.Version) installed successfully at '$moduleDst\$moduleName"

$functions = $res.ExportedFunctions.Keys

Import-Module $moduleDst/$moduleName -Force
$aliases = Get-Alias | Where-Object { $_.Source -eq $moduleName }

if ($functions.Length) {
    $functions | ForEach-Object {
        [PSCustomObject]@{ Function = $_; Alias = $aliases | Where-Object Defintion -eq $_ }
    } | ForEach-Object { Write-Host ("`n  {0,-20} {1}`n  --------             -----" -f 'Function', 'Alias') } {
        Write-Host ("  {0,-20} {1}" -f $_.Function, "$($_.Alias)")
    }
}

Remove-Module $moduleName
Write-Host "`nTo learn more about ${moduleName}:    man about_$moduleName"
Write-Host "`nSee help for any function:    man updateall`n"
