package com.qiro.domain.fault.service

import com.qiro.domain.fault.dto.CreateFaultCategoryRequest
import com.qiro.domain.fault.dto.FaultCategoryDto
import com.qiro.domain.fault.dto.UpdateFaultCategoryRequest
import com.qiro.domain.fault.entity.FaultCategory
import com.qiro.domain.fault.repository.FaultCategoryRepository
import org.springframework.stereotype.Service
import org.springframework.transaction.annotation.Transactional
import java.util.*

/**
 * 고장 분류 서비스
 */
@Service
@Transactional(readOnly = true)
class FaultCategoryService(
    private val faultCategoryRepository: FaultCategoryRepository
) {

    /**
     * 고장 분류 생성
     */
    @Transactional
    fun createFaultCategory(request: CreateFaultCategoryRequest): FaultCategoryDto {
        // 분류 코드 중복 확인
        if (faultCategoryRepository.existsByCompanyIdAndCategoryCode(request.companyId, request.categoryCode)) {
            throw IllegalArgumentException("이미 존재하는 분류 코드입니다: ${request.categoryCode}")
        }

        // 상위 분류 존재 확인
        if (request.parentCategoryId != null) {
            val parentCategory = faultCategoryRepository.findById(request.parentCategoryId)
                .orElseThrow { IllegalArgumentException("상위 분류를 찾을 수 없습니다: ${request.parentCategoryId}") }
            
            if (parentCategory.companyId != request.companyId) {
                throw IllegalArgumentException("상위 분류가 같은 회사에 속하지 않습니다")
            }
        }

        val faultCategory = FaultCategory(
            companyId = request.companyId,
            categoryCode = request.categoryCode,
            categoryName = request.categoryName,
            categoryDescription = request.categoryDescription,
            parentCategoryId = request.parentCategoryId,
            defaultPriority = request.defaultPriority,
            defaultUrgency = request.defaultUrgency,
            autoEscalationHours = request.autoEscalationHours,
            requiresImmediateResponse = request.requiresImmediateResponse,
            responseTimeMinutes = request.responseTimeMinutes,
            resolutionTimeHours = request.resolutionTimeHours,
            defaultAssignedTeam = request.defaultAssignedTeam,
            requiresSpecialist = request.requiresSpecialist,
            contractorRequired = request.contractorRequired,
            notifyManagement = request.notifyManagement,
            notifyResidents = request.notifyResidents,
            categoryLevel = request.categoryLevel,
            displayOrder = request.displayOrder
        )

        val savedCategory = faultCategoryRepository.save(faultCategory)
        return FaultCategoryDto.from(savedCategory)
    }

    /**
     * 고장 분류 조회
     */
    fun getFaultCategory(id: UUID): FaultCategoryDto {
        val faultCategory = faultCategoryRepository.findById(id)
            .orElseThrow { IllegalArgumentException("고장 분류를 찾을 수 없습니다: $id") }

        return FaultCategoryDto.from(faultCategory)
    }

    /**
     * 회사별 고장 분류 목록 조회 (활성화된 것만)
     */
    fun getFaultCategories(companyId: UUID): List<FaultCategoryDto> {
        return faultCategoryRepository.findByCompanyIdAndIsActiveTrueOrderByDisplayOrderAscCategoryNameAsc(companyId)
            .map { FaultCategoryDto.from(it) }
    }

    /**
     * 회사별 모든 고장 분류 조회
     */
    fun getAllFaultCategories(companyId: UUID): List<FaultCategoryDto> {
        return faultCategoryRepository.findByCompanyIdOrderByDisplayOrderAscCategoryNameAsc(companyId)
            .map { FaultCategoryDto.from(it) }
    }

    /**
     * 최상위 분류 조회
     */
    fun getRootCategories(companyId: UUID): List<FaultCategoryDto> {
        return faultCategoryRepository.findByCompanyIdAndParentCategoryIdIsNullAndIsActiveTrueOrderByDisplayOrderAscCategoryNameAsc(companyId)
            .map { FaultCategoryDto.from(it) }
    }

    /**
     * 하위 분류 조회
     */
    fun getSubCategories(companyId: UUID, parentCategoryId: UUID): List<FaultCategoryDto> {
        return faultCategoryRepository.findByCompanyIdAndParentCategoryIdAndIsActiveTrueOrderByDisplayOrderAscCategoryNameAsc(companyId, parentCategoryId)
            .map { FaultCategoryDto.from(it) }
    }

    /**
     * 계층 구조 조회
     */
    fun getCategoryHierarchy(companyId: UUID): List<FaultCategoryDto> {
        return faultCategoryRepository.findCategoryHierarchy(companyId)
            .map { FaultCategoryDto.from(it) }
    }

    /**
     * 레벨별 분류 조회
     */
    fun getCategoriesByLevel(companyId: UUID, level: Int): List<FaultCategoryDto> {
        return faultCategoryRepository.findByCompanyIdAndCategoryLevelAndIsActiveTrueOrderByDisplayOrderAscCategoryNameAsc(companyId, level)
            .map { FaultCategoryDto.from(it) }
    }

    /**
     * 즉시 응답 필요 분류 조회
     */
    fun getImmediateResponseCategories(companyId: UUID): List<FaultCategoryDto> {
        return faultCategoryRepository.findByCompanyIdAndRequiresImmediateResponseTrueAndIsActiveTrueOrderByCategoryNameAsc(companyId)
            .map { FaultCategoryDto.from(it) }
    }

    /**
     * 전문가 필요 분류 조회
     */
    fun getSpecialistRequiredCategories(companyId: UUID): List<FaultCategoryDto> {
        return faultCategoryRepository.findByCompanyIdAndRequiresSpecialistTrueAndIsActiveTrueOrderByCategoryNameAsc(companyId)
            .map { FaultCategoryDto.from(it) }
    }

    /**
     * 협력업체 필요 분류 조회
     */
    fun getContractorRequiredCategories(companyId: UUID): List<FaultCategoryDto> {
        return faultCategoryRepository.findByCompanyIdAndContractorRequiredTrueAndIsActiveTrueOrderByCategoryNameAsc(companyId)
            .map { FaultCategoryDto.from(it) }
    }

    /**
     * 팀별 기본 분류 조회
     */
    fun getCategoriesByTeam(companyId: UUID, team: String): List<FaultCategoryDto> {
        return faultCategoryRepository.findByCompanyIdAndDefaultAssignedTeamAndIsActiveTrueOrderByCategoryNameAsc(companyId, team)
            .map { FaultCategoryDto.from(it) }
    }

    /**
     * 분류명으로 검색
     */
    fun searchCategories(companyId: UUID, keyword: String): List<FaultCategoryDto> {
        return faultCategoryRepository.searchByKeyword(companyId, keyword)
            .map { FaultCategoryDto.from(it) }
    }

    /**
     * 분류 코드로 조회
     */
    fun getFaultCategoryByCode(companyId: UUID, categoryCode: String): FaultCategoryDto? {
        return faultCategoryRepository.findByCompanyIdAndCategoryCode(companyId, categoryCode)
            ?.let { FaultCategoryDto.from(it) }
    }

    /**
     * 고장 분류 업데이트
     */
    @Transactional
    fun updateFaultCategory(id: UUID, request: UpdateFaultCategoryRequest): FaultCategoryDto {
        val faultCategory = faultCategoryRepository.findById(id)
            .orElseThrow { IllegalArgumentException("고장 분류를 찾을 수 없습니다: $id") }

        val updatedCategory = faultCategory.copy(
            categoryName = request.categoryName ?: faultCategory.categoryName,
            categoryDescription = request.categoryDescription ?: faultCategory.categoryDescription,
            defaultPriority = request.defaultPriority ?: faultCategory.defaultPriority,
            defaultUrgency = request.defaultUrgency ?: faultCategory.defaultUrgency,
            autoEscalationHours = request.autoEscalationHours ?: faultCategory.autoEscalationHours,
            requiresImmediateResponse = request.requiresImmediateResponse ?: faultCategory.requiresImmediateResponse,
            responseTimeMinutes = request.responseTimeMinutes ?: faultCategory.responseTimeMinutes,
            resolutionTimeHours = request.resolutionTimeHours ?: faultCategory.resolutionTimeHours,
            defaultAssignedTeam = request.defaultAssignedTeam ?: faultCategory.defaultAssignedTeam,
            requiresSpecialist = request.requiresSpecialist ?: faultCategory.requiresSpecialist,
            contractorRequired = request.contractorRequired ?: faultCategory.contractorRequired,
            notifyManagement = request.notifyManagement ?: faultCategory.notifyManagement,
            notifyResidents = request.notifyResidents ?: faultCategory.notifyResidents,
            displayOrder = request.displayOrder ?: faultCategory.displayOrder,
            isActive = request.isActive ?: faultCategory.isActive
        )

        val savedCategory = faultCategoryRepository.save(updatedCategory)
        return FaultCategoryDto.from(savedCategory)
    }

    /**
     * 고장 분류 활성화
     */
    @Transactional
    fun activateFaultCategory(id: UUID): FaultCategoryDto {
        val faultCategory = faultCategoryRepository.findById(id)
            .orElseThrow { IllegalArgumentException("고장 분류를 찾을 수 없습니다: $id") }

        val activatedCategory = faultCategory.activate()
        val savedCategory = faultCategoryRepository.save(activatedCategory)
        return FaultCategoryDto.from(savedCategory)
    }

    /**
     * 고장 분류 비활성화
     */
    @Transactional
    fun deactivateFaultCategory(id: UUID): FaultCategoryDto {
        val faultCategory = faultCategoryRepository.findById(id)
            .orElseThrow { IllegalArgumentException("고장 분류를 찾을 수 없습니다: $id") }

        // 하위 분류가 있는지 확인
        if (faultCategoryRepository.existsByCompanyIdAndParentCategoryId(faultCategory.companyId, id)) {
            throw IllegalStateException("하위 분류가 있는 분류는 비활성화할 수 없습니다")
        }

        val deactivatedCategory = faultCategory.deactivate()
        val savedCategory = faultCategoryRepository.save(deactivatedCategory)
        return FaultCategoryDto.from(savedCategory)
    }

    /**
     * 고장 분류 삭제
     */
    @Transactional
    fun deleteFaultCategory(id: UUID) {
        val faultCategory = faultCategoryRepository.findById(id)
            .orElseThrow { IllegalArgumentException("고장 분류를 찾을 수 없습니다: $id") }

        // 하위 분류가 있는지 확인
        if (faultCategoryRepository.existsByCompanyIdAndParentCategoryId(faultCategory.companyId, id)) {
            throw IllegalStateException("하위 분류가 있는 분류는 삭제할 수 없습니다")
        }

        // TODO: 해당 분류를 사용하는 고장 신고가 있는지 확인

        faultCategoryRepository.deleteById(id)
    }

    /**
     * 기본 설정 업데이트
     */
    @Transactional
    fun updateCategoryDefaults(
        id: UUID,
        priority: com.qiro.domain.fault.entity.FaultPriority? = null,
        urgency: com.qiro.domain.fault.entity.FaultUrgency? = null,
        responseTime: Int? = null,
        resolutionTime: Int? = null
    ): FaultCategoryDto {
        val faultCategory = faultCategoryRepository.findById(id)
            .orElseThrow { IllegalArgumentException("고장 분류를 찾을 수 없습니다: $id") }

        val updatedCategory = faultCategory.updateDefaults(priority, urgency, responseTime, resolutionTime)
        val savedCategory = faultCategoryRepository.save(updatedCategory)
        return FaultCategoryDto.from(savedCategory)
    }
}