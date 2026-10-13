package com.ssafy.b209.report.service;

import com.fasterxml.jackson.core.JsonProcessingException;
import com.fasterxml.jackson.databind.JsonNode;
import com.fasterxml.jackson.databind.ObjectMapper;
import com.ssafy.b209.auth.authorization.GuardianResourceAccessRepository;
import com.ssafy.b209.drawing.service.DrawingAssetFileUrlFactory;
import com.ssafy.b209.drawing.service.StrokeBehaviorSummary;
import com.ssafy.b209.global.exception.BusinessException;
import com.ssafy.b209.report.domain.Report;
import com.ssafy.b209.report.domain.ReportChildView;
import com.ssafy.b209.report.domain.ReportDocument;
import com.ssafy.b209.report.domain.ReportDrawingAssetView;
import com.ssafy.b209.report.domain.ReportDrawingSessionView;
import com.ssafy.b209.report.domain.ReportDrawingTypeView;
import com.ssafy.b209.report.domain.ReportStatus;
import com.ssafy.b209.report.dto.ObservationGenerationResult;
import com.ssafy.b209.report.dto.ObservationGenerationResult.CrisisAlertDraft;
import com.ssafy.b209.report.dto.ReportActivityFactsResponse;
import com.ssafy.b209.report.dto.ReportChildExpressionResponse;
import com.ssafy.b209.report.dto.ReportConversationSummaryResponse;
import com.ssafy.b209.report.dto.ReportCrisisAlertResponse;
import com.ssafy.b209.report.dto.ReportCrisisResourceResponse;
import com.ssafy.b209.report.dto.ReportDetailResponse;
import com.ssafy.b209.report.dto.ReportDiaryInsightsResponse;
import com.ssafy.b209.report.dto.ReportDiaryInsightsResponse.DiaryTranscriptEntryResponse;
import com.ssafy.b209.report.dto.ReportDocumentPayload;
import com.ssafy.b209.report.dto.ReportDrawingResponse;
import com.ssafy.b209.report.dto.ReportDrawingSessionResponse;
import com.ssafy.b209.report.dto.ReportEvidenceItemResponse;
import com.ssafy.b209.report.dto.ReportExpertReviewResponse;
import com.ssafy.b209.report.dto.ReportObservedFeatureResponse;
import com.ssafy.b209.report.dto.ReportParentGuideResponse;
import com.ssafy.b209.report.dto.ReportPublicInterpretationResponse;
import com.ssafy.b209.report.dto.ReportQaPairResponse;
import com.ssafy.b209.report.dto.ReportReferenceResponse;
import com.ssafy.b209.report.dto.ReportSubjectResponse;
import com.ssafy.b209.report.dto.ReportUtteranceResponse;
import com.ssafy.b209.report.exception.ReportDetailErrorCode;
import com.ssafy.b209.report.repository.ReportChildViewRepository;
import com.ssafy.b209.report.repository.ReportDocumentRepository;
import com.ssafy.b209.report.repository.ReportDrawingAssetViewRepository;
import com.ssafy.b209.report.repository.ReportDrawingSessionViewRepository;
import com.ssafy.b209.report.repository.ReportDrawingTypeViewRepository;
import com.ssafy.b209.report.repository.ReportHtpStepViewRepository;
import com.ssafy.b209.report.repository.ReportRepository;
import com.ssafy.b209.screening.dto.response.ScreeningSummaryResponse;
import com.ssafy.b209.screening.service.ScreeningRecordQueryService;
import java.util.ArrayList;
import java.util.LinkedHashSet;
import java.util.List;
import java.util.Map;
import java.util.Set;
import java.util.function.Function;
import java.util.stream.Collectors;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

/**
 * 보호자용 관찰 리포트 상세 문서를 조회하고 공개 API 응답으로 조립한다.
 *
 * <p>리포트 생성 시점에 안전 검증을 마친 {@link ReportDocument} Snapshot을 정본으로 사용한다. 현재 대화나 분석 테이블을 다시 조합하지 않으므로,
 * 과거 리포트의 의미가 이후 데이터 변경이나 AI 계약 변경으로 달라지지 않는다. 접근 권한과 이미지 URL처럼 조회 시점에 확인해야 하는 정보만 현재 상태에서 보완한다.
 */
