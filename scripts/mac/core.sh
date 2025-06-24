#!/bin/bash

# Load configurations
CONFIG_DIR="$(dirname "$0")/../../config"
APPS_CONFIG="$CONFIG_DIR/apps.json"
SEARCH_CONFIG="$CONFIG_DIR/search_engines.json"

open_app() {
    local target=$1
    local app_path=$(jq -r ".$target" "$APPS_CONFIG")
    
    if [ "$app_path" != "null" ]; then
        open "$app_path"
    elif [[ $target == http* ]]; then
        open "$target"
    elif [ -e "$target" ]; then
        open "$target"
    else
        echo "Application or target not found: $target"
    fi
}

# Add these functions somewhere before the command dispatcher
sys_status() {
    echo "--- System Status ---"

    # CPU Usage (using top for a quick snapshot)
    echo "CPU Usage:"
    top -l 1 | grep "CPU usage" | awk '{print "  "$3" user, "$5" sys, "$7" idle"}'

    # Memory Stats (using top for a quick snapshot)
    echo "Memory Stats:"
    top -l 1 | grep "PhysMem" | awk '{print "  "$2" used, "$6" free"}'

    # Disk Space (using df -h)
    echo "Disk Space:"
    df -h | grep -E '^/dev/' | awk '{print "  "$1": "$5" used of "$2" ("$4" free)"}'
    echo "---------------------"
}

git_sync() {
    local message=$1

    if [ -z "$message" ]; then
        echo "Usage: git-sync <commit_message>"
        return 1
    fi

    echo "--- Git Sync ---"
    echo "Adding all changes..."
    git add . || { echo "Error during git add." ; return 1; }

    echo "Committing with message: '$message'..."
    git commit -m "$message" || { echo "Error during git commit." ; return 1; }

    echo "Pushing to origin main..."
    git push -u origin main || { echo "Error during git push." ; return 1; }

    echo "Git sync complete."
    echo "----------------"
}

# Modify the existing command dispatcher 'case' statement:
# ... (existing code) ...

# Dispatcher for command-line arguments
if [ "$#" -gt 0 ]; then
    command=$1
    shift # Remove the command from the arguments list

    case "$command" in
        "open")
            open_app "$@"
            ;;
        "search")
            search_web "$@"
            ;;
        "find")
            find_file "$@"
            ;;
        "sys-status") # Add this case
            sys_status
            ;;
        "git-sync") # Add this case
            git_sync "$@"
            ;;
        *)
            echo "Unknown command: $command"
            ;;
    esac
else
    echo "No command provided."
fi


search_web() {
    local query=$1
    local engine=${2:-default}
    local url_template=$(jq -r ".$engine" "$SEARCH_CONFIG")
    
    if [ "$url_template" != "null" ]; then
        local encoded_query=$(python -c "import urllib.parse; print(urllib.parse.quote('$query'))")
        local url=${url_template//\{query\}/$encoded_query}
        open "$url"
    else
        echo "Search engine not found: $engine"
    fi
}

find_file() {
    local pattern=$1
    local open_file=$2
    local results=($(find ~ -name "*$pattern*" 2>/dev/null))
    
    if [ "$open_file" = true ]; then
        if [ ${#results[@]} -gt 0 ]; then
            open "${results[0]}"
        else
            echo "File not found: $pattern"
        fi
    else
        for result in "${results[@]}"; do
            echo "$result"
        done
    fi
}
