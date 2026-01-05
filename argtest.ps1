function T {
    [CmdletBinding()]
    param(
        [Parameter(ValueFromRemainingArguments=$true)]
        [string[]]$arguments
    )
    Write-Host "Count=$($arguments.Count)"
    foreach ($arg in $arguments) { Write-Host "[$arg]" }
}
T --here 'what is dog'
