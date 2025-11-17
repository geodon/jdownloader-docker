#!/bin/sh

# Script to configure JDownloader general settings

# Import helper functions
. /scripts/_json-config.sh

# Configure general settings
GENERAL_CONFIG="org.jdownloader.settings.GeneralSettings.json"
RECONNECT_CONFIG="jd.controlling.reconnect.ReconnectConfig.json"

# Set download folder to the Downloads volume with package name subfolder
json_set_property "$GENERAL_CONFIG" "defaultdownloadfolder" "/Downloads/<jd:packagename>"

# Disable auto-reconnect (not useful in Docker environment)
json_set_property "$RECONNECT_CONFIG" "autoreconnectenabled" "false"
