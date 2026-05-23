# HELIOS Docs Index

This `docs/` directory is the repository knowledge base for the root workspace.
`AGENTS.md` is only the entry point.

## Core Documents

- [`ARCHITECTURE.md`](./ARCHITECTURE.md): service boundaries, ownership, and the main runtime flow.
- [`SERVICE_CONTRACTS.md`](./SERVICE_CONTRACTS.md): ports, URLs, API/WS contracts, and shared asset paths.
- [`HARNESS.md`](./HARNESS.md): what “harness engineering” means here and how the local harness works.
- [`WORKFLOW.md`](./WORKFLOW.md): how active plans and task-scoped worklogs are structured.

## Working Rules

- Keep service-level truth in service code, not duplicated prose.
- Keep cross-service truth in this `docs/` directory.
- Prefer short, checkable invariants.
- If a cross-service assumption matters, encode it in `scripts/harness/check.sh`.
