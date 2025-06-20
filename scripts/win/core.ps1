# Load configurations
$configPath = Join-Path $PSScriptRoot "../../config/apps.json"
$appsConfig = Get-Content $configPath | ConvertFrom-Json

$searchConfigPath = Join-Path $PSScriptRoot "../../config/search_engines.json"
$searchConfig = Get-Content $searchConfigPath | ConvertFrom-Json

function Check-ForUpdates {
    $currentVersion = "1.0.0"  # Update this with each release
    $repo = "User719-blip/PowerWords"  # e.g., "JohnDoe/MyLauncher"

    try {
        # Get latest release info from GitHub API
        $latestRelease = (Invoke-RestMethod -Uri "https://api.github.com/repos/$repo/releases/latest" -UseBasicParsing)
        $latestVersion = $latestRelease.tag_name -replace "v", ""  # Remove 'v' from v1.0.0

        if ([version]$latestVersion -gt [version]$currentVersion) {
            Write-Host "🚀 Update available: $latestVersion (Current: $currentVersion)"
            
            # Ask user if they want to update
            $choice = Read-Host "Do you want to update now? (Y/N)"
            if ($choice -eq 'Y') {
                # Find the installer download URL
                $asset = $latestRelease.assets | Where-Object { $_.name -like "*Setup*.exe" }
                $downloadUrl = $asset.browser_download_url

                # Download and run the installer silently
                $tempInstaller = "$env:TEMP\MyLauncherUpdate.exe"
                Invoke-WebRequest -Uri $downloadUrl -OutFile $tempInstaller -UseBasicParsing
                Start-Process -FilePath $tempInstaller -ArgumentList "/VERYSILENT" -Wait

                Write-Host "✅ Update installed! Restart the launcher."
                exit
            }
        }
    }
    catch {
        Write-Host "⚠️ Could not check for updates: $_" -ForegroundColor Yellow
    }
}

# Call this at startup
Check-ForUpdates



function Invoke-Open {
    Write-Host "starting"
    param(
        [string]$target)
    
    if ($appsConfig.PSObject.Properties.Name -contains $target) {
        Start-Process $appsConfig.$target
        Write-Host "Opening $target"

    }
    elseif (Test-Path $target) {
        Start-Process $target
        Write-Host "Opening $target"
    }
    elseif ($target -match "^https?://") {
        Start-Process $target
        Write-Host "Opening $target"

    }
    else {
        Write-Host "Application or target not found: $target"
    }
    Write-Host "ended process"
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


# ...existing code...

# Dispatcher for command-line arguments
if ($args.Count -gt 0) {
    $command = $args[0]
    $commandArgs = $args[1..($args.Count - 1)]

    switch ($command.ToLower()) {
        "open"   { Invoke-Open @commandArgs }
        "search" { Invoke-Search @commandArgs }
        "find"   { Invoke-Find @commandArgs }
        default  { Write-Host "Unknown command: $command" }
    }
} else {
    Write-Host "No command provided."
}

# When you run a .ps1 script with -File, PowerShell does not automatically call any functions defined in the script. It just loads and runs the top-level code.
# Your functions are defined, but never invoked unless you explicitly call them in the script body.



