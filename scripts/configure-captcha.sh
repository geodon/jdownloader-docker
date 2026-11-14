#!/bin/sh
set -e

# Install the glm-ocr JAC method, which solves the image captchas of the hosts
# listed in jacinfo.xml with an Ollama server, only when OLLAMA_URL is set.
#
# JDownloader writes the captcha to input.png, runs glm-ocr.sh without
# arguments from the method directory and reads the answer from result.txt.
# The script is linked instead of copied so it always matches the image.

METHOD_DIR="/JDownloader/jd/captcha/methods/glm-ocr"

if [ -n "${OLLAMA_URL:-}" ]; then
    mkdir -p "${METHOD_DIR}"
    cp /scripts/jac/glm-ocr/jacinfo.xml "${METHOD_DIR}/jacinfo.xml"
    ln -sf /scripts/glm-ocr.sh "${METHOD_DIR}/glm-ocr.sh"
    printf "[DOCKER-INIT] CONFIGURE\t%s\tCAPTCHA\tglm-ocr (%s)\n" "${METHOD_DIR}" "${OLLAMA_URL}"
elif [ -e "${METHOD_DIR}" ]; then
    rm -rf "${METHOD_DIR}"
    printf "[DOCKER-INIT] REMOVE\t%s\tCAPTCHA\tglm-ocr (OLLAMA_URL not set)\n" "${METHOD_DIR}"
fi
