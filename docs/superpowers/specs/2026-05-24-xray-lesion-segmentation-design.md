# X-ray Lesion Segmentation Design

## Summary

HELIOS will support both classification and segmentation. The first segmentation target is binary lesion segmentation for chest X-ray images. The existing CheXpert classification flow remains available and unchanged for classification sessions.

## Core Decision

Segmentation auto-labeling is browser-first with no server fallback. The browser may download a TF.js segmentation model bundle, but patient images stay in browser memory and are not uploaded to `helios_ai` or any external AI API for mask generation.

## Data Shape

- Classification:
  - `xTrain/xTest`: `[N, 224, 224, 3]`
  - `yTrain/yTest`: `[N, 14]`
- Segmentation:
  - `xTrain/xTest`: `[N, 256, 256, 3]`
  - `yTrain/yTest`: `[N, 256, 256, 1]`

## Model Source

The first browser auto-label model should be trained from CheXlocalize annotations. The 10 pathology masks are unioned into a single binary lesion mask. The deployed model path is:

`Heliosclient/public/models/xray_lesion_seg_tfjs/model.json`

## Frontend Flow

- Session creation exposes task type: classification or segmentation.
- Classification sessions keep existing CheXpert and DR label workflows.
- X-ray segmentation manual labeling provides a canvas mask editor with brush and eraser.
- X-ray segmentation auto-labeling attempts to load the TF.js model and predicts a mask in the browser.
- If the model is missing or fails to load, auto-labeling is disabled and manual mask editing remains available.

## Training Flow

The browser FL client selects its model by task type. Classification uses the existing CNN classification head. Segmentation uses a small U-Net style model with sigmoid output, BCE/Dice loss, and Dice/IoU metrics. The AI server continues to coordinate WebSocket rounds and FedAvg without receiving images.

## Backend Boundary

No backend code changes are part of this task. If persistent task type storage becomes unavoidable, backend files and rationale must be reported to the user before any backend edit.
