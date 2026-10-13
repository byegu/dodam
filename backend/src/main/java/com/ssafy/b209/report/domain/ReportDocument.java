package com.ssafy.b209.report.domain;

import com.fasterxml.jackson.databind.JsonNode;
import jakarta.persistence.Column;
import jakarta.persistence.Entity;
import jakarta.persistence.Id;
import jakarta.persistence.Table;
import java.time.LocalDateTime;
import java.util.Objects;
import org.hibernate.annotations.JdbcTypeCode;
import org.hibernate.type.SqlTypes;

/**
 * 보호자용 리포트의 버전 있는 상세 문서를 보관한다.
 *
 * <p>{@link Report}가 생성 상태와 접근 기준을 관리하고, 이 Entity는 AI 계약과 함께 변하는 상세 내용을 단일 JSON Snapshot으로 보존한다. 공개
 * 응답은 저장 전에 안전 검증을 통과한 문서만 사용해야 하며, 생성 이후 원문을 다시 해석해 기존 리포트가 달라지지 않게 한다.
 */
@Entity
@Table(name = "report_documents")
public class ReportDocument {

  @Id
  @Column(name = "report_id")
  private Long reportId;

  @Column(name = "schema_version", nullable = false, length = 20)
  private String schemaVersion;

  @JdbcTypeCode(SqlTypes.JSON)
  @Column(name = "document_json", nullable = false, columnDefinition = "json")
  private JsonNode documentJson;

  @Column(
      name = "content_checksum_sha256",
      nullable = false,
      length = 64,
      columnDefinition = "char(64)")
  private String documentChecksumSha256;

  @Column(name = "created_at", nullable = false)
  private LocalDateTime createdAt;

  /** JPA가 Entity를 복원할 때 사용하는 생성자다. */
  protected ReportDocument() {}

  private ReportDocument(
      Long reportId,
      String schemaVersion,
      JsonNode documentJson,
      String documentChecksumSha256,
      LocalDateTime createdAt) {
    this.reportId = Objects.requireNonNull(reportId, "reportId must not be null");
    this.schemaVersion = requireText(schemaVersion, "schemaVersion");
    this.documentJson = requireDocumentObject(documentJson);
    this.documentChecksumSha256 = requireSha256(documentChecksumSha256);
    this.createdAt = Objects.requireNonNull(createdAt, "createdAt must not be null");
  }

  /**
   * 검증과 직렬화를 마친 리포트 문서를 생성한다.
   *
   * @param reportId 문서가 속한 리포트 식별자
   * @param schemaVersion 문서 구조 버전
   * @param documentJson 저장할 불변 리포트 Snapshot
   * @param documentChecksumSha256 UTF-8 JSON bytes의 SHA-256 checksum
   * @param createdAt 문서를 확정한 시각
   * @return 저장 가능한 리포트 문서
   */
  public static ReportDocument create(
      Long reportId,
      String schemaVersion,
      JsonNode documentJson,
      String documentChecksumSha256,
      LocalDateTime createdAt) {
    return new ReportDocument(
        reportId, schemaVersion, documentJson, documentChecksumSha256, createdAt);
  }

  /**
   * @return 문서를 소유한 리포트 식별자
   */
  public Long getReportId() {
    return reportId;
  }

  /**
   * @return 문서 구조 버전
   */
  public String getSchemaVersion() {
    return schemaVersion;
  }

  /**
   * @return 저장된 상세 문서 JSON
   */
  public JsonNode getDocumentJson() {
    return documentJson.deepCopy();
  }

  /**
   * @return 문서 위변조와 직렬화 일관성 확인용 SHA-256 checksum
   */
  public String getDocumentChecksumSha256() {
    return documentChecksumSha256;
  }

  /**
   * @return 문서를 확정한 시각
   */
  public LocalDateTime getCreatedAt() {
    return createdAt;
  }

  private static String requireText(String value, String name) {
    if (value == null || value.isBlank()) {
      throw new IllegalArgumentException(name + " must not be blank");
    }
    return value;
  }

  private static JsonNode requireDocumentObject(JsonNode value) {
    if (value == null || !value.isObject()) {
      throw new IllegalArgumentException("documentJson must be a JSON object");
    }
    return value.deepCopy();
  }

  private static String requireSha256(String value) {
    if (value == null || !value.matches("[0-9a-fA-F]{64}")) {
      throw new IllegalArgumentException(
          "documentChecksumSha256 must be a 64-character hexadecimal SHA-256 checksum");
    }
    return value.toLowerCase(java.util.Locale.ROOT);
  }
}
