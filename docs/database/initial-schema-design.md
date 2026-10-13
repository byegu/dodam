# 도담 데이터베이스 Baseline 1.0

## 1. 정본

도담의 신규 MySQL 환경은 아래 두 Flyway 파일을 순서대로 적용한다.

1. `backend/src/main/resources/db/migration/V1_0_0__create_dodam_schema.sql`
2. `backend/src/main/resources/db/migration/V1_0_1__seed_dodam_defaults.sql`

첫 번째 파일은 MySQL 8.4 실행 스키마이자 ERDCloud SQL Import 정본이다. 두 번째 파일은 출시 활동 유형, 감정, 질문 폴백, 동의 약관 등 서비스 시작에 필요한 기준 데이터만 담는다. 과거 `V1`부터 `V53`까지의 누적 Migration은 Baseline 1.0으로 합쳤으며 신규 환경에서 다시 실행하지 않는다.

## 2. Baseline 요약

| 항목 | 확정 값 |
| --- | ---: |
| 업무 테이블 | 69개 |
| JSON 컬럼 | 2개 |
| 활성 그림 유형 | `ART_DIARY`, `HTP` |
| Refresh Token 저장소 | Redis |
| 그림·음성·PDF 원본 | MinIO |
| 캔버스 Stroke 운영 저장소 | MongoDB |

관계 검색, 소유권, 상태 전이, 멱등성, 감사 이력은 MySQL의 일반 컬럼과 FK/Unique/Check 제약으로 유지한다. 계약 변화가 잦고 생성 시점 Snapshot 재현이 중요한 분석·리포트 본문만 JSON 문서로 보관한다.

## 3. 도메인별 저장 구조

### 계정·아동·동의

- `users`, `auth_accounts`: 사용자와 소셜 Provider 식별자
- `children`, `guardian_child_relations`, `child_profile_image_files`: 아동 프로필과 보호자 접근 관계
- `consent_terms`, `consent_records`: 버전 있는 약관과 동의·철회 증빙
- `user_guardian_pins`: 보호자 화면 전환용 PIN Hash
- Refresh Token 원문과 Hash는 MySQL에 저장하지 않는다. Redis에서 Token family, 기기 식별자, TTL, Rotation 상태를 원자적으로 관리한다.

### 그림·대화·HTP

- `drawing_types`, `drawing_sessions`, `drawing_assets`, `drawing_session_emotions`: 활동 생명주기와 파일 Metadata
- `stroke_batches`, `stroke_events`, `stroke_event_points`: 관계형 호환·감사 경계. 운영 캔버스 원본은 MongoDB가 정본이다.
- `conversation_sessions`, `conversation_messages`와 선택지·대상 하위 테이블: 질문·답변 순서와 음성 처리 상태
- `htp_assessments`, `htp_assessment_steps`: HOUSE → TREE → PERSON 묶음과 현재 단계

### 분석

| 테이블 | 책임 |
| --- | --- |
| `analyses` | 분석 요청, 상태, 멱등성, Model 실행 정보 |
| `analysis_detected_objects` | 검색과 후속 질문에 필요한 정규화 탐지 객체 |
| `analysis_results` | 분석 계약 전체 Snapshot (`result_json`) |

기존 시각 특징·행동 특징·대화 요약·관찰 결과·미사용 입력 테이블은 `analysis_results.result_json`으로 합쳤다. 탐지 객체만 질문 생성과 좌표 검색에 직접 사용하므로 관계형 테이블로 유지한다.

### 리포트

| 테이블 | 책임 |
| --- | --- |
| `reports` | 생성 상태, 버전, PDF 상태, 실패·재시도 기준 |
| `report_documents` | 안전 검증을 마친 리포트 전체 Snapshot (`document_json`) |
| `report_evidence_items`, `report_evidence_relations` | 공개 근거 추적과 참조 무결성 |
| `report_drawn_items` | 보호자 화면의 객관적인 '그린 것' 감사 행 |
| `report_crisis_alerts`, `report_crisis_alert_steps`, `report_crisis_alert_resources` | 사전 검토된 위기 안내 감사 경계 |
| `report_generation_retries` | 비동기 생성 실패 재시도 |

