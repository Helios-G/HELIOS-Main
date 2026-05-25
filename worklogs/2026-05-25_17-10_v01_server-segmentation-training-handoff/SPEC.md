# 서버 Segmentation 학습 핸드오프 명세

## 전제

- 현재 Codex 세션에는 서버 SSH 접속 정보가 없다.
- 서버에서는 root, frontend, AI repo를 모두 최신 커밋으로 맞춘 뒤 진행한다.
- 실제 학습 데이터는 서버 로컬에만 둔다.

## 산출물

- `docs/SERVER_SEGMENTATION_TRAINING_HANDOFF.md`
- 이 worklog 디렉터리의 `PLAN.md`, `SPEC.md`, `WORKLOG.md`, `RESULT.md`

## 포함해야 할 내용

- 현재 Git branch/commit
- 서버 시작 명령
- Python venv 구성
- CheXlocalize image/mask pair 준비
- Keras U-Net 학습
- TF.js 변환
- 프론트 로딩 검증
- Git 커밋 대상과 제외 대상
- 알려진 harness/backend 이슈
