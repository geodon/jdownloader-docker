#!/bin/sh

# Script to configure JDownloader Archive Extractor settings

# Import helper functions
. /scripts/_json-config.sh

# Configure extraction settings
EXTRACTION_CONFIG="org.jdownloader.extensions.extraction.ExtractionExtension.json"

# Optional behavior:
# - false (default): delete archive files after successful extraction
# - true: keep archive files
: "${DISABLE_ARCHIVE_DELETE:=false}"

case "$DISABLE_ARCHIVE_DELETE" in
    true|TRUE|1|yes|YES)
        DELETE_ARCHIVE_ACTION="NO_DELETE"
        ;;
    false|FALSE|0|no|NO)
        DELETE_ARCHIVE_ACTION="NULL"
        ;;
    *)
        printf "[DOCKER-INIT] WARN\tInvalid DISABLE_ARCHIVE_DELETE='%s', using default false\n" "$DISABLE_ARCHIVE_DELETE"
        DELETE_ARCHIVE_ACTION="NULL"
        ;;
esac

# Ensure extension is enabled
json_set_property "$EXTRACTION_CONFIG" "enabled" "true"

# Delete archive files after successful extraction.
# JDownloader stores this as an enum value. "NULL" means permanent delete.
json_set_property "$EXTRACTION_CONFIG" "deletearchivefilesafterextractionaction" "$DELETE_ARCHIVE_ACTION"
