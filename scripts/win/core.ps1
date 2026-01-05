# Load configurations
$configPath = Join-Path $PSScriptRoot "../../config/app.json"
$appsConfig = Get-Content $configPath | ConvertFrom-Json

$searchConfigPath = Join-Path $PSScriptRoot "../../config/search_engines.json"
$searchConfig = Get-Content $searchConfigPath | ConvertFrom-Json
function Invoke-gui{
    
}
function Invoke-help{
    Write-Host "Available commands:"
    Write-Host "  open <app_name|path|url>     - Open an application, file, or URL."
    Write-Host "  search <query> [engine]      - Search the web using the specified engine."
    Write-Host "  find <pattern> [-open]       - Find files matching the pattern. Use -open to open the first match."
    Write-Host "  sys-status                   - Display system status information."
    Write-Host "  git-sync <commit_message>    - Sync local changes to the Git repository with the provided commit message."
    Write-Host "  help                         - Show this help message."
}

function Test-ForUpdates {
    [CmdletBinding()]
    param()
    $currentVersion = "1.0.0"
    $repo = "User719-blip/PowerWords"

    try {
        # Get latest release info from GitHub API
        $latestRelease = Invoke-RestMethod -Uri "https://api.github.com/repos/$repo/releases/latest" -UseBasicParsing -Headers @{ 'User-Agent' = 'PowerWords-Updater' }
        $rawTag = $latestRelease.tag_name

        if ([string]::IsNullOrWhiteSpace($rawTag)) {
            Write-Verbose "Update check skipped: latest release has no tag."
            return
        }

        $normalizedTag = $rawTag -replace "^v", ""
        $parsedLatest = $null
        if (-not [System.Version]::TryParse($normalizedTag, [ref]$parsedLatest)) {
            Write-Verbose "Update check skipped: invalid version tag '$rawTag'."
            return
        }

        $parsedCurrent = $null
        if (-not [System.Version]::TryParse($currentVersion, [ref]$parsedCurrent)) {
            Write-Verbose "Update check skipped: invalid current version '$currentVersion'."
            return
        }

        if ($parsedLatest -gt $parsedCurrent) {
            Write-Host "Update available: $normalizedTag (Current: $parsedCurrent)"

            # Ask user if they want to update
            $choice = Read-Host "Do you want to update now? (Y/N)"
            if ($choice -eq 'Y') {
                # Find the installer download URL
                $asset = $latestRelease.assets | Where-Object { $_.name -like "*Setup*.exe" }
                $downloadUrl = $asset.browser_download_url

                if (-not [string]::IsNullOrWhiteSpace($downloadUrl)) {
                    # Download and run the installer silently
                    $tempInstaller = "$env:TEMP\MyLauncherUpdate.exe"
                    Invoke-WebRequest -Uri $downloadUrl -OutFile $tempInstaller -UseBasicParsing
                    Start-Process -FilePath $tempInstaller -ArgumentList "/VERYSILENT" -Wait

                    Write-Host "Update installed! Restart the launcher."
                    exit
                }
                else {
                    Write-Verbose "Update asset not found; please check the release manually."
                }
            }
        }
    }
    catch {
        Write-Host "Could not check for updates: $($_.Exception.Message)" -ForegroundColor Yellow
    }
}

# Call this at startup
Test-ForUpdates


