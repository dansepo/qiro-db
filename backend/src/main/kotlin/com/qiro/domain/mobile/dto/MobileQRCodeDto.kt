package com.qiro.domain.mobile.dto

import java.math.BigDecimal
import java.time.LocalDate
import java.time.LocalDateTime
import java.util.*

/**
 * QR코드 스캔 결과 DTO
 */
data class QRCodeScanResultDto(
    val qrCodeType: QRCodeType,
    val entityId: UUID,
    val entityData: Any,
    val scanTimestamp: LocalDateTime = LocalDateTime.now(),
    val isValid: Boolean = true,
    val errorMessage: String? = null
)

/**
 * QR코드 유형 열거형
 */
enum class QRCodeType {
    ASSET,          // 시설물 자산
    PART,           // 부품
    WORK_ORDER,     // 작업 지시서
    LOCATION,       // 위치
    MAINTENANCE     // 정비 계획
}

/**
 * 자산 QR코드 정보 DTO
 */
data class AssetQRCodeDto(
    val assetId: UUID,
    val assetNumber: String,
    val assetName: String,
    val assetType: String,
    val location: String,
    val manufacturer: String?,
    val modelNumber: String?,
    val installationDate: LocalDate?,
    val warrantyExpiry: LocalDate?,
    val status: String,
    val lastMaintenanceDate: LocalDate?,
    val nextMaintenanceDate: LocalDate?,
    val recentFaultReports: List<RecentFaultReportDto> = emptyList(),
    val maintenanceHistory: List<MaintenanceHistoryDto> = emptyList(),
    val specifications: Map<String, String> = emptyMap(),
    val manualUrl: String? = null,
    val contactInfo: ContactInfoDto? = null
)

/**
 * 부품 QR코드 정보 DTO
 */
data class PartQRCodeDto(
    val partId: UUID,
    val partNumber: String,
    val partName: String,
    val description: String?,
    val category: String,
    val manufacturer: String?,
    val unitPrice: BigDecimal?,
    val stockQuantity: Int,
    val minStockLevel: Int,
    val maxStockLevel: Int,
    val location: String?,
    val expiryDate: LocalDate?,
    val batchNumber: String?,
    val specifications: Map<String, String> = emptyMap(),
    val compatibleAssets: List<CompatibleAssetDto> = emptyList(),
    val usageInstructions: String? = null,
    val safetyNotes: String? = null,
    val supplierInfo: SupplierInfoDto? = null
)

/**
 * 작업 지시서 QR코드 정보 DTO
 */
data class WorkOrderQRCodeDto(
    val workOrderId: UUID,
    val workOrderNumber: String,
    val title: String,
    val description: String,
    val status: String,
    val priority: String,
    val assignedTechnician: String?,
    val scheduledStart: LocalDateTime?,
    val scheduledEnd: LocalDateTime?,
    val location: String,
    val workInstructions: String?,
    val safetyNotes: String?,
    val requiredParts: List<RequiredPartDto> = emptyList(),
    val checklistItems: List<ChecklistItemDto> = emptyList(),
    val canStart: Boolean = false,
    val canComplete: Boolean = false
)

/**
 * 위치 QR코드 정보 DTO
 */
data class LocationQRCodeDto(
    val locationId: UUID,
    val locationCode: String,
    val locationName: String,
    val description: String?,
    val building: String?,
    val floor: String?,
    val room: String?,
    val coordinates: CoordinatesDto?,
    val assetsAtLocation: List<AssetSummaryDto> = emptyList(),
    val activeWorkOrders: List<WorkOrderSummaryDto> = emptyList(),
    val emergencyContacts: List<ContactInfoDto> = emptyList(),
    val accessInstructions: String? = null,
    val safetyNotes: String? = null
)

/**
 * 최근 고장 신고 DTO
 */
data class RecentFaultReportDto(
    val reportId: UUID,
    val reportNumber: String,
    val title: String,
    val status: String,
    val reportedAt: LocalDateTime,
    val priority: String
)

/**
 * 정비 이력 DTO
 */
data class MaintenanceHistoryDto(
    val maintenanceId: UUID,
    val maintenanceType: String,
    val performedAt: LocalDateTime,
    val performedBy: String,
    val result: String,
    val nextDueDate: LocalDate?
)

/**
 * 연락처 정보 DTO
 */
data class ContactInfoDto(
    val name: String,
    val phone: String?,
    val email: String?,
    val department: String? = null
)

/**
 * 호환 자산 DTO
 */
data class CompatibleAssetDto(
    val assetId: UUID,
    val assetName: String,
    val assetType: String,
    val location: String
)

/**
 * 공급업체 정보 DTO
 */
data class SupplierInfoDto(
    val supplierId: UUID,
    val supplierName: String,
    val contactPerson: String?,
    val phone: String?,
    val email: String?,
    val leadTime: Int? = null // 일 단위
)

/**
 * 좌표 DTO
 */
data class CoordinatesDto(
    val latitude: Double,
    val longitude: Double,
    val altitude: Double? = null
)

/**
 * 자산 요약 DTO
 */
data class AssetSummaryDto(
    val assetId: UUID,
    val assetName: String,
    val assetType: String,
    val status: String
)

/**
 * 작업 지시서 요약 DTO
 */
data class WorkOrderSummaryDto(
    val workOrderId: UUID,
    val workOrderNumber: String,
    val title: String,
    val status: String,
    val priority: String,
    val assignedTechnician: String?
)

/**
 * QR코드 생성 요청 DTO
 */
data class GenerateQRCodeRequest(
    val qrCodeType: QRCodeType,
    val entityId: UUID,
    val size: Int = 200, // 픽셀 단위
    val format: String = "PNG" // PNG, JPG, SVG
)

/**
 * QR코드 생성 응답 DTO
 */
data class GenerateQRCodeResponse(
    val qrCodeData: String, // Base64 인코딩된 이미지 또는 SVG 텍스트
    val qrCodeUrl: String, // QR코드 이미지 URL
    val entityType: QRCodeType,
    val entityId: UUID,
    val generatedAt: LocalDateTime = LocalDateTime.now(),
    val expiresAt: LocalDateTime? = null
)

/**
 * 부품 사용 기록 요청 DTO
 */
data class RecordPartUsageRequest(
    val partId: UUID,
    val workOrderId: UUID,
    val quantityUsed: Int,
    val usageNotes: String? = null,
    val scannedAt: LocalDateTime = LocalDateTime.now(),
    val gpsLatitude: Double? = null,
    val gpsLongitude: Double? = null
)