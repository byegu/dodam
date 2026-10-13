package com.ssafy.b209.report.service;

import com.fasterxml.jackson.databind.JsonNode;
import com.fasterxml.jackson.databind.ObjectMapper;
import com.ssafy.b209.analysis.domain.DrawingAnalysis;
import com.ssafy.b209.analysis.domain.DrawingCoordinateSpace;
import com.ssafy.b209.analysis.domain.DrawingDetectedObject;
import com.ssafy.b209.analysis.repository.AnalysisResultJdbcRepository;
import com.ssafy.b209.analysis.repository.DrawingAnalysisRepository;
import com.ssafy.b209.conversation.domain.ConversationSession;
import com.ssafy.b209.conversation.dto.KeyConversationSource;
import com.ssafy.b209.conversation.repository.ConversationMessageRepository;
import com.ssafy.b209.conversation.repository.ConversationSessionRepository;
import com.ssafy.b209.drawing.domain.DrawingSession;
import com.ssafy.b209.drawing.domain.DrawingSessionEmotion;
import com.ssafy.b209.drawing.htp.domain.HtpAssessment;
import com.ssafy.b209.drawing.htp.domain.HtpAssessmentStep;
import com.ssafy.b209.drawing.htp.repository.HtpAssessmentRepository;
import com.ssafy.b209.drawing.repository.DrawingSessionEmotionRepository;
import com.ssafy.b209.drawing.service.StrokeBehaviorSummary;
import com.ssafy.b209.drawing.service.StrokeBehaviorSummaryService;
import com.ssafy.b209.global.exception.BusinessException;
import com.ssafy.b209.global.support.ColumnTextLimiter;
import com.ssafy.b209.report.domain.Report;
import com.ssafy.b209.report.domain.ReportCrisisAlert;
import com.ssafy.b209.report.domain.ReportDocument;
import com.ssafy.b209.report.domain.ReportDrawnItem;
import com.ssafy.b209.report.domain.ReportEvidenceItem;
import com.ssafy.b209.report.domain.ReportEvidenceSourceKind;
import com.ssafy.b209.report.domain.ReportEvidenceSourceRef;
import com.ssafy.b209.report.domain.ReportEvidenceSourceType;
import com.ssafy.b209.report.domain.ReportStatus;
import com.ssafy.b209.report.dto.ObservationGeneration;
import com.ssafy.b209.report.dto.ObservationGenerationResult;
import com.ssafy.b209.report.dto.ReportDocumentPayload;
import com.ssafy.b209.report.exception.MockObservationReportErrorCode;
import com.ssafy.b209.report.repository.ReportCrisisAlertRepository;
import com.ssafy.b209.report.repository.ReportDocumentRepository;
import com.ssafy.b209.report.repository.ReportDrawnItemRepository;
import com.ssafy.b209.report.repository.ReportEvidenceItemRepository;
import com.ssafy.b209.report.repository.ReportRepository;
import com.ssafy.b209.report.safety.InterpretationCandidate;
import com.ssafy.b209.report.safety.InterpretationSafetyOutcome;
import com.ssafy.b209.report.safety.InterpretationSafetyVerifier;
import java.nio.charset.StandardCharsets;
import java.security.MessageDigest;
import java.security.NoSuchAlgorithmException;
import java.time.Clock;
import java.time.LocalDate;
import java.time.LocalDateTime;
import java.util.ArrayList;
import java.util.Comparator;
import java.util.HashMap;
import java.util.HashSet;
import java.util.HexFormat;
import java.util.List;
import java.util.Locale;
import java.util.Map;
import java.util.Optional;
import java.util.Set;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.context.ApplicationEventPublisher;
import org.springframework.dao.DataIntegrityViolationException;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Propagation;
import org.springframework.transaction.annotation.Transactional;

/**
 * 관찰 리포트 생성 입력과 검증된 결과를 버전 있는 문서로 저장하고 관련 상태를 전이한다.
 *
 * <p>변경 주기가 큰 리포트 본문은 {@code report_documents.document_json}에 한 번에 저장한다. 상태·감사·검색에 필요한 핵심 행은 관계형
 * 테이블에 유지하며, AI 호출은 이 클래스 밖에서 수행한다. 같은 생성 건을 다시 완료하면 아무 변경 없이 종료한다.
 */
@Service
public class ObservationReportPersistenceService {

