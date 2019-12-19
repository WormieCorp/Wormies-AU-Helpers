function Expand-AliasesInText {
    [cmdletbinding(SupportsShouldProcess = $True)]
    param(
        [Parameter(Mandatory = $true)]
        [string]$text,
        [Parameter(Mandatory = $true)]
        [hashtable]$aliases,
        $ParserErrors = $null,
        [string[]]$whitelist = @())

    $additionalReplaces = @{
        "touch" = "New-Item -ItemType File -Path"
    }

    $tokens = [System.Management.Automation.PSParser]::Tokenize($text, [ref]$ParserErrors)
    $commands = $tokens | Where-Object Type -eq "Command" | Sort-Object Start -Descending

    foreach ($cmd in $commands) {
        $key = $cmd.Content
        if ($whitelist.Contains($key)) { continue; }
        if ($aliases.Contains($key)) {
            $alias = $aliases.$key
            $old = $key
            $new = $alias.ResolvedCommandName
            if ($PSCmdlet.ShouldProcess($old, "Expand alias to $new")) {
                $text = $text.Remove($cmd.Start, $old.Length).Insert($cmd.Start, $new)
            }
        } elseif ($additionalReplaces.ContainsKey($key)) {
            $old = $key
            $new = $additionalReplaces[$key]
            if ($PSCmdlet.ShouldProcess($old, "Expand command to $new")) {
                $text = $text.Remove($cmd.Start, $old.Length).Insert($cmd.Start, $new)
            }
        }
    }

    return $text
}
