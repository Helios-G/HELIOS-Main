# Planning And Worklog Workflow

## Purpose

This document defines how work should be planned and recorded in the HELIOS root workspace.

## Core Rule

- `ACTIVE PLAN.md` at the repository root is the active plan.
- `worklogs/` contains task-scoped historical records.
- Create or switch to the task-scoped `worklogs/` record before substantive implementation edits begin.
- New task records should follow the sample structure under `worklogs/sample/`.
- If backend code changes become necessary, record that scope change in the active task and report it to the user before editing backend files.

## Why This Split

- Active plans need to be easy to find and fast to update.
- Specs need to stay stable enough to review.
- Research notes should not pollute the active plan.
- Results should be easy to scan after work is done.

## Directory Layout

- Root active plan: `ACTIVE PLAN.md`
- Historical task records: `worklogs/YYYY-MM-DD_HH-mm_vNN_short_summary/`

Recommended contents:

- `PLAN.md`
- `SPEC.md`
- `WORKLOG.md`
- `RESULT.md`

## File Semantics

- `ACTIVE PLAN.md`: what we intend to do now.
- `SPEC.md`: what the task must satisfy.
- `WORKLOG.md`: ongoing progress, commands, observations, decisions, blockers, and next actions.
- `RESULT.md`: what actually happened.

## Document Language

- Write `PLAN.md`, `SPEC.md`, `WORKLOG.md`, and `RESULT.md` in Korean by default.
- Root-level coordination documents may use the language that best fits the task, unless another rule says otherwise.
- If a task needs English for an external audience or copied upstream artifact, note that exception in the active task record.

## Naming Convention

- Use `YYYY-MM-DD_HH-mm_vNN_short_summary`.
- Keep the date and time sortable.
- Use `vNN` to distinguish iterations of the same effort when needed.
- Keep the summary short.
- Prefer ASCII slugs for path stability.
- Existing legacy directories may keep the older naming scheme, but new directories should follow the sample format.

## When To Create Each File

- Always create `PLAN.md`.
- Create `SPEC.md` when behavior, scope, or acceptance needs precision.
- Create `WORKLOG.md` when the task involves research, debugging, implementation progress, or multiple experiments.
- Create `RESULT.md` when handing off, pausing, or finishing the task.
- For implementation tasks, create the task directory itself before substantive code changes rather than after the fact.

## Suggested Sections

- `PLAN.md`: metadata, goal, why now, proposed changes, validation plan, risks, user review notes, execution gate
- `SPEC.md`: metadata, summary, question, hypothesis or requirement, baseline, fixed conditions, variables, metrics, validation plan, promotion criteria, stop criteria
- `WORKLOG.md`: current context, repeated timestamped entries with changed files, commands, outputs, observations, and decisions
- `RESULT.md`: status, decision, what was tested or changed, comparison summary, interpretation, limitations, and next actions

## Research Basis

This workflow is based on a small set of practical documentation principles:

- top-level entry points should stay short
- rules and assumptions should be explicit
- active intent and historical evidence should be separated
- the system should be light enough to keep current during implementation

References:

- OpenAI, Harness Engineering
  https://openai.com/index/harness-engineering/
- RulePad paper on checkable design rules
  https://arxiv.org/abs/2007.05046
