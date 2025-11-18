# Awesome Dockerized JDownloader

Docker image for running JDownloader 2 with automatic configuration, MyJDownloader support, and quality-of-life enhancements.

## Features

- Runs JDownloader 2 in a container with persistent config and downloads
- MyJDownloader remote control support (required)
- Automatic EventScripter extension install and auto-update script
- Secure secrets support for credentials
- Runs as non-root user (configurable UID/GID)
- Easy to use with Docker or Docker Compose

---

## Usage

### Quick start with Docker

```bash
docker run -d \
  --name jdownloader \
  --restart unless-stopped \
  -e MYJD_EMAIL=your@email.com \
  -e MYJD_PASSWORD=your_password \
  -e MYJD_DEVICENAME=MyJDownloader \
  -v /path/to/data:/JDownloader \
  -v /path/to/downloads:/Downloads \
  -p 3129:3129 \
  geodonz/jdownloader:latest
```

#### Using Docker secrets (recommended for production)

```bash
docker run -d \
  --name jdownloader \
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
    restart: unless-stopped
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

---

## Environment variables

- `MYJD_EMAIL` (**required**): Your MyJDownloader account email
- `MYJD_PASSWORD` (**required**): Your MyJDownloader account password
- `MYJD_DEVICENAME` (optional): Device name (default: JDownloader)

You can also use `_FILE` variants for secrets (e.g. `MYJD_EMAIL_FILE`).

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
- For advanced configuration, see the [DEVELOPER.md](https://github.com/geodon/jdownloader-docker/blob/main/DEVELOPER.md) file.

---

## License

Apache License 2.0. See [LICENSE](https://github.com/geodon/jdownloader-docker/blob/main/LICENSE).

