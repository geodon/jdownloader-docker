# jdownloader-docker: Developer Documentation

## Project Structure

- `Dockerfile`: Base image and JDownloader setup
- `scripts/`: Automatic configuration scripts (general, extensions, EventScripter, etc.)
- `config/`: JDownloader JSON configuration files
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

## CI/CD

- GitHub Actions: `.github/workflows/docker-publish.yml`
  - Builds and pushes to Docker Hub on every push to main
  - Syncs README.md as overview

## Testing

- Use `make test` for local tests
- Test volumes are in `.local/`

## Notes

- The container runs as a configurable non-root user (UID/GID)
- Settings are applied on every container start
- For EventScripter script development, edit files in `config/` and restart the container

---

For questions or contributions, open an issue or pull request.
