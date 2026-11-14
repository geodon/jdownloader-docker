#!/bin/sh
# JAC external method command for JDownloader: recognise the text of
# input.png with glm-ocr on Ollama and write it without whitespace to
# result.txt, both in the working directory.
# OLLAMA_URL selects the server (default http://localhost:11434).
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

printf '%s\n' "$response" | jq -r '.response | gsub("\\s"; "")'
