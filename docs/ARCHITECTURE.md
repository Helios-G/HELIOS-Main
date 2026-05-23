# HELIOS Architecture

## Workspace Topology

The root workspace coordinates three services plus one database:

- `Heliosclient`
  - React/Vite UI
  - TensorFlow.js labeling and browser-local training
  - Session creation, participation, and training dashboards
- `Helios_backend`
  - Spring Boot API
  - Auth, users, sessions, and training orchestration
  - PostgreSQL-backed persistence
- `helios_ai`
  - FastAPI app
  - WebSocket coordination for federated training rounds
  - Weight aggregation with `FedAvg`
- `helios-db`
  - PostgreSQL runtime dependency

## Ownership Boundaries

### Frontend

The frontend owns:

- user-facing routes and forms
- browser-side image labeling
- browser-side model training data preparation
- browser-side X-ray lesion mask editing and optional TF.js segmentation auto-labeling
- local training client behavior over WebSocket

The frontend does not own:

- durable user/session storage
- cross-client training orchestration
- model registry persistence

### Backend

The backend owns:

- user and session persistence
- join and capacity rules
- triggering federated runs when a session reaches capacity

The backend does not own:

- per-round model aggregation
- browser training execution

### AI Service

The AI service owns:

- WebSocket session fan-out/fan-in
- round coordination
- federated averaging
- notifying the backend when clients join

The AI service does not own:

- durable session metadata
- browser labeling workflows

## Critical Runtime Flow

1. A user creates a session in `Heliosclient`.
2. `Heliosclient` calls `Helios_backend` to persist the session.
3. A participant joins the session.
4. `Helios_backend` counts participants and starts AI orchestration when the max is reached.
5. A participant labels images or masks in the browser and creates:
   - `xTrain`
   - `yTrain`
   - `xTest`
   - `yTest`
   Classification labels use class vectors. X-ray segmentation labels use binary lesion masks.
6. `Heliosclient` connects to `helios_ai` over WebSocket.
7. `helios_ai` sends `fit` commands, collects local weights, and aggregates them.
8. The frontend renders round metrics and final results.

## Architectural Risks To Watch

- Port drift between compose, frontend runtime URLs, backend config, and AI runtime.
- Contract drift between labeling pages and the training page.
- Asset drift between public model files and the download/inference utilities.
- Task drift between classification and segmentation tensor shapes.
- Root workspace drift because the three services are maintained as separate repositories.
