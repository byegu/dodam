package com.ssafy.b209.analysis.repository;

import com.fasterxml.jackson.core.JsonProcessingException;
import com.fasterxml.jackson.databind.JsonNode;
import com.fasterxml.jackson.databind.ObjectMapper;
import com.fasterxml.jackson.databind.node.ArrayNode;
import com.fasterxml.jackson.databind.node.ObjectNode;
import com.ssafy.b209.infrastructure.ai.drawing.contract.AiDrawingAnalysisResponse;
import java.time.LocalDateTime;
import java.util.List;
import java.util.Optional;
import org.springframework.jdbc.core.JdbcTemplate;
import org.springframework.stereotype.Repository;

/**
 * 분석 실행의 확장 결과를 하나의 버전 있는 JSON 문서로 저장한다.
 *
 * <p>분석 상태와 객체 탐지는 각각 {@code analyses}, {@code analysis_detected_objects}가 담당한다. 모델 정보, 시각·행동 특징,
 * 대화 요약, 관찰 초안, 근거와 경고처럼 AI 계약에 따라 함께 변하는 값은 {@code analysis_results.result_json}에 원자적으로 교체해 정규화
 * 테이블 간 부분 저장을 방지한다.
 */
@Repository
public class AnalysisResultJdbcRepository {

  private static final String SCHEMA_VERSION = "1.0";

  private final JdbcTemplate jdbcTemplate;
  private final ObjectMapper objectMapper;

  /**
   * 분석 결과 문서 저장에 필요한 JDBC 접근자와 JSON 변환기를 주입받는다.
   *
   * @param jdbcTemplate Spring이 관리하는 JDBC 접근자
   * @param objectMapper 애플리케이션 공통 Jackson 설정이 적용된 JSON 변환기
   */
  public AnalysisResultJdbcRepository(JdbcTemplate jdbcTemplate, ObjectMapper objectMapper) {
    this.jdbcTemplate = jdbcTemplate;
    this.objectMapper = objectMapper;
  }

  /**
   * 분석 식별자에 연결된 결과 문서를 AI 서버의 검증된 정본 응답으로 교체한다.
   *
   * <p>호출 Service의 Transaction에 참여하므로 분석 상태·객체 탐지와 이 문서는 함께 Commit되거나 함께 Rollback된다.
   *
   * @param analysisId 결과를 소유하는 분석 식별자
   * @param response AI 서버의 검증된 정본 응답
   * @param occurredAt Spring Boot가 응답 처리를 완료한 시각
   */
  public void replace(
      Long analysisId, AiDrawingAnalysisResponse response, LocalDateTime occurredAt) {
    replaceDocument(analysisId, objectMapper.valueToTree(response), occurredAt);
  }

  /**
   * 분석 식별자의 확장 결과를 이미 검증된 JSON 문서로 교체한다.
   *
   * <p>관찰 리포트처럼 종합 분석 응답과 구조가 다른 결과도 같은 저장 경계를 사용하되, 호출부가 계약 검증을 마친 문서만 전달해야 한다.
   *
   * @param analysisId 결과를 소유하는 분석 식별자
   * @param document 저장할 JSON 문서
   * @param occurredAt 결과를 확정한 시각
   */
  public void replaceDocument(Long analysisId, JsonNode document, LocalDateTime occurredAt) {
    String json = write(document);
    jdbcTemplate.update(
        "INSERT INTO analysis_results "
            + "(analysis_id, schema_version, result_json, created_at, updated_at) "
            + "VALUES (?, ?, CAST(? AS JSON), ?, ?) "
            + "ON DUPLICATE KEY UPDATE schema_version = VALUES(schema_version), "
            + "result_json = CASE "
            + "WHEN JSON_CONTAINS_PATH(VALUES(result_json), 'one', '$.serverUnusedInputs') "
            + "THEN VALUES(result_json) "
            + "WHEN JSON_CONTAINS_PATH(result_json, 'one', '$.serverUnusedInputs') "
            + "THEN JSON_SET(VALUES(result_json), '$.serverUnusedInputs', "
            + "JSON_EXTRACT(result_json, '$.serverUnusedInputs')) "
            + "ELSE VALUES(result_json) END, updated_at = VALUES(updated_at)",
        analysisId,
        SCHEMA_VERSION,
        json,
        occurredAt,
        occurredAt);
  }

