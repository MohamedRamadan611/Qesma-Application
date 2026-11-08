#!/usr/bin/env bash
# Regenerates mobile/packages/qesma_api from docs/openapi.json and refreshes mobile/openapi.sha256.
# Needs Docker (only here, never in CI) and a Flutter SDK on PATH. Never hand-edit the generated package.
set -euo pipefail
ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
GENERATOR="openapitools/openapi-generator-cli:v7.8.0"
OUT="$ROOT/mobile/packages/qesma_api"

rm -rf "$OUT"
MSYS_NO_PATHCONV=1 docker run --rm -v "$ROOT:/local" "$GENERATOR" generate \
  -i /local/docs/openapi.json -g dart-dio -o /local/mobile/packages/qesma_api \
  --additional-properties=pubName=qesma_api,pubVersion=1.0.0,serializationLibrary=built_value

(cd "$OUT" && dart pub get && dart run build_runner build)

# LF-normalised so a Windows (CRLF) checkout and Linux CI agree.
tr -d '\r' < "$ROOT/docs/openapi.json" | sha256sum | cut -d' ' -f1 > "$ROOT/mobile/openapi.sha256"
echo "openapi.sha256 = $(cat "$ROOT/mobile/openapi.sha256")"
