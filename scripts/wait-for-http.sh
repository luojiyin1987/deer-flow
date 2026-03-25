#!/usr/bin/env bash
#
# wait-for-http.sh - Wait for an HTTP endpoint to become ready
#
# Usage: ./scripts/wait-for-http.sh <url> [timeout_seconds] [service_name]
#
# Arguments:
#   url              - HTTP/HTTPS URL to probe (required)
#   timeout_seconds  - Max seconds to wait (default: 60)
#   service_name     - Display name for messages (default: "Service")
#
# Exit codes:
#   0 - Endpoint responded successfully
#   1 - Timed out waiting

set -euo pipefail

URL="${1:?Usage: wait-for-http.sh <url> [timeout] [service_name]}"
TIMEOUT="${2:-60}"
SERVICE="${3:-Service}"

elapsed=0
interval=1

probe_http() {
    if command -v curl >/dev/null 2>&1; then
        curl --silent --show-error --fail --output /dev/null "$URL" >/dev/null 2>&1
        return $?
    fi

    if command -v wget >/dev/null 2>&1; then
        wget --quiet --spider "$URL" >/dev/null 2>&1
        return $?
    fi

    if command -v python3 >/dev/null 2>&1; then
        python3 - "$URL" >/dev/null 2>&1 <<'PY'
import sys
import urllib.request

with urllib.request.urlopen(sys.argv[1], timeout=2):
    pass
PY
        return $?
    fi

    if command -v python >/dev/null 2>&1; then
        python - "$URL" >/dev/null 2>&1 <<'PY'
import sys
import urllib.request

with urllib.request.urlopen(sys.argv[1], timeout=2):
    pass
PY
        return $?
    fi

    echo "✗ No HTTP client available. Install curl, wget, or python." >&2
    return 1
}

while ! probe_http; do
    if [ "$elapsed" -ge "$TIMEOUT" ]; then
        echo ""
        echo "✗ $SERVICE failed readiness check at $URL after ${TIMEOUT}s"
        exit 1
    fi
    printf "\r  Waiting for %s readiness at %s... %ds" "$SERVICE" "$URL" "$elapsed"
    sleep "$interval"
    elapsed=$((elapsed + interval))
done

printf "\r  %-60s\r" ""
