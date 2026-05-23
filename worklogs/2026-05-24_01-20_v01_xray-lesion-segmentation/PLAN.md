---
noteId: "202605240120_xray_lesion_segmentation_plan"
tags: ["helios", "xray", "segmentation", "plan"]
---

# X-ray 병변 Segmentation 작업 계획

## 메타데이터

- 작업 id: `2026-05-24_01-20_v01_xray-lesion-segmentation`
- 시작 일시: `2026-05-24 01:20 KST`
- 상태: 진행 중
- 담당자: Codex

## 목표

기존 classification 경로를 유지하면서 X-ray 병변 segmentation 라벨링, 오토라벨 모델 준비, 브라우저 FL 학습 경로를 추가한다.

## 제안 변경사항

- task type 유틸리티를 추가해 `classification`과 `segmentation`을 구분한다.
- segmentation 수동 라벨링을 위한 canvas mask editor를 추가한다.
- segmentation 오토라벨 TF.js 모델 loader를 추가하되, 서버 fallback은 만들지 않는다.
- FL 클라이언트를 task type에 따라 classification 모델 또는 segmentation 모델로 초기화한다.
- segmentation 모델 학습/변환 스크립트 골격을 `helios_ai/preprocessing/segmentation/`에 추가한다.
- docs와 harness check에 segmentation 모델 경로와 tensor handoff 조건을 반영한다.

## 검증 계획

- `cd Heliosclient/src && npm run build`
- `cd helios_ai && python3 -m py_compile main.py preprocessing/segmentation/train_xray_lesion_unet.py`
- `make harness-check`

## 백엔드 정책

백엔드 코드는 수정하지 않는다. task type 저장이 꼭 필요해지면 변경 파일과 이유를 사용자에게 먼저 보고하고 승인을 받은 뒤 진행한다.
