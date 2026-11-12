# jdownloader-docker: Developer Documentation

## Project Structure

- `Dockerfile`: Base image and JDownloader setup
- `scripts/`: Automatic configuration and startup scripts
- `.github/workflows/`: CI/CD for build and Docker Hub publishing
- `Makefile`: Local development and testing workflow

## Local Development

1. Clone the repository and copy `.env.example` to `.env` to customize variables.
2. Use `make build` to build the image locally.
3. Use `make run` to launch a development container with local volumes.
4. The scripts in `scripts/` are executed automatically by the entrypoint.

## Main Scripts

- `entrypoint.sh`: Initialization orchestrator
- `_file-env.sh`: Support for Docker-style variables and secrets
- `_json-config.sh`: Utilities for manipulating JSON with jq
- `configure-myjd.sh`: Configures MyJDownloader credentials
- `configure-general.sh`: Applies general settings
- `configure-extraction.sh`: Configures Archive Extractor defaults
- `configure-extensions.sh`: Marks extensions for installation
- `configure-eventscripter.sh`: Configures EventScripter and scripts
- `configure-updates.sh`: Disables update-on-exit/background writes and optionally jar diffs
- `prepare-start.sh`: Tracks failed starts and requests installation repair when needed
- `download-jar.sh`: Verifies/downloads `JDownloader.jar` and resets mixed installations
- `start-jdownloader.sh`: Supervises the JVM across JDownloader self-restarts and watches logs
- `reset-installation.sh`: Removes `JDownloader.jar`, `Core.jar`, `tmp` and `update` (keeps config/downloads)
- `cleanup-update-cache.sh`: Manual maintenance script to clear updater cache/state

## Startup and recovery

`entrypoint.sh` runs the configuration scripts, then `prepare-start.sh`, then
`download-jar.sh`, and finally hands control to `start-jdownloader.sh`.

The supervisor starts Java in the background and does not exit while any `java`
process is running. This is required because JDownloader restarts itself during
core updates: the old JVM exits while the update helper is still writing jars.
If the container treated the old JVM as PID 1, Docker would kill the whole
cgroup mid-update and leave `JDownloader.jar` and `Core.jar` from different
revisions.

State is stored in `/JDownloader/.docker`:

- `started`: a start is in progress
- `healthy`: JDownloader logged `Initialisation finished`
- `fail-count`: consecutive starts that ended before becoming healthy
- `force-repair`: the supervisor detected fatal class/linkage errors
- `previous-log-dir`: newest log directory before the current start

When `fail-count` reaches `JD_MAX_START_FAILURES`, or `force-repair` exists,
`reset-installation.sh` is executed before the next launch. The launcher is then
downloaded again and the normal update process rebuilds the installation while
configuration and download lists are preserved.

`start-jdownloader.sh` also watches the current JDownloader log. A burst of
`NoClassDefFoundError`, `IllegalAccessError`, `ClassNotFoundException`,
`LinkageError` or `JDLauncherFailedException` entries triggers a repair instead
of leaving a live JVM in a permanent error loop.

## CI/CD

- GitHub Actions: `.github/workflows/docker-publish.yml`
  - Builds and pushes to Docker Hub on every push to master
  - Syncs README.md as overview

## Testing

- Use `make test` for local tests
- Test volumes are in `.local/`

## Notes

- The container runs as a configurable non-root user (UID/GID)
- Settings are applied on every container start
- For EventScripter script development, edit files in `scripts/` and restart the container

---

For questions or contributions, open an issue or pull request.
