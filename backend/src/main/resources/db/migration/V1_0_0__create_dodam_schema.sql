-- Dodam 서비스의 초기 MySQL 8.x 스키마이다.
-- 개발·배포 환경을 새로 초기화할 때 이 파일과 V1_0_1 seed만 적용한다.

SET NAMES utf8mb4;
SET FOREIGN_KEY_CHECKS = 0;

CREATE TABLE `activity_template_attachments` (
  `id` bigint NOT NULL AUTO_INCREMENT COMMENT '미술 활동 자료 첨부 파일 ID',
  `activity_template_id` bigint NOT NULL COMMENT '미술 활동 자료 ID',
  `storage_key` varchar(1000) NOT NULL COMMENT '첨부 파일 저장 Key',
  `storage_key_hash` char(64) NOT NULL COMMENT '첨부 파일 저장 Key SHA-256 Hash',
  `file_name` varchar(255) DEFAULT NULL COMMENT '원본 파일명',
  `mime_type` varchar(100) DEFAULT NULL COMMENT 'MIME 유형',
  `display_order` smallint NOT NULL DEFAULT '0' COMMENT '노출 순서',
  `created_at` datetime(6) NOT NULL DEFAULT CURRENT_TIMESTAMP(6) COMMENT '생성 일시',
  PRIMARY KEY (`id`),
  UNIQUE KEY `uk_activity_template_attachments_key_hash` (`storage_key_hash`),
  UNIQUE KEY `uk_activity_template_attachments_order` (`activity_template_id`,`display_order`),
  CONSTRAINT `fk_activity_template_attachments_template_id` FOREIGN KEY (`activity_template_id`) REFERENCES `activity_templates` (`id`) ON DELETE CASCADE,
  CONSTRAINT `ck_activity_template_attachments_order` CHECK ((`display_order` >= 0))
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci COMMENT='미술 활동 자료 첨부 파일';

CREATE TABLE `activity_templates` (
  `id` bigint NOT NULL AUTO_INCREMENT COMMENT '미술 활동 자료 ID',
  `expert_profile_id` bigint DEFAULT NULL COMMENT '전문가 프로필 ID (NULL = 작성자 탈퇴)',
  `title` varchar(200) NOT NULL COMMENT '자료 제목',
  `summary` text COMMENT '자료 요약',
  `content` longtext NOT NULL COMMENT '자료 내용',
  `age_group` varchar(30) NOT NULL COMMENT '권장 연령 그룹',
  `activity_type` varchar(50) NOT NULL COMMENT '활동 유형',
  `thumbnail_key` varchar(1000) DEFAULT NULL COMMENT 'Thumbnail 저장 Key',
  `is_visible` tinyint(1) NOT NULL DEFAULT '1' COMMENT '공개 여부',
  `created_at` datetime(6) NOT NULL DEFAULT CURRENT_TIMESTAMP(6) COMMENT '생성 일시',
  `updated_at` datetime(6) NOT NULL DEFAULT CURRENT_TIMESTAMP(6) ON UPDATE CURRENT_TIMESTAMP(6) COMMENT '수정 일시',
  `deleted_at` datetime(6) DEFAULT NULL COMMENT '삭제 일시',
  PRIMARY KEY (`id`),
  KEY `idx_activity_templates_expert_created_at` (`expert_profile_id`,`created_at`),
  KEY `idx_activity_templates_visible_created_at` (`is_visible`,`created_at`),
  CONSTRAINT `fk_activity_templates_expert_profile_id` FOREIGN KEY (`expert_profile_id`) REFERENCES `expert_profiles` (`id`) ON DELETE SET NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci COMMENT='미술 활동 자료';

CREATE TABLE `ai_question_template_options` (
  `id` bigint NOT NULL AUTO_INCREMENT COMMENT 'AI 질문 Template 선택지 ID',
  `question_template_id` bigint NOT NULL COMMENT 'AI 질문 Template ID',
  `option_key` varchar(80) NOT NULL COMMENT 'API 선택지 식별자',
  `option_type` varchar(30) NOT NULL COMMENT '선택지 유형',
  `option_value` varchar(255) NOT NULL COMMENT '선택지 값',
  `label` varchar(200) NOT NULL COMMENT '표시 문구',
  `emoji` varchar(20) DEFAULT NULL COMMENT '표시 Emoji',
  `display_order` smallint NOT NULL DEFAULT '0' COMMENT '노출 순서',
  PRIMARY KEY (`id`),
  UNIQUE KEY `uk_ai_question_template_options_template_key` (`question_template_id`,`option_key`),
  UNIQUE KEY `uk_ai_question_template_options_template_order` (`question_template_id`,`display_order`),
  CONSTRAINT `fk_ai_question_template_options_template_id` FOREIGN KEY (`question_template_id`) REFERENCES `ai_question_templates` (`id`) ON DELETE CASCADE,
  CONSTRAINT `ck_ai_question_template_options_order` CHECK ((`display_order` >= 0))
) ENGINE=InnoDB AUTO_INCREMENT=4 DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci COMMENT='AI 질문 Template 선택지';

CREATE TABLE `ai_question_template_risk_responses` (
  `question_template_id` bigint NOT NULL COMMENT 'AI 질문 Template ID',
  `is_enabled` tinyint(1) NOT NULL DEFAULT '0' COMMENT '위험 응답 안내 활성 여부',
  `guardian_guide_template` text COMMENT '보호자 안내 Template',
  `updated_at` datetime(6) NOT NULL DEFAULT CURRENT_TIMESTAMP(6) ON UPDATE CURRENT_TIMESTAMP(6) COMMENT '수정 일시',
  PRIMARY KEY (`question_template_id`),
  CONSTRAINT `fk_ai_question_template_risk_responses_template_id` FOREIGN KEY (`question_template_id`) REFERENCES `ai_question_templates` (`id`) ON DELETE CASCADE,
  CONSTRAINT `ck_ai_question_template_risk_responses_guide` CHECK (((`is_enabled` = false) or (`guardian_guide_template` is not null)))
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci COMMENT='AI 질문 Template 위험 응답 안내';

CREATE TABLE `ai_question_templates` (
  `id` bigint NOT NULL AUTO_INCREMENT COMMENT 'AI 질문 Template ID',
  `drawing_type_id` bigint DEFAULT NULL COMMENT '그림 활동 유형 ID',
  `created_by_user_id` bigint DEFAULT NULL COMMENT '생성자 사용자 ID',
  `updated_by_user_id` bigint DEFAULT NULL COMMENT '수정자 사용자 ID',
  `template_type` varchar(20) NOT NULL COMMENT 'Template 유형',
  `age_group` varchar(30) NOT NULL COMMENT '연령 그룹',
  `difficulty` varchar(30) NOT NULL COMMENT '질문 난이도',
  `question_purpose` varchar(50) NOT NULL COMMENT '질문 목적',
  `question_text` text NOT NULL COMMENT '질문 내용',
  `is_active` tinyint(1) NOT NULL DEFAULT '1' COMMENT '활성 여부',
  `created_at` datetime(6) NOT NULL DEFAULT CURRENT_TIMESTAMP(6) COMMENT '생성 일시',
  `updated_at` datetime(6) NOT NULL DEFAULT CURRENT_TIMESTAMP(6) ON UPDATE CURRENT_TIMESTAMP(6) COMMENT '수정 일시',
  PRIMARY KEY (`id`),
  KEY `fk_ai_question_templates_created_by_id` (`created_by_user_id`),
  KEY `fk_ai_question_templates_updated_by_id` (`updated_by_user_id`),
  KEY `idx_ai_question_templates_lookup` (`drawing_type_id`,`age_group`,`difficulty`,`is_active`),
  CONSTRAINT `fk_ai_question_templates_created_by_id` FOREIGN KEY (`created_by_user_id`) REFERENCES `users` (`id`) ON DELETE SET NULL,
  CONSTRAINT `fk_ai_question_templates_drawing_type_id` FOREIGN KEY (`drawing_type_id`) REFERENCES `drawing_types` (`id`) ON DELETE SET NULL,
  CONSTRAINT `fk_ai_question_templates_updated_by_id` FOREIGN KEY (`updated_by_user_id`) REFERENCES `users` (`id`) ON DELETE SET NULL
) ENGINE=InnoDB AUTO_INCREMENT=2 DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci COMMENT='AI 질문 Template';

CREATE TABLE `analyses` (
  `id` bigint NOT NULL AUTO_INCREMENT COMMENT '분석 ID',
  `drawing_session_id` bigint NOT NULL COMMENT '그림 활동 세션 ID',
  `drawing_asset_id` bigint DEFAULT NULL COMMENT '분석 대상 그림 파일 ID',
  `retry_of_analysis_id` bigint DEFAULT NULL COMMENT '재시도 원본 분석 ID',
  `analysis_type` varchar(20) NOT NULL COMMENT '분석 유형',
  `analysis_task_type` varchar(30) DEFAULT NULL COMMENT 'AI 분석 작업 유형',
  `idempotency_key` varchar(100) NOT NULL COMMENT 'Idempotency Key',
  `input_checksum_sha256` char(64) DEFAULT NULL COMMENT '입력 SHA-256 Checksum',
  `analysis_status` varchar(20) NOT NULL DEFAULT 'PENDING' COMMENT '분석 상태',
  `trigger_reason` varchar(30) DEFAULT NULL COMMENT '분석 실행 사유',
  `model_name` varchar(100) DEFAULT NULL COMMENT 'Model 이름',
  `model_version` varchar(255) DEFAULT NULL COMMENT 'Model 버전',
  `confidence` decimal(5,4) DEFAULT NULL COMMENT '신뢰도',
  `error_code` varchar(80) DEFAULT NULL COMMENT '오류 코드',
  `error_message` text COMMENT '오류 메시지',
  `requested_at` datetime(6) NOT NULL DEFAULT CURRENT_TIMESTAMP(6) COMMENT '요청 일시',
  `started_at` datetime(6) DEFAULT NULL COMMENT '시작 일시',
  `completed_at` datetime(6) DEFAULT NULL COMMENT '분석 완료 일시',
  `created_at` datetime(6) NOT NULL DEFAULT CURRENT_TIMESTAMP(6) COMMENT '생성 일시',
  `active_drawing_asset_id` bigint GENERATED ALWAYS AS ((case when (`analysis_status` in (_utf8mb4'PROCESSING',_utf8mb4'SUCCESS',_utf8mb4'PARTIAL_SUCCESS')) then `drawing_asset_id` else NULL end)) VIRTUAL COMMENT '진행·완료 분석 중복 방지용 생성값',
  PRIMARY KEY (`id`),
  UNIQUE KEY `uk_analyses_idempotency_key` (`idempotency_key`),
  UNIQUE KEY `uk_analyses_active_asset_task` (`active_drawing_asset_id`,`analysis_task_type`),
  KEY `fk_analyses_retry_of_analysis_id` (`retry_of_analysis_id`),
  KEY `idx_analyses_drawing_session_id` (`drawing_session_id`,`requested_at`),
  KEY `idx_analyses_asset_task_status` (`drawing_asset_id`,`analysis_task_type`,`analysis_status`),
  CONSTRAINT `fk_analyses_drawing_asset_id` FOREIGN KEY (`drawing_asset_id`) REFERENCES `drawing_assets` (`id`) ON DELETE CASCADE,
  CONSTRAINT `fk_analyses_drawing_session_id` FOREIGN KEY (`drawing_session_id`) REFERENCES `drawing_sessions` (`id`) ON DELETE CASCADE,
  CONSTRAINT `fk_analyses_retry_of_analysis_id` FOREIGN KEY (`retry_of_analysis_id`) REFERENCES `analyses` (`id`) ON DELETE SET NULL,
  CONSTRAINT `ck_analyses_confidence` CHECK (((`confidence` is null) or ((`confidence` >= 0) and (`confidence` <= 1)))),
  CONSTRAINT `ck_analyses_status` CHECK ((`analysis_status` in (_utf8mb4'PENDING',_utf8mb4'PROCESSING',_utf8mb4'PARTIAL_SUCCESS',_utf8mb4'SUCCESS',_utf8mb4'FAILED'))),
  CONSTRAINT `ck_analyses_task_type` CHECK (((`analysis_task_type` is null) or (`analysis_task_type` in (_utf8mb4'OBJECT_DETECTION',_utf8mb4'ACTIVITY_REPORT')))),
  CONSTRAINT `ck_analyses_trigger_reason` CHECK (((`trigger_reason` is null) or (`trigger_reason` in (_utf8mb4'PAUSE',_utf8mb4'INTERVAL',_utf8mb4'STROKE_COUNT',_utf8mb4'CHANGE_RATIO',_utf8mb4'USER_REQUEST',_utf8mb4'DRAWING_COMPLETE',_utf8mb4'ACTIVITY_COMPLETE',_utf8mb4'RETRY')))),
  CONSTRAINT `ck_analyses_type` CHECK ((`analysis_type` in (_utf8mb4'INTERMEDIATE',_utf8mb4'FINAL')))
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci COMMENT='분석';

CREATE TABLE `analysis_detected_objects` (
  `detected_object_id` bigint NOT NULL AUTO_INCREMENT COMMENT '탐지 객체 ID',
  `analysis_id` bigint NOT NULL COMMENT '분석 ID',
  `drawing_asset_id` bigint NOT NULL COMMENT '그림 파일 ID',
  `object_code` varchar(50) DEFAULT NULL COMMENT '객체 코드',
  `object_name` varchar(100) DEFAULT NULL COMMENT '객체명',
  `confidence_score` decimal(5,4) DEFAULT NULL COMMENT '신뢰도 점수',
  `bbox_x` decimal(12,6) DEFAULT NULL COMMENT 'Bounding Box X 좌표',
  `bbox_y` decimal(12,6) DEFAULT NULL COMMENT 'Bounding Box Y 좌표',
  `bbox_width` decimal(12,6) DEFAULT NULL COMMENT 'Bounding Box 너비',
  `bbox_height` decimal(12,6) DEFAULT NULL COMMENT 'Bounding Box 높이',
  `area_ratio` decimal(8,6) DEFAULT NULL COMMENT '면적 비율',
  `coordinate_space` varchar(20) NOT NULL DEFAULT 'PIXEL' COMMENT 'Bounding Box 좌표계',
  `detection_order` int DEFAULT NULL COMMENT '탐지 순서',
  `model_version` varchar(50) DEFAULT NULL COMMENT 'Model 버전',
  `created_at` datetime(6) NOT NULL DEFAULT CURRENT_TIMESTAMP(6) COMMENT '생성 일시',
  PRIMARY KEY (`detected_object_id`),
  KEY `idx_analysis_detected_objects_analysis_id` (`analysis_id`),
  KEY `idx_analysis_detected_objects_drawing_asset_id` (`drawing_asset_id`),
  CONSTRAINT `fk_analysis_detected_objects_analysis_id` FOREIGN KEY (`analysis_id`) REFERENCES `analyses` (`id`) ON DELETE CASCADE,
  CONSTRAINT `fk_analysis_detected_objects_drawing_asset_id` FOREIGN KEY (`drawing_asset_id`) REFERENCES `drawing_assets` (`id`) ON DELETE CASCADE,
  CONSTRAINT `ck_analysis_detected_objects_bbox_coordinate` CHECK ((((`bbox_x` is null) or (`bbox_x` >= 0)) and ((`bbox_y` is null) or (`bbox_y` >= 0)) and ((`bbox_width` is null) or (`bbox_width` > 0)) and ((`bbox_height` is null) or (`bbox_height` > 0)) and ((`coordinate_space` = _utf8mb4'PIXEL') or (((`bbox_x` is null) or (`bbox_x` <= 1)) and ((`bbox_y` is null) or (`bbox_y` <= 1)) and ((`bbox_width` is null) or (`bbox_width` <= 1)) and ((`bbox_height` is null) or (`bbox_height` <= 1)) and ((`bbox_x` is null) or (`bbox_width` is null) or ((`bbox_x` + `bbox_width`) <= 1)) and ((`bbox_y` is null) or (`bbox_height` is null) or ((`bbox_y` + `bbox_height`) <= 1)))))),
  CONSTRAINT `ck_analysis_detected_objects_confidence` CHECK (((`confidence_score` is null) or ((`confidence_score` >= 0) and (`confidence_score` <= 1)))),
  CONSTRAINT `ck_analysis_detected_objects_coordinate_space` CHECK ((`coordinate_space` in (_utf8mb4'PIXEL',_utf8mb4'NORMALIZED'))),
  CONSTRAINT `ck_analysis_detected_objects_order` CHECK (((`detection_order` is null) or (`detection_order` >= 0)))
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci COMMENT='분석 탐지 객체';

CREATE TABLE `audit_log_changes` (
  `id` bigint NOT NULL AUTO_INCREMENT COMMENT '감사 로그 변경 항목 ID',
  `audit_log_id` bigint NOT NULL COMMENT '감사 로그 ID',
  `field_path` varchar(255) NOT NULL COMMENT '변경 필드 경로',
  `value_type` varchar(20) NOT NULL DEFAULT 'STRING' COMMENT '값 유형',
  `snapshot_value` text COMMENT '대상 Snapshot 값',
  `before_value` text COMMENT '변경 전 값',
  `after_value` text COMMENT '변경 후 값',
  `is_masked` tinyint(1) NOT NULL DEFAULT '0' COMMENT '민감값 마스킹 여부',
  `created_at` datetime(6) NOT NULL DEFAULT CURRENT_TIMESTAMP(6) COMMENT '생성 일시',
  PRIMARY KEY (`id`),
  UNIQUE KEY `uk_audit_log_changes_log_field` (`audit_log_id`,`field_path`),
  CONSTRAINT `fk_audit_log_changes_audit_log_id` FOREIGN KEY (`audit_log_id`) REFERENCES `audit_logs` (`id`) ON DELETE CASCADE,
  CONSTRAINT `ck_audit_log_changes_type` CHECK ((`value_type` in (_utf8mb4'STRING',_utf8mb4'NUMBER',_utf8mb4'BOOLEAN',_utf8mb4'DATE',_utf8mb4'DATETIME',_utf8mb4'NULL')))
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci COMMENT='감사 로그 변경 항목';

CREATE TABLE `audit_logs` (
  `id` bigint NOT NULL AUTO_INCREMENT COMMENT '감사 로그 ID',
  `actor_user_id` bigint DEFAULT NULL COMMENT '처리 사용자 ID',
  `action_type` varchar(80) NOT NULL COMMENT '행위 유형',
  `resource_type` varchar(50) NOT NULL COMMENT '대상 Resource 유형',
  `resource_id` bigint DEFAULT NULL COMMENT '대상 Resource ID',
  `ip_address` varchar(45) DEFAULT NULL COMMENT 'IP 주소',
  `created_at` datetime(6) NOT NULL DEFAULT CURRENT_TIMESTAMP(6) COMMENT '생성 일시',
  PRIMARY KEY (`id`),
  KEY `idx_audit_logs_resource` (`resource_type`,`resource_id`,`created_at`),
  KEY `idx_audit_logs_actor_user_id` (`actor_user_id`,`created_at`),
  CONSTRAINT `fk_audit_logs_actor_user_id` FOREIGN KEY (`actor_user_id`) REFERENCES `users` (`id`) ON DELETE SET NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci COMMENT='감사 로그';

CREATE TABLE `auth_accounts` (
  `id` bigint NOT NULL AUTO_INCREMENT COMMENT '인증 계정 ID',
  `user_id` bigint NOT NULL COMMENT '사용자 ID',
  `provider` varchar(20) NOT NULL COMMENT '인증 제공자',
  `provider_subject` varchar(255) NOT NULL COMMENT '인증 제공자 사용자 식별자',
  `provider_email` varchar(255) DEFAULT NULL COMMENT '로그인 이메일',
  `provider_email_verified_at` datetime(6) DEFAULT NULL COMMENT '이메일 인증 일시',
  `created_at` datetime(6) NOT NULL DEFAULT CURRENT_TIMESTAMP(6) COMMENT '생성 일시',
  `updated_at` datetime(6) NOT NULL DEFAULT CURRENT_TIMESTAMP(6) ON UPDATE CURRENT_TIMESTAMP(6) COMMENT '수정 일시',
  PRIMARY KEY (`id`),
  UNIQUE KEY `uk_auth_accounts_provider_subject` (`provider`,`provider_subject`),
  KEY `fk_auth_accounts_user_id` (`user_id`),
  CONSTRAINT `fk_auth_accounts_user_id` FOREIGN KEY (`user_id`) REFERENCES `users` (`id`) ON DELETE CASCADE,
  CONSTRAINT `ck_auth_accounts_provider` CHECK ((`provider` in (_utf8mb4'KAKAO',_utf8mb4'GOOGLE',_utf8mb4'NAVER',_utf8mb4'APPLE')))
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci COMMENT='인증 계정';

CREATE TABLE `child_profile_image_files` (
  `id` bigint NOT NULL AUTO_INCREMENT COMMENT '아동 프로필 이미지 내부 ID',
  `file_id` char(36) NOT NULL COMMENT 'API 공개 파일 UUID',
  `uploaded_by_user_id` bigint NOT NULL COMMENT '업로드 사용자 ID',
  `storage_key` varchar(1000) NOT NULL COMMENT '이미지 Storage Key',
  `content_type` varchar(100) NOT NULL COMMENT '검증된 MIME Type',
  `file_size_bytes` bigint NOT NULL COMMENT '파일 크기(Byte)',
  `width_px` int NOT NULL COMMENT '이미지 너비(px)',
  `height_px` int NOT NULL COMMENT '이미지 높이(px)',
  `checksum_sha256` char(64) NOT NULL COMMENT '이미지 Byte SHA-256',
  `status` varchar(20) NOT NULL DEFAULT 'TEMP' COMMENT 'TEMP 또는 ATTACHED',
  `child_id` bigint DEFAULT NULL COMMENT '연결된 아동 ID',
  `expires_at` datetime(6) NOT NULL COMMENT 'TEMP 파일 만료 시각',
  `attached_at` datetime(6) DEFAULT NULL COMMENT '아동 연결 시각',
  `created_at` datetime(6) NOT NULL DEFAULT CURRENT_TIMESTAMP(6) COMMENT '업로드 시각',
  PRIMARY KEY (`id`),
  UNIQUE KEY `uk_child_profile_image_files_file_id` (`file_id`),
  UNIQUE KEY `uk_child_profile_image_files_child_id` (`child_id`),
  KEY `idx_child_profile_image_files_owner_status` (`uploaded_by_user_id`,`status`,`expires_at`),
  KEY `idx_child_profile_image_files_expiry` (`status`,`expires_at`),
  CONSTRAINT `fk_child_profile_image_files_child_id` FOREIGN KEY (`child_id`) REFERENCES `children` (`id`) ON DELETE SET NULL,
  CONSTRAINT `fk_child_profile_image_files_user_id` FOREIGN KEY (`uploaded_by_user_id`) REFERENCES `users` (`id`) ON DELETE RESTRICT,
  CONSTRAINT `ck_child_profile_image_files_dimensions` CHECK (((`width_px` > 0) and (`height_px` > 0))),
  CONSTRAINT `ck_child_profile_image_files_size` CHECK (((`file_size_bytes` > 0) and (`file_size_bytes` <= 5242880))),
  CONSTRAINT `ck_child_profile_image_files_status` CHECK ((`status` in (_utf8mb4'TEMP',_utf8mb4'ATTACHED')))
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci COMMENT='아동 프로필 이미지 파일';

CREATE TABLE `child_response_modes` (
  `id` bigint NOT NULL AUTO_INCREMENT COMMENT '아동 응답 방식 ID',
  `child_id` bigint NOT NULL COMMENT '아동 ID',
  `response_mode` varchar(20) NOT NULL COMMENT '응답 방식',
  `display_order` smallint NOT NULL DEFAULT '0' COMMENT '노출 순서',
  `created_at` datetime(6) NOT NULL DEFAULT CURRENT_TIMESTAMP(6) COMMENT '생성 일시',
  PRIMARY KEY (`id`),
  UNIQUE KEY `uk_child_response_modes_child_mode` (`child_id`,`response_mode`),
  UNIQUE KEY `uk_child_response_modes_child_order` (`child_id`,`display_order`),
  CONSTRAINT `fk_child_response_modes_child_id` FOREIGN KEY (`child_id`) REFERENCES `children` (`id`) ON DELETE CASCADE,
  CONSTRAINT `ck_child_response_modes_mode` CHECK ((`response_mode` in (_utf8mb4'VOICE',_utf8mb4'EMOJI',_utf8mb4'COLOR',_utf8mb4'PICTURE',_utf8mb4'TEXT'))),
  CONSTRAINT `ck_child_response_modes_order` CHECK ((`display_order` >= 0))
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci COMMENT='아동 응답 방식';

CREATE TABLE `child_screening_record_domains` (
  `id` bigint NOT NULL AUTO_INCREMENT COMMENT '영역 결과 ID',
  `screening_record_id` bigint NOT NULL COMMENT '선별 결과 기록 ID',
  `domain_name` varchar(60) NOT NULL COMMENT '영역 이름을 공식 결과지 그대로',
  `result_label` varchar(120) NOT NULL COMMENT '영역 결과 라벨을 공식 결과지 그대로',
  `display_order` smallint NOT NULL DEFAULT '0' COMMENT '노출 순서',
  PRIMARY KEY (`id`),
  UNIQUE KEY `uk_child_screening_record_domains_slot` (`screening_record_id`,`display_order`),
  CONSTRAINT `fk_child_screening_record_domains_record_id` FOREIGN KEY (`screening_record_id`) REFERENCES `child_screening_records` (`id`) ON DELETE CASCADE,
  CONSTRAINT `ck_child_screening_record_domains_order` CHECK ((`display_order` >= 0))
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci COMMENT='선별 결과의 영역별 라벨';

CREATE TABLE `child_screening_records` (
  `id` bigint NOT NULL AUTO_INCREMENT COMMENT '선별 결과 기록 ID',
  `child_id` bigint NOT NULL COMMENT '아동 ID',
  `instrument_id` varchar(40) NOT NULL COMMENT '등록부 allow-list 안의 도구 식별자',
  `instrument_version` varchar(60) DEFAULT NULL COMMENT '보호자가 적은 도구 버전',
  `respondent` varchar(20) NOT NULL COMMENT 'GUARDIAN·TEACHER·CHILD',
  `completed_at` date NOT NULL COMMENT '검사 실시일',
  `child_age_months_at_administration` smallint DEFAULT NULL COMMENT '실시 당시 아동 개월 나이',
  `source_authority_type` varchar(30) NOT NULL COMMENT 'OFFICIAL_SERVICE·GUARDIAN_REPORTED·CLINICIAN_REPORTED',
  `source_authority_name` varchar(150) NOT NULL COMMENT '결과를 발급한 곳',
  `source_verified` tinyint(1) NOT NULL DEFAULT '0' COMMENT '출처 검증 여부. 공식 연동이 없어 현재 항상 FALSE',
  `verification_method` varchar(150) DEFAULT NULL COMMENT '검증 방법이며 미검증이면 NULL',
  `official_result_code` varchar(60) DEFAULT NULL COMMENT '공식 결과 코드를 그대로',
  `official_result_text` varchar(500) NOT NULL COMMENT '공식 결과 문구를 변경 없이',
  `diagnostic_status` varchar(30) NOT NULL DEFAULT 'SCREENING_NOT_DIAGNOSIS' COMMENT '선별은 진단이 아니라는 고정 표기',
  `scored_by` varchar(30) NOT NULL COMMENT '채점 주체. 이 서비스는 절대 채점하지 않는다',
  `ai_recalculated` tinyint(1) NOT NULL DEFAULT '0' COMMENT 'AI 재계산 여부. 항상 FALSE',
  `followup_level` varchar(40) DEFAULT NULL COMMENT 'NONE·DISCUSS_WITH_GUARDIAN·SCHEDULE_FURTHER_EVALUATION',
  `followup_message` varchar(500) DEFAULT NULL COMMENT '보호자에게 보이는 후속 안내',
  `consent_record_id` bigint NOT NULL COMMENT '이 기록을 남길 때 확인한 동의 이력 ID',
  `source_document_ref` varchar(300) DEFAULT NULL COMMENT '원본 문서 참조',
  `payload_hash` char(64) NOT NULL COMMENT '등록 당시 요청 본문의 SHA-256',
  `created_at` datetime(6) NOT NULL DEFAULT CURRENT_TIMESTAMP(6) COMMENT '등록 일시',
  `deleted_at` datetime(6) DEFAULT NULL COMMENT '보호자 삭제 일시. 삭제권 행사 시각을 남긴다',
  PRIMARY KEY (`id`),
  KEY `fk_child_screening_records_consent_record_id` (`consent_record_id`),
  KEY `idx_child_screening_records_child` (`child_id`,`deleted_at`,`completed_at`),
  CONSTRAINT `fk_child_screening_records_child_id` FOREIGN KEY (`child_id`) REFERENCES `children` (`id`) ON DELETE CASCADE,
  CONSTRAINT `fk_child_screening_records_consent_record_id` FOREIGN KEY (`consent_record_id`) REFERENCES `consent_records` (`id`),
  CONSTRAINT `ck_child_screening_records_not_scored_here` CHECK ((`ai_recalculated` = false))
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci COMMENT='보호자가 입력한 표준화 선별 결과';

CREATE TABLE `child_screening_referral_options` (
  `id` bigint NOT NULL AUTO_INCREMENT COMMENT '후속 경로 ID',
  `screening_record_id` bigint NOT NULL COMMENT '선별 결과 기록 ID',
  `referral_option` varchar(120) NOT NULL COMMENT '소아청소년과·발달클리닉 등',
  `display_order` smallint NOT NULL DEFAULT '0' COMMENT '노출 순서',
  PRIMARY KEY (`id`),
  UNIQUE KEY `uk_child_screening_referral_options_slot` (`screening_record_id`,`display_order`),
  CONSTRAINT `fk_child_screening_referral_options_record_id` FOREIGN KEY (`screening_record_id`) REFERENCES `child_screening_records` (`id`) ON DELETE CASCADE,
  CONSTRAINT `ck_child_screening_referral_options_order` CHECK ((`display_order` >= 0))
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci COMMENT='선별 결과의 후속 상담 경로';

CREATE TABLE `children` (
  `id` bigint NOT NULL AUTO_INCREMENT COMMENT '아동 ID',
  `nickname` varchar(50) NOT NULL COMMENT '닉네임',
  `birth_date` date NOT NULL COMMENT '생년월일',
  `profile_image_url` varchar(1000) DEFAULT NULL COMMENT '프로필 이미지 URL',
  `preferred_character` varchar(50) DEFAULT NULL COMMENT '선호 캐릭터',
  `question_difficulty` varchar(30) NOT NULL DEFAULT 'PRESCHOOL' COMMENT '질문 난이도',
  `education_stage` varchar(20) DEFAULT NULL COMMENT '다니는 곳(PRESCHOOL·KINDERGARTEN·GRADE_1). NULL 은 미입력',
  `tutorial_status` varchar(20) NOT NULL DEFAULT 'NOT_STARTED' COMMENT '튜토리얼 상태',
  `tutorial_last_step` varchar(50) DEFAULT NULL COMMENT 'Tutorial 마지막 진행 단계',
  `tutorial_completed_at` datetime(6) DEFAULT NULL COMMENT 'Tutorial 완료 또는 건너뛰기 일시',
  `profile_status` varchar(20) NOT NULL DEFAULT 'ACTIVE' COMMENT '프로필 상태',
  `created_at` datetime(6) NOT NULL DEFAULT CURRENT_TIMESTAMP(6) COMMENT '생성 일시',
  `updated_at` datetime(6) NOT NULL DEFAULT CURRENT_TIMESTAMP(6) ON UPDATE CURRENT_TIMESTAMP(6) COMMENT '수정 일시',
  `deleted_at` datetime(6) DEFAULT NULL COMMENT '삭제 일시',
  PRIMARY KEY (`id`),
  CONSTRAINT `ck_children_education_stage` CHECK (((`education_stage` is null) or (`education_stage` in (_utf8mb4'PRESCHOOL',_utf8mb4'KINDERGARTEN',_utf8mb4'GRADE_1')))),
  CONSTRAINT `ck_children_preferred_character` CHECK (((`preferred_character` is null) or (`preferred_character` in (_utf8mb4'BASE',_utf8mb4'PRINCESS',_utf8mb4'DINO',_utf8mb4'OCTOPUS',_utf8mb4'EXPLORER',_utf8mb4'RIBBON',_utf8mb4'PRINCE')))),
  CONSTRAINT `ck_children_profile_status` CHECK ((`profile_status` in (_utf8mb4'ACTIVE',_utf8mb4'DELETED'))),
  CONSTRAINT `ck_children_question_difficulty` CHECK ((`question_difficulty` in (_utf8mb4'PRESCHOOL',_utf8mb4'LOWER_ELEMENTARY',_utf8mb4'UPPER_ELEMENTARY',_utf8mb4'SUPPORT'))),
  CONSTRAINT `ck_children_tutorial_status` CHECK ((`tutorial_status` in (_utf8mb4'NOT_STARTED',_utf8mb4'IN_PROGRESS',_utf8mb4'COMPLETED',_utf8mb4'SKIPPED')))
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci COMMENT='아동';

CREATE TABLE `comments` (
  `id` bigint NOT NULL AUTO_INCREMENT COMMENT '댓글 ID',
  `post_id` bigint NOT NULL COMMENT '게시글 ID',
  `author_user_id` bigint DEFAULT NULL COMMENT '작성자 사용자 ID',
  `content` text NOT NULL COMMENT '댓글 내용',
  `is_anonymous` tinyint(1) NOT NULL DEFAULT '0' COMMENT '익명 여부',
  `is_visible` tinyint(1) NOT NULL DEFAULT '1' COMMENT '공개 여부',
  `comment_status` varchar(20) NOT NULL DEFAULT 'ACTIVE' COMMENT '댓글 상태',
  `created_at` datetime(6) NOT NULL DEFAULT CURRENT_TIMESTAMP(6) COMMENT '생성 일시',
  `updated_at` datetime(6) NOT NULL DEFAULT CURRENT_TIMESTAMP(6) ON UPDATE CURRENT_TIMESTAMP(6) COMMENT '수정 일시',
  `deleted_at` datetime(6) DEFAULT NULL COMMENT '삭제 일시',
  PRIMARY KEY (`id`),
  KEY `idx_comments_author_user_id` (`author_user_id`),
  KEY `idx_comments_post_created_at` (`post_id`,`created_at`),
  CONSTRAINT `fk_comments_author_user_id` FOREIGN KEY (`author_user_id`) REFERENCES `users` (`id`) ON DELETE SET NULL,
  CONSTRAINT `fk_comments_post_id` FOREIGN KEY (`post_id`) REFERENCES `community_posts` (`id`) ON DELETE CASCADE,
  CONSTRAINT `ck_comments_status` CHECK ((`comment_status` in (_utf8mb4'ACTIVE',_utf8mb4'HIDDEN',_utf8mb4'DELETED')))
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci COMMENT='댓글';

CREATE TABLE `community_attachment_files` (
  `id` bigint NOT NULL AUTO_INCREMENT COMMENT '커뮤니티 첨부 파일 내부 ID',
  `file_id` char(36) NOT NULL COMMENT 'API 공개 파일 UUID',
  `uploaded_by_user_id` bigint NOT NULL COMMENT '업로드 사용자 ID',
  `storage_key` varchar(1000) NOT NULL COMMENT '이미지 Storage Key',
  `content_type` varchar(100) NOT NULL COMMENT '검증된 MIME Type',
  `file_size_bytes` bigint NOT NULL COMMENT '파일 크기(Byte)',
  `width_px` int NOT NULL COMMENT '이미지 너비(px)',
  `height_px` int NOT NULL COMMENT '이미지 높이(px)',
  `checksum_sha256` char(64) NOT NULL COMMENT '이미지 Byte SHA-256',
  `status` varchar(20) NOT NULL DEFAULT 'TEMP' COMMENT 'TEMP 또는 ATTACHED',
  `post_id` bigint DEFAULT NULL COMMENT '연결된 커뮤니티 게시글 ID',
  `display_order` int DEFAULT NULL COMMENT '게시글 내 노출 순서',
  `expires_at` datetime(6) NOT NULL COMMENT 'TEMP 파일 만료 시각',
  `attached_at` datetime(6) DEFAULT NULL COMMENT '게시글 연결 시각',
  `created_at` datetime(6) NOT NULL DEFAULT CURRENT_TIMESTAMP(6) COMMENT '업로드 시각',
  PRIMARY KEY (`id`),
  UNIQUE KEY `uk_community_attachment_files_file_id` (`file_id`),
  KEY `idx_community_attachment_files_owner_status` (`uploaded_by_user_id`,`status`,`expires_at`),
  KEY `idx_community_attachment_files_post_order` (`post_id`,`display_order`),
  KEY `idx_community_attachment_files_expiry` (`status`,`expires_at`),
  CONSTRAINT `fk_community_attachment_files_post_id` FOREIGN KEY (`post_id`) REFERENCES `community_posts` (`id`) ON DELETE CASCADE,
  CONSTRAINT `fk_community_attachment_files_user_id` FOREIGN KEY (`uploaded_by_user_id`) REFERENCES `users` (`id`) ON DELETE RESTRICT,
  CONSTRAINT `ck_community_attachment_files_dimensions` CHECK (((`width_px` > 0) and (`height_px` > 0))),
  CONSTRAINT `ck_community_attachment_files_order` CHECK (((`display_order` is null) or ((`display_order` >= 0) and (`display_order` < 5)))),
  CONSTRAINT `ck_community_attachment_files_size` CHECK (((`file_size_bytes` > 0) and (`file_size_bytes` <= 5242880))),
  CONSTRAINT `ck_community_attachment_files_status` CHECK ((`status` in (_utf8mb4'TEMP',_utf8mb4'ATTACHED'))),
  CONSTRAINT `ck_community_attachment_files_status_fields` CHECK ((((`status` = _utf8mb4'TEMP') and (`post_id` is null) and (`display_order` is null) and (`attached_at` is null)) or ((`status` = _utf8mb4'ATTACHED') and (`post_id` is not null) and (`display_order` is not null) and (`attached_at` is not null))))
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci COMMENT='커뮤니티 게시글 첨부 이미지 파일';

CREATE TABLE `community_post_template_fields` (
  `id` bigint NOT NULL AUTO_INCREMENT COMMENT '커뮤니티 Template 항목 ID',
  `community_post_id` bigint NOT NULL COMMENT '게시글 ID',
  `field_code` varchar(80) NOT NULL COMMENT 'Template 항목 코드',
  `value_type` varchar(20) NOT NULL DEFAULT 'STRING' COMMENT '값 유형',
  `value_text` text NOT NULL COMMENT 'Template 항목 값',
  `display_order` smallint NOT NULL DEFAULT '0' COMMENT '노출 순서',
  PRIMARY KEY (`id`),
  UNIQUE KEY `uk_community_post_template_fields_post_code` (`community_post_id`,`field_code`),
  UNIQUE KEY `uk_community_post_template_fields_post_order` (`community_post_id`,`display_order`),
  CONSTRAINT `fk_community_post_template_fields_post_id` FOREIGN KEY (`community_post_id`) REFERENCES `community_posts` (`id`) ON DELETE CASCADE,
  CONSTRAINT `ck_community_post_template_fields_order` CHECK ((`display_order` >= 0)),
  CONSTRAINT `ck_community_post_template_fields_type` CHECK ((`value_type` in (_utf8mb4'STRING',_utf8mb4'NUMBER',_utf8mb4'BOOLEAN',_utf8mb4'DATE')))
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci COMMENT='커뮤니티 게시글 Template 항목';

CREATE TABLE `community_posts` (
  `id` bigint NOT NULL AUTO_INCREMENT COMMENT '게시글 ID',
  `author_user_id` bigint DEFAULT NULL COMMENT '작성자 사용자 ID',
  `post_type` varchar(40) NOT NULL COMMENT '게시글 유형',
  `title` varchar(200) NOT NULL COMMENT '게시글 제목',
  `content` longtext NOT NULL COMMENT '게시글 내용',
  `is_anonymous` tinyint(1) NOT NULL DEFAULT '0' COMMENT '익명 여부',
  `is_visible` tinyint(1) NOT NULL DEFAULT '1' COMMENT '공개 여부',
  `post_status` varchar(20) NOT NULL DEFAULT 'ACTIVE' COMMENT '게시글 상태',
  `created_at` datetime(6) NOT NULL DEFAULT CURRENT_TIMESTAMP(6) COMMENT '생성 일시',
  `updated_at` datetime(6) NOT NULL DEFAULT CURRENT_TIMESTAMP(6) ON UPDATE CURRENT_TIMESTAMP(6) COMMENT '수정 일시',
  `deleted_at` datetime(6) DEFAULT NULL COMMENT '삭제 일시',
  PRIMARY KEY (`id`),
  KEY `idx_community_posts_author_created_at` (`author_user_id`,`created_at`),
  CONSTRAINT `fk_community_posts_author_user_id` FOREIGN KEY (`author_user_id`) REFERENCES `users` (`id`) ON DELETE SET NULL,
  CONSTRAINT `ck_community_posts_status` CHECK ((`post_status` in (_utf8mb4'ACTIVE',_utf8mb4'HIDDEN',_utf8mb4'DELETED'))),
  CONSTRAINT `ck_community_posts_type` CHECK ((`post_type` in (_utf8mb4'GUARDIAN_STORY',_utf8mb4'ACTIVITY_REVIEW',_utf8mb4'EXPERT_COLUMN',_utf8mb4'ART_RESOURCE',_utf8mb4'DRAWING_GUIDE',_utf8mb4'EXPERT_QNA',_utf8mb4'NOTICE')))
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci COMMENT='커뮤니티 게시글';

CREATE TABLE `complaint_actions` (
  `id` bigint NOT NULL AUTO_INCREMENT COMMENT '신고 처리 이력 ID',
  `complaint_id` bigint NOT NULL COMMENT '신고 ID',
  `actor_user_id` bigint DEFAULT NULL COMMENT '처리 관리자 사용자 ID',
  `action_type` varchar(30) NOT NULL COMMENT '처리 유형',
  `previous_status` varchar(20) NOT NULL COMMENT '처리 전 상태',
  `next_status` varchar(20) NOT NULL COMMENT '처리 후 상태',
  `resolution_note` text COMMENT '처리 메모',
  `notify_reporter` tinyint(1) NOT NULL DEFAULT '0' COMMENT '신고자 알림 여부',
  `notify_target_author` tinyint(1) NOT NULL DEFAULT '0' COMMENT '대상 작성자 알림 여부',
  `created_at` datetime(6) NOT NULL DEFAULT CURRENT_TIMESTAMP(6) COMMENT '생성 일시',
  PRIMARY KEY (`id`),
  KEY `fk_complaint_actions_actor_user_id` (`actor_user_id`),
  KEY `idx_complaint_actions_complaint_created_at` (`complaint_id`,`created_at`),
  CONSTRAINT `fk_complaint_actions_actor_user_id` FOREIGN KEY (`actor_user_id`) REFERENCES `users` (`id`) ON DELETE SET NULL,
  CONSTRAINT `fk_complaint_actions_complaint_id` FOREIGN KEY (`complaint_id`) REFERENCES `complaints` (`id`) ON DELETE CASCADE,
  CONSTRAINT `ck_complaint_actions_type` CHECK ((`action_type` in (_utf8mb4'NO_ACTION',_utf8mb4'HIDE_CONTENT',_utf8mb4'DELETE_CONTENT',_utf8mb4'WARN_USER',_utf8mb4'SUSPEND_USER',_utf8mb4'HIDE_REPORT',_utf8mb4'REQUEST_REANALYSIS')))
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci COMMENT='신고 처리 이력';

CREATE TABLE `complaints` (
  `id` bigint NOT NULL AUTO_INCREMENT COMMENT '신고 ID',
  `reporter_user_id` bigint DEFAULT NULL COMMENT '신고자 사용자 ID',
  `target_type` varchar(20) NOT NULL COMMENT '신고 대상 유형',
  `target_report_id` bigint DEFAULT NULL COMMENT '대상 리포트 ID',
  `target_post_id` bigint DEFAULT NULL COMMENT '대상 게시글 ID',
  `target_comment_id` bigint DEFAULT NULL COMMENT '대상 댓글 ID',
  `reason_code` varchar(50) NOT NULL COMMENT '신고 사유 코드',
  `detail_text` text COMMENT '신고 상세',
  `complaint_status` varchar(20) NOT NULL DEFAULT 'PENDING' COMMENT '신고 처리 상태',
  `assigned_admin_user_id` bigint DEFAULT NULL COMMENT '담당 관리자 사용자 ID',
  `resolved_at` datetime(6) DEFAULT NULL COMMENT '처리 일시',
  `created_at` datetime(6) NOT NULL DEFAULT CURRENT_TIMESTAMP(6) COMMENT '생성 일시',
  `updated_at` datetime(6) NOT NULL DEFAULT CURRENT_TIMESTAMP(6) ON UPDATE CURRENT_TIMESTAMP(6) COMMENT '수정 일시',
  PRIMARY KEY (`id`),
  UNIQUE KEY `uk_complaints_reporter_post_reason` (`reporter_user_id`,`target_post_id`,`reason_code`),
  UNIQUE KEY `uk_complaints_reporter_comment_reason` (`reporter_user_id`,`target_comment_id`,`reason_code`),
  UNIQUE KEY `uk_complaints_reporter_report_reason` (`reporter_user_id`,`target_report_id`,`reason_code`),
  KEY `fk_complaints_target_report_id` (`target_report_id`),
  KEY `fk_complaints_target_post_id` (`target_post_id`),
  KEY `fk_complaints_target_comment_id` (`target_comment_id`),
  KEY `fk_complaints_assigned_admin_user_id` (`assigned_admin_user_id`),
  KEY `idx_complaints_status_created_at` (`complaint_status`,`created_at`),
  KEY `idx_complaints_reporter_created_at` (`reporter_user_id`,`created_at`),
  CONSTRAINT `fk_complaints_assigned_admin_user_id` FOREIGN KEY (`assigned_admin_user_id`) REFERENCES `users` (`id`) ON DELETE SET NULL,
  CONSTRAINT `fk_complaints_reporter_user_id` FOREIGN KEY (`reporter_user_id`) REFERENCES `users` (`id`) ON DELETE SET NULL,
  CONSTRAINT `fk_complaints_target_comment_id` FOREIGN KEY (`target_comment_id`) REFERENCES `comments` (`id`) ON DELETE RESTRICT,
  CONSTRAINT `fk_complaints_target_post_id` FOREIGN KEY (`target_post_id`) REFERENCES `community_posts` (`id`) ON DELETE RESTRICT,
  CONSTRAINT `fk_complaints_target_report_id` FOREIGN KEY (`target_report_id`) REFERENCES `reports` (`id`) ON DELETE RESTRICT,
  CONSTRAINT `ck_complaints_status` CHECK ((`complaint_status` in (_utf8mb4'PENDING',_utf8mb4'REVIEWING',_utf8mb4'RESOLVED',_utf8mb4'REJECTED'))),
  CONSTRAINT `ck_complaints_target` CHECK ((((`target_type` = _utf8mb4'REPORT') and (`target_report_id` is not null) and (`target_post_id` is null) and (`target_comment_id` is null)) or ((`target_type` = _utf8mb4'POST') and (`target_report_id` is null) and (`target_post_id` is not null) and (`target_comment_id` is null)) or ((`target_type` = _utf8mb4'COMMENT') and (`target_report_id` is null) and (`target_post_id` is null) and (`target_comment_id` is not null))))
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci COMMENT='신고';

CREATE TABLE `consent_record_evidences` (
  `id` bigint NOT NULL AUTO_INCREMENT COMMENT '동의 증빙 항목 ID',
  `consent_record_id` bigint NOT NULL COMMENT '동의 이력 ID',
  `evidence_key` varchar(80) NOT NULL COMMENT '증빙 항목 코드',
  `value_type` varchar(20) NOT NULL DEFAULT 'STRING' COMMENT '값 유형',
  `value_text` text NOT NULL COMMENT '증빙 값',
  `created_at` datetime(6) NOT NULL DEFAULT CURRENT_TIMESTAMP(6) COMMENT '생성 일시',
  PRIMARY KEY (`id`),
  UNIQUE KEY `uk_consent_record_evidences_record_key` (`consent_record_id`,`evidence_key`),
  CONSTRAINT `fk_consent_record_evidences_record_id` FOREIGN KEY (`consent_record_id`) REFERENCES `consent_records` (`id`) ON DELETE CASCADE,
  CONSTRAINT `ck_consent_record_evidences_type` CHECK ((`value_type` in (_utf8mb4'STRING',_utf8mb4'NUMBER',_utf8mb4'BOOLEAN',_utf8mb4'DATETIME')))
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci COMMENT='동의 증빙 항목';

CREATE TABLE `consent_records` (
  `id` bigint NOT NULL AUTO_INCREMENT COMMENT '동의 이력 ID',
  `consent_term_id` bigint NOT NULL COMMENT '동의 약관 ID',
  `actor_user_id` bigint DEFAULT NULL COMMENT '처리 사용자 ID',
  `subject_child_id` bigint DEFAULT NULL COMMENT '동의 대상 아동 ID',
  `subject_reference_hash` char(64) NOT NULL COMMENT '동의 대상 참조 Hash',
  `action` varchar(20) NOT NULL COMMENT '동의 또는 철회 유형',
  `ip_address` varchar(45) DEFAULT NULL COMMENT 'IP 주소',
  `user_agent` varchar(500) DEFAULT NULL COMMENT 'User-Agent',
  `recorded_at` datetime(6) NOT NULL DEFAULT CURRENT_TIMESTAMP(6) COMMENT '기록 일시',
  PRIMARY KEY (`id`),
  KEY `fk_consent_records_term_id` (`consent_term_id`),
  KEY `fk_consent_records_actor_user_id` (`actor_user_id`),
  KEY `fk_consent_records_subject_child_id` (`subject_child_id`),
  KEY `idx_consent_records_subject_hash` (`subject_reference_hash`,`recorded_at`),
  CONSTRAINT `fk_consent_records_actor_user_id` FOREIGN KEY (`actor_user_id`) REFERENCES `users` (`id`) ON DELETE SET NULL,
  CONSTRAINT `fk_consent_records_subject_child_id` FOREIGN KEY (`subject_child_id`) REFERENCES `children` (`id`) ON DELETE SET NULL,
  CONSTRAINT `fk_consent_records_term_id` FOREIGN KEY (`consent_term_id`) REFERENCES `consent_terms` (`id`) ON DELETE RESTRICT,
  CONSTRAINT `ck_consent_records_action` CHECK ((`action` in (_utf8mb4'AGREE',_utf8mb4'WITHDRAW')))
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci COMMENT='동의 이력';

CREATE TABLE `consent_terms` (
  `id` bigint NOT NULL AUTO_INCREMENT COMMENT '동의 약관 ID',
  `term_code` varchar(50) NOT NULL COMMENT '약관 코드',
  `target_scope` varchar(10) NOT NULL COMMENT '동의 대상 범위',
  `is_required` tinyint(1) NOT NULL COMMENT '필수 여부',
  `version` varchar(30) NOT NULL COMMENT '약관 버전',
  `title` varchar(150) NOT NULL COMMENT '약관 제목',
  `content_url` varchar(1000) DEFAULT NULL COMMENT '내용 URL',
  `content_html` text COMMENT '약관 원문 HTML',
  `effective_at` datetime(6) NOT NULL COMMENT '시행 일시',
  `is_active` tinyint(1) NOT NULL DEFAULT '1' COMMENT '활성 여부',
  `created_at` datetime(6) NOT NULL DEFAULT CURRENT_TIMESTAMP(6) COMMENT '생성 일시',
  PRIMARY KEY (`id`),
  UNIQUE KEY `uk_consent_terms_code_version` (`term_code`,`version`)
) ENGINE=InnoDB AUTO_INCREMENT=9 DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci COMMENT='동의 약관';

CREATE TABLE `conversation_message_audio_variants` (
  `id` bigint NOT NULL AUTO_INCREMENT COMMENT '대화 음성 변형 ID',
  `conversation_message_id` bigint NOT NULL COMMENT '대화 메시지 ID',
  `voice_code` varchar(50) NOT NULL COMMENT '음성 코드',
  `speech_speed` decimal(4,2) NOT NULL DEFAULT '1.00' COMMENT '재생 속도',
  `storage_key` varchar(1000) NOT NULL COMMENT '음성 파일 저장 Key',
  `checksum_sha256` char(64) NOT NULL COMMENT '음성 파일 SHA-256 Checksum',
  `mime_type` varchar(100) NOT NULL COMMENT 'MIME 유형',
  `file_size_bytes` bigint NOT NULL COMMENT '파일 크기(Byte)',
  `created_at` datetime(6) NOT NULL DEFAULT CURRENT_TIMESTAMP(6) COMMENT '생성 일시',
  PRIMARY KEY (`id`),
  UNIQUE KEY `uk_conversation_audio_variant` (`conversation_message_id`,`voice_code`,`speech_speed`),
  CONSTRAINT `fk_conversation_audio_variant_message_id` FOREIGN KEY (`conversation_message_id`) REFERENCES `conversation_messages` (`id`) ON DELETE CASCADE,
  CONSTRAINT `ck_conversation_audio_variant_size` CHECK ((`file_size_bytes` > 0)),
  CONSTRAINT `ck_conversation_audio_variant_speed` CHECK ((`speech_speed` between 0.80 and 1.20))
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci COMMENT='대화 메시지 음성 변형';

CREATE TABLE `conversation_message_options` (
  `id` bigint NOT NULL AUTO_INCREMENT COMMENT '대화 메시지 선택지 ID',
  `conversation_message_id` bigint NOT NULL COMMENT '질문 메시지 ID',
  `template_option_id` bigint DEFAULT NULL COMMENT '원본 Template 선택지 ID',
  `option_key` varchar(80) NOT NULL COMMENT 'API 선택지 식별자 Snapshot',
  `option_type` varchar(30) NOT NULL COMMENT '선택지 유형 Snapshot',
  `option_value` varchar(255) NOT NULL COMMENT '선택지 값 Snapshot',
  `label` varchar(200) NOT NULL COMMENT '표시 문구 Snapshot',
  `emoji` varchar(20) DEFAULT NULL COMMENT '표시 Emoji Snapshot',
  `display_order` smallint NOT NULL DEFAULT '0' COMMENT '노출 순서',
  PRIMARY KEY (`id`),
  UNIQUE KEY `uk_conversation_message_options_message_key` (`conversation_message_id`,`option_key`),
  UNIQUE KEY `uk_conversation_message_options_message_order` (`conversation_message_id`,`display_order`),
  UNIQUE KEY `uk_conversation_message_options_message_id` (`conversation_message_id`,`id`),
  KEY `fk_conversation_message_options_template_option_id` (`template_option_id`),
  CONSTRAINT `fk_conversation_message_options_message_id` FOREIGN KEY (`conversation_message_id`) REFERENCES `conversation_messages` (`id`) ON DELETE CASCADE,
  CONSTRAINT `fk_conversation_message_options_template_option_id` FOREIGN KEY (`template_option_id`) REFERENCES `ai_question_template_options` (`id`) ON DELETE SET NULL,
  CONSTRAINT `ck_conversation_message_options_order` CHECK ((`display_order` >= 0))
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci COMMENT='대화 메시지 선택지 Snapshot';

CREATE TABLE `conversation_message_selected_options` (
  `id` bigint NOT NULL AUTO_INCREMENT COMMENT '대화 선택 응답 ID',
  `answer_message_id` bigint NOT NULL COMMENT '답변 메시지 ID',
  `question_message_id` bigint NOT NULL COMMENT '질문 메시지 ID',
  `message_option_id` bigint NOT NULL COMMENT '질문 메시지 선택지 ID',
  `label_snapshot` varchar(200) NOT NULL COMMENT '선택 당시 표시 문구',
  `selection_order` smallint NOT NULL DEFAULT '0' COMMENT '선택 순서',
  PRIMARY KEY (`id`),
  UNIQUE KEY `uk_conversation_message_selected_options_answer_option` (`answer_message_id`,`message_option_id`),
  UNIQUE KEY `uk_conversation_message_selected_options_answer_order` (`answer_message_id`,`selection_order`),
  KEY `fk_conversation_message_selected_options_answer_question` (`answer_message_id`,`question_message_id`),
  KEY `fk_conversation_message_selected_options_question_option` (`question_message_id`,`message_option_id`),
  CONSTRAINT `fk_conversation_message_selected_options_answer_question` FOREIGN KEY (`answer_message_id`, `question_message_id`) REFERENCES `conversation_messages` (`id`, `parent_message_id`) ON DELETE CASCADE,
  CONSTRAINT `fk_conversation_message_selected_options_question_option` FOREIGN KEY (`question_message_id`, `message_option_id`) REFERENCES `conversation_message_options` (`conversation_message_id`, `id`) ON DELETE CASCADE,
  CONSTRAINT `ck_conversation_message_selected_options_order` CHECK ((`selection_order` >= 0))
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci COMMENT='대화 메시지 선택 응답';

CREATE TABLE `conversation_message_targets` (
  `conversation_message_id` bigint NOT NULL COMMENT '질문 메시지 ID',
  `detected_object_id` bigint DEFAULT NULL COMMENT '분석 탐지 객체 ID',
  `object_code` varchar(50) DEFAULT NULL COMMENT '객체 코드 Snapshot',
  `object_name` varchar(100) DEFAULT NULL COMMENT '객체명 Snapshot',
  `bbox_x` decimal(8,6) NOT NULL COMMENT 'Bounding Box X 좌표',
  `bbox_y` decimal(8,6) NOT NULL COMMENT 'Bounding Box Y 좌표',
  `bbox_width` decimal(8,6) NOT NULL COMMENT 'Bounding Box 너비',
  `bbox_height` decimal(8,6) NOT NULL COMMENT 'Bounding Box 높이',
  PRIMARY KEY (`conversation_message_id`),
  KEY `fk_conversation_message_targets_detected_object_id` (`detected_object_id`),
  CONSTRAINT `fk_conversation_message_targets_detected_object_id` FOREIGN KEY (`detected_object_id`) REFERENCES `analysis_detected_objects` (`detected_object_id`) ON DELETE SET NULL,
  CONSTRAINT `fk_conversation_message_targets_message_id` FOREIGN KEY (`conversation_message_id`) REFERENCES `conversation_messages` (`id`) ON DELETE CASCADE,
  CONSTRAINT `ck_conversation_message_targets_bbox` CHECK (((`bbox_x` >= 0) and (`bbox_x` <= 1) and (`bbox_y` >= 0) and (`bbox_y` <= 1) and (`bbox_width` > 0) and (`bbox_width` <= 1) and (`bbox_height` > 0) and (`bbox_height` <= 1) and ((`bbox_x` + `bbox_width`) <= 1) and ((`bbox_y` + `bbox_height`) <= 1)))
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci COMMENT='대화 메시지 대상 객체';

CREATE TABLE `conversation_messages` (
  `id` bigint NOT NULL AUTO_INCREMENT COMMENT '대화 메시지 ID',
  `conversation_session_id` bigint NOT NULL COMMENT '대화 세션 ID',
  `parent_message_id` bigint DEFAULT NULL COMMENT '상위 메시지 ID',
  `question_template_id` bigint DEFAULT NULL COMMENT '질문 Template ID',
  `message_sequence` int NOT NULL COMMENT '메시지 순번',
  `sender_type` varchar(20) NOT NULL COMMENT '발신자 유형',
  `message_type` varchar(30) NOT NULL COMMENT '메시지 유형',
  `raw_text` text COMMENT '원문 Text',
  `stt_text` text COMMENT '음성 인식 Text',
  `audio_storage_key` varchar(1000) DEFAULT NULL COMMENT '음성 파일 저장 Key',
  `audio_url` varchar(1000) DEFAULT NULL COMMENT '음성 파일 URL',
  `audio_checksum_sha256` char(64) DEFAULT NULL COMMENT '음성 파일 SHA-256 Checksum',
  `speech_status` varchar(20) DEFAULT NULL COMMENT '음성 처리 상태',
  `tts_voice` varchar(50) DEFAULT NULL COMMENT 'AI 질문 TTS 생성 음성 코드',
  `tts_speed` decimal(3,2) DEFAULT NULL COMMENT 'AI 질문 TTS 생성 재생 속도',
  `stt_confidence` decimal(5,4) DEFAULT NULL COMMENT 'STT 신뢰도',
  `needs_guardian_confirmation` tinyint(1) NOT NULL DEFAULT '0' COMMENT '보호자 확인 필요 여부',
  `is_skipped` tinyint(1) NOT NULL DEFAULT '0' COMMENT '건너뜀 여부',
  `superseded_at` datetime(6) DEFAULT NULL COMMENT '뒤에 온 명시적 답에 자리를 내준 시각. NULL 이면 살아 있는 답',
  `superseded_by_message_id` bigint DEFAULT NULL COMMENT '자리를 대신한 답 메시지 ID',
  `created_at` datetime(6) NOT NULL DEFAULT CURRENT_TIMESTAMP(6) COMMENT '생성 일시',
  `tts_tone_profile` varchar(50) DEFAULT NULL COMMENT '질문 TTS 캐시를 구분하는 서버 고정 캐릭터·상황 말투 프로필',
  PRIMARY KEY (`id`),
  UNIQUE KEY `uk_conversation_messages_session_sequence` (`conversation_session_id`,`message_sequence`),
  UNIQUE KEY `uk_conversation_messages_id_parent` (`id`,`parent_message_id`),
  KEY `fk_conversation_messages_template_id` (`question_template_id`),
  KEY `idx_conversation_messages_parent_message_id` (`parent_message_id`),
  KEY `idx_conversation_messages_live_answer` (`parent_message_id`,`superseded_at`),
  CONSTRAINT `fk_conversation_messages_parent_message_id` FOREIGN KEY (`parent_message_id`) REFERENCES `conversation_messages` (`id`) ON DELETE SET NULL,
  CONSTRAINT `fk_conversation_messages_session_id` FOREIGN KEY (`conversation_session_id`) REFERENCES `conversation_sessions` (`id`) ON DELETE CASCADE,
  CONSTRAINT `fk_conversation_messages_template_id` FOREIGN KEY (`question_template_id`) REFERENCES `ai_question_templates` (`id`) ON DELETE SET NULL,
  CONSTRAINT `ck_conversation_messages_message_type` CHECK ((`message_type` in (_utf8mb4'QUESTION',_utf8mb4'VOICE_ANSWER',_utf8mb4'OPTION_ANSWER',_utf8mb4'TEXT_ANSWER',_utf8mb4'SYSTEM_NOTICE'))),
  CONSTRAINT `ck_conversation_messages_sender_type` CHECK ((`sender_type` in (_utf8mb4'AI',_utf8mb4'CHILD',_utf8mb4'GUARDIAN',_utf8mb4'SYSTEM'))),
  CONSTRAINT `ck_conversation_messages_speech_status` CHECK (((`speech_status` is null) or (`speech_status` in (_utf8mb4'NOT_REQUIRED',_utf8mb4'PENDING',_utf8mb4'PROCESSING',_utf8mb4'SUCCESS',_utf8mb4'FAILED')))),
  CONSTRAINT `ck_conversation_messages_stt_confidence` CHECK (((`stt_confidence` is null) or ((`stt_confidence` >= 0) and (`stt_confidence` <= 1)))),
  CONSTRAINT `ck_conversation_messages_supersede_pair` CHECK ((((`superseded_at` is null) and (`superseded_by_message_id` is null)) or ((`superseded_at` is not null) and (`superseded_by_message_id` is not null)))),
  CONSTRAINT `ck_conversation_messages_tts_tone_profile` CHECK (((`tts_tone_profile` is null) or (`tts_tone_profile` in (_utf8mb4'CHARACTER_DEFAULT_V1',_utf8mb4'CHARACTER_CELEBRATING_V1',_utf8mb4'CHARACTER_ENCOURAGING_V1'))))
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci COMMENT='대화 메시지';

CREATE TABLE `conversation_sessions` (
  `id` bigint NOT NULL AUTO_INCREMENT COMMENT '대화 세션 ID',
  `conversation_status` varchar(20) NOT NULL DEFAULT 'CONVERSING' COMMENT '대화 상태',
  `difficulty_snapshot` varchar(30) NOT NULL COMMENT '난이도 적용값',
  `max_question_count` smallint NOT NULL DEFAULT '10' COMMENT '최대 질문 수',
  `question_count` smallint NOT NULL DEFAULT '0' COMMENT '현재 질문 수',
  `completion_reason` varchar(30) DEFAULT NULL COMMENT '대화 종료 사유',
  `started_at` datetime(6) NOT NULL DEFAULT CURRENT_TIMESTAMP(6) COMMENT '시작 일시',
  `completed_at` datetime(6) DEFAULT NULL COMMENT '완료 일시',
  `created_at` datetime(6) NOT NULL DEFAULT CURRENT_TIMESTAMP(6) COMMENT '생성 일시',
  `updated_at` datetime(6) NOT NULL DEFAULT CURRENT_TIMESTAMP(6) ON UPDATE CURRENT_TIMESTAMP(6) COMMENT '수정 일시',
  `drawing_session_id` bigint NOT NULL COMMENT '그림 활동 세션 ID',
  PRIMARY KEY (`id`),
  UNIQUE KEY `uk_conversation_sessions_drawing_session_id` (`drawing_session_id`),
  KEY `idx_conversation_sessions_drawing_session_id` (`drawing_session_id`),
  CONSTRAINT `fk_conversation_sessions_drawing_session_id` FOREIGN KEY (`drawing_session_id`) REFERENCES `drawing_sessions` (`id`) ON DELETE CASCADE,
  CONSTRAINT `ck_conversation_sessions_completion_reason` CHECK (((`completion_reason` is null) or (`completion_reason` in (_utf8mb4'QUESTION_LIMIT_REACHED',_utf8mb4'CHILD_REQUEST',_utf8mb4'GUARDIAN_REQUEST',_utf8mb4'NO_MORE_QUESTION')))),
  CONSTRAINT `ck_conversation_sessions_question_count` CHECK (((`max_question_count` > 0) and (`question_count` >= 0) and (`question_count` <= `max_question_count`))),
  CONSTRAINT `ck_conversation_sessions_status` CHECK ((`conversation_status` in (_utf8mb4'CONVERSING',_utf8mb4'COMPLETED',_utf8mb4'FAILED')))
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci COMMENT='대화 세션';

CREATE TABLE `data_export_jobs` (
  `id` bigint NOT NULL AUTO_INCREMENT COMMENT '데이터 내보내기 작업 ID',
  `user_id` bigint NOT NULL COMMENT '사용자 ID',
  `export_status` varchar(20) NOT NULL DEFAULT 'PENDING' COMMENT '내보내기 상태',
  `storage_key` varchar(1000) DEFAULT NULL COMMENT '내보내기 파일 저장 Key',
  `expires_at` datetime(6) DEFAULT NULL COMMENT '다운로드 만료 일시',
  `completed_at` datetime(6) DEFAULT NULL COMMENT '완료 일시',
  `error_code` varchar(80) DEFAULT NULL COMMENT '오류 코드',
  `created_at` datetime(6) NOT NULL DEFAULT CURRENT_TIMESTAMP(6) COMMENT '생성 일시',
  `updated_at` datetime(6) NOT NULL DEFAULT CURRENT_TIMESTAMP(6) ON UPDATE CURRENT_TIMESTAMP(6) COMMENT '수정 일시',
  PRIMARY KEY (`id`),
  KEY `idx_data_export_jobs_user_created_at` (`user_id`,`created_at`),
  KEY `idx_data_export_jobs_status_created_at` (`export_status`,`created_at`),
  CONSTRAINT `fk_data_export_jobs_user_id` FOREIGN KEY (`user_id`) REFERENCES `users` (`id`) ON DELETE CASCADE,
  CONSTRAINT `ck_data_export_jobs_status` CHECK ((`export_status` in (_utf8mb4'PENDING',_utf8mb4'PROCESSING',_utf8mb4'COMPLETED',_utf8mb4'FAILED',_utf8mb4'EXPIRED')))
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci COMMENT='데이터 내보내기 작업';

CREATE TABLE `drawing_assets` (
  `id` bigint NOT NULL AUTO_INCREMENT COMMENT '그림 파일 ID',
  `drawing_session_id` bigint NOT NULL COMMENT '그림 활동 세션 ID',
  `asset_type` varchar(20) NOT NULL COMMENT '파일 유형',
  `asset_version` int NOT NULL DEFAULT '1' COMMENT '파일 버전',
  `storage_key` varchar(1000) NOT NULL COMMENT '파일 저장 Key',
  `file_url` varchar(1000) DEFAULT NULL COMMENT '파일 URL',
  `mime_type` varchar(100) NOT NULL COMMENT 'MIME 유형',
  `file_size_bytes` bigint NOT NULL COMMENT '파일 크기(Byte)',
  `width_px` int DEFAULT NULL COMMENT '이미지 너비(px)',
  `height_px` int DEFAULT NULL COMMENT '이미지 높이(px)',
  `checksum_sha256` char(64) NOT NULL COMMENT 'SHA-256 Checksum',
  `last_event_sequence` bigint DEFAULT NULL COMMENT '자산에 반영된 마지막 Stroke 이벤트 순번',
  `object_code` varchar(50) DEFAULT NULL COMMENT '다중 객체 업로드 식별 코드',
  `captured_at` datetime(6) NOT NULL COMMENT '클라이언트 캡처 일시',
  `expires_at` datetime(6) DEFAULT NULL COMMENT '만료 일시',
  `created_at` datetime(6) NOT NULL DEFAULT CURRENT_TIMESTAMP(6) COMMENT '생성 일시',
  `final_drawing_session_id` bigint GENERATED ALWAYS AS ((case when (`asset_type` = _utf8mb4'FINAL') then `drawing_session_id` else NULL end)) VIRTUAL COMMENT '세션별 최종 그림 유일성 검사용 생성값',
  `upload_idempotency_key` varchar(100) DEFAULT NULL COMMENT 'HTP 원본 이미지 업로드 멱등 키',
  `upload_fingerprint` char(64) DEFAULT NULL COMMENT '정규화된 업로드 요청 SHA-256',
  `upload_rotation_degrees` int DEFAULT NULL COMMENT '클라이언트가 적용한 회전 각도',
  `upload_crop_applied` tinyint(1) DEFAULT NULL COMMENT '클라이언트 자르기 적용 여부',
  `uploaded_drawing_session_id` bigint GENERATED ALWAYS AS ((case when (`asset_type` = _utf8mb4'UPLOADED') then `drawing_session_id` else NULL end)) VIRTUAL COMMENT '세션별 업로드 원본 유일성 검사용 생성값',
  PRIMARY KEY (`id`),
  UNIQUE KEY `uk_drawing_assets_session_type_version` (`drawing_session_id`,`asset_type`,`asset_version`),
  UNIQUE KEY `uk_drawing_assets_upload_idempotency_key` (`upload_idempotency_key`),
  UNIQUE KEY `uk_drawing_assets_final_session` (`final_drawing_session_id`),
  UNIQUE KEY `uk_drawing_assets_uploaded_session` (`uploaded_drawing_session_id`),
  KEY `idx_drawing_assets_session_type` (`drawing_session_id`,`asset_type`,`asset_version`),
  CONSTRAINT `fk_drawing_assets_session_id` FOREIGN KEY (`drawing_session_id`) REFERENCES `drawing_sessions` (`id`) ON DELETE CASCADE,
  CONSTRAINT `ck_drawing_assets_asset_type` CHECK ((`asset_type` in (_utf8mb4'DRAFT',_utf8mb4'INTERMEDIATE',_utf8mb4'FINAL',_utf8mb4'UPLOADED',_utf8mb4'THUMBNAIL',_utf8mb4'TIMELAPSE'))),
  CONSTRAINT `ck_drawing_assets_file_size` CHECK ((`file_size_bytes` >= 0)),
  CONSTRAINT `ck_drawing_assets_last_event_sequence` CHECK (((`last_event_sequence` is null) or (`last_event_sequence` >= 0)))
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci COMMENT='그림 파일';

CREATE TABLE `drawing_session_emotions` (
  `id` bigint NOT NULL AUTO_INCREMENT COMMENT '그림 활동 선택 감정 ID',
  `drawing_session_id` bigint NOT NULL COMMENT '그림 활동 세션 ID',
  `emotion_code` varchar(20) NOT NULL COMMENT '감정 코드',
  `selection_order` smallint NOT NULL DEFAULT '0' COMMENT '선택 순서',
  `created_at` datetime(6) NOT NULL DEFAULT CURRENT_TIMESTAMP(6) COMMENT '생성 일시',
  PRIMARY KEY (`id`),
  UNIQUE KEY `uk_drawing_session_emotions_session_emotion` (`drawing_session_id`,`emotion_code`),
  UNIQUE KEY `uk_drawing_session_emotions_session_order` (`drawing_session_id`,`selection_order`),
  CONSTRAINT `fk_drawing_session_emotions_session_id` FOREIGN KEY (`drawing_session_id`) REFERENCES `drawing_sessions` (`id`) ON DELETE CASCADE,
  CONSTRAINT `ck_drawing_session_emotions_code` CHECK ((`emotion_code` in (_utf8mb4'HAPPY',_utf8mb4'SAD',_utf8mb4'ANGRY',_utf8mb4'SCARED',_utf8mb4'CALM',_utf8mb4'UNKNOWN'))),
  CONSTRAINT `ck_drawing_session_emotions_order` CHECK ((`selection_order` >= 0))
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci COMMENT='그림 활동 선택 감정';

CREATE TABLE `drawing_sessions` (
  `id` bigint NOT NULL AUTO_INCREMENT COMMENT '그림 활동 세션 ID',
  `child_id` bigint NOT NULL COMMENT '아동 ID',
  `drawing_type_id` bigint NOT NULL COMMENT '그림 활동 유형 ID',
  `started_by_user_id` bigint DEFAULT NULL COMMENT '시작 사용자 ID',
  `input_method` varchar(20) NOT NULL COMMENT '입력 방식',
  `title` varchar(200) DEFAULT NULL COMMENT '그림 제목',
  `expressed_emotion_text` text COMMENT '표현한 감정 내용',
  `session_status` varchar(20) NOT NULL DEFAULT 'IN_PROGRESS' COMMENT '세션 상태',
  `current_stage` varchar(30) NOT NULL DEFAULT 'DRAWING' COMMENT '현재 단계',
  `started_at` datetime(6) NOT NULL DEFAULT CURRENT_TIMESTAMP(6) COMMENT '시작 일시',
  `completed_at` datetime(6) DEFAULT NULL COMMENT '완료 일시',
  `created_at` datetime(6) NOT NULL DEFAULT CURRENT_TIMESTAMP(6) COMMENT '생성 일시',
  `updated_at` datetime(6) NOT NULL DEFAULT CURRENT_TIMESTAMP(6) ON UPDATE CURRENT_TIMESTAMP(6) COMMENT '수정 일시',
  `deleted_at` datetime(6) DEFAULT NULL COMMENT '삭제 일시',
  `idempotency_key` varchar(100) DEFAULT NULL COMMENT '그림 활동 세션 생성 요청 멱등성 Key',
  PRIMARY KEY (`id`),
  UNIQUE KEY `uk_drawing_sessions_idempotency_key` (`idempotency_key`),
  KEY `fk_drawing_sessions_drawing_type_id` (`drawing_type_id`),
  KEY `fk_drawing_sessions_started_by_user_id` (`started_by_user_id`),
  KEY `idx_drawing_sessions_child_id` (`child_id`,`created_at`),
  KEY `idx_drawing_sessions_active_child` (`child_id`,`session_status`,`deleted_at`),
  CONSTRAINT `fk_drawing_sessions_child_id` FOREIGN KEY (`child_id`) REFERENCES `children` (`id`) ON DELETE RESTRICT,
  CONSTRAINT `fk_drawing_sessions_drawing_type_id` FOREIGN KEY (`drawing_type_id`) REFERENCES `drawing_types` (`id`) ON DELETE RESTRICT,
  CONSTRAINT `fk_drawing_sessions_started_by_user_id` FOREIGN KEY (`started_by_user_id`) REFERENCES `users` (`id`) ON DELETE SET NULL,
  CONSTRAINT `ck_drawing_sessions_current_stage` CHECK ((`current_stage` in (_utf8mb4'DRAWING',_utf8mb4'ANALYZING',_utf8mb4'CONVERSING',_utf8mb4'REFLECTION',_utf8mb4'REPORTING',_utf8mb4'COMPLETED'))),
  CONSTRAINT `ck_drawing_sessions_input_method` CHECK ((`input_method` in (_utf8mb4'CANVAS',_utf8mb4'UPLOAD'))),
  CONSTRAINT `ck_drawing_sessions_session_status` CHECK ((`session_status` in (_utf8mb4'IN_PROGRESS',_utf8mb4'COMPLETED',_utf8mb4'FAILED',_utf8mb4'ABANDONED',_utf8mb4'DELETED')))
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci COMMENT='그림 활동 세션';

CREATE TABLE `drawing_types` (
  `id` bigint NOT NULL AUTO_INCREMENT COMMENT '그림 활동 유형 ID',
  `code` varchar(50) NOT NULL COMMENT '코드',
  `name` varchar(100) NOT NULL COMMENT '그림 활동 유형명',
  `activity_category` varchar(20) NOT NULL COMMENT '활동 분류',
  `selectable_by` varchar(20) NOT NULL COMMENT '선택 가능 주체',
  `recommended_age_min` tinyint DEFAULT NULL COMMENT '권장 최소 연령',
  `recommended_age_max` tinyint DEFAULT NULL COMMENT '권장 최대 연령',
  `guide_text` text COMMENT '안내 문구',
  `is_active` tinyint(1) NOT NULL DEFAULT '1' COMMENT '활성 여부',
  `display_order` smallint NOT NULL DEFAULT '0' COMMENT '노출 순서',
  `created_at` datetime(6) NOT NULL DEFAULT CURRENT_TIMESTAMP(6) COMMENT '생성 일시',
  `updated_at` datetime(6) NOT NULL DEFAULT CURRENT_TIMESTAMP(6) ON UPDATE CURRENT_TIMESTAMP(6) COMMENT '수정 일시',
  PRIMARY KEY (`id`),
  UNIQUE KEY `uk_drawing_types_code` (`code`),
  CONSTRAINT `ck_drawing_types_activity_category` CHECK ((`activity_category` in (_utf8mb4'ASSESSMENT',_utf8mb4'GENERAL'))),
  CONSTRAINT `ck_drawing_types_age_range` CHECK (((`recommended_age_min` is null) or (`recommended_age_max` is null) or (`recommended_age_min` <= `recommended_age_max`))),
  CONSTRAINT `ck_drawing_types_selectable_by` CHECK ((`selectable_by` in (_utf8mb4'GUARDIAN',_utf8mb4'CHILD',_utf8mb4'BOTH')))
) ENGINE=InnoDB AUTO_INCREMENT=6 DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci COMMENT='그림 활동 유형';

CREATE TABLE `expert_credential_files` (
  `id` bigint NOT NULL AUTO_INCREMENT COMMENT '전문가 자격 증빙 파일 ID',
  `expert_credential_id` bigint NOT NULL COMMENT '전문가 자격 ID',
  `storage_key` varchar(1000) NOT NULL COMMENT '증빙 파일 저장 Key',
  `storage_key_hash` char(64) NOT NULL COMMENT '증빙 파일 저장 Key SHA-256 Hash',
  `file_name` varchar(255) DEFAULT NULL COMMENT '원본 파일명',
  `mime_type` varchar(100) DEFAULT NULL COMMENT 'MIME 유형',
  `file_size_bytes` bigint DEFAULT NULL COMMENT '파일 크기(Byte)',
  `display_order` smallint NOT NULL DEFAULT '0' COMMENT '노출 순서',
  `created_at` datetime(6) NOT NULL DEFAULT CURRENT_TIMESTAMP(6) COMMENT '생성 일시',
  PRIMARY KEY (`id`),
  UNIQUE KEY `uk_expert_credential_files_key_hash` (`storage_key_hash`),
  UNIQUE KEY `uk_expert_credential_files_order` (`expert_credential_id`,`display_order`),
  CONSTRAINT `fk_expert_credential_files_credential_id` FOREIGN KEY (`expert_credential_id`) REFERENCES `expert_credentials` (`id`) ON DELETE CASCADE,
  CONSTRAINT `ck_expert_credential_files_order` CHECK ((`display_order` >= 0)),
  CONSTRAINT `ck_expert_credential_files_size` CHECK (((`file_size_bytes` is null) or (`file_size_bytes` > 0)))
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci COMMENT='전문가 자격 증빙 파일';

CREATE TABLE `expert_credentials` (
  `id` bigint NOT NULL AUTO_INCREMENT COMMENT '전문가 자격 ID',
  `expert_profile_id` bigint NOT NULL COMMENT '전문가 프로필 ID',
  `credential_type` varchar(50) NOT NULL COMMENT '자격 분류 코드',
  `license_name` varchar(150) NOT NULL COMMENT '자격명',
  `issuer` varchar(150) NOT NULL COMMENT '발급 기관',
  `credential_number` varchar(100) DEFAULT NULL COMMENT '자격 번호',
  `acquired_on` date DEFAULT NULL COMMENT '취득일',
  `expires_on` date DEFAULT NULL COMMENT '만료일',
  `verification_status` varchar(20) NOT NULL DEFAULT 'PENDING' COMMENT '검증 상태',
  `created_at` datetime(6) NOT NULL DEFAULT CURRENT_TIMESTAMP(6) COMMENT '생성 일시',
  `updated_at` datetime(6) NOT NULL DEFAULT CURRENT_TIMESTAMP(6) ON UPDATE CURRENT_TIMESTAMP(6) COMMENT '수정 일시',
  PRIMARY KEY (`id`),
  KEY `idx_expert_credentials_profile_status` (`expert_profile_id`,`verification_status`),
  CONSTRAINT `fk_expert_credentials_profile_id` FOREIGN KEY (`expert_profile_id`) REFERENCES `expert_profiles` (`id`) ON DELETE CASCADE,
  CONSTRAINT `ck_expert_credentials_dates` CHECK (((`expires_on` is null) or (`acquired_on` is null) or (`expires_on` >= `acquired_on`))),
  CONSTRAINT `ck_expert_credentials_status` CHECK ((`verification_status` in (_utf8mb4'PENDING',_utf8mb4'VERIFIED',_utf8mb4'REJECTED',_utf8mb4'REVIEW_REQUIRED')))
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci COMMENT='전문가 자격';

CREATE TABLE `expert_follows` (
  `id` bigint NOT NULL AUTO_INCREMENT COMMENT '전문가 팔로우 ID',
  `guardian_user_id` bigint NOT NULL COMMENT '보호자 사용자 ID',
  `expert_profile_id` bigint NOT NULL COMMENT '전문가 프로필 ID',
  `created_at` datetime(6) NOT NULL DEFAULT CURRENT_TIMESTAMP(6) COMMENT '생성 일시',
  PRIMARY KEY (`id`),
  UNIQUE KEY `uk_expert_follows_guardian_expert` (`guardian_user_id`,`expert_profile_id`),
  KEY `fk_expert_follows_expert_profile_id` (`expert_profile_id`),
  CONSTRAINT `fk_expert_follows_expert_profile_id` FOREIGN KEY (`expert_profile_id`) REFERENCES `expert_profiles` (`id`) ON DELETE CASCADE,
  CONSTRAINT `fk_expert_follows_guardian_user_id` FOREIGN KEY (`guardian_user_id`) REFERENCES `users` (`id`) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci COMMENT='전문가 팔로우';

CREATE TABLE `expert_profile_specialties` (
  `id` bigint NOT NULL AUTO_INCREMENT COMMENT '전문가 전문 분야 ID',
  `expert_profile_id` bigint NOT NULL COMMENT '전문가 프로필 ID',
  `specialty_code` varchar(50) NOT NULL COMMENT '전문 분야 코드',
  `specialty_name` varchar(100) NOT NULL COMMENT '전문 분야명 Snapshot',
  `display_order` smallint NOT NULL DEFAULT '0' COMMENT '노출 순서',
  `created_at` datetime(6) NOT NULL DEFAULT CURRENT_TIMESTAMP(6) COMMENT '생성 일시',
  PRIMARY KEY (`id`),
  UNIQUE KEY `uk_expert_profile_specialties_profile_code` (`expert_profile_id`,`specialty_code`),
  CONSTRAINT `fk_expert_profile_specialties_profile_id` FOREIGN KEY (`expert_profile_id`) REFERENCES `expert_profiles` (`id`) ON DELETE CASCADE,
  CONSTRAINT `ck_expert_profile_specialties_order` CHECK ((`display_order` >= 0))
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci COMMENT='전문가 전문 분야';

CREATE TABLE `expert_profiles` (
  `id` bigint NOT NULL AUTO_INCREMENT COMMENT '전문가 프로필 ID',
  `display_name` varchar(80) NOT NULL COMMENT '표시 이름',
  `profile_image_url` varchar(1000) DEFAULT NULL COMMENT '프로필 이미지 URL',
  `organization` varchar(150) DEFAULT NULL COMMENT '소속 기관',
  `position_title` varchar(100) DEFAULT NULL COMMENT '직책',
  `career_years` smallint NOT NULL DEFAULT '0' COMMENT '경력 연수',
  `target_age_min` smallint DEFAULT NULL COMMENT '상담 대상 최소 연령',
  `target_age_max` smallint DEFAULT NULL COMMENT '상담 대상 최대 연령',
  `introduction` text COMMENT '소개',
  `is_consultation_available` tinyint(1) NOT NULL DEFAULT '0' COMMENT '상담 가능 여부',
  `verification_status` varchar(20) NOT NULL DEFAULT 'PENDING' COMMENT '검증 상태',
  `workplace` varchar(255) DEFAULT NULL COMMENT '근무지',
  `contact_phone` varchar(30) DEFAULT NULL COMMENT '연락처',
  `contact_email` varchar(255) DEFAULT NULL COMMENT '연락 이메일',
  `created_at` datetime(6) NOT NULL DEFAULT CURRENT_TIMESTAMP(6) COMMENT '생성 일시',
  `updated_at` datetime(6) NOT NULL DEFAULT CURRENT_TIMESTAMP(6) ON UPDATE CURRENT_TIMESTAMP(6) COMMENT '수정 일시',
  `deleted_at` datetime(6) DEFAULT NULL COMMENT '삭제 일시',
  `user_id` bigint NOT NULL COMMENT '사용자 ID',
  PRIMARY KEY (`id`),
  UNIQUE KEY `uk_expert_profiles_user_id` (`user_id`),
  CONSTRAINT `fk_expert_profiles_user_id` FOREIGN KEY (`user_id`) REFERENCES `users` (`id`) ON DELETE CASCADE,
  CONSTRAINT `ck_expert_profiles_career_years` CHECK ((`career_years` >= 0)),
  CONSTRAINT `ck_expert_profiles_target_age` CHECK ((((`target_age_min` is null) and (`target_age_max` is null)) or ((`target_age_min` between 0 and 19) and (`target_age_max` between 0 and 19) and (`target_age_min` <= `target_age_max`)))),
  CONSTRAINT `ck_expert_profiles_verification_status` CHECK ((`verification_status` in (_utf8mb4'PENDING',_utf8mb4'VERIFIED',_utf8mb4'REJECTED',_utf8mb4'REVIEW_REQUIRED')))
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci COMMENT='전문가 프로필';

CREATE TABLE `expert_verification_review_credentials` (
  `review_id` bigint NOT NULL COMMENT '전문가 검토 이력 ID',
  `expert_credential_id` bigint NOT NULL COMMENT '승인한 전문가 자격 ID',
  PRIMARY KEY (`review_id`,`expert_credential_id`),
  KEY `fk_expert_verification_review_credentials_credential_id` (`expert_credential_id`),
  CONSTRAINT `fk_expert_verification_review_credentials_credential_id` FOREIGN KEY (`expert_credential_id`) REFERENCES `expert_credentials` (`id`) ON DELETE RESTRICT,
  CONSTRAINT `fk_expert_verification_review_credentials_review_id` FOREIGN KEY (`review_id`) REFERENCES `expert_verification_reviews` (`id`) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci COMMENT='전문가 검토 승인 자격';

CREATE TABLE `expert_verification_reviews` (
  `id` bigint NOT NULL AUTO_INCREMENT COMMENT '전문가 검토 이력 ID',
  `expert_profile_id` bigint NOT NULL COMMENT '검토 대상 전문가 프로필 ID',
  `reviewer_user_id` bigint NOT NULL COMMENT '검토 관리자 사용자 ID',
  `decision_status` varchar(20) NOT NULL COMMENT '최종 승인·반려 상태',
  `rejection_reason` varchar(1000) DEFAULT NULL COMMENT '전문가에게 공개할 반려 사유',
  `internal_note` varchar(2000) DEFAULT NULL COMMENT '관리자 내부 검토 메모',
  `reviewed_at` datetime(6) NOT NULL COMMENT '검토 완료 일시',
  PRIMARY KEY (`id`),
  KEY `fk_expert_verification_reviews_reviewer_id` (`reviewer_user_id`),
  KEY `idx_expert_verification_reviews_profile_reviewed` (`expert_profile_id`,`reviewed_at` DESC),
  CONSTRAINT `fk_expert_verification_reviews_profile_id` FOREIGN KEY (`expert_profile_id`) REFERENCES `expert_profiles` (`id`) ON DELETE CASCADE,
  CONSTRAINT `fk_expert_verification_reviews_reviewer_id` FOREIGN KEY (`reviewer_user_id`) REFERENCES `users` (`id`) ON DELETE RESTRICT,
  CONSTRAINT `ck_expert_verification_reviews_reason` CHECK ((((`decision_status` = _utf8mb4'VERIFIED') and (`rejection_reason` is null)) or ((`decision_status` = _utf8mb4'REJECTED') and (`rejection_reason` is not null)))),
  CONSTRAINT `ck_expert_verification_reviews_status` CHECK ((`decision_status` in (_utf8mb4'VERIFIED',_utf8mb4'REJECTED')))
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci COMMENT='전문가 자격 검토 이력';

CREATE TABLE `guardian_child_relations` (
  `id` bigint NOT NULL AUTO_INCREMENT COMMENT '보호자-아동 관계 ID',
  `guardian_user_id` bigint NOT NULL COMMENT '보호자 사용자 ID',
  `child_id` bigint NOT NULL COMMENT '아동 ID',
  `relationship_type` varchar(30) NOT NULL COMMENT '관계 유형',
  `created_at` datetime(6) NOT NULL DEFAULT CURRENT_TIMESTAMP(6) COMMENT '생성 일시',
  PRIMARY KEY (`id`),
  UNIQUE KEY `uk_guardian_child_relations_guardian_child` (`guardian_user_id`,`child_id`),
  KEY `fk_guardian_child_relations_child_id` (`child_id`),
  CONSTRAINT `fk_guardian_child_relations_child_id` FOREIGN KEY (`child_id`) REFERENCES `children` (`id`) ON DELETE CASCADE,
  CONSTRAINT `fk_guardian_child_relations_guardian_id` FOREIGN KEY (`guardian_user_id`) REFERENCES `users` (`id`) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci COMMENT='보호자-아동 관계';

CREATE TABLE `htp_assessment_steps` (
  `id` bigint NOT NULL AUTO_INCREMENT COMMENT 'HTP 그림 단계 ID',
  `htp_assessment_id` bigint NOT NULL COMMENT 'HTP 활동 묶음 ID',
  `step_order` tinyint NOT NULL COMMENT '그림 단계 순서',
  `drawing_subject` varchar(20) NOT NULL COMMENT '그림 주제',
  `drawing_session_id` bigint NOT NULL COMMENT '단계별 그림 활동 세션 ID',
  `subject_detected` tinyint(1) DEFAULT NULL COMMENT '주제 전체 객체 탐지 여부',
  `retry_count` tinyint NOT NULL DEFAULT '0' COMMENT '추가 그리기 요청 횟수',
  `transition_idempotency_key` varchar(100) NOT NULL COMMENT '단계 생성 요청 멱등 키',
  `completion_idempotency_key` varchar(100) DEFAULT NULL COMMENT '단계 완료 요청 멱등 키',
  `created_at` datetime(6) NOT NULL COMMENT '단계 생성 일시',
  PRIMARY KEY (`id`),
  UNIQUE KEY `uk_htp_assessment_steps_order` (`htp_assessment_id`,`step_order`),
  UNIQUE KEY `uk_htp_assessment_steps_subject` (`htp_assessment_id`,`drawing_subject`),
  UNIQUE KEY `uk_htp_assessment_steps_session` (`drawing_session_id`),
  UNIQUE KEY `uk_htp_assessment_steps_transition_key` (`transition_idempotency_key`),
  CONSTRAINT `fk_htp_assessment_steps_assessment_id` FOREIGN KEY (`htp_assessment_id`) REFERENCES `htp_assessments` (`id`) ON DELETE CASCADE,
  CONSTRAINT `fk_htp_assessment_steps_drawing_session_id` FOREIGN KEY (`drawing_session_id`) REFERENCES `drawing_sessions` (`id`) ON DELETE RESTRICT,
  CONSTRAINT `ck_htp_assessment_steps_order` CHECK ((`step_order` between 1 and 3)),
  CONSTRAINT `ck_htp_assessment_steps_retry_count` CHECK ((`retry_count` between 0 and 1)),
  CONSTRAINT `ck_htp_assessment_steps_subject` CHECK ((`drawing_subject` in (_utf8mb4'HOUSE',_utf8mb4'TREE',_utf8mb4'PERSON')))
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci COMMENT='HTP 그림 단계';

CREATE TABLE `htp_assessments` (
  `id` bigint NOT NULL AUTO_INCREMENT COMMENT 'HTP 활동 묶음 ID',
  `child_id` bigint NOT NULL COMMENT '아동 ID',
  `drawing_type_id` bigint NOT NULL COMMENT 'HTP 그림 활동 유형 ID',
  `status` varchar(20) NOT NULL COMMENT 'HTP 활동 상태',
  `current_step_order` tinyint NOT NULL COMMENT '현재 그림 단계 순서',
  `expires_at` datetime(6) NOT NULL COMMENT '재개 만료 일시',
  `created_at` datetime(6) NOT NULL COMMENT '생성 일시',
  `completed_at` datetime(6) DEFAULT NULL COMMENT '완료·포기 일시',
  `idempotency_key` varchar(100) NOT NULL COMMENT 'HTP 시작 요청 멱등 키',
  `completion_idempotency_key` varchar(100) DEFAULT NULL COMMENT 'HTP 종합 완료 요청 멱등 키',
  `report_analysis_id` bigint DEFAULT NULL COMMENT '현재 HTP 리포트 생성 분석 ID',
  `report_id` bigint DEFAULT NULL COMMENT '현재 HTP 단일 리포트 ID',
  `active_child_id` bigint GENERATED ALWAYS AS ((case when (`status` in (_utf8mb4'IN_PROGRESS',_utf8mb4'ANALYZING')) then `child_id` else NULL end)) STORED COMMENT '아동별 진행 중 HTP 유일성 보장용',
  PRIMARY KEY (`id`),
  UNIQUE KEY `uk_htp_assessments_idempotency_key` (`idempotency_key`),
  UNIQUE KEY `uk_htp_assessments_active_child` (`active_child_id`),
  UNIQUE KEY `uk_htp_assessments_completion_key` (`completion_idempotency_key`),
  KEY `fk_htp_assessments_drawing_type_id` (`drawing_type_id`),
  KEY `idx_htp_assessments_child_created_at` (`child_id`,`created_at`),
  KEY `fk_htp_assessments_report_analysis_id` (`report_analysis_id`),
  KEY `fk_htp_assessments_report_id` (`report_id`),
  CONSTRAINT `fk_htp_assessments_child_id` FOREIGN KEY (`child_id`) REFERENCES `children` (`id`) ON DELETE RESTRICT,
  CONSTRAINT `fk_htp_assessments_drawing_type_id` FOREIGN KEY (`drawing_type_id`) REFERENCES `drawing_types` (`id`) ON DELETE RESTRICT,
  CONSTRAINT `fk_htp_assessments_report_analysis_id` FOREIGN KEY (`report_analysis_id`) REFERENCES `analyses` (`id`) ON DELETE RESTRICT,
  CONSTRAINT `fk_htp_assessments_report_id` FOREIGN KEY (`report_id`) REFERENCES `reports` (`id`) ON DELETE RESTRICT,
  CONSTRAINT `ck_htp_assessments_current_step_order` CHECK ((`current_step_order` between 1 and 3)),
  CONSTRAINT `ck_htp_assessments_status` CHECK ((`status` in (_utf8mb4'IN_PROGRESS',_utf8mb4'ANALYZING',_utf8mb4'COMPLETED',_utf8mb4'FAILED',_utf8mb4'ABANDONED',_utf8mb4'EXPIRED')))
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci COMMENT='HTP 활동 묶음';

CREATE TABLE `notification_attributes` (
  `id` bigint NOT NULL AUTO_INCREMENT COMMENT '알림 부가 속성 ID',
  `notification_id` bigint NOT NULL COMMENT '알림 ID',
  `attribute_key` varchar(80) NOT NULL COMMENT '부가 속성 코드',
  `value_type` varchar(20) NOT NULL DEFAULT 'STRING' COMMENT '값 유형',
  `value_text` varchar(1000) NOT NULL COMMENT '부가 속성 값',
  PRIMARY KEY (`id`),
  UNIQUE KEY `uk_notification_attributes_notification_key` (`notification_id`,`attribute_key`),
  CONSTRAINT `fk_notification_attributes_notification_id` FOREIGN KEY (`notification_id`) REFERENCES `notifications` (`id`) ON DELETE CASCADE,
  CONSTRAINT `ck_notification_attributes_type` CHECK ((`value_type` in (_utf8mb4'STRING',_utf8mb4'NUMBER',_utf8mb4'BOOLEAN',_utf8mb4'DATETIME')))
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci COMMENT='알림 부가 속성';

CREATE TABLE `notification_device_tokens` (
  `id` bigint NOT NULL AUTO_INCREMENT COMMENT 'Push 기기 Token ID',
  `user_id` bigint NOT NULL COMMENT '사용자 ID',
  `device_id` varchar(100) NOT NULL COMMENT '클라이언트 설치 식별자',
  `token_ciphertext` varchar(1500) NOT NULL COMMENT '암호화된 Push Provider 기기 Token',
  `token_hash` char(64) NOT NULL COMMENT '기기 Token SHA-256 Hash',
  `platform` varchar(20) NOT NULL COMMENT '기기 Platform',
  `push_provider` varchar(20) NOT NULL COMMENT 'Push Provider',
  `app_version` varchar(20) DEFAULT NULL COMMENT '등록 시점 앱 버전',
  `is_active` tinyint(1) NOT NULL DEFAULT '1' COMMENT '활성 여부',
  `last_used_at` datetime(6) DEFAULT NULL COMMENT '마지막 사용 일시',
  `created_at` datetime(6) NOT NULL DEFAULT CURRENT_TIMESTAMP(6) COMMENT '생성 일시',
  `updated_at` datetime(6) NOT NULL DEFAULT CURRENT_TIMESTAMP(6) ON UPDATE CURRENT_TIMESTAMP(6) COMMENT '수정 일시',
  PRIMARY KEY (`id`),
  UNIQUE KEY `uk_notification_device_tokens_hash` (`token_hash`),
  UNIQUE KEY `uk_notification_device_tokens_user_device` (`user_id`,`device_id`),
  KEY `idx_notification_device_tokens_user_active` (`user_id`,`is_active`),
  CONSTRAINT `fk_notification_device_tokens_user_id` FOREIGN KEY (`user_id`) REFERENCES `users` (`id`) ON DELETE CASCADE,
  CONSTRAINT `ck_notification_device_tokens_platform` CHECK ((`platform` in (_utf8mb4'ANDROID',_utf8mb4'IOS',_utf8mb4'WEB'))),
  CONSTRAINT `ck_notification_device_tokens_provider` CHECK ((`push_provider` in (_utf8mb4'FCM',_utf8mb4'APNS')))
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci COMMENT='Push 기기 Token';

CREATE TABLE `notifications` (
  `id` bigint NOT NULL AUTO_INCREMENT COMMENT '알림 ID',
  `recipient_user_id` bigint NOT NULL COMMENT '수신자 사용자 ID',
  `notification_type` varchar(40) NOT NULL COMMENT '알림 유형',
  `title` varchar(200) NOT NULL COMMENT '알림 제목',
  `content` text NOT NULL COMMENT '알림 내용',
  `related_post_id` bigint DEFAULT NULL COMMENT '관련 게시글 ID',
  `related_report_id` bigint DEFAULT NULL COMMENT '관련 리포트 ID',
  `related_drawing_session_id` bigint DEFAULT NULL COMMENT '관련 그림 활동 세션 ID',
  `delivery_status` varchar(20) NOT NULL DEFAULT 'PENDING' COMMENT '전송 상태',
  `read_at` datetime(6) DEFAULT NULL COMMENT '읽은 일시',
  `sent_at` datetime(6) DEFAULT NULL COMMENT '전송 일시',
  `failed_at` datetime(6) DEFAULT NULL COMMENT '실패 일시',
  `created_at` datetime(6) NOT NULL DEFAULT CURRENT_TIMESTAMP(6) COMMENT '생성 일시',
  PRIMARY KEY (`id`),
  KEY `fk_notifications_related_post_id` (`related_post_id`),
  KEY `fk_notifications_related_report_id` (`related_report_id`),
  KEY `fk_notifications_related_drawing_session_id` (`related_drawing_session_id`),
  KEY `idx_notifications_recipient_created_at` (`recipient_user_id`,`created_at`),
  CONSTRAINT `fk_notifications_recipient_user_id` FOREIGN KEY (`recipient_user_id`) REFERENCES `users` (`id`) ON DELETE CASCADE,
  CONSTRAINT `fk_notifications_related_drawing_session_id` FOREIGN KEY (`related_drawing_session_id`) REFERENCES `drawing_sessions` (`id`) ON DELETE SET NULL,
  CONSTRAINT `fk_notifications_related_post_id` FOREIGN KEY (`related_post_id`) REFERENCES `community_posts` (`id`) ON DELETE SET NULL,
  CONSTRAINT `fk_notifications_related_report_id` FOREIGN KEY (`related_report_id`) REFERENCES `reports` (`id`) ON DELETE SET NULL,
  CONSTRAINT `ck_notifications_delivery_status` CHECK ((`delivery_status` in (_utf8mb4'PENDING',_utf8mb4'SENT',_utf8mb4'FAILED'))),
  CONSTRAINT `ck_notifications_type` CHECK ((`notification_type` in (_utf8mb4'ANALYSIS_COMPLETED',_utf8mb4'ANALYSIS_FAILED',_utf8mb4'REPORT_COMPLETED',_utf8mb4'NEW_EXPERT_POST',_utf8mb4'COMMENT_CREATED',_utf8mb4'CONSENT_UPDATED',_utf8mb4'RETENTION_NOTICE',_utf8mb4'ACTIVITY_REMINDER',_utf8mb4'RISK_REVIEW_GUIDE',_utf8mb4'EXPERT_VERIFICATION_RESULT')))
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci COMMENT='알림';

CREATE TABLE `post_likes` (
  `id` bigint NOT NULL AUTO_INCREMENT COMMENT '게시글 좋아요 ID',
  `post_id` bigint NOT NULL COMMENT '게시글 ID',
  `user_id` bigint NOT NULL COMMENT '사용자 ID',
  `created_at` datetime(6) NOT NULL DEFAULT CURRENT_TIMESTAMP(6) COMMENT '생성 일시',
  PRIMARY KEY (`id`),
  UNIQUE KEY `uk_post_likes_post_user` (`post_id`,`user_id`),
  KEY `fk_post_likes_user_id` (`user_id`),
  CONSTRAINT `fk_post_likes_post_id` FOREIGN KEY (`post_id`) REFERENCES `community_posts` (`id`) ON DELETE CASCADE,
  CONSTRAINT `fk_post_likes_user_id` FOREIGN KEY (`user_id`) REFERENCES `users` (`id`) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci COMMENT='게시글 좋아요';

CREATE TABLE `report_crisis_alert_resources` (
  `id` bigint NOT NULL AUTO_INCREMENT COMMENT '위기 안내 자원 ID',
  `report_id` bigint NOT NULL COMMENT '리포트 ID',
  `display_order` smallint NOT NULL DEFAULT '0' COMMENT '노출 순서',
  `resource_name` varchar(100) NOT NULL COMMENT '자원 이름',
  `contact` varchar(100) NOT NULL COMMENT '연락처',
  `note` varchar(300) NOT NULL DEFAULT '' COMMENT '보충 설명',
  PRIMARY KEY (`id`),
  UNIQUE KEY `uk_report_crisis_alert_resources_order` (`report_id`,`display_order`),
  CONSTRAINT `fk_report_crisis_alert_resources_report_id` FOREIGN KEY (`report_id`) REFERENCES `report_crisis_alerts` (`report_id`) ON DELETE CASCADE,
  CONSTRAINT `ck_report_crisis_alert_resources_order` CHECK ((`display_order` >= 0))
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci COMMENT='위기 안내 상담·신고 자원';

CREATE TABLE `report_crisis_alert_steps` (
  `id` bigint NOT NULL AUTO_INCREMENT COMMENT '위기 안내 행동 단계 ID',
  `report_id` bigint NOT NULL COMMENT '리포트 ID',
  `display_order` smallint NOT NULL DEFAULT '0' COMMENT '노출 순서',
  `step_text` text NOT NULL COMMENT '보호자가 취할 행동',
  PRIMARY KEY (`id`),
  UNIQUE KEY `uk_report_crisis_alert_steps_order` (`report_id`,`display_order`),
  CONSTRAINT `fk_report_crisis_alert_steps_report_id` FOREIGN KEY (`report_id`) REFERENCES `report_crisis_alerts` (`report_id`) ON DELETE CASCADE,
  CONSTRAINT `ck_report_crisis_alert_steps_order` CHECK ((`display_order` >= 0))
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci COMMENT='위기 안내 행동 단계';

CREATE TABLE `report_crisis_alerts` (
  `report_id` bigint NOT NULL COMMENT '리포트 ID',
  `reason_code` varchar(30) NOT NULL COMMENT '위기 사유 코드',
  `severity` varchar(10) NOT NULL COMMENT '심각도',
  `title` varchar(200) NOT NULL COMMENT '안내 제목',
  `message` text NOT NULL COMMENT '안내 본문',
  PRIMARY KEY (`report_id`),
  CONSTRAINT `fk_report_crisis_alerts_report_id` FOREIGN KEY (`report_id`) REFERENCES `reports` (`id`) ON DELETE CASCADE,
  CONSTRAINT `ck_report_crisis_alerts_reason` CHECK ((`reason_code` in (_utf8mb4'SELF_HARM_RISK',_utf8mb4'CRISIS_INTENT'))),
  CONSTRAINT `ck_report_crisis_alerts_severity` CHECK ((`severity` in (_utf8mb4'HIGH',_utf8mb4'ELEVATED')))
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci COMMENT='리포트 위기 대응 안내';

CREATE TABLE `report_drawn_items` (
  `id` bigint NOT NULL AUTO_INCREMENT COMMENT '리포트 그린 것 ID',
  `report_id` bigint NOT NULL COMMENT '리포트 ID',
  `display_order` smallint NOT NULL DEFAULT '0' COMMENT '노출 순서이며 주제 순서(집→나무→사람)를 보존한다',
  `drawing_subject` varchar(10) DEFAULT NULL COMMENT 'HTP 주제이며 그림일기는 NULL',
  `name` varchar(100) NOT NULL COMMENT '보호자 화면에 그대로 나가는 한국어 표현',
  PRIMARY KEY (`id`),
  UNIQUE KEY `uk_report_drawn_items_report_order` (`report_id`,`display_order`),
  CONSTRAINT `fk_report_drawn_items_report_id` FOREIGN KEY (`report_id`) REFERENCES `reports` (`id`) ON DELETE CASCADE,
  CONSTRAINT `ck_report_drawn_items_order` CHECK ((`display_order` >= 0)),
  CONSTRAINT `ck_report_drawn_items_subject` CHECK (((`drawing_subject` is null) or (`drawing_subject` in (_utf8mb4'HOUSE',_utf8mb4'TREE',_utf8mb4'PERSON'))))
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci COMMENT='리포트 그린 것';

CREATE TABLE `report_evidence_items` (
  `id` bigint NOT NULL AUTO_INCREMENT COMMENT '리포트 근거 ID',
  `report_id` bigint NOT NULL COMMENT '리포트 ID',
  `evidence_number` int NOT NULL COMMENT '리포트 안에서 유일한 근거 번호이며 응답의 evidenceId 로 나간다',
  `source_type` varchar(20) NOT NULL COMMENT '근거 종류',
  `text` text NOT NULL COMMENT '근거 문장',
  `source_ref_kind` varchar(20) DEFAULT NULL COMMENT '원본 근거의 종류이며 파생 근거면 NULL',
  `source_ref_id` varchar(64) DEFAULT NULL COMMENT 'BE 가 발급한 원본 식별자이며 파생 근거면 NULL',
  `stt_needs_confirmation` tinyint(1) NOT NULL DEFAULT '0' COMMENT '음성 인식 확인이 필요한 발화에서 온 근거인지',
  PRIMARY KEY (`id`),
  UNIQUE KEY `uk_report_evidence_items_report_number` (`report_id`,`evidence_number`),
  CONSTRAINT `fk_report_evidence_items_report_id` FOREIGN KEY (`report_id`) REFERENCES `reports` (`id`) ON DELETE CASCADE,
  CONSTRAINT `ck_report_evidence_items_number` CHECK ((`evidence_number` > 0)),
  CONSTRAINT `ck_report_evidence_items_source_ref_kind` CHECK (((`source_ref_kind` is null) or (`source_ref_kind` in (_utf8mb4'QA_ANSWER',_utf8mb4'DETECTED_OBJECT',_utf8mb4'VLM_OBSERVATION',_utf8mb4'EMOTION_SELECTION',_utf8mb4'ACTIVITY_METRIC',_utf8mb4'PRIOR_ACTIVITY')))),
  CONSTRAINT `ck_report_evidence_items_source_ref_pair` CHECK ((((`source_ref_kind` is null) and (`source_ref_id` is null)) or ((`source_ref_kind` is not null) and (`source_ref_id` is not null)))),
  CONSTRAINT `ck_report_evidence_items_source_type` CHECK ((`source_type` in (_utf8mb4'VISION',_utf8mb4'CHILD_ANSWER',_utf8mb4'SELECTED_EMOTION',_utf8mb4'STATED_EMOTION',_utf8mb4'ACTIVITY_METRIC',_utf8mb4'REPEATED_SUBJECT',_utf8mb4'LONGITUDINAL')))
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci COMMENT='리포트 근거';

CREATE TABLE `report_generation_retries` (
  `id` bigint NOT NULL AUTO_INCREMENT COMMENT '재시도 작업 ID',
  `report_id` bigint NOT NULL COMMENT '리포트 ID',
  `analysis_id` bigint NOT NULL COMMENT '최종 분석 ID',
  `attempt_count` smallint NOT NULL DEFAULT '0' COMMENT '지금까지 시도한 횟수',
  `next_attempt_at` datetime(6) NOT NULL COMMENT '다음 시도 예정 시각',
  `last_failure_stage` varchar(40) DEFAULT NULL COMMENT '마지막 실패 단계(AI 호출·응답 검증·저장)',
  `last_failure_code` varchar(100) DEFAULT NULL COMMENT '마지막 실패 분류 코드',
  `correlation_id` char(36) DEFAULT NULL COMMENT '요청을 로그와 잇는 식별자',
  `created_at` datetime(6) NOT NULL DEFAULT CURRENT_TIMESTAMP(6) COMMENT '등록 일시',
  `resolved_at` datetime(6) DEFAULT NULL COMMENT '성공하거나 포기한 시각',
  PRIMARY KEY (`id`),
  UNIQUE KEY `uk_report_generation_retries_report` (`report_id`),
  KEY `idx_report_generation_retries_due` (`resolved_at`,`next_attempt_at`),
  CONSTRAINT `fk_report_generation_retries_report_id` FOREIGN KEY (`report_id`) REFERENCES `reports` (`id`) ON DELETE CASCADE,
  CONSTRAINT `ck_report_generation_retries_attempts` CHECK ((`attempt_count` >= 0))
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci COMMENT='리포트 생성 재시도 대기열';

CREATE TABLE `reports` (
  `id` bigint NOT NULL AUTO_INCREMENT COMMENT '리포트 ID',
  `drawing_session_id` bigint NOT NULL COMMENT '그림 활동 세션 ID',
  `analysis_id` bigint NOT NULL COMMENT '분석 ID',
  `report_version` int NOT NULL DEFAULT '1' COMMENT '리포트 버전',
  `report_status` varchar(20) NOT NULL DEFAULT 'GENERATING' COMMENT '리포트 상태',
  `is_expert_review_recommended` tinyint(1) NOT NULL DEFAULT '0' COMMENT '전문가 검토 권장 여부',
  `limitations_text` text NOT NULL COMMENT '한계 및 주의 문구',
  `failure_reason` varchar(100) DEFAULT NULL COMMENT '리포트 생성 실패 분류 코드',
  `failed_at` datetime(6) DEFAULT NULL COMMENT '리포트 생성 실패 일시',
  `pdf_storage_key` varchar(1000) DEFAULT NULL COMMENT 'PDF 저장 Key',
  `pdf_url` varchar(1000) DEFAULT NULL COMMENT 'PDF URL',
  `pdf_status` varchar(20) NOT NULL DEFAULT 'NONE' COMMENT 'PDF 생성 상태',
  `hidden_at` datetime(6) DEFAULT NULL COMMENT '숨김 일시',
  `created_at` datetime(6) NOT NULL DEFAULT CURRENT_TIMESTAMP(6) COMMENT '리포트 생성 일시',
  `updated_at` datetime(6) NOT NULL DEFAULT CURRENT_TIMESTAMP(6) ON UPDATE CURRENT_TIMESTAMP(6) COMMENT '리포트 수정 일시',
  `has_drawn_items` tinyint(1) NOT NULL DEFAULT '0' COMMENT 'AI drawnItems 필드 저장 여부',
  PRIMARY KEY (`id`),
  UNIQUE KEY `uk_reports_session_version` (`drawing_session_id`,`report_version`),
  KEY `fk_reports_analysis_id` (`analysis_id`),
  KEY `idx_reports_drawing_session_id` (`drawing_session_id`,`created_at`),
  CONSTRAINT `fk_reports_analysis_id` FOREIGN KEY (`analysis_id`) REFERENCES `analyses` (`id`) ON DELETE RESTRICT,
  CONSTRAINT `fk_reports_drawing_session_id` FOREIGN KEY (`drawing_session_id`) REFERENCES `drawing_sessions` (`id`) ON DELETE RESTRICT,
  CONSTRAINT `ck_reports_pdf_status` CHECK ((`pdf_status` in (_utf8mb4'NONE',_utf8mb4'GENERATING',_utf8mb4'READY',_utf8mb4'FAILED'))),
  CONSTRAINT `ck_reports_status` CHECK ((`report_status` in (_utf8mb4'GENERATING',_utf8mb4'COMPLETED',_utf8mb4'FAILED',_utf8mb4'HIDDEN',_utf8mb4'FAILED_RETRYABLE',_utf8mb4'FAILED_FINAL')))
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci COMMENT='리포트';

CREATE TABLE `storage_deletion_jobs` (
  `id` bigint NOT NULL AUTO_INCREMENT COMMENT 'Storage 삭제 작업 ID',
  `storage_key` varchar(1000) NOT NULL COMMENT '삭제 대상 Storage Key',
  `resource_type` varchar(50) NOT NULL COMMENT '연결 Resource 유형',
  `resource_id` bigint DEFAULT NULL COMMENT '연결 Resource ID',
  `deletion_status` varchar(20) NOT NULL DEFAULT 'PENDING' COMMENT '삭제 상태',
  `retry_count` smallint NOT NULL DEFAULT '0' COMMENT '재시도 횟수',
  `error_code` varchar(80) DEFAULT NULL COMMENT '마지막 오류 코드',
  `requested_at` datetime(6) NOT NULL DEFAULT CURRENT_TIMESTAMP(6) COMMENT '삭제 요청 일시',
  `last_attempted_at` datetime(6) DEFAULT NULL COMMENT '마지막 시도 일시',
  `completed_at` datetime(6) DEFAULT NULL COMMENT '삭제 완료 일시',
  `created_at` datetime(6) NOT NULL DEFAULT CURRENT_TIMESTAMP(6) COMMENT '생성 일시',
  `updated_at` datetime(6) NOT NULL DEFAULT CURRENT_TIMESTAMP(6) ON UPDATE CURRENT_TIMESTAMP(6) COMMENT '수정 일시',
  PRIMARY KEY (`id`),
  KEY `idx_storage_deletion_jobs_status_requested_at` (`deletion_status`,`requested_at`),
  KEY `idx_storage_deletion_jobs_resource` (`resource_type`,`resource_id`),
  CONSTRAINT `ck_storage_deletion_jobs_retry_count` CHECK ((`retry_count` >= 0)),
  CONSTRAINT `ck_storage_deletion_jobs_status` CHECK ((`deletion_status` in (_utf8mb4'PENDING',_utf8mb4'PROCESSING',_utf8mb4'COMPLETED',_utf8mb4'FAILED')))
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci COMMENT='Storage 삭제 작업';

CREATE TABLE `stroke_batches` (
  `id` bigint NOT NULL AUTO_INCREMENT COMMENT 'Stroke 배치 ID',
  `drawing_session_id` bigint NOT NULL COMMENT '그림 활동 세션 ID',
  `batch_sequence` int NOT NULL COMMENT '배치 순번',
  `first_event_sequence` bigint NOT NULL COMMENT '첫 이벤트 순번',
  `last_event_sequence` bigint NOT NULL COMMENT '마지막 이벤트 순번',
  `event_count` int NOT NULL COMMENT '이벤트 수',
  `payload_checksum_sha256` char(64) NOT NULL COMMENT '배치 Payload SHA-256 Checksum',
  `undo_count_delta` int NOT NULL DEFAULT '0' COMMENT '실행 취소 증가량',
  `redo_count_delta` int NOT NULL DEFAULT '0' COMMENT '다시 실행 증가량',
  `erase_count_delta` int NOT NULL DEFAULT '0' COMMENT '지우기 증가량',
  `pause_duration_ms_delta` bigint NOT NULL DEFAULT '0' COMMENT '일시 정지 시간 증가량(ms)',
  `client_created_at` datetime(6) DEFAULT NULL COMMENT '클라이언트 생성 일시',
  `received_at` datetime(6) NOT NULL DEFAULT CURRENT_TIMESTAMP(6) COMMENT '수신 일시',
  `created_at` datetime(6) NOT NULL DEFAULT CURRENT_TIMESTAMP(6) COMMENT '생성 일시',
  PRIMARY KEY (`id`),
  UNIQUE KEY `uk_stroke_batches_session_sequence` (`drawing_session_id`,`batch_sequence`),
  CONSTRAINT `fk_stroke_batches_session_id` FOREIGN KEY (`drawing_session_id`) REFERENCES `drawing_sessions` (`id`) ON DELETE CASCADE,
  CONSTRAINT `ck_stroke_batches_event_count` CHECK ((`event_count` > 0)),
  CONSTRAINT `ck_stroke_batches_metric_deltas` CHECK (((`undo_count_delta` >= 0) and (`redo_count_delta` >= 0) and (`erase_count_delta` >= 0) and (`pause_duration_ms_delta` >= 0))),
  CONSTRAINT `ck_stroke_batches_sequence_range` CHECK ((`first_event_sequence` <= `last_event_sequence`))
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci COMMENT='Stroke 배치';

CREATE TABLE `stroke_event_points` (
  `id` bigint NOT NULL AUTO_INCREMENT COMMENT 'Stroke 좌표 ID',
  `stroke_event_id` bigint NOT NULL COMMENT 'Stroke 이벤트 ID',
  `point_sequence` int NOT NULL COMMENT '이벤트 내부 좌표 순번',
  `x` decimal(8,6) NOT NULL COMMENT '정규화 X 좌표',
  `y` decimal(8,6) NOT NULL COMMENT '정규화 Y 좌표',
  `elapsed_ms` bigint NOT NULL COMMENT '이벤트 시작 후 경과 시간(ms)',
  `pressure` decimal(6,5) DEFAULT NULL COMMENT '좌표별 필압',
  PRIMARY KEY (`id`),
  UNIQUE KEY `uk_stroke_event_points_event_sequence` (`stroke_event_id`,`point_sequence`),
  CONSTRAINT `fk_stroke_event_points_event_id` FOREIGN KEY (`stroke_event_id`) REFERENCES `stroke_events` (`id`) ON DELETE CASCADE,
  CONSTRAINT `ck_stroke_event_points_coordinates` CHECK (((`x` >= 0) and (`x` <= 1) and (`y` >= 0) and (`y` <= 1))),
  CONSTRAINT `ck_stroke_event_points_elapsed` CHECK ((`elapsed_ms` >= 0)),
  CONSTRAINT `ck_stroke_event_points_pressure` CHECK (((`pressure` is null) or ((`pressure` >= 0) and (`pressure` <= 1)))),
  CONSTRAINT `ck_stroke_event_points_sequence` CHECK ((`point_sequence` >= 0))
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci COMMENT='Stroke 이벤트 좌표';

CREATE TABLE `stroke_events` (
  `id` bigint NOT NULL AUTO_INCREMENT COMMENT 'Stroke 이벤트 ID',
  `stroke_batch_id` bigint NOT NULL COMMENT 'Stroke 배치 ID',
  `event_sequence` bigint NOT NULL COMMENT '전체 이벤트 순번',
  `event_type` varchar(30) NOT NULL COMMENT '이벤트 유형',
  `tool` varchar(30) DEFAULT NULL COMMENT '그리기 도구',
  `color` char(9) DEFAULT NULL COMMENT '색상 코드',
  `width` decimal(8,3) DEFAULT NULL COMMENT '선 굵기',
  `pressure` decimal(6,5) DEFAULT NULL COMMENT '이벤트 대표 필압',
  `created_at` datetime(6) NOT NULL DEFAULT CURRENT_TIMESTAMP(6) COMMENT '생성 일시',
  PRIMARY KEY (`id`),
  UNIQUE KEY `uk_stroke_events_batch_sequence` (`stroke_batch_id`,`event_sequence`),
  CONSTRAINT `fk_stroke_events_batch_id` FOREIGN KEY (`stroke_batch_id`) REFERENCES `stroke_batches` (`id`) ON DELETE CASCADE,
  CONSTRAINT `ck_stroke_events_pressure` CHECK (((`pressure` is null) or ((`pressure` >= 0) and (`pressure` <= 1)))),
  CONSTRAINT `ck_stroke_events_sequence` CHECK ((`event_sequence` >= 0)),
  CONSTRAINT `ck_stroke_events_width` CHECK (((`width` is null) or (`width` > 0)))
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci COMMENT='Stroke 이벤트';

CREATE TABLE `user_blocks` (
  `id` bigint NOT NULL AUTO_INCREMENT COMMENT '사용자 차단 ID',
  `blocker_user_id` bigint NOT NULL COMMENT '차단한 사용자 ID',
  `blocked_user_id` bigint NOT NULL COMMENT '차단된 사용자 ID',
  `created_at` datetime(6) NOT NULL DEFAULT CURRENT_TIMESTAMP(6) COMMENT '차단 일시',
  PRIMARY KEY (`id`),
  UNIQUE KEY `uk_user_blocks_blocker_blocked` (`blocker_user_id`,`blocked_user_id`),
  KEY `idx_user_blocks_blocked_user_id` (`blocked_user_id`),
  CONSTRAINT `fk_user_blocks_blocked_user_id` FOREIGN KEY (`blocked_user_id`) REFERENCES `users` (`id`) ON DELETE CASCADE,
  CONSTRAINT `fk_user_blocks_blocker_user_id` FOREIGN KEY (`blocker_user_id`) REFERENCES `users` (`id`) ON DELETE CASCADE,
  CONSTRAINT `ck_user_blocks_not_self` CHECK ((`blocker_user_id` <> `blocked_user_id`))
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci COMMENT='사용자 차단';

CREATE TABLE `user_data_retention_settings` (
  `user_id` bigint NOT NULL COMMENT '사용자 ID',
  `retention_days` int NOT NULL DEFAULT '180' COMMENT '데이터 보관 기간(일). 정책 확정 전 잠정값',
  `notice_days_before` int NOT NULL DEFAULT '30' COMMENT '보관 만료 사전 안내 시점(일). 정책 확정 전 잠정값',
  `updated_at` datetime(6) NOT NULL DEFAULT CURRENT_TIMESTAMP(6) ON UPDATE CURRENT_TIMESTAMP(6) COMMENT '수정 일시',
  PRIMARY KEY (`user_id`),
  CONSTRAINT `fk_user_data_retention_settings_user_id` FOREIGN KEY (`user_id`) REFERENCES `users` (`id`) ON DELETE CASCADE,
  CONSTRAINT `ck_user_data_retention_settings_notice_before_expiry` CHECK ((`notice_days_before` < `retention_days`)),
  CONSTRAINT `ck_user_data_retention_settings_notice_days` CHECK ((`notice_days_before` >= 0)),
  CONSTRAINT `ck_user_data_retention_settings_retention_days` CHECK ((`retention_days` > 0))
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci COMMENT='사용자 데이터 보관 설정';

CREATE TABLE `user_guardian_pins` (
  `user_id` bigint NOT NULL COMMENT '보호자 사용자 ID',
  `pin_hash` varchar(255) NOT NULL COMMENT 'pepper 적용 후 BCrypt 해시. 원문 저장 금지',
  `hash_algorithm` varchar(30) NOT NULL COMMENT '해시 알고리즘 식별자',
  `failed_attempt_count` int NOT NULL DEFAULT '0' COMMENT '연속 검증 실패 횟수',
  `lockout_level` int NOT NULL DEFAULT '0' COMMENT '지수 백오프 단계이며 성공 시 0으로 초기화',
  `locked_until` datetime(6) DEFAULT NULL COMMENT '잠금 해제 시각(UTC)이며 잠금 중이 아니면 NULL',
  `last_verified_at` datetime(6) DEFAULT NULL COMMENT '마지막 검증 성공 시각(UTC)',
  `created_at` datetime(6) NOT NULL DEFAULT CURRENT_TIMESTAMP(6) COMMENT '생성 일시',
  `updated_at` datetime(6) NOT NULL DEFAULT CURRENT_TIMESTAMP(6) ON UPDATE CURRENT_TIMESTAMP(6) COMMENT '수정 일시',
  PRIMARY KEY (`user_id`),
  CONSTRAINT `fk_user_guardian_pins_user_id` FOREIGN KEY (`user_id`) REFERENCES `users` (`id`) ON DELETE CASCADE,
  CONSTRAINT `ck_user_guardian_pins_counters` CHECK (((`failed_attempt_count` >= 0) and (`lockout_level` >= 0)))
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci COMMENT='보호자 PIN';

CREATE TABLE `user_notification_settings` (
  `user_id` bigint NOT NULL COMMENT '사용자 ID',
  `analysis_completed` tinyint(1) NOT NULL DEFAULT '1' COMMENT '분석 완료 알림 수신 여부',
  `community` tinyint(1) NOT NULL DEFAULT '1' COMMENT '커뮤니티 알림 수신 여부',
  `service_notice` tinyint(1) NOT NULL DEFAULT '1' COMMENT '서비스 공지 수신 여부',
  `marketing` tinyint(1) NOT NULL DEFAULT '0' COMMENT '마케팅 알림 수신 여부',
  `updated_at` datetime(6) NOT NULL DEFAULT CURRENT_TIMESTAMP(6) ON UPDATE CURRENT_TIMESTAMP(6) COMMENT '수정 일시',
  PRIMARY KEY (`user_id`),
  CONSTRAINT `fk_user_notification_settings_user_id` FOREIGN KEY (`user_id`) REFERENCES `users` (`id`) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci COMMENT='사용자 알림 설정';

CREATE TABLE `users` (
  `id` bigint NOT NULL AUTO_INCREMENT COMMENT '사용자 ID',
  `role` varchar(20) DEFAULT NULL COMMENT '사용자 역할, Onboarding 전에는 NULL',
  `nickname` varchar(50) DEFAULT NULL COMMENT '닉네임',
  `email` varchar(255) DEFAULT NULL COMMENT '사용자 연락 이메일, Onboarding에서 확정',
  `account_status` varchar(20) NOT NULL DEFAULT 'PENDING' COMMENT '계정 상태',
  `profile_image_url` varchar(1000) DEFAULT NULL COMMENT '프로필 이미지 URL',
  `is_completed` tinyint(1) NOT NULL DEFAULT '0' COMMENT '온보딩 완료 여부',
  `last_login_at` datetime(6) DEFAULT NULL COMMENT '마지막 로그인 일시',
  `created_at` datetime(6) NOT NULL DEFAULT CURRENT_TIMESTAMP(6) COMMENT '생성 일시',
  `updated_at` datetime(6) NOT NULL DEFAULT CURRENT_TIMESTAMP(6) ON UPDATE CURRENT_TIMESTAMP(6) COMMENT '수정 일시',
  `deleted_at` datetime(6) DEFAULT NULL COMMENT '삭제 일시',
  PRIMARY KEY (`id`),
  CONSTRAINT `ck_users_account_status` CHECK ((`account_status` in (_utf8mb4'PENDING',_utf8mb4'ACTIVE',_utf8mb4'SUSPENDED',_utf8mb4'DELETED'))),
  CONSTRAINT `ck_users_role` CHECK ((`role` in (_utf8mb4'GUARDIAN',_utf8mb4'EXPERT',_utf8mb4'ADMIN')))
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci COMMENT='사용자';

CREATE TABLE `analysis_results` (
  `analysis_id` BIGINT NOT NULL COMMENT '분석 ID',
  `schema_version` VARCHAR(20) NOT NULL COMMENT '결과 문서 스키마 버전',
  `result_json` JSON NOT NULL COMMENT 'AI 분석 결과 문서',
  `created_at` DATETIME(6) NOT NULL DEFAULT CURRENT_TIMESTAMP(6) COMMENT '생성 일시',
  `updated_at` DATETIME(6) NOT NULL DEFAULT CURRENT_TIMESTAMP(6) ON UPDATE CURRENT_TIMESTAMP(6) COMMENT '수정 일시',
  CONSTRAINT `pk_analysis_results` PRIMARY KEY (`analysis_id`),
  CONSTRAINT `fk_analysis_results_analysis_id` FOREIGN KEY (`analysis_id`) REFERENCES `analyses` (`id`) ON DELETE CASCADE,
  CONSTRAINT `ck_analysis_results_schema_version` CHECK (`schema_version` <> '')
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci COMMENT='버전이 고정된 AI 분석 결과 문서';

CREATE TABLE `report_documents` (
  `report_id` BIGINT NOT NULL COMMENT '리포트 ID',
  `schema_version` VARCHAR(20) NOT NULL COMMENT '리포트 문서 스키마 버전',
  `document_json` JSON NOT NULL COMMENT '보호자용 리포트 스냅샷',
  `content_checksum_sha256` CHAR(64) NOT NULL COMMENT '문서 무결성 검증용 SHA-256',
  `created_at` DATETIME(6) NOT NULL DEFAULT CURRENT_TIMESTAMP(6) COMMENT '생성 일시',
  CONSTRAINT `pk_report_documents` PRIMARY KEY (`report_id`),
  CONSTRAINT `fk_report_documents_report_id` FOREIGN KEY (`report_id`) REFERENCES `reports` (`id`) ON DELETE CASCADE,
  CONSTRAINT `uk_report_documents_checksum` UNIQUE (`report_id`, `content_checksum_sha256`),
  CONSTRAINT `ck_report_documents_schema_version` CHECK (`schema_version` <> '')
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci COMMENT='버전이 고정된 리포트 문서 스냅샷';

CREATE TABLE `report_evidence_relations` (
  `id` BIGINT NOT NULL AUTO_INCREMENT COMMENT '리포트 근거 관계 ID',
  `report_id` BIGINT NOT NULL COMMENT '리포트 ID',
  `source_evidence_item_id` BIGINT NOT NULL COMMENT '출발 근거 항목 ID',
  `relation_type` VARCHAR(30) NOT NULL COMMENT '근거 관계 유형',
  `target_kind` VARCHAR(30) NOT NULL COMMENT '관계를 연결할 문서 요소 유형',
  `target_key` VARCHAR(100) NOT NULL COMMENT '문서 요소 식별 키',
  `display_order` SMALLINT NOT NULL DEFAULT 0 COMMENT '표시 순서',
  CONSTRAINT `pk_report_evidence_relations` PRIMARY KEY (`id`),
  CONSTRAINT `fk_report_evidence_relations_report_id` FOREIGN KEY (`report_id`) REFERENCES `reports` (`id`) ON DELETE CASCADE,
  CONSTRAINT `fk_report_evidence_relations_evidence_id` FOREIGN KEY (`source_evidence_item_id`) REFERENCES `report_evidence_items` (`id`) ON DELETE CASCADE,
  CONSTRAINT `uk_report_evidence_relations_target` UNIQUE (`report_id`, `relation_type`, `target_kind`, `target_key`, `source_evidence_item_id`),
  CONSTRAINT `ck_report_evidence_relations_order` CHECK (`display_order` >= 0),
  CONSTRAINT `ck_report_evidence_relations_type` CHECK (`relation_type` IN ('SUPPORTS', 'DERIVED_FROM', 'REFERENCES')),
  CONSTRAINT `ck_report_evidence_relations_target_kind` CHECK (`target_kind` IN ('INTERPRETATION', 'SUBJECT', 'PARENT_GUIDE', 'REFERENCE'))
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci COMMENT='리포트 문서 요소와 근거 간 추적 관계';
SET FOREIGN_KEY_CHECKS = 1;

