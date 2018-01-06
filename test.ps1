param(
    [switch]$Chocolatey,
    [switch]$Pester,
    [string]$Tag,
    [switch]$CodeCoverage
)

$ErrorActionPreference = 'Stop'

if (!$Chocolatey -and !$Pester) { $Chocolatey = $Pester = $true }

$buildDir = Get-Item $PSScriptRoot/.build/*

if ($Chocolatey) {
    "`n==| Running Chocolatey tests"

    Test-Package $buildDir
}

if ($Pester) {
    "`n==| Running Pester tests"

    $testResultsFile = "$buildDir/TestResults.xml"
    if ($CodeCoverage) {
        $files = @(Get-ChildItem $PSScriptRoot/Wormies-AU-Helpers/* -Filter *.ps1 -Recurse | ForEach-Object FullName)
        if ((Test-Path Env:\APPVEYOR) -and (Get-Command Export-CodeCovIoJson -ea 0)) {
            $res = Invoke-Pester -OutputFormat NUnitXml -OutputFile $testResultsFile -PassThru -CodeCoverage $files -CodeCoverageOutputFile "coverage.xml"
            $wc = New-Object 'System.Net.WebClient'
            $wc.UploadFile("https://ci.appveyor.com/api/testresults/nunit/$($env:APPVEYOR_JOB_ID)", (Resolve-Path $testResultsFile))
            Export-CodeCovIoJson -CodeCoverage $res.CodeCoverage -RepoRoot $PSScriptRoot -Path "coverage.json" | Out-Null
            if ($res.FailedCount -gt 0) {
                throw "$($res.FailedCount) tests failed"
            }
        }
        else {
            $res = Invoke-Pester -Tag $Tag -OutputFormat NUnitXml -OutputFile $testResultsFile -PassThru -CodeCoverage $files
        }
    }
    else {
        $res = Invoke-Pester -Tag $Tag -OutputFormat NUnitXml -OutputFile $testResultsFile -PassThru
    }
}
