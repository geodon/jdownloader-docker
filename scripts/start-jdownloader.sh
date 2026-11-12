#!/bin/sh
set -u

# Supervise the JDownloader JVM.
#
# JDownloader restarts itself when it installs a core update.  The restart is
# implemented by starting a new JVM and letting the old one exit.  If the
# container's PID 1 is the JVM, Docker considers the container finished and
# kills the whole cgroup while the update helper is still writing jars.  That
# leaves JDownloader.jar and Core.jar from different revisions.
#
# This script stays alive while *any* java process is running, so the container
# survives JDownloader's internal restart.  It also watches the JDownloader log
# to mark a successful start and to detect fatal class/linkage error loops.

BASE_DIR="${BASE_DIR:-/JDownloader}"
STATE_DIR="${STATE_DIR:-${BASE_DIR}/.docker}"
START_MARKER="${STATE_DIR}/start-marker"
HEALTHY_MARKER="${STATE_DIR}/healthy"
FORCE_REPAIR_MARKER="${STATE_DIR}/force-repair"
PREVIOUS_LOG_DIR=$(cat "${STATE_DIR}/previous-log-dir" 2>/dev/null || true)
STARTUP_TIMEOUT="${JD_STARTUP_TIMEOUT:-1800}"
FATAL_THRESHOLD="${JD_FATAL_ERROR_THRESHOLD:-5}"
POLL_INTERVAL="${JD_WATCH_INTERVAL:-5}"
SHUTDOWN_TIMEOUT="${JD_SHUTDOWN_TIMEOUT:-120}"

case "${STARTUP_TIMEOUT}" in ''|*[!0-9]*) STARTUP_TIMEOUT=1800 ;; esac
case "${FATAL_THRESHOLD}" in ''|*[!0-9]*|0) FATAL_THRESHOLD=5 ;; esac
case "${POLL_INTERVAL}" in ''|*[!0-9]*|0) POLL_INTERVAL=5 ;; esac
case "${SHUTDOWN_TIMEOUT}" in ''|*[!0-9]*|0) SHUTDOWN_TIMEOUT=120 ;; esac

mkdir -p "${STATE_DIR}" "${BASE_DIR}/logs"
touch "${START_MARKER}"
cd "${BASE_DIR}" || exit 1

log() {
    printf '[DOCKER-JD] %s\n' "$*"
}

java_pids() {
    pgrep -x java 2>/dev/null || true
}

any_java() {
    pgrep -x java >/dev/null 2>&1
}

reap_zombies() {
    for pid in $(ps -eo pid,stat,comm 2>/dev/null | awk '$3 == "java" && $2 ~ /^Z/ {print $1}'); do
        wait "${pid}" 2>/dev/null || true
    done
}

is_self_update_pid() {
    # The self-update helper runs from tmp/update/self/JDU/ and is the process
    # that rewrites JDownloader.jar.  Do not kill it while it is installing.
    tr '\0' ' ' < "/proc/$1/cmdline" 2>/dev/null | grep -q 'tmp/update/self/'
}

kill_java() {
    for pid in $(java_pids); do
        kill -TERM "${pid}" 2>/dev/null || true
    done
    i=0
    while any_java && [ "${i}" -lt 20 ]; do
        reap_zombies
        sleep 1
        i=$((i + 1))
    done
    for pid in $(java_pids); do
        kill -KILL "${pid}" 2>/dev/null || true
    done
}

# Newest JDownloader session log created after this start.  JDownloader log
# session directories are named with a millisecond timestamp; logs/updatehistory
# also lives under logs and must not be selected.
current_log_file() {
    [ -d "${BASE_DIR}/logs" ] || return 1
    latest_dir=$(ls -1d "${BASE_DIR}"/logs/[0-9]*/ 2>/dev/null | sort | tail -n 1)
    [ -n "${latest_dir}" ] || return 1
    if [ -n "${PREVIOUS_LOG_DIR}" ] && [ "${latest_dir}" = "${PREVIOUS_LOG_DIR}" ]; then
        return 1
    fi
    latest_log=$(ls -1 "${latest_dir}"Log.L.log* 2>/dev/null | grep -v '\.lck$' | head -n 1)
    [ -n "${latest_log}" ] || return 1
    printf '%s\n' "${latest_log}"
}

