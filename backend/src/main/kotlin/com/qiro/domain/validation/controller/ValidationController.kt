package com.qiro.domain.validation.controller

import com.qiro.domain.validation.dto.*
import com.qiro.domain.validation.service.BusinessRuleService
import com.qiro.domain.validation.service.ValidationService
import com.qiro.global.response.ApiResponse
import com.qiro.global.security.CurrentUser
import com.qiro.global.security.UserPrincipal
import io.swagger.v3.oas.annotations.Operation
import io.swagger.v3.oas.annotations.Parameter
import io.swagger.v3.oas.annotations.tags.Tag
import jakarta.validation.Valid
import org.springframework.data.domain.Page
import org.springframework.data.domain.Pageable
import org.springframework.data.web.PageableDefault
import org.springframework.format.annotation.DateTimeFormat
import org.springframework.http.ResponseEntity
import org.springframework.security.access.prepost.PreAuthorize
import org.springframework.web.bind.annotation.*
import java.time.LocalDateTime
import java.util.*

/**
 * 검증 및 비즈니스 규칙 컨트롤러
 */
@Tag(name = "Validation", description = "데이터 검증 및 비즈니스 규칙 관리 API")
@RestController
@RequestMapping("/api/v1/validation")
class ValidationController(
    private val validationService: ValidationService,
    private val businessRuleService: BusinessRuleService
) {

    /**
     * 엔티티 검증
     */
    @Operation(summary = "엔티티 검증", description = "지정된 엔티티의 데이터를 검증합니다")
    @PostMapping("/validate/{entityType}")
    @PreAuthorize("hasRole('USER')")
    fun validateEntity(
        @Parameter(description = "엔티티 타입") @PathVariable entityType: String,
        @Parameter(description = "검증할 데이터") @RequestBody entityData: Map<String, Any>,
        @Parameter(description = "작업 타입") @RequestParam(defaultValue = "CREATE") operation: String,
        @CurrentUser userPrincipal: UserPrincipal
    ): ResponseEntity<ApiResponse<ValidationResultDto>> {
        val result = validationService.validateEntity(
            entityType = entityType,
            entityData = entityData,
            companyId = userPrincipal.companyId,
            userId = userPrincipal.id,
            operation = operation
        )

        return ResponseEntity.ok(ApiResponse.success(result))
    }

    /**
     * 배치 검증
     */
    @Operation(summary = "배치 검증", description = "여러 엔티티를 한 번에 검증합니다")
    @PostMapping("/validate/batch")
    @PreAuthorize("hasRole('USER')")
    fun validateBatch(
        @Parameter(description = "배치 검증 요청") @Valid @RequestBody request: BatchValidationRequest,
        @CurrentUser userPrincipal: UserPrincipal
    ): ResponseEntity<ApiResponse<BatchValidationResultDto>> {
        val result = validationService.validateBatch(
            request = request,
            companyId = userPrincipal.companyId,
            userId = userPrincipal.id
        )

        return ResponseEntity.ok(ApiResponse.success(result))
    }

    /**
     * 데이터 무결성 검사
     */
    @Operation(summary = "데이터 무결성 검사", description = "지정된 엔티티의 데이터 무결성을 검사합니다")
    @PostMapping("/integrity-check/{entityType}")
    @PreAuthorize("hasRole('ADMIN')")
    fun checkDataIntegrity(
        @Parameter(description = "엔티티 타입") @PathVariable entityType: String,
        @CurrentUser userPrincipal: UserPrincipal
    ): ResponseEntity<ApiResponse<DataIntegrityCheckResultDto>> {
        val result = validationService.checkDataIntegrity(
            entityType = entityType,
            companyId = userPrincipal.companyId,
            userId = userPrincipal.id
        )

        return ResponseEntity.ok(ApiResponse.success(result))
    }

    /**
     * 검증 실행 통계 조회
     */
    @Operation(summary = "검증 실행 통계", description = "검증 실행 통계를 조회합니다")
    @GetMapping("/statistics/execution")
    @PreAuthorize("hasRole('ADMIN')")
    fun getExecutionStatistics(
        @Parameter(description = "시작일") @RequestParam @DateTimeFormat(iso = DateTimeFormat.ISO.DATE_TIME) startDate: LocalDateTime,
        @Parameter(description = "종료일") @RequestParam @DateTimeFormat(iso = DateTimeFormat.ISO.DATE_TIME) endDate: LocalDateTime,
        @CurrentUser userPrincipal: UserPrincipal
    ): ResponseEntity<ApiResponse<List<Map<String, Any>>>> {
        val statistics = validationService.getExecutionStatistics(
            companyId = userPrincipal.companyId,
            startDate = startDate,
            endDate = endDate
        )

        return ResponseEntity.ok(ApiResponse.success(statistics))
    }

    /**
     * 규칙별 실행 통계 조회
     */
    @Operation(summary = "규칙별 실행 통계", description = "규칙별 실행 통계를 조회합니다")
    @GetMapping("/statistics/rules")
    @PreAuthorize("hasRole('ADMIN')")
    fun getRuleExecutionStatistics(
        @Parameter(description = "시작일") @RequestParam @DateTimeFormat(iso = DateTimeFormat.ISO.DATE_TIME) startDate: LocalDateTime,
        @Parameter(description = "종료일") @RequestParam @DateTimeFormat(iso = DateTimeFormat.ISO.DATE_TIME) endDate: LocalDateTime,
        @CurrentUser userPrincipal: UserPrincipal
    ): ResponseEntity<ApiResponse<List<Map<String, Any>>>> {
        val statistics = validationService.getRuleExecutionStatistics(
            companyId = userPrincipal.companyId,
            startDate = startDate,
            endDate = endDate
        )

        return ResponseEntity.ok(ApiResponse.success(statistics))
    }
}

