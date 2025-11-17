#!/bin/sh

# Configure MyJDownloader settings
/scripts/configure-myjd.sh

# Download JDownloader JAR if needed
/scripts/download-jar.sh

# Start JDownloader
exec java -jar JDownloader.jar -console -noerr -norestart
