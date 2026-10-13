package com.ssafy.b209.report.dto;

import com.ssafy.b209.drawing.service.StrokeBehaviorSummary;
import com.ssafy.b209.report.service.ObservationGenerationContext;

/**
 * 리포트 생성 시점의 입력과 검증된 결과를 함께 보존하는 내부 문서 계약이다.
 *
 * <p>외부 API DTO가 아니며 {@code schemaVersion}을 기준으로만 역직렬화한다. 이후 AI 계약이 바뀌더라도 과거 리포트는 이 Snapshot으로
 * 재현하고, 현재 DB 상태로 내용을 다시 생성하지 않는다.
 *
 * @param schemaVersion 내부 문서 구조 버전
 * @param context 리포트 생성에 사용한 서버 확정 입력 Snapshot
 * @param result 계약 검증과 공개 안전 검증을 마친 생성 결과
 * @param behaviorSummary 저장된 Stroke 배치 집계이며 수집하지 못했으면 {@code null}
 * @param rawJson AI 응답 원문이며 보관하지 않았으면 {@code null}
 */
public record ReportDocumentPayload(
    String schemaVersion,
    ObservationGenerationContext context,
    ObservationGenerationResult result,
    StrokeBehaviorSummary behaviorSummary,
    String rawJson) {}
