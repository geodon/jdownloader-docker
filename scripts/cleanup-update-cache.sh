#!/bin/sh
set -e

# Script to clear JDownloader update cache/state directories.
# Intended for manual execution via docker exec.

BASE_DIR="${1:-/JDownloader}"

if [ "${BASE_DIR}" = "/" ]; then
    printf "[MAINTENANCE] Refusing to operate on root directory\n" >&2
    exit 1
fi

if [ ! -d "${BASE_DIR}" ]; then
    printf "[MAINTENANCE] Base directory not found: %s\n" "${BASE_DIR}" >&2
    exit 1
fi

for dir in "${BASE_DIR}/tmp/update" "${BASE_DIR}/update"; do
    if [ -e "${dir}" ]; then
        rm -rf "${dir}"
        printf "[MAINTENANCE] Removed: %s\n" "${dir}"
    else
        printf "[MAINTENANCE] Already absent: %s\n" "${dir}"
    fi
done

printf "[MAINTENANCE] Update cache cleanup complete. Restart the container.\n"
