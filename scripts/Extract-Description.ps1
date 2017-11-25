param(
    [Parameter(Mandatory = $true)]
    [string]$scriptFile,
    [Parameter(Mandatory = $true)]
    [string]$outDirectory
)
$ErrorActionPreference = "Stop"

if (!(Test-Path $scriptFile)) { Write-Warning "File doesn't exist. Skipping..."}

if (!(Test-Path $outDirectory)) { mkdir $outDirectory -Force }

$data = @{}
$key = $null
$propKey = $null
$startRead = $false
$exampleId = -1
$content = Get-Content $scriptFile -Encoding UTF8
$examples = New-Object System.Collections.Generic.List[string]

foreach ($line in $content) {
    if ($line -match "^\<#" -and $line -match "AUTHOR") { continue }
    elseif ($line -match "^\<#") { $startRead = $true; continue }
    elseif ($startRead -and $line -match "^\.[A-Z]+") {
        if ($line -match "^\.PARAMETER") {
            $propKey = $line -split ' ' | Select-Object -first 1 -skip 1
            $key = $null
            if (!$data["parameters"]) {
                $data["parameters"] = @{ }
            }
        }
        else {
            $key = $line.Trim(' ', '.').ToLowerInvariant()
            if ($key -eq 'example') { $exampleId += 1 }
            $propKey = $null
        }
        continue
    }
    elseif ($startRead -and $line -match "#\>") { break }
    elseif ($startRead -and $propKey) {
        if ($data["parameters"][$propKey]) {
            $data["parameters"][$propKey] += "`n$($line.Trim())"
        }
        else {
            $data["parameters"][$propKey] = $line.Trim()
        }
    }
    elseif ($startRead -and $key) {
        if ($key -eq 'example') {
            if ($line.Trim()) {
                if ($examples.Count - 1 -lt $exampleId) {
                    $examples.Add($line.Trim())
                }
                else {
                    $examples[$exampleId] += "`n$($line.Trim())"
                }
            }
        }
        elseif ($data[$key]) {
            $data[$key] += "`n$($line.Trim())"
        }
        else {
            $data[$key] = $line.Trim()
        }
    }
}

if ($examples -gt 0) {
    $data["examples"] = $examples
}

$fileName = (Split-Path -Leaf $scriptFile) -replace "\.ps1$", ".help.json"
$path = "$outDirectory/about_$fileName"
$data | ConvertTo-Json | Out-File -FilePath $path -Encoding ascii

if (Test-Path Env:\APPVEYOR) {
    Push-Location "$PSScriptRoot/.."
    $langPath = (Resolve-path -Relative $path).TrimStart('\', '.')
    $langPath = $langPath -replace 'en', '<lang>' -replace '\\', '/'
    Pop-Location
    if ($langPath -eq $scriptFile) { return }
    Write-Verbose "Creating transifex settings"
    $slug = (Split-Path -Leaf $scriptFile) -replace '\.ps1'
    $slug = $slug.ToLowerInvariant()
    $slug = "wormies-au-helpers.about_$slug"
    $cmd = "tx set --auto-local -r $slug '$langPath' --source-lang en --type KEYVALUEJSON --execute"

    Write-Debug "Calling $cmd"
    "& $cmd" | Invoke-Expression
}
