# Load configurations
$configPath = Join-Path $PSScriptRoot "../../config/app.json"
$appsConfig = Get-Content $configPath | ConvertFrom-Json

$searchConfigPath = Join-Path $PSScriptRoot "../../config/search_engines.json"
$searchConfig = Get-Content $searchConfigPath | ConvertFrom-Json
Start-Process powershell.exe -NoNewWindow -Wait{
    (Get-Host).UI.RawUI.BackgroundColor = 'Black'
    (Get-Host).UI.RawUI.ForegroundColor = 'White'

}

function Test-ForUpdates {
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
Test-ForUpdates


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

# Add these functions somewhere before the command dispatcher
function Invoke-SysStatus {
    Write-Host "--- System Status ---"

    # CPU Usage (Note: Get-Counter for CPU can be slow or require admin privileges in some environments)
    try {
        $cpu = Get-Counter '\Processor(_Total)\% Processor Time' | Select-Object -ExpandProperty CounterSamples
        Write-Host "CPU Usage: $($cpu.CookedValue.ToString("N2"))%"
    } catch {
        Write-Host "Could not retrieve CPU usage."
    }

    # Memory Stats
    try {
        $memory = Get-Counter '\Memory\Available MBytes' | Select-Object -ExpandProperty CounterSamples
        $totalMemory = (Get-WmiObject Win32_ComputerSystem).TotalPhysicalMemory / 1MB
        $usedMemory = $totalMemory - $memory.CookedValue
        Write-Host "Memory Used: $($usedMemory.ToString("N2")) MB / $($totalMemory.ToString("N2")) MB"
    } catch {
        Write-Host "Could not retrieve memory stats."
    }

    # Disk Space
    Write-Host "Disk Space:"
    try {
        Get-PSDrive -PSProvider FileSystem | ForEach-Object {
            $freeGB = ($_.Free / 1GB).ToString("N2")
            $usedGB = (($_.Used / 1GB)).ToString("N2")
            $sizeGB = (($_.Size / 1GB)).ToString("N2")
            Write-Host "  $($_.Name): $($usedGB) GB used of $($sizeGB) GB ($($freeGB) GB free)"
        }
    } catch {
        Write-Host "Could not retrieve disk space information."
    }
    Write-Host "---------------------"
}

function Invoke-GitSync {
    param(
        [string]$message
    )

    if ([string]::IsNullOrEmpty($message)) {
        Write-Host "Usage: git-sync <commit_message>"
        return
    }

    Write-Host "--- Git Sync ---"
    Write-Host "Adding all changes..."
    git add .
    if ($LASTEXITCODE -ne 0) { Write-Host "Error during git add." ; return }

    Write-Host "Committing with message: '$message'..."
    git commit -m "$message"
    if ($LASTEXITCODE -ne 0) { Write-Host "Error during git commit." ; return }

    Write-Host "Pushing to origin main..."
    git push -u origin main
    if ($LASTEXITCODE -ne 0) { Write-Host "Error during git push." ; return }

    Write-Host "Git sync complete."
    Write-Host "----------------"
}

# Modify the existing command dispatcher 'switch' statement:
# ... (existing code) ...

# Dispatcher for command-line arguments


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

     Write-Host "Hello, world!" # This
    switch ($command.ToLower()) {
        
        "open"      { Invoke-Open @commandArgs }
        "search"    { Invoke-Search @commandArgs }
        "find"      { Invoke-Find @commandArgs }
        "sys-status" { Invoke-SysStatus } # Add this line
        "git-sync"  { Invoke-GitSync @commandArgs } # Add this line
        default     { Write-Host "Unknown command: $command" }
    }
} else {
    Write-Host "No command provided."
}
# When you run a .ps1 script with -File, PowerShell does not automatically call any functions defined in the script. It just loads and runs the top-level code.
# Your functions are defined, but never invoked unless you explicitly call them in the script body.