  private static final Logger log =
      LoggerFactory.getLogger(ObservationReportPersistenceService.class);
  private static final String DOCUMENT_SCHEMA_VERSION = "1.0";
  private static final int MAX_KEY_CONVERSATIONS = 5;
  private static final int MODEL_NAME_LIMIT = 100;
  private static final int MODEL_VERSION_LIMIT = 255;
  private static final int ANALYSIS_ERROR_CODE_LIMIT = 80;
  private static final int REPORT_FAILURE_REASON_LIMIT = 100;
  private static final String FAILED_LIMITATIONS = "리포트 생성에 실패했습니다. 잠시 후 다시 시도해 주세요.";

  private final DrawingAnalysisRepository analysisRepository;
  private final AnalysisResultJdbcRepository analysisResultRepository;
  private final ReportRepository reportRepository;
  private final ReportDocumentRepository reportDocumentRepository;
  private final ReportDrawnItemRepository drawnItemRepository;
  private final ReportEvidenceItemRepository evidenceItemRepository;
  private final ReportCrisisAlertRepository crisisAlertRepository;
  private final InterpretationSafetyVerifier safetyVerifier;
  private final InterpretationCandidateAdapter candidateAdapter;
  private final ConversationSessionRepository conversationSessionRepository;
  private final ConversationMessageRepository conversationMessageRepository;
  private final DrawingSessionEmotionRepository emotionRepository;
  private final HtpAssessmentRepository htpAssessmentRepository;
  private final StrokeBehaviorSummaryService behaviorSummaryService;
  private final ApplicationEventPublisher eventPublisher;
  private final ObjectMapper objectMapper;
  private final Clock clock;

  /**
   * 리포트 Snapshot 생성과 핵심 관계형 기록에 필요한 경계를 주입받는다.
   *
   * @param analysisRepository 최종 분석 저장소
   * @param analysisResultRepository 분석 확장 결과 문서 저장소
   * @param reportRepository 리포트 상태 저장소
   * @param reportDocumentRepository 리포트 상세 문서 저장소
   * @param drawnItemRepository 보호자 화면에 노출하는 그린 것 감사 저장소
   * @param evidenceItemRepository 리포트 근거 감사 저장소
   * @param crisisAlertRepository 위기 대응 안내 저장소
   * @param safetyVerifier 경향 해석 공개 안전 검증기
   * @param candidateAdapter AI 응답을 안전 검증 입력으로 옮기는 Adapter
   * @param conversationSessionRepository 대화 세션 저장소
   * @param conversationMessageRepository 대화 집계와 문답 Snapshot 저장소
   * @param emotionRepository 아동 선택 감정 저장소
   * @param htpAssessmentRepository HTP 세 단계 조회와 상태 전이 저장소
   * @param behaviorSummaryService Stroke 행동 수치 집계 경계
   * @param eventPublisher 완료·실패 후속 처리 이벤트 발행기
   * @param objectMapper 공통 JSON 변환기
   * @param clock 저장 시각을 제공하는 시계
   */
  public ObservationReportPersistenceService(
      DrawingAnalysisRepository analysisRepository,
      AnalysisResultJdbcRepository analysisResultRepository,
      ReportRepository reportRepository,
      ReportDocumentRepository reportDocumentRepository,
      ReportDrawnItemRepository drawnItemRepository,
      ReportEvidenceItemRepository evidenceItemRepository,
      ReportCrisisAlertRepository crisisAlertRepository,
      InterpretationSafetyVerifier safetyVerifier,
      InterpretationCandidateAdapter candidateAdapter,
      ConversationSessionRepository conversationSessionRepository,
      ConversationMessageRepository conversationMessageRepository,
      DrawingSessionEmotionRepository emotionRepository,
      HtpAssessmentRepository htpAssessmentRepository,
      StrokeBehaviorSummaryService behaviorSummaryService,
      ApplicationEventPublisher eventPublisher,
      ObjectMapper objectMapper,
      Clock clock) {
    this.analysisRepository = analysisRepository;
    this.analysisResultRepository = analysisResultRepository;
    this.reportRepository = reportRepository;
    this.reportDocumentRepository = reportDocumentRepository;
    this.drawnItemRepository = drawnItemRepository;
    this.evidenceItemRepository = evidenceItemRepository;
    this.crisisAlertRepository = crisisAlertRepository;
    this.safetyVerifier = safetyVerifier;
    this.candidateAdapter = candidateAdapter;
    this.conversationSessionRepository = conversationSessionRepository;
    this.conversationMessageRepository = conversationMessageRepository;
    this.emotionRepository = emotionRepository;
    this.htpAssessmentRepository = htpAssessmentRepository;
    this.behaviorSummaryService = behaviorSummaryService;
    this.eventPublisher = eventPublisher;
    this.objectMapper = objectMapper;
    this.clock = clock;
  }

