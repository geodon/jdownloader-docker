#!/bin/sh
set -e

# Make sure a usable JDownloader.jar exists and repair obviously broken
# installations.  JDownloader.jar and Core.jar must always come from the same
# installation generation, so whenever the launcher is replaced we also remove
# Core.jar and the update state.

BASE_DIR="${BASE_DIR:-/JDownloader}"
JAR="${BASE_DIR}/JDownloader.jar"
INSTALLER_URL="${JD_INSTALLER_URL:-https://installer.jdownloader.org/JDownloader.jar}"
REPAIR_MARKER="${BASE_DIR}/.fix_jd_install"

cd "${BASE_DIR}"

if [ -f "${REPAIR_MARKER}" ]; then
    printf "[DOCKER-INIT] Repair marker found; resetting installation\n"
    /scripts/reset-installation.sh "${BASE_DIR}"
    rm -f "${REPAIR_MARKER}"
fi

if [ -f "${JAR}" ] && ! unzip -t "${JAR}" >/dev/null 2>&1; then
    printf "[DOCKER-INIT] JDownloader.jar is corrupt; resetting installation\n"
    /scripts/reset-installation.sh "${BASE_DIR}"
fi

if [ ! -f "${JAR}" ]; then
    printf "[DOCKER-INIT] Downloading JDownloader.jar\n"
    rm -f "${BASE_DIR}/Core.jar"
    rm -rf "${BASE_DIR}/tmp" "${BASE_DIR}/update"
    if ! wget -nv --timeout=30 -O "${JAR}" "${INSTALLER_URL}"; then
        rm -f "${JAR}"
        printf "[DOCKER-INIT] ERROR: could not download JDownloader.jar\n" >&2
        exit 1
    fi
    if ! unzip -t "${JAR}" >/dev/null 2>&1; then
        rm -f "${JAR}"
        printf "[DOCKER-INIT] ERROR: downloaded JDownloader.jar is not a valid jar\n" >&2
        exit 1
    fi
fi