@Service
@Transactional(readOnly = true)
public class ReportDetailQueryService {

  private static final Logger log = LoggerFactory.getLogger(ReportDetailQueryService.class);
  private static final String HTP_ACTIVITY_CODE = "HTP";
  private static final Set<String> IMAGE_ASSET_TYPES = Set.of("FINAL", "THUMBNAIL", "UPLOADED");

  private final GuardianResourceAccessRepository guardianAccessRepository;
  private final ReportRepository reportRepository;
  private final ReportDocumentRepository documentRepository;
  private final ReportDrawingSessionViewRepository drawingSessionRepository;
  private final ReportDrawingTypeViewRepository drawingTypeRepository;
  private final ReportDrawingAssetViewRepository assetRepository;
  private final ReportHtpStepViewRepository htpStepRepository;
  private final ReportChildViewRepository childRepository;
  private final DrawingAssetFileUrlFactory fileUrlFactory;
  private final ScreeningRecordQueryService screeningRecordQueryService;
  private final ObjectMapper objectMapper;
  private final boolean aiRawReportExposed;

  /**
   * 리포트 상세 조회에 필요한 상태, 문서, 공개 파일 URL 경계를 구성한다.
   *
   * @param guardianAccessRepository 보호자와 그림 활동의 접근 관계 확인 경계
   * @param reportRepository 리포트 상태 조회 경계
   * @param documentRepository 검증 완료된 리포트 JSON Snapshot 조회 경계
   * @param drawingSessionRepository 그림 활동 세션 조회 경계
   * @param drawingTypeRepository 그림 유형 표시 정보 조회 경계
   * @param assetRepository 최종 그림과 미리보기 자산 조회 경계
   * @param htpStepRepository 여러 HTP 단계를 합친 리포트인지 확인하는 경계
   * @param childRepository 표지에 사용할 아동 별명 조회 경계
   * @param fileUrlFactory JWT 인증이 필요한 그림 파일 상대 URL 생성기
   * @param screeningRecordQueryService 보호자가 기록한 외부 선별 결과 요약 경계
   * @param objectMapper 저장 문서 직렬화 경계
   * @param aiRawReportExposed HTP AI 원문 노출 여부
   */
  public ReportDetailQueryService(
      GuardianResourceAccessRepository guardianAccessRepository,
      ReportRepository reportRepository,
      ReportDocumentRepository documentRepository,
      ReportDrawingSessionViewRepository drawingSessionRepository,
      ReportDrawingTypeViewRepository drawingTypeRepository,
      ReportDrawingAssetViewRepository assetRepository,
      ReportHtpStepViewRepository htpStepRepository,
      ReportChildViewRepository childRepository,
      DrawingAssetFileUrlFactory fileUrlFactory,
      ScreeningRecordQueryService screeningRecordQueryService,
      ObjectMapper objectMapper,
      @Value("${app.report.ai-raw-report.exposed:true}") boolean aiRawReportExposed) {
    this.guardianAccessRepository = guardianAccessRepository;
    this.reportRepository = reportRepository;
    this.documentRepository = documentRepository;
    this.drawingSessionRepository = drawingSessionRepository;
    this.drawingTypeRepository = drawingTypeRepository;
    this.assetRepository = assetRepository;
    this.htpStepRepository = htpStepRepository;
    this.childRepository = childRepository;
    this.fileUrlFactory = fileUrlFactory;
    this.screeningRecordQueryService = screeningRecordQueryService;
    this.objectMapper = objectMapper;
    this.aiRawReportExposed = aiRawReportExposed;
  }

