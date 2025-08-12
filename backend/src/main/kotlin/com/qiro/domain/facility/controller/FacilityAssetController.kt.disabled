package com.qiro.domain.facility.controller

import com.qiro.domain.facility.dto.*
import com.qiro.domain.facility.service.FacilityAssetService
import io.swagger.v3.oas.annotations.Operation
import io.swagger.v3.oas.annotations.Parameter
import io.swagger.v3.oas.annotations.tags.Tag
import org.springframework.data.domain.Page
import org.springframework.data.domain.Pageable
import org.springframework.data.web.PageableDefault
import org.springframework.http.HttpStatus
import org.springframework.http.ResponseEntity
import org.springframework.web.bind.annotation.*

/**
 * 시설물 자산 관리 컨트롤러
 */
@RestController
@RequestMapping("/api/v1/facility/assets")
@Tag(name = "시설물 자산 관리", description = "시설물 자산 등록, 조회, 수정, 삭제 및 상태 관리")
class FacilityAssetController(
    private val facilityAssetService: FacilityAssetService
) {

    @Operation(summary = "시설물 자산 생성", description = "새로운 시설물 자산을 등록합니다")
    @PostMapping
    fun createAsset(
        @RequestBody request: CreateFacilityAssetRequestDto,
        @RequestHeader("X-User-Id") userId: Long
    ): ResponseEntity<FacilityAssetResponseDto> {
        val asset = facilityAssetService.createAsset(request, userId)
        return ResponseEntity.status(HttpStatus.CREATED).body(asset)
    }

    @Operation(summary = "시설물 자산 조회", description = "ID로 시설물 자산을 조회합니다")
    @GetMapping("/{id}")
    fun getAsset(
        @Parameter(description = "자산 ID") @PathVariable id: Long
    ): ResponseEntity<FacilityAssetResponseDto> {
        val asset = facilityAssetService.getAsset(id)
        return ResponseEntity.ok(asset)
    }

    @Operation(summary = "자산 코드로 조회", description = "자산 코드로 시설물 자산을 조회합니다")
    @GetMapping("/code/{assetCode}")
    fun getAssetByCode(
        @Parameter(description = "자산 코드") @PathVariable assetCode: String
    ): ResponseEntity<FacilityAssetResponseDto> {
        val asset = facilityAssetService.getAssetByCode(assetCode)
        return ResponseEntity.ok(asset)
    }

    @Operation(summary = "시설물 자산 수정", description = "시설물 자산 정보를 수정합니다")
    @PutMapping("/{id}")
    fun updateAsset(
        @Parameter(description = "자산 ID") @PathVariable id: Long,
        @RequestBody request: UpdateFacilityAssetRequestDto,
        @RequestHeader("X-User-Id") userId: Long
    ): ResponseEntity<FacilityAssetResponseDto> {
        val asset = facilityAssetService.updateAsset(id, request, userId)
        return ResponseEntity.ok(asset)
    }

    @Operation(summary = "시설물 자산 삭제", description = "시설물 자산을 삭제합니다 (논리 삭제)")
    @DeleteMapping("/{id}")
    fun deleteAsset(
        @Parameter(description = "자산 ID") @PathVariable id: Long,
        @RequestHeader("X-User-Id") userId: Long
    ): ResponseEntity<Void> {
        facilityAssetService.deleteAsset(id, userId)
        return ResponseEntity.noContent().build()
    }

    @Operation(summary = "자산 상태 업데이트", description = "시설물 자산의 상태를 업데이트합니다")
    @PatchMapping("/{id}/status")
    fun updateAssetStatus(
        @Parameter(description = "자산 ID") @PathVariable id: Long,
        @RequestBody request: AssetStatusUpdateRequestDto
    ): ResponseEntity<FacilityAssetResponseDto> {
        val asset = facilityAssetService.updateAssetStatus(id, request)
        return ResponseEntity.ok(asset)
    }

    @Operation(summary = "자산 정비 완료", description = "시설물 자산의 정비를 완료 처리합니다")
    @PatchMapping("/{id}/maintenance/complete")
    fun completeAssetMaintenance(
        @Parameter(description = "자산 ID") @PathVariable id: Long,
        @RequestBody request: AssetMaintenanceCompleteRequestDto
    ): ResponseEntity<FacilityAssetResponseDto> {
        val asset = facilityAssetService.completeAssetMaintenance(id, request)
        return ResponseEntity.ok(asset)
    }

    @Operation(summary = "건물별 자산 목록 조회", description = "특정 건물의 시설물 자산 목록을 조회합니다")
    @GetMapping("/building/{buildingId}")
    fun getAssetsByBuilding(
        @Parameter(description = "건물 ID") @PathVariable buildingId: Long,
        @PageableDefault(size = 20) pageable: Pageable
    ): ResponseEntity<Page<FacilityAssetResponseDto>> {
        val assets = facilityAssetService.getAssetsByBuilding(buildingId, pageable)
        return ResponseEntity.ok(assets)
    }

    @Operation(summary = "자산 검색", description = "다양한 조건으로 시설물 자산을 검색합니다")
    @GetMapping("/search")
    fun searchAssets(
        @Parameter(description = "검색 키워드") @RequestParam(required = false) keyword: String?,
        @Parameter(description = "자산 분류") @RequestParam(required = false) assetCategory: String?,
        @Parameter(description = "자산 상태") @RequestParam(required = false) assetStatus: String?,
        @Parameter(description = "사용 상태") @RequestParam(required = false) usageStatus: String?,
        @Parameter(description = "중요도") @RequestParam(required = false) importanceLevel: String?,
        @Parameter(description = "건물 ID") @RequestParam(required = false) buildingId: Long?,
        @Parameter(description = "층수") @RequestParam(required = false) floorNumber: Int?,
        @Parameter(description = "담당자 ID") @RequestParam(required = false) managerId: Long?,
        @Parameter(description = "보증 만료 예정") @RequestParam(required = false, defaultValue = "false") warrantyExpiring: Boolean,
        @Parameter(description = "점검 필요") @RequestParam(required = false, defaultValue = "false") maintenanceRequired: Boolean,
        @Parameter(description = "보증 만료 예정 일수") @RequestParam(required = false) warrantyExpiryDays: Int?,
        @PageableDefault(size = 20) pageable: Pageable
    ): ResponseEntity<Page<FacilityAssetResponseDto>> {
        val criteria = FacilityAssetSearchCriteria(
            keyword = keyword,
            assetCategory = assetCategory,
            assetStatus = assetStatus?.let { com.qiro.domain.facility.entity.AssetStatus.valueOf(it) },
            usageStatus = usageStatus?.let { com.qiro.domain.facility.entity.UsageStatus.valueOf(it) },
            importanceLevel = importanceLevel?.let { com.qiro.domain.facility.entity.ImportanceLevel.valueOf(it) },
            buildingId = buildingId,
            floorNumber = floorNumber,
            managerId = managerId,
            warrantyExpiring = warrantyExpiring,
            maintenanceRequired = maintenanceRequired,
            warrantyExpiryDays = warrantyExpiryDays
        )
        
        val assets = facilityAssetService.searchAssets(criteria, pageable)
        return ResponseEntity.ok(assets)
    }

    @Operation(summary = "보증 만료 예정 자산 조회", description = "보증 기간이 만료 예정인 자산들을 조회합니다")
    @GetMapping("/warranty-expiring")
    fun getAssetsWithWarrantyExpiringSoon(
        @Parameter(description = "예정 일수 (기본값: 30일)") @RequestParam(defaultValue = "30") days: Int,
        @PageableDefault(size = 20) pageable: Pageable
    ): ResponseEntity<Page<FacilityAssetResponseDto>> {
        val assets = facilityAssetService.getAssetsWithWarrantyExpiringSoon(days, pageable)
        return ResponseEntity.ok(assets)
    }

    @Operation(summary = "점검 필요 자산 조회", description = "정기 점검이 필요한 자산들을 조회합니다")
    @GetMapping("/maintenance-required")
    fun getAssetsRequiringMaintenance(
        @PageableDefault(size = 20) pageable: Pageable
    ): ResponseEntity<Page<FacilityAssetResponseDto>> {
        val assets = facilityAssetService.getAssetsRequiringMaintenance(pageable)
        return ResponseEntity.ok(assets)
    }

    @Operation(summary = "자산 통계 조회", description = "시설물 자산의 통계 정보를 조회합니다")
    @GetMapping("/statistics")
    fun getAssetStatistics(
        @Parameter(description = "건물 ID (선택사항)") @RequestParam(required = false) buildingId: Long?
    ): ResponseEntity<FacilityAssetStatsDto> {
        val stats = facilityAssetService.getAssetStatistics(buildingId)
        return ResponseEntity.ok(stats)
    }

    @Operation(summary = "전체 자산 목록 조회", description = "모든 활성 상태의 시설물 자산을 조회합니다")
    @GetMapping
    fun getAllAssets(
        @PageableDefault(size = 20) pageable: Pageable
    ): ResponseEntity<Page<FacilityAssetResponseDto>> {
        val criteria = FacilityAssetSearchCriteria()
        val assets = facilityAssetService.searchAssets(criteria, pageable)
        return ResponseEntity.ok(assets)
    }
}