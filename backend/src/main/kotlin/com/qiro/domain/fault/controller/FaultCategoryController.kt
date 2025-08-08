package com.qiro.domain.fault.controller

import com.qiro.common.response.ApiResponse
import com.qiro.domain.fault.dto.CreateFaultCategoryRequest
import com.qiro.domain.fault.dto.FaultCategoryDto
import com.qiro.domain.fault.dto.UpdateFaultCategoryRequest
import com.qiro.domain.fault.service.FaultCategoryService
import io.swagger.v3.oas.annotations.Operation
import io.swagger.v3.oas.annotations.Parameter
import io.swagger.v3.oas.annotations.tags.Tag
import org.springframework.http.HttpStatus
import org.springframework.web.bind.annotation.*
import java.util.*
import jakarta.validation.Valid

/**
 * 고장 분류 컨트롤러
 */
@RestController
@RequestMapping("/api/v1/fault-categories")
@Tag(name = "고장 분류", description = "고장 분류 관리 API")
class FaultCategoryController(
    private val faultCategoryService: FaultCategoryService
) {

    /**
     * 고장 분류 생성
     */
    @PostMapping
    @Operation(summary = "고장 분류 생성", description = "새로운 고장 분류를 생성합니다.")
    fun createFaultCategory(
        @Valid @RequestBody request: CreateFaultCategoryRequest
    ): ApiResponse<FaultCategoryDto> {
        val faultCategory = faultCategoryService.createFaultCategory(request)
        return ApiResponse.success(faultCategory, "고장 분류가 성공적으로 생성되었습니다.")
    }

    /**
     * 고장 분류 조회
     */
    @GetMapping("/{id}")
    @Operation(summary = "고장 분류 조회", description = "고장 분류 상세 정보를 조회합니다.")
    fun getFaultCategory(
        @Parameter(description = "고장 분류 ID") @PathVariable id: UUID
    ): ApiResponse<FaultCategoryDto> {
        val faultCategory = faultCategoryService.getFaultCategory(id)
        return ApiResponse.success(faultCategory)
    }

    /**
     * 회사별 고장 분류 목록 조회 (활성화된 것만)
     */
    @GetMapping
    @Operation(summary = "고장 분류 목록 조회", description = "회사별 활성화된 고장 분류 목록을 조회합니다.")
    fun getFaultCategories(
        @Parameter(description = "회사 ID") @RequestParam companyId: UUID
    ): ApiResponse<List<FaultCategoryDto>> {
        val categories = faultCategoryService.getFaultCategories(companyId)
        return ApiResponse.success(categories)
    }

    /**
     * 회사별 모든 고장 분류 조회
     */
    @GetMapping("/all")
    @Operation(summary = "모든 고장 분류 조회", description = "회사별 모든 고장 분류를 조회합니다.")
    fun getAllFaultCategories(
        @Parameter(description = "회사 ID") @RequestParam companyId: UUID
    ): ApiResponse<List<FaultCategoryDto>> {
        val categories = faultCategoryService.getAllFaultCategories(companyId)
        return ApiResponse.success(categories)
    }

    /**
     * 최상위 분류 조회
     */
    @GetMapping("/root")
    @Operation(summary = "최상위 분류 조회", description = "최상위 고장 분류를 조회합니다.")
    fun getRootCategories(
        @Parameter(description = "회사 ID") @RequestParam companyId: UUID
    ): ApiResponse<List<FaultCategoryDto>> {
        val rootCategories = faultCategoryService.getRootCategories(companyId)
        return ApiResponse.success(rootCategories)
    }

    /**
     * 하위 분류 조회
     */
    @GetMapping("/{parentId}/subcategories")
    @Operation(summary = "하위 분류 조회", description = "특정 분류의 하위 분류를 조회합니다.")
    fun getSubCategories(
        @Parameter(description = "상위 분류 ID") @PathVariable parentId: UUID,
        @Parameter(description = "회사 ID") @RequestParam companyId: UUID
    ): ApiResponse<List<FaultCategoryDto>> {
        val subCategories = faultCategoryService.getSubCategories(companyId, parentId)
        return ApiResponse.success(subCategories)
    }

    /**
     * 계층 구조 조회
     */
    @GetMapping("/hierarchy")
    @Operation(summary = "계층 구조 조회", description = "고장 분류의 전체 계층 구조를 조회합니다.")
    fun getCategoryHierarchy(
        @Parameter(description = "회사 ID") @RequestParam companyId: UUID
    ): ApiResponse<List<FaultCategoryDto>> {
        val hierarchy = faultCategoryService.getCategoryHierarchy(companyId)
        return ApiResponse.success(hierarchy)
    }

    /**
     * 레벨별 분류 조회
     */
    @GetMapping("/level/{level}")
    @Operation(summary = "레벨별 분류 조회", description = "특정 레벨의 고장 분류를 조회합니다.")
    fun getCategoriesByLevel(
        @Parameter(description = "분류 레벨") @PathVariable level: Int,
        @Parameter(description = "회사 ID") @RequestParam companyId: UUID
    ): ApiResponse<List<FaultCategoryDto>> {
        val categories = faultCategoryService.getCategoriesByLevel(companyId, level)
        return ApiResponse.success(categories)
    }

    /**
     * 즉시 응답 필요 분류 조회
     */
    @GetMapping("/immediate-response")
    @Operation(summary = "즉시 응답 필요 분류 조회", description = "즉시 응답이 필요한 고장 분류를 조회합니다.")
    fun getImmediateResponseCategories(
        @Parameter(description = "회사 ID") @RequestParam companyId: UUID
    ): ApiResponse<List<FaultCategoryDto>> {
        val categories = faultCategoryService.getImmediateResponseCategories(companyId)
        return ApiResponse.success(categories)
    }

    /**
     * 전문가 필요 분류 조회
     */
    @GetMapping("/specialist-required")
    @Operation(summary = "전문가 필요 분류 조회", description = "전문가가 필요한 고장 분류를 조회합니다.")
    fun getSpecialistRequiredCategories(
        @Parameter(description = "회사 ID") @RequestParam companyId: UUID
    ): ApiResponse<List<FaultCategoryDto>> {
        val categories = faultCategoryService.getSpecialistRequiredCategories(companyId)
        return ApiResponse.success(categories)
    }

    /**
     * 협력업체 필요 분류 조회
     */
    @GetMapping("/contractor-required")
    @Operation(summary = "협력업체 필요 분류 조회", description = "협력업체가 필요한 고장 분류를 조회합니다.")
    fun getContractorRequiredCategories(
        @Parameter(description = "회사 ID") @RequestParam companyId: UUID
    ): ApiResponse<List<FaultCategoryDto>> {
        val categories = faultCategoryService.getContractorRequiredCategories(companyId)
        return ApiResponse.success(categories)
    }

    /**
     * 팀별 기본 분류 조회
     */
    @GetMapping("/team/{team}")
    @Operation(summary = "팀별 기본 분류 조회", description = "특정 팀의 기본 고장 분류를 조회합니다.")
    fun getCategoriesByTeam(
        @Parameter(description = "팀명") @PathVariable team: String,
        @Parameter(description = "회사 ID") @RequestParam companyId: UUID
    ): ApiResponse<List<FaultCategoryDto>> {
        val categories = faultCategoryService.getCategoriesByTeam(companyId, team)
        return ApiResponse.success(categories)
    }

    /**
     * 분류명으로 검색
     */
    @GetMapping("/search")
    @Operation(summary = "분류명 검색", description = "분류명으로 고장 분류를 검색합니다.")
    fun searchCategories(
        @Parameter(description = "회사 ID") @RequestParam companyId: UUID,
        @Parameter(description = "검색 키워드") @RequestParam keyword: String
    ): ApiResponse<List<FaultCategoryDto>> {
        val categories = faultCategoryService.searchCategories(companyId, keyword)
        return ApiResponse.success(categories)
    }

    /**
     * 분류 코드로 조회
     */
    @GetMapping("/code/{categoryCode}")
    @Operation(summary = "분류 코드로 조회", description = "분류 코드로 고장 분류를 조회합니다.")
    fun getFaultCategoryByCode(
        @Parameter(description = "분류 코드") @PathVariable categoryCode: String,
        @Parameter(description = "회사 ID") @RequestParam companyId: UUID
    ): ApiResponse<FaultCategoryDto?> {
        val category = faultCategoryService.getFaultCategoryByCode(companyId, categoryCode)
        return ApiResponse.success(category)
    }

    /**
     * 고장 분류 업데이트
     */
    @PutMapping("/{id}")
    @Operation(summary = "고장 분류 업데이트", description = "고장 분류 정보를 업데이트합니다.")
    fun updateFaultCategory(
        @Parameter(description = "고장 분류 ID") @PathVariable id: UUID,
        @Valid @RequestBody request: UpdateFaultCategoryRequest
    ): ApiResponse<FaultCategoryDto> {
        val updatedCategory = faultCategoryService.updateFaultCategory(id, request)
        return ApiResponse.success(updatedCategory, "고장 분류가 성공적으로 업데이트되었습니다.")
    }

    /**
     * 고장 분류 활성화
     */
    @PatchMapping("/{id}/activate")
    @Operation(summary = "고장 분류 활성화", description = "고장 분류를 활성화합니다.")
    fun activateFaultCategory(
        @Parameter(description = "고장 분류 ID") @PathVariable id: UUID
    ): ApiResponse<FaultCategoryDto> {
        val activatedCategory = faultCategoryService.activateFaultCategory(id)
        return ApiResponse.success(activatedCategory, "고장 분류가 성공적으로 활성화되었습니다.")
    }

    /**
     * 고장 분류 비활성화
     */
    @PatchMapping("/{id}/deactivate")
    @Operation(summary = "고장 분류 비활성화", description = "고장 분류를 비활성화합니다.")
    fun deactivateFaultCategory(
        @Parameter(description = "고장 분류 ID") @PathVariable id: UUID
    ): ApiResponse<FaultCategoryDto> {
        val deactivatedCategory = faultCategoryService.deactivateFaultCategory(id)
        return ApiResponse.success(deactivatedCategory, "고장 분류가 성공적으로 비활성화되었습니다.")
    }

    /**
     * 기본 설정 업데이트
     */
    @PatchMapping("/{id}/defaults")
    @Operation(summary = "기본 설정 업데이트", description = "고장 분류의 기본 설정을 업데이트합니다.")
    fun updateCategoryDefaults(
        @Parameter(description = "고장 분류 ID") @PathVariable id: UUID,
        @Parameter(description = "기본 우선순위") @RequestParam(required = false) priority: String?,
        @Parameter(description = "기본 긴급도") @RequestParam(required = false) urgency: String?,
        @Parameter(description = "응답 시간(분)") @RequestParam(required = false) responseTime: Int?,
        @Parameter(description = "해결 시간(시간)") @RequestParam(required = false) resolutionTime: Int?
    ): ApiResponse<FaultCategoryDto> {
        val updatedCategory = faultCategoryService.updateCategoryDefaults(
            id,
            priority?.let { com.qiro.domain.fault.entity.FaultPriority.valueOf(it) },
            urgency?.let { com.qiro.domain.fault.entity.FaultUrgency.valueOf(it) },
            responseTime,
            resolutionTime
        )
        return ApiResponse.success(updatedCategory, "기본 설정이 성공적으로 업데이트되었습니다.")
    }

    /**
     * 고장 분류 삭제
     */
    @DeleteMapping("/{id}")
    @ResponseStatus(HttpStatus.NO_CONTENT)
    @Operation(summary = "고장 분류 삭제", description = "고장 분류를 삭제합니다.")
    fun deleteFaultCategory(
        @Parameter(description = "고장 분류 ID") @PathVariable id: UUID
    ): ApiResponse<Unit> {
        faultCategoryService.deleteFaultCategory(id)
        return ApiResponse.success(message = "고장 분류가 성공적으로 삭제되었습니다.")
    }
}