  /**
   * 보호자 접근 권한을 확인하고 저장된 리포트 Snapshot을 상세 응답으로 변환한다.
   *
   * <p>생성 중이거나 실패해 문서가 없는 리포트도 상태 확인이 가능하도록 빈 섹션으로 반환한다. 숨김 리포트는 존재 여부를 노출하지 않는다.
   *
   * @param guardianUserId 인증된 보호자 사용자 식별자
   * @param reportId 조회할 리포트 식별자
   * @return 보호자에게 공개 가능한 리포트 상세
   * @throws BusinessException 리포트가 없거나 숨김이면 {@code REPORT_NOT_FOUND}, 접근 권한이 없으면 {@code
   *     REPORT_ACCESS_DENIED}
   */
  public ReportDetailResponse getReport(Long guardianUserId, Long reportId) {
    Report report =
        reportRepository
            .findById(reportId)
            .orElseThrow(() -> new BusinessException(ReportDetailErrorCode.REPORT_NOT_FOUND));
    if (report.getStatus() == ReportStatus.HIDDEN) {
      throw new BusinessException(ReportDetailErrorCode.REPORT_NOT_FOUND);
    }

    Long drawingSessionId = report.getDrawingSession().getId();
    if (!guardianAccessRepository.hasDrawingSessionAccess(guardianUserId, drawingSessionId)) {
      throw new BusinessException(ReportDetailErrorCode.REPORT_ACCESS_DENIED);
    }
    ReportDrawingSessionView session =
        drawingSessionRepository
            .findById(drawingSessionId)
            .orElseThrow(() -> new BusinessException(ReportDetailErrorCode.REPORT_NOT_FOUND));
    ReportDocumentPayload payload = loadPayload(reportId);
    ObservationGenerationContext context = payload == null ? null : payload.context();
    ObservationGenerationResult result = payload == null ? null : payload.result();
    StrokeBehaviorSummary behavior = payload == null ? null : payload.behaviorSummary();
    String activityType = resolveActivityType(session);

    return new ReportDetailResponse(
        report.getId(),
        report.getReportVersion(),
        report.getStatus().name(),
        buildDrawingSession(session),
        buildDrawing(session.getId()),
        buildChildExpression(session, context),
        buildObservedFeatures(result),
        buildActivityFacts(session, context, result, behavior, drawingSessionId),
        buildConversationSummary(context, result),
        buildGuardianConversationGuide(result),
        splitLimitations(report.getLimitationsText()),
        ReportExpertReviewResponse.notRequested(),
        report.getCreatedAt(),
        ReportDetailResponse.NON_DIAGNOSTIC_NOTICE,
        buildPublicInterpretations(result),
        buildEvidenceItems(result),
        buildSubjectReports(context, result),
        buildParentGuides(result),
        buildCrisisAlert(result),
        buildReferences(result),
        activityType,
        resolveChildDisplayName(session),
        resolveAiRawReport(payload, activityType, reportId),
        buildDiaryInsights(context, result),
        buildScreeningSummary(session));
  }

  private ReportDocumentPayload loadPayload(Long reportId) {
    return documentRepository
        .findById(reportId)
        .map(ReportDocument::getDocumentJson)
        .map(
            document -> {
              try {
                return objectMapper.treeToValue(document, ReportDocumentPayload.class);
              } catch (JsonProcessingException | IllegalArgumentException exception) {
                log.warn("리포트 문서 구조를 읽지 못했습니다. reportId={}", reportId);
                return null;
              }
            })
        .orElse(null);
  }

  private ReportDrawingSessionResponse buildDrawingSession(ReportDrawingSessionView session) {
    ReportDrawingTypeView type =
        drawingTypeRepository.findById(session.getDrawingTypeId()).orElse(null);
    return new ReportDrawingSessionResponse(
        session.getId(),
        session.getChildId(),
        type == null ? null : type.getCode(),
        type == null ? null : type.getName(),
        session.getTitle(),
        session.getInputMethod(),
        session.getStartedAt(),
        session.getCompletedAt(),
        session.durationMs());
  }

  private ReportDrawingResponse buildDrawing(Long drawingSessionId) {
    Map<String, ReportDrawingAssetView> assets = latestAssetsByType(drawingSessionId);
    ReportDrawingAssetView finalAsset = assets.get("FINAL");
    if (finalAsset == null) {
      finalAsset = assets.get("UPLOADED");
    }
    String finalUrl = urlOf(finalAsset);
    String thumbnailUrl = urlOf(assets.get("THUMBNAIL"));
    return new ReportDrawingResponse(finalUrl, thumbnailUrl == null ? finalUrl : thumbnailUrl);
  }

