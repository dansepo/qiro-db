package com.qiro.domain.security.service

import com.qiro.domain.migration.dto.*
import org.springframework.data.domain.Page
import org.springframework.data.domain.Pageable
import java.time.LocalDate
import java.time.LocalDateTime
import java.util.*

/**
 * 보안 및 접근 제어 서비스 인터페이스
 * 
 * 기존 데이터베이스 프로시저들을 백엔드 서비스로 이관:
 * - 보안 관리 (8개 프로시저)
 * - 방문자 관리 (3개 프로시저)
 * - 권한 및 세션 관리 (3개 프로시저)
 */
interface SecurityManagementService {
    
    // === 보안 구역 관리 ===
    
    /**
     * 보안 구역 생성
     * 기존 프로시저: bms.create_security_zone
     */
    fun createSecurityZone(request: CreateSecurityZoneRequest): SecurityZoneDto
    
    /**
     * 보안 구역 조회
     */
    fun getSecurityZone(companyId: UUID, zoneId: UUID): SecurityZoneDto?
    
    /**
     * 보안 구역 목록 조회
     */
    fun getSecurityZones(companyId: UUID, pageable: Pageable): Page<SecurityZoneDto>
    
    /**
     * 보안 구역 필터 조회
     */
    fun getSecurityZonesWithFilter(filter: SecurityManagementFilter, pageable: Pageable): Page<SecurityZoneDto>
    
    /**
     * 보안 구역 수정
     */
    fun updateSecurityZone(zoneId: UUID, request: CreateSecurityZoneRequest): SecurityZoneDto
    
    /**
     * 보안 구역 삭제 (비활성화)
     */
    fun deleteSecurityZone(companyId: UUID, zoneId: UUID): Boolean
    
    /**
     * 구역 접근 권한 검증
     * 기존 프로시저: bms.validate_zone_access
     */
    fun validateZoneAccess(request: ValidateZoneAccessRequest): AccessValidationResult
    
    // === 보안 장치 관리 ===
    
    /**
     * 보안 장치 등록
     * 기존 프로시저: bms.register_security_device
     */
    fun registerSecurityDevice(request: RegisterSecurityDeviceRequest): SecurityDeviceDto
    
    /**
     * 보안 장치 조회
     */
    fun getSecurityDevice(companyId: UUID, deviceId: UUID): SecurityDeviceDto?
    
    /**
     * 보안 장치 목록 조회
     */
    fun getSecurityDevices(companyId: UUID, pageable: Pageable): Page<SecurityDeviceDto>
    
    /**
     * 구역별 보안 장치 조회
     */
    fun getSecurityDevicesByZone(companyId: UUID, zoneId: UUID): List<SecurityDeviceDto>
    
    /**
     * 보안 장치 수정
     */
    fun updateSecurityDevice(deviceId: UUID, request: RegisterSecurityDeviceRequest): SecurityDeviceDto
    
    /**
     * 보안 장치 삭제 (비활성화)
     */
    fun deleteSecurityDevice(companyId: UUID, deviceId: UUID): Boolean
    
    /**
     * 보안 장치 상태 업데이트
     */
    fun updateDeviceStatus(deviceId: UUID, status: String, notes: String? = null): SecurityDeviceDto
    
    /**
     * 보안 장치 유지보수 기록
     */
    fun recordDeviceMaintenance(
        deviceId: UUID,
        maintenanceType: String,
        maintenanceNotes: String? = null,
        performedBy: UUID? = null
    ): SecurityDeviceDto
    
    // === 접근 제어 관리 ===
    
    /**
     * 접근 시도 로그 기록
     * 기존 프로시저: bms.log_access_attempt
     */
    fun logAccessAttempt(request: LogAccessAttemptRequest): AccessControlRecordDto
    
    /**
     * 접근 제어 기록 조회
     */
    fun getAccessControlRecord(companyId: UUID, recordId: UUID): AccessControlRecordDto?
    
    /**
     * 접근 제어 기록 목록 조회
     */
    fun getAccessControlRecords(companyId: UUID, pageable: Pageable): Page<AccessControlRecordDto>
    
    /**
     * 접근 제어 기록 필터 조회
     */
    fun getAccessControlRecordsWithFilter(filter: SecurityManagementFilter, pageable: Pageable): Page<AccessControlRecordDto>
    
    /**
     * 사용자별 접근 이력 조회
     */
    fun getAccessHistoryByPerson(
        companyId: UUID,
        personId: UUID,
        startDate: LocalDateTime? = null,
        endDate: LocalDateTime? = null,
        pageable: Pageable
    ): Page<AccessControlRecordDto>
    