리포트 상세 조회는 `report_documents.document_json`을 생성 시점 정본으로 사용한다. 현재 대화·분석 테이블을 다시 조합하지 않으므로 과거 리포트의 의미가 데이터 변경이나 AI 계약 변경으로 달라지지 않는다. 접근 권한과 JWT 이미지 Proxy URL처럼 조회 시점에 확인해야 하는 값만 현재 상태에서 보완한다.

### 커뮤니티·전문가·운영

커뮤니티, 전문가 검증, 알림, 신고·차단, 선별 기록, 감사 Log, Export·Storage 삭제 작업은 목록 검색과 권한 검증이 중심이므로 기존 관계형 구조를 유지한다. 이 영역은 테이블 수를 줄이기 위해 JSON으로 합치지 않는다.

## 4. JSON 사용 원칙

허용된 JSON 컬럼은 다음 두 개뿐이다.

- `analysis_results.result_json`
- `report_documents.document_json`

두 문서는 모두 `schema_version`과 생성 시각을 갖는다. 리포트 문서는 UTF-8 직렬화 결과의 SHA-256 Checksum도 저장한다. JSON 내부 값을 운영 목록 필터나 소유권 판정의 유일한 근거로 사용하지 않는다.

## 5. ERDCloud Import

1. ERDCloud에서 MySQL 프로젝트를 새로 만든다.
2. `V1_0_0__create_dodam_schema.sql` 전체를 UTF-8로 Import한다.
3. 업무 테이블이 69개인지 확인한다.
4. `analysis_results.result_json`, `report_documents.document_json` 외 JSON 컬럼이 없는지 확인한다.
5. `refresh_tokens` 테이블이 없는지 확인한다.

기준 데이터 파일 `V1_0_1__seed_dodam_defaults.sql`은 ERD 구조가 아니라 실행 환경 초기값이므로 ERDCloud에 Import하지 않아도 된다.

## 6. 기존 개발 DB 전환

이 Baseline은 기존 `V1`~`V53`에 이어 붙이는 증분 Migration이 아니다. 기존 개발 DB의 Flyway 이력과 테이블을 그대로 둔 채 배포하면 69개 구조로 정리되지 않는다.

전환 순서는 다음과 같다.

1. 필요한 자료가 있으면 전환 전에 백업한다.
2. 백엔드·AI·Worker 쓰기를 중지한다.
3. 대상이 개발/데모 DB인지 재확인한다.
4. 기존 MySQL Schema 또는 Volume을 제거하고 빈 Schema를 만든다.
5. Baseline 1.0이 포함된 백엔드를 기동해 Flyway `1.0.1`까지 적용한다.
6. `/actuator/health`와 핵심 가입 → 아동 등록 → 그림 활동 → 리포트 흐름을 확인한다.

운영 데이터가 필요한 환경에는 위 초기화 절차를 적용하면 안 된다. 해당 환경은 별도의 데이터 변환 Migration과 리허설이 필요하다. 저장소에는 자동으로 운영 데이터를 삭제하는 Script를 두지 않는다.

## 7. 변경 규칙

- Baseline 파일은 배포 이후 수정하지 않는다.
- 이후 구조 변경은 `V1_1_0__...`, 수정·보완은 `V1_0_2__...`처럼 의미 있는 Flyway 버전을 사용한다.
- 도메인 관계와 검색 조건을 먼저 확인하고, 테이블 수를 줄이기 위한 JSON 전환은 하지 않는다.
- Java Entity와 Migration 정합성, 업무 테이블 69개, JSON 2개 조건은 통합 테스트로 검증한다.
- 아동 그림·음성·대화 원문과 Secret은 Migration, 로그, Jira, Git에 기록하지 않는다.
