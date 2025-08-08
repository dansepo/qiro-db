package com.qiro.domain.fault.service

import com.qiro.domain.fault.dto.*
import com.qiro.domain.fault.entity.*
import com.qiro.domain.fault.repository.FaultCategoryRepository
import com.qiro.domain.fault.repository.FaultReportRepository
import org.springframework.data.domain.Page
import org.springframework.data.domain.Pageable
import org.springframework.stereotype.Service
import org.springframework.transaction.annotation.Transactional
import java.time.LocalDateTime
import java.util.*

/**
 * 고장 신고 서비스
 */
@Service
@Transactional(readOnly = true)
class FaultReportService(
    private val faultReportRepository: FaultReportRepository,
    private val faultReportRepositoryImpl: FaultReportRepositoryImpl,
    private val faultCategoryRepository: FaultCategoryRepository,
    private val attachmentService: AttachmentService
) {

    /**
     * 고장 신고 생성
     */
    @Transactional
    fun createFaultReport(request: CreateFaultReportRequest): FaultReportDto {
        // 분류 정보 조회
        val category = faultCategoryRepository.findById(request.categoryId)
            .orElseThrow { IllegalArgumentException("고장 분류를 찾을 수 없습니다: ${request.categoryId}") }

        // 신고 번호 생성
        val reportNumber = generateReportNumber()

        // 우선순위 및 긴급도 결정
        val priority = determinePriority(request.faultSeverity, category.defaultPriority)
        val urgency = determineUrgency(request.faultSeverity, category.defaultUrgency)

        // 응답 및 해결 기한 계산
        val now = LocalDateTime.now()
        val firstResponseDue = now.plusMinutes(category.responseTimeMinutes.toLong())
        val resolutionDue = now.plusHours(category.resolutionTimeHours.toLong())

        // 고장 신고 엔티티 생성
        val faultReport = FaultReport(
            companyId = request.companyId,
            buildingId = request.buildingId,
            unitId = request.unitId,
            assetId = request.assetId,
            categoryId = request.categoryId,
            reportNumber = reportNumber,
            reportTitle = request.reportTitle,
            reportDescription = request.reportDescription,
            reporterType = request.reporterType,
            reporterName = request.reporterName,
            reporterContact = request.reporterContact,
            reporterUnitId = request.reporterUnitId,
            anonymousReport = request.anonymousReport,
            faultType = request.faultType,
            faultSeverity = request.faultSeverity,
            faultUrgency = urgency,
            faultPriority = priority,
            faultLocation = request.faultLocation,
            affectedAreas = request.affectedAreas,
            environmentalConditions = request.environmentalConditions,
            safetyImpact = request.safetyImpact,
            operationalImpact = request.operationalImpact,
            residentImpact = request.residentImpact,
            estimatedAffectedUnits = request.estimatedAffectedUnits,
            faultOccurredAt = request.faultOccurredAt,
            firstResponseDue = firstResponseDue,
            resolutionDue = resolutionDue,
            initialPhotos = request.initialPhotos,
            supportingDocuments = request.supportingDocuments,
            assignedTeam = category.defaultAssignedTeam
        )

        val savedReport = faultReportRepository.save(faultReport)

        // 긴급 신고인 경우 즉시 알림 발송
        if (savedReport.isUrgent()) {
            // TODO: 알림 서비스 연동
        }

        return FaultReportDto.from(savedReport)
    }

    /**
     * 고장 신고 조회
     */
    fun getFaultReport(id: UUID): FaultReportDto {
        val faultReport = faultReportRepository.findById(id)
            .orElseThrow { IllegalArgumentException("고장 신고를 찾을 수 없습니다: $id") }

        val dto = FaultReportDto.from(faultReport)
        
        // 첨부파일 정보 추가
        val attachments = attachmentService.getAttachmentsByEntity(id, EntityType.FAULT_REPORT)
        
        return dto.copy(attachments = attachments)
    }

    /**
     * 고장 신고 목록 조회
     */
    fun getFaultReports(filter: FaultReportFilter, pageable: Pageable): Page<FaultReportDto> {
        return when {
            filter.reportStatus != null -> {
                faultReportRepository.findByCompanyIdAndReportStatusOrderByReportedAtDesc(
                    filter.companyId, filter.reportStatus, pageable
                )
            }
            filter.faultPriority != null -> {
                faultReportRepository.findByCompanyIdAndFaultPriorityOrderByReportedAtDesc(
                    filter.companyId, filter.faultPriority, pageable
                )
            }
            filter.assignedTo != null -> {
                faultReportRepository.findByCompanyIdAndAssignedToOrderByReportedAtDesc(
                    filter.companyId, filter.assignedTo, pageable
                )
            }
            filter.buildingId != null -> {
                faultReportRepository.findByCompanyIdAndBuildingIdOrderByReportedAtDesc(
                    filter.companyId, filter.buildingId, pageable
                )
            }
            filter.dateFrom != null && filter.dateTo != null -> {
                faultReportRepository.findByCompanyIdAndReportedAtBetween(
                    filter.companyId, filter.dateFrom, filter.dateTo, pageable
                )
            }
            else -> {
                faultReportRepository.findByCompanyIdOrderByReportedAtDesc(filter.companyId, pageable)
            }
        }.map { FaultReportDto.from(it) }
    }

    /**
     * 긴급 고장 신고 조회
     */
    fun getUrgentFaultReports(companyId: UUID): List<FaultReportDto> {
        return faultReportRepository.findUrgentFaultReports(companyId)
            .map { FaultReportDto.from(it) }
    }

    /**
     * 응답 시간 초과 신고 조회
     */
    fun getOverdueResponseReports(companyId: UUID): List<FaultReportDto> {
        return faultReportRepository.findOverdueResponseReports(companyId, LocalDateTime.now())
            .map { FaultReportDto.from(it) }
    }

    /**
     * 해결 시간 초과 신고 조회
     */
    fun getOverdueResolutionReports(companyId: UUID): List<FaultReportDto> {
        return faultReportRepository.findOverdueResolutionReports(companyId, LocalDateTime.now())
            .map { FaultReportDto.from(it) }
    }

    /**
     * 미배정 신고 조회
     */
    fun getUnassignedReports(companyId: UUID): List<FaultReportDto> {
        return faultReportRepository.findUnassignedReports(companyId)
            .map { FaultReportDto.from(it) }
    }

    /**
     * 진행 중인 신고 조회
     */
    fun getActiveReports(companyId: UUID): List<FaultReportDto> {
        return faultReportRepository.findActiveReports(companyId)
            .map { FaultReportDto.from(it) }
    }

    /**
     * 고장 신고 업데이트
     */
    @Transactional
    fun updateFaultReport(id: UUID, request: UpdateFaultReportRequest): FaultReportDto {
        val faultReport = faultReportRepository.findById(id)
            .orElseThrow { IllegalArgumentException("고장 신고를 찾을 수 없습니다: $id") }

        val updatedReport = faultReport.copy(
            reportTitle = request.reportTitle ?: faultReport.reportTitle,
            reportDescription = request.reportDescription ?: faultReport.reportDescription,
            faultSeverity = request.faultSeverity ?: faultReport.faultSeverity,
            faultLocation = request.faultLocation ?: faultReport.faultLocation,
            affectedAreas = request.affectedAreas ?: faultReport.affectedAreas,
            environmentalConditions = request.environmentalConditions ?: faultReport.environmentalConditions,
            safetyImpact = request.safetyImpact ?: faultReport.safetyImpact,
            operationalImpact = request.operationalImpact ?: faultReport.operationalImpact,
            residentImpact = request.residentImpact ?: faultReport.residentImpact,
            estimatedAffectedUnits = request.estimatedAffectedUnits ?: faultReport.estimatedAffectedUnits,
            assignedTo = request.assignedTo ?: faultReport.assignedTo,
            assignedTeam = request.assignedTeam ?: faultReport.assignedTeam,
            contractorId = request.contractorId ?: faultReport.contractorId,
            internalNotes = request.internalNotes ?: faultReport.internalNotes,
            followUpRequired = request.followUpRequired ?: faultReport.followUpRequired,
            followUpDate = request.followUpDate ?: faultReport.followUpDate,
            followUpNotes = request.followUpNotes ?: faultReport.followUpNotes
        )

        val savedReport = faultReportRepository.save(updatedReport)
        return FaultReportDto.from(savedReport)
    }

    /**
     * 고장 신고 상태 업데이트
     */
    @Transactional
    fun updateFaultReportStatus(id: UUID, request: UpdateFaultReportStatusRequest): FaultReportDto {
        val faultReport = faultReportRepository.findById(id)
            .orElseThrow { IllegalArgumentException("고장 신고를 찾을 수 없습니다: $id") }

        val updatedReport = faultReport.copy(
            reportStatus = request.reportStatus,
            resolutionStatus = request.resolutionStatus ?: faultReport.resolutionStatus
        )

        val savedReport = faultReportRepository.save(updatedReport)
        return FaultReportDto.from(savedReport)
    }

    /**
     * 담당자 배정
     */
    @Transactional
    fun assignTechnician(reportId: UUID, technicianId: UUID, team: String? = null): FaultReportDto {
        val faultReport = faultReportRepository.findById(reportId)
            .orElseThrow { IllegalArgumentException("고장 신고를 찾을 수 없습니다: $reportId") }

        val updatedReport = faultReport.assignTo(technicianId, team)
        val savedReport = faultReportRepository.save(updatedReport)

        // TODO: 담당자에게 알림 발송

        return FaultReportDto.from(savedReport)
    }

    /**
     * 접수 확인
     */
    @Transactional
    fun acknowledgeFaultReport(reportId: UUID, userId: UUID): FaultReportDto {
        val faultReport = faultReportRepository.findById(reportId)
            .orElseThrow { IllegalArgumentException("고장 신고를 찾을 수 없습니다: $reportId") }

        val updatedReport = faultReport.acknowledge(userId)
        val savedReport = faultReportRepository.save(updatedReport)

        // TODO: 신고자에게 접수 확인 알림 발송

        return FaultReportDto.from(savedReport)
    }

    /**
     * 작업 시작
     */
    @Transactional
    fun startWork(reportId: UUID): FaultReportDto {
        val faultReport = faultReportRepository.findById(reportId)
            .orElseThrow { IllegalArgumentException("고장 신고를 찾을 수 없습니다: $reportId") }

        val updatedReport = faultReport.startWork()
        val savedReport = faultReportRepository.save(updatedReport)

        return FaultReportDto.from(savedReport)
    }

    /**
     * 해결 완료
     */
    @Transactional
    fun completeFaultReport(reportId: UUID, userId: UUID, request: CompleteFaultReportRequest): FaultReportDto {
        val faultReport = faultReportRepository.findById(reportId)
            .orElseThrow { IllegalArgumentException("고장 신고를 찾을 수 없습니다: $reportId") }

        val updatedReport = faultReport.resolve(userId, request.resolutionMethod, request.resolutionDescription)
            .copy(
                actualRepairCost = request.actualRepairCost ?: faultReport.actualRepairCost,
                resolutionPhotos = request.resolutionPhotos ?: faultReport.resolutionPhotos,
                followUpRequired = request.followUpRequired,
                followUpDate = request.followUpDate,
                followUpNotes = request.followUpNotes
            )

        val savedReport = faultReportRepository.save(updatedReport)

        // TODO: 신고자에게 완료 알림 발송

        return FaultReportDto.from(savedReport)
    }

    /**
     * 고장 신고 삭제 (소프트 삭제)
     */
    @Transactional
    fun deleteFaultReport(id: UUID) {
        val faultReport = faultReportRepository.findById(id)
            .orElseThrow { IllegalArgumentException("고장 신고를 찾을 수 없습니다: $id") }

        // 상태를 취소로 변경
        val cancelledReport = faultReport.copy(reportStatus = ReportStatus.CANCELLED)
        faultReportRepository.save(cancelledReport)
    }

    /**
     * 신고 번호 생성
     */
    private fun generateReportNumber(): String {
        val now = LocalDateTime.now()
        val dateStr = now.format(java.time.format.DateTimeFormatter.ofPattern("yyyyMMdd"))
        val timeStr = now.format(java.time.format.DateTimeFormatter.ofPattern("HHmmss"))
        return "FR-$dateStr-$timeStr"
    }

    /**
     * 우선순위 결정
     */
    private fun determinePriority(severity: FaultSeverity, defaultPriority: FaultPriority): FaultPriority {
        return when (severity) {
            FaultSeverity.CATASTROPHIC -> FaultPriority.EMERGENCY
            FaultSeverity.CRITICAL -> FaultPriority.URGENT
            FaultSeverity.MAJOR -> FaultPriority.HIGH
            FaultSeverity.MODERATE -> defaultPriority
            FaultSeverity.MINOR -> FaultPriority.LOW
        }
    }

    /**
     * 긴급도 결정
     */
    private fun determineUrgency(severity: FaultSeverity, defaultUrgency: FaultUrgency): FaultUrgency {
        return when (severity) {
            FaultSeverity.CATASTROPHIC -> FaultUrgency.CRITICAL
            FaultSeverity.CRITICAL -> FaultUrgency.CRITICAL
            FaultSeverity.MAJOR -> FaultUrgency.HIGH
            FaultSeverity.MODERATE -> defaultUrgency
            FaultSeverity.MINOR -> FaultUrgency.LOW
        }
    }

    /**
     * 신고자별 신고 이력 조회
     */
    fun getReporterHistory(filter: ReporterHistoryFilter, pageable: Pageable): Page<FaultReportDto> {
        return faultReportRepository.findReporterHistory(
            companyId = filter.companyId,
            reporterType = filter.reporterType,
            reporterName = filter.reporterName,
            reporterUnitId = filter.reporterUnitId,
            reporterContact = filter.reporterContact,
            pageable = pageable
        ).map { FaultReportDto.from(it) }
    }

    /**
     * 신고자별 통계 조회
     */
    fun getReporterStatistics(
        companyId: UUID,
        reporterType: ReporterType?,
        dateFrom: LocalDateTime?,
        dateTo: LocalDateTime?
    ): List<ReporterStatisticsDto> {
        return faultReportRepositoryImpl.findReporterStatistics(companyId, reporterType, dateFrom, dateTo)
    }

    /**
     * 고장 신고 전체 통계 조회
     */
    fun getFaultReportStatistics(
        companyId: UUID,
        dateFrom: LocalDateTime?,
        dateTo: LocalDateTime?,
        groupBy: String?
    ): FaultReportStatisticsDto {
        return faultReportRepositoryImpl.findFaultReportStatistics(companyId, dateFrom, dateTo, groupBy)
    }

    /**
     * 응답 시간 통계 조회
     */
    fun getResponseTimeStatistics(
        companyId: UUID,
        dateFrom: LocalDateTime?,
        dateTo: LocalDateTime?
    ): ResponseTimeStatisticsDto {
        return faultReportRepositoryImpl.findResponseTimeStatistics(companyId, dateFrom, dateTo)
    }

    /**
     * 고장 유형별 통계 조회
     */
    fun getFaultTypeStatistics(
        companyId: UUID,
        dateFrom: LocalDateTime?,
        dateTo: LocalDateTime?
    ): List<FaultTypeStatisticsDto> {
        return faultReportRepositoryImpl.findFaultTypeStatistics(companyId, dateFrom, dateTo)
    }

    /**
     * 월별 고장 신고 추이 조회
     */
    fun getMonthlyTrend(companyId: UUID, months: Int): List<MonthlyTrendDto> {
        return faultReportRepositoryImpl.findMonthlyTrend(companyId, months)
    }
}