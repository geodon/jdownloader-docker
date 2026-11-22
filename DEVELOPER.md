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
- `configure-captcha.sh`: Installs the `glm-ocr` JAC captcha method when `OPENROUTER_API_KEY` or `OLLAMA_URL` is set and removes it otherwise
- `glm-ocr.sh`: JAC method command; recognises `input.png` with OpenRouter or the `glm-ocr` model on Ollama and writes the text to `result.txt`
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

## Captcha solving

JDownloader supports external captcha solvers through JAC methods: each
directory in `jd/captcha/methods/` holds a `jacinfo.xml` with the supported
hosts and the command to run. `scripts/jac/glm-ocr/jacinfo.xml` declares the
`glm-ocr` method for the Keep2Share family: `k2s.cc`, `fileboom.me` and
`tezfiles.com`. Their JDownloader plugins share the same Keep2Share API
captcha, and each alternative domain maps to one of these host names.

`configure-captcha.sh` copies that file to
`/JDownloader/jd/captcha/methods/glm-ocr/` and links `glm-ocr.sh` next to it.
For each image captcha of those hosts, JDownloader writes `input.png` in that
directory, runs `glm-ocr.sh` from it and reads the answer from `result.txt`.
The script tries the configured backends in the order of `GLM_OCR_BACKENDS`
(default `openrouter ollama`):

- `openrouter`, enabled by `OPENROUTER_API_KEY`, sends the image and a prompt
  describing the captcha to `OPENROUTER_MODEL` through the OpenAI-compatible
  chat completions API. The default model, `z-ai/glm-5.3-flash`, was chosen
  by comparing models on saved captchas. Most glm-ocr failures come from the
  plain vertical bar of the captcha font, which glm-ocr reads as `1`. The
  bar stands for `l` or `I`, which the image does not tell apart, so no model
  can solve every captcha.
- `ollama`, enabled by `OLLAMA_URL`, sends the image to the `glm-ocr` model.

The script removes everything but letters and digits from the answer, since
models sometimes wrap it in quotes or Markdown. An answer without exactly 6
characters is requested again, up to `GLM_OCR_ATTEMPTS` times per backend
(default 5). After the last attempt, or at once when a backend is
unreachable, times out after 30 seconds or returns an error, the next backend
is tried. `result.txt` stays empty when every backend fails. glm-ocr on
Ollama answers the same image the same way, so its retries rarely help. Runs are serialised per
method. Empty answers are ignored and the captcha falls back to the other
solvers.

When `GLM_OCR_SAMPLES_DIR` is set, the script also copies each image to
`<timestamp>_<pid>.png` in that directory and appends the name, the answer,
the backend and the attempt that gave it, separated by tabs, to
`answers.tsv`. The verdict of each answer is in the hoster plugin log:
`Captcha accepted` or `Invalid captcha code`; `Download count files exceed`
also comes after a valid captcha, but `Download is not available` does not
tell. Correct answers give labelled images for comparing other OCR models.

To test the OCR manually with an image from the host, run:

```bash
docker exec -i -w /tmp <container_name> sh -c 'cat >input.png && /scripts/glm-ocr.sh; cat result.txt' <captcha.png
```

## CI/CD

- GitHub Actions: `.github/workflows/docker-publish.yml`
  - Builds and pushes `latest` and a date tag to Docker Hub on every push to
    master
  - Builds and pushes `pr-<number>` on every push to a pull request from this
    repository, without touching `latest`, so the change can be deployed and
    tested before merging. Pull requests from forks are not built
  - Syncs README.md as overview on master builds

## Testing

- Use `make test` for local tests
- Test volumes are in `.local/`

## Notes

- The container runs as a configurable non-root user (UID/GID)
- Settings are applied on every container start
- For EventScripter script development, edit files in `scripts/` and restart the container

---

For questions or contributions, open an issue or pull request.
