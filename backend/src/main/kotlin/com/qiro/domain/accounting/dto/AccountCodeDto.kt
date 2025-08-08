package com.qiro.domain.accounting.dto

import com.qiro.domain.accounting.entity.AccountType
import io.swagger.v3.oas.annotations.media.Schema
import java.math.BigDecimal
import java.time.LocalDateTime
import java.util.*

/**
 * 계정과목 응답 DTO
 */
@Schema(description = "계정과목 정보")
data class AccountCodeDto(
    @Schema(description = "계정과목 ID", example = "1")
    val id: Long,

    @Schema(description = "회사 ID")
    val companyId: UUID,

    @Schema(description = "계정과목 코드", example = "1100")
    val accountCode: String,

    @Schema(description = "계정과목명", example = "현금")
    val accountName: String,

    @Schema(description = "계정 유형")
    val accountType: AccountType,

    @Schema(description = "상위 계정과목 ID")
    val parentAccountId: Long? = null,

    @Schema(description = "상위 계정과목명")
    val parentAccountName: String? = null,

    @Schema(description = "계정 레벨", example = "1")
    val accountLevel: Int,

    @Schema(description = "활성 상태", example = "true")
    val isActive: Boolean,

    @Schema(description = "시스템 계정 여부", example = "false")
    val isSystemAccount: Boolean,

    @Schema(description = "설명")
    val description: String? = null,

    @Schema(description = "현재 잔액")
    val currentBalance: BigDecimal = BigDecimal.ZERO,

    @Schema(description = "차변 잔액")
    val debitBalance: BigDecimal = BigDecimal.ZERO,

    @Schema(description = "대변 잔액")
    val creditBalance: BigDecimal = BigDecimal.ZERO,

    @Schema(description = "전체 경로")
    val fullPath: String,

    @Schema(description = "하위 계정과목 수")
    val childAccountCount: Int = 0,

    @Schema(description = "생성일시")
    val createdAt: LocalDateTime,

    @Schema(description = "수정일시")
    val updatedAt: LocalDateTime,

    @Schema(description = "생성자 ID")
    val createdBy: UUID? = null,

    @Schema(description = "수정자 ID")
    val updatedBy: UUID? = null
)

/**
 * 계정과목 생성 요청 DTO
 */
@Schema(description = "계정과목 생성 요청")
data class CreateAccountCodeRequest(
    @Schema(description = "계정과목 코드", example = "1100", required = true)
    val accountCode: String,

    @Schema(description = "계정과목명", example = "현금", required = true)
    val accountName: String,

    @Schema(description = "계정 유형", required = true)
    val accountType: AccountType,

    @Schema(description = "상위 계정과목 ID")
    val parentAccountId: Long? = null,

    @Schema(description = "설명")
    val description: String? = null
)

/**
 * 계정과목 수정 요청 DTO
 */
@Schema(description = "계정과목 수정 요청")
data class UpdateAccountCodeRequest(
    @Schema(description = "계정과목명", example = "현금")
    val accountName: String? = null,

    @Schema(description = "계정 유형")
    val accountType: AccountType? = null,

    @Schema(description = "상위 계정과목 ID")
    val parentAccountId: Long? = null,

    @Schema(description = "활성 상태")
    val isActive: Boolean? = null,

    @Schema(description = "설명")
    val description: String? = null
)

/**
 * 계정과목 검색 요청 DTO
 */
@Schema(description = "계정과목 검색 요청")
data class AccountCodeSearchRequest(
    @Schema(description = "계정과목 코드 (부분 검색)")
    val accountCode: String? = null,

    @Schema(description = "계정과목명 (부분 검색)")
    val accountName: String? = null,

    @Schema(description = "계정 유형")
    val accountType: AccountType? = null,

    @Schema(description = "상위 계정과목 ID")
    val parentAccountId: Long? = null,

    @Schema(description = "계정 레벨")
    val accountLevel: Int? = null,

    @Schema(description = "활성 상태만 조회", example = "true")
    val activeOnly: Boolean = true,

    @Schema(description = "시스템 계정 포함 여부", example = "false")
    val includeSystemAccounts: Boolean = false
)

/**
 * 계정과목 계층 구조 DTO
 */
@Schema(description = "계정과목 계층 구조")
data class AccountCodeHierarchyDto(
    @Schema(description = "계정과목 정보")
    val account: AccountCodeDto,

    @Schema(description = "하위 계정과목 목록")
    val children: List<AccountCodeHierarchyDto> = emptyList()
)

/**
 * 계정과목 잔액 정보 DTO
 */
@Schema(description = "계정과목 잔액 정보")
data class AccountBalanceDto(
    @Schema(description = "계정과목 ID")
    val accountId: Long,

    @Schema(description = "계정과목 코드")
    val accountCode: String,

    @Schema(description = "계정과목명")
    val accountName: String,

    @Schema(description = "계정 유형")
    val accountType: AccountType,

    @Schema(description = "차변 금액")
    val debitAmount: BigDecimal,

    @Schema(description = "대변 금액")
    val creditAmount: BigDecimal,

    @Schema(description = "잔액")
    val balance: BigDecimal,

    @Schema(description = "기준일")
    val asOfDate: LocalDateTime
)

/**
 * 계정과목 통계 DTO
 */
@Schema(description = "계정과목 통계")
data class AccountCodeStatisticsDto(
    @Schema(description = "전체 계정과목 수")
    val totalAccounts: Long,

    @Schema(description = "활성 계정과목 수")
    val activeAccounts: Long,

    @Schema(description = "계정 유형별 통계")
    val accountTypeStatistics: Map<AccountType, Long>,

    @Schema(description = "계정 레벨별 통계")
    val accountLevelStatistics: Map<Int, Long>
)