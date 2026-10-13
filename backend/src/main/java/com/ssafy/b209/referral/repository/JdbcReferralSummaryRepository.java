package com.ssafy.b209.referral.repository;

import com.fasterxml.jackson.core.JsonProcessingException;
import com.fasterxml.jackson.databind.ObjectMapper;
import com.ssafy.b209.report.domain.ReportDocument;
import com.ssafy.b209.report.dto.ObservationGenerationResult;
import com.ssafy.b209.report.dto.ReportDocumentPayload;
import com.ssafy.b209.report.repository.ReportDocumentRepository;
import java.time.LocalDate;
import java.util.ArrayList;
import java.util.LinkedHashMap;
import java.util.List;
import java.util.Map;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.jdbc.core.JdbcTemplate;
import org.springframework.stereotype.Repository;

/**
 * 상담 의뢰 요약에 필요한 활동 헤더와 확정 리포트 Snapshot을 읽는다.
 *
 * <p>별도 의뢰 요약 테이블을 만들지 않고, 리포트 생성 시점에 안전 검증을 마친 {@code report_documents} 내용을 사용한다. 현재 원자료를 다시 해석하지
 * 않으므로 보호자가 확인한 리포트와 상담용 요약의 내용이 어긋나지 않는다.
 */
@Repository
public class JdbcReferralSummaryRepository {

  private static final Logger log = LoggerFactory.getLogger(JdbcReferralSummaryRepository.class);

  private final JdbcTemplate jdbcTemplate;
  private final ReportDocumentRepository documentRepository;
  private final ObjectMapper objectMapper;

  /**
   * 상담 의뢰 요약의 관계형 헤더와 JSON 문서 조회 경계를 구성한다.
   *
   * @param jdbcTemplate 활동과 리포트 헤더를 조회할 JDBC Template
   * @param documentRepository 확정 리포트 문서 저장소
   * @param objectMapper 리포트 문서 역직렬화 경계
   */
  public JdbcReferralSummaryRepository(
      JdbcTemplate jdbcTemplate,
      ReportDocumentRepository documentRepository,
      ObjectMapper objectMapper) {
    this.jdbcTemplate = jdbcTemplate;
    this.documentRepository = documentRepository;
    this.objectMapper = objectMapper;
  }

  /**
   * 아이의 완료된 최근 활동을 최신순으로 읽고 그림일기 핵심 내용을 결합한다.
   *
   * @param childId 아동 식별자
   * @param limit 가져올 최대 회차 수
   * @return 최신순 활동 목록
   */
  public List<ReferralSessionRow> findRecentSessions(Long childId, int limit) {
    List<SessionHeader> headers =
        jdbcTemplate.query(
            """
            select report.id as report_id,
                   type.code as activity_type,
                   date(session.started_at) as activity_date
              from reports report
              join drawing_sessions session on session.id = report.drawing_session_id
              join drawing_types type on type.id = session.drawing_type_id
              join report_documents document on document.report_id = report.id
             where session.child_id = ?
               and report.report_status = 'COMPLETED'
             order by session.started_at desc, report.id desc
             limit ?
            """,
            (rs, rowNum) ->
                new SessionHeader(
                    rs.getLong("report_id"),
                    rs.getString("activity_type"),
                    rs.getObject("activity_date", LocalDate.class)),
            childId,
            limit);
    Map<Long, ReportDocumentPayload> documents =
        loadDocuments(headers.stream().map(SessionHeader::reportId).toList());
    return headers.stream()
        .map(header -> toSessionRow(header, documents.get(header.reportId())))
        .toList();
  }

  /**
   * 지정 리포트에서 보호자에게 공개된 아이 발화를 읽는다.
   *
   * @param reportIds 리포트 식별자 목록
   * @return 입력 리포트 순서와 문서 내 발화 순서를 유지한 목록
   */
  public List<ReferralChildVoiceRow> findChildVoices(List<Long> reportIds) {
    Map<Long, ReportDocumentPayload> documents = loadDocuments(reportIds);
    List<ReferralChildVoiceRow> rows = new ArrayList<>();
    for (Long reportId : reportIds) {
      ReportDocumentPayload payload = documents.get(reportId);
      ObservationGenerationResult result = payload == null ? null : payload.result();
      if (result == null || result.diaryInsights() == null) {
        continue;
      }
      result.diaryInsights().childVoiceItems().stream()
          .map(
              voice ->
                  new ReferralChildVoiceRow(
                      reportId,
                      voice.text(),
                      voice.elicitationType(),
                      voice.answerType(),
                      voice.sttNeedsConfirmation()))
          .forEach(rows::add);
    }
    return rows;
  }

  /**
   * 지정 리포트에서 이번 활동에 한정된 관찰 항목을 읽는다.
   *
   * @param reportIds 리포트 식별자 목록
   * @return 입력 리포트 순서와 문서 내 관찰 순서를 유지한 목록
   */
  public List<ReferralObservationRow> findObservations(List<Long> reportIds) {
    Map<Long, ReportDocumentPayload> documents = loadDocuments(reportIds);
    List<ReferralObservationRow> rows = new ArrayList<>();
    for (Long reportId : reportIds) {
      ReportDocumentPayload payload = documents.get(reportId);
      ObservationGenerationResult result = payload == null ? null : payload.result();
      if (result == null || result.diaryInsights() == null) {
        continue;
      }
      result.diaryInsights().sessionObservations().stream()
          .map(
              observation ->
                  new ReferralObservationRow(
                      reportId, observation.observationCode(), observation.title()))
          .forEach(rows::add);
    }
    return rows;
  }

