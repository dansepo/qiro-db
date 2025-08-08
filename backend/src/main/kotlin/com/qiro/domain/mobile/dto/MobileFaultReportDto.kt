package com.qiro.domain.mobile.dto

import com.qiro.domain.fault.dto.FaultPriority
import com.qiro.domain.fault.dto.FaultStatus
import java.time.LocalDateTime
import java.util.*

/**
 * 모바일 고장 신고 DTO
 */
data class MobileFaultReportDto(
    val reportId: UUID,
    val reportNumber: String,
    val title: String,
    val description: String,
    val priority: FaultPriority,
    val status: FaultStatus,
    val location: String,
    val reportedAt: LocalDateTime,
    val expectedCompletion: LocalDateTime?,
    val actualCompletion: LocalDateTime?,
    val assignedTechnicianName: String?,
    val statusMessage: String,
    val photos: List<String> = emptyList(),
    val canCancel: Boolean = false,
    val canUpdate: Boolean = false
)

/**
 * 모바일 고장 신고 생성 요청 DTO
 */
data class CreateMobileFaultReportRequest(
    val title: String,
    val description: String,
    val priority: FaultPriority,
    val location: String,
    val assetId: UUID? = null,
    val unitId: UUID? = null,
    val photos: List<String> = emptyList(), // Base64 인코딩된 이미지 또는 파일 경로
    val gpsLatitude: Double? = null,
    val gpsLongitude: Double? = null,
    val contactPhone: String? = null
)

/**
 * 모바일 고장 신고 수정 요청 DTO
 */
data class UpdateMobileFaultReportRequest(
    val title: String? = null,
    val description: String? = null,
    val priority: FaultPriority? = null,
    val location: String? = null,
    val additionalPhotos: List<String> = emptyList(),
    val contactPhone: String? = null
)

/**
 * 모바일 고장 신고 목록 DTO
 */
data class MobileFaultReportListDto(
    val reportId: UUID,
    val reportNumber: String,
    val title: String,
    val priority: FaultPriority,
    val status: FaultStatus,
    val location: String,
    val reportedAt: LocalDateTime,
    val statusBadge: StatusBadge,
    val hasPhotos: Boolean = false,
    val isUrgent: Boolean = false
)

/**
 * 상태 배지 DTO
 */
data class StatusBadge(
    val text: String,
    val color: String, // HEX 색상 코드
    val backgroundColor: String // HEX 배경색 코드
)

/**
 * 모바일 고장 신고 상세 DTO
 */
data class MobileFaultReportDetailDto(
    val reportId: UUID,
    val reportNumber: String,
    val title: String,
    val description: String,
    val priority: FaultPriority,
    val status: FaultStatus,
    val location: String,
    val reportedAt: LocalDateTime,
    val expectedCompletion: LocalDateTime?,
    val actualCompletion: LocalDateTime?,
    val assignedTechnician: TechnicianInfo?,
    val workProgress: List<WorkProgressDto> = emptyList(),
    val photos: List<PhotoDto> = emptyList(),
    val timeline: List<TimelineEventDto> = emptyList(),
    val canCancel: Boolean = false,
    val canUpdate: Boolean = false,
    val estimatedCost: java.math.BigDecimal? = null,
    val actualCost: java.math.BigDecimal? = null
)

/**
 * 기술자 정보 DTO
 */
data class TechnicianInfo(
    val technicianId: UUID,
    val name: String,
    val phone: String?,
    val specialization: String?,
    val rating: Double? = null
)

/**
 * 작업 진행 상황 DTO
 */
data class WorkProgressDto(
    val stepName: String,
    val isCompleted: Boolean,
    val completedAt: LocalDateTime?,
    val description: String?
)

/**
 * 사진 DTO
 */
data class PhotoDto(
    val photoId: UUID,
    val fileName: String,
    val thumbnailUrl: String,
    val fullUrl: String,
    val uploadedAt: LocalDateTime,
    val description: String? = null
)

/**
 * 타임라인 이벤트 DTO
 */
data class TimelineEventDto(
    val eventId: UUID,
    val eventType: String,
    val title: String,
    val description: String,
    val occurredAt: LocalDateTime,
    val performedBy: String?,
    val icon: String? = null,
    val color: String? = null
)

/**
 * 모바일 고장 신고 필터 DTO
 */
data class MobileFaultReportFilter(
    val status: FaultStatus? = null,
    val priority: FaultPriority? = null,
    val dateRange: DateRangeFilter? = null,
    val location: String? = null
)

/**
 * 날짜 범위 필터 DTO
 */
data class DateRangeFilter(
    val startDate: LocalDateTime,
    val endDate: LocalDateTime
)