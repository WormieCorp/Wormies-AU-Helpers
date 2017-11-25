param(
    [switch]$Chocolatey,
    [switch]$Pester,
    [string]$Tag,
    [switch]$CodeCoverage
)

if (!$Chocolatey -and !$Pester) { $Chocolatey = $Pester = $true }

$buildDir = gi $PSScriptRoot/.build/*

if ($Chocolatey) {
    "`n==| Running Chocolatey tests"

    Test-Package $buildDir
}

if ($Pester) {
    "`n==| Running Pester tests"

    $testResultsFile = "$buildDir/TestResults.xml"
    if ($CodeCoverage) {
        $files = @(ls $PSScriptRoot/Wormies-AU-Helpers/* -Filter *.ps1 -Recurse | % FullName)
        if ((Test-Path Env:\APPVEYOR) -and (Get-Command Export-CodeCovIoJson -ea 0)) {
            $coverageFile = "$buildDir/coverage.xml"
            $res = Invoke-Pester -OutputFormat NUnitXml -OutputFile $testResultsFile -PassThru -CodeCoverage $files -CodeCoverageOutputFile "$coverageFile"
            (New-Object "System.Net.WebClient").UploadFile("https://ci.appveyor.com/testresults/nunit/$($env:APPVEYOR_JOB_ID)", (Resolve-Path $testResultsFile))
            Export-CodeCovIoJson -CodeCoverage $res.CodeCoverage -RepoRoot $PSScriptRoot -Path "$buildDir/coverage.json"
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