  /**
   * 지정 리포트의 사전 검토된 안전 안내를 읽는다.
   *
   * @param reportIds 리포트 식별자 목록
   * @return 리포트별 안전 신호 목록
   */
  public List<ReferralSafetySignalRow> findSafetySignals(List<Long> reportIds) {
    if (reportIds.isEmpty()) {
      return List.of();
    }
    String placeholders = String.join(",", reportIds.stream().map(id -> "?").toList());
    return jdbcTemplate.query(
        "select report_id, reason_code, severity, title from report_crisis_alerts where report_id in ("
            + placeholders
            + ") order by report_id desc",
        (rs, rowNum) ->
            new ReferralSafetySignalRow(
                rs.getLong("report_id"),
                rs.getString("reason_code"),
                rs.getString("severity"),
                rs.getString("title")),
        reportIds.toArray());
  }

  private ReferralSessionRow toSessionRow(SessionHeader header, ReportDocumentPayload payload) {
    ObservationGenerationResult.DiaryInsightsDraft diary =
        payload == null || payload.result() == null ? null : payload.result().diaryInsights();
    ObservationGenerationResult.DiaryStorySnapshotDraft story =
        diary == null ? null : diary.storySnapshot();
    ObservationGenerationResult.DiaryDataQualityDraft quality =
        diary == null ? null : diary.dataQuality();
    return new ReferralSessionRow(
        header.reportId(),
        header.activityType(),
        header.activityDate(),
        story == null ? null : story.headline(),
        story == null ? null : story.mainEvent(),
        story == null ? null : story.realityStatus(),
        story == null ? null : story.timeScope(),
        quality == null ? 0 : quality.confirmedVoiceCount(),
        quality == null ? 0 : quality.optionAnswerCount(),
        quality == null ? 0 : quality.skippedCount(),
        quality == null ? 0 : quality.sttConfirmationCount());
  }

  private Map<Long, ReportDocumentPayload> loadDocuments(List<Long> reportIds) {
    if (reportIds.isEmpty()) {
      return Map.of();
    }
    Map<Long, ReportDocumentPayload> documents = new LinkedHashMap<>();
    for (ReportDocument document : documentRepository.findAllById(reportIds)) {
      try {
        documents.put(
            document.getReportId(),
            objectMapper.treeToValue(document.getDocumentJson(), ReportDocumentPayload.class));
      } catch (JsonProcessingException | IllegalArgumentException exception) {
        log.warn("상담 의뢰용 리포트 문서를 읽지 못했습니다. reportId={}", document.getReportId());
      }
    }
    return documents;
  }

  private record SessionHeader(Long reportId, String activityType, LocalDate activityDate) {}

  /**
   * 상담 의뢰 요약에 사용하는 활동 한 회차의 공개 원자료다.
   *
   * @param reportId 출처 리포트 식별자
   * @param activityType 활동 유형 코드
   * @param activityDate 활동 날짜
   * @param headline 그림일기 이야기 제목
   * @param mainEvent 아이가 설명한 중심 사건
   * @param realityStatus 이야기의 사실성 구분
   * @param timeScope 이야기의 시간 범위
   * @param confirmedVoiceCount 확정된 음성 답변 수
   * @param optionAnswerCount 선택형 답변 수
   * @param skippedCount 건너뛴 질문 수
   * @param sttConfirmationCount STT 확인이 필요한 답변 수
   */
  public record ReferralSessionRow(
      Long reportId,
      String activityType,
      LocalDate activityDate,
      String headline,
      String mainEvent,
      String realityStatus,
      String timeScope,
      int confirmedVoiceCount,
      int optionAnswerCount,
      int skippedCount,
      int sttConfirmationCount) {}

  /**
   * 상담 의뢰 요약에 포함할 아이 발화 한 줄이다.
   *
   * @param reportId 출처 리포트 식별자
   * @param text 보호자에게 공개 가능한 아이 발화
   * @param elicitationType 발화를 이끈 질문 유형
   * @param answerType 답변 입력 유형
   * @param sttNeedsConfirmation STT 결과 확인 필요 여부
   */
  public record ReferralChildVoiceRow(
      Long reportId,
      String text,
      String elicitationType,
      String answerType,
      boolean sttNeedsConfirmation) {}

  /**
   * 상담 의뢰 요약에 포함할 활동 한정 관찰 한 건이다.
   *
   * @param reportId 출처 리포트 식별자
   * @param observationCode 관찰 항목 코드
   * @param title 보호자에게 공개된 관찰 제목
   */
  public record ReferralObservationRow(Long reportId, String observationCode, String title) {}

  /**
   * 상담 의뢰 요약에 포함할 사전 검토된 안전 신호 한 건이다.
   *
   * @param reportId 출처 리포트 식별자
   * @param reasonCode 안전 신호 사유 코드
   * @param severity 심각도
   * @param title 보호자에게 공개된 안전 신호 제목
   */
  public record ReferralSafetySignalRow(
      Long reportId, String reasonCode, String severity, String title) {}
}
