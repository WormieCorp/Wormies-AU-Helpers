# Build the chocolatey package based on the latest module built in ..\.build folder

$buildPath = Resolve-Path $PSScriptRoot/../.build
$version = Get-ChildItem $buildPath | Sort-Object CreationDate -Descending | Select-Object -First 1 -Expand Name
$version = $version.ToString()
if (!$version) { throw "Latest module build can not be found" }
$modulePath = "$buildPath/$version/Wormies-AU-Helpers"

. $modulePath/private/Test-ValidVersion.ps1
if (!(Test-ValidVersion -version $version)) {
    throw "Latest module is not a valid version."
}

$nuspecPath = "$PSScriptRoot/wormies-au-helpers.nuspec"

"`n==| Building Chocolatey package for Wormies-AU-Helpers $version at '$modulePath'`n"

"Setting description"
$readmePath = Resolve-Path "$PSScriptRoot/../README.md"
$readme = Get-Content $readmePath -Raw
$res = $readme -match "## Features(.|\n)+?(?=\n##)"
if (!$res) { throw "Can't find markdown header 'Features' in the README.md" }

$features = $Matches[0]
"Updating nuspec file"
$nuspecBuildPath = $nuspecPath -replace "\.nuspec$", "_build.nuspec"
[xml]$au = Get-Content $nuspecPath -Encoding UTF8
$description = $au.package.metadata.summary + ".`n`n" + $features
$au.package.metadata.version = $version
$au.package.metadata.description = $description
$au.package.metadata.releaseNotes = "https://github.com/majkinetor/au/releases/tag/" + $version
$au.Save($nuspecBuildPath)

"Copying module"
Copy-Item -Force -Recurse $modulePath $PSScriptRoot/tools
Copy-Item $PSScriptRoot/../install.ps1 $PSScriptRoot/tools

Remove-Item $PSScriptRoot/*.nupkg
choco pack -r $nuspecBuildPath --outputdirectory $PSScriptRoot
Remove-Item $nuspecBuildPath -ErrorAction Ignore
