package com.qiro.domain.safety.service

import com.qiro.domain.migration.dto.*
import org.springframework.data.domain.Page
import org.springframework.data.domain.Pageable
import java.time.LocalDate
import java.util.*

/**
 * 안전 및 규정 준수 서비스 인터페이스
 * 
 * 기존 데이터베이스 프로시저들을 백엔드 서비스로 이관:
 * - 안전 점검 (5개 프로시저)
 * - 규정 준수 (3개 프로시저)
 * - 안전 사고 보고 및 예방 조치 기능
 */
interface SafetyComplianceService {
    
    // === 안전 점검 카테고리 관리 ===
    
    /**
     * 안전 점검 카테고리 생성
     */
    fun createSafetyInspectionCategory(request: CreateSafetyInspectionCategoryRequest): SafetyInspectionCategoryDto
    
    /**
     * 안전 점검 카테고리 조회
     */
    fun getSafetyInspectionCategory(companyId: UUID, categoryId: UUID): SafetyInspectionCategoryDto?
    
    /**
     * 안전 점검 카테고리 목록 조회
     */
    fun getSafetyInspectionCategories(companyId: UUID, pageable: Pageable): Page<SafetyInspectionCategoryDto>
    
    /**
     * 안전 점검 카테고리 수정
     */
    fun updateSafetyInspectionCategory(categoryId: UUID, request: CreateSafetyInspectionCategoryRequest): SafetyInspectionCategoryDto
    
    /**
     * 안전 점검 카테고리 삭제 (비활성화)
     */
    fun deleteSafetyInspectionCategory(companyId: UUID, categoryId: UUID): Boolean
    
    // === 안전 점검 일정 관리 ===
    
    /**
     * 안전 점검 일정 생성
     * 기존 프로시저: bms.create_safety_inspection_schedule
     */
    fun createSafetyInspectionSchedule(request: CreateSafetyInspectionScheduleRequest): SafetyInspectionScheduleDto
    
    /**
     * 안전 점검 일정 조회
     */
    fun getSafetyInspectionSchedule(companyId: UUID, scheduleId: UUID): SafetyInspectionScheduleDto?
    
    /**
     * 안전 점검 일정 목록 조회
     */
    fun getSafetyInspectionSchedules(companyId: UUID, pageable: Pageable): Page<SafetyInspectionScheduleDto>
    
    /**
     * 안전 점검 일정 필터 조회
     */
    fun getSafetyInspectionSchedulesWithFilter(filter: SafetyComplianceFilter, pageable: Pageable): Page<SafetyInspectionScheduleDto>
    
    /**
     * 안전 점검 일정 수정
     */
    fun updateSafetyInspectionSchedule(scheduleId: UUID, request: CreateSafetyInspectionScheduleRequest): SafetyInspectionScheduleDto
    
    /**
     * 안전 점검 일정 삭제
     */
    fun deleteSafetyInspectionSchedule(companyId: UUID, scheduleId: UUID): Boolean
    
    /**
     * 예정된 안전 점검 조회
     */
    fun getUpcomingSafetyInspections(companyId: UUID, days: Int = 30): List<SafetyInspectionScheduleDto>
    
    // === 안전 점검 관리 ===
    
    /**
     * 안전 점검 생성
     * 기존 프로시저: bms.create_safety_inspection
     */
    fun createSafetyInspection(request: CreateSafetyInspectionRequest): SafetyInspectionDto
    
    /**
     * 안전 점검 조회
     */
    fun getSafetyInspection(companyId: UUID, inspectionId: UUID): SafetyInspectionDto?
    
    /**
     * 안전 점검 목록 조회
     */
    fun getSafetyInspections(companyId: UUID, pageable: Pageable): Page<SafetyInspectionDto>
    
    /**
     * 안전 점검 필터 조회
     */
    fun getSafetyInspectionsWithFilter(filter: SafetyComplianceFilter, pageable: Pageable): Page<SafetyInspectionDto>
    
    /**
     * 안전 점검 완료
     * 기존 프로시저: bms.complete_safety_inspection
     */
    fun completeSafetyInspection(request: CompleteSafetyInspectionRequest): SafetyInspectionDto
    