function Invoke-Open {
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


# Dispatcher for command-line arguments


function Invoke-Search {
    [CmdletBinding()]
    param(
        [Parameter(ValueFromRemainingArguments = $true)]
        [string[]]$arguments
    )

    $here = $false
    $engine = "default"
    $queryParts = New-Object System.Collections.Generic.List[string]

    foreach ($arg in $arguments) {
        if ($arg -eq "--here") {
            $here = $true
            continue
        }

        if ($arg -like "--engine=*") {
            $engine = $arg.Substring(9)
            continue
        }

        $queryParts.Add($arg)
    }

    if ($queryParts.Count -eq 0) {
        Write-Host "Usage: search [--here] <query> [engine]"
        return
    }

    if (-not $here -and $queryParts.Count -gt 1) {
        $candidateEngine = $queryParts[-1]
        if ($searchConfig.PSObject.Properties.Name -contains $candidateEngine) {
            $engine = $candidateEngine
            [void]$queryParts.RemoveAt($queryParts.Count - 1)
        }
    }

    $query = [string]::Join(" ", $queryParts)

    if ($here) {
        
        try {
            $encodedQuery = [Uri]::EscapeDataString($query)
            $apiUrl = "https://api.duckduckgo.com/?q=$encodedQuery&format=json&no_redirect=1&no_html=1"
            $response = Invoke-RestMethod -Uri $apiUrl -UseBasicParsing

            $summary = $null
            if (-not [string]::IsNullOrWhiteSpace($response.AbstractText)) {
                $summary = $response.AbstractText
            }
            elseif ($response.RelatedTopics -and $response.RelatedTopics[0].Text) {
                $summary = $response.RelatedTopics[0].Text
            }

            if ([string]::IsNullOrWhiteSpace($summary)) {
                Write-Host "No inline summary found for '$query'. Opening browser instead."
                $template = if ($searchConfig.PSObject.Properties.Name -contains $engine) {
                    $searchConfig.$engine
                } else {
                    $searchConfig.default
                }
                Start-Process ($template -replace "{query}", $encodedQuery)
                return
            }

            $words = $summary -split '\s+'
            if ($words.Count -gt 60) {
                $summary = ($words[0..59] -join ' ') + '...'
            } else {
                $summary = $words -join ' '
            }

            Write-Host "Query: $query"
            foreach ($line in ($summary -split '(.{1,90})(?:\s+|$)' | Where-Object { $_ })) {
                Write-Host $line.Trim()
            }
        }
        catch {
            Write-Host "Inline lookup failed: $($_.Exception.Message)."
        }
        return
    }

    if ($searchConfig.PSObject.Properties.Name -contains $engine) {
        $template = $searchConfig.$engine
    } else {
        Write-Host "Search engine not found: $engine"
        return
    }

    Start-Process ($template -replace "{query}", [Uri]::EscapeDataString($query))
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

function Invoke-Path {
    param(
        [string]$targetPath = (Get-Location).Path
    )

    if (-not (Test-Path $targetPath)) {
        Write-Host "Path not found: $targetPath"
        return
    }

    $scriptsDir = Split-Path $PSScriptRoot -Parent
    $projectRoot = Split-Path $scriptsDir -Parent
    $launcherCandidates = @(
        Join-Path $projectRoot "launcher.exe",
        Join-Path $projectRoot "bin\launcher.exe"
    )

    $launcherExe = $launcherCandidates | Where-Object { Test-Path $_ } | Select-Object -First 1

    if ($launcherExe) {
        & $launcherExe "list" $targetPath
    }
    else {
        Get-ChildItem -Path $targetPath -Directory | ForEach-Object { $_.FullName }
    }
}



# Dispatcher for command-line arguments

if ($args.Count -gt 0) {
    $command = $args[0]
    $commandArgs = if ($args.Count -gt 1) { $args[1..($args.Count - 1)] } else { @() }

    switch ($command.ToLower()) {
        
        "help"      { Invoke-help }
        "open"      { Invoke-Open @commandArgs }
        "search"    { Invoke-Search @commandArgs }
        "find"      { Invoke-Find @commandArgs }
        "sys-status" { Invoke-SysStatus }
        "git-sync"  { Invoke-GitSync @commandArgs }
        "path"      { Invoke-Path @commandArgs }
        default     { Write-Host "Unknown command: $command" }
    }
} else {
    Write-Host "No command provided."
}
# When you run a .ps1 script with -File, PowerShell does not automatically call any functions defined in the script. It just loads and runs the top-level code.
# Your functions are defined, but never invoked unless you explicitly call them in the script body