  /**
   * 생성 대상 분석과 리포트가 처리 가능한 상태이면 AI 호출에 필요한 불변 맥락을 조회한다.
   *
   * @param analysisId 최종 분석 식별자
   * @return 처리 가능한 생성 맥락이며 대상이 없거나 이미 완료됐으면 빈 값
   */
  @Transactional(readOnly = true, propagation = Propagation.REQUIRES_NEW)
  public Optional<ObservationGenerationContext> loadContext(Long analysisId) {
    Optional<DrawingAnalysis> analysisOptional = analysisRepository.findById(analysisId);
    if (analysisOptional.isEmpty() || !analysisOptional.get().isPending()) {
      return Optional.empty();
    }
    DrawingAnalysis analysis = analysisOptional.get();
    Optional<Report> reportOptional = reportRepository.findByAnalysisId(analysisId);
    if (reportOptional.isEmpty() || reportOptional.get().getStatus() != ReportStatus.GENERATING) {
      return Optional.empty();
    }
    DrawingSession session = analysis.getDrawingSession();
    Long drawingSessionId = session.getId();
    List<ObservationGenerationContext.ActivitySessionRef> contextSessions =
        htpAssessmentRepository
            .findStepByDrawingSessionId(drawingSessionId)
            .map(
                step ->
                    step.getAssessment().getSteps().stream()
                        .sorted(Comparator.comparingInt(HtpAssessmentStep::getStepOrder))
                        .map(
                            htpStep ->
                                new ObservationGenerationContext.ActivitySessionRef(
                                    htpStep.getDrawingSession().getId(),
                                    htpStep.getDrawingSubject().name()))
                        .toList())
            .orElseGet(
                () ->
                    List.of(
                        new ObservationGenerationContext.ActivitySessionRef(
                            drawingSessionId, null)));
    List<Long> contextSessionIds =
        contextSessions.stream()
            .map(ObservationGenerationContext.ActivitySessionRef::drawingSessionId)
            .toList();
    ConversationSession representativeConversation =
        conversationSessionRepository.findByDrawingSessionId(drawingSessionId).orElse(null);

    int questionCount = 0;
    int answeredCount = 0;
    int skippedCount = 0;
    int unrecognizedSpeechCount = 0;
    List<ObservationGenerationContext.KeyConversationLine> keyConversations = new ArrayList<>();
    List<ObservationGenerationContext.SubjectContext> subjectContexts = new ArrayList<>();
    for (ObservationGenerationContext.ActivitySessionRef contextSession : contextSessions) {
      Long contextSessionId = contextSession.drawingSessionId();
      List<ObservationGenerationContext.KeyConversationLine> subjectQaPairs = new ArrayList<>();
      ConversationSession conversation =
          conversationSessionRepository.findByDrawingSessionId(contextSessionId).orElse(null);
      if (conversation != null) {
        Long conversationId = conversation.getId();
        questionCount += (int) conversationMessageRepository.countQuestions(conversationId);
        answeredCount += (int) conversationMessageRepository.countAnswered(conversationId);
        skippedCount += (int) conversationMessageRepository.countSkipped(conversationId);
        unrecognizedSpeechCount +=
            (int) conversationMessageRepository.countUnrecognizedSpeech(conversationId);
        for (KeyConversationSource source :
            conversationMessageRepository.findKeyConversationSources(conversationId)) {
          ObservationGenerationContext.KeyConversationLine line =
              new ObservationGenerationContext.KeyConversationLine(
                  source.getQuestionMessageId(),
                  source.getQuestionText(),
                  source.getAnswerMessageId(),
                  source.getAnswerText(),
                  source.getAnswerType(),
                  source.getAnswerNeedsGuardianConfirmation(),
                  source.getAnswerSpeechStatus(),
                  Integer.valueOf(1).equals(source.getAnswerAudioAvailable()),
                  source.getAnswerCreatedAt());
          subjectQaPairs.add(line);
          if (keyConversations.size() < MAX_KEY_CONVERSATIONS) {
            keyConversations.add(line);
          }
        }
      }

      AnalysisResultJdbcRepository.LatestObservation observation =
          analysisResultRepository
              .findLatestObservationByDrawingSessionId(contextSessionId)
              .orElse(null);
      List<DrawingDetectedObject> detections =
          observation == null
              ? List.of()
              : analysisRepository
                  .findById(observation.analysisId())
                  .map(DrawingAnalysis::getDetections)
                  .orElse(List.of());
      List<String> objectCodes = detections.stream().map(DrawingDetectedObject::getLabel).toList();
      List<ObservationGenerationContext.DetectedObjectRef> detectedObjects =
          detections.stream()
              .filter(ObservationReportPersistenceService::isNormalized)
              .map(
                  detection ->
                      new ObservationGenerationContext.DetectedObjectRef(
                          detection.getId(),
                          detection.getLabel(),
                          detection.getX(),
                          detection.getY(),
                          detection.getWidth(),
                          detection.getHeight(),
                          detection.getAreaRatio(),
                          detection.getConfidence()))
              .toList();
      String description = observation == null ? null : observation.overallSummary();
      if (description != null || !objectCodes.isEmpty() || !subjectQaPairs.isEmpty()) {
        subjectContexts.add(
            new ObservationGenerationContext.SubjectContext(
                contextSession.drawingSubject(),
                description,
                objectCodes,
                subjectQaPairs,
                observation == null ? null : observation.analysisId(),
                detectedObjects,
                contextSessionId));
      }
    }

    List<DrawingSessionEmotion> emotionSources =
        contextSessionIds.size() == 1
            ? emotionRepository.findAllByDrawingSessionIdOrderBySelectionOrderAscIdAsc(
                drawingSessionId)
            : emotionRepository
                .findByDrawingSessionIdInOrderByDrawingSessionIdAscSelectionOrderAscIdAsc(
                    contextSessionIds);
    List<ObservationGenerationContext.SelectedEmotionRef> emotionRefs =
        emotionSources.stream()
            .map(
                emotion ->
                    new ObservationGenerationContext.SelectedEmotionRef(
                        emotion.getId(), emotion.getEmotionCode().name()))
            .toList();
    return Optional.of(
        new ObservationGenerationContext(
            analysisId,
            drawingSessionId,
            reportOptional.get().getId(),
            representativeConversation == null ? null : representativeConversation.getId(),
            representativeConversation == null
                ? null
                : representativeConversation.getDifficultySnapshot(),
            questionCount,
            answeredCount,
            skippedCount,
            unrecognizedSpeechCount,
            emotionRefs.stream()
                .map(ObservationGenerationContext.SelectedEmotionRef::emotionCode)
                .toList(),
            session.getExpressedEmotionText(),
            keyConversations,
            subjectContexts,
            emotionRefs,
            contextSessions,
            childAgeOf(session),
            ageMonthsOf(session),
            educationStageOf(session)));
  }

