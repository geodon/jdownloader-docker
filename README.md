# jdownloader-docker
Dockerized JDownloader with quality-of-life enhancements

## Build

The image supports the following build arguments to customize the user that runs JDownloader:

- `UID`: User ID for the jdownloader user (default: `1000`)
- `GID`: Group ID for the jdownloader group (default: `1000`)

### Building with custom UID/GID

To build the image with your current user's UID/GID:

```bash
docker build --build-arg UID=$(id -u) --build-arg GID=$(id -g) -t jdownloader .
```

This ensures that files created in mounted volumes will have the correct ownership matching your host user.

### Building with default values

If you don't specify the arguments, the image will use UID/GID 1000:

```bash
docker build -t jdownloader .
```

## Configuration

### Environment Variables

The container requires the following environment variables to configure MyJDownloader:

- `MYJD_EMAIL` (**required**): Your MyJDownloader account email
- `MYJD_PASSWORD` (**required**): Your MyJDownloader account password
- `MYJD_DEVICENAME` (optional): Device name to identify this instance (default: `JDownloader`)

#### Using direct environment variables

```bash
docker run -d \
  --restart unless-stopped \
  -e MYJD_EMAIL=user@example.com \
  -e MYJD_PASSWORD=mypassword \
  -e MYJD_DEVICENAME=MyServer \
  -v /path/to/config:/JDownloader/cfg \
  -v /path/to/downloads:/Downloads \
  jdownloader
```

#### Using Docker secrets (recommended for production)

```bash
docker run -d \
  --restart unless-stopped \
  -e MYJD_EMAIL_FILE=/run/secrets/jd-email \
  -e MYJD_PASSWORD_FILE=/run/secrets/jd-password \
  --secret jd-email \
  --secret jd-password \
  -v /path/to/config:/JDownloader/cfg \
  -v /path/to/downloads:/Downloads \
  jdownloader
```

For each variable, you can use either:
- The variable directly with the value (e.g., `MYJD_EMAIL=value`)
- The variable with `_FILE` suffix pointing to a file containing the value (e.g., `MYJD_EMAIL_FILE=/path/to/file`)

The configuration is updated every time the container starts, so you can change credentials without recreating volumes.

### Direct Connection (Optional)

By default, JDownloader clients connect through the MyJDownloader cloud service. If you want to enable direct connection from the UI to the JDownloader instance:

1. **Expose port 3129** when running the container:
   ```bash
   docker run -d \
     --restart unless-stopped \
     -p 3129:3129 \
     -e MYJD_EMAIL=user@example.com \
     -e MYJD_PASSWORD=mypassword \
     -v /path/to/config:/JDownloader/cfg \
     -v /path/to/downloads:/Downloads \
     jdownloader
   ```

2. **Configure custom device IPs** in the JDownloader UI:
   - Go to Settings → Advanced Settings
   - Search for `customdeviceips`
   - Add the IP address(es) that clients should use to connect to the host
   - Example: If your host is at `192.168.1.100`, add that IP address

This allows the UI to connect directly to JDownloader without routing through the cloud, which can be faster and more reliable on a local network.
