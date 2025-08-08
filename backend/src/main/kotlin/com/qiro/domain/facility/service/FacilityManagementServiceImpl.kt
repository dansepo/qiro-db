package com.qiro.domain.facility.service

import com.qiro.domain.migration.common.BaseService
import com.qiro.domain.migration.dto.*
import com.qiro.domain.migration.entity.FacilityAsset
import com.qiro.domain.migration.entity.FaultReport
import com.qiro.domain.migration.entity.WorkOrder
import com.qiro.domain.migration.exception.ProcedureMigrationException
import com.qiro.domain.migration.repository.FacilityAssetRepository
import com.qiro.domain.migration.repository.FaultReportRepository
import com.qiro.domain.migration.repository.WorkOrderRepository
import org.slf4j.LoggerFactory
import org.springframework.data.domain.Page
import org.springframework.data.domain.Pageable
import org.springframework.stereotype.Service
import org.springframework.transaction.annotation.Transactional
import java.time.LocalDate
import java.time.LocalDateTime
import java.util.*

/**
 * 시설 관리 서비스 구현체
 * 
 * 기존 데이터베이스 프로시저들을 백엔드 서비스로 이관:
 * - 작업 지시서 관리 (7개 프로시저)
 * - 점검 및 유지보수 (5개 프로시저) 
 * - 고장 신고 관리 (5개 프로시저)
 * - 자산 관리 (2개 프로시저)
 */
