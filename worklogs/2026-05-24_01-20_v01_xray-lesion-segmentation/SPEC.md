---
noteId: "202605240120_xray_lesion_segmentation_spec"
tags: ["helios", "xray", "segmentation", "tfjs"]
---

# X-ray 병변 Segmentation 스펙

## 메타데이터

- 작업 id: `2026-05-24_01-20_v01_xray-lesion-segmentation`
- 시작 일시: `2026-05-24 01:20 KST`
- 상태: 진행 중
- 담당자: Codex

## 요약

HELIOS는 기존 CheXpert classification 흐름을 유지하면서 흉부 X-ray 병변 segmentation을 추가한다. segmentation은 binary lesion mask를 대상으로 하며, 오토라벨링과 수동 라벨링을 모두 지원한다. 의료 이미지는 브라우저 밖으로 전송하지 않는다.

## 목표

- classification과 segmentation task를 프론트 학습 흐름에서 구분한다.
- X-ray segmentation 수동 라벨링은 브러시와 지우개로 병변 mask를 그리게 한다.
- X-ray segmentation 오토라벨링은 TF.js 모델 번들이 있을 때 브라우저에서만 수행한다.
- segmentation 학습 텐서는 `xTrain/xTest = [N, 256, 256, 3]`, `yTrain/yTest = [N, 256, 256, 1]`로 전달한다.
- segmentation FL 클라이언트는 작은 U-Net 계열 모델과 Dice/IoU 중심 지표를 사용한다.
- CheXpert classification의 기존 `[N, 224, 224, 3]` / `[N, 14]` 흐름은 깨지지 않아야 한다.

## 비목표

- 백엔드 DB 스키마를 바꾸지 않는다.
- 의료 이미지를 `helios_ai`로 업로드하는 segmentation endpoint를 만들지 않는다.
- 외부 AI API를 segmentation 오토라벨링에 사용하지 않는다.
- 첫 버전에서 질환별 multi-class mask를 만들지 않는다.

## 데이터와 모델

- 1차 모델 후보 데이터셋은 CheXlocalize다.
- CheXlocalize의 10개 pathology segmentation annotation을 union하여 하나의 binary lesion mask로 만든다.
- 모델 입력 크기는 브라우저 성능을 위해 `256x256`을 기본값으로 한다.
- 모델 출력은 sigmoid binary mask `[256, 256, 1]`이다.
- 배포 경로는 `Heliosclient/public/models/xray_lesion_seg_tfjs/model.json`이다.

## 보안 원칙

- 사용자가 선택한 X-ray 이미지는 브라우저 메모리에서만 decode, preview, mask 생성, tensor 변환을 수행한다.
- segmentation TF.js 모델은 정적 asset으로 다운로드되지만, 추론 입력 이미지는 서버로 전송하지 않는다.
- 모델 번들이 없거나 로드에 실패하면 오토라벨 기능을 비활성화하고 수동 라벨링만 허용한다.

## 수용 기준

- X-ray segmentation task에서 수동 mask를 만들고 학습 화면으로 이동할 수 있다.
- segmentation task의 `client_hello.profile.labelShape`는 `[N,256,256,1]` 형태를 보고한다.
- segmentation 학습은 BCE + Dice loss 또는 equivalent composite loss로 한 라운드 이상 실행 가능하다.
- 학습 화면은 classification에서 Accuracy를, segmentation에서 Dice/IoU를 표시한다.
- `npm run build`, `python3 -m py_compile helios_ai/main.py`, harness check가 통과하거나 실패 원인을 기록한다.

## 리스크

- CheXlocalize 데이터셋은 별도 다운로드와 라이선스 확인이 필요하다.
- 병변 segmentation 모델 품질은 초기에 낮을 수 있어 사람이 mask를 수정하는 흐름이 중요하다.
- 브라우저 메모리 사용량이 커질 수 있으므로 입력 크기와 batch size를 보수적으로 잡는다.
- task type을 백엔드에 저장하지 않으면 새로고침 후 복원에 한계가 있어 프론트 local session convention으로 보완한다.
