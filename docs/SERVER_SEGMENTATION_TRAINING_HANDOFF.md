# 서버 X-ray 병변 Segmentation 학습 핸드오프

## 목적

서버에서 Codex를 다시 켰을 때 바로 이어서 실제 흉부 X-ray 병변 segmentation 모델을 학습하고, 브라우저 오토라벨링용 TF.js 모델로 변환하기 위한 작업 설명서다.

현재 로컬 작업은 브라우저 우선 segmentation 라벨링 플로우와 smoke TF.js 모델까지 구현되어 있다. 서버에서는 synthetic smoke 모델을 실제 CheXlocalize 기반 학습 모델로 교체하는 것이 목표다.

## 현재 Git 상태

2026-05-25 기준으로 관련 변경은 GitHub에 push되어 있다.

| Repo | Branch | Commit | 내용 |
| --- | --- | --- | --- |
| `HELIOS-Main` | `codex-helios-frontend-redesign` | `aff382f` | root 문서, harness, segmentation worklog |
| `Heliosclient` | `codex/helios-frontend-redesign` | `4e2d4cc1` | segmentation labeling UI, TF.js loader, browser smoke model |
| `helios_ai` | `main` | `06774b0` | CheXlocalize 준비/학습/변환 스크립트 |

서버에서 시작할 때는 세 repo를 모두 최신 상태로 맞춘다.

```bash
cd /path/to/HELIOS-Main
git fetch origin
git checkout codex-helios-frontend-redesign
git pull

cd Heliosclient
git fetch origin
git checkout codex/helios-frontend-redesign
git pull

cd ../helios_ai
git fetch origin
git checkout main
git pull
```

## 구현된 브라우저 계약

프론트는 segmentation 모델을 아래 public asset에서 로드한다.

```text
Heliosclient/public/models/xray_lesion_seg_tfjs/model.json
```

관련 파일:

- `Heliosclient/src/lib/taskTypes.ts`
- `Heliosclient/src/lib/segmentationModel.ts`
- `Heliosclient/src/pages/LabelingSegmentationPage.tsx`
- `Heliosclient/src/components/segmentation/MaskEditor.tsx`
- `Heliosclient/src/lib/fl_client.js`

입출력 shape:

- 이미지 입력: `[N, 256, 256, 3]`
- 마스크 출력/라벨: `[N, 256, 256, 1]`
- mask 값: `0.0` 또는 `1.0`
- task type: `segmentation`

오토라벨링은 브라우저에서만 수행한다. 서버 fallback은 없다. 사용자의 의료 이미지를 `helios_ai`나 외부 API로 보내지 않는다.

## 서버 접근 가능 여부

현재 Codex 세션에는 서버 SSH 접속 정보가 없다. 서버에서 직접 진행하려면 서버 안에서 Codex를 켜고 이 문서를 기준으로 이어가면 된다.

필요한 서버 조건:

- Python 3.10 이상 권장
- 충분한 디스크 공간
- GPU가 있으면 CUDA TensorFlow 환경 권장
- GPU가 없어도 학습은 가능하지만 CheXlocalize 전체 학습은 느릴 수 있다.
- Node/npm은 frontend build 검증용으로 필요하다.

## 데이터 준비

CheXlocalize 원본 데이터는 Git에 넣지 않는다. 서버의 `helios_ai/data/chexlocalize/` 아래에 둔다.

예상 입력 예시:

```text
helios_ai/data/chexlocalize/
  gt_segmentations_val.json
  images/
    patient001.png
    patient002.png
```

실제 다운로드 파일명이 다르면 명령어의 경로만 맞춘다.

## Python 환경 생성

학습 환경과 TF.js 변환 환경을 분리하는 것을 권장한다. 로컬 smoke 작업에서는 `tensorflowjs`가 `protobuf`/`tensorflow-decision-forests`와 충돌할 수 있었다.

### 학습용 venv

```bash
cd /path/to/HELIOS-Main/helios_ai

python3 -m venv .venv-seg-train
source .venv-seg-train/bin/activate
python -m pip install --upgrade pip
python -m pip install tensorflow pillow numpy
```

CheXlocalize annotation JSON이 compressed COCO RLE이면 추가 설치가 필요하다.

```bash
python -m pip install pycocotools
```

GPU 서버라면 서버 CUDA/TensorFlow 정책에 맞게 TensorFlow 패키지를 설치한다. 이 문서는 패키지 이름을 강제하지 않는다.

## CheXlocalize mask pair 준비

```bash
cd /path/to/HELIOS-Main/helios_ai
source .venv-seg-train/bin/activate

python preprocessing/segmentation/prepare_chexlocalize_masks.py \
  --annotation-json data/chexlocalize/gt_segmentations_val.json \
  --source-image-dir data/chexlocalize/images \
  --output-dir data/xray_lesion_seg \
  --image-size 256
```

출력:

```text
helios_ai/data/xray_lesion_seg/
  images/
  masks/
```

기본 병변 union 대상:

- Atelectasis
- Cardiomegaly
- Consolidation
- Edema
- Enlarged Cardiomediastinum
- Lung Lesion
- Lung Opacity
- Pleural Effusion
- Pneumothorax
- Support Devices

