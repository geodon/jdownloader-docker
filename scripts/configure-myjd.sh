#!/bin/sh

# Script to configure MyJDownloader settings

# Import helper functions
. /scripts/_file-env.sh
. /scripts/_json-config.sh

# Read required variables
file_env 'MYJD_EMAIL'
file_env 'MYJD_PASSWORD'

# Set default for devicename if not provided
: ${MYJD_DEVICENAME:=JDownloader}

# Configure MyJDownloader properties
MYJD_CONFIG="org.jdownloader.api.myjdownloader.MyJDownloaderSettings.json"
json_set_property "$MYJD_CONFIG" "email" "$MYJD_EMAIL"
json_set_property "$MYJD_CONFIG" "password" "$MYJD_PASSWORD" "<hidden>"
json_set_property "$MYJD_CONFIG" "devicename" "$MYJD_DEVICENAME"

printf "[DOCKER-INIT] MyJDownloader configuration complete\n"
