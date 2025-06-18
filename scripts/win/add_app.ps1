param(
    [Parameter(Mandatory=$true)]
    [string]$name,
    [Parameter(Mandatory=$true)]
    [string]$path
)

$configPath = Join-Path $PSScriptRoot "../../config/app.json"
$config = Get-Content $configPath | ConvertFrom-Json

if ([string]::IsNullOrWhiteSpace($name)) {
    Write-Error "The 'name' parameter cannot be null or empty."
    exit 1
}

$config | Add-Member -NotePropertyName $name -NotePropertyValue $path -Force

$config | ConvertTo-Json | Set-Content $configPath

Write-Host "Added $name pointing to $path"