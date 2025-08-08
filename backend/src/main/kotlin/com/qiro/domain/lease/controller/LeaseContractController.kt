package com.qiro.domain.lease.controller

import com.qiro.domain.lease.dto.*
import com.qiro.domain.lease.entity.ContractStatus
import com.qiro.domain.lease.service.LeaseContractService
import com.qiro.common.response.ApiResponse
import com.qiro.common.response.PageResponse
import com.qiro.common.security.CurrentUser
import com.qiro.common.security.UserPrincipal
import io.swagger.v3.oas.annotations.Operation
import io.swagger.v3.oas.annotations.Parameter
import io.swagger.v3.oas.annotations.tags.Tag
import jakarta.validation.Valid
import org.springframework.data.domain.Pageable
import org.springframework.data.web.PageableDefault
import org.springframework.http.HttpStatus
import org.springframework.web.bind.annotation.*
import java.util.*

@Tag(name = "임대차 계약 관리", description = "임대차 계약 관리 API")
@RestController
@RequestMapping("/api/v1/lease/contracts")
class LeaseContractController(
    private val leaseContractService: LeaseContractService
) {

    @Operation(summary = "계약 목록 조회", description = "회사의 모든 임대차 계약 목록을 조회합니다")
    @GetMapping
    fun getContracts(
        @CurrentUser userPrincipal: UserPrincipal,
        @PageableDefault(size = 20) pageable: Pageable
    ): ApiResponse<PageResponse<LeaseContractSummaryDto>> {
        val contracts = leaseContractService.getContracts(userPrincipal.companyId, pageable)
        return ApiResponse.success(PageResponse.of(contracts))
    }

    @Operation(summary = "상태별 계약 목록 조회", description = "특정 상태의 임대차 계약 목록을 조회합니다")
    @GetMapping("/status/{status}")
    fun getContractsByStatus(
        @CurrentUser userPrincipal: UserPrincipal,
        @Parameter(description = "계약 상태") @PathVariable status: ContractStatus,
        @PageableDefault(size = 20) pageable: Pageable
    ): ApiResponse<PageResponse<LeaseContractSummaryDto>> {
        val contracts = leaseContractService.getContractsByStatus(
            userPrincipal.companyId, status, pageable
        )
        return ApiResponse.success(PageResponse.of(contracts))
    }

    @Operation(summary = "계약 검색", description = "계약 번호, 임차인명, 임대인명, 세대번호로 계약을 검색합니다")
    @GetMapping("/search")
    fun searchContracts(
        @CurrentUser userPrincipal: UserPrincipal,
        @Parameter(description = "계약 상태") @RequestParam status: ContractStatus,
        @Parameter(description = "검색어") @RequestParam search: String,
        @PageableDefault(size = 20) pageable: Pageable
    ): ApiResponse<PageResponse<LeaseContractSummaryDto>> {
        val contracts = leaseContractService.searchContracts(
            userPrincipal.companyId, status, search, pageable
        )
        return ApiResponse.success(PageResponse.of(contracts))
    }

    @Operation(summary = "계약 상세 조회", description = "특정 임대차 계약의 상세 정보를 조회합니다")
    @GetMapping("/{contractId}")
    fun getContract(
        @CurrentUser userPrincipal: UserPrincipal,
        @Parameter(description = "계약 ID") @PathVariable contractId: UUID
    ): ApiResponse<LeaseContractDto> {
        val contract = leaseContractService.getContract(contractId, userPrincipal.companyId)
        return ApiResponse.success(contract)
    }

    @Operation(summary = "만료 예정 계약 조회", description = "지정된 일수 내에 만료 예정인 계약 목록을 조회합니다")
    @GetMapping("/expiring")
    fun getExpiringContracts(
        @CurrentUser userPrincipal: UserPrincipal,
        @Parameter(description = "조회 기간 (일)") @RequestParam(defaultValue = "30") days: Int,
        @PageableDefault(size = 20) pageable: Pageable
    ): ApiResponse<PageResponse<LeaseContractSummaryDto>> {
        val contracts = leaseContractService.getExpiringContracts(
            userPrincipal.companyId, days, pageable
        )
        return ApiResponse.success(PageResponse.of(contracts))
    }

    @Operation(summary = "계약 통계 조회", description = "임대차 계약 관련 통계 정보를 조회합니다")
    @GetMapping("/statistics")
    fun getContractStatistics(
        @CurrentUser userPrincipal: UserPrincipal
    ): ApiResponse<ContractStatisticsDto> {
        val statistics = leaseContractService.getContractStatistics(userPrincipal.companyId)
        return ApiResponse.success(statistics)
    }

    @Operation(summary = "계약 생성", description = "새로운 임대차 계약을 생성합니다")
    @PostMapping
    @ResponseStatus(HttpStatus.CREATED)
    fun createContract(
        @CurrentUser userPrincipal: UserPrincipal,
        @Valid @RequestBody request: CreateLeaseContractRequest
    ): ApiResponse<LeaseContractDto> {
        val contract = leaseContractService.createContract(userPrincipal.companyId, request)
        return ApiResponse.success(contract)
    }

    @Operation(summary = "계약 수정", description = "임대차 계약 정보를 수정합니다 (초안 상태만 가능)")
    @PutMapping("/{contractId}")
    fun updateContract(
        @CurrentUser userPrincipal: UserPrincipal,
        @Parameter(description = "계약 ID") @PathVariable contractId: UUID,
        @Valid @RequestBody request: UpdateLeaseContractRequest
    ): ApiResponse<LeaseContractDto> {
        val contract = leaseContractService.updateContract(
            contractId, userPrincipal.companyId, request
        )
        return ApiResponse.success(contract)
    }

    @Operation(summary = "계약 서명", description = "임대차 계약에 서명하여 서명 완료 상태로 변경합니다")
    @PostMapping("/{contractId}/sign")
    fun signContract(
        @CurrentUser userPrincipal: UserPrincipal,
        @Parameter(description = "계약 ID") @PathVariable contractId: UUID,
        @Valid @RequestBody request: SignContractRequest
    ): ApiResponse<LeaseContractDto> {
        val contract = leaseContractService.signContract(
            contractId, userPrincipal.companyId, request
        )
        return ApiResponse.success(contract)
    }

    @Operation(summary = "계약 활성화", description = "서명된 계약을 활성화하여 임대를 시작합니다")
    @PostMapping("/{contractId}/activate")
    fun activateContract(
        @CurrentUser userPrincipal: UserPrincipal,
        @Parameter(description = "계약 ID") @PathVariable contractId: UUID,
        @Valid @RequestBody request: ActivateContractRequest
    ): ApiResponse<LeaseContractDto> {
        val contract = leaseContractService.activateContract(
            contractId, userPrincipal.companyId, request
        )
        return ApiResponse.success(contract)
    }

    @Operation(summary = "계약 해지", description = "활성 상태의 계약을 해지합니다")
    @PostMapping("/{contractId}/terminate")
    fun terminateContract(
        @CurrentUser userPrincipal: UserPrincipal,
        @Parameter(description = "계약 ID") @PathVariable contractId: UUID,
        @Valid @RequestBody request: TerminateContractRequest
    ): ApiResponse<LeaseContractDto> {
        val contract = leaseContractService.terminateContract(
            contractId, userPrincipal.companyId, request
        )
        return ApiResponse.success(contract)
    }

    @Operation(summary = "계약 갱신", description = "활성 상태의 계약을 갱신하여 새로운 계약을 생성합니다")
    @PostMapping("/{contractId}/renew")
    fun renewContract(
        @CurrentUser userPrincipal: UserPrincipal,
        @Parameter(description = "계약 ID") @PathVariable contractId: UUID,
        @Valid @RequestBody request: RenewContractRequest
    ): ApiResponse<LeaseContractDto> {
        val contract = leaseContractService.renewContract(
            contractId, userPrincipal.companyId, request
        )
        return ApiResponse.success(contract)
    }

    @Operation(summary = "계약 삭제", description = "초안 상태의 계약을 삭제합니다")
    @DeleteMapping("/{contractId}")
    @ResponseStatus(HttpStatus.NO_CONTENT)
    fun deleteContract(
        @CurrentUser userPrincipal: UserPrincipal,
        @Parameter(description = "계약 ID") @PathVariable contractId: UUID
    ): ApiResponse<Unit> {
        leaseContractService.deleteContract(contractId, userPrincipal.companyId)
        return ApiResponse.success()
    }
}