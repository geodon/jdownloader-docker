#!/bin/sh
# JAC external method command for JDownloader: recognise the text of
# input.png with glm-ocr on Ollama and write it without whitespace to
# result.txt, both in the working directory.
# OLLAMA_URL selects the server (default http://localhost:11434).
# GLM_OCR_SAMPLES_DIR, when set, keeps each image and its answer there to
# build a test set for comparing OCR models.
set -eu

# Truncate before querying so a failure does not leave a stale answer.
exec >result.txt

# Without pipefail, set -e only catches a curl failure, the last command.
response=$(
  base64 -w0 input.png \
    | jq -Rs '{model: "glm-ocr", prompt: "Text Recognition:", images: [.], stream: false}' \
    | curl -sS --data-binary @- "${OLLAMA_URL:-http://localhost:11434}/api/generate"
)

if error=$(printf '%s\n' "$response" | jq -er '.error // empty'); then
  echo "Ollama error: $error" >&2
  exit 1
fi

answer=$(printf '%s\n' "$response" | jq -r '.response | gsub("\\s"; "")')
printf '%s\n' "$answer"

# A failure to keep the sample must not discard the answer.
if [ -n "${GLM_OCR_SAMPLES_DIR:-}" ]; then
  sample="$(date -u +%Y%m%dT%H%M%SZ)_$$"
  {
    mkdir -p "$GLM_OCR_SAMPLES_DIR" \
      && cp input.png "$GLM_OCR_SAMPLES_DIR/$sample.png" \
      && printf '%s\t%s\n' "$sample" "$answer" >>"$GLM_OCR_SAMPLES_DIR/answers.tsv"
  } || echo "Could not keep sample $sample in $GLM_OCR_SAMPLES_DIR" >&2
fi
