package com.qiro.domain.facility.entity

import jakarta.persistence.*
import org.springframework.data.annotation.CreatedDate
import org.springframework.data.annotation.LastModifiedDate
import org.springframework.data.jpa.domain.support.AuditingEntityListener
import java.math.BigDecimal
import java.time.LocalDate
import java.time.LocalDateTime

/**
 * 시설물 자산 엔티티
 * 건물 내 모든 시설물과 장비의 정보를 관리
 */
@Entity
@Table(name = "facility_assets", schema = "bms")
@EntityListeners(AuditingEntityListener::class)
data class FacilityAsset(
    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    @Column(name = "asset_id")
    val id: Long? = null,

    /**
     * 자산 코드 (고유 식별자)
     */
    @Column(name = "asset_code", nullable = false, unique = true, length = 50)
    val assetCode: String,

    /**
     * 자산명
     */
    @Column(name = "asset_name", nullable = false, length = 200)
    val assetName: String,

    /**
     * 자산 분류 (전기, 기계, 소방, 승강기 등)
     */
    @Column(name = "asset_category", nullable = false, length = 50)
    val assetCategory: String,

    /**
     * 자산 유형 (세부 분류)
     */
    @Column(name = "asset_type", length = 100)
    val assetType: String? = null,

    /**
     * 제조사
     */
    @Column(name = "manufacturer", length = 100)
    val manufacturer: String? = null,

    /**
     * 모델명
     */
    @Column(name = "model_name", length = 100)
    val modelName: String? = null,

    /**
     * 시리얼 번호
     */
    @Column(name = "serial_number", length = 100)
    val serialNumber: String? = null,

    /**
     * 설치 위치
     */
    @Column(name = "location", nullable = false, length = 200)
    val location: String,

    /**
     * 건물 ID (외래키)
     */
    @Column(name = "building_id", nullable = false)
    val buildingId: Long,

    /**
     * 층수
     */
    @Column(name = "floor_number")
    val floorNumber: Int? = null,

    /**
     * 구매일자
     */
    @Column(name = "purchase_date")
    val purchaseDate: LocalDate? = null,

    /**
     * 구매 금액
     */
    @Column(name = "purchase_amount", precision = 15, scale = 2)
    val purchaseAmount: BigDecimal? = null,

    /**
     * 설치일자
     */
    @Column(name = "installation_date")
    val installationDate: LocalDate? = null,

    /**
     * 보증 시작일
     */
    @Column(name = "warranty_start_date")
    val warrantyStartDate: LocalDate? = null,

    /**
     * 보증 종료일
     */
    @Column(name = "warranty_end_date")
    val warrantyEndDate: LocalDate? = null,

    /**
     * 자산 상태 (정상, 점검필요, 수리중, 폐기 등)
     */
    @Enumerated(EnumType.STRING)
    @Column(name = "asset_status", nullable = false)
    val assetStatus: AssetStatus = AssetStatus.NORMAL,

    /**
     * 사용 상태 (사용중, 미사용, 대기 등)
     */
    @Enumerated(EnumType.STRING)
    @Column(name = "usage_status", nullable = false)
    val usageStatus: UsageStatus = UsageStatus.IN_USE,

    /**
     * 중요도 (높음, 보통, 낮음)
     */
    @Enumerated(EnumType.STRING)
    @Column(name = "importance_level", nullable = false)
    val importanceLevel: ImportanceLevel = ImportanceLevel.MEDIUM,

    /**
     * 정기 점검 주기 (일 단위)
     */
    @Column(name = "maintenance_cycle_days")
    val maintenanceCycleDays: Int? = null,

    /**
     * 마지막 점검일
     */
    @Column(name = "last_maintenance_date")
    val lastMaintenanceDate: LocalDate? = null,

    /**
     * 다음 점검 예정일
     */
    @Column(name = "next_maintenance_date")
    val nextMaintenanceDate: LocalDate? = null,

    /**
     * 설명/메모
     */
    @Column(name = "description", columnDefinition = "TEXT")
    val description: String? = null,

    /**
     * 담당자 ID
     */
    @Column(name = "manager_id")
    val managerId: Long? = null,

    /**
     * 활성 상태
     */
    @Column(name = "is_active", nullable = false)
    val isActive: Boolean = true,

    /**
     * 생성일시
     */
    @CreatedDate
    @Column(name = "created_at", nullable = false, updatable = false)
    val createdAt: LocalDateTime? = null,

    /**
     * 수정일시
     */
    @LastModifiedDate
    @Column(name = "updated_at", nullable = false)
    val updatedAt: LocalDateTime? = null,

    /**
     * 생성자 ID
     */
    @Column(name = "created_by")
    val createdBy: Long? = null,

    /**
     * 수정자 ID
     */
    @Column(name = "updated_by")
    val updatedBy: Long? = null
) {
    /**
     * 보증 기간 만료 여부 확인
     */
    fun isWarrantyExpired(): Boolean {
        return warrantyEndDate?.isBefore(LocalDate.now()) ?: false
    }

    /**
     * 점검 필요 여부 확인
     */
    fun isMaintenanceRequired(): Boolean {
        return nextMaintenanceDate?.isBefore(LocalDate.now()) ?: false
    }

    /**
     * 자산 상태 업데이트
     */
    fun updateStatus(newStatus: AssetStatus): FacilityAsset {
        return this.copy(assetStatus = newStatus, updatedAt = LocalDateTime.now())
    }
}

/**
 * 자산 상태 열거형
 */
enum class AssetStatus(val description: String) {
    NORMAL("정상"),
    INSPECTION_REQUIRED("점검필요"),
    UNDER_REPAIR("수리중"),
    OUT_OF_ORDER("고장"),
    DISPOSED("폐기"),
    RESERVED("예약됨")
}

/**
 * 사용 상태 열거형
 */
enum class UsageStatus(val description: String) {
    IN_USE("사용중"),
    NOT_IN_USE("미사용"),
    STANDBY("대기"),
    MAINTENANCE("정비중")
}

/**
 * 중요도 열거형
 */
enum class ImportanceLevel(val description: String) {
    HIGH("높음"),
    MEDIUM("보통"),
    LOW("낮음")
}