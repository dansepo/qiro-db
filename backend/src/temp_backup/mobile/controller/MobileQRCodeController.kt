package com.qiro.domain.mobile.controller

import com.qiro.domain.mobile.dto.*
import com.qiro.domain.mobile.service.MobileQRCodeService
import io.swagger.v3.oas.annotations.Operation
import io.swagger.v3.oas.annotations.Parameter
import io.swagger.v3.oas.annotations.tags.Tag
import org.springframework.http.ResponseEntity
import org.springframework.web.bind.annotation.*
import java.util.*

/**
 * 모바일 QR코드 컨트롤러
 */
@RestController
@RequestMapping("/api/v1/mobile/companies/{companyId}/qr-codes")
@Tag(name = "Mobile QR Codes", description = "모바일 QR코드 관리 API")
class MobileQRCodeController(
    private val mobileQRCodeService: MobileQRCodeService
) {

    @Operation(summary = "QR코드 스캔", description = "QR코드를 스캔하여 관련 정보를 조회합니다")
    @PostMapping("/scan")
    fun scanQRCode(
        @Parameter(description = "회사 ID") @PathVariable companyId: UUID,
        @RequestBody request: Map<String, String>,
        @RequestHeader("X-User-Id") userId: UUID
    ): ResponseEntity<QRCodeScanResultDto> {
        val qrCodeData = request["qrCodeData"] ?: throw IllegalArgumentException("QR코드 데이터가 필요합니다")
        val result = mobileQRCodeService.scanQRCode(qrCodeData, userId)
        return ResponseEntity.ok(result)
    }

    @Operation(summary = "자산 QR코드 정보 조회", description = "자산 QR코드의 상세 정보를 조회합니다")
    @GetMapping("/assets/{assetId}")
    fun getAssetQRCodeData(
        @Parameter(description = "회사 ID") @PathVariable companyId: UUID,
        @Parameter(description = "자산 ID") @PathVariable assetId: UUID
    ): ResponseEntity<AssetQRCodeDto> {
        val result = mobileQRCodeService.getAssetQRCodeData(assetId)
        return ResponseEntity.ok(result)
    }

    @Operation(summary = "부품 QR코드 정보 조회", description = "부품 QR코드의 상세 정보를 조회합니다")
    @GetMapping("/parts/{partId}")
    fun getPartQRCodeData(
        @Parameter(description = "회사 ID") @PathVariable companyId: UUID,
        @Parameter(description = "부품 ID") @PathVariable partId: UUID
    ): ResponseEntity<PartQRCodeDto> {
        val result = mobileQRCodeService.getPartQRCodeData(partId)
        return ResponseEntity.ok(result)
    }

    @Operation(summary = "작업 지시서 QR코드 정보 조회", description = "작업 지시서 QR코드의 상세 정보를 조회합니다")
    @GetMapping("/work-orders/{workOrderId}")
    fun getWorkOrderQRCodeData(
        @Parameter(description = "회사 ID") @PathVariable companyId: UUID,
        @Parameter(description = "작업 지시서 ID") @PathVariable workOrderId: UUID
    ): ResponseEntity<WorkOrderQRCodeDto> {
        val result = mobileQRCodeService.getWorkOrderQRCodeData(workOrderId)
        return ResponseEntity.ok(result)
    }

    @Operation(summary = "위치 QR코드 정보 조회", description = "위치 QR코드의 상세 정보를 조회합니다")
    @GetMapping("/locations/{locationId}")
    fun getLocationQRCodeData(
        @Parameter(description = "회사 ID") @PathVariable companyId: UUID,
        @Parameter(description = "위치 ID") @PathVariable locationId: UUID
    ): ResponseEntity<LocationQRCodeDto> {
        val result = mobileQRCodeService.getLocationQRCodeData(locationId)
        return ResponseEntity.ok(result)
    }

    @Operation(summary = "QR코드 생성", description = "엔티티에 대한 QR코드를 생성합니다")
    @PostMapping("/generate")
    fun generateQRCode(
        @Parameter(description = "회사 ID") @PathVariable companyId: UUID,
        @RequestBody request: GenerateQRCodeRequest
    ): ResponseEntity<GenerateQRCodeResponse> {
        val result = mobileQRCodeService.generateQRCode(request)
        return ResponseEntity.ok(result)
    }

    @Operation(summary = "부품 사용 기록", description = "QR코드 스캔을 통해 부품 사용을 기록합니다")
    @PostMapping("/parts/usage")
    fun recordPartUsage(
        @Parameter(description = "회사 ID") @PathVariable companyId: UUID,
        @RequestBody request: RecordPartUsageRequest,
        @RequestHeader("X-User-Id") userId: UUID
    ): ResponseEntity<Map<String, Any>> {
        val success = mobileQRCodeService.recordPartUsage(request, userId)
        val response = mapOf(
            "success" to success,
            "message" to if (success) "부품 사용이 기록되었습니다" else "부품 사용 기록에 실패했습니다",
            "timestamp" to java.time.LocalDateTime.now()
        )
        return ResponseEntity.ok(response)
    }

    @Operation(summary = "QR코드 스캔 이력 조회", description = "사용자의 QR코드 스캔 이력을 조회합니다")
    @GetMapping("/scan-history")
    fun getQRCodeScanHistory(
        @Parameter(description = "회사 ID") @PathVariable companyId: UUID,
        @RequestHeader("X-User-Id") userId: UUID,
        @Parameter(description = "조회할 개수") @RequestParam(defaultValue = "20") limit: Int
    ): ResponseEntity<List<Map<String, Any>>> {
        // 실제 구현에서는 스캔 이력을 데이터베이스에서 조회
        val history = listOf(
            mapOf(
                "scanId" to UUID.randomUUID(),
                "qrCodeType" to "ASSET",
                "entityName" to "엘리베이터 #1",
                "scannedAt" to java.time.LocalDateTime.now().minusHours(2),
                "location" to "1층 로비"
            ),
            mapOf(
                "scanId" to UUID.randomUUID(),
                "qrCodeType" to "PART",
                "entityName" to "LED 전구 20W",
                "scannedAt" to java.time.LocalDateTime.now().minusHours(4),
                "location" to "창고 A-1-3"
            )
        )
        return ResponseEntity.ok(history)
    }
}