package com.ssafy.b209.database;

import static org.assertj.core.api.Assertions.assertThat;

import java.util.List;
import org.flywaydb.core.Flyway;
import org.junit.jupiter.api.BeforeAll;
import org.junit.jupiter.api.Test;
import org.springframework.jdbc.core.JdbcTemplate;
import org.springframework.jdbc.datasource.DriverManagerDataSource;
import org.testcontainers.containers.MySQLContainer;
import org.testcontainers.junit.jupiter.Container;
import org.testcontainers.junit.jupiter.Testcontainers;

/**
 * 초기화 가능한 Dodam MySQL 스키마의 최종 baseline 계약을 실제 MySQL에서 검증한다.
 *
 * <p>서비스 핵심 관계 데이터는 정규화하고, 변경 불가능한 AI 분석 결과와 리포트 문서만 JSON으로 보관하는 경계를 보호한다.
 */
@Testcontainers
class DatabaseBaselineContractIntegrationTest {

  @Container
  static final MySQLContainer<?> MYSQL_CONTAINER =
      new MySQLContainer<>("mysql:8.4.10")
          .withDatabaseName("dodam_baseline")
          .withUsername("test")
          .withPassword("test");

  private static JdbcTemplate jdbcTemplate;
  private static Flyway flyway;

  @BeforeAll
  static void migrateFreshDatabase() {
    flyway =
        Flyway.configure()
            .dataSource(
                MYSQL_CONTAINER.getJdbcUrl(),
                MYSQL_CONTAINER.getUsername(),
                MYSQL_CONTAINER.getPassword())
            .load();
    flyway.migrate();
    jdbcTemplate =
        new JdbcTemplate(
            new DriverManagerDataSource(
                MYSQL_CONTAINER.getJdbcUrl(),
                MYSQL_CONTAINER.getUsername(),
                MYSQL_CONTAINER.getPassword()));
  }

  @Test
  void createsSemanticBaselineWithOnlyApprovedDocumentJsonColumns() {
    assertThat(flyway.info().current().getVersion().getVersion()).isEqualTo("1.0.1");
    assertThat(tableNames()).hasSize(69);

    assertThat(jsonColumns())
        .containsExactly("analysis_results.result_json", "report_documents.document_json");

    assertThat(tableNames())
        .contains(
            "analyses",
            "analysis_results",
            "analysis_detected_objects",
            "reports",
            "report_documents",
            "report_evidence_items",
            "report_evidence_relations",
            "report_drawn_items",
            "report_crisis_alerts",
            "report_crisis_alert_steps",
            "report_crisis_alert_resources",
            "report_generation_retries")
        .doesNotContain(
            "refresh_tokens",
            "analysis_visual_features",
            "analysis_behavior_features",
            "analysis_model_components",
            "analysis_warnings",
            "report_diary_insights",
            "report_public_interpretations",
            "report_subjects");
  }

  @Test
  void seedsOnlyLaunchDrawingActivitiesAsActive() {
    assertThat(
            jdbcTemplate.queryForList(
                "SELECT code FROM drawing_types WHERE is_active = TRUE ORDER BY display_order",
                String.class))
        .containsExactly("ART_DIARY", "HTP");
  }

  private List<String> tableNames() {
    return jdbcTemplate.queryForList(
        "SELECT table_name FROM information_schema.tables "
            + "WHERE table_schema = DATABASE() AND table_type = 'BASE TABLE' "
            + "AND table_name <> 'flyway_schema_history' ORDER BY table_name",
        String.class);
  }

  private List<String> jsonColumns() {
    return jdbcTemplate.queryForList(
        "SELECT CONCAT(table_name, '.', column_name) FROM information_schema.columns "
            + "WHERE table_schema = DATABASE() AND data_type = 'json' "
            + "ORDER BY table_name, ordinal_position",
        String.class);
  }
}
