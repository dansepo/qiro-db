package com.qiro.domain.fault.entity

import com.qiro.common.entity.BaseEntity
import jakarta.persistence.*
import java.util.*

/**
 * 고장 분류 엔티티
 * 고장 유형별 분류 및 기본 설정 관리
 */
@Entity
@Table(name = "fault_categories", schema = "bms")
data class FaultCategory(
    @Id
    @Column(name = "category_id")
    val id: UUID = UUID.randomUUID(),

    /**
     * 회사 ID (멀티테넌시)
     */
    @Column(name = "company_id", nullable = false)
    val companyId: UUID,

    /**
     * 분류 코드
     */
    @Column(name = "category_code", nullable = false, length = 20)
    val categoryCode: String,

    /**
     * 분류명
     */
    @Column(name = "category_name", nullable = false, length = 100)
    val categoryName: String,

    /**
     * 분류 설명
     */
    @Column(name = "category_description", columnDefinition = "TEXT")
    val categoryDescription: String? = null,

    /**
     * 상위 분류 ID
     */
    @Column(name = "parent_category_id")
    val parentCategoryId: UUID? = null,

    /**
     * 기본 우선순위
     */
    @Enumerated(EnumType.STRING)
    @Column(name = "default_priority", nullable = false)
    val defaultPriority: FaultPriority = FaultPriority.MEDIUM,

    /**
     * 기본 긴급도
     */
    @Enumerated(EnumType.STRING)
    @Column(name = "default_urgency", nullable = false)
    val defaultUrgency: FaultUrgency = FaultUrgency.NORMAL,

    /**
     * 자동 에스컬레이션 시간 (시간 단위)
     */
    @Column(name = "auto_escalation_hours", nullable = false)
    val autoEscalationHours: Int = 24,

    /**
     * 즉시 응답 필요 여부
     */
    @Column(name = "requires_immediate_response", nullable = false)
    val requiresImmediateResponse: Boolean = false,

    /**
     * 응답 시간 (분 단위)
     */
    @Column(name = "response_time_minutes", nullable = false)
    val responseTimeMinutes: Int = 240, // 4시간 기본값

    /**
     * 해결 시간 (시간 단위)
     */
    @Column(name = "resolution_time_hours", nullable = false)
    val resolutionTimeHours: Int = 24,

    /**
     * 기본 담당 팀
     */
    @Column(name = "default_assigned_team", length = 50)
    val defaultAssignedTeam: String? = null,

    /**
     * 전문가 필요 여부
     */
    @Column(name = "requires_specialist", nullable = false)
    val requiresSpecialist: Boolean = false,

    /**
     * 협력업체 필요 여부
     */
    @Column(name = "contractor_required", nullable = false)
    val contractorRequired: Boolean = false,

    /**
     * 관리진 알림 여부
     */
    @Column(name = "notify_management", nullable = false)
    val notifyManagement: Boolean = false,

    /**
     * 거주자 알림 여부
     */
    @Column(name = "notify_residents", nullable = false)
    val notifyResidents: Boolean = false,

    /**
     * 분류 레벨
     */
    @Column(name = "category_level", nullable = false)
    val categoryLevel: Int = 1,

    /**
     * 표시 순서
     */
    @Column(name = "display_order", nullable = false)
    val displayOrder: Int = 0,

    /**
     * 활성 상태
     */
    @Column(name = "is_active", nullable = false)
    val isActive: Boolean = true

) : BaseEntity() {

    /**
     * 하위 분류 여부 확인
     */
    fun hasParent(): Boolean = parentCategoryId != null

    /**
     * 최상위 분류 여부 확인
     */
    fun isRootCategory(): Boolean = parentCategoryId == null

    /**
     * 긴급 분류 여부 확인
     */
    fun isUrgentCategory(): Boolean {
        return requiresImmediateResponse || 
               defaultPriority == FaultPriority.EMERGENCY ||
               defaultUrgency == FaultUrgency.CRITICAL
    }

    /**
     * 분류 활성화
     */
    fun activate(): FaultCategory = this.copy(isActive = true)

    /**
     * 분류 비활성화
     */
    fun deactivate(): FaultCategory = this.copy(isActive = false)

    /**
     * 기본 설정 업데이트
     */
    fun updateDefaults(
        priority: FaultPriority? = null,
        urgency: FaultUrgency? = null,
        responseTime: Int? = null,
        resolutionTime: Int? = null
    ): FaultCategory {
        return this.copy(
            defaultPriority = priority ?: this.defaultPriority,
            defaultUrgency = urgency ?: this.defaultUrgency,
            responseTimeMinutes = responseTime ?: this.responseTimeMinutes,
            resolutionTimeHours = resolutionTime ?: this.resolutionTimeHours
        )
    }
}