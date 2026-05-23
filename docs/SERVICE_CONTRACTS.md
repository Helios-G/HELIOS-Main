# HELIOS Service Contracts

## Canonical Ports

| Service | Port | Source |
| --- | --- | --- |
| Frontend dev server | `3000` | `Heliosclient/vite.config.ts` |
| Spring Boot backend | `8081` | `Helios_backend/src/main/resources/application.properties` |
| FastAPI / WebSocket AI server | `8000` | `helios_ai/main.py` and compose |
| PostgreSQL | `5432` | `docker-compose.yml` |

## Directory Contracts

- Backend directory name: `Helios_backend`
- Frontend directory name: `Heliosclient`
- AI directory name: `helios_ai`

The root `docker-compose.yml` must use those exact names because the filesystem is case-sensitive.

## Frontend To Backend Contracts

- Login: `POST /auth/login`
- Login response must include `accessToken` and the authenticated `userId`.
- Authenticated user profile lookup: `GET /users/me`
- Session creation: `POST /sessions/create`
- Session creation payload must include the configured `rounds` value.
- Session listing: `GET /sessions`
- My sessions: `GET /sessions/my?userId=...`
- Session join: `POST /sessions/{sessionId}/join`
- Dev proxy target: `http://localhost:8081`
- Container proxy target: `http://helios-backend:8081`

## Frontend To AI Contracts

- Training WebSocket base: `ws://localhost:8000/ws/fl/...`
- The WebSocket `userId` query parameter must match the authenticated backend `userId`.
- The first WebSocket message must be `client_hello`.
- `client_hello.profile` must include:
  - `expectedDomain`
  - `detectedDomain`
  - `domainScore`
  - `trainSamples`
  - `testSamples`
  - `inputShape`
  - `labelShape`
  - `taskType`
  - `channelMeans`
  - `channelStddevs`
- Classification task tensors use:
  - `xTrain` / `xTest`: `[N, 224, 224, 3]`
  - `yTrain` / `yTest`: `[N, 14]` for CheXpert X-ray
- X-ray lesion segmentation task tensors use:
  - `xTrain` / `xTest`: `[N, 256, 256, 3]`
  - `yTrain` / `yTest`: `[N, 256, 256, 1]`
  - `taskType`: `segmentation`
  - `maskShape`: `[256, 256, 1]`
- AI model public path: `/models/chexpert_tfjs/model.json`
- Optional X-ray lesion segmentation auto-label model public path: `/models/xray_lesion_seg_tfjs/model.json`
- Both auto and manual labeling flows must produce train/test tensors before entering `SessionTrainingPage`.
- X-ray lesion segmentation labeling must produce train/test image and mask tensors before entering `SessionTrainingPage`.
- X-ray lesion segmentation auto-labeling must run in the browser with the TF.js asset when available.
- X-ray lesion segmentation auto-labeling must not upload images to `helios_ai` or external AI APIs as a fallback.
- Labeling must reject image batches whose inferred domain does not match the session `dataFormat`.
- Diagnostic report draft generation: `POST http://localhost:8000/reports/diagnostic-draft`
- Diagnostic report request must include:
  - `modelTitle`
  - `domainLabel`
  - `results` as ordered diagnosis candidates with `name` and `score`
- Diagnostic report request may include:
  - `sessionId`
  - `imageFileName`
  - `notes`
- Diagnostic report response returns:
  - `summary`
  - `findings`
  - `recommendations`
  - `caution`
  - `draft`
  - `storedPath`
- The AI server must allow browser CORS access from `http://localhost:3000` and `http://127.0.0.1:3000` for this REST endpoint.
- The AI server currently uses Gemini `generateContent` as the report-draft provider.
- AI report generation environment variables:
  - `GEMINI_API_KEY` or `GOOGLE_API_KEY`
  - optional `GEMINI_REPORT_MODEL`
- The AI server may load these values from `helios_ai/.env`.
- A checked-in example file is `helios_ai/.env.example`.

## Backend To AI Contracts

- Training start request: `POST http://localhost:8000/sessions/{sessionId}/start`
- The AI server may keep `POST /train/start` as a legacy fallback, but the session-scoped start route is canonical.
- Training start payload must include backend-selected `rounds`.
- Join callback target from AI service: `POST http://localhost:8081/sessions/{sessionId}/join`

## AI Screening Contracts

- The AI server is allowed to reject a client before training if its domain profile does not match the session domain.
- The AI server is allowed to exclude a client from a round if:
  - its fit response is much slower than the round median
  - its update vector is a strong outlier against the round cohort
- The AI server persists suspicious screening cases as a session report under `helios_ai/reports/`.
- Screening review report endpoint: `GET http://localhost:8000/sessions/{sessionId}/screening-report`

## Model Asset Contracts

The browser-accessible model bundle lives in:

- `Heliosclient/public/models/chexpert_tfjs/model.json`
- `Heliosclient/public/models/chexpert_tfjs/group1-shard1of7.bin`
- `...`
- `Heliosclient/public/models/chexpert_tfjs/group1-shard7of7.bin`
- `Heliosclient/public/models/dr_tfjs_manual/model.json`
- `Heliosclient/public/models/dr_tfjs_manual/group1-shard1of24.bin`
- `...`
- `Heliosclient/public/models/dr_tfjs_manual/group1-shard24of24.bin`
- Optional X-ray lesion segmentation auto-label bundle:
  - `Heliosclient/public/models/xray_lesion_seg_tfjs/model.json`
  - shard files generated by `tensorflowjs_converter`

The following files rely on that bundle shape:

- `Heliosclient/src/pages/LabelingAutoPage.tsx`
- `Heliosclient/src/pages/LabelingManualPage.tsx`
- `Heliosclient/src/pages/LabelingSegmentationPage.tsx`
- `Heliosclient/src/lib/segmentationModel.ts`
- `Heliosclient/src/utils/download.ts`
- `Heliosclient/src/pages/ModelInferencePage.tsx`

For browser-playground inference, the frontend may auto-load one of the bundled model manifests directly from these public paths without requiring the user to download and re-upload `.bin` shards manually.

## Root Harness Scope

The root harness currently enforces:

- service directory existence
- compose path correctness
- port consistency across root and service configs
- browser model asset presence
- train/test tensor handoff in both labeling flows
- segmentation route, task type, and mask tensor handoff

The root harness does not yet enforce:

- API schema compatibility
- DB schema migrations
- end-to-end WebSocket behavior
