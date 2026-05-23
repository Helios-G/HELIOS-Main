#!/usr/bin/env bash

set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"

"$ROOT/scripts/harness/check.sh"

printf 'RUN frontend build\n'
(
  cd "$ROOT/Heliosclient"
  npm run build
)

if [[ "${HELIOS_SKIP_BACKEND_TESTS:-0}" == "1" ]]; then
  printf 'SKIP backend tests (HELIOS_SKIP_BACKEND_TESTS=1)\n'
  exit 0
fi

printf 'RUN backend tests\n'
(
  cd "$ROOT/Helios_backend"
  GRADLE_USER_HOME="$ROOT/Helios_backend/.gradle" ./gradlew test
)
