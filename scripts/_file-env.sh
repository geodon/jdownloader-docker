#!/bin/sh

# Helper function to read required variable from file or directly
# Usage: file_env 'VAR_NAME'
# Checks for VAR_NAME or VAR_NAME_FILE environment variables
# Exits with error if neither is set
file_env() {
    var="$1"
    fileVar="${var}_FILE"
    
    eval fileVarValue="\$$fileVar"
    eval varValue="\$$var"
    
    if [ -n "$fileVarValue" ] && [ -f "$fileVarValue" ]; then
        val="$(cat "$fileVarValue")"
        eval export "$var=\"$val\""
    elif [ -z "$varValue" ]; then
        echo "Error: $var or $fileVar must be set" >&2
        exit 1
    fi
}