## 모델 학습

첫 서버 smoke 학습:

```bash
cd /path/to/HELIOS-Main/helios_ai
source .venv-seg-train/bin/activate

python preprocessing/segmentation/train_xray_lesion_unet.py \
  --image-dir data/xray_lesion_seg/images \
  --mask-dir data/xray_lesion_seg/masks \
  --output-dir preprocessing/segmentation/xray_lesion_saved_model \
  --image-size 256 \
  --batch-size 8 \
  --epochs 20
```

메모리가 부족하면 `--batch-size 2` 또는 `--batch-size 4`로 낮춘다. 전체 학습 전에는 `--epochs 1`로 저장/변환 smoke test를 먼저 한다.

학습 스크립트 출력 모델 signature:

- input: `[None, 256, 256, 3]`
- output: `[None, 256, 256, 1]`

## TF.js 변환

변환용 venv를 따로 만든다.

```bash
cd /path/to/HELIOS-Main/helios_ai

python3 -m venv .venv-seg-convert
source .venv-seg-convert/bin/activate
python -m pip install --upgrade pip
python -m pip install tensorflowjs setuptools
```

변환:

```bash
preprocessing/segmentation/convert_xray_lesion_to_tfjs.sh \
  preprocessing/segmentation/xray_lesion_saved_model \
  ../Heliosclient/public/models/xray_lesion_seg_tfjs
```

출력 확인:

```bash
ls -lh ../Heliosclient/public/models/xray_lesion_seg_tfjs
```

최소 기대 파일:

```text
model.json
group1-shard*.bin
```

## 프론트 로딩 검증

```bash
cd /path/to/HELIOS-Main/Heliosclient
npm run build
npm run dev -- --host 127.0.0.1 --port 3002
```

다른 터미널에서:

```bash
curl -I http://127.0.0.1:3002/models/xray_lesion_seg_tfjs/model.json
curl -I http://127.0.0.1:3002/models/xray_lesion_seg_tfjs/group1-shard1of1.bin
```

shard 파일명이 여러 개면 실제 생성된 첫 shard 이름으로 확인한다.

TF.js 로딩과 더미 예측 확인:

```bash
cd /path/to/HELIOS-Main/Heliosclient

node --input-type=module -e "import * as tf from '@tensorflow/tfjs'; const m = await tf.loadGraphModel('http://127.0.0.1:3002/models/xray_lesion_seg_tfjs/model.json'); const x = tf.zeros([1,256,256,3]); const y = m.predict(x); const out = Array.isArray(y) ? y[0] : y; console.log('predict', out.shape.join(',')); tf.dispose([x, y]); m.dispose();"
```

기대 출력:

```text
predict 1,256,256,1
```

## 품질 확인

현재 모델은 binary lesion mask 오토라벨링 보조 모델이다. 의료적 확정 판단용이 아니다.

서버 학습 후 최소 확인:

- validation dice가 smoke 모델보다 유의미하게 상승하는지 확인
- 정상/비정상 X-ray 몇 장에서 mask가 완전히 빈 값으로만 나오지 않는지 확인
- 과도하게 전체 폐 영역을 칠하지 않는지 확인
- 브라우저 수동 editor에서 auto mask를 수정할 수 있는지 확인

## Git 반영

서버에서 실제 학습 모델로 교체되면 frontend repo에 TF.js asset만 커밋한다.

```bash
cd /path/to/HELIOS-Main/Heliosclient
git status --short
git add public/models/xray_lesion_seg_tfjs/model.json public/models/xray_lesion_seg_tfjs/*.bin
git commit -m "Update xray lesion segmentation model"
git push
```

학습 중간 산출물은 커밋하지 않는다.

커밋하지 않을 것:

- `helios_ai/data/`
- `helios_ai/.venv-*`
- `helios_ai/preprocessing/segmentation/*saved_model*/`
- raw CheXlocalize 이미지/annotation

## 알려진 이슈

- `make harness-check`는 백엔드 `Helios_backend/src/main/java/com/helios/auth/dto/TokenResponse.java`에 `private Long userId;`가 없어 실패한다.
- 백엔드 변경은 이 작업 범위에서 승인 없이 하지 않았다.
- 현재 브라우저 bundle은 smoke 모델이다. 실제 서버 학습 후 반드시 교체해야 한다.

## 서버 Codex 시작 프롬프트 예시

```text
HELIOS-Main repo에서 docs/SERVER_SEGMENTATION_TRAINING_HANDOFF.md를 읽고 이어서 진행해줘.
목표는 CheXlocalize 기반 X-ray lesion segmentation 모델을 서버에서 학습하고,
Heliosclient/public/models/xray_lesion_seg_tfjs/의 smoke TF.js 모델을 실제 학습 모델로 교체하는 거야.
백엔드 코드는 수정하지 말고, 데이터는 Git에 넣지 마.
먼저 데이터 경로와 GPU/CPU 환경을 확인한 뒤 1 epoch smoke train/convert/load 검증부터 해줘.
```
