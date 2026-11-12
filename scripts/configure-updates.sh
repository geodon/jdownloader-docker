#!/bin/sh
set -e

# Configure JDownloader update behavior.
#
# Updates are still allowed while JDownloader is idle (the EventScripter script
# calls restartAndUpdate).  We only disable the update paths that write files
# while the process is shutting down or in the background, because those can
# leave JDownloader.jar/Core.jar in an inconsistent state when the container is
# stopped at the wrong moment.
. /scripts/_json-config.sh

UPDATE_CONFIG="org.jdownloader.updatev2.UpdateSettings.json"

# Do not install updates while JDownloader is exiting.  The supervisor in
# start-jdownloader.sh handles restarts; writing jars during shutdown adds a
# window where the container can be killed mid-installation.
json_set_property "${UPDATE_CONFIG}" "installupdatesonexitenabled" "false"

# Avoid silent background updates that modify the installation while JD is
# running.  Explicit updates (EventScripter/restartAndUpdate) still work.
json_set_property "${UPDATE_CONFIG}" "installupdatessilentlyifpossibleenabled" "false"

# Jar diffs are faster but rely on the base jar matching exactly.  They are
# enabled by default; set JD_JARDIFF_ENABLED=false to force full jars when
# diagnosing or after repeated update corruption.
case "${JD_JARDIFF_ENABLED:-}" in
    false|FALSE|0|no|NO)
        json_set_property "${UPDATE_CONFIG}" "jardiffenabled" "false"
        ;;
esac

printf "[DOCKER-INIT] CONFIGURE\t%s\tupdate-on-exit/silent-updates disabled\n" "${UPDATE_CONFIG}"
