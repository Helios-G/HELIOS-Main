---
noteId: "202605240120_xray_lesion_segmentation_worklog"
tags: ["helios", "xray", "segmentation", "worklog"]
---

# X-ray 병변 Segmentation 작업 로그

## 현재 컨텍스트

- 사용자는 classification과 segmentation을 모두 지원하길 원한다.
- 첫 segmentation 대상은 흉부 X-ray 병변 mask다.
- 수동 라벨링은 브라우저 brush/eraser 방식으로 진행한다.
- 오토라벨링은 브라우저 TF.js 모델 우선이며 서버 fallback은 없다.
- 병변 segmentation 모델은 CheXlocalize 기반 Keras U-Net으로 직접 만드는 방향이다.

## 2026-05-24 01:20 KST

- 기존 CheXpert classification 흐름을 조사했다.
- 주요 영향 파일:
  - `Heliosclient/src/pages/SessionCreatePage.tsx`
  - `Heliosclient/src/pages/LabelingAutoPage.tsx`
  - `Heliosclient/src/pages/LabelingManualPage.tsx`
  - `Heliosclient/src/pages/SessionTrainingPage.tsx`
  - `Heliosclient/src/lib/fl_client.js`
  - `Heliosclient/src/contexts/TrainingDataContext.tsx`
  - `helios_ai/main.py`
- `ACTIVE PLAN.md`를 segmentation 작업으로 갱신했다.

## 2026-05-24 01:35 KST

- 프론트에 task type 유틸을 추가했다.
  - `Heliosclient/src/lib/taskTypes.ts`
- browser-local segmentation 오토라벨 모델 loader를 추가했다.
  - `Heliosclient/src/lib/segmentationModel.ts`
- 병변 mask 수동 편집 컴포넌트와 X-ray segmentation 라벨링 페이지를 추가했다.
  - `Heliosclient/src/components/segmentation/MaskEditor.tsx`
  - `Heliosclient/src/pages/LabelingSegmentationPage.tsx`
- 세션 생성/참여/학습 화면을 segmentation task로 분기하도록 수정했다.
  - `Heliosclient/src/pages/SessionCreatePage.tsx`
  - `Heliosclient/src/pages/SessionJoinPage.tsx`
  - `Heliosclient/src/pages/SessionTrainingPage.tsx`
- FL 클라이언트에 segmentation 모델, BCE+Dice loss, Dice/IoU metric을 추가했다.
  - `Heliosclient/src/lib/fl_client.js`
- CheXlocalize-style image/mask pair를 학습하는 Keras U-Net 스크립트와 TF.js 변환 helper를 추가했다.
  - `helios_ai/preprocessing/segmentation/train_xray_lesion_unet.py`
  - `helios_ai/preprocessing/segmentation/convert_xray_lesion_to_tfjs.sh`
- 문서와 harness에 segmentation 계약을 추가했다.

## 2026-05-24 01:45 KST

- 검증:
  - `cd Heliosclient && npm run build`: 통과
  - `python3 -m py_compile helios_ai/main.py helios_ai/preprocessing/segmentation/train_xray_lesion_unet.py`: 통과
  - `make harness-check`: 실패
- `make harness-check` 실패 원인:
  - 현재 백엔드 `Helios_backend/src/main/java/com/helios/auth/dto/TokenResponse.java`에 `private Long userId;`가 없다.
  - 이 파일은 AGENTS의 “로그인 응답 must include userId” 계약과 맞지 않지만, 백엔드 코드는 승인 없이 수정하지 않았다.
- 브라우저 확인:
  - Vite dev server는 sandbox 안에서 포트 바인딩 권한 문제로 실패했고, 승격 실행으로 `http://127.0.0.1:3002/`에 기동했다.
  - 보호 라우트 때문에 `/session/create`는 로그인 페이지로 redirect되었다.
  - 검증 후 dev server 프로세스를 종료했다.

## 2026-05-24 01:35 KST 추가

- CheXlocalize-style annotation JSON을 학습용 image/mask pair로 변환하는 준비 스크립트를 추가했다.
  - `helios_ai/preprocessing/segmentation/prepare_chexlocalize_masks.py`
- synthetic uncompressed COCO RLE 테스트를 추가했다.
  - `helios_ai/preprocessing/segmentation/test_prepare_chexlocalize_masks.py`
- 모델 생성 절차 README를 추가했다.
  - `helios_ai/preprocessing/segmentation/README.md`
- 검증:
  - `cd helios_ai/preprocessing/segmentation && python3 -m unittest test_prepare_chexlocalize_masks.py -v`: 통과

## 2026-05-24 02:00 KST

- 로컬 Mac smoke 학습 환경을 만들었다.
  - `.venv-seg-smoke`
  - TensorFlow 2.19.0
  - TensorFlow.js converter 4.22.0
- 현재 workspace 안에는 실제 CheXlocalize 이미지/annotation이 없어 synthetic smoke dataset을 생성했다.
  - `helios_ai/data/xray_lesion_seg_smoke/images`
  - `helios_ai/data/xray_lesion_seg_smoke/masks`
- synthetic 24장으로 2 epoch smoke 학습을 실행했다.
  - 출력 SavedModel: `helios_ai/preprocessing/segmentation/xray_lesion_saved_model_smoke`
  - 출력 signature: input `[None, 256, 256, 3]`, output `[None, 256, 256, 1]`
- smoke SavedModel을 브라우저용 TF.js graph model로 변환했다.
  - `Heliosclient/public/models/xray_lesion_seg_tfjs/model.json`
  - `Heliosclient/public/models/xray_lesion_seg_tfjs/group1-shard1of1.bin`
- 변환 중 `tensorflowjs`와 `protobuf`/`tensorflow-decision-forests` 조합 이슈가 있어 smoke 환경에서 `protobuf>=6.31.1`와 `setuptools<81`를 추가했다.
  - 실학습용 환경은 학습용 venv와 변환용 venv를 분리하는 편이 더 안정적이다.
- 로컬 학습 환경과 중간 SavedModel은 Git에 들어가지 않도록 ignore 규칙을 추가했다.
- 검증:
  - `cd Heliosclient && npm run build`: 통과
  - `python3 -m py_compile helios_ai/preprocessing/segmentation/prepare_chexlocalize_masks.py helios_ai/preprocessing/segmentation/train_xray_lesion_unet.py`: 통과
  - `cd helios_ai/preprocessing/segmentation && ../../../.venv-seg-smoke/bin/python -m unittest test_prepare_chexlocalize_masks.py -v`: 통과
