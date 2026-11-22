#!/bin/sh
# JAC external method command for JDownloader: recognise the text of
# input.png and write it without whitespace to result.txt, both in the
# working directory.
#
# Backends, enabled by their variables:
# - openrouter: OPENROUTER_MODEL (default z-ai/glm-5.3-flash) on OpenRouter,
#   with the API key in OPENROUTER_API_KEY.
# - ollama: glm-ocr on the Ollama server at OLLAMA_URL.
# GLM_OCR_BACKENDS sets the order to try them (default "openrouter ollama").
# A backend that fails or returns an empty answer passes to the next one.
set -eu

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

# Print the answer of backend $1 without whitespace, or fail. Without
# pipefail, the exit status of the query is the one of curl.
recognise() {
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
  result=$(printf '%s\n' "$response" | jq -r "$text | gsub(\"\\\\s\"; \"\")") || return 1
  if [ -z "$result" ]; then
    echo "Empty answer from $1" >&2
    return 1
  fi
  printf '%s\n' "$result"
}

# Truncate before querying so a failure does not leave a stale answer.
exec >result.txt

answer=
for backend in ${GLM_OCR_BACKENDS:-openrouter ollama}; do
  if answer=$(recognise "$backend"); then
    break
  fi
  answer=
done
[ -n "$answer" ] || exit 1
printf '%s\n' "$answer"
