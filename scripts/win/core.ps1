# Load configurations
$configPath = Join-Path $PSScriptRoot "../../config/apps.json"
$appsConfig = Get-Content $configPath | ConvertFrom-Json

$searchConfigPath = Join-Path $PSScriptRoot "../../config/search_engines.json"
$searchConfig = Get-Content $searchConfigPath | ConvertFrom-Json

function Invoke-Open {
    param(
        [string]$target
    )
    
    if ($appsConfig.PSObject.Properties.Name -contains $target) {
        Start-Process $appsConfig.$target
    }
    elseif (Test-Path $target) {
        Start-Process $target
    }
    elseif ($target -match "^https?://") {
        Start-Process $target
    }
    else {
        Write-Host "Application or target not found: $target"
    }
}

function Invoke-Search {
    param(
        [string]$query,
        [string]$engine = "default"
    )
    
    if ($searchConfig.PSObject.Properties.Name -contains $engine) {
        $url = $searchConfig.$engine -replace "{query}", [Uri]::EscapeDataString($query)
        Start-Process $url
    }
    else {
        Write-Host "Search engine not found: $engine"
    }
}

function Invoke-Find {
    param(
        [string]$pattern,
        [switch]$open = $false
    )
    
    $results = Get-ChildItem -Path $HOME -Recurse -Filter "*$pattern*" -ErrorAction SilentlyContinue
    
    if ($open) {
        if ($results.Count -gt 0) {
            Start-Process $results[0].FullName
        }
        else {
            Write-Host "File not found: $pattern"
        }
    }
    else {
        $results | ForEach-Object { $_.FullName }
    }
}

# Export functions for the main launcher
Export-ModuleMember -Function Invoke-Open, Invoke-Search, Invoke-Find
