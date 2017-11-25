[CmdletBinding()]
param(
    [Parameter(Mandatory = $true)]
    [string]$ModulePath,

    [Parameter(Mandatory = $true)]
    [Version]$Version
)
$ErrorActionPreference = "Stop"

$moduleName = Split-Path -Leaf $ModulePath

Write-Verbose "Getting public module functions"
$functions = Get-ChildItem $ModulePath/public/*.ps1 | ForEach-Object { $_.Name -replace '\.ps1$' }

Write-Verbose "Getting public module aliases"
try { Import-Module $ModulePath -Force } catch { throw $_ }
$aliases = Get-Alias | Where-Object { $_.Source -eq $moduleName -and ($functions -contains $_.Definition )}
Write-Verbose "Getting public variables"
$variables = Get-Variable | Where-Object { $_.Module -eq $moduleName -and ($functions -contains $_.Name )}
$cmdlets = @()

Write-Verbose "Generatinv module manifest"
$params = @{
    Guid              = "2ade4cb5-31b7-41d9-8c10-6f3cefc118af"
    Author            = "Kim J. Nordmo"
    PowerShellVersion = "3.0"
    Description       = "Helper scripts to make updating packages with AU even easier"
    HelpInfoURI       = "https://github.com/AdmiringWorm/wormies-au-helpers/blob/master/README.md"
    Tags              = "chocolatey", "au", "update"
    LicenseUri        = "https://github.com/AdmiringWorm/wormies-au-helpers/blob/master/LICENSE"
    ReleaseNotes      = "https://github.com/AdmiringWorm/wormies-au-helpers/releases/tag/$Version"
    ProjectUri        = "https://github.com/AdmiringWorm/wormies-au-helpers"

    ModuleVersion     = $Version
    FunctionsToExport = @($functions)
    AliasesToExport   = @($aliases)
    VariablesToExport = @($variables)
    CmdletsToExport   = @($cmdlets)
    Path              = "$modulePath/$moduleName.psd1"
    RootModule        = "$moduleName.psm1"

    RequiredModules   = @('AU')
}

New-ModuleManifest @params
