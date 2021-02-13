#requires -version 3

$paths = "private", "public"
foreach ($path in $paths) {
    Get-ChildItem $PSScriptRoot\$path\*.ps1 | ForEach-Object { . $_.FullName }
}