STOPPING=0
on_term() {
    STOPPING=1
    log "Termination requested; asking JDownloader to stop"

    # Ask the main JVM to terminate, but leave a self-update helper alone: it
    # is the process that rewrites JDownloader.jar.  If we kill it mid-write,
    # the next start sees a corrupt installation.
    for pid in $(java_pids); do
        if ! is_self_update_pid "${pid}"; then
            kill -TERM "${pid}" 2>/dev/null || true
        fi
    done

    i=0
    while any_java && [ "${i}" -lt "${SHUTDOWN_TIMEOUT}" ]; do
        reap_zombies
        sleep 1
        i=$((i + 1))
    done

    if any_java; then
        log "Shutdown timeout reached; killing remaining java processes"
        kill_java
    fi

    exit 0
}
trap on_term TERM INT

log "Starting JDownloader"
java -Djava.awt.headless=true -jar JDownloader.jar &
initial_pid=$!

healthy=0
elapsed=0
startup_warned=0
log_file=""
log_offset=0

while :; do
    reap_zombies

    if [ -n "${initial_pid}" ] && ! kill -0 "${initial_pid}" 2>/dev/null; then
        wait "${initial_pid}" 2>/dev/null || true
        initial_pid=""
    fi

    if ! any_java; then
        # JDownloader starts its replacement JVM before the old one exits, but
        # allow a short gap before concluding that it really stopped.
        sleep 3
        reap_zombies
        if ! any_java; then
            wait 2>/dev/null || true
            log "No JDownloader java process is running; exiting container supervisor"
            if [ "${STOPPING}" -eq 0 ]; then
                rm -f "${HEALTHY_MARKER}"
            fi
            break
        fi
    fi

    new_log=$(current_log_file 2>/dev/null || true)
    if [ -n "${new_log}" ]; then
        if [ "${new_log}" != "${log_file}" ]; then
            log "JDownloader session log changed; resetting error watchdog"
            log_file="${new_log}"
            log_offset=0
        fi

        size=$(wc -c < "${log_file}" 2>/dev/null || echo 0)
        if [ "${size}" -lt "${log_offset}" ]; then
            log "JDownloader log was truncated; resetting error watchdog"
            log_offset=0
        fi
        if [ "${size}" -gt "${log_offset}" ]; then
            chunk=$(tail -c +$((log_offset + 1)) "${log_file}" 2>/dev/null || true)
            log_offset="${size}"

            if [ "${healthy}" -eq 0 ] && printf '%s\n' "${chunk}" | grep -q "Initialisation finished"; then
                log "JDownloader initialisation finished"
                touch "${HEALTHY_MARKER}"
                healthy=1
            fi

            count=$(printf '%s\n' "${chunk}" | grep -E -c 'java\.lang\.(NoClassDefFoundError|IllegalAccessError|ClassNotFoundException|LinkageError)|JDLauncherFailedException' 2>/dev/null || true)
            case "${count}" in
                ''|*[!0-9]*) count=0 ;;
            esac
            if [ "${count}" -ge "${FATAL_THRESHOLD}" ]; then
                log "Detected ${count} fatal class/linkage errors; scheduling installation repair"
                rm -f "${HEALTHY_MARKER}"
                touch "${FORCE_REPAIR_MARKER}"
                kill_java
                break
            fi
        fi
    fi

    if [ "${healthy}" -eq 0 ]; then
        elapsed=$((elapsed + POLL_INTERVAL))
        if [ "${elapsed}" -ge "${STARTUP_TIMEOUT}" ] && [ "${startup_warned}" -eq 0 ]; then
            log "Startup still in progress after ${STARTUP_TIMEOUT}s; leaving it running (update/installation may be large)"
            startup_warned=1
        fi
    fi

    sleep "${POLL_INTERVAL}"
done

exit 0
