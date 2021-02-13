param(
    [string]$PathToModule,
    [string]$ModuleName = "Wormies-AU-Helpers",
    [string]$OutputFolderPath = "$PSScriptRoot/../docs/input/docs/functions"
)

function GenerateTemporaryFile {
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

function GenerateSyntax {
    param($syntax, [bool]$commonParameters)

    $sb = New-Object System.Text.StringBuilder

    $sb.Append($syntax.name) | Out-Null

    foreach ($param in $syntax.parameter | Sort-Object Position) {
        $sb.AppendLine(' `') | Out-Null
        $sb.Append("    ") | Out-Null
        if ($param.required -eq 'false') { $sb.Append('[') | Out-Null }
        $sb.AppendFormat("-{0} <{1}>", $param.name, $param.parameterValue) | Out-Null
        if ($param.required -eq 'false') { $sb.Append(']') | Out-Null }
    }

    if ($commonParameters) {
        $sb.AppendLine(' `') | Out-Null
        $sb.Append("    [<CommonParameters>]") | Out-Null
    }

    return $sb.ToString()
}

function GenerateParameterTable {
    param(
        $parameters,
        $arrParameterProperties
    )

    forEach ($item in $parameters) {
        '### -' + $item.name + " \<" + $item.Type.Name + "\>`n"
        ($item.Description | Out-String).Trim() + "`r`n"
        $propLen = $arrParameterProperties | ForEach-Object { $_ -split '\:' | Select-Object -last 1 } | Measure-Object -Maximum -Property Length | ForEach-Object Maximum
        $propLen += 2

        $valLen = $arrParameterProperties | ForEach-Object { $_ -split '\:' | Select-Object -first 1 | ForEach-Object { $item.$_ } } | Measure-Object -Maximum -Property Length | ForEach-Object Maximum
        $valLen += 2
        if ($valLen -lt 7) { $valLen = 7 }
        if ($propLen -lt 10) { $propLen = 10 }

        $format = '|{0,-' + $propLen + '}|{1,' + $valLen + '}|'

        ($format -f " Property ", " Value ")
        "|:" + ("-" * ($propLen - 1)) + "|:" + ("-" * ($valLen - 2)) + ":|"

        foreach ($arrParameterProperty in $arrParameterProperties) {
            $splits = $arrParameterProperty -split '\:'
            $name = if ($splits.Length -ge 2) { $splits[1] } else { $splits[0] }
            $val = $item."$($splits[0])" -replace "([\\\/\<\>])", '\$1'
            $format -f " $name ", " $val "
        }

        ""
    }
}

if (!(Test-Path $OutputFolderPath)) { New-Item -ItemType Directory -Path $OutputFolderPath }
$OutputFolderPath = Resolve-Path $OutputFolderPath

$arrParameterProperties = @(
    "Aliases",
    'Position:Position?'
    'Globbing:Globbing?'
    'DefaultValue:Default Value',
    'PipelineInput:Accept Pipeline Input?'
)

# Prepare output file name which is temporary due to UTF conversion
$outputFile = (GenerateTemporaryFile).Fullname
#$outputFile = "C:\Users\nord_\AppData\Local\Temp\testing.md"

$b = {
    Remove-Module $ModuleName -Force -ea 0
    $Module = Import-Module $PathToModule -Force

    $commands = Get-Command -Module $ModuleName | Where-Object CommandType -ne 'Alias'

    $tags = . git tag
    $prevTag = "e50169dd32d8ddeb8c5eae3fc81415376dd6b58b" # The first commit in this repo

    $tagsWithCommands = @{ }

    foreach ($tag in $tags) {
        $functions = git diff "$prevTag..$tag" --name-only | ForEach-Object {
            (Split-Path -Leaf $_) -split '\.ps1' | Select-Object -first 1
        } | Where-Object {
            $file = $_
            $commands | Where-Object { $file -eq $_.Name }
        }

        if ($functions) {
            $tagsWithCommands[$tag] = [array]$functions
        }
        $prevTag = $tag
    }

    [array]$nextFunctions = git diff "$prevTag.." --name-only | ForEach-Object {
        (Split-Path -Leaf $_) -split "\.ps1" | Select-Object -first 1
    } | Where-Object {
        $file = $_
        $commands | Where-Object { $file -eq $_.Name }
    } | Where-Object {
        $file = $_
        $commandsInPreviousTag = $tagsWithCommands.Values | Where-Object { $_ -eq $file }
        !$commandsInPreviousTag
    }

    foreach ($singleFunction in (Get-Command -Module $ModuleName | Where-Object CommandType -ne 'Alias').Name) {
        # Get functionHelp for the current function
        $functionHelp = Get-Help $singleFunction -Full -ErrorAction SilentlyContinue
        "Generating wyam documentation for function: '$singleFunction'"

        # Add function base name

        "---`r`nTitle: " + $singleFunction | Out-File -FilePath $outputFile -Force

        # Add synopsis
        if ($functionHelp.Synopsis) {
            "Description: " + $functionHelp.Synopsis.Trim() + "`r`n---`r`n" | Out-File -FilePath $outputFile -Append
        }
        else {
            "---`r`n" | Out-File -FilePath $outputFile -Force
        }

        if ($nextFunctions -and ($nextFunctions.Contains($singleFunction))) {
            ":::{.alert .alert-warning}`r`n**Preliminary Notice**`r`n`r`nThis function has not yet been made available. It is a planned function for the next minor version.`r`n:::" | Out-File -FilePath $outputFile -Append
        }
        else {
            [version]$tag = $tagsWithCommands.GetEnumerator() | Where-Object { $_.Value | Where-Object { $_ -eq $singleFunction } } | ForEach-Object { $_.Key } | Sort-Object | Select-Object -First 1

            ":::{.alert .alert-info}`r`nThis function was introduced in version [**$tag**](https://github.com/WormieCorp/Wormies-AU-Helpers/releases/tag/$tag).`r`n:::" | Out-File -FilePath $outputFile -Append
        }

        if ($functionHelp.Synopsis) {
            $functionHelp.Synopsis + " `r`n" | Out-File -FilePath $outputFile -Append
        }

        $commonParameters = if ($functionHelp.CommonParameters) { $true } else { $false }

        # Add Syntax
        if ($functionHelp.Syntax) {
            '## Syntax' | Out-File -FilePath $outputFile -Append

            $functionHelp.Syntax.syntaxItem | ForEach-Object { "``````PowerShell`r`n" + (GenerateSyntax -syntax $_ -commonParameters $commonParameters) + "`r`n```````r`n" } | Out-File -FilePath $outputFile -Append
        }

        # Add Description
        if ($functionHelp.Description) {
            '## Description' | Out-File -FilePath $outputFile -Append
            $functionHelp.Description.Text + "`r`n" | Out-File -FilePath $outputFile -Append
        }

        if ($functionHelp.alertSet) {
            '## Notes' | Out-File -FilePath $outputFile -Append
            $functionHelp.alertSet.alert.text | Out-File -FilePath $outputFile -Append
        }

        $aliases = Get-Alias -Definition $singleFunction -ErrorAction SilentlyContinue

        "## Aliases" | Out-File -FilePath $outputFile -Append
        if ($aliases) {
            $aliases | ForEach-Object { "``$_``  " } | Out-File $outputFile -Append
            "" | Out-File $outputFile -Append
        }
        else {
            "None`r`n" | Out-File -FilePath $outputFile -Append
        }

        # Add examples
        if ($functionHelp.Examples) {
            "## Examples `r`n" | Out-File -FilePath $outputFile -Append
            forEach ($item in $functionHelp.Examples.Example) {
                "`r`n### " + $item.title.Replace('-', '').Replace('EXAMPLE', 'Example') | Out-File -FilePath $outputFile -Append
                if ($item.Code) {
                    "``````PowerShell`r`n" + $item.Code.Trim() + "`r`n``````" | Out-File -FilePath $outputFile -Append
                }
                if ($item.Remarks) {
                    ($item.Remarks | Out-String).Trim() | Out-File -FilePath $outputFile -Append
                }
            }

            "" | Out-File -FilePath $outputFile -Append
        }

        "## Inputs" | Out-File -FilePath $outputFile -Append

        if ($functionHelp.input) {
            $functionHelp.input + "`r`n" | Out-File -FilePath $outputFile -Append
        }
        else {
            "None`r`n" | Out-File -FilePath $outputFile -Append
        }

        "## Outputs" | Out-File -FilePath $outputFile -Append

        if ($functionHelp.returnValues) {
            foreach ($text in $functionHelp.returnValues.returnValue.type.name) {
                "$text`r`n" | Out-File -FilePath $outputFile -Append
            }
        }
        else {
            "None`r`n" | Out-File -FilePath $outputFile -Append
        }

        # Add parameters
        if ($functionHelp.Parameters) {
            $requiredParams = $functionHelp.Parameters.Parameter | Where-Object required -eq 'true'
            $optionalParams = $functionHelp.Parameters.Parameter | Where-Object required -eq 'false'
            if ($requiredParams) {
                "## Required Parameters`r`n" | Out-File -FilePath $outputFile -Append
                GenerateParameterTable -parameters $requiredParams -arrParameterProperties $arrParameterProperties | Out-File -FilePath $outputFile -Append
            }

            if ($optionalParams) {
                "## Optional Parameters`r`n" | Out-File -FilePath $outputFile -Append
                GenerateParameterTable -parameters $optionalParams -arrParameterProperties $arrParameterProperties | Out-File -FilePath $outputFile -Append
            }
        }

        if ($commonParameters) {
            if (!$functionHelp.parameters) { "## Parameters " | Out-File -FilePath $outputFile -Append }
            "### <CommonParameters>`r`nThis cmdlet supports the common parameters: -Verbose, -Debug, -ErrorAction, -ErrorVariable, -OutBuffer, and -OutVariable. For more information, see `about_commonParameters` https://go.microsoft.com/fwlink/p/?LinkID=113216" | Out-File -FilePath $outputFile -Append
        }

        if ($functionHelp.relatedLinks) {
            $links = New-Object System.Collections.Generic.List[string]

            foreach ($link in $functionHelp.relatedLinks.navigationLink) {
                if ($link.linkText -and $link.uri) {
                    $links.Add("- [$($link.linkText)]($($link.uri))")
                }
                elseif ($link.uri) {
                    # First check if this uri is the one for this function
                    $name = $link.uri -split '\/' | Select-Object -last 1
                    $funcSlug = $singleFunction.ToLowerInvariant()
                    if ($name -ne $funcSlug) {
                        $links.Add("- <$($link.uri)>")
                    }
                }
                elseif ((Get-Command -Module $ModuleName -Name $link.linkText -ErrorAction SilentlyContinue)) {
                    # Now we know it is a local function
                    $funcSlug = (Get-Command -Module $ModuleName $link.linkText).Name.ToLowerInvariant()
                    $links.Add(" - [$($link.linkText)]($funcSlug)")
                }
                else {
                    $helpItem = Get-Help $link.linkText | Where-Object { $_.relatedLinks.navigationLink.uri } | ForEach-Object { $_.relatedLinks.navigationLink | Select-Object -first 1 }
                    if ($helpItem.linkText) {
                        $Links.Add("- [$($helpItem.linkText)]($($helpItem.uri)) {target=_blank}")
                    }
                    else {
                        $links.Add("- [$($link.linkText)]($($helpItem.uri)) {target=_blank}")
                    }
                }

                #" - <$uri>" | Out-File -FilePath $outputFile -Append
                if ($links.Count -gt 0) {
                    '## Related Links' | Out-File -FilePath $outputFile -Append
                    $links | Out-File -FilePath $outputFile -Append
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