  /**
   * 검증된 관찰 결과를 문서와 핵심 감사 행에 저장하고 분석·리포트 상태를 완료로 전이한다.
   *
   * @param context 생성 맥락
   * @param generation AI Client가 반환한 계약 결과와 응답 원문
   * @throws BusinessException 대상이 사라졌거나 저장 충돌이 발생한 경우
   */
  @Transactional(propagation = Propagation.REQUIRES_NEW)
  public void complete(ObservationGenerationContext context, ObservationGeneration generation) {
    DrawingAnalysis analysis =
        analysisRepository
            .findByIdForUpdate(context.analysisId())
            .orElseThrow(
                () -> new BusinessException(MockObservationReportErrorCode.ANALYSIS_NOT_FOUND));
    if (!analysis.isPending()) {
      return;
    }
    Report report =
        reportRepository
            .findByIdForUpdate(context.reportId())
            .orElseThrow(
                () -> new BusinessException(MockObservationReportErrorCode.REPORT_NOT_FOUND));
    if (report.getStatus() != ReportStatus.GENERATING) {
      return;
    }

    LocalDateTime now = LocalDateTime.now(clock);
    ObservationGenerationResult safeResult = filterForGuardian(generation.result());
    StrokeBehaviorSummary behaviorSummary = aggregateBehavior(context);
    try {
      analysis.succeedFinal(
          ColumnTextLimiter.fit(safeResult.modelName(), MODEL_NAME_LIMIT, "analyses.model_name"),
          ColumnTextLimiter.fit(
              safeResult.modelVersion(), MODEL_VERSION_LIMIT, "analyses.model_version"),
          safeResult.confidence(),
          now);
      ReportDocumentPayload payload =
          new ReportDocumentPayload(
              DOCUMENT_SCHEMA_VERSION,
              context,
              safeResult,
              behaviorSummary,
              normalizeRawJson(generation.rawJson()));
      JsonNode document = objectMapper.valueToTree(payload);
      reportDocumentRepository.save(
          ReportDocument.create(
              report.getId(), DOCUMENT_SCHEMA_VERSION, document, sha256(document), now));
      analysisResultRepository.replaceDocument(
          analysis.getId(), objectMapper.valueToTree(safeResult), now);
      saveAuditRows(report, safeResult);
      report.complete(
          safeResult.observationDraft().expertReviewRequired(), safeResult.limitationsText(), now);
      htpAssessmentRepository
          .findByStepDrawingSessionIdForUpdate(analysis.getDrawingSession().getId())
          .ifPresent(assessment -> assessment.completeAnalysis(now));
      eventPublisher.publishEvent(new AnalysisCompletedEvent(report.getId()));
    } catch (DataIntegrityViolationException exception) {
      throw new BusinessException(
          MockObservationReportErrorCode.REPORT_STORAGE_CONFLICT, exception);
    }
  }

