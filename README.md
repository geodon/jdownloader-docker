# Awesome Dockerized JDownloader

Docker image for running JDownloader 2 with automatic configuration, MyJDownloader support, and quality-of-life enhancements.

## Features

- Runs JDownloader 2 in a container with persistent config and downloads
- MyJDownloader remote control support (required)
- Automatic EventScripter extension install and auto-update script
- Supervises JDownloader restarts and recovers automatically from broken updates
- Secure secrets support for credentials
- Runs as non-root user (configurable UID/GID)
- Easy to use with Docker or Docker Compose

---

## Usage

### Quick start with Docker

```bash
docker run -d \
  --name jdownloader \
  --init \
  --restart unless-stopped \
  -e MYJD_EMAIL=your@email.com \
  -e MYJD_PASSWORD=your_password \
  -e MYJD_DEVICENAME=MyJDownloader \
  -v /path/to/data:/JDownloader \
  -v /path/to/downloads:/Downloads \
  -p 3129:3129 \
  geodonz/jdownloader:latest
```

`--init` is recommended so orphaned update processes are reaped correctly.

#### Using Docker secrets (recommended for production)

```bash
docker run -d \
  --name jdownloader \
  --init \
  --restart unless-stopped \
  -e MYJD_EMAIL_FILE=/run/secrets/jd-email \
  -e MYJD_PASSWORD_FILE=/run/secrets/jd-password \
  --secret jd-email \
  --secret jd-password \
  -v /path/to/data:/JDownloader \
  -v /path/to/downloads:/Downloads \
  -p 3129:3129 \
  geodonz/jdownloader:latest
```

---

### Example docker-compose.yml

```yaml
version: '3.8'
services:
  jdownloader:
    image: geodonz/jdownloader:latest
    container_name: jdownloader
    init: true
    restart: unless-stopped
    stop_grace_period: 3m
    environment:
      - MYJD_EMAIL=your@email.com
      - MYJD_PASSWORD=your_password
      - MYJD_DEVICENAME=MyJDownloader
    ports:
      - 3129:3129
    volumes:
      - ./data:/JDownloader
      - ./downloads:/Downloads
```

`stop_grace_period` gives JDownloader time to finish a self-update before Docker
kills the container. With `docker run`, use `--stop-timeout 180` for the same
effect.

---

## Environment variables

- `MYJD_EMAIL` (**required**): Your MyJDownloader account email
- `MYJD_PASSWORD` (**required**): Your MyJDownloader account password
- `MYJD_DEVICENAME` (optional): Device name (default: JDownloader)
- `AUTO_EXTRACTION_ENABLED` (optional): Set the default automatic extraction behavior to `true` or `false`. If unset, leave the existing JDownloader setting unchanged. Individual archives can override this default.
- `DISABLE_ARCHIVE_DELETE` (optional): Keep archive files after extraction (`false` by default; set `true` to disable deletion)
- `JD_JARDIFF_ENABLED` (optional): Keep JDownloader jar diffs enabled (`true` by default). Set to `false` to force complete jars when downloading updates.
- `JD_MAX_START_FAILURES` (optional): Consecutive starts that may fail before automatic installation repair (default `3`).
- `JD_STARTUP_TIMEOUT` (optional): Seconds before logging a slow-start warning (default `1800`). It does not interrupt an update.
- `JD_FATAL_ERROR_THRESHOLD` (optional): Number of fatal class/linkage errors in one watch interval that triggers repair (default `5`).
- `JD_WATCH_INTERVAL` (optional): Supervisor polling interval in seconds (default `5`).
- `JD_SHUTDOWN_TIMEOUT` (optional): Seconds to wait for a self-update helper during container shutdown (default `120`).

For credentials, `MYJD_EMAIL_FILE` and `MYJD_PASSWORD_FILE` can supply the values from files. The other variables do not support `_FILE` variants.

## Volumes

- `/JDownloader`: JDownloader configuration and data (persistent)
- `/Downloads`: Download destination

## Ports

- `3129/tcp`: (optional) Direct connection for JDownloader UI

## Notes

- The container auto-installs the EventScripter extension and a safe auto-update script.
- EventScripter is enabled after the first container restart.
- The first time the auto-update script runs, it will request permission to call the JDownloader API. You must grant this permission in the MyJDownloader interface for the script to work.
- All configuration is applied on every container start.
- JDownloader runs under a supervisor. When JDownloader restarts itself to install an update, the container stays alive until every Java process, including the update helper, has finished. This prevents the mixed `JDownloader.jar`/`Core.jar` states that cause `IllegalAccessError` and `NoClassDefFoundError` restart loops.
- If JDownloader does not reach initialisation, the supervisor records the failure. After `JD_MAX_START_FAILURES` consecutive failed starts it removes `JDownloader.jar`, `Core.jar`, `tmp` and `update`, then downloads a fresh launcher. This preserves configuration, download lists and logs.
- If the JVM stays alive but repeatedly logs fatal class/linkage errors, the supervisor triggers the same repair on the next start.
- To force a repair manually, create the file `.fix_jd_install` inside the data volume and restart the container:
  ```bash
  touch /path/to/data/.fix_jd_install
  docker restart jdownloader
  ```
- To clear only the update cache manually, run `docker exec <container_name> /scripts/cleanup-update-cache.sh` and restart the container.
- For a complete manual repair, run `docker exec <container_name> /scripts/reset-installation.sh` and restart the container.
- For advanced configuration, see the [DEVELOPER.md](https://github.com/geodon/jdownloader-docker/blob/master/DEVELOPER.md) file.

---

## License

Apache License 2.0. See [LICENSE](https://github.com/geodon/jdownloader-docker/blob/master/LICENSE).
