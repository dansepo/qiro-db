package com.qiro.domain.mobile.service

import com.qiro.domain.fault.dto.FaultPriority
import com.qiro.domain.fault.dto.FaultStatus
import com.qiro.domain.fault.service.FaultReportService
import com.qiro.domain.mobile.dto.*
import org.springframework.data.domain.Page
import org.springframework.data.domain.PageImpl
import org.springframework.data.domain.Pageable
import org.springframework.stereotype.Service
import org.springframework.transaction.annotation.Transactional
import java.time.LocalDateTime
import java.util.*

/**
 * 모바일 고장 신고 서비스
 */
@Service
@Transactional
class MobileFaultReportService(
    private val faultReportService: FaultReportService
) {

    /**
     * 모바일 고장 신고 생성
     */
    fun createMobileFaultReport(
        companyId: UUID,
        request: CreateMobileFaultReportRequest,
        reporterId: UUID
    ): MobileFaultReportDto {
        // 기존 FaultReportService를 활용하여 고장 신고 생성
        val createRequest = com.qiro.domain.fault.dto.CreateFaultReportRequest(
            title = request.title,
            description = request.description,
            priority = request.priority,
            location = request.location,
            assetId = request.assetId,
            unitId = request.unitId,
            contactPhone = request.contactPhone,
            photos = request.photos
        )
        
        val faultReport = faultReportService.createFaultReport(companyId, createRequest, reporterId)
        return convertToMobileDto(faultReport)
    }

    /**
     * 모바일 고장 신고 수정
     */
    fun updateMobileFaultReport(
        reportId: UUID,
        request: UpdateMobileFaultReportRequest,
        userId: UUID
    ): MobileFaultReportDto {
        val updateRequest = com.qiro.domain.fault.dto.UpdateFaultReportRequest(
            title = request.title,
            description = request.description,
            priority = request.priority,
            location = request.location,
            contactPhone = request.contactPhone
        )
        
        val faultReport = faultReportService.updateFaultReport(reportId, updateRequest, userId)
        return convertToMobileDto(faultReport)
    }

    /**
     * 모바일 고장 신고 상세 조회
     */
    @Transactional(readOnly = true)
    fun getMobileFaultReportDetail(reportId: UUID): MobileFaultReportDetailDto {
        val faultReport = faultReportService.getFaultReport(reportId)
        return convertToMobileDetailDto(faultReport)
    }

    /**
     * 모바일 고장 신고 목록 조회
     */
    @Transactional(readOnly = true)
    fun getMobileFaultReports(
        companyId: UUID,
        filter: MobileFaultReportFilter?,
        pageable: Pageable
    ): Page<MobileFaultReportListDto> {
        // 필터를 기존 서비스 필터로 변환
        val faultFilter = filter?.let { mobileFilter ->
            com.qiro.domain.fault.dto.FaultReportFilter(
                status = mobileFilter.status,
                priority = mobileFilter.priority,
                startDate = mobileFilter.dateRange?.startDate?.toLocalDate(),
                endDate = mobileFilter.dateRange?.endDate?.toLocalDate(),
                location = mobileFilter.location
            )
        }
        
        val faultReports = if (faultFilter != null) {
            faultReportService.getFaultReportsWithFilter(companyId, faultFilter, pageable)
        } else {
            faultReportService.getFaultReports(companyId, pageable)
        }
        
        val mobileList = faultReports.content.map { convertToMobileListDto(it) }
        return PageImpl(mobileList, pageable, faultReports.totalElements)
    }

    /**
     * 사용자별 고장 신고 목록 조회
     */
    @Transactional(readOnly = true)
    fun getMyFaultReports(
        companyId: UUID,
        reporterId: UUID,
        pageable: Pageable
    ): Page<MobileFaultReportListDto> {
        val faultReports = faultReportService.getFaultReportsByReporter(companyId, reporterId, pageable)
        val mobileList = faultReports.content.map { convertToMobileListDto(it) }
        return PageImpl(mobileList, pageable, faultReports.totalElements)
    }

    /**
     * 긴급 고장 신고 목록 조회
     */
    @Transactional(readOnly = true)
    fun getUrgentFaultReports(companyId: UUID): List<MobileFaultReportListDto> {
        val urgentReports = faultReportService.getUrgentFaultReports(companyId)
        return urgentReports.map { convertToMobileListDto(it) }
    }

    /**
     * 고장 신고 취소
     */
    fun cancelFaultReport(reportId: UUID, userId: UUID, reason: String): MobileFaultReportDto {
        val faultReport = faultReportService.cancelFaultReport(reportId, userId, reason)
        return convertToMobileDto(faultReport)
    }

    /**
     * 고장 신고 사진 추가
     */
    fun addPhotosToFaultReport(
        reportId: UUID,
        photos: List<String>,
        userId: UUID
    ): MobileFaultReportDto {
        val faultReport = faultReportService.addPhotosToFaultReport(reportId, photos, userId)
        return convertToMobileDto(faultReport)
    }

    /**
     * FaultReportDto를 MobileFaultReportDto로 변환
     */
    private fun convertToMobileDto(faultReport: com.qiro.domain.fault.dto.FaultReportDto): MobileFaultReportDto {
        return MobileFaultReportDto(
            reportId = faultReport.reportId,
            reportNumber = faultReport.reportNumber,
            title = faultReport.title,
            description = faultReport.description,
            priority = faultReport.priority,
            status = faultReport.status,
            location = faultReport.location,
            reportedAt = faultReport.reportedAt,
            expectedCompletion = faultReport.expectedCompletion,
            actualCompletion = faultReport.actualCompletion,
            assignedTechnicianName = faultReport.assignedTechnicianName,
            statusMessage = getStatusMessage(faultReport.status),
            photos = faultReport.photos ?: emptyList(),
            canCancel = canCancelReport(faultReport.status),
            canUpdate = canUpdateReport(faultReport.status)
        )
    }

    /**
     * FaultReportDto를 MobileFaultReportDetailDto로 변환
     */
    private fun convertToMobileDetailDto(faultReport: com.qiro.domain.fault.dto.FaultReportDto): MobileFaultReportDetailDto {
        return MobileFaultReportDetailDto(
            reportId = faultReport.reportId,
            reportNumber = faultReport.reportNumber,
            title = faultReport.title,
            description = faultReport.description,
            priority = faultReport.priority,
            status = faultReport.status,
            location = faultReport.location,
            reportedAt = faultReport.reportedAt,
            expectedCompletion = faultReport.expectedCompletion,
            actualCompletion = faultReport.actualCompletion,
            assignedTechnician = faultReport.assignedTechnicianName?.let { 
                TechnicianInfo(
                    technicianId = UUID.randomUUID(), // 실제로는 기술자 ID를 가져와야 함
                    name = it,
                    phone = null,
                    specialization = null
                )
            },
            workProgress = generateWorkProgress(faultReport.status),
            photos = (faultReport.photos ?: emptyList()).map { photoUrl ->
                PhotoDto(
                    photoId = UUID.randomUUID(),
                    fileName = photoUrl.substringAfterLast("/"),
                    thumbnailUrl = photoUrl,
                    fullUrl = photoUrl,
                    uploadedAt = LocalDateTime.now()
                )
            },
            timeline = generateTimeline(faultReport),
            canCancel = canCancelReport(faultReport.status),
            canUpdate = canUpdateReport(faultReport.status),
            estimatedCost = faultReport.estimatedRepairCost,
            actualCost = faultReport.actualRepairCost
        )
    }

    /**
     * FaultReportDto를 MobileFaultReportListDto로 변환
     */
    private fun convertToMobileListDto(faultReport: com.qiro.domain.fault.dto.FaultReportDto): MobileFaultReportListDto {
        return MobileFaultReportListDto(
            reportId = faultReport.reportId,
            reportNumber = faultReport.reportNumber,
            title = faultReport.title,
            priority = faultReport.priority,
            status = faultReport.status,
            location = faultReport.location,
            reportedAt = faultReport.reportedAt,
            statusBadge = getStatusBadge(faultReport.status),
            hasPhotos = !faultReport.photos.isNullOrEmpty(),
            isUrgent = faultReport.priority == FaultPriority.URGENT
        )
    }

    /**
     * 상태 메시지 생성
     */
    private fun getStatusMessage(status: FaultStatus): String {
        return when (status) {
            FaultStatus.REPORTED -> "신고가 접수되었습니다"
            FaultStatus.ASSIGNED -> "담당자가 배정되었습니다"
            FaultStatus.IN_PROGRESS -> "수리 작업이 진행 중입니다"
            FaultStatus.COMPLETED -> "수리가 완료되었습니다"
            FaultStatus.VERIFIED -> "수리 결과가 확인되었습니다"
            FaultStatus.CLOSED -> "신고가 종료되었습니다"
            FaultStatus.CANCELLED -> "신고가 취소되었습니다"
        }
    }

    /**
     * 상태 배지 생성
     */
    private fun getStatusBadge(status: FaultStatus): StatusBadge {
        return when (status) {
            FaultStatus.REPORTED -> StatusBadge("신고됨", "#FFFFFF", "#6B7280")
            FaultStatus.ASSIGNED -> StatusBadge("배정됨", "#FFFFFF", "#3B82F6")
            FaultStatus.IN_PROGRESS -> StatusBadge("진행중", "#FFFFFF", "#F59E0B")
            FaultStatus.COMPLETED -> StatusBadge("완료됨", "#FFFFFF", "#10B981")
            FaultStatus.VERIFIED -> StatusBadge("확인됨", "#FFFFFF", "#059669")
            FaultStatus.CLOSED -> StatusBadge("종료됨", "#FFFFFF", "#6B7280")
            FaultStatus.CANCELLED -> StatusBadge("취소됨", "#FFFFFF", "#EF4444")
        }
    }

    /**
     * 작업 진행 상황 생성
     */
    private fun generateWorkProgress(status: FaultStatus): List<WorkProgressDto> {
        val steps = listOf(
            WorkProgressDto("신고 접수", true, LocalDateTime.now(), "고장 신고가 접수되었습니다"),
            WorkProgressDto("담당자 배정", status.ordinal >= FaultStatus.ASSIGNED.ordinal, 
                if (status.ordinal >= FaultStatus.ASSIGNED.ordinal) LocalDateTime.now() else null, 
                "담당 기술자가 배정되었습니다"),
            WorkProgressDto("수리 진행", status.ordinal >= FaultStatus.IN_PROGRESS.ordinal,
                if (status.ordinal >= FaultStatus.IN_PROGRESS.ordinal) LocalDateTime.now() else null,
                "수리 작업이 진행 중입니다"),
            WorkProgressDto("수리 완료", status.ordinal >= FaultStatus.COMPLETED.ordinal,
                if (status.ordinal >= FaultStatus.COMPLETED.ordinal) LocalDateTime.now() else null,
                "수리 작업이 완료되었습니다"),
            WorkProgressDto("결과 확인", status.ordinal >= FaultStatus.VERIFIED.ordinal,
                if (status.ordinal >= FaultStatus.VERIFIED.ordinal) LocalDateTime.now() else null,
                "수리 결과가 확인되었습니다")
        )
        return steps
    }

    /**
     * 타임라인 생성
     */
    private fun generateTimeline(faultReport: com.qiro.domain.fault.dto.FaultReportDto): List<TimelineEventDto> {
        val timeline = mutableListOf<TimelineEventDto>()
        
        timeline.add(TimelineEventDto(
            eventId = UUID.randomUUID(),
            eventType = "REPORTED",
            title = "고장 신고",
            description = "고장이 신고되었습니다",
            occurredAt = faultReport.reportedAt,
            performedBy = "신고자",
            icon = "report",
            color = "#3B82F6"
        ))
        
        if (faultReport.status.ordinal >= FaultStatus.ASSIGNED.ordinal) {
            timeline.add(TimelineEventDto(
                eventId = UUID.randomUUID(),
                eventType = "ASSIGNED",
                title = "담당자 배정",
                description = "${faultReport.assignedTechnicianName}님이 배정되었습니다",
                occurredAt = LocalDateTime.now(),
                performedBy = "시스템",
                icon = "assign",
                color = "#10B981"
            ))
        }
        
        return timeline.sortedByDescending { it.occurredAt }
    }

    /**
     * 신고 취소 가능 여부 확인
     */
    private fun canCancelReport(status: FaultStatus): Boolean {
        return status in listOf(FaultStatus.REPORTED, FaultStatus.ASSIGNED)
    }

    /**
     * 신고 수정 가능 여부 확인
     */
    private fun canUpdateReport(status: FaultStatus): Boolean {
        return status in listOf(FaultStatus.REPORTED, FaultStatus.ASSIGNED)
    }
}