  /**
   * 생성 또는 저장 실패를 대기 중 분석과 생성 중 리포트에 기록한다.
   *
   * @param analysisId 최종 분석 식별자
   * @param reportId 리포트 식별자이며 없으면 {@code null}
   * @param failureCode 원문을 포함하지 않는 실패 분류 코드
   * @param failureMessage 외부에 노출해도 되는 안전한 실패 메시지
   */
  @Transactional(propagation = Propagation.REQUIRES_NEW)
  public void markFailed(
      Long analysisId, Long reportId, String failureCode, String failureMessage) {
    markFailed(analysisId, reportId, failureCode, failureMessage, ReportStatus.FAILED_FINAL);
  }

  /**
   * 실패를 재시도 가능 여부와 함께 기록한다.
   *
   * @param analysisId 최종 분석 식별자
   * @param reportId 리포트 식별자이며 없으면 {@code null}
   * @param failureCode 원문을 포함하지 않는 실패 분류 코드
   * @param failureMessage 외부에 노출해도 되는 안전한 실패 메시지
   * @param failureStatus 재시도 가능 여부를 나타내는 리포트 실패 상태
   */
  @Transactional(propagation = Propagation.REQUIRES_NEW)
  public void markFailed(
      Long analysisId,
      Long reportId,
      String failureCode,
      String failureMessage,
      ReportStatus failureStatus) {
    LocalDateTime now = LocalDateTime.now(clock);
    analysisRepository
        .findByIdForUpdate(analysisId)
        .filter(DrawingAnalysis::isPending)
        .ifPresent(
            analysis -> {
              analysis.failFinal(
                  ColumnTextLimiter.fit(
                      failureCode, ANALYSIS_ERROR_CODE_LIMIT, "analyses.error_code"),
                  failureMessage,
                  now);
              htpAssessmentRepository
                  .findByStepDrawingSessionIdForUpdate(analysis.getDrawingSession().getId())
                  .ifPresent(HtpAssessment::failAnalysis);
            });
    if (reportId == null) {
      return;
    }
    reportRepository
        .findByIdForUpdate(reportId)
        .filter(report -> report.getStatus() == ReportStatus.GENERATING)
        .ifPresent(
            report -> {
              report.fail(
                  FAILED_LIMITATIONS,
                  ColumnTextLimiter.fit(
                      failureCode, REPORT_FAILURE_REASON_LIMIT, "reports.failure_reason"),
                  now,
                  failureStatus);
              if (failureStatus == ReportStatus.FAILED_FINAL) {
                eventPublisher.publishEvent(new ReportGenerationFailedEvent(reportId));
              }
            });
  }

