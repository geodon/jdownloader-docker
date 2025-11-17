#!/bin/sh

# Ensure cfg directory exists
mkdir -p cfg

# Helper function to set a JSON property in a config file
# Usage: json_set_property 'filename.json' 'propertyName' 'value' ['display_value']
# Works in cfg/ directory
# Values 'true' and 'false' are treated as booleans, numbers as numbers, everything else as strings
# Optional 4th parameter: display value for logs (use to hide sensitive data)
json_set_property() {
    filename="$1"
    property="$2"
    value="$3"
    display_value="${4:-$value}"
    
    file="cfg/$filename"
    
    # Determine the jq argument based on value type
    case "$value" in
        true|false)
            # Boolean value
            jq_args="--argjson val $value"
            ;;
        ''|*[!0-9]*)
            # String value (contains non-digits or is empty)
            jq_args="--arg val $value"
            ;;
        *)
            # Numeric value
            jq_args="--argjson val $value"
            ;;
    esac
    
    # Create file with single property if it doesn't exist or is empty
    if [ ! -f "$file" ] || [ ! -s "$file" ]; then
        jq -nc --arg prop "$property" $jq_args '{($prop): $val}' > "$file"
        printf "[DOCKER-INIT] CREATE\t%s\t%s\t%s\n" "$file" "$property" "$display_value"
        return
    fi
    
    # Get current value
    current_value=$(jq -r --arg prop "$property" '.[$prop] // empty' "$file")
    
    # Update only if value changed or property doesn't exist
    if [ "$current_value" != "$value" ]; then
        jq -c --arg prop "$property" $jq_args '.[$prop] = $val' "$file" > "$file.tmp" && mv "$file.tmp" "$file"
        
        if [ -z "$current_value" ]; then
            printf "[DOCKER-INIT] ADD\t%s\t%s\t%s\n" "$file" "$property" "$display_value"
        else
            printf "[DOCKER-INIT] UPDATE\t%s\t%s\t%s\n" "$file" "$property" "$display_value"
        fi
    fi
}
