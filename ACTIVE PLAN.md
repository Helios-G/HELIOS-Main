---
noteId: "202603301856_active_plan"
tags: []
---

# HELIOS Active Plan

## Current Focus

- `Heliosclient`와 `helios_ai`의 학습 task를 classification과 segmentation으로 확장한다.
- 첫 segmentation 대상은 흉부 X-ray 병변 binary mask이며, 오토라벨링과 수동 라벨링을 모두 브라우저 로컬 우선으로 지원한다.

## Scope

- API/WS 계약과 포트는 유지한다.
- 백엔드 코드는 수정하지 않는다.
- 기존 CheXpert classification 라벨링과 학습 흐름은 계속 동작해야 한다.
- X-ray segmentation은 병변 mask를 `[N, H, W, 1]` 텐서로 전달한다.
- segmentation 오토라벨링은 TF.js 모델 번들이 있을 때만 브라우저에서 수행한다.
- segmentation 모델이 없거나 로드에 실패하면 서버 fallback 없이 수동 mask editor만 제공한다.
- 의료 이미지는 segmentation 오토라벨링을 위해 `helios_ai` 또는 외부 API로 업로드하지 않는다.

## Working Rules

- `ACTIVE PLAN.md`는 루트의 활성 계획 파일이다.
- 새 작업 디렉터리는 `worklogs/YYYY-MM-DD_HH-mm_vNN_short_summary` 형식을 따른다.
- 작업 문서 `PLAN.md`, `SPEC.md`, `WORKLOG.md`, `RESULT.md`는 기본적으로 한국어로 작성한다.
- 백엔드 변경이 필요해지면 파일과 이유를 먼저 사용자에게 보고하고 승인 전에는 수정하지 않는다.

## Default Task Flow

1. 새 작업 디렉터리를 만든다.
2. `PLAN.md`를 먼저 작성한다.
3. 필요하면 `SPEC.md`를 추가한다.
4. 진행 상황은 `WORKLOG.md`에 누적 기록한다.
5. 작업 종료 또는 일시 중단 시 `RESULT.md`를 갱신한다.
6. 활성 작업이 바뀌면 이 파일을 갱신한다.

## Current Task Record

- Active task directory: `worklogs/2026-05-25_17-10_v01_server-segmentation-training-handoff`
