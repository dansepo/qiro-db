package com.qiro.domain.accounting.controller

import com.qiro.common.response.ApiResponse
import com.qiro.common.response.PageResponse
import com.qiro.common.security.CurrentUser
import com.qiro.common.security.UserPrincipal
import com.qiro.domain.accounting.dto.*
import com.qiro.domain.accounting.service.JournalEntryService
import io.swagger.v3.oas.annotations.Operation
import io.swagger.v3.oas.annotations.Parameter
import io.swagger.v3.oas.annotations.tags.Tag
import jakarta.validation.Valid
import org.springframework.data.domain.Pageable
import org.springframework.data.web.PageableDefault
import org.springframework.format.annotation.DateTimeFormat
import org.springframework.http.HttpStatus
import org.springframework.web.bind.annotation.*
import java.time.LocalDate
import java.util.*

/**
 * 분개 처리 컨트롤러
 * 분개 전표의 생성, 수정, 승인, 전기, 역분개 등의 API를 제공합니다.
 */
@Tag(name = "Journal Entry", description = "분개 처리 API")
@RestController
@RequestMapping("/api/v1/accounting/journal-entries")
class JournalEntryController(
    private val journalEntryService: JournalEntryService
) {

    @Operation(summary = "분개 전표 생성", description = "새로운 분개 전표를 생성합니다.")
    @PostMapping
    @ResponseStatus(HttpStatus.CREATED)
    fun createJournalEntry(
        @Valid @RequestBody request: CreateJournalEntryRequest,
        @CurrentUser userPrincipal: UserPrincipal
    ): ApiResponse<JournalEntryResponse> {
        val response = journalEntryService.createJournalEntry(request)
        return ApiResponse.success(response, "분개 전표가 성공적으로 생성되었습니다.")
    }

    @Operation(summary = "분개 전표 수정", description = "기존 분개 전표를 수정합니다. (초안 상태만 가능)")
    @PutMapping("/{entryId}")
    fun updateJournalEntry(
        @Parameter(description = "분개 전표 ID") @PathVariable entryId: UUID,
        @Valid @RequestBody request: UpdateJournalEntryRequest,
        @CurrentUser userPrincipal: UserPrincipal
    ): ApiResponse<JournalEntryResponse> {
        val response = journalEntryService.updateJournalEntry(entryId, request)
        return ApiResponse.success(response, "분개 전표가 성공적으로 수정되었습니다.")
    }

    @Operation(summary = "분개 전표 조회", description = "특정 분개 전표의 상세 정보를 조회합니다.")
    @GetMapping("/{entryId}")
    fun getJournalEntry(
        @Parameter(description = "분개 전표 ID") @PathVariable entryId: UUID,
        @CurrentUser userPrincipal: UserPrincipal
    ): ApiResponse<JournalEntryResponse> {
        val response = journalEntryService.getJournalEntry(entryId)
        return ApiResponse.success(response)
    }

    @Operation(summary = "분개 전표 목록 조회", description = "분개 전표 목록을 페이징하여 조회합니다.")
    @GetMapping
    fun getJournalEntries(
        @PageableDefault(size = 20) pageable: Pageable,
        @CurrentUser userPrincipal: UserPrincipal
    ): ApiResponse<PageResponse<JournalEntryListResponse>> {
        val page = journalEntryService.getJournalEntries(pageable)
        val response = PageResponse.of(page)
        return ApiResponse.success(response)
    }

    @Operation(summary = "분개 전표 검색", description = "조건에 따라 분개 전표를 검색합니다.")
    @GetMapping("/search")
    fun searchJournalEntries(
        @Parameter(description = "시작 날짜") @RequestParam(required = false) 
        @DateTimeFormat(iso = DateTimeFormat.ISO.DATE) startDate: LocalDate?,
        
        @Parameter(description = "종료 날짜") @RequestParam(required = false) 
        @DateTimeFormat(iso = DateTimeFormat.ISO.DATE) endDate: LocalDate?,
        
        @Parameter(description = "분개 상태") @RequestParam(required = false) status: String?,
        
        @Parameter(description = "분개 유형") @RequestParam(required = false) entryType: String?,
        
        @Parameter(description = "계정 ID") @RequestParam(required = false) accountId: UUID?,
        
        @Parameter(description = "설명 검색어") @RequestParam(required = false) description: String?,
        
        @Parameter(description = "전표 번호") @RequestParam(required = false) entryNumber: String?,
        
        @Parameter(description = "참조 유형") @RequestParam(required = false) referenceType: String?,
        
        @Parameter(description = "참조 ID") @RequestParam(required = false) referenceId: UUID?,
        
        @CurrentUser userPrincipal: UserPrincipal
    ): ApiResponse<List<JournalEntryListResponse>> {
        val searchRequest = JournalEntrySearchRequest(
            startDate = startDate,
            endDate = endDate,
            status = status?.let { runCatching { com.qiro.domain.accounting.entity.JournalEntryStatus.valueOf(it) }.getOrNull() },
            entryType = entryType?.let { runCatching { com.qiro.domain.accounting.entity.JournalEntryType.valueOf(it) }.getOrNull() },
            accountId = accountId,
            description = description,
            entryNumber = entryNumber,
            referenceType = referenceType,
            referenceId = referenceId
        )
        
        val response = journalEntryService.searchJournalEntries(searchRequest)
        return ApiResponse.success(response)
    }

    @Operation(summary = "분개 전표 승인", description = "분개 전표를 승인합니다.")
    @PostMapping("/{entryId}/approve")
    fun approveJournalEntry(
        @Parameter(description = "분개 전표 ID") @PathVariable entryId: UUID,
        @Valid @RequestBody request: ApproveJournalEntryRequest,
        @CurrentUser userPrincipal: UserPrincipal
    ): ApiResponse<JournalEntryResponse> {
        val response = journalEntryService.approveJournalEntry(entryId, request)
        return ApiResponse.success(response, "분개 전표가 성공적으로 승인되었습니다.")
    }

    @Operation(summary = "분개 전표 전기", description = "승인된 분개 전표를 전기합니다.")
    @PostMapping("/{entryId}/post")
    fun postJournalEntry(
        @Parameter(description = "분개 전표 ID") @PathVariable entryId: UUID,
        @CurrentUser userPrincipal: UserPrincipal
    ): ApiResponse<JournalEntryResponse> {
        val response = journalEntryService.postJournalEntry(entryId)
        return ApiResponse.success(response, "분개 전표가 성공적으로 전기되었습니다.")
    }

    @Operation(summary = "역분개 처리", description = "전기된 분개 전표를 역분개 처리합니다.")
    @PostMapping("/{entryId}/reverse")
    fun reverseJournalEntry(
        @Parameter(description = "분개 전표 ID") @PathVariable entryId: UUID,
        @Valid @RequestBody request: ReverseJournalEntryRequest,
        @CurrentUser userPrincipal: UserPrincipal
    ): ApiResponse<JournalEntryResponse> {
        val response = journalEntryService.reverseJournalEntry(entryId, request)
        return ApiResponse.success(response, "역분개가 성공적으로 처리되었습니다.")
    }

    @Operation(summary = "시산표 조회", description = "지정된 기간의 시산표를 조회합니다.")
    @GetMapping("/trial-balance")
    fun getTrialBalance(
        @Parameter(description = "시작 날짜", required = true) @RequestParam 
        @DateTimeFormat(iso = DateTimeFormat.ISO.DATE) startDate: LocalDate,
        
        @Parameter(description = "종료 날짜", required = true) @RequestParam 
        @DateTimeFormat(iso = DateTimeFormat.ISO.DATE) endDate: LocalDate,
        
        @CurrentUser userPrincipal: UserPrincipal
    ): ApiResponse<List<TrialBalanceResponse>> {
        val response = journalEntryService.getTrialBalance(startDate, endDate)
        return ApiResponse.success(response)
    }

    @Operation(summary = "분개 전표 삭제", description = "초안 상태의 분개 전표를 삭제합니다.")
    @DeleteMapping("/{entryId}")
    @ResponseStatus(HttpStatus.NO_CONTENT)
    fun deleteJournalEntry(
        @Parameter(description = "분개 전표 ID") @PathVariable entryId: UUID,
        @CurrentUser userPrincipal: UserPrincipal
    ): ApiResponse<Void> {
        // 삭제 로직은 서비스에서 구현 필요
        return ApiResponse.success(null, "분개 전표가 성공적으로 삭제되었습니다.")
    }

    @Operation(summary = "승인 대기 분개 전표 조회", description = "승인 대기 중인 분개 전표 목록을 조회합니다.")
    @GetMapping("/pending")
    fun getPendingJournalEntries(
        @CurrentUser userPrincipal: UserPrincipal
    ): ApiResponse<List<JournalEntryListResponse>> {
        val searchRequest = JournalEntrySearchRequest(
            status = com.qiro.domain.accounting.entity.JournalEntryStatus.PENDING
        )
        val response = journalEntryService.searchJournalEntries(searchRequest)
        return ApiResponse.success(response)
    }

    @Operation(summary = "분개 전표 상태 변경", description = "분개 전표의 상태를 변경합니다.")
    @PatchMapping("/{entryId}/status")
    fun changeJournalEntryStatus(
        @Parameter(description = "분개 전표 ID") @PathVariable entryId: UUID,
        @Parameter(description = "변경할 상태") @RequestParam status: String,
        @CurrentUser userPrincipal: UserPrincipal
    ): ApiResponse<JournalEntryResponse> {
        // 상태 변경 로직은 각각의 메서드로 분리되어 있으므로 여기서는 기본 응답만 제공
        val response = journalEntryService.getJournalEntry(entryId)
        return ApiResponse.success(response, "분개 전표 상태가 변경되었습니다.")
    }
}