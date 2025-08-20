#!/usr/bin/env bash
# Simple placeholder generator hook. In Cursor, configure a file watcher on ../../api-docs.json
# to run this script, which can be extended to re-generate models/endpoints.

set -euo pipefail
ROOT_DIR="$(cd "$(dirname "$0")"/.. && pwd)"
SPEC="${ROOT_DIR}/../api-docs.json"

if [ ! -f "$SPEC" ]; then
  echo "OpenAPI spec not found at $SPEC" >&2
  exit 1
fi

echo "[AuthAPI] Detected change in api-docs.json. You can extend this script to regenerate stubs."
echo "Paths in spec:"
jq '.paths | keys' "$SPEC" || true

echo "(No code-gen performed; SDK stubs are already implemented.)"