  private ObservationGenerationResult filterForGuardian(ObservationGenerationResult result) {
    List<InterpretationCandidate> candidates =
        candidateAdapter.toCandidates(result.publicInterpretations());
    InterpretationSafetyOutcome outcome =
        safetyVerifier.verify(
            candidates, candidateAdapter.toEvidenceCandidates(result.evidenceItems()));
    List<ObservationGenerationResult.PublicInterpretationDraft> published =
        outcome.published().stream()
            .map(InterpretationSafetyOutcome.PublishedInterpretation::candidate)
            .map(ObservationReportPersistenceService::toDraft)
            .toList();
    Map<Integer, Integer> publishedIndex = new HashMap<>();
    Set<Long> evidenceNumbers = new HashSet<>();
    for (int index = 0; index < outcome.published().size(); index++) {
      InterpretationSafetyOutcome.PublishedInterpretation item = outcome.published().get(index);
      publishedIndex.put(item.sourceIndex(), index);
      evidenceNumbers.addAll(item.candidate().evidenceRefs());
    }
    List<ObservationGenerationResult.EvidenceItemDraft> evidence =
        result.evidenceItems().stream()
            .filter(item -> item != null && evidenceNumbers.contains(item.evidenceId()))
            .toList();
    List<ObservationGenerationResult.SubjectReportDraft> subjects =
        result.subjectReports().stream()
            .map(
                subject ->
                    new ObservationGenerationResult.SubjectReportDraft(
                        subject.subjectType(),
                        subject.visionObservations(),
                        subject.interpretationRefs().stream()
                            .map(publishedIndex::get)
                            .filter(java.util.Objects::nonNull)
                            .toList()))
            .toList();
    ObservationGenerationResult.CrisisAlertDraft crisis =
        result.crisisAlert() != null
                && ReportCrisisAlert.isStorableReason(result.crisisAlert().reasonCode())
            ? result.crisisAlert()
            : null;
    return new ObservationGenerationResult(
        result.requestId(),
        result.modelName(),
        result.modelVersion(),
        result.confidence(),
        result.observationDraft(),
        result.conversationSummary(),
        result.activityNotes(),
        result.followUpGuides(),
        result.guardianQuestions(),
        result.limitationsText(),
        result.drawnItems(),
        published,
        evidence,
        result.parentGuides(),
        crisis,
        subjects,
        result.ragReferences(),
        result.diaryInsights());
  }

  private static ObservationGenerationResult.PublicInterpretationDraft toDraft(
      InterpretationCandidate candidate) {
    return new ObservationGenerationResult.PublicInterpretationDraft(
        candidate.category().name(),
        candidate.title(),
        candidate.tendencyText(),
        candidate.scopeText(),
        candidate.homeObservationGuide(),
        candidate.evidenceRefs(),
        candidate.confidence() == null ? null : candidate.confidence().name());
  }

  private void saveAuditRows(Report report, ObservationGenerationResult result) {
    if (result.hasDrawnItems()) {
      List<ReportDrawnItem> items = new ArrayList<>();
      int order = 0;
      for (ObservationGenerationResult.DrawnItemDraft item : result.drawnItemsOrEmpty()) {
        if (item != null
            && item.name() != null
            && !item.name().isBlank()
            && item.name().codePointCount(0, item.name().length())
                <= ReportDrawnItem.DISPLAY_NAME_MAX_CODE_POINTS) {
          items.add(ReportDrawnItem.create(report, order++, item.drawingSubject(), item.name()));
        }
      }
      drawnItemRepository.saveAll(items);
      report.markDrawnItemsStored();
    }
    List<ReportEvidenceItem> evidenceItems = new ArrayList<>();
    for (ObservationGenerationResult.EvidenceItemDraft evidence : result.evidenceItems()) {
      ReportEvidenceItem item = toEvidence(report, evidence);
      if (item != null) {
        evidenceItems.add(item);
      }
    }
    evidenceItemRepository.saveAll(evidenceItems);
    saveCrisisAlert(report, result.crisisAlert());
  }

