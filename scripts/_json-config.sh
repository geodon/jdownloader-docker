#!/bin/sh

# Ensure cfg directory exists
mkdir -p cfg

# Helper function to set a JSON property in a config file
# Usage: json_set_property 'filename.json' 'propertyName' 'value'
# Works in cfg/ directory
json_set_property() {
    filename="$1"
    property="$2"
    value="$3"
    
    file="cfg/$filename"
    
    # Create file with single property if it doesn't exist or is empty
    if [ ! -f "$file" ] || [ ! -s "$file" ]; then
        jq -nc --arg prop "$property" --arg val "$value" '{($prop): $val}' > "$file"
        echo "Created $file with $property=\"$value\""
        return
    fi
    
    # Get current value
    current_value=$(jq -r --arg prop "$property" '.[$prop] // empty' "$file")
    
    # Update only if value changed or property doesn't exist
    if [ "$current_value" != "$value" ]; then
        jq -c --arg prop "$property" --arg val "$value" '.[$prop] = $val' "$file" > "$file.tmp" && mv "$file.tmp" "$file"
        
        if [ -z "$current_value" ]; then
            echo "Added $property=\"$value\" to $file"
        else
            echo "Updated $property=\"$value\" in $file"
        fi
    fi
}