    /**
     * 구역별 접근 이력 조회
     */
    fun getAccessHistoryByZone(
        companyId: UUID,
        zoneId: UUID,
        startDate: LocalDateTime? = null,
        endDate: LocalDateTime? = null,
        pageable: Pageable
    ): Page<AccessControlRecordDto>
    
    /**
     * 장치별 접근 이력 조회
     */
    fun getAccessHistoryByDevice(
        companyId: UUID,
        deviceId: UUID,
        startDate: LocalDateTime? = null,
        endDate: LocalDateTime? = null,
        pageable: Pageable
    ): Page<AccessControlRecordDto>
    
    // === 보안 사건 관리 ===
    
    /**
     * 보안 사건 생성
     * 기존 프로시저: bms.create_security_incident
     */
    fun createSecurityIncident(request: CreateSecurityIncidentRequest): SecurityIncidentDto
    
    /**
     * 보안 사건 조회
     */
    fun getSecurityIncident(companyId: UUID, incidentId: UUID): SecurityIncidentDto?
    
    /**
     * 보안 사건 목록 조회
     */
    fun getSecurityIncidents(companyId: UUID, pageable: Pageable): Page<SecurityIncidentDto>
    
    /**
     * 보안 사건 필터 조회
     */
    fun getSecurityIncidentsWithFilter(filter: SecurityManagementFilter, pageable: Pageable): Page<SecurityIncidentDto>
    
    /**
     * 보안 사건 할당
     */
    fun assignSecurityIncident(
        companyId: UUID,
        incidentId: UUID,
        assignedTo: UUID,
        assignmentNotes: String? = null
    ): SecurityIncidentDto
    
    /**
     * 보안 사건 해결
     */
    fun resolveSecurityIncident(
        companyId: UUID,
        incidentId: UUID,
        resolutionNotes: String,
        resolvedBy: UUID
    ): SecurityIncidentDto
    
    /**
     * 긴급 보안 사건 조회
     */
    fun getCriticalSecurityIncidents(companyId: UUID, pageable: Pageable): Page<SecurityIncidentDto>
    
    /**
     * 미해결 보안 사건 조회
     */
    fun getOpenSecurityIncidents(companyId: UUID, pageable: Pageable): Page<SecurityIncidentDto>
    
    // === 방문자 관리 ===
    
    /**
     * 방문자 등록
     * 기존 프로시저: bms.register_visitor
     */
    fun registerVisitor(request: RegisterVisitorRequest): VisitorManagementDto
    
    /**
     * 방문자 조회
     */
    fun getVisitor(companyId: UUID, visitId: UUID): VisitorManagementDto?
    
    /**
     * 방문자 목록 조회
     */
    fun getVisitors(companyId: UUID, pageable: Pageable): Page<VisitorManagementDto>
    
    /**
     * 방문자 필터 조회
     */
    fun getVisitorsWithFilter(filter: SecurityManagementFilter, pageable: Pageable): Page<VisitorManagementDto>
    
    /**
     * 방문자 체크인
     * 기존 프로시저: bms.visitor_check_in
     */
    fun visitorCheckIn(request: VisitorCheckInOutRequest): VisitorManagementDto
    
    /**
     * 방문자 체크아웃
     * 기존 프로시저: bms.visitor_check_out
     */
    fun visitorCheckOut(request: VisitorCheckInOutRequest): VisitorManagementDto
    
    /**
     * 방문 승인
     */
    fun approveVisit(
        companyId: UUID,
        visitId: UUID,
        approvedBy: UUID,
        approvalNotes: String? = null
    ): VisitorManagementDto
    
    /**
     * 방문 취소
     */
    fun cancelVisit(
        companyId: UUID,
        visitId: UUID,
        cancellationReason: String,
        cancelledBy: UUID? = null
    ): VisitorManagementDto
    
    /**
     * 현재 방문 중인 방문자 조회
     */
    fun getCurrentVisitors(companyId: UUID): List<VisitorManagementDto>
    
    /**
     * 오늘 예정된 방문자 조회
     */
    fun getTodayScheduledVisitors(companyId: UUID): List<VisitorManagementDto>
    
    // === 보안 순찰 관리 ===
    
    /**
     * 보안 순찰 일정 생성
     * 기존 프로시저: bms.schedule_security_patrol
     */
    fun scheduleSecurityPatrol(request: ScheduleSecurityPatrolRequest): SecurityPatrolDto
    
    /**
     * 보안 순찰 조회
     */
    fun getSecurityPatrol(companyId: UUID, patrolId: UUID): SecurityPatrolDto?
    
    /**
     * 보안 순찰 목록 조회
     */
    fun getSecurityPatrols(companyId: UUID, pageable: Pageable): Page<SecurityPatrolDto>
    
