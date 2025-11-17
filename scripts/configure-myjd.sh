#!/bin/sh

# Script to configure MyJDownloader settings

# Import helper functions
. /scripts/_file-env.sh

# Read required variables
file_env 'MYJD_EMAIL'
file_env 'MYJD_PASSWORD'

# Set default for devicename if not provided
: ${MYJD_DEVICENAME:=JDownloader}

CONFIG_FILE="cfg/org.jdownloader.api.myjdownloader.MyJDownloaderSettings.json"

# Create config if it doesn't exist
if [ ! -f "$CONFIG_FILE" ]; then
    echo '{
        "email":"'${MYJD_EMAIL}'",
        "password":"'${MYJD_PASSWORD}'",
        "devicename":"'${MYJD_DEVICENAME}'"
    }' > "$CONFIG_FILE"
else
    # Update or add properties to existing config
    # Check if email exists, update or add it
    if grep -q '"email"' "$CONFIG_FILE"; then
        sed -i 's/"email"[[:space:]]*:[[:space:]]*"[^"]*"/"email":"'"${MYJD_EMAIL}"'"/' "$CONFIG_FILE"
    else
        sed -i 's/}/,\n  "email":"'"${MYJD_EMAIL}"'"\n}/' "$CONFIG_FILE"
    fi
    
    # Check if password exists, update or add it
    if grep -q '"password"' "$CONFIG_FILE"; then
        sed -i 's/"password"[[:space:]]*:[[:space:]]*"[^"]*"/"password":"'"${MYJD_PASSWORD}"'"/' "$CONFIG_FILE"
    else
        sed -i 's/}/,\n  "password":"'"${MYJD_PASSWORD}"'"\n}/' "$CONFIG_FILE"
    fi
    
    # Check if devicename exists, update or add it
    if grep -q '"devicename"' "$CONFIG_FILE"; then
        sed -i 's/"devicename"[[:space:]]*:[[:space:]]*"[^"]*"/"devicename":"'"${MYJD_DEVICENAME}"'"/' "$CONFIG_FILE"
    else
        sed -i 's/}/,\n  "devicename":"'"${MYJD_DEVICENAME}"'"\n}/' "$CONFIG_FILE"
    fi
fi
