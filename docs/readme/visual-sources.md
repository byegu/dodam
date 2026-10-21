# README 시각 자료 출처

## 시스템 아키텍처

- `system-architecture.png`: 프로젝트에서 생성한 `system-architecture-수정.png` 원본. 2026-10-21 최종 발표자료의 시스템 아키텍처 페이지(슬라이드 14·22)와 시각적으로 대조한 뒤 변경 없이 복사했다.
- 그림은 전체 팀의 구성이다. 최종 Docker Compose 실행 환경은 `infra/docker-compose.yml` 및 프로젝트 사실표와 대조했다. 개인 구현이나 현재 운영 상태를 증명하는 그림이 아니다.
- 이름·연락처·접속 키·내부 서버 주소를 새로 추가하지 않았다. 원본 발표자료 전체는 게시하지 않는다.

## 개인 구현 흐름

- `implementation-flow.svg`: 기존 README의 개인 담당 설명을 문서용 벡터로 정리했다. 서비스의 따뜻한 색상과 발표자료의 영역 구분을 참고했다.
- 근거: `GuardianResourceAccessValidator`, `RedisRefreshTokenSessionStore`, 그림 활동 API·AI Client, `StorageReportAssetResolver`와 프로젝트 사실표의 DODAM-015·017·019·020·021.
- 그림은 처리 경계의 요약이며 모든 분기 또는 실제 호출 순서를 빠짐없이 나타낸 시퀀스 다이어그램은 아니다.
- AI 모델 학습·전체 인프라·전체 프론트엔드를 개인 구현으로 표시하지 않는다. 측정되지 않은 성능 수치는 추가하지 않았다.
