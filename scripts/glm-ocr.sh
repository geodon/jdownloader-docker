#!/bin/sh
# JAC external method command for JDownloader: recognise the 6 letters and
# digits of the captcha in input.png and write them to result.txt, both in the
# working directory.
#
# Backends, enabled by their variables:
# - openrouter: OPENROUTER_MODEL (default z-ai/glm-5.3-flash) on OpenRouter,
#   with the API key in OPENROUTER_API_KEY.
# - ollama: glm-ocr on the Ollama server at OLLAMA_URL.
# GLM_OCR_BACKENDS sets the order to try them (default "openrouter ollama").
# Everything but letters and digits is removed from the answer. An answer
# without exactly 6 characters is requested again, up to GLM_OCR_ATTEMPTS
# times per backend (default 5); then, or when a backend fails, the next
# backend is tried.
#
# GLM_OCR_SAMPLES_DIR, when set, keeps each image and its answer there to
# build a test set for comparing OCR models.
set -eu

LENGTH=6

PROMPT="This is a captcha image. It contains exactly 6 characters: \
case-sensitive letters (A-Z, a-z) and digits (0-9), possibly overlapping and \
crossed by a line. Reply with only those 6 characters, nothing else."

# Print the response of OpenRouter. The key goes through a file descriptor so
# it does not show up in ps.
query_openrouter() {
  base64 -w0 input.png \
    | jq -Rs --arg model "${OPENROUTER_MODEL:-z-ai/glm-5.3-flash}" --arg prompt "$PROMPT" '{
        model: $model,
        temperature: 0,
        max_tokens: 2000,
        messages: [{role: "user", content: [
          {type: "text", text: $prompt},
          {type: "image_url", image_url: {url: ("data:image/png;base64," + .)}}
        ]}]
      }' \
    | curl -sS --max-time 30 -H 'Content-Type: application/json' -H @/dev/fd/3 \
        --data-binary @- https://openrouter.ai/api/v1/chat/completions 3<<EOF
Authorization: Bearer $OPENROUTER_API_KEY
EOF
}

query_ollama() {
  base64 -w0 input.png \
    | jq -Rs '{model: "glm-ocr", prompt: "Text Recognition:", images: [.], stream: false}' \
    | curl -sS --max-time 30 --data-binary @- "$OLLAMA_URL/api/generate"
}

# Print the raw answer of backend $1, or fail when it is not configured or
# returns an error. Without pipefail, the exit status of the query is the one
# of curl.
ask() {
  case "$1" in
    openrouter)
      [ -n "${OPENROUTER_API_KEY:-}" ] || return 1
      text='.choices[0].message.content // ""'
      ;;
    ollama)
      [ -n "${OLLAMA_URL:-}" ] || return 1
      text='.response // ""'
      ;;
    *)
      echo "Unknown OCR backend: $1" >&2
      return 1
      ;;
  esac
  response=$("query_$1") || return 1
  # Ollama returns the error as a string; OpenRouter as an object.
  if error=$(printf '%s\n' "$response" | jq -er '.error // empty | if type == "object" then .message else . end'); then
    echo "OCR error from $1: $error" >&2
    return 1
  fi
  printf '%s\n' "$response" | jq -r "$text"
}

# Truncate before querying so a failure does not leave a stale answer.
exec >result.txt

answer=
for backend in ${GLM_OCR_BACKENDS:-openrouter ollama}; do
  attempt=1
  while [ "$attempt" -le "${GLM_OCR_ATTEMPTS:-5}" ]; do
    raw=$(ask "$backend") || break
    # The model may wrap the answer in quotes or Markdown.
    answer=$(printf '%s' "$raw" | tr -cd 'A-Za-z0-9')
    if [ "${#answer}" -eq "$LENGTH" ]; then
      break 2
    fi
    echo "Invalid answer from $backend, attempt $attempt: $raw" >&2
    answer=
    attempt=$((attempt + 1))
  done
done
[ -n "$answer" ] || exit 1
printf '%s\n' "$answer"

# A failure to keep the sample must not discard the answer.
if [ -n "${GLM_OCR_SAMPLES_DIR:-}" ]; then
  sample="$(date -u +%Y%m%dT%H%M%SZ)_$$"
  {
    mkdir -p "$GLM_OCR_SAMPLES_DIR" \
      && cp input.png "$GLM_OCR_SAMPLES_DIR/$sample.png" \
      && printf '%s\t%s\t%s\t%s\n' "$sample" "$answer" "$backend" "$attempt" >>"$GLM_OCR_SAMPLES_DIR/answers.tsv"
  } || echo "Could not keep sample $sample in $GLM_OCR_SAMPLES_DIR" >&2
fi
