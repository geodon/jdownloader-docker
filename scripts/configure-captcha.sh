#!/bin/sh
set -e

# Install the glm-ocr JAC method, which solves the image captchas of the hosts
# listed in jacinfo.xml with OpenRouter or an Ollama server, only when
# OPENROUTER_API_KEY or OLLAMA_URL is set.
#
# JDownloader writes the captcha to input.png, runs glm-ocr.sh without
# arguments from the method directory and reads the answer from result.txt.
# The script is linked instead of copied so it always matches the image.

METHOD_DIR="/JDownloader/jd/captcha/methods/glm-ocr"

if [ -n "${OPENROUTER_API_KEY:-}" ] || [ -n "${OLLAMA_URL:-}" ]; then
    mkdir -p "${METHOD_DIR}"
    cp /scripts/jac/glm-ocr/jacinfo.xml "${METHOD_DIR}/jacinfo.xml"
    ln -sf /scripts/glm-ocr.sh "${METHOD_DIR}/glm-ocr.sh"
    backends=
    for backend in ${GLM_OCR_BACKENDS:-openrouter ollama}; do
        case "${backend}" in
            openrouter) [ -n "${OPENROUTER_API_KEY:-}" ] && backends="${backends} openrouter (${OPENROUTER_MODEL:-z-ai/glm-5.3-flash})," ;;
            ollama) [ -n "${OLLAMA_URL:-}" ] && backends="${backends} ollama (${OLLAMA_URL})," ;;
        esac
    done
    if [ -n "${backends}" ]; then
        printf "[DOCKER-INIT] CONFIGURE\t%s\tCAPTCHA\tglm-ocr:%s\n" "${METHOD_DIR}" "${backends%,}"
    else
        printf "[DOCKER-INIT] WARNING\t%s\tCAPTCHA\tglm-ocr: no configured backend in GLM_OCR_BACKENDS (%s)\n" "${METHOD_DIR}" "${GLM_OCR_BACKENDS}"
    fi
elif [ -e "${METHOD_DIR}" ]; then
    rm -rf "${METHOD_DIR}"
    printf "[DOCKER-INIT] REMOVE\t%s\tCAPTCHA\tglm-ocr (OPENROUTER_API_KEY and OLLAMA_URL not set)\n" "${METHOD_DIR}"
fi
