#!/bin/sh

# Script to configure JDownloader general settings

# Import helper functions
. /scripts/_json-config.sh

# Configure general settings
GENERAL_CONFIG="org.jdownloader.settings.GeneralSettings.json"
RECONNECT_CONFIG="jd.controlling.reconnect.ReconnectConfig.json"

# Set download folder to the Downloads volume with package name subfolder
json_set_property "$GENERAL_CONFIG" "defaultdownloadfolder" "/Downloads/<jd:packagename>"
json_set_property "$GENERAL_CONFIG" "cleanupafterdownloadaction" "CLEANUP_AFTER_PACKAGE_HAS_FINISHED"
json_set_property "$GENERAL_CONFIG" "autostartdownloadoption" "ALWAYS"
json_set_property "$GENERAL_CONFIG" "hashcheckenabled" "true"
json_set_property "$GENERAL_CONFIG" "iffileexistsaction" "SKIP_FILE"
json_set_property "$GENERAL_CONFIG" "createfoldertrigger" "ON_DOWNLOAD_START"
json_set_property "$GENERAL_CONFIG" "onskipduetoalreadyexistsaction" "SET_FILE_TO_SUCCESSFUL"

# Disable auto-reconnect (not useful in Docker environment)
json_set_property "$RECONNECT_CONFIG" "autoreconnectenabled" "false"
