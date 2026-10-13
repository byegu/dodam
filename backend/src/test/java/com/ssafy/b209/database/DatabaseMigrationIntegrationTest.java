package com.ssafy.b209.database;

import static org.assertj.core.api.Assertions.assertThat;

import java.util.List;
import org.flywaydb.core.Flyway;
import org.junit.jupiter.api.Test;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.boot.test.context.SpringBootTest;
import org.springframework.boot.testcontainers.service.connection.ServiceConnection;
import org.springframework.jdbc.core.JdbcTemplate;
import org.springframework.test.context.ActiveProfiles;
import org.testcontainers.containers.MySQLContainer;
import org.testcontainers.junit.jupiter.Container;
import org.testcontainers.junit.jupiter.Testcontainers;

/** MySQL 8에서 최종 Baseline Migration과 애플리케이션 Entity의 정합성을 검증한다. */
@Testcontainers
@SpringBootTest
@ActiveProfiles("integration-test")
class DatabaseMigrationIntegrationTest {

  @Container @ServiceConnection
  static final MySQLContainer<?> MYSQL_CONTAINER =
      new MySQLContainer<>("mysql:8.4.10")
          .withDatabaseName("dodam")
          .withUsername("test")
          .withPassword("test");

  @Autowired JdbcTemplate jdbcTemplate;
  @Autowired Flyway flyway;

  @Test
  void appliesSemanticBaselineWithSixtyNineBusinessTables() {
    assertThat(MYSQL_CONTAINER.isRunning()).isTrue();
    assertThat(flyway.info().current().getVersion().getVersion()).isEqualTo("1.0.1");
    assertThat(tableCountExcludingFlyway()).isEqualTo(69);
    assertThat(jsonColumnCount()).isEqualTo(2);
    assertThat(jsonColumns())
        .containsExactlyInAnyOrder(
            "analysis_results.result_json", "report_documents.document_json");
    assertThat(tableExists("refresh_tokens")).isFalse();
  }

  @Test
  void keepsCoreDomainsAndReplacesLegacyAnalysisAndReportFragments() {
    assertThat(tableExists("users")).isTrue();
    assertThat(tableExists("children")).isTrue();
    assertThat(tableExists("drawing_sessions")).isTrue();
    assertThat(tableExists("conversation_sessions")).isTrue();
    assertThat(tableExists("community_posts")).isTrue();
    assertThat(tableExists("analysis_results")).isTrue();
    assertThat(tableExists("report_documents")).isTrue();
    assertThat(tableExists("report_evidence_relations")).isTrue();
    assertThat(tableExists("analysis_observation_results")).isFalse();
    assertThat(tableExists("analysis_conversation_summaries")).isFalse();
    assertThat(tableExists("report_diary_insights")).isFalse();
    assertThat(tableExists("report_public_interpretations")).isFalse();
  }

  @Test
  void createsRepresentativeKeysForConsolidatedDocuments() {
    assertThat(primaryKeyExists("analysis_results", "analysis_id")).isTrue();
    assertThat(primaryKeyExists("report_documents", "report_id")).isTrue();
    assertThat(foreignKeyExists("analysis_results", "fk_analysis_results_analysis_id")).isTrue();
    assertThat(foreignKeyExists("report_documents", "fk_report_documents_report_id")).isTrue();
    assertThat(indexExists("report_documents", "uk_report_documents_checksum", true)).isTrue();
    assertThat(indexExists("analyses", "uk_analyses_active_asset_task", true)).isTrue();
    assertThat(indexExists("drawing_assets", "uk_drawing_assets_session_type_version", true))
        .isTrue();
  }

  @Test
  void keepsHtpAndReportAuditConstraints() {
    assertThat(tableExists("htp_assessments")).isTrue();
    assertThat(tableExists("htp_assessment_steps")).isTrue();
    assertThat(indexExists("htp_assessments", "uk_htp_assessments_active_child", true)).isTrue();
    assertThat(indexExists("htp_assessment_steps", "uk_htp_assessment_steps_session", true))
        .isTrue();
    assertThat(tableExists("report_evidence_items")).isTrue();
    assertThat(tableExists("report_crisis_alerts")).isTrue();
    assertThat(tableExists("report_generation_retries")).isTrue();
  }

  @Test
  void seedsOnlyLaunchDrawingTypesAsActive() {
    assertThat(
            jdbcTemplate.queryForList(
                "SELECT code FROM drawing_types WHERE is_active = TRUE ORDER BY display_order",
                String.class))
        .containsExactly("ART_DIARY", "HTP");
    assertThat(
            jdbcTemplate.queryForObject(
                "SELECT activity_category FROM drawing_types WHERE code = 'HTP'", String.class))
        .isEqualTo("ASSESSMENT");
    assertThat(
            jdbcTemplate.queryForObject(
                "SELECT COUNT(*) FROM consent_terms WHERE term_code = 'SERVICE_TOS' "
                    + "AND is_active = TRUE AND is_required = TRUE",
                Integer.class))
        .isEqualTo(1);
  }

  private int tableCountExcludingFlyway() {
    return jdbcTemplate.queryForObject(
        "SELECT COUNT(*) FROM information_schema.tables "
            + "WHERE table_schema = DATABASE() AND table_name <> 'flyway_schema_history'",
        Integer.class);
  }

  private int jsonColumnCount() {
    return jdbcTemplate.queryForObject(
        "SELECT COUNT(*) FROM information_schema.columns "
            + "WHERE table_schema = DATABASE() AND data_type = 'json'",
        Integer.class);
  }

  private List<String> jsonColumns() {
    return jdbcTemplate.queryForList(
        "SELECT CONCAT(table_name, '.', column_name) FROM information_schema.columns "
            + "WHERE table_schema = DATABASE() AND data_type = 'json'",
        String.class);
  }

  private boolean tableExists(String tableName) {
    return count(
            "SELECT COUNT(*) FROM information_schema.tables "
                + "WHERE table_schema = DATABASE() AND table_name = ?",
            tableName)
        > 0;
  }

  private boolean primaryKeyExists(String tableName, String columnName) {
    return count(
            "SELECT COUNT(*) FROM information_schema.key_column_usage "
                + "WHERE table_schema = DATABASE() AND table_name = ? "
                + "AND constraint_name = 'PRIMARY' AND column_name = ?",
            tableName,
            columnName)
        > 0;
  }

  private boolean foreignKeyExists(String tableName, String constraintName) {
    return count(
            "SELECT COUNT(*) FROM information_schema.referential_constraints "
                + "WHERE constraint_schema = DATABASE() AND table_name = ? AND constraint_name = ?",
            tableName,
            constraintName)
        > 0;
  }

  private boolean indexExists(String tableName, String indexName, boolean unique) {
    return count(
            "SELECT COUNT(*) FROM information_schema.statistics "
                + "WHERE table_schema = DATABASE() AND table_name = ? AND index_name = ? "
                + "AND non_unique = ?",
            tableName,
            indexName,
            unique ? 0 : 1)
        > 0;
  }

  private int count(String sql, Object... args) {
    return jdbcTemplate.queryForObject(sql, Integer.class, args);
  }
}
