name="$1"
path="$2"
config_file="$(dirname "$0")/../../config/apps.json"

jq --arg name "$name" --arg path "$path" '.apps += [{"name": $name, "path": $path}]' "$config_file" > "$config_file.tmp" && mv "$config_file.tmp" "$config_file"

echo "Added $name pointing to $path"