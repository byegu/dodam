package com.ssafy.b209.report.domain;

import static org.assertj.core.api.Assertions.assertThat;
import static org.assertj.core.api.Assertions.assertThatThrownBy;

import com.fasterxml.jackson.databind.node.JsonNodeFactory;
import java.time.LocalDateTime;
import org.junit.jupiter.api.Test;

class ReportDocumentTest {

  @Test
  void createsImmutableJsonSnapshotWithValidatedChecksum() {
    LocalDateTime createdAt = LocalDateTime.of(2026, 8, 12, 17, 30);

    ReportDocument document =
        ReportDocument.create(
            7L,
            "1.0",
            JsonNodeFactory.instance.objectNode().put("headline", "오늘의 이야기"),
            "a".repeat(64),
            createdAt);

    assertThat(document.getReportId()).isEqualTo(7L);
    assertThat(document.getSchemaVersion()).isEqualTo("1.0");
    assertThat(document.getDocumentJson().get("headline").asText()).isEqualTo("오늘의 이야기");
    assertThat(document.getCreatedAt()).isEqualTo(createdAt);
  }

  @Test
  void rejectsNonObjectDocumentAndInvalidChecksum() {
    LocalDateTime createdAt = LocalDateTime.of(2026, 8, 12, 17, 30);

    assertThatThrownBy(
            () ->
                ReportDocument.create(
                    7L,
                    "1.0",
                    JsonNodeFactory.instance.textNode("not-an-object"),
                    "a".repeat(64),
                    createdAt))
        .isInstanceOf(IllegalArgumentException.class)
        .hasMessageContaining("documentJson");
    assertThatThrownBy(
            () ->
                ReportDocument.create(
                    7L, "1.0", JsonNodeFactory.instance.objectNode(), "not-a-checksum", createdAt))
        .isInstanceOf(IllegalArgumentException.class)
        .hasMessageContaining("documentChecksumSha256");
  }
}
