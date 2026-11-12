#!/bin/sh
set -e

# Decide whether the previous start completed successfully and whether the
# installation needs repair before JDownloader is launched again.
#
# State lives on the /JDownloader volume:
#   started       - a start is in progress
#   healthy       - JDownloader logged "Initialisation finished" during that start
#   fail-count    - consecutive starts that ended before becoming healthy
#   force-repair  - a watchdog detected fatal errors and requested a reset
#   start-marker  - timestamp marker for this start
#   previous-log-dir - newest log directory before this start

BASE_DIR="${BASE_DIR:-/JDownloader}"
STATE_DIR="${STATE_DIR:-${BASE_DIR}/.docker}"
FAIL_FILE="${STATE_DIR}/fail-count"
STARTED_MARKER="${STATE_DIR}/started"
HEALTHY_MARKER="${STATE_DIR}/healthy"
FORCE_REPAIR_MARKER="${STATE_DIR}/force-repair"
START_MARKER="${STATE_DIR}/start-marker"
MAX_FAILURES="${JD_MAX_START_FAILURES:-3}"

case "${MAX_FAILURES}" in
    ''|*[!0-9]*|0)
        MAX_FAILURES=3
        ;;
esac

mkdir -p "${STATE_DIR}"

force_repair=0
if [ -f "${FORCE_REPAIR_MARKER}" ]; then
    force_repair=1
fi

failures=0
if [ -f "${HEALTHY_MARKER}" ]; then
    # The previous run reached normal operation, so this is not a crash loop.
    failures=0
elif [ -f "${STARTED_MARKER}" ]; then
    failures=$(cat "${FAIL_FILE}" 2>/dev/null || echo 0)
    case "${failures}" in
        ''|*[!0-9]*)
            failures=0
            ;;
    esac
    failures=$((failures + 1))
fi

# Start a fresh attempt.
rm -f "${HEALTHY_MARKER}" "${STARTED_MARKER}" "${FORCE_REPAIR_MARKER}"
touch "${STARTED_MARKER}"

if [ "${force_repair}" -eq 1 ]; then
    printf "[DOCKER-RECOVERY] Watchdog requested a full installation repair\n"
    /scripts/reset-installation.sh "${BASE_DIR}"
    failures=0
elif [ "${failures}" -ge "${MAX_FAILURES}" ]; then
    printf "[DOCKER-RECOVERY] %s consecutive starts failed before initialisation; repairing installation\n" "${failures}"
    /scripts/reset-installation.sh "${BASE_DIR}"
    failures=0
fi

printf '%s\n' "${failures}" > "${FAIL_FILE}"
touch "${START_MARKER}"

# Remember the newest session log directory that already exists, so the
# supervisor can tell when JDownloader creates the log for the current run.
# Only directories starting with the millisecond timestamp are sessions;
# logs/updatehistory is not a session and must be ignored.
previous_log_dir=$(ls -1d "${BASE_DIR}"/logs/[0-9]*/ 2>/dev/null | sort | tail -n 1)
printf '%s\n' "${previous_log_dir}" > "${STATE_DIR}/previous-log-dir"

printf "[DOCKER-RECOVERY] Start attempt ready (previous failures: %s)\n" "${failures}"
