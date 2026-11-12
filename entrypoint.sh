#!/bin/sh

# Configure MyJDownloader settings
/scripts/configure-myjd.sh

# Configure general settings
/scripts/configure-general.sh

# Configure extensions to install
/scripts/configure-extensions.sh

# Configure Archive Extractor defaults
/scripts/configure-extraction.sh

# Configure EventScripter extension
/scripts/configure-eventscripter.sh

# Configure update behavior
/scripts/configure-updates.sh

# Recover from previous failed starts before touching the installation
/scripts/prepare-start.sh

# Verify the launcher and download it when missing or corrupt
/scripts/download-jar.sh

# Start JDownloader under a supervisor that survives its internal restarts
exec /scripts/start-jdownloader.sh
