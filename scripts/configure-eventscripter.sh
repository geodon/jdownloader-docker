#!/bin/sh
set -e

# Source helper functions
. /scripts/_json-config.sh

CONFIG_FILE="org.jdownloader.extensions.eventscripter.EventScripterExtension.json"
SCRIPTS_FILE="/JDownloader/cfg/org.jdownloader.extensions.eventscripter.EventScripterExtension.scripts.json"
AUTOUPDATE_SCRIPT="/scripts/eventscripter-autoupdate.js"

# Configure EventScripter extension settings
json_set_property "${CONFIG_FILE}" "enabled" "true"

# Create scripts array with auto-update script
# Read the script content and encode it as JSON string
SCRIPT_CONTENT=$(cat "${AUTOUPDATE_SCRIPT}" | jq -Rs .)

cat > "${SCRIPTS_FILE}" <<EOF
[
  {
    "id": 1594796988140,
    "name": "Auto-update JD",
    "eventTrigger": "INTERVAL",
    "eventTriggerSettings": {
      "interval": 600000,
      "isSynchronous": false
    },
    "script": ${SCRIPT_CONTENT},
    "enabled": true
  }
]
EOF

printf "[DOCKER-INIT] CONFIGURE\t%s\tSCRIPTS\tAuto-update JD\n" "${SCRIPTS_FILE}"