  private ReportEvidenceItem toEvidence(
      Report report, ObservationGenerationResult.EvidenceItemDraft evidence) {
    if (evidence == null || evidence.evidenceId() == null || evidence.text() == null) {
      return null;
    }
    ReportEvidenceSourceType sourceType =
        parseEnum(ReportEvidenceSourceType.class, evidence.sourceType());
    if (sourceType == null) {
      return null;
    }
    int number = evidence.evidenceId().intValue();
    try {
      if (evidence.sourceRef() != null) {
        ReportEvidenceSourceKind kind =
            parseEnum(ReportEvidenceSourceKind.class, evidence.sourceRef().kind());
        return kind == null
            ? null
            : ReportEvidenceItem.original(
                report,
                number,
                sourceType,
                evidence.text(),
                kind,
                evidence.sourceRef().id(),
                evidence.sttNeedsConfirmation());
      }
      List<ReportEvidenceSourceRef> origins =
          evidence.derivedFrom().stream()
              .map(
                  ref -> {
                    ReportEvidenceSourceKind kind =
                        parseEnum(ReportEvidenceSourceKind.class, ref.kind());
                    return kind == null || ref.id() == null
                        ? null
                        : new ReportEvidenceSourceRef(kind, ref.id());
                  })
              .filter(java.util.Objects::nonNull)
              .toList();
      return origins.isEmpty()
          ? null
          : ReportEvidenceItem.derived(
              report,
              number,
              sourceType,
              evidence.text(),
              origins,
              evidence.sttNeedsConfirmation());
    } catch (IllegalArgumentException exception) {
      return null;
    }
  }

  private void saveCrisisAlert(Report report, ObservationGenerationResult.CrisisAlertDraft draft) {
    if (draft == null || !ReportCrisisAlert.isStorableReason(draft.reasonCode())) {
      return;
    }
    try {
      ReportCrisisAlert alert =
          ReportCrisisAlert.create(
              report, draft.reasonCode(), draft.severity(), draft.title(), draft.message());
      draft.actionSteps().stream()
          .filter(value -> value != null && !value.isBlank())
          .forEach(alert::addStep);
      draft.resources().stream()
          .filter(java.util.Objects::nonNull)
          .forEach(
              resource -> alert.addResource(resource.name(), resource.contact(), resource.note()));
      crisisAlertRepository.save(alert);
    } catch (IllegalArgumentException exception) {
      log.warn("허용하지 않는 위기 안내를 리포트 문서에서 제외했습니다. reportId={}", report.getId());
    }
  }

  private StrokeBehaviorSummary aggregateBehavior(ObservationGenerationContext context) {
    List<Long> sessionIds = context.activitySessionIds();
    if (sessionIds == null || sessionIds.isEmpty()) {
      sessionIds = List.of(context.drawingSessionId());
    }
    try {
      return behaviorSummaryService.summarizeAll(sessionIds).orElse(null);
    } catch (RuntimeException exception) {
      log.warn(
          "그리기 행동 수치 집계에 실패해 리포트에 수치를 남기지 않습니다. reportId={}, exceptionType={}",
          context.reportId(),
          exception.getClass().getName());
      return null;
    }
  }

  private static boolean isNormalized(DrawingDetectedObject detection) {
    return detection.getCoordinateSpace() == DrawingCoordinateSpace.NORMALIZED
        && detection.getX() != null
        && detection.getY() != null
        && detection.getWidth() != null
        && detection.getHeight() != null;
  }

  private Integer childAgeOf(DrawingSession session) {
    return session.getChild() == null ? null : session.getChild().ageOn(LocalDate.now(clock));
  }

  private Integer ageMonthsOf(DrawingSession session) {
    return session.getChild() == null ? null : session.getChild().ageMonthsOn(LocalDate.now(clock));
  }

  private String educationStageOf(DrawingSession session) {
    return session.getChild() == null || session.getChild().getEducationStage() == null
        ? null
        : session.getChild().getEducationStage().name();
  }

  private String sha256(JsonNode document) {
    try {
      byte[] bytes = objectMapper.writeValueAsString(document).getBytes(StandardCharsets.UTF_8);
      return HexFormat.of().formatHex(MessageDigest.getInstance("SHA-256").digest(bytes));
    } catch (NoSuchAlgorithmException exception) {
      throw new IllegalStateException("SHA-256 is not available", exception);
    } catch (com.fasterxml.jackson.core.JsonProcessingException exception) {
      throw new IllegalStateException("report document JSON serialization failed", exception);
    }
  }

  private static String normalizeRawJson(String rawJson) {
    return rawJson == null || rawJson.isBlank() ? null : rawJson;
  }

  private static <E extends Enum<E>> E parseEnum(Class<E> type, String value) {
    if (value == null || value.isBlank()) {
      return null;
    }
    try {
      return Enum.valueOf(type, value.trim().toUpperCase(Locale.ROOT));
    } catch (IllegalArgumentException exception) {
      return null;
    }
  }
}