  private Map<String, ReportDrawingAssetView> latestAssetsByType(Long drawingSessionId) {
    return assetRepository
        .findByDrawingSessionIdAndAssetTypeInOrderByAssetVersionAsc(
            drawingSessionId, IMAGE_ASSET_TYPES)
        .stream()
        .collect(
            Collectors.toMap(
                ReportDrawingAssetView::getAssetType,
                Function.identity(),
                (older, newer) -> newer));
  }

  private String resolveFinalImageUrl(Long drawingSessionId) {
    if (drawingSessionId == null) {
      return null;
    }
    return buildDrawing(drawingSessionId).finalImageUrl();
  }

  private String urlOf(ReportDrawingAssetView asset) {
    return asset == null ? null : fileUrlFactory.create(asset.getId());
  }

  private ReportChildExpressionResponse buildChildExpression(
      ReportDrawingSessionView session, ObservationGenerationContext context) {
    if (context == null) {
      return new ReportChildExpressionResponse(
          List.of(), session.getExpressedEmotionText(), List.of());
    }
    List<ReportUtteranceResponse> utterances =
        safe(context.keyConversations()).stream()
            .filter(line -> !line.sttNeedsConfirmation())
            .map(
                line ->
                    new ReportUtteranceResponse(
                        line.answerMessageId(),
                        line.answerText(),
                        isVoice(line.answerType()) ? "STT" : "TEXT",
                        false))
            .toList();
    return new ReportChildExpressionResponse(
        safe(context.selectedEmotions()), context.expressedEmotionText(), utterances);
  }

  private List<ReportObservedFeatureResponse> buildObservedFeatures(
      ObservationGenerationResult result) {
    if (result == null
        || result.observationDraft() == null
        || !"AI_REVIEWED".equals(result.observationDraft().status())) {
      return List.of();
    }
    return safe(result.observationDraft().features()).stream()
        .filter(feature -> "REVIEWED_GUARDIAN".equals(feature.visibilityScope()))
        .filter(feature -> feature.description() != null && !feature.description().isBlank())
        .map(
            feature ->
                new ReportObservedFeatureResponse(
                    feature.title(), feature.description(), feature.evidenceSummary()))
        .toList();
  }

  private ReportActivityFactsResponse buildActivityFacts(
      ReportDrawingSessionView session,
      ObservationGenerationContext context,
      ObservationGenerationResult result,
      StrokeBehaviorSummary behavior,
      Long drawingSessionId) {
    List<String> drawnItems =
        result == null
            ? List.of()
            : result.drawnItemsOrEmpty().stream()
                .map(ObservationGenerationResult.DrawnItemDraft::name)
                .filter(name -> name != null && !name.isBlank())
                .toList();
    Long drawingDurationMs = behavior == null ? null : behavior.drawingDurationMs();
    boolean aggregatedHtp = htpStepRepository.countStepsSharingAssessment(drawingSessionId) > 1;
    return new ReportActivityFactsResponse(
        drawnItems,
        drawingDurationMs,
        behavior == null ? null : behavior.pauseCount(),
        behavior == null ? null : behavior.eraseCount(),
        behavior != null && behavior.pressureAvailable(),
        result == null ? List.of() : safe(result.activityNotes()),
        ReportActivityFactsResponse.toSeconds(session.durationMs()),
        ReportActivityFactsResponse.toSeconds(drawingDurationMs),
        behavior == null ? null : behavior.undoCount(),
        context == null ? null : context.questionCount(),
        context == null ? null : context.answeredCount(),
        context == null ? null : context.skippedCount(),
        drawnItems.size(),
        null,
        behavior != null && behavior.truncated(),
        aggregatedHtp);
  }

  private ReportConversationSummaryResponse buildConversationSummary(
      ObservationGenerationContext context, ObservationGenerationResult result) {
    String summary =
        result == null || result.conversationSummary() == null
            ? null
            : result.conversationSummary().summaryText();
    return new ReportConversationSummaryResponse(
        context == null ? null : context.questionCount(),
        context == null ? null : context.answeredCount(),
        context == null ? null : context.skippedCount(),
        summary);
  }

