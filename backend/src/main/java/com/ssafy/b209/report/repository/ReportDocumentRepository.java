package com.ssafy.b209.report.repository;

import com.ssafy.b209.report.domain.ReportDocument;
import org.springframework.data.jpa.repository.JpaRepository;

/** 리포트 상세 JSON Snapshot의 저장과 조회를 담당한다. */
public interface ReportDocumentRepository extends JpaRepository<ReportDocument, Long> {}