@Service
@Transactional
class FacilityManagementServiceImpl(
    private val facilityAssetRepository: FacilityAssetRepository,
    private val workOrderRepository: WorkOrderRepository,
    private val faultReportRepository: FaultReportRepository
) : FacilityManagementService, BaseService {

    private val logger = LoggerFactory.getLogger(FacilityServiceImpl::class.java)

    // === 시설 자산 관리 ===

    /**
     * 시설 자산 생성
     * 기존 프로시저: bms.create_facility_asset
     */
    override fun createFacilityAsset(request: CreateFacilityAssetRequest): FacilityAssetDto {
        logger.info("시설 자산 생성 시작: companyId=${request.companyId}, assetCode=${request.assetCode}")
        
        // 입력 검증
        val validationResult = validateInput(request)
        if (!validationResult.isValid) {
            throw ProcedureMigrationException.ValidationException(
                "시설 자산 생성 입력 검증 실패: ${validationResult.errors.joinToString(", ")}"
            )
        }

        // 자산 코드 중복 체크
        if (facilityAssetRepository.existsByCompanyIdAndAssetCodeAndIsActiveTrue(request.companyId, request.assetCode)) {
            throw ProcedureMigrationException.DataIntegrityException(
                "이미 존재하는 자산 코드입니다: ${request.assetCode}"
            )
        }

        val facilityAsset = FacilityAsset(
            id = UUID.randomUUID(),
            companyId = request.companyId,
            buildingId = request.buildingId,
            unitId = request.unitId,
            assetCode = request.assetCode,
            assetName = request.assetName,
            assetType = request.assetType,
            assetCategory = request.assetCategory,
            location = request.location,
            manufacturer = request.manufacturer,
            modelNumber = request.modelNumber,
            serialNumber = request.serialNumber,
            installationDate = request.installationDate,
            warrantyExpiryDate = request.warrantyExpiryDate,
            assetStatus = "ACTIVE",
            isActive = true
        )

        val savedAsset = facilityAssetRepository.save(facilityAsset)
        
        logOperation("CREATE_FACILITY_ASSET", "자산 생성 완료: ${savedAsset.id}")
        
        return savedAsset.toDto()
    }

    /**
     * 시설 자산 조회
     */
    override fun getFacilityAsset(companyId: UUID, assetId: UUID): FacilityAssetDto? {
        return facilityAssetRepository.findById(assetId)
            .filter { it.companyId == companyId && it.isActive }
            .map { it.toDto() }
            .orElse(null)
    }

    /**
     * 시설 자산 목록 조회
     */
    override fun getFacilityAssets(companyId: UUID, pageable: Pageable): Page<FacilityAssetDto> {
        return facilityAssetRepository.findByCompanyIdAndIsActiveTrueOrderByAssetNameAsc(companyId, pageable)
            .map { it.toDto() }
    }

    /**
     * 시설 자산 필터 조회
     */
    override fun getFacilityAssetsWithFilter(filter: FacilityManagementFilter, pageable: Pageable): Page<FacilityAssetDto> {
        return facilityAssetRepository.findWithFilter(
            companyId = filter.companyId,
            buildingId = filter.buildingId,
            unitId = filter.unitId,
            assetType = filter.assetType,
            assetCategory = null,
            assetStatus = filter.status,
            location = null,
            pageable = pageable
        ).map { it.toDto() }
    }

    /**
     * 시설 자산 수정
     */
    override fun updateFacilityAsset(assetId: UUID, request: CreateFacilityAssetRequest): FacilityAssetDto {
        val existingAsset = facilityAssetRepository.findById(assetId)
            .filter { it.companyId == request.companyId && it.isActive }
            .orElseThrow { 
                ProcedureMigrationException.DataIntegrityException("시설 자산을 찾을 수 없습니다: $assetId") 
            }

        // 자산 코드 변경 시 중복 체크
        if (existingAsset.assetCode != request.assetCode) {
            if (facilityAssetRepository.existsByCompanyIdAndAssetCodeAndIsActiveTrue(request.companyId, request.assetCode)) {
                throw ProcedureMigrationException.DataIntegrityException(
                    "이미 존재하는 자산 코드입니다: ${request.assetCode}"
                )
            }
        }

        val updatedAsset = existingAsset.copy(
            buildingId = request.buildingId,
            unitId = request.unitId,
            assetCode = request.assetCode,
            assetName = request.assetName,
            assetType = request.assetType,
            assetCategory = request.assetCategory,
            location = request.location,
            manufacturer = request.manufacturer,
            modelNumber = request.modelNumber,
            serialNumber = request.serialNumber,
            installationDate = request.installationDate,
            warrantyExpiryDate = request.warrantyExpiryDate
        )

        val savedAsset = facilityAssetRepository.save(updatedAsset)
        
        logOperation("UPDATE_FACILITY_ASSET", "자산 수정 완료: $assetId")
        
        return savedAsset.toDto()
    }

    /**
     * 시설 자산 삭제 (비활성화)
     */
    override fun deleteFacilityAsset(companyId: UUID, assetId: UUID): Boolean {
        val asset = facilityAssetRepository.findById(assetId)
            .filter { it.companyId == companyId && it.isActive }
            .orElseThrow { 
                ProcedureMigrationException.DataIntegrityException("시설 자산을 찾을 수 없습니다: $assetId") 
            }

        val deactivatedAsset = asset.copy(isActive = false)
        facilityAssetRepository.save(deactivatedAsset)
        
        logOperation("DELETE_FACILITY_ASSET", "자산 비활성화 완료: $assetId")
        
        return true
    }

    /**
     * 보증 만료 예정 자산 조회
     */
    override fun getAssetsWithExpiringWarranty(
        companyId: UUID, 
        startDate: LocalDate, 
        endDate: LocalDate, 
        pageable: Pageable
    ): Page<FacilityAssetDto> {
        return facilityAssetRepository.findAssetsWithExpiringWarranty(companyId, startDate, endDate, pageable)
            .map { it.toDto() }
    }

    // === 작업 지시서 관리 ===

    /**
     * 작업 지시서 생성
     * 기존 프로시저: bms.create_work_order
     */
    override fun createWorkOrder(request: CreateWorkOrderRequest): WorkOrderDto {
        logger.info("작업 지시서 생성 시작: companyId=${request.companyId}, title=${request.title}")
        
        // 입력 검증
        val validationResult = validateInput(request)
        if (!validationResult.isValid) {
            throw ProcedureMigrationException.ValidationException(
                "작업 지시서 생성 입력 검증 실패: ${validationResult.errors.joinToString(", ")}"
            )
        }

        // 작업 지시서 번호 생성
        val workOrderNumber = generateWorkOrderNumber(request.companyId)

        val workOrder = WorkOrder(
            id = UUID.randomUUID(),
            companyId = request.companyId,
            workOrderNumber = workOrderNumber,
            title = request.title,
            description = request.description,
            workType = request.workType,
            priority = request.priority,
            workStatus = "PENDING",
            assetId = request.assetId,
            buildingId = request.buildingId,
            unitId = request.unitId,
            location = request.location,
            assignedTo = request.assignedTo,
            requestedBy = request.requestedBy,
            faultReportId = request.faultReportId,
            scheduledStartTime = request.scheduledStartTime,
            scheduledEndTime = request.scheduledEndTime,
            estimatedHours = request.estimatedHours,
            isActive = true
        )

        val savedWorkOrder = workOrderRepository.save(workOrder)
        
        logOperation("CREATE_WORK_ORDER", "작업 지시서 생성 완료: ${savedWorkOrder.id}")
        
        return savedWorkOrder.toDto()
    }

    /**
     * 작업 지시서 조회
     */
    override fun getWorkOrder(companyId: UUID, workOrderId: UUID): WorkOrderDto? {
        return workOrderRepository.findById(workOrderId)
            .filter { it.companyId == companyId && it.isActive }
            .map { it.toDto() }
            .orElse(null)
    }

    /**
     * 작업 지시서 목록 조회
     */
    override fun getWorkOrders(companyId: UUID, pageable: Pageable): Page<WorkOrderDto> {
        return workOrderRepository.findByCompanyIdAndIsActiveTrueOrderByCreatedAtDesc(companyId, pageable)
            .map { it.toDto() }
    }

    /**
     * 작업 지시서 필터 조회
     */
    override fun getWorkOrdersWithFilter(filter: FacilityManagementFilter, pageable: Pageable): Page<WorkOrderDto> {
        return workOrderRepository.findWithFilter(
            companyId = filter.companyId,
            workType = filter.workType,
            priority = filter.priority,
            workStatus = filter.status,
            assignedTo = filter.assignedTo,
            assetId = null,
            buildingId = filter.buildingId,
            startDate = filter.startDate,
            endDate = filter.endDate,
            pageable = pageable
        ).map { it.toDto() }
    }

    /**
     * 작업 지시서 상태 업데이트
     * 기존 프로시저: bms.update_work_order_status
     */
    override fun updateWorkOrderStatus(workOrderId: UUID, request: UpdateWorkOrderStatusRequest): WorkOrderDto {
        val workOrder = workOrderRepository.findById(workOrderId)
            .filter { it.isActive }
            .orElseThrow { 
                ProcedureMigrationException.DataIntegrityException("작업 지시서를 찾을 수 없습니다: $workOrderId") 
            }

        val updatedWorkOrder = workOrder.copy(
            workStatus = request.workStatus,
            completionNotes = request.completionNotes,
            actualStartTime = request.actualStartTime ?: workOrder.actualStartTime,
            actualEndTime = request.actualEndTime ?: workOrder.actualEndTime,
            actualHours = request.actualHours ?: workOrder.actualHours
        )

        val savedWorkOrder = workOrderRepository.save(updatedWorkOrder)
        
        logOperation("UPDATE_WORK_ORDER_STATUS", "작업 지시서 상태 업데이트: $workOrderId -> ${request.workStatus}")
        
        return savedWorkOrder.toDto()
    }

    /**
     * 작업 지시서 할당
     * 기존 프로시저: bms.assign_work_order
     */
    override fun assignWorkOrder(companyId: UUID, workOrderId: UUID, assignedTo: UUID): WorkOrderDto {
        val workOrder = workOrderRepository.findById(workOrderId)
            .filter { it.companyId == companyId && it.isActive }
            .orElseThrow { 
                ProcedureMigrationException.DataIntegrityException("작업 지시서를 찾을 수 없습니다: $workOrderId") 
            }

        val updatedWorkOrder = workOrder.copy(assignedTo = assignedTo)
        val savedWorkOrder = workOrderRepository.save(updatedWorkOrder)
        
        logOperation("ASSIGN_WORK_ORDER", "작업 지시서 할당: $workOrderId -> $assignedTo")
        
        return savedWorkOrder.toDto()
    }

    /**
     * 작업 지시서 완료
     * 기존 프로시저: bms.complete_work_order
     */
    override fun completeWorkOrder(
        companyId: UUID, 
        workOrderId: UUID, 
        completionNotes: String?, 
        actualHours: Double?
    ): WorkOrderDto {
        val workOrder = workOrderRepository.findById(workOrderId)
            .filter { it.companyId == companyId && it.isActive }
            .orElseThrow { 
                ProcedureMigrationException.DataIntegrityException("작업 지시서를 찾을 수 없습니다: $workOrderId") 
            }

        val now = LocalDateTime.now()
        val updatedWorkOrder = workOrder.copy(
            workStatus = "COMPLETED",
            completionNotes = completionNotes,
            actualEndTime = now,
            actualHours = actualHours,
            actualStartTime = workOrder.actualStartTime ?: now
        )

        val savedWorkOrder = workOrderRepository.save(updatedWorkOrder)
        
        logOperation("COMPLETE_WORK_ORDER", "작업 지시서 완료: $workOrderId")
        
        return savedWorkOrder.toDto()
    }

    /**
     * 지연된 작업 지시서 조회
     */
    override fun getOverdueWorkOrders(companyId: UUID, pageable: Pageable): Page<WorkOrderDto> {
        return workOrderRepository.findOverdueWorkOrders(companyId, LocalDateTime.now(), pageable)
            .map { it.toDto() }
    }

    // === 고장 신고 관리 ===

    /**
     * 고장 신고 생성
     * 기존 프로시저: bms.create_fault_report
     */
    override fun createFaultReport(request: CreateFaultReportRequest): FaultReportDto {
        logger.info("고장 신고 생성 시작: companyId=${request.companyId}, title=${request.title}")
        
        // 입력 검증
        val validationResult = validateInput(request)
        if (!validationResult.isValid) {
            throw ProcedureMigrationException.ValidationException(
                "고장 신고 생성 입력 검증 실패: ${validationResult.errors.joinToString(", ")}"
            )
        }

        // 신고 번호 생성
        val reportNumber = generateFaultReportNumber(request.companyId)

        val faultReport = FaultReport(
            id = UUID.randomUUID(),
            companyId = request.companyId,
            reportNumber = reportNumber,
            title = request.title,
            description = request.description,
            faultType = request.faultType,
            faultSeverity = request.faultSeverity,
            reportStatus = "REPORTED",
            assetId = request.assetId,
            buildingId = request.buildingId,
            unitId = request.unitId,
            location = request.location,
            reporterId = request.reporterId,
            reporterName = request.reporterName,
            reporterContact = request.reporterContact,
            reportedAt = LocalDateTime.now(),
            isActive = true
        )

        val savedFaultReport = faultReportRepository.save(faultReport)
        
        logOperation("CREATE_FAULT_REPORT", "고장 신고 생성 완료: ${savedFaultReport.id}")
        
        return savedFaultReport.toDto()
    }

    /**
     * 고장 신고 조회
     */
    override fun getFaultReport(companyId: UUID, reportId: UUID): FaultReportDto? {
        return faultReportRepository.findById(reportId)
            .filter { it.companyId == companyId && it.isActive }
            .map { it.toDto() }
            .orElse(null)
    }

    /**
     * 고장 신고 목록 조회
     */
    override fun getFaultReports(companyId: UUID, pageable: Pageable): Page<FaultReportDto> {
        return faultReportRepository.findByCompanyIdAndIsActiveTrueOrderByReportedAtDesc(companyId, pageable)
            .map { it.toDto() }
    }

    /**
     * 고장 신고 필터 조회
     */
    override fun getFaultReportsWithFilter(filter: FacilityManagementFilter, pageable: Pageable): Page<FaultReportDto> {
        return faultReportRepository.findWithFilter(
            companyId = filter.companyId,
            faultType = filter.workType, // workType을 faultType으로 매핑
            faultSeverity = filter.priority, // priority를 faultSeverity로 매핑
            reportStatus = filter.status,
            assignedTechnician = filter.assignedTo,
            assetId = null,
            buildingId = filter.buildingId,
            reporterId = null,
            startDate = filter.startDate,
            endDate = filter.endDate,
            pageable = pageable
        ).map { it.toDto() }
    }

    /**
     * 고장 신고 상태 업데이트
     * 기존 프로시저: bms.update_fault_report_status
     */
    override fun updateFaultReportStatus(reportId: UUID, request: UpdateFaultReportStatusRequest): FaultReportDto {
        val faultReport = faultReportRepository.findById(reportId)
            .filter { it.isActive }
            .orElseThrow { 
                ProcedureMigrationException.DataIntegrityException("고장 신고를 찾을 수 없습니다: $reportId") 
            }

        val updatedFaultReport = faultReport.copy(
            reportStatus = request.reportStatus,
            assignedTechnician = request.assignedTechnician ?: faultReport.assignedTechnician,
            resolutionNotes = request.resolutionNotes ?: faultReport.resolutionNotes,
            acknowledgedAt = request.acknowledgedAt ?: faultReport.acknowledgedAt,
            resolvedAt = request.resolvedAt ?: faultReport.resolvedAt
        )

        val savedFaultReport = faultReportRepository.save(updatedFaultReport)
        
        logOperation("UPDATE_FAULT_REPORT_STATUS", "고장 신고 상태 업데이트: $reportId -> ${request.reportStatus}")
        
        return savedFaultReport.toDto()
    }

    /**
     * 고장 신고 할당
     * 기존 프로시저: bms.assign_fault_report
     */
    override fun assignFaultReport(companyId: UUID, reportId: UUID, assignedTechnician: UUID): FaultReportDto {
        val faultReport = faultReportRepository.findById(reportId)
            .filter { it.companyId == companyId && it.isActive }
            .orElseThrow { 
                ProcedureMigrationException.DataIntegrityException("고장 신고를 찾을 수 없습니다: $reportId") 
            }

        val updatedFaultReport = faultReport.copy(
            assignedTechnician = assignedTechnician,
            reportStatus = "ASSIGNED",
            acknowledgedAt = LocalDateTime.now()
        )

        val savedFaultReport = faultReportRepository.save(updatedFaultReport)
        
        logOperation("ASSIGN_FAULT_REPORT", "고장 신고 할당: $reportId -> $assignedTechnician")
        
        return savedFaultReport.toDto()
    }

    /**
     * 고장 신고 해결
     */
    override fun resolveFaultReport(
        companyId: UUID, 
        reportId: UUID, 
        resolutionNotes: String?
    ): FaultReportDto {
        val faultReport = faultReportRepository.findById(reportId)
            .filter { it.companyId == companyId && it.isActive }
            .orElseThrow { 
                ProcedureMigrationException.DataIntegrityException("고장 신고를 찾을 수 없습니다: $reportId") 
            }

        val updatedFaultReport = faultReport.copy(
            reportStatus = "RESOLVED",
            resolutionNotes = resolutionNotes,
            resolvedAt = LocalDateTime.now()
        )

        val savedFaultReport = faultReportRepository.save(updatedFaultReport)
        
        logOperation("RESOLVE_FAULT_REPORT", "고장 신고 해결: $reportId")
        
        return savedFaultReport.toDto()
    }

    /**
     * 긴급 고장 신고 조회
     */
    override fun getCriticalFaultReports(companyId: UUID, pageable: Pageable): Page<FaultReportDto> {
        return faultReportRepository.findCriticalFaultReports(companyId, pageable)
            .map { it.toDto() }
    }

    /**
     * 미해결 고장 신고 조회
     */
    override fun getUnresolvedFaultReports(companyId: UUID, pageable: Pageable): Page<FaultReportDto> {
        return faultReportRepository.findUnresolvedFaultReports(companyId, pageable)
            .map { it.toDto() }
    }

    // === 통계 및 분석 ===

    /**
     * 시설 관리 통계 조회
     */
    override fun getFacilityManagementStatistics(companyId: UUID): FacilityManagementStatisticsDto {
        val totalAssets = facilityAssetRepository.countActiveAssetsByCompanyId(companyId)
        val assetsByStatus = facilityAssetRepository.countAssetsByStatus(companyId)
        
        val totalWorkOrders = workOrderRepository.countActiveWorkOrdersByCompanyId(companyId)
        val workOrdersByStatus = workOrderRepository.countWorkOrdersByStatus(companyId)
        
        val totalFaultReports = faultReportRepository.countActiveFaultReportsByCompanyId(companyId)
        val faultReportsByStatus = faultReportRepository.countFaultReportsByStatus(companyId)
        
        val averageResolutionTime = faultReportRepository.getAverageResolutionTimeInHours(companyId)

        // 상태별 카운트 맵 생성
        val workOrderStatusMap = workOrdersByStatus.associate { 
            (it[0] as String) to (it[1] as Long) 
        }
        val faultReportStatusMap = faultReportsByStatus.associate { 
            (it[0] as String) to (it[1] as Long) 
        }

        return FacilityManagementStatisticsDto(
            totalAssets = totalAssets,
            activeAssets = totalAssets, // 활성 자산만 조회하므로 동일
            assetsUnderMaintenance = 0L, // 별도 구현 필요
            totalWorkOrders = totalWorkOrders,
            pendingWorkOrders = workOrderStatusMap["PENDING"] ?: 0L,
            inProgressWorkOrders = workOrderStatusMap["IN_PROGRESS"] ?: 0L,
            completedWorkOrders = workOrderStatusMap["COMPLETED"] ?: 0L,
            totalFaultReports = totalFaultReports,
            openFaultReports = faultReportStatusMap.filterKeys { it != "RESOLVED" && it != "CANCELLED" }.values.sum(),
            resolvedFaultReports = faultReportStatusMap["RESOLVED"] ?: 0L,
            averageResolutionTime = averageResolutionTime
        )
    }

    /**
     * 자산별 작업 이력 조회
     */
    override fun getAssetWorkHistory(companyId: UUID, assetId: UUID, pageable: Pageable): Page<WorkOrderDto> {
        return workOrderRepository.findByCompanyIdAndAssetIdAndIsActiveTrueOrderByCreatedAtDesc(companyId, assetId, pageable)
            .map { it.toDto() }
    }

    /**
     * 담당자별 작업 현황 조회
     */
    override fun getAssigneeWorkload(companyId: UUID, assigneeId: UUID, pageable: Pageable): Page<WorkOrderDto> {
        return workOrderRepository.findByCompanyIdAndAssignedToAndIsActiveTrueOrderByCreatedAtDesc(companyId, assigneeId, pageable)
            .map { it.toDto() }
    }

    /**
     * 고장 신고에서 작업 지시서 생성
     */
    override fun createWorkOrderFromFaultReport(
        companyId: UUID, 
        faultReportId: UUID, 
        workType: String,
        assignedTo: UUID?,
        estimatedHours: Double?
    ): WorkOrderDto {
        val faultReport = faultReportRepository.findById(faultReportId)
            .filter { it.companyId == companyId && it.isActive }
            .orElseThrow { 
                ProcedureMigrationException.DataIntegrityException("고장 신고를 찾을 수 없습니다: $faultReportId") 
            }

        val workOrderRequest = CreateWorkOrderRequest(
            companyId = companyId,
            title = "고장 수리: ${faultReport.title}",
            description = faultReport.description,
            workType = workType,
            priority = when (faultReport.faultSeverity) {
                "CRITICAL" -> "HIGH"
                "HIGH" -> "HIGH"
                "MEDIUM" -> "MEDIUM"
                "LOW" -> "LOW"
                else -> "MEDIUM"
            },
            assetId = faultReport.assetId,
            buildingId = faultReport.buildingId,
            unitId = faultReport.unitId,
            location = faultReport.location,
            assignedTo = assignedTo,
            faultReportId = faultReportId,
            estimatedHours = estimatedHours
        )

        return createWorkOrder(workOrderRequest)
    }

    // === 유틸리티 메서드 ===

    /**
     * 입력 검증
     */
    override fun validateInput(input: Any): ValidationResult {
        val errors = mutableListOf<String>()

        when (input) {
            is CreateFacilityAssetRequest -> {
                if (input.assetCode.isBlank()) errors.add("자산 코드는 필수입니다")
                if (input.assetName.isBlank()) errors.add("자산명은 필수입니다")
                if (input.assetType.isBlank()) errors.add("자산 유형은 필수입니다")
            }
            is CreateWorkOrderRequest -> {
                if (input.title.isBlank()) errors.add("작업 제목은 필수입니다")
                if (input.workType.isBlank()) errors.add("작업 유형은 필수입니다")
            }
            is CreateFaultReportRequest -> {
                if (input.title.isBlank()) errors.add("신고 제목은 필수입니다")
                if (input.faultType.isBlank()) errors.add("고장 유형은 필수입니다")
            }
        }

        return ValidationResult(
            isValid = errors.isEmpty(),
            errors = errors
        )
    }

    /**
     * 작업 로그
     */
    override fun logOperation(operation: String, result: Any) {
        logger.info("FacilityService 작업 완료: $operation - $result")
    }

    /**
     * 작업 지시서 번호 생성
     */
    private fun generateWorkOrderNumber(companyId: UUID): String {
        val timestamp = System.currentTimeMillis()
        val random = (1000..9999).random()
        return "WO-${companyId.toString().substring(0, 8).uppercase()}-$timestamp-$random"
    }

    /**
     * 고장 신고 번호 생성
     */
    private fun generateFaultReportNumber(companyId: UUID): String {
        val timestamp = System.currentTimeMillis()
        val random = (1000..9999).random()
        return "FR-${companyId.toString().substring(0, 8).uppercase()}-$timestamp-$random"
    }

    // === 확장 함수 ===

    /**
     * FacilityAsset 엔티티를 DTO로 변환
     */
    private fun FacilityAsset.toDto(): FacilityAssetDto {
        return FacilityAssetDto(
            id = this.id,
            companyId = this.companyId,
            buildingId = this.buildingId,
            unitId = this.unitId,
            assetCode = this.assetCode,
            assetName = this.assetName,
            assetType = this.assetType,
            assetCategory = this.assetCategory,
            location = this.location,
            manufacturer = this.manufacturer,
            modelNumber = this.modelNumber,
            serialNumber = this.serialNumber,
            installationDate = this.installationDate,
            warrantyExpiryDate = this.warrantyExpiryDate,
            assetStatus = this.assetStatus,
            isActive = this.isActive,
            createdAt = this.createdAt,
            updatedAt = this.updatedAt
        )
    }

    /**
     * WorkOrder 엔티티를 DTO로 변환
     */
    private fun WorkOrder.toDto(): WorkOrderDto {
        return WorkOrderDto(
            id = this.id,
            companyId = this.companyId,
            workOrderNumber = this.workOrderNumber,
            title = this.title,
            description = this.description,
            workType = this.workType,
            priority = this.priority,
            workStatus = this.workStatus,
            assetId = this.assetId,
            buildingId = this.buildingId,
            unitId = this.unitId,
            location = this.location,
            assignedTo = this.assignedTo,
            requestedBy = this.requestedBy,
            faultReportId = this.faultReportId,
            scheduledStartTime = this.scheduledStartTime,
            scheduledEndTime = this.scheduledEndTime,
            actualStartTime = this.actualStartTime,
            actualEndTime = this.actualEndTime,
            estimatedHours = this.estimatedHours,
            actualHours = this.actualHours,
            completionNotes = this.completionNotes,
            isActive = this.isActive,
            createdAt = this.createdAt,
            updatedAt = this.updatedAt
        )
    }

    /**
     * FaultReport 엔티티를 DTO로 변환
     */
    private fun FaultReport.toDto(): FaultReportDto {
        return FaultReportDto(
            id = this.id,
            companyId = this.companyId,
            reportNumber = this.reportNumber,
            title = this.title,
            description = this.description,
            faultType = this.faultType,
            faultSeverity = this.faultSeverity,
            reportStatus = this.reportStatus,
            assetId = this.assetId,
            buildingId = this.buildingId,
            unitId = this.unitId,
            location = this.location,
            reporterId = this.reporterId,
            reporterName = this.reporterName,
            reporterContact = this.reporterContact,
            assignedTechnician = this.assignedTechnician,
            reportedAt = this.reportedAt,
            acknowledgedAt = this.acknowledgedAt,
            resolvedAt = this.resolvedAt,
            resolutionNotes = this.resolutionNotes,
            isActive = this.isActive,
            createdAt = this.createdAt,
            updatedAt = this.updatedAt
        )
    }
}