  private List<String> buildGuardianConversationGuide(ObservationGenerationResult result) {
    if (result == null) {
      return List.of();
    }
    LinkedHashSet<String> guides = new LinkedHashSet<>();
    safe(result.followUpGuides()).stream()
        .map(ObservationGenerationResult.FollowUpGuideDraft::guidance)
        .filter(ReportDetailQueryService::hasText)
        .forEach(guides::add);
    safe(result.guardianQuestions()).stream()
        .map(ObservationGenerationResult.GuardianQuestionDraft::questionText)
        .filter(ReportDetailQueryService::hasText)
        .forEach(guides::add);
    return List.copyOf(guides);
  }

  private List<ReportPublicInterpretationResponse> buildPublicInterpretations(
      ObservationGenerationResult result) {
    if (result == null) {
      return List.of();
    }
    return result.publicInterpretations().stream()
        .map(
            card ->
                new ReportPublicInterpretationResponse(
                    card.category(),
                    card.title(),
                    card.tendencyText(),
                    card.scopeText(),
                    card.homeObservationGuide(),
                    card.evidenceRefs().stream().map(Long::intValue).toList(),
                    card.confidence()))
        .toList();
  }

  private List<ReportEvidenceItemResponse> buildEvidenceItems(ObservationGenerationResult result) {
    if (result == null) {
      return List.of();
    }
    Set<Long> referenced =
        result.publicInterpretations().stream()
            .flatMap(card -> card.evidenceRefs().stream())
            .collect(Collectors.toSet());
    return result.evidenceItems().stream()
        .filter(item -> referenced.contains(item.evidenceId()))
        .map(
            item ->
                new ReportEvidenceItemResponse(
                    item.evidenceId().intValue(), item.sourceType(), item.text()))
        .toList();
  }

  private List<ReportSubjectResponse> buildSubjectReports(
      ObservationGenerationContext context, ObservationGenerationResult result) {
    if (result == null) {
      return List.of();
    }
    Map<String, ObservationGenerationContext.SubjectContext> contexts =
        context == null
            ? Map.of()
            : safe(context.subjectContexts()).stream()
                .filter(subject -> subject.drawingSubject() != null)
                .collect(
                    Collectors.toMap(
                        ObservationGenerationContext.SubjectContext::drawingSubject,
                        Function.identity(),
                        (first, ignored) -> first));
    List<ReportSubjectResponse> subjects = new ArrayList<>();
    for (ObservationGenerationResult.SubjectReportDraft subject : result.subjectReports()) {
      ObservationGenerationContext.SubjectContext subjectContext =
          contexts.get(subject.subjectType());
      List<ReportQaPairResponse> qaPairs =
          subjectContext == null
              ? List.of()
              : safe(subjectContext.qaPairs()).stream().map(this::toQaPair).toList();
      subjects.add(
          new ReportSubjectResponse(
              subject.subjectType(),
              subjectContext == null
                  ? null
                  : resolveFinalImageUrl(subjectContext.drawingSessionId()),
              subject.visionObservations(),
              qaPairs,
              subject.interpretationRefs()));
    }
    return subjects;
  }

  private ReportQaPairResponse toQaPair(ObservationGenerationContext.KeyConversationLine line) {
    boolean answered = hasText(line.answerText());
    return new ReportQaPairResponse(
        line.questionText(),
        line.answerText(),
        answered ? "ANSWERED" : "SKIPPED",
        isVoice(line.answerType()) ? "VOICE" : "TEXT",
        line.sttNeedsConfirmation(),
        answered && !line.sttNeedsConfirmation());
  }

  private List<ReportParentGuideResponse> buildParentGuides(ObservationGenerationResult result) {
    if (result == null) {
      return List.of();
    }
    return result.parentGuides().stream()
        .map(guide -> new ReportParentGuideResponse(guide.guideType(), guide.items()))
        .toList();
  }

