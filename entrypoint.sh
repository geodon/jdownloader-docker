#!/bin/sh

# Configure MyJDownloader settings
/scripts/configure-myjd.sh

# Configure general settings
/scripts/configure-general.sh

# Configure extensions to install
/scripts/configure-extensions.sh

# Configure EventScripter extension
/scripts/configure-eventscripter.sh

# Download JDownloader JAR if needed
/scripts/download-jar.sh

# Start JDownloader
exec java -jar JDownloader.jar -console -noerr -norestart
