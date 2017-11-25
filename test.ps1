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
        Invoke-Pester -Tag $Tag -OutputFormat NUnitXml -OutputFile $testResultsFile -PassThru -CodeCoverage $files
    }
    else {
        Invoke-Pester -Tag $Tag -OutputFormat NUnitXml -OutputFile $testResultsFile -PassThru
    }
}
