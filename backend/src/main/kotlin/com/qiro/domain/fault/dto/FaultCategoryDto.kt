package com.qiro.domain.fault.dto

import com.qiro.domain.fault.entity.FaultCategory
import com.qiro.domain.fault.entity.FaultPriority
import com.qiro.domain.fault.entity.FaultUrgency
import jakarta.validation.constraints.*
import java.time.LocalDateTime
import java.util.*

/**
 * 고장 분류 DTO
 */
data class FaultCategoryDto(
    val id: UUID,
    val companyId: UUID,
    val categoryCode: String,
    val categoryName: String,
    val categoryDescription: String? = null,
    val parentCategoryId: UUID? = null,
    val defaultPriority: FaultPriority,
    val defaultUrgency: FaultUrgency,
    val autoEscalationHours: Int,
    val requiresImmediateResponse: Boolean,
    val responseTimeMinutes: Int,
    val resolutionTimeHours: Int,
    val defaultAssignedTeam: String? = null,
    val requiresSpecialist: Boolean,
    val contractorRequired: Boolean,
    val notifyManagement: Boolean,
    val notifyResidents: Boolean,
    val categoryLevel: Int,
    val displayOrder: Int,
    val isActive: Boolean,
    val createdAt: LocalDateTime? = null,
    val updatedAt: LocalDateTime? = null,
    val createdBy: UUID? = null,
    val updatedBy: UUID? = null,
    
    // 추가 정보
    val parentCategoryName: String? = null,
    val subCategories: List<FaultCategoryDto>? = null
) {
    companion object {
        /**
         * Entity를 DTO로 변환
         */
        fun from(entity: FaultCategory): FaultCategoryDto {
            return FaultCategoryDto(
                id = entity.id,
                companyId = entity.companyId,
                categoryCode = entity.categoryCode,
                categoryName = entity.categoryName,
                categoryDescription = entity.categoryDescription,
                parentCategoryId = entity.parentCategoryId,
                defaultPriority = entity.defaultPriority,
                defaultUrgency = entity.defaultUrgency,
                autoEscalationHours = entity.autoEscalationHours,
                requiresImmediateResponse = entity.requiresImmediateResponse,
                responseTimeMinutes = entity.responseTimeMinutes,
                resolutionTimeHours = entity.resolutionTimeHours,
                defaultAssignedTeam = entity.defaultAssignedTeam,
                requiresSpecialist = entity.requiresSpecialist,
                contractorRequired = entity.contractorRequired,
                notifyManagement = entity.notifyManagement,
                notifyResidents = entity.notifyResidents,
                categoryLevel = entity.categoryLevel,
                displayOrder = entity.displayOrder,
                isActive = entity.isActive,
                createdAt = entity.createdAt,
                updatedAt = entity.updatedAt,
                createdBy = entity.createdBy,
                updatedBy = entity.updatedBy
            )
        }
    }

    /**
     * 하위 분류 여부
     */
    fun hasParent(): Boolean = parentCategoryId != null

    /**
     * 최상위 분류 여부
     */
    fun isRootCategory(): Boolean = parentCategoryId == null

    /**
     * 긴급 분류 여부
     */
    fun isUrgentCategory(): Boolean {
        return requiresImmediateResponse || 
               defaultPriority == FaultPriority.EMERGENCY ||
               defaultUrgency == FaultUrgency.CRITICAL
    }
}

/**
 * 고장 분류 생성 요청 DTO
 */
data class CreateFaultCategoryRequest(
    @field:NotNull(message = "회사 ID는 필수입니다")
    val companyId: UUID,
    @field:NotBlank(message = "분류 코드는 필수입니다")
    @field:Size(max = 20, message = "분류 코드는 20자 이하여야 합니다")
    val categoryCode: String,
    @field:NotBlank(message = "분류명은 필수입니다")
    @field:Size(max = 100, message = "분류명은 100자 이하여야 합니다")
    val categoryName: String,
    val categoryDescription: String? = null,
    val parentCategoryId: UUID? = null,
    val defaultPriority: FaultPriority = FaultPriority.MEDIUM,
    val defaultUrgency: FaultUrgency = FaultUrgency.NORMAL,
    @field:Min(value = 1, message = "자동 에스컬레이션 시간은 1시간 이상이어야 합니다")
    val autoEscalationHours: Int = 24,
    val requiresImmediateResponse: Boolean = false,
    @field:Min(value = 1, message = "응답 시간은 1분 이상이어야 합니다")
    val responseTimeMinutes: Int = 240,
    @field:Min(value = 1, message = "해결 시간은 1시간 이상이어야 합니다")
    val resolutionTimeHours: Int = 24,
    @field:Size(max = 50, message = "기본 담당 팀명은 50자 이하여야 합니다")
    val defaultAssignedTeam: String? = null,
    val requiresSpecialist: Boolean = false,
    val contractorRequired: Boolean = false,
    val notifyManagement: Boolean = false,
    val notifyResidents: Boolean = false,
    @field:Min(value = 1, message = "분류 레벨은 1 이상이어야 합니다")
    @field:Max(value = 5, message = "분류 레벨은 5 이하여야 합니다")
    val categoryLevel: Int = 1,
    @field:Min(value = 0, message = "표시 순서는 0 이상이어야 합니다")
    val displayOrder: Int = 0
)

/**
 * 고장 분류 업데이트 요청 DTO
 */
data class UpdateFaultCategoryRequest(
    val categoryName: String? = null,
    val categoryDescription: String? = null,
    val defaultPriority: FaultPriority? = null,
    val defaultUrgency: FaultUrgency? = null,
    val autoEscalationHours: Int? = null,
    val requiresImmediateResponse: Boolean? = null,
    val responseTimeMinutes: Int? = null,
    val resolutionTimeHours: Int? = null,
    val defaultAssignedTeam: String? = null,
    val requiresSpecialist: Boolean? = null,
    val contractorRequired: Boolean? = null,
    val notifyManagement: Boolean? = null,
    val notifyResidents: Boolean? = null,
    val displayOrder: Int? = null,
    val isActive: Boolean? = null
)