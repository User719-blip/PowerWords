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
