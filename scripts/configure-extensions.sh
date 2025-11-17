#!/bin/sh
set -e

# Extensions directory
EXTENSIONS_DIR="/JDownloader/update/versioninfo/JD"
REQUESTED_FILE="${EXTENSIONS_DIR}/extensions.requestedinstalls.json"

# Create extensions directory if it doesn't exist
mkdir -p "${EXTENSIONS_DIR}"

# Extensions to install (always EventScripter)
EXTENSIONS_JSON='["eventscripter"]'

# Write requested installs - JDownloader will manage the installed state
printf '%s\n' "${EXTENSIONS_JSON}" > "${REQUESTED_FILE}"
printf "[DOCKER-INIT] CONFIGURE\t%s\tEXTENSIONS\teventscripter\n" "${REQUESTED_FILE}"
