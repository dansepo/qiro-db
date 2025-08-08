package com.qiro.domain.accounting.controller

import com.qiro.domain.accounting.dto.*
import com.qiro.domain.accounting.service.HomeTaxService
import org.springframework.http.ResponseEntity
import org.springframework.web.bind.annotation.*
import java.util.*

/**
 * 국세청 홈택스 연동 REST API Controller (건물관리 특화)
 * 부가세 신고서 자동 전송, 세금계산서 자동 발행/수취 기능 제공
 */
@RestController
@RequestMapping("/api/hometax")
@CrossOrigin(origins = ["*"])
class HomeTaxController(
    private val homeTaxService: HomeTaxService
) {

    /**
     * 홈택스 연동 설정
     * POST /api/hometax/connect
     */
    @PostMapping("/connect")
    fun connectHomeTax(
        @RequestParam companyId: UUID,
        @RequestBody request: HomeTaxConnectionRequest
    ): ResponseEntity<HomeTaxConnectionResponse> {
        val response = homeTaxService.connectHomeTax(companyId, request)
        return ResponseEntity.ok(response)
    }

    /**
     * 부가세 신고서 생성 및 전송
     * POST /api/hometax/vat-return
     */
    @PostMapping("/vat-return")
    fun submitVatReturn(
        @RequestParam companyId: UUID,
        @RequestBody request: VatReturnSubmissionRequest
    ): ResponseEntity<VatReturnResponse> {
        val response = homeTaxService.submitVatReturn(companyId, request)
        return ResponseEntity.ok(response)
    }

    /**
     * 세금계산서 발행
     * POST /api/hometax/tax-invoice
     */
    @PostMapping("/tax-invoice")
    fun issueTaxInvoice(
        @RequestParam companyId: UUID,
        @RequestBody request: TaxInvoiceIssueRequest
    ): ResponseEntity<TaxInvoiceResponse> {
        val response = homeTaxService.issueTaxInvoice(companyId, request)
        return ResponseEntity.ok(response)
    }

    /**
     * 원천징수 신고서 생성 및 전송
     * POST /api/hometax/withholding-tax
     */
    @PostMapping("/withholding-tax")
    fun submitWithholdingTaxReturn(
        @RequestParam companyId: UUID,
        @RequestBody request: WithholdingTaxReturnRequest
    ): ResponseEntity<WithholdingTaxReturnResponse> {
        val response = homeTaxService.submitWithholdingTaxReturn(companyId, request)
        return ResponseEntity.ok(response)
    }

    /**
     * 홈택스 신고 현황 조회
     * GET /api/hometax/submission-status
     */
    @GetMapping("/submission-status")
    fun getHomeTaxSubmissionStatus(
        @RequestParam companyId: UUID
    ): ResponseEntity<HomeTaxSubmissionStatusResponse> {
        val response = homeTaxService.getHomeTaxSubmissionStatus(companyId)
        return ResponseEntity.ok(response)
    }

    /**
     * 세금계산서 수취 현황 조회
     * GET /api/hometax/tax-invoice-receipt
     */
    @GetMapping("/tax-invoice-receipt")
    fun getTaxInvoiceReceiptStatus(
        @RequestParam companyId: UUID
    ): ResponseEntity<TaxInvoiceReceiptStatusResponse> {
        val response = homeTaxService.getTaxInvoiceReceiptStatus(companyId)
        return ResponseEntity.ok(response)
    }

    /**
     * 홈택스 API 상태 조회
     * GET /api/hometax/api-status
     */
    @GetMapping("/api-status")
    fun getHomeTaxApiStatus(): ResponseEntity<HomeTaxApiStatusResponse> {
        val response = homeTaxService.getHomeTaxApiStatus()
        return ResponseEntity.ok(response)
    }

    /**
     * 세무 신고 일정 조회
     * GET /api/hometax/tax-schedule
     */
    @GetMapping("/tax-schedule")
    fun getTaxSchedule(
        @RequestParam companyId: UUID
    ): ResponseEntity<List<TaxScheduleResponse>> {
        val response = homeTaxService.getTaxSchedule(companyId)
        return ResponseEntity.ok(response)
    }

    /**
     * 세무 대시보드 데이터 조회
     * GET /api/hometax/dashboard
     */
    @GetMapping("/dashboard")
    fun getTaxDashboard(
        @RequestParam companyId: UUID
    ): ResponseEntity<TaxDashboardResponse> {
        val response = homeTaxService.getTaxDashboard(companyId)
        return ResponseEntity.ok(response)
    }

    /**
     * 인증서 관리 정보 조회
     * GET /api/hometax/certificates
     */
    @GetMapping("/certificates")
    fun getCertificateManagement(
        @RequestParam companyId: UUID
    ): ResponseEntity<List<CertificateManagementResponse>> {
        val response = homeTaxService.getCertificateManagement(companyId)
        return ResponseEntity.ok(response)
    }

    /**
     * 부가세 신고서 미리보기
     * GET /api/hometax/vat-return/preview
     */
    @GetMapping("/vat-return/preview")
    fun previewVatReturn(
        @RequestParam companyId: UUID,
        @RequestParam taxPeriodId: UUID
    ): ResponseEntity<VatReturnPreviewResponse> {
        // 실제 구현에서는 HomeTaxService에 메서드 추가
        val response = VatReturnPreviewResponse(
            taxPeriod = "2025-1Q",
            businessNumber = "123-**-67890",
            companyName = "건물관리 회사",
            salesAmount = java.math.BigDecimal("10000000"),
            outputVat = java.math.BigDecimal("1000000"),
            purchaseAmount = java.math.BigDecimal("5000000"),
            inputVat = java.math.BigDecimal("500000"),
            payableVat = java.math.BigDecimal("500000"),
            refundableVat = java.math.BigDecimal.ZERO,
            estimatedTax = java.math.BigDecimal("500000"),
            dueDate = java.time.LocalDate.of(2025, 4, 25),
            warnings = listOf("매입세액 공제 한도를 확인하세요."),
            recommendations = listOf("정기 예금 이자소득에 대한 원천징수세액을 확인하세요.")
        )
        return ResponseEntity.ok(response)
    }

    /**
     * 세금계산서 일괄 발행
     * POST /api/hometax/tax-invoice/bulk
     */
    @PostMapping("/tax-invoice/bulk")
    fun bulkIssueTaxInvoice(
        @RequestParam companyId: UUID,
        @RequestBody request: BulkTaxInvoiceIssueRequest
    ): ResponseEntity<BulkTaxInvoiceIssueResponse> {
        // 실제 구현에서는 HomeTaxService에 메서드 추가
        val response = BulkTaxInvoiceIssueResponse(
            totalCount = request.invoices.size,
            successCount = request.invoices.size - 1,
            failureCount = 1,
            results = request.invoices.mapIndexed { index, invoice ->
                BulkIssueResult(
                    requestId = invoice.requestId,
                    invoiceNumber = if (index == 0) null else "TI2025${(index + 1).toString().padStart(3, '0')}",
                    status = if (index == 0) "FAILED" else "SUCCESS",
                    errorMessage = if (index == 0) "사업자등록번호가 올바르지 않습니다." else null,
                    issuedAt = if (index == 0) null else java.time.LocalDateTime.now()
                )
            },
            processingTime = 2500L
        )
        return ResponseEntity.ok(response)
    }

    /**
     * 홈택스 연동 해제
     * DELETE /api/hometax/disconnect
     */
    @DeleteMapping("/disconnect")
    fun disconnectHomeTax(
        @RequestParam companyId: UUID,
        @RequestParam connectionId: UUID
    ): ResponseEntity<HomeTaxDisconnectionResponse> {
        // 실제 구현에서는 HomeTaxService에 메서드 추가
        val response = HomeTaxDisconnectionResponse(
            connectionId = connectionId,
            disconnectedAt = java.time.LocalDateTime.now(),
            status = "DISCONNECTED",
            message = "홈택스 연동이 성공적으로 해제되었습니다."
        )
        return ResponseEntity.ok(response)
    }

    /**
     * 세무 신고 이력 조회
     * GET /api/hometax/submission-history
     */
    @GetMapping("/submission-history")
    fun getSubmissionHistory(
        @RequestParam companyId: UUID,
        @RequestParam(required = false) submissionType: String?,
        @RequestParam(required = false) year: Int?,
        @RequestParam(defaultValue = "0") page: Int,
        @RequestParam(defaultValue = "20") size: Int
    ): ResponseEntity<SubmissionHistoryResponse> {
        // 실제 구현에서는 HomeTaxService에 메서드 추가
        val submissions = listOf(
            SubmissionHistoryItem(
                submissionId = UUID.randomUUID(),
                submissionType = "VAT_RETURN",
                taxPeriod = "2024-4Q",
                submissionDate = java.time.LocalDateTime.now().minusDays(30),
                status = "ACCEPTED",
                acceptanceNumber = "VAT20241225001",
                amount = java.math.BigDecimal("2500000")
            ),
            SubmissionHistoryItem(
                submissionId = UUID.randomUUID(),
                submissionType = "WITHHOLDING_TAX",
                taxPeriod = "2024-12",
                submissionDate = java.time.LocalDateTime.now().minusDays(15),
                status = "ACCEPTED",
                acceptanceNumber = "WTH20241210001",
                amount = java.math.BigDecimal("150000")
            )
        )

        val response = SubmissionHistoryResponse(
            totalCount = submissions.size,
            currentPage = page,
            totalPages = 1,
            submissions = submissions
        )
        return ResponseEntity.ok(response)
    }
}