    /**
     * 안전 점검 수정
     */
    fun updateSafetyInspection(inspectionId: UUID, request: CreateSafetyInspectionRequest): SafetyInspectionDto
    
    /**
     * 안전 점검 취소
     */
    fun cancelSafetyInspection(companyId: UUID, inspectionId: UUID, reason: String): SafetyInspectionDto
    
    /**
     * 재점검 일정 생성
     */
    fun scheduleReinspection(
        companyId: UUID, 
        originalInspectionId: UUID, 
        reinspectionDate: LocalDate,
        reason: String
    ): SafetyInspectionDto
    
    // === 안전 점검 항목 관리 ===
    
    /**
     * 안전 점검 항목 생성
     */
    fun createSafetyInspectionItem(request: CreateSafetyInspectionItemRequest): SafetyInspectionItemDto
    
    /**
     * 안전 점검 항목 조회
     */
    fun getSafetyInspectionItem(companyId: UUID, itemId: UUID): SafetyInspectionItemDto?
    
    /**
     * 점검별 안전 점검 항목 목록 조회
     */
    fun getSafetyInspectionItemsByInspection(companyId: UUID, inspectionId: UUID): List<SafetyInspectionItemDto>
    
    /**
     * 안전 점검 항목 수정
     */
    fun updateSafetyInspectionItem(itemId: UUID, request: CreateSafetyInspectionItemRequest): SafetyInspectionItemDto
    
    /**
     * 안전 점검 항목 삭제
     */
    fun deleteSafetyInspectionItem(companyId: UUID, itemId: UUID): Boolean
    
    /**
     * 시정 조치가 필요한 항목 조회
     */
    fun getItemsRequiringCorrectiveAction(companyId: UUID, pageable: Pageable): Page<SafetyInspectionItemDto>
    
    // === 안전 교육 관리 ===
    
    /**
     * 안전 교육 생성
     */
    fun createSafetyTraining(request: CreateSafetyTrainingRequest): SafetyTrainingRecordDto
    
    /**
     * 안전 교육 조회
     */
    fun getSafetyTraining(companyId: UUID, trainingId: UUID): SafetyTrainingRecordDto?
    
    /**
     * 안전 교육 목록 조회
     */
    fun getSafetyTrainings(companyId: UUID, pageable: Pageable): Page<SafetyTrainingRecordDto>
    
    /**
     * 안전 교육 필터 조회
     */
    fun getSafetyTrainingsWithFilter(filter: SafetyComplianceFilter, pageable: Pageable): Page<SafetyTrainingRecordDto>
    
    /**
     * 안전 교육 수정
     */
    fun updateSafetyTraining(trainingId: UUID, request: CreateSafetyTrainingRequest): SafetyTrainingRecordDto
    
    /**
     * 안전 교육 취소
     */
    fun cancelSafetyTraining(companyId: UUID, trainingId: UUID, reason: String): SafetyTrainingRecordDto
    
    /**
     * 안전 교육 완료 처리
     */
    fun completeSafetyTraining(
        companyId: UUID,
        trainingId: UUID,
        attendedParticipants: Int,
        trainingEffectivenessScore: java.math.BigDecimal? = null,
        participantSatisfactionScore: java.math.BigDecimal? = null,
        trainingNotes: String? = null
    ): SafetyTrainingRecordDto
    
    /**
     * 예정된 안전 교육 조회
     */
    fun getUpcomingSafetyTrainings(companyId: UUID, days: Int = 30): List<SafetyTrainingRecordDto>
    
    // === 안전 사고 관리 ===
    
    /**
     * 안전 사고 신고
     * 기존 프로시저: bms.report_safety_incident
     */
    fun reportSafetyIncident(request: ReportSafetyIncidentRequest): SafetyIncidentDto
    
    /**
     * 안전 사고 조회
     */
    fun getSafetyIncident(companyId: UUID, incidentId: UUID): SafetyIncidentDto?
    
    /**
     * 안전 사고 목록 조회
     */
    fun getSafetyIncidents(companyId: UUID, pageable: Pageable): Page<SafetyIncidentDto>
    
