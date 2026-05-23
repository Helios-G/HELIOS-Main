#!/usr/bin/env bash

set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"

pass() {
  printf 'PASS %s\n' "$1"
}

fail() {
  printf 'FAIL %s\n' "$1" >&2
  exit 1
}

require_dir() {
  local rel="$1"
  [[ -d "$ROOT/$rel" ]] || fail "missing directory: $rel"
  pass "directory exists: $rel"
}

require_file() {
  local rel="$1"
  [[ -f "$ROOT/$rel" ]] || fail "missing file: $rel"
  pass "file exists: $rel"
}

require_contains() {
  local rel="$1"
  local needle="$2"
  rg -q --fixed-strings -- "$needle" "$ROOT/$rel" || fail "$rel missing required text: $needle"
  pass "$rel contains: $needle"
}

require_dir "Heliosclient"
require_dir "Helios_backend"
require_dir "helios_ai"
require_dir "docs"
require_dir "scripts/harness"

require_file "AGENTS.md"
require_file "Makefile"
require_file "docs/README.md"
require_file "docs/ARCHITECTURE.md"
require_file "docs/SERVICE_CONTRACTS.md"
require_file "docs/HARNESS.md"
require_file "docker-compose.yml"
require_file "scripts/harness/check.sh"
require_file "scripts/harness/smoke.sh"

require_contains "docker-compose.yml" "build: ./Helios_backend"
require_contains "docker-compose.yml" "build: ./Heliosclient"
require_contains "docker-compose.yml" "build: ./helios_ai"
require_contains "docker-compose.yml" "- \"8081:8081\""
require_contains "docker-compose.yml" "- \"8000:8000\""
require_contains "docker-compose.yml" "AI_SERVER_URL=http://helios-ai:8000"

require_contains "Helios_backend/src/main/resources/application.properties" "server.port=8081"
require_contains "Helios_backend/src/main/java/com/helios/auth/dto/TokenResponse.java" "private Long userId;"
require_contains "Helios_backend/src/main/java/com/helios/session/dto/SessionCreateRequest.java" "private Integer rounds;"
require_contains "Helios_backend/src/main/java/com/helios/learning/service/LearningService.java" "session.getRounds()"
require_contains "helios_ai/main.py" "SPRING_BOOT_URL = os.getenv(\"SPRING_BOOT_URL\", \"http://localhost:8081\")"
require_contains "helios_ai/main.py" "@app.post(\"/train/start\")"
require_contains "helios_ai/main.py" "@app.post(\"/sessions/{session_id}/start\")"
require_contains "helios_ai/main.py" "@app.websocket(\"/ws/fl/{session_id}/{user_token}\")"

require_contains "Heliosclient/vite.config.ts" "target: 'http://localhost:8081'"
require_contains "Heliosclient/default.conf" "proxy_pass http://helios-backend:8081;"
require_contains "Heliosclient/src/pages/LoginPage.tsx" "authFetch(\"/auth/login\""
require_contains "Heliosclient/src/pages/SessionTrainingPage.tsx" "ws://localhost:8000/ws/fl/"
require_contains "Heliosclient/src/pages/SessionCreatePage.tsx" "rounds: parseInt(rounds)"
require_contains "Heliosclient/src/pages/LabelingAutoPage.tsx" "/models/chexpert_tfjs/model.json"
require_contains "Heliosclient/src/pages/LabelingManualPage.tsx" "/models/chexpert_tfjs/model.json"
require_contains "Heliosclient/src/pages/LabelingManualPage.tsx" "setTrainingData(trainTensors.x, trainTensors.y, testTensors.x, testTensors.y);"
require_contains "Heliosclient/src/App.tsx" "/session/:sessionId/labeling/segmentation"
require_contains "Heliosclient/src/lib/taskTypes.ts" "XRAY_LESION_SEGMENTATION_MODEL_PATH = \"/models/xray_lesion_seg_tfjs/model.json\""
require_contains "Heliosclient/src/pages/LabelingSegmentationPage.tsx" "yAll.slice([0, 0, 0, 0]"
require_contains "Heliosclient/src/pages/LabelingSegmentationPage.tsx" "taskType: SEGMENTATION_TASK"
require_contains "Heliosclient/src/lib/fl_client.js" "createSegmentationModel()"
require_contains "Heliosclient/src/utils/download.ts" "const basePath = \"/models/chexpert_tfjs\";"

require_file "Heliosclient/public/models/chexpert_tfjs/model.json"
for shard in 1 2 3 4 5 6 7; do
  require_file "Heliosclient/public/models/chexpert_tfjs/group1-shard${shard}of7.bin"
done

pass "all HELIOS harness checks passed"
