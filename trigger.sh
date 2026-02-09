#!/usr/bin/env bash
# trigger.sh — push one feeds.check event per feed URL
# Usage: ./trigger.sh [--digest]
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"

# Push one check event per feed
while IFS= read -r url; do
  # Skip empty lines and comments
  [[ -z "$url" || "$url" == "#"* ]] && continue
  busytown events push --worker cron --type feeds.check \
    --payload "{\"url\":\"$url\"}"
done < <(deno eval "JSON.parse(Deno.readTextFileSync('$SCRIPT_DIR/feeds.json')).forEach((u: string) => console.log(u))")

echo "Pushed feeds.check events for all feeds."

# Optionally push digest request
if [[ "${1:-}" == "--digest" ]]; then
  busytown events push --worker cron --type digest.request
  echo "Pushed digest.request."
fi
