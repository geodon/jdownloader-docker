#!/bin/sh

# Script to clean MyJDownloader session files
# This forces a fresh authentication and prevents issues caused by corrupted or expired session tokens
# while preserving all other JDownloader configuration (accounts, settings, history, etc.)

printf "[DOCKER-INIT] Cleaning MyJDownloader session files...\n"

# Remove MyJDownloader configuration backup if it exists
if [ -f "cfg/org.jdownloader.api.myjdownloader.MyJDownloaderSettings.json.backup" ]; then
    rm -f "cfg/org.jdownloader.api.myjdownloader.MyJDownloaderSettings.json.backup"
    printf "[DOCKER-INIT] Removed MyJDownloader config backup\n"
fi

# Remove MyJDownloader device connect ports file (contains session-specific port mappings)
if [ -f "cfg/org.jdownloader.api.myjdownloader.MyJDownloaderSettings.deviceconnectports.json" ]; then
    rm -f "cfg/org.jdownloader.api.myjdownloader.MyJDownloaderSettings.deviceconnectports.json"
    printf "[DOCKER-INIT] Removed MyJDownloader device connect ports\n"
fi

# Remove MyJDownloader session database files (if they exist)
for pattern in "cfg/*myjd*.db" "cfg/myjd.*"; do
    for file in $pattern; do
        if [ -f "$file" ]; then
            rm -f "$file"
            printf "[DOCKER-INIT] Removed session file: %s\n" "$file"
        fi
    done
done

printf "[DOCKER-INIT] MyJDownloader session cleanup complete\n"
