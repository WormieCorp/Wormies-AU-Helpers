param(
    $docsDirectory,
    $buildDirectory
)

function AppendSection {
    param(
        [System.Text.StringBuilder]$sb,
        [string]$header,
        [string]$line
    )

    $sb.AppendLine($header) | Out-Null
    GetText $line | % {
        $sb.AppendLine($_)
    } | Out-Null
    $sb.AppendLine() | Out-Null
}

function GetText {
    param([string]$line)

    $prevIndex = 0
    $index = $line.IndexOf("`n")
    while ($index -gt 0) {
        $nextLine = "`t" + $line.Substring($prevIndex, $index - $prevIndex)
        $nextLine.TrimEnd()

        $prevIndex = $index + 1
        $index = $line.IndexOf("`n", $prevIndex)
    }

    $nextLine = "`t" + $line.Substring($prevIndex)
    if ($nextLine.Trim()) {
        $nextLine
    }
}

# Before we start, and if we are running on appveyor, we pull down translations first
if (Test-Path Env:\APPVEYOR) {
    $cmd = "tx pull -a --minimum-perc=60"
    "& $cmd" | iex
}

pushd $docsDirectory
gci $docsDirectory -Filter "*.help.json" -Recurse | % {
    $directoryPath = Split-Path -Parent $_.FullName
    $relPath = Resolve-Path $directoryPath -Relative
    if (!(Test-Path $buildDirectory/$relPath)) {
        mkdir $buildDirectory/$relPath -Force
    }

    $sb = New-Object System.Text.StringBuilder

    $data = Get-Content -Encoding UTF8 $_.FullName | ConvertFrom-Json

    $topic = $_.BaseName -replace "\.help$"

    AppendSection $sb "TOPIC" $topic

    if ($data.synopsis) {
        Write-Verbose "Adding SYNOPSIS..."
        AppendSection $sb "SYNOPSIS" $data.synopsis
    }

    if ($data.description) {
        Write-Verbose "Adding DESCRIPTION..."
        AppendSection $sb "DESCRIPTION" $data.description
    }

    if ($data.parameters) {
        Write-Verbose "Adding .PARAMETER sections..."
        $data.parameters | Get-Member -MemberType NoteProperty | % {
            $key = $_.Name
            $value = $data.parameters."$key"
            AppendSection $sb "PARAMETER $key" $value
        }
    }

    if ($data.outputs) {
        Write-Verbose "Adding .OUTPUTS section..."
        AppendSection $sb "OUTPUTS" $data.outputs
    }

    if ($data.examples) {
        $data.examples | % {
            AppendSection $sb "EXAMPLE" $_
        }
    }

    $fileName = "$($_.BaseName).txt"

    $sb.ToString().TrimEnd() | Out-File "$buildDirectory/$relPath/$fileName" -Encoding utf8
}
popd
