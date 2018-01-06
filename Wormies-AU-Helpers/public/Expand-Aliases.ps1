<#
.SYNOPSIS
    Expands the aliases in either the file or text passed to the function.

    .DESCRIPTION
    Any scripts in 'corporate' or 'formal' use should have any aliases expanded.
    This this removes ambiguity and any potential clashes or errors.

.PARAMETER Text
    The script text that should parsed for aliases to expand.

.EXAMPLE
    Expand-Aliases -Text "rm file.txt; gi file.exe"

    Should be expanded to "Remove-Item file.txt; Get-Item file.exe"
#>

function Expand-Aliases () {
    param(
        [Parameter(Mandatory = $true, ParameterSetName = 'text')]
        [string]$Text,
        [Parameter(Mandatory = $true, ParameterSetName = 'directory')]
        [string]$Directory,
        [Parameter(Mandatory = $false, ParameterSetName = 'directory')]
        [string]$Filter = "*.ps1",
        [Parameter(Mandatory = $true, ParameterSetName = 'files')]
        [string[]]$Files
    )

    BEGIN {
        $moduleExists = Get-Module chocolateyInstaller -All -ErrorAction SilentlyContinue
        if (!$moduleExists) {
            Import-Module "$env:ChocolateyInstall\helpers\chocolateyInstaller.psm1" -ErrorAction SilentlyContinue -Force -WarningAction SilentlyContinue
        }
        $aliases = Get-Alias | Group-Object -AsHashTable -Property Name
        $ParserErrors = $null
    }

    PROCESS {
        if ($directory -or $files) {
            $allFiles = if (!$files) {
                Get-ChildItem -LiteralPath $directory -Filter $filter -Recurse
            }
            else {
                $files | ForEach-Object { Get-Item $_ }
            }

            foreach ($file in $allFiles) {
                $oldText = Get-Content -Path $file.FullName -Raw
                $text = Expand-AliasesInText -text $oldText -aliases $aliases -ParserErrors $ParserErrors
                if ($oldText -cne $text) {
                    [System.IO.File]::WriteAllText($file.FullName, $text, [System.Text.Encoding]::UTF8)
                }
            }
        }
        else {
            $text = Expand-AliasesInText -text $text -aliases $aliases -ParserErrors $ParserErrors
        }
    }

    END {
        if (!$moduleExists) {
            Remove-Module chocolateyInstaller -ErrorAction SilentlyContinue -Force
        }
        if (!$directory -and !$Files) {
            $Text
        }
    }
}
