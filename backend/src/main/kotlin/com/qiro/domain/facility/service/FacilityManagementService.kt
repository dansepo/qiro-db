package com.qiro.domain.facility.service

import com.qiro.domain.migration.dto.*
import org.springframework.data.domain.Page
import org.springframework.data.domain.Pageable
import java.time.LocalDate
import java.time.LocalDateTime
import java.util.*

/**
 * 시설 관리 서비스 인터페이스
 */
interface FacilityManagementService {
    
    // === 시설 자산 관리 ===
    
    /**
     * 시설 자산 생성
     */
    fun createFacilityAsset(request: CreateFacilityAssetRequest): FacilityAssetDto
    
    /**
     * 시설 자산 조회
     */
    fun getFacilityAsset(companyId: UUID, assetId: UUID): FacilityAssetDto?
    
    /**
     * 시설 자산 목록 조회
     */
    fun getFacilityAssets(companyId: UUID, pageable: Pageable): Page<FacilityAssetDto>
    
    /**
     * 시설 자산 필터 조회
     */
    fun getFacilityAssetsWithFilter(filter: FacilityManagementFilter, pageable: Pageable): Page<FacilityAssetDto>
    
    /**
     * 시설 자산 수정
     */
    fun updateFacilityAsset(assetId: UUID, request: CreateFacilityAssetRequest): FacilityAssetDto
    
    /**
     * 시설 자산 삭제 (비활성화)
     */
    fun deleteFacilityAsset(companyId: UUID, assetId: UUID): Boolean
    
    /**
     * 보증 만료 예정 자산 조회
     */
    fun getAssetsWithExpiringWarranty(
        companyId: UUID, 
        startDate: LocalDate, 
        endDate: LocalDate, 
        pageable: Pageable
    ): Page<FacilityAssetDto>
    
    // === 작업 지시서 관리 ===
    
    /**
     * 작업 지시서 생성
     */
    fun createWorkOrder(request: CreateWorkOrderRequest): WorkOrderDto
    
    /**
     * 작업 지시서 조회
     */
    fun getWorkOrder(companyId: UUID, workOrderId: UUID): WorkOrderDto?
    
    /**
     * 작업 지시서 목록 조회
     */
    fun getWorkOrders(companyId: UUID, pageable: Pageable): Page<WorkOrderDto>
    
    /**
     * 작업 지시서 필터 조회
     */
    fun getWorkOrdersWithFilter(filter: FacilityManagementFilter, pageable: Pageable): Page<WorkOrderDto>
    
    /**
     * 작업 지시서 상태 업데이트
     */
    fun updateWorkOrderStatus(workOrderId: UUID, request: UpdateWorkOrderStatusRequest): WorkOrderDto
    
    /**
     * 작업 지시서 할당
     */
    fun assignWorkOrder(companyId: UUID, workOrderId: UUID, assignedTo: UUID): WorkOrderDto
    
    /**
     * 작업 지시서 완료
     */
    fun completeWorkOrder(
        companyId: UUID, 
        workOrderId: UUID, 
        completionNotes: String?, 
        actualHours: Double?
    ): WorkOrderDto
    
    /**
     * 지연된 작업 지시서 조회
     */
    fun getOverdueWorkOrders(companyId: UUID, pageable: Pageable): Page<WorkOrderDto>
    
    // === 고장 신고 관리 ===
    
    /**
     * 고장 신고 생성
     */
    fun createFaultReport(request: CreateFaultReportRequest): FaultReportDto
    
    /**
     * 고장 신고 조회
     */
    fun getFaultReport(companyId: UUID, reportId: UUID): FaultReportDto?
    
    /**
     * 고장 신고 목록 조회
     */
    fun getFaultReports(companyId: UUID, pageable: Pageable): Page<FaultReportDto>
    
    /**
     * 고장 신고 필터 조회
     */
    fun getFaultReportsWithFilter(filter: FacilityManagementFilter, pageable: Pageable): Page<FaultReportDto>
    
    /**
     * 고장 신고 상태 업데이트
     */
    fun updateFaultReportStatus(reportId: UUID, request: UpdateFaultReportStatusRequest): FaultReportDto
    
    /**
     * 고장 신고 할당
     */
    fun assignFaultReport(companyId: UUID, reportId: UUID, assignedTechnician: UUID): FaultReportDto
    
    /**
     * 고장 신고 해결
     */
    fun resolveFaultReport(
        companyId: UUID, 
        reportId: UUID, 
        resolutionNotes: String?
    ): FaultReportDto
    
    /**
     * 긴급 고장 신고 조회
     */
    fun getCriticalFaultReports(companyId: UUID, pageable: Pageable): Page<FaultReportDto>
    
    /**
     * 미해결 고장 신고 조회
     */
    fun getUnresolvedFaultReports(companyId: UUID, pageable: Pageable): Page<FaultReportDto>
    
    // === 통계 및 분석 ===
    
    /**
     * 시설 관리 통계 조회
     */
    fun getFacilityManagementStatistics(companyId: UUID): FacilityManagementStatisticsDto
    
    /**
     * 자산별 작업 이력 조회
     */
    fun getAssetWorkHistory(companyId: UUID, assetId: UUID, pageable: Pageable): Page<WorkOrderDto>
    
    /**
     * 담당자별 작업 현황 조회
     */
    fun getAssigneeWorkload(companyId: UUID, assigneeId: UUID, pageable: Pageable): Page<WorkOrderDto>
    
    /**
     * 고장 신고에서 작업 지시서 생성
     */
    fun createWorkOrderFromFaultReport(
        companyId: UUID, 
        faultReportId: UUID, 
        workType: String,
        assignedTo: UUID?,
        estimatedHours: Double?
    ): WorkOrderDto
}