  /**
   * 분석 입력에서 제외한 자료를 기존 결과 문서의 서버 확정 이력에 덧붙인다.
   *
   * <p>기존 AI 응답의 {@code unusedInputs}를 덮어쓰지 않고 {@code serverUnusedInputs}에 별도로 저장한다. 행을 잠근 뒤 문서를
   * 교체하므로 동시에 추가된 제외 이력이 유실되지 않는다.
   *
   * @param analysisId 제외 이력을 소유하는 분석 식별자
   * @param inputs 제외한 입력 목록이며 비어 있으면 아무 변경도 하지 않는다
   * @param occurredAt 제외를 확정한 시각
   */
  public void appendUnusedInputs(
      Long analysisId, List<UnusedAnalysisInput> inputs, LocalDateTime occurredAt) {
    if (inputs == null || inputs.isEmpty()) {
      return;
    }
    ObjectNode document =
        jdbcTemplate
            .query(
                "SELECT result_json FROM analysis_results WHERE analysis_id = ? FOR UPDATE",
                (resultSet, rowNum) -> readObject(resultSet.getString(1)),
                analysisId)
            .stream()
            .findFirst()
            .orElseGet(objectMapper::createObjectNode);
    ArrayNode history =
        document.has("serverUnusedInputs") && document.get("serverUnusedInputs").isArray()
            ? (ArrayNode) document.get("serverUnusedInputs")
            : document.putArray("serverUnusedInputs");
    for (UnusedAnalysisInput input : inputs) {
      ObjectNode item = history.addObject();
      item.put("sourceType", input.sourceType());
      putNullable(item, "sourceId", input.sourceId());
      putNullable(item, "inputName", input.inputName());
      item.put("reasonCode", input.reasonCode());
      putNullable(item, "reasonDetail", input.reasonDetail());
      item.put("retryable", input.retryable());
      item.put("occurredAt", occurredAt.toString());
    }
    replaceDocument(analysisId, document, occurredAt);
  }

  /**
   * 질문 생성에 사용할 최신 그림 관찰 서술을 조회한다.
   *
   * @param analysisId 근거 분석 식별자
   * @return 관찰 서술이 존재하고 비어 있지 않으면 해당 문자열
   */
  public Optional<String> findLatestOverallSummary(Long analysisId) {
    return jdbcTemplate
        .query(
            "SELECT JSON_UNQUOTE(JSON_EXTRACT(result_json, "
                + "'$.observationDraft.overallSummary')) "
                + "FROM analysis_results WHERE analysis_id = ?",
            (resultSet, rowNum) -> resultSet.getString(1),
            analysisId)
        .stream()
        .filter(value -> value != null && !value.isBlank())
        .findFirst();
  }

  /**
   * 그림 활동 세션에 속한 분석 중 관찰 서술이 있는 최신 결과를 찾는다.
   *
   * @param drawingSessionId 그림 활동 세션 식별자
   * @return 최신 분석 식별자와 관찰 서술
   */
  public Optional<LatestObservation> findLatestObservationByDrawingSessionId(
      Long drawingSessionId) {
    return jdbcTemplate
        .query(
            "SELECT ar.analysis_id, JSON_UNQUOTE(JSON_EXTRACT(ar.result_json, "
                + "'$.observationDraft.overallSummary')) AS overall_summary "
                + "FROM analysis_results ar JOIN analyses a ON a.id = ar.analysis_id "
                + "WHERE a.drawing_session_id = ? "
                + "AND JSON_UNQUOTE(JSON_EXTRACT(ar.result_json, "
                + "'$.observationDraft.overallSummary')) IS NOT NULL "
                + "ORDER BY ar.analysis_id DESC LIMIT 1",
            (resultSet, rowNum) ->
                new LatestObservation(
                    resultSet.getLong("analysis_id"), resultSet.getString("overall_summary")),
            drawingSessionId)
        .stream()
        .findFirst();
  }

  /**
   * 최신 관찰 문서를 가리키는 최소 조회 결과다.
   *
   * @param analysisId 관찰 문서를 소유한 분석 식별자
   * @param overallSummary 그림 관찰 서술
   */
  public record LatestObservation(Long analysisId, String overallSummary) {}

  private String write(JsonNode document) {
    try {
      return objectMapper.writeValueAsString(document);
    } catch (JsonProcessingException exception) {
      throw new IllegalStateException("analysis result JSON serialization failed", exception);
    }
  }

  private ObjectNode readObject(String json) {
    try {
      JsonNode node = objectMapper.readTree(json);
      if (node == null || !node.isObject()) {
        throw new IllegalStateException("analysis result JSON must be an object");
      }
      return (ObjectNode) node;
    } catch (JsonProcessingException exception) {
      throw new IllegalStateException("analysis result JSON parsing failed", exception);
    }
  }

  private static void putNullable(ObjectNode node, String field, Object value) {
    if (value == null) {
      node.putNull(field);
    } else {
      node.put(field, value.toString());
    }
  }
}
