---
noteId: "202605240120_xray_lesion_segmentation_result"
tags: ["helios", "xray", "segmentation", "result"]
---

# X-ray 병변 Segmentation 결과

## 상태

브라우저 오토라벨 smoke 모델까지 생성 완료.

## 현재까지 완료

- classification과 segmentation을 구분하는 task type 유틸을 추가했다.
- X-ray 병변 segmentation 라벨링 페이지와 mask editor를 추가했다.
- segmentation 오토라벨링은 `/models/xray_lesion_seg_tfjs/model.json` TF.js asset이 있을 때만 브라우저에서 수행하도록 만들었다.
- 서버 fallback은 만들지 않았다.
- segmentation 학습 텐서는 `[N, 256, 256, 3]` / `[N, 256, 256, 1]`로 생성한다.
- FL 클라이언트는 classification이면 기존 CNN, segmentation이면 작은 encoder-decoder 모델을 사용한다.
- segmentation metric은 Dice 중심으로 학습 화면에 표시된다.
- Keras U-Net 학습 스크립트와 TF.js 변환 helper를 추가했다.
- CheXlocalize annotation을 binary lesion mask pair로 준비하는 스크립트를 추가했다.
- segmentation 모델 생성 README를 추가했다.
- Mac 로컬 smoke 학습 환경을 만들고 synthetic dataset으로 2 epoch 학습을 실행했다.
- smoke 모델을 TF.js graph model로 변환해 브라우저 asset 경로에 배치했다.
  - `Heliosclient/public/models/xray_lesion_seg_tfjs/model.json`
  - `Heliosclient/public/models/xray_lesion_seg_tfjs/group1-shard1of1.bin`

## 검증

- `cd Heliosclient && npm run build`: 통과
- `python3 -m py_compile helios_ai/main.py helios_ai/preprocessing/segmentation/train_xray_lesion_unet.py`: 통과
- `cd helios_ai/preprocessing/segmentation && python3 -m unittest test_prepare_chexlocalize_masks.py -v`: 통과
- `cd helios_ai/preprocessing/segmentation && ../../../.venv-seg-smoke/bin/python -m unittest test_prepare_chexlocalize_masks.py -v`: 통과
- `make harness-check`: 실패

## 남은 이슈

- `make harness-check`는 현재 백엔드 `TokenResponse`에 `private Long userId;`가 없어 실패한다.
- 백엔드 변경은 작업 정책상 사용자 승인 전에는 하지 않았다.
- 현재 브라우저 asset은 synthetic smoke dataset으로 만든 동작 확인용 모델이다.
- 실제 오토라벨링 품질 검증에는 CheXlocalize 기반 실제 학습 산출물로 교체해야 한다.