    /**
     * 순찰 시작
     */
    fun startPatrol(
        companyId: UUID,
        patrolId: UUID,
        startedBy: UUID,
        startNotes: String? = null
    ): SecurityPatrolDto
    
    /**
     * 순찰 완료
     */
    fun completePatrol(
        companyId: UUID,
        patrolId: UUID,
        completionNotes: String? = null,
        incidentsFound: Int? = null
    ): SecurityPatrolDto
    
    /**
     * 순찰 체크포인트 기록
     */
    fun recordPatrolCheckpoint(
        patrolId: UUID,
        checkpointId: UUID,
        notes: String? = null
    ): PatrolCheckpointDto
    
    /**
     * 오늘 예정된 순찰 조회
     */
    fun getTodayScheduledPatrols(companyId: UUID): List<SecurityPatrolDto>
    
    // === 보안 알림 및 이벤트 ===
    
    /**
     * 보안 알림 생성
     * 기존 프로시저: bms.generate_security_alert
     */
    fun generateSecurityAlert(request: GenerateSecurityAlertRequest): SecurityAlertDto
    
    /**
     * 보안 이벤트 로그 기록
     */
    fun logSecurityEvent(
        companyId: UUID,
        eventType: String,
        eventSeverity: String,
        eventMessage: String,
        sourceSystem: String? = null,
        userId: UUID? = null,
        deviceId: UUID? = null,
        zoneId: UUID? = null,
        eventData: String? = null
    ): SecurityEventLogDto
    
    /**
     * 보안 알림 확인
     */
    fun acknowledgeSecurityAlert(
        alertId: UUID,
        acknowledgedBy: UUID,
        acknowledgmentNotes: String? = null
    ): SecurityAlertDto
    
    /**
     * 미확인 보안 알림 조회
     */
    fun getUnacknowledgedAlerts(companyId: UUID): List<SecurityAlertDto>
    
    /**
     * 보안 이벤트 로그 조회
     */
    fun getSecurityEventLogs(
        companyId: UUID,
        startDate: LocalDateTime? = null,
        endDate: LocalDateTime? = null,
        pageable: Pageable
    ): Page<SecurityEventLogDto>
    
    // === 통계 및 분석 ===
    
    /**
     * 보안 관리 통계 조회
     */
    fun getSecurityManagementStatistics(companyId: UUID): SecurityManagementStatisticsDto
    
    /**
     * 보안 대시보드 데이터 조회
     * 기존 프로시저: bms.get_security_dashboard_data
     */
    fun getSecurityDashboardData(
        companyId: UUID,
        dateFrom: LocalDate? = null,
        dateTo: LocalDate? = null
    ): SecurityDashboardDataDto
    
    /**
     * 접근 패턴 분석
     */
    fun getAccessPatternAnalysis(
        companyId: UUID,
        analysisType: String = "DAILY", // DAILY, WEEKLY, MONTHLY
        period: Int = 30
    ): Map<String, Any>
    
    /**
     * 보안 사건 트렌드 분석
     */
    fun getSecurityIncidentTrends(
        companyId: UUID,
        period: String = "MONTHLY"
    ): Map<String, Any>
    
    /**
     * 방문자 통계 분석
     */
    fun getVisitorStatistics(
        companyId: UUID,
        startDate: LocalDate,
        endDate: LocalDate
    ): Map<String, Any>
    
    /**
     * 순찰 효율성 분석
     */
    fun getPatrolEfficiencyAnalysis(companyId: UUID): Map<String, Any>
    
    /**
     * 구역별 보안 현황 분석
     */
    fun getZoneSecurityStatus(companyId: UUID): Map<String, Any>
    
    /**
     * 장치 성능 분석
     */
    fun getDevicePerformanceAnalysis(companyId: UUID): Map<String, Any>
    
    // === 자동화 및 배치 작업 ===
    
    /**
     * 자동 보안 점검 실행
     */
    fun executeAutomaticSecurityCheck(companyId: UUID): Map<String, Any>
    
    /**
     * 만료된 방문 권한 정리
     */
    fun cleanupExpiredVisitorAccess(companyId: UUID): Map<String, Any>
    
    /**
     * 보안 장치 상태 점검
     */
    fun checkDeviceHealthStatus(companyId: UUID): Map<String, Any>
    
    /**
     * 보안 정책 준수 점검
     */
    fun validateSecurityPolicyCompliance(companyId: UUID): Map<String, Any>
    
    /**
     * 보안 백업 및 아카이브
     */
    fun performSecurityDataArchive(
        companyId: UUID,
        archiveDate: LocalDate,
        dataTypes: List<String>
    ): Map<String, Any>
}