#!/usr/bin/env bash
set -euo pipefail

SQLITE3_VERSION="2.9.4"
SQLITE3_URL="https://github.com/simolus3/sqlite3.dart/releases/download/sqlite3-${SQLITE3_VERSION}/sqlite3.wasm"

mkdir -p web

echo "Compiling Drift web worker..."
dart compile js -O4 web/drift_worker.dart -o web/drift_worker.dart.js

if [[ ! -s web/sqlite3.wasm ]]; then
  echo "Downloading sqlite3.wasm ${SQLITE3_VERSION}..."
  curl -L --fail --retry 3 --retry-delay 2 \
    "$SQLITE3_URL" \
    -o web/sqlite3.wasm
fi

test -s web/drift_worker.dart.js
test -s web/sqlite3.wasm
