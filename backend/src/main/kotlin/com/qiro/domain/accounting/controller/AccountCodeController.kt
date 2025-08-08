package com.qiro.domain.accounting.controller

import com.qiro.common.response.ApiResponse
import com.qiro.common.security.CurrentUser
import com.qiro.domain.accounting.dto.*
import com.qiro.domain.accounting.entity.AccountType
import com.qiro.domain.accounting.service.AccountCodeService
import com.qiro.security.CustomUserPrincipal
import io.swagger.v3.oas.annotations.Operation
import io.swagger.v3.oas.annotations.Parameter
import io.swagger.v3.oas.annotations.tags.Tag
import org.springframework.data.domain.Page
import org.springframework.data.domain.Pageable
import org.springframework.data.web.PageableDefault
import org.springframework.http.HttpStatus
import org.springframework.web.bind.annotation.*
import java.util.*
import jakarta.validation.Valid

/**
 * 계정과목 관리 컨트롤러
 */
@Tag(name = "계정과목 관리", description = "계정과목 생성, 수정, 조회, 삭제 API")
@RestController
@RequestMapping("/api/v1/companies/{companyId}/account-codes")
class AccountCodeController(
    private val accountCodeService: AccountCodeService
) {

    @Operation(summary = "계정과목 생성", description = "새로운 계정과목을 생성합니다.")
    @PostMapping
    @ResponseStatus(HttpStatus.CREATED)
    fun createAccountCode(
        @Parameter(description = "회사 ID") @PathVariable companyId: UUID,
        @Valid @RequestBody request: CreateAccountCodeRequest,
        @CurrentUser userPrincipal: CustomUserPrincipal
    ): ApiResponse<AccountCodeDto> {
        val accountCode = accountCodeService.createAccountCode(companyId, request, userPrincipal.userId)
        return ApiResponse.success(accountCode, "계정과목이 성공적으로 생성되었습니다.")
    }

    @Operation(summary = "계정과목 수정", description = "기존 계정과목 정보를 수정합니다.")
    @PutMapping("/{accountId}")
    fun updateAccountCode(
        @Parameter(description = "회사 ID") @PathVariable companyId: UUID,
        @Parameter(description = "계정과목 ID") @PathVariable accountId: Long,
        @Valid @RequestBody request: UpdateAccountCodeRequest,
        @CurrentUser userPrincipal: CustomUserPrincipal
    ): ApiResponse<AccountCodeDto> {
        val accountCode = accountCodeService.updateAccountCode(companyId, accountId, request, userPrincipal.userId)
        return ApiResponse.success(accountCode, "계정과목이 성공적으로 수정되었습니다.")
    }

    @Operation(summary = "계정과목 삭제", description = "계정과목을 삭제합니다.")
    @DeleteMapping("/{accountId}")
    @ResponseStatus(HttpStatus.NO_CONTENT)
    fun deleteAccountCode(
        @Parameter(description = "회사 ID") @PathVariable companyId: UUID,
        @Parameter(description = "계정과목 ID") @PathVariable accountId: Long
    ): ApiResponse<Unit> {
        accountCodeService.deleteAccountCode(companyId, accountId)
        return ApiResponse.success(Unit, "계정과목이 성공적으로 삭제되었습니다.")
    }

    @Operation(summary = "계정과목 단건 조회", description = "특정 계정과목의 상세 정보를 조회합니다.")
    @GetMapping("/{accountId}")
    fun getAccountCode(
        @Parameter(description = "회사 ID") @PathVariable companyId: UUID,
        @Parameter(description = "계정과목 ID") @PathVariable accountId: Long
    ): ApiResponse<AccountCodeDto> {
        val accountCode = accountCodeService.getAccountCode(companyId, accountId)
        return ApiResponse.success(accountCode)
    }

    @Operation(summary = "계정과목 목록 조회", description = "회사의 모든 계정과목 목록을 페이징으로 조회합니다.")
    @GetMapping
    fun getAccountCodes(
        @Parameter(description = "회사 ID") @PathVariable companyId: UUID,
        @Parameter(description = "활성 계정과목만 조회") @RequestParam(defaultValue = "false") activeOnly: Boolean,
        @PageableDefault(size = 20) pageable: Pageable
    ): ApiResponse<Page<AccountCodeDto>> {
        val accountCodes = if (activeOnly) {
            accountCodeService.getActiveAccountCodes(companyId, pageable)
        } else {
            accountCodeService.getAccountCodes(companyId, pageable)
        }
        return ApiResponse.success(accountCodes)
    }

    @Operation(summary = "계정과목 검색", description = "다양한 조건으로 계정과목을 검색합니다.")
    @PostMapping("/search")
    fun searchAccountCodes(
        @Parameter(description = "회사 ID") @PathVariable companyId: UUID,
        @Valid @RequestBody searchRequest: AccountCodeSearchRequest,
        @PageableDefault(size = 20) pageable: Pageable
    ): ApiResponse<Page<AccountCodeDto>> {
        val accountCodes = accountCodeService.searchAccountCodes(companyId, searchRequest, pageable)
        return ApiResponse.success(accountCodes)
    }

    @Operation(summary = "계정과목 계층 구조 조회", description = "계정과목의 계층 구조를 트리 형태로 조회합니다.")
    @GetMapping("/hierarchy")
    fun getAccountCodeHierarchy(
        @Parameter(description = "회사 ID") @PathVariable companyId: UUID
    ): ApiResponse<List<AccountCodeHierarchyDto>> {
        val hierarchy = accountCodeService.getAccountCodeHierarchy(companyId)
        return ApiResponse.success(hierarchy)
    }

    @Operation(summary = "계정 유형별 계정과목 조회", description = "특정 계정 유형의 계정과목들을 조회합니다.")
    @GetMapping("/by-type/{accountType}")
    fun getAccountCodesByType(
        @Parameter(description = "회사 ID") @PathVariable companyId: UUID,
        @Parameter(description = "계정 유형") @PathVariable accountType: AccountType
    ): ApiResponse<List<AccountCodeDto>> {
        val accountCodes = accountCodeService.getAccountCodesByType(companyId, accountType)
        return ApiResponse.success(accountCodes)
    }

    @Operation(summary = "계정과목 통계 조회", description = "계정과목 관련 통계 정보를 조회합니다.")
    @GetMapping("/statistics")
    fun getAccountCodeStatistics(
        @Parameter(description = "회사 ID") @PathVariable companyId: UUID
    ): ApiResponse<AccountCodeStatisticsDto> {
        val statistics = accountCodeService.getAccountCodeStatistics(companyId)
        return ApiResponse.success(statistics)
    }

    @Operation(summary = "다음 계정과목 코드 생성", description = "특정 계정 유형의 다음 계정과목 코드를 생성합니다.")
    @GetMapping("/next-code/{accountType}")
    fun generateNextAccountCode(
        @Parameter(description = "회사 ID") @PathVariable companyId: UUID,
        @Parameter(description = "계정 유형") @PathVariable accountType: AccountType
    ): ApiResponse<String> {
        val nextCode = accountCodeService.generateNextAccountCode(companyId, accountType)
        return ApiResponse.success(nextCode)
    }

    @Operation(summary = "기본 계정과목 생성", description = "회사의 기본 계정과목들을 일괄 생성합니다.")
    @PostMapping("/default")
    @ResponseStatus(HttpStatus.CREATED)
    fun createDefaultAccountCodes(
        @Parameter(description = "회사 ID") @PathVariable companyId: UUID,
        @CurrentUser userPrincipal: CustomUserPrincipal
    ): ApiResponse<Unit> {
        accountCodeService.createDefaultAccountCodes(companyId, userPrincipal.userId)
        return ApiResponse.success(Unit, "기본 계정과목이 성공적으로 생성되었습니다.")
    }
}