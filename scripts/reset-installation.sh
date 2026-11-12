#!/bin/sh
set -e

# Remove the JDownloader binaries and update state while preserving the user's
# configuration, download lists and logs.
#
# This follows the official repair procedure:
# https://support.jdownloader.org/en/knowledgebase/article/fix-jdownloader-installation
#
# After this script, JDownloader.jar is missing and download-jar.sh will obtain
# a fresh copy from installer.jdownloader.org.

BASE_DIR="${1:-/JDownloader}"

if [ "${BASE_DIR}" = "/" ]; then
    printf "[DOCKER-RECOVERY] Refusing to operate on root directory\n" >&2
    exit 1
fi

if [ ! -d "${BASE_DIR}" ]; then
    printf "[DOCKER-RECOVERY] Base directory not found: %s\n" "${BASE_DIR}" >&2
    exit 1
fi

rm -f "${BASE_DIR}/JDownloader.jar" "${BASE_DIR}/Core.jar"
rm -rf "${BASE_DIR}/tmp" "${BASE_DIR}/update"

printf "[DOCKER-RECOVERY] Removed JDownloader.jar, Core.jar, tmp and update\n"
