param(
    [string]$PathToModule,
    [string]$ModuleName = "Wormies-AU-Helpers",
    [string]$OutputFolderPath = "$PSScriptRoot/../docs/input/docs/functions"
)

function Generate-TemporaryFile {
    <#
    .SYNOPSIS
    Function used to generate a temporary file.

    .DESCRIPTION
    Generates a new file in temporary folder. The method of creation depends on the powershell version used
    #>
    if ($PSVersionTable.PSVersion.Major -ge 5) {
        return New-TemporaryFile
    }
    else {
        return (New-Item -ItemType File -Path $env:TEMP -Name (New-Guid).Guid)
    }
}

if (!(Test-Path $OutputFolderPath)) { mkdir -Path $OutputFolderPath }
$OutputFolderPath = Resolve-Path $OutputFolderPath

$arrParameterProperties = @(
    'DefaultValue',
    'ParameterValue',
    'PipelineInput',
    'Position',
    'Required'
)

# Prepare output file name which is temporary due to UTF conversion
$outputFile = (Generate-TemporaryFile).Fullname

$b = {
    Remove-Module $ModuleName -Force -ea 0
    $Module = Import-Module $PathToModule -Force

    foreach ($singleFunction in (Get-Command -Module $ModuleName).Name) {
        # Get functionHelp for the current function
        $functionHelp = Get-Help $singleFunction -ErrorAction SilentlyContinue

        # Add function base name

        "---`r`nTitle: " + $singleFunction | Out-File -FilePath $outputFile -Force

        # Add synopsis
        if ($functionHelp.Synopsis) {
            "Description: " + $functionHelp.Synopsis + "`r`n---" | Out-File -FilePath $outputFile -Append
            '## Synopsis' | Out-File $outputFile -Append
            $functionHelp.Synopsis + " `r`n" | Out-File -FilePath $outputFile -Append
        }
        else {
            "---`r`n" | Out-File -FilePath $outputFile -Force
        }

        # Add Syntax
        if ($functionHelp.Syntax) {
            '## Syntax' | Out-File -FilePath $outputFile -Append
            "``````PowerShell`r`n" + ($functionHelp.Syntax | Out-String).trim() + "`r`n```````r`n" | Out-File -FilePath $outputFile -Append
        }

        # Add Description
        if ($functionHelp.Description) {
            '## Description' | Out-File -FilePath $outputFile -Append
            $functionHelp.Description.Text + "`r`n" | Out-File -FilePath $outputFile -Append
        }

        # Add parameters
        if ($functionHelp.Parameters) {
            '## Parameters' | Out-File -FilePath $outputFile -Append
            forEach ($item in $functionHelp.Parameters.Parameter) {
                '### ' + $item.name | Out-File -FilePath $outputFile -Append
                $item.Description + "`r`n" | Out-File -FilePath $outputFile -Append
                '- **Type**: ' + $item.Type.Name | Out-File -FilePath $outputFile -Append
                forEach ($arrParameterProperty in $arrParameterProperties) {
                    if ($item.$arrParameterProperty) {
                        "- **$arrParameterProperty**: " + $item.$arrParameterProperty | Out-File -FilePath $outputFile -Append
                    }

                }
            }
        }

        # Add examples
        if ($functionHelp.Examples) {
            "## Examples `r`n" | Out-File -FilePath $outputFile -Append
            forEach ($item in $functionHelp.Examples.Example) {
                "`r`n### " + $item.title.Replace('-', '').Replace('EXAMPLE', 'Example') | Out-File -FilePath $outputFile -Append
                if ($item.Code) {
                    "``````PowerShell`r`n" + $item.Code + "`r`n``````" | Out-File -FilePath $outputFile -Append
                }
                if ($item.Remarks) {
                    $item.Remarks | Out-File -FilePath $outputFile -Append
                }
            }
        }

        $resultFileName = $singleFunction.ToLowerInvariant() + ".md"
        $finalFileName = Join-Path $OutputFolderPath $resultFileName

        [System.IO.File]::ReadAllText($outputFile) | Out-File -FilePath $finalFileName -Encoding utf8
    }

    Remove-Item $outputFile -Force
}

. $b

Remove-Module $ModuleName