  private ReportCrisisAlertResponse buildCrisisAlert(ObservationGenerationResult result) {
    CrisisAlertDraft alert = result == null ? null : result.crisisAlert();
    if (alert == null) {
      return null;
    }
    return new ReportCrisisAlertResponse(
        alert.reasonCode(),
        alert.severity(),
        alert.title(),
        alert.message(),
        alert.actionSteps(),
        alert.resources().stream()
            .map(
                resource ->
                    new ReportCrisisResourceResponse(
                        resource.name(), resource.contact(), resource.note()))
            .toList());
  }

  private List<ReportReferenceResponse> buildReferences(ObservationGenerationResult result) {
    if (result == null) {
      return List.of();
    }
    return result.ragReferences().stream()
        .map(reference -> new ReportReferenceResponse(reference.title(), null))
        .toList();
  }

  private ReportDiaryInsightsResponse buildDiaryInsights(
      ObservationGenerationContext context, ObservationGenerationResult result) {
    if (result == null || result.diaryInsights() == null) {
      return null;
    }
    ReportDiaryInsightsResponse converted =
        objectMapper.convertValue(result.diaryInsights(), ReportDiaryInsightsResponse.class);
    List<DiaryTranscriptEntryResponse> transcript =
        context == null
            ? List.of()
            : safe(context.keyConversations()).stream().map(this::toTranscriptEntry).toList();
    return new ReportDiaryInsightsResponse(
        converted.storySnapshot(),
        converted.narrativeFlow(),
        converted.childVoiceItems(),
        converted.sessionObservations(),
        converted.caregiverQuestions(),
        converted.listeningTip(),
        converted.developmentalObservations(),
        converted.unknownItems(),
        converted.dataQuality(),
        converted.schemaVersion(),
        converted.dataScope(),
        converted.storyComponents(),
        converted.drawingObservations(),
        transcript);
  }

  private DiaryTranscriptEntryResponse toTranscriptEntry(
      ObservationGenerationContext.KeyConversationLine line) {
    String audioUrl =
        line.audioAvailableAtGeneration() && line.answerMessageId() != null
            ? "/api/v1/conversation-messages/" + line.answerMessageId() + "/audio"
            : null;
    return new DiaryTranscriptEntryResponse(
        line.questionMessageId(),
        line.answerMessageId(),
        line.questionText(),
        line.answerText(),
        hasText(line.answerText()) ? (isVoice(line.answerType()) ? "VOICE" : "TEXT") : "SKIPPED",
        line.speechStatus(),
        null,
        audioUrl != null,
        audioUrl,
        null,
        line.answerCreatedAt());
  }

  private JsonNode resolveAiRawReport(
      ReportDocumentPayload payload, String activityType, Long reportId) {
    if (!aiRawReportExposed
        || !HTP_ACTIVITY_CODE.equalsIgnoreCase(activityType)
        || payload == null
        || !hasText(payload.rawJson())) {
      return null;
    }
    try {
      return objectMapper.readTree(payload.rawJson());
    } catch (JsonProcessingException exception) {
      log.warn("리포트 AI 원문을 JSON으로 읽지 못했습니다. reportId={}", reportId);
      return null;
    }
  }

  private String resolveActivityType(ReportDrawingSessionView session) {
    return drawingTypeRepository
        .findById(session.getDrawingTypeId())
        .map(ReportDrawingTypeView::getCode)
        .orElse(null);
  }

  private String resolveChildDisplayName(ReportDrawingSessionView session) {
    return childRepository
        .findById(session.getChildId())
        .map(ReportChildView::displayName)
        .orElse(null);
  }

  private ScreeningSummaryResponse buildScreeningSummary(ReportDrawingSessionView session) {
    return session.getChildId() == null
        ? null
        : screeningRecordQueryService.summarize(session.getChildId());
  }

  private List<String> splitLimitations(String limitationsText) {
    if (limitationsText == null) {
      return List.of();
    }
    return limitationsText.lines().map(String::strip).filter(line -> !line.isEmpty()).toList();
  }

  private static boolean isVoice(String answerType) {
    return answerType != null && answerType.toUpperCase().contains("VOICE");
  }

  private static boolean hasText(String value) {
    return value != null && !value.isBlank();
  }

  private static <T> List<T> safe(List<T> values) {
    return values == null ? List.of() : values;
  }
}