    /**
     * 안전 사고 필터 조회
     */
    fun getSafetyIncidentsWithFilter(filter: SafetyComplianceFilter, pageable: Pageable): Page<SafetyIncidentDto>
    
    /**
     * 안전 사고 수정
     */
    fun updateSafetyIncident(incidentId: UUID, request: ReportSafetyIncidentRequest): SafetyIncidentDto
    
    /**
     * 안전 사고 조사 시작
     */
    fun startSafetyIncidentInvestigation(
        companyId: UUID,
        incidentId: UUID,
        investigatorId: UUID,
        investigationStartDate: LocalDate = LocalDate.now()
    ): SafetyIncidentDto
    
    /**
     * 안전 사고 조사 완료
     */
    fun completeSafetyIncidentInvestigation(
        companyId: UUID,
        incidentId: UUID,
        investigationFindings: String,
        correctiveActionsRequired: String? = null,
        preventiveMeasures: String? = null,
        lessonsLearned: String? = null
    ): SafetyIncidentDto
    
    /**
     * 안전 사고 종료
     */
    fun closeSafetyIncident(companyId: UUID, incidentId: UUID, closureNotes: String): SafetyIncidentDto
    
    /**
     * 중대 사고 조회
     */
    fun getCriticalSafetyIncidents(companyId: UUID, pageable: Pageable): Page<SafetyIncidentDto>
    
    /**
     * 미해결 사고 조회
     */
    fun getOpenSafetyIncidents(companyId: UUID, pageable: Pageable): Page<SafetyIncidentDto>
    
    // === 통계 및 분석 ===
    
    /**
     * 안전 관리 통계 조회
     */
    fun getSafetyComplianceStatistics(companyId: UUID): SafetyComplianceStatisticsDto
    
    /**
     * 안전 대시보드 데이터 조회
     */
    fun getSafetyDashboardData(
        companyId: UUID,
        dateFrom: LocalDate? = null,
        dateTo: LocalDate? = null
    ): SafetyDashboardDataDto
    
    /**
     * 안전 점검 요약 조회
     * 기존 프로시저: bms.get_safety_inspection_summary
     */
    fun getSafetyInspectionSummary(
        companyId: UUID,
        startDate: LocalDate? = null,
        endDate: LocalDate? = null,
        categoryId: UUID? = null
    ): List<SafetyInspectionSummaryDto>
    
    /**
     * 규정 준수 보고서 생성
     */
    fun generateComplianceReport(
        companyId: UUID,
        reportType: String,
        startDate: LocalDate,
        endDate: LocalDate
    ): ComplianceReportDto
    
    /**
     * 안전 점검 트렌드 분석
     */
    fun getSafetyInspectionTrends(
        companyId: UUID,
        period: String = "MONTHLY"
    ): Map<String, Any>
    
    /**
     * 사고 발생 패턴 분석
     */
    fun getSafetyIncidentPatterns(companyId: UUID): Map<String, Any>
    
    /**
     * 교육 효과성 분석
     */
    fun getTrainingEffectivenessAnalysis(companyId: UUID): Map<String, Any>
    
    /**
     * 카테고리별 규정 준수율 분석
     */
    fun getComplianceRateByCategory(companyId: UUID): Map<String, Any>
    
    /**
     * 시정 조치 추적 분석
     */
    fun getCorrectiveActionTracking(companyId: UUID): Map<String, Any>
    
    // === 자동화 및 배치 작업 ===
    
    /**
     * 자동 점검 일정 생성
     */
    fun generateAutomaticInspectionSchedules(companyId: UUID): Map<String, Any>
    
    /**
     * 만료된 인증서 확인
     */
    fun checkExpiredCertifications(companyId: UUID): Map<String, Any>
    
    /**
     * 규정 준수 알림 발송
     */
    fun sendComplianceNotifications(companyId: UUID): Map<String, Any>
    
    /**
     * 안전 데이터 아카이브
     */
    fun performSafetyDataArchive(
        companyId: UUID,
        archiveDate: LocalDate,
        dataTypes: List<String>
    ): Map<String, Any>
}