/**
 * 비즈니스 규칙 관리 컨트롤러
 */
@Tag(name = "Business Rules", description = "비즈니스 규칙 관리 API")
@RestController
@RequestMapping("/api/v1/business-rules")
class BusinessRuleController(
    private val businessRuleService: BusinessRuleService
) {

    /**
     * 비즈니스 규칙 생성
     */
    @Operation(summary = "비즈니스 규칙 생성", description = "새로운 비즈니스 규칙을 생성합니다")
    @PostMapping
    @PreAuthorize("hasRole('ADMIN')")
    fun createBusinessRule(
        @Parameter(description = "비즈니스 규칙 생성 요청") @Valid @RequestBody request: CreateBusinessRuleRequest,
        @CurrentUser userPrincipal: UserPrincipal
    ): ResponseEntity<ApiResponse<BusinessRuleDto>> {
        val result = businessRuleService.createBusinessRule(
            request = request,
            companyId = userPrincipal.companyId,
            userId = userPrincipal.id
        )

        return ResponseEntity.ok(ApiResponse.success(result))
    }

    /**
     * 비즈니스 규칙 수정
     */
    @Operation(summary = "비즈니스 규칙 수정", description = "기존 비즈니스 규칙을 수정합니다")
    @PutMapping("/{ruleId}")
    @PreAuthorize("hasRole('ADMIN')")
    fun updateBusinessRule(
        @Parameter(description = "규칙 ID") @PathVariable ruleId: UUID,
        @Parameter(description = "비즈니스 규칙 수정 요청") @Valid @RequestBody request: UpdateBusinessRuleRequest,
        @CurrentUser userPrincipal: UserPrincipal
    ): ResponseEntity<ApiResponse<BusinessRuleDto>> {
        val result = businessRuleService.updateBusinessRule(
            ruleId = ruleId,
            request = request,
            companyId = userPrincipal.companyId,
            userId = userPrincipal.id
        )

        return ResponseEntity.ok(ApiResponse.success(result))
    }

    /**
     * 비즈니스 규칙 삭제
     */
    @Operation(summary = "비즈니스 규칙 삭제", description = "비즈니스 규칙을 삭제합니다")
    @DeleteMapping("/{ruleId}")
    @PreAuthorize("hasRole('ADMIN')")
    fun deleteBusinessRule(
        @Parameter(description = "규칙 ID") @PathVariable ruleId: UUID,
        @CurrentUser userPrincipal: UserPrincipal
    ): ResponseEntity<ApiResponse<Void>> {
        businessRuleService.deleteBusinessRule(
            ruleId = ruleId,
            companyId = userPrincipal.companyId
        )

        return ResponseEntity.ok(ApiResponse.success())
    }

    /**
     * 비즈니스 규칙 조회
     */
    @Operation(summary = "비즈니스 규칙 조회", description = "특정 비즈니스 규칙을 조회합니다")
    @GetMapping("/{ruleId}")
    @PreAuthorize("hasRole('USER')")
    fun getBusinessRule(
        @Parameter(description = "규칙 ID") @PathVariable ruleId: UUID,
        @CurrentUser userPrincipal: UserPrincipal
    ): ResponseEntity<ApiResponse<BusinessRuleDto>> {
        val result = businessRuleService.getBusinessRule(
            ruleId = ruleId,
            companyId = userPrincipal.companyId
        )

        return ResponseEntity.ok(ApiResponse.success(result))
    }

    /**
     * 비즈니스 규칙 목록 조회
     */
    @Operation(summary = "비즈니스 규칙 목록 조회", description = "비즈니스 규칙 목록을 조회합니다")
    @GetMapping
    @PreAuthorize("hasRole('USER')")
    fun getBusinessRules(
        @Parameter(description = "규칙 타입") @RequestParam(required = false) ruleType: BusinessRuleType?,
        @Parameter(description = "엔티티 타입") @RequestParam(required = false) entityType: String?,
        @Parameter(description = "활성 여부") @RequestParam(required = false) isActive: Boolean?,
        @Parameter(description = "검색 키워드") @RequestParam(required = false) keyword: String?,
        @PageableDefault(size = 20) pageable: Pageable,
        @CurrentUser userPrincipal: UserPrincipal
    ): ResponseEntity<ApiResponse<Page<BusinessRuleDto>>> {
        val result = businessRuleService.getBusinessRules(
            companyId = userPrincipal.companyId,
            ruleType = ruleType,
            entityType = entityType,
            isActive = isActive,
            keyword = keyword,
            pageable = pageable
        )

        return ResponseEntity.ok(ApiResponse.success(result))
    }

    /**
     * 엔티티별 활성 규칙 조회
     */
    @Operation(summary = "엔티티별 활성 규칙 조회", description = "특정 엔티티의 활성 규칙을 조회합니다")
    @GetMapping("/entity/{entityType}")
    @PreAuthorize("hasRole('USER')")
    fun getActiveRulesByEntity(
        @Parameter(description = "엔티티 타입") @PathVariable entityType: String,
        @CurrentUser userPrincipal: UserPrincipal
    ): ResponseEntity<ApiResponse<List<BusinessRuleDto>>> {
        val result = businessRuleService.getActiveRulesByEntity(
            companyId = userPrincipal.companyId,
            entityType = entityType
        )

        return ResponseEntity.ok(ApiResponse.success(result))
    }

    /**
     * 규칙 타입별 활성 규칙 조회
     */
    @Operation(summary = "규칙 타입별 활성 규칙 조회", description = "특정 타입의 활성 규칙을 조회합니다")
    @GetMapping("/type/{ruleType}")
    @PreAuthorize("hasRole('USER')")
    fun getActiveRulesByType(
        @Parameter(description = "규칙 타입") @PathVariable ruleType: BusinessRuleType,
        @CurrentUser userPrincipal: UserPrincipal
    ): ResponseEntity<ApiResponse<List<BusinessRuleDto>>> {
        val result = businessRuleService.getActiveRulesByType(
            companyId = userPrincipal.companyId,
            ruleType = ruleType
        )

        return ResponseEntity.ok(ApiResponse.success(result))
    }

    /**
     * 비즈니스 규칙 활성화
     */
    @Operation(summary = "비즈니스 규칙 활성화", description = "비즈니스 규칙을 활성화합니다")
    @PostMapping("/{ruleId}/activate")
    @PreAuthorize("hasRole('ADMIN')")
    fun activateBusinessRule(
        @Parameter(description = "규칙 ID") @PathVariable ruleId: UUID,
        @CurrentUser userPrincipal: UserPrincipal
    ): ResponseEntity<ApiResponse<BusinessRuleDto>> {
        val result = businessRuleService.activateBusinessRule(
            ruleId = ruleId,
            companyId = userPrincipal.companyId,
            userId = userPrincipal.id
        )

        return ResponseEntity.ok(ApiResponse.success(result))
    }

    /**
     * 비즈니스 규칙 비활성화
     */
    @Operation(summary = "비즈니스 규칙 비활성화", description = "비즈니스 규칙을 비활성화합니다")
    @PostMapping("/{ruleId}/deactivate")
    @PreAuthorize("hasRole('ADMIN')")
    fun deactivateBusinessRule(
        @Parameter(description = "규칙 ID") @PathVariable ruleId: UUID,
        @CurrentUser userPrincipal: UserPrincipal
    ): ResponseEntity<ApiResponse<BusinessRuleDto>> {
        val result = businessRuleService.deactivateBusinessRule(
            ruleId = ruleId,
            companyId = userPrincipal.companyId,
            userId = userPrincipal.id
        )

        return ResponseEntity.ok(ApiResponse.success(result))
    }

    /**
     * 우선순위 범위 내 규칙 조회
     */
    @Operation(summary = "우선순위 범위 내 규칙 조회", description = "지정된 우선순위 범위 내의 규칙을 조회합니다")
    @GetMapping("/priority-range")
    @PreAuthorize("hasRole('USER')")
    fun getRulesByPriorityRange(
        @Parameter(description = "엔티티 타입") @RequestParam entityType: String,
        @Parameter(description = "최소 우선순위") @RequestParam minPriority: Int,
        @Parameter(description = "최대 우선순위") @RequestParam maxPriority: Int,
        @CurrentUser userPrincipal: UserPrincipal
    ): ResponseEntity<ApiResponse<List<BusinessRuleDto>>> {
        val result = businessRuleService.getRulesByPriorityRange(
            companyId = userPrincipal.companyId,
            entityType = entityType,
            minPriority = minPriority,
            maxPriority = maxPriority
        )

        return ResponseEntity.ok(ApiResponse.success(result))
    }

    /**
     * 규칙 우선순위 업데이트
     */
    @Operation(summary = "규칙 우선순위 업데이트", description = "비즈니스 규칙의 우선순위를 변경합니다")
    @PutMapping("/{ruleId}/priority")
    @PreAuthorize("hasRole('ADMIN')")
    fun updateRulePriority(
        @Parameter(description = "규칙 ID") @PathVariable ruleId: UUID,
        @Parameter(description = "새 우선순위") @RequestParam newPriority: Int,
        @CurrentUser userPrincipal: UserPrincipal
    ): ResponseEntity<ApiResponse<BusinessRuleDto>> {
        val result = businessRuleService.updateRulePriority(
            ruleId = ruleId,
            newPriority = newPriority,
            companyId = userPrincipal.companyId,
            userId = userPrincipal.id
        )

        return ResponseEntity.ok(ApiResponse.success(result))
    }

    /**
     * 규칙 복사
     */
    @Operation(summary = "규칙 복사", description = "기존 비즈니스 규칙을 복사하여 새 규칙을 생성합니다")
    @PostMapping("/{ruleId}/copy")
    @PreAuthorize("hasRole('ADMIN')")
    fun copyBusinessRule(
        @Parameter(description = "원본 규칙 ID") @PathVariable ruleId: UUID,
        @Parameter(description = "새 규칙 코드") @RequestParam newRuleCode: String,
        @Parameter(description = "새 규칙 이름") @RequestParam newRuleName: String,
        @CurrentUser userPrincipal: UserPrincipal
    ): ResponseEntity<ApiResponse<BusinessRuleDto>> {
        val result = businessRuleService.copyBusinessRule(
            sourceRuleId = ruleId,
            newRuleCode = newRuleCode,
            newRuleName = newRuleName,
            companyId = userPrincipal.companyId,
            userId = userPrincipal.id
        )

        return ResponseEntity.ok(ApiResponse.success(result))
    }

    /**
     * 규칙 템플릿 생성
     */
    @Operation(summary = "규칙 템플릿 생성", description = "기본 비즈니스 규칙 템플릿을 생성합니다")
    @PostMapping("/templates")
    @PreAuthorize("hasRole('ADMIN')")
    fun createRuleTemplates(
        @CurrentUser userPrincipal: UserPrincipal
    ): ResponseEntity<ApiResponse<List<BusinessRuleDto>>> {
        val result = businessRuleService.createRuleTemplates(
            companyId = userPrincipal.companyId,
            userId = userPrincipal.id
        )

        return ResponseEntity.ok(ApiResponse.success(result))
    }
}