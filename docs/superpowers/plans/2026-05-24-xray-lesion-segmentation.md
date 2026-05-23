# X-ray Lesion Segmentation Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Add browser-local X-ray lesion segmentation support while preserving existing classification workflows.

**Architecture:** The frontend introduces task-type aware labeling and training. Classification keeps the current CheXpert/DR path, while X-ray segmentation uses browser canvas masks, optional TF.js auto-label inference, and a segmentation FL client. The AI server remains image-free and only coordinates weights and metrics.

**Tech Stack:** React, Vite, TensorFlow.js, FastAPI orchestration, Keras/TensorFlow model training utilities, shell harness checks.

---

## File Structure

- `Heliosclient/src/lib/taskTypes.ts`: central task-type helpers and constants.
- `Heliosclient/src/lib/segmentationModel.ts`: browser TF.js lesion segmentation model loader and mask prediction helpers.
- `Heliosclient/src/components/segmentation/MaskEditor.tsx`: focused canvas editor for brush/eraser mask creation.
- `Heliosclient/src/pages/LabelingSegmentationPage.tsx`: X-ray segmentation labeling flow.
- `Heliosclient/src/lib/fl_client.js`: task-aware FL client with classification and segmentation models.
- `Heliosclient/src/pages/SessionCreatePage.tsx`: task type selection and X-ray segmentation preset.
- `Heliosclient/src/pages/SessionJoinPage.tsx`: route segmentation sessions to segmentation labeling.
- `Heliosclient/src/pages/SessionTrainingPage.tsx`: task-aware metrics display.
- `Heliosclient/src/App.tsx`: segmentation labeling route.
- `helios_ai/preprocessing/segmentation/train_xray_lesion_unet.py`: Keras U-Net training script for CheXlocalize-style image/mask pairs.
- `helios_ai/preprocessing/segmentation/convert_xray_lesion_to_tfjs.sh`: SavedModel to TF.js conversion helper.
- `scripts/harness/check.sh`: static checks for segmentation route/model path/task handoff.
- `docs/SERVICE_CONTRACTS.md`: segmentation model and tensor contracts.

### Task 1: Task Type Helpers And Session Preset

- [ ] Add `taskTypes.ts` with `classification`, `segmentation`, `isSegmentationTask`, and label-list conventions.
- [ ] Update session creation to expose classification/segmentation selection.
- [ ] Add an X-ray lesion segmentation preset that sets data type to `X-ray`, class list to `Lesion Mask`, and local task type to `segmentation`.
- [ ] Build to verify no TypeScript errors.

### Task 2: Segmentation Data Context Metadata

- [ ] Extend training metadata with `taskType`, `maskShape`, and metric preference.
- [ ] Keep existing `setTrainingData(xTrain, yTrain, xTest, yTest)` API stable.
- [ ] Ensure `client_hello.profile.labelShape` reports segmentation mask shape without backend changes.

### Task 3: Mask Editor

- [ ] Create a canvas editor with image layer, mask layer, brush size, draw mode, erase mode, clear, and opacity controls.
- [ ] Export binary mask tensors at `256x256x1`.
- [ ] Keep pointer events mouse/touch compatible.

### Task 4: Browser Segmentation Auto-Label Loader

- [ ] Add a TF.js loader for `/models/xray_lesion_seg_tfjs/model.json`.
- [ ] Return a disabled state when the model asset is missing or load fails.
- [ ] Convert model output to an editable canvas mask thresholded at `0.5`.
- [ ] Do not call `helios_ai` or any external API for image inference.

### Task 5: Segmentation Labeling Page

- [ ] Add `/session/:sessionId/labeling/segmentation`.
- [ ] Reuse existing X-ray domain screening before images enter labeling.
- [ ] Support manual mask editing for every image.
- [ ] Support optional browser auto-label mask generation when model is available.
- [ ] Convert edited images and masks into train/test tensors.

### Task 6: Task-Aware FL Client

- [ ] Refactor `MyFlowerClient` to accept `{ taskType }`.
- [ ] Preserve the current classification model and metrics.
- [ ] Add a small segmentation model with sigmoid output `[256,256,1]`.
- [ ] Compile segmentation with binary crossentropy plus Dice loss and report Dice/IoU as `accuracy`-compatible metrics.

### Task 7: Training Page Metrics

- [ ] Instantiate `MyFlowerClient({ taskType })`.
- [ ] Show Accuracy for classification.
- [ ] Show Dice or IoU for segmentation.
- [ ] Keep WebSocket contract unchanged.

### Task 8: Model Training Utilities

- [ ] Add a Keras U-Net training script that accepts local image and mask directories.
- [ ] Save a TensorFlow SavedModel suitable for TF.js conversion.
- [ ] Add a conversion shell helper documenting the expected `tensorflowjs_converter` command.

### Task 9: Docs And Harness

- [ ] Update service contracts for task type, segmentation tensor shapes, and model path.
- [ ] Update harness checks for the segmentation route, model path constant, and `[N,256,256,1]` handoff.
- [ ] Update worklog and result.

### Task 10: Verification

- [ ] Run `cd Heliosclient/src && npm run build`.
- [ ] Run `cd helios_ai && python3 -m py_compile main.py preprocessing/segmentation/train_xray_lesion_unet.py`.
- [ ] Run `make harness-check`.
- [ ] Record all outputs or blockers in `WORKLOG.md` and `RESULT.md`.
