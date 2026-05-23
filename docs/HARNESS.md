# Harness Engineering In HELIOS

## Definition

For this workspace, harness engineering means:

- making the repository legible to humans and agents
- encoding cross-service assumptions as files and checks
- adding short feedback loops so integration drift is caught early

This is not a prompt library. It is repository scaffolding.

## What We Added

- `AGENTS.md` as a short entry point
- `docs/` as the system of record for root-level knowledge
- `scripts/harness/check.sh` for mechanical static validation
- `scripts/harness/smoke.sh` for a local validation loop
- `Makefile` as the stable command surface

## Why This Fits HELIOS

HELIOS is a multi-service project with three separate repositories under one root. Its highest-risk failures are not deep algorithmic bugs; they are integration drifts such as:

- wrong service directory casing in compose
- port mismatches between services
- browser training pages handing off incomplete tensors
- public model asset paths drifting from the code that loads them

Those are exactly the kinds of issues a harness should make legible and enforceable.

## Ownership Guardrails

The default development posture for this workspace is:

- optimize for `Heliosclient` and `helios_ai`
- treat `Helios_backend` as an adjacent integration dependency
- avoid backend code changes unless the task cannot be completed safely without them

If backend code changes become necessary, the harness requires an explicit user review step before making that change. The intent is to keep our work aligned with the role boundary that we are frontend and AI server developers, not the primary backend developers.

## Local Workflow

Run these from the root workspace:

- `make harness-check`
  - fast static contract checks
- `make harness-smoke`
  - static checks
  - frontend production build
  - backend tests with a workspace-local Gradle cache

## Default Runtime Validation Sequence

Use this as the default manual verification flow after merges or cross-service changes.

1. Frontend static check

- `cd Heliosclient && npm run build`

2. AI static check

- `cd helios_ai && python3 -m py_compile main.py`

3. Start the runtime services in this order

- `cd helios_ai && python3 -m uvicorn main:app --host 127.0.0.1 --port 8000`
- `cd Heliosclient && npm run dev -- --host 127.0.0.1 --port 3000`
- Only if end-to-end verification is needed:
  `cd Helios_backend && ./gradlew bootRun`

4. Verify live HTTP surfaces

- `curl -I http://127.0.0.1:3000/`
- `curl -I http://127.0.0.1:8000/docs`
- `curl http://127.0.0.1:8000/openapi.json`

5. Verify AI WebSocket acceptance

- Open `ws://127.0.0.1:8000/ws/fl/{session_id}/{user_token}?userId={id}`
- Confirm the socket connects successfully before testing FL rounds

6. Full-stack backend + AI end-to-end check

- Sign up two users through `/auth/signup`
- Log both in through `/auth/login`
- Create one session through `/sessions/create` with `memberCount=2`
- Open two AI WebSocket clients for that `sessionId`
- Let the AI server call backend `/sessions/{sessionId}/join` for each client
- Confirm the second join triggers backend `POST http://localhost:8000/train/start`
- Confirm both clients receive 5 `status` messages and 5 `fit` messages
- Confirm both clients close cleanly after FL completes
- Confirm `/sessions` shows the target session full and `/sessions/my?userId=...` returns the joined session

7. Cleanup

- Stop `uvicorn`, `vite`, and `bootRun`
- Remove transient artifacts such as `__pycache__`
- Restore generated frontend build artifacts if they changed during validation

## Validation Notes

- This workspace treats frontend and AI as the primary development surface.
- Running the backend for integration verification is expected when the task crosses service boundaries.
- Backend code changes are still exception-only and should be reviewed by the user before implementation.
- `Helios_backend` currently uses `spring.jpa.hibernate.ddl-auto=create`, so a local `bootRun` recreates tables and should be treated as disposable test state.

## Extension Points

The next useful harness upgrades would be:

- JSON-schema checks for API payloads shared across services
- a WebSocket smoke client for `helios_ai`
- a backend health endpoint plus compose health checks
- a root CI workflow if these three service repositories are ever consolidated
