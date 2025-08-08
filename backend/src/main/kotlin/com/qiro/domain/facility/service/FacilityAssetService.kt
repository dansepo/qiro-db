package com.qiro.domain.facility.service

import com.qiro.common.service.DataIntegrityService
import com.qiro.domain.facility.dto.*
import com.qiro.domain.facility.entity.AssetStatus
import com.qiro.domain.facility.entity.FacilityAsset
import com.qiro.domain.facility.repository.FacilityAssetRepository
import org.springframework.data.domain.Page
import org.springframework.data.domain.Pageable
import org.springframework.stereotype.Service
import org.springframework.transaction.annotation.Transactional
import java.time.LocalDate
import java.time.LocalDateTime

/**
 * 시설물 자산 관리 서비스
 */
@Service
@Transactional(readOnly = true)
class FacilityAssetService(
    private val facilityAssetRepository: FacilityAssetRepository,
    private val dataIntegrityService: DataIntegrityService
) {

    /**
     * 시설물 자산 생성
     */
    @Transactional
    fun createAsset(request: CreateFacilityAssetRequestDto, createdBy: Long): FacilityAssetResponseDto {
        // 데이터 유효성 검증
        validateAssetData(request)
        
        // 자산 코드 중복 확인
        if (facilityAssetRepository.existsByAssetCodeAndIsActiveTrue(request.assetCode)) {
            throw IllegalArgumentException("이미 존재하는 자산 코드입니다: ${request.assetCode}")
        }
        
        // 시리얼 번호 중복 확인 (시리얼 번호가 있는 경우)
        request.serialNumber?.let { serialNumber ->
            if (facilityAssetRepository.existsBySerialNumberAndIsActiveTrue(serialNumber)) {
                throw IllegalArgumentException("이미 존재하는 시리얼 번호입니다: $serialNumber")
            }
        }
        
        val asset = request.toEntity(createdBy)
        val savedAsset = facilityAssetRepository.save(asset)
        
        return FacilityAssetResponseDto.from(savedAsset)
    }

    /**
     * 시설물 자산 조회
     */
    fun getAsset(id: Long): FacilityAssetResponseDto {
        val asset = facilityAssetRepository.findById(id)
            .orElseThrow { NoSuchElementException("자산을 찾을 수 없습니다: $id") }
        
        if (!asset.isActive) {
            throw IllegalStateException("비활성화된 자산입니다: $id")
        }
        
        return FacilityAssetResponseDto.from(asset)
    }

    /**
     * 자산 코드로 조회
     */
    fun getAssetByCode(assetCode: String): FacilityAssetResponseDto {
        val asset = facilityAssetRepository.findByAssetCode(assetCode)
            ?: throw NoSuchElementException("자산을 찾을 수 없습니다: $assetCode")
        
        if (!asset.isActive) {
            throw IllegalStateException("비활성화된 자산입니다: $assetCode")
        }
        
        return FacilityAssetResponseDto.from(asset)
    }

    /**
     * 시설물 자산 수정
     */
    @Transactional
    fun updateAsset(id: Long, request: UpdateFacilityAssetRequestDto, updatedBy: Long): FacilityAssetResponseDto {
        val existingAsset = facilityAssetRepository.findById(id)
            .orElseThrow { NoSuchElementException("자산을 찾을 수 없습니다: $id") }
        
        if (!existingAsset.isActive) {
            throw IllegalStateException("비활성화된 자산은 수정할 수 없습니다: $id")
        }
        
        // 시리얼 번호 중복 확인 (변경하는 경우)
        request.serialNumber?.let { newSerialNumber ->
            if (newSerialNumber != existingAsset.serialNumber && 
                facilityAssetRepository.existsBySerialNumberAndIsActiveTrue(newSerialNumber)) {
                throw IllegalArgumentException("이미 존재하는 시리얼 번호입니다: $newSerialNumber")
            }
        }
        
        val updatedAsset = existingAsset.copy(
            assetName = request.assetName ?: existingAsset.assetName,
            assetCategory = request.assetCategory ?: existingAsset.assetCategory,
            assetType = request.assetType ?: existingAsset.assetType,
            manufacturer = request.manufacturer ?: existingAsset.manufacturer,
            modelName = request.modelName ?: existingAsset.modelName,
            serialNumber = request.serialNumber ?: existingAsset.serialNumber,
            location = request.location ?: existingAsset.location,
            floorNumber = request.floorNumber ?: existingAsset.floorNumber,
            purchaseDate = request.purchaseDate ?: existingAsset.purchaseDate,
            purchaseAmount = request.purchaseAmount ?: existingAsset.purchaseAmount,
            installationDate = request.installationDate ?: existingAsset.installationDate,
            warrantyStartDate = request.warrantyStartDate ?: existingAsset.warrantyStartDate,
            warrantyEndDate = request.warrantyEndDate ?: existingAsset.warrantyEndDate,
            assetStatus = request.assetStatus ?: existingAsset.assetStatus,
            usageStatus = request.usageStatus ?: existingAsset.usageStatus,
            importanceLevel = request.importanceLevel ?: existingAsset.importanceLevel,
            maintenanceCycleDays = request.maintenanceCycleDays ?: existingAsset.maintenanceCycleDays,
            description = request.description ?: existingAsset.description,
            managerId = request.managerId ?: existingAsset.managerId,
            updatedBy = updatedBy,
            updatedAt = LocalDateTime.now()
        )
        
        val savedAsset = facilityAssetRepository.save(updatedAsset)
        return FacilityAssetResponseDto.from(savedAsset)
    }

    /**
     * 시설물 자산 삭제 (논리 삭제)
     */
    @Transactional
    fun deleteAsset(id: Long, deletedBy: Long) {
        val asset = facilityAssetRepository.findById(id)
            .orElseThrow { NoSuchElementException("자산을 찾을 수 없습니다: $id") }
        
        val deletedAsset = asset.copy(
            isActive = false,
            updatedBy = deletedBy,
            updatedAt = LocalDateTime.now()
        )
        
        facilityAssetRepository.save(deletedAsset)
    }

    /**
     * 자산 상태 업데이트
     */
    @Transactional
    fun updateAssetStatus(id: Long, request: AssetStatusUpdateRequestDto): FacilityAssetResponseDto {
        val asset = facilityAssetRepository.findById(id)
            .orElseThrow { NoSuchElementException("자산을 찾을 수 없습니다: $id") }
        
        if (!asset.isActive) {
            throw IllegalStateException("비활성화된 자산의 상태는 변경할 수 없습니다: $id")
        }
        
        val updatedAsset = asset.copy(
            assetStatus = request.assetStatus,
            updatedBy = request.updatedBy,
            updatedAt = LocalDateTime.now()
        )
        
        val savedAsset = facilityAssetRepository.save(updatedAsset)
        return FacilityAssetResponseDto.from(savedAsset)
    }

    /**
     * 자산 정비 완료 처리
     */
    @Transactional
    fun completeAssetMaintenance(id: Long, request: AssetMaintenanceCompleteRequestDto): FacilityAssetResponseDto {
        val asset = facilityAssetRepository.findById(id)
            .orElseThrow { NoSuchElementException("자산을 찾을 수 없습니다: $id") }
        
        if (!asset.isActive) {
            throw IllegalStateException("비활성화된 자산의 정비는 완료할 수 없습니다: $id")
        }
        
        val nextMaintenanceDate = request.nextMaintenanceDate 
            ?: asset.maintenanceCycleDays?.let { cycle ->
                request.maintenanceDate.plusDays(cycle.toLong())
            }
        
        val updatedAsset = asset.copy(
            lastMaintenanceDate = request.maintenanceDate,
            nextMaintenanceDate = nextMaintenanceDate,
            assetStatus = AssetStatus.NORMAL, // 정비 완료 후 정상 상태로 변경
            updatedBy = request.updatedBy,
            updatedAt = LocalDateTime.now()
        )
        
        val savedAsset = facilityAssetRepository.save(updatedAsset)
        return FacilityAssetResponseDto.from(savedAsset)
    }

    /**
     * 건물별 자산 목록 조회
     */
    fun getAssetsByBuilding(buildingId: Long, pageable: Pageable): Page<FacilityAssetResponseDto> {
        return facilityAssetRepository.findByBuildingIdAndIsActiveTrue(buildingId, pageable)
            .map { FacilityAssetResponseDto.from(it) }
    }

    /**
     * 자산 검색
     */
    fun searchAssets(criteria: FacilityAssetSearchCriteria, pageable: Pageable): Page<FacilityAssetResponseDto> {
        return when {
            criteria.keyword != null -> {
                facilityAssetRepository.searchAssets(criteria.keyword, pageable)
            }
            criteria.assetCategory != null -> {
                facilityAssetRepository.findByAssetCategoryAndIsActiveTrue(criteria.assetCategory, pageable)
            }
            criteria.assetStatus != null -> {
                facilityAssetRepository.findByAssetStatusAndIsActiveTrue(criteria.assetStatus, pageable)
            }
            criteria.buildingId != null -> {
                facilityAssetRepository.findByBuildingIdAndIsActiveTrue(criteria.buildingId, pageable)
            }
            criteria.managerId != null -> {
                facilityAssetRepository.findByManagerIdAndIsActiveTrue(criteria.managerId, pageable)
            }
            criteria.importanceLevel != null -> {
                facilityAssetRepository.findByImportanceLevelAndIsActiveTrue(criteria.importanceLevel, pageable)
            }
            criteria.warrantyExpiring -> {
                val endDate = LocalDate.now().plusDays((criteria.warrantyExpiryDays ?: 30).toLong())
                facilityAssetRepository.findAssetsWithWarrantyExpiringSoon(LocalDate.now(), endDate, pageable)
            }
            criteria.maintenanceRequired -> {
                facilityAssetRepository.findAssetsRequiringMaintenance(LocalDate.now(), pageable)
            }
            else -> {
                facilityAssetRepository.findAll(pageable)
                    .map { asset -> asset.takeIf { it.isActive } }
                    .map { it?.let { asset -> asset } }
            }
        }.map { FacilityAssetResponseDto.from(it) }
    }

    /**
     * 보증 만료 예정 자산 조회
     */
    fun getAssetsWithWarrantyExpiringSoon(days: Int = 30, pageable: Pageable): Page<FacilityAssetResponseDto> {
        val startDate = LocalDate.now()
        val endDate = startDate.plusDays(days.toLong())
        
        return facilityAssetRepository.findAssetsWithWarrantyExpiringSoon(startDate, endDate, pageable)
            .map { FacilityAssetResponseDto.from(it) }
    }

    /**
     * 점검 필요 자산 조회
     */
    fun getAssetsRequiringMaintenance(pageable: Pageable): Page<FacilityAssetResponseDto> {
        return facilityAssetRepository.findAssetsRequiringMaintenance(LocalDate.now(), pageable)
            .map { FacilityAssetResponseDto.from(it) }
    }

    /**
     * 자산 통계 조회
     */
    fun getAssetStatistics(buildingId: Long? = null): FacilityAssetStatsDto {
        val allAssets = if (buildingId != null) {
            facilityAssetRepository.findByBuildingIdAndIsActiveTrue(buildingId, Pageable.unpaged()).content
        } else {
            facilityAssetRepository.findAll().filter { it.isActive }
        }
        
        val statusStats = allAssets.groupBy { it.assetStatus }
        val categoryStats = allAssets.groupBy { it.assetCategory }.mapValues { it.value.size.toLong() }
        val importanceStats = allAssets.groupBy { it.importanceLevel }.mapValues { it.value.size.toLong() }
        
        val now = LocalDate.now()
        val warrantyExpiringSoon = allAssets.count { 
            it.warrantyEndDate?.let { date -> date.isAfter(now) && date.isBefore(now.plusDays(30)) } ?: false
        }
        val maintenanceRequired = allAssets.count { it.isMaintenanceRequired() }
        
        return FacilityAssetStatsDto(
            totalAssets = allAssets.size.toLong(),
            normalAssets = statusStats[AssetStatus.NORMAL]?.size?.toLong() ?: 0L,
            inspectionRequiredAssets = statusStats[AssetStatus.INSPECTION_REQUIRED]?.size?.toLong() ?: 0L,
            underRepairAssets = statusStats[AssetStatus.UNDER_REPAIR]?.size?.toLong() ?: 0L,
            outOfOrderAssets = statusStats[AssetStatus.OUT_OF_ORDER]?.size?.toLong() ?: 0L,
            warrantyExpiringSoon = warrantyExpiringSoon.toLong(),
            maintenanceRequired = maintenanceRequired.toLong(),
            categoryStats = categoryStats,
            importanceLevelStats = importanceStats
        )
    }

    /**
     * 자산 데이터 유효성 검증
     */
    private fun validateAssetData(request: CreateFacilityAssetRequestDto) {
        // DataIntegrityService를 사용한 기본 검증
        if (request.assetCode.isBlank()) {
            throw IllegalArgumentException("자산 코드는 필수입니다")
        }
        
        if (request.assetName.isBlank()) {
            throw IllegalArgumentException("자산명은 필수입니다")
        }
        
        if (request.assetCategory.isBlank()) {
            throw IllegalArgumentException("자산 분류는 필수입니다")
        }
        
        if (request.location.isBlank()) {
            throw IllegalArgumentException("설치 위치는 필수입니다")
        }
        
        // 날짜 유효성 검증
        if (request.warrantyStartDate != null && request.warrantyEndDate != null) {
            if (request.warrantyEndDate.isBefore(request.warrantyStartDate)) {
                throw IllegalArgumentException("보증 종료일은 시작일보다 늦어야 합니다")
            }
        }
        
        if (request.purchaseDate != null && request.installationDate != null) {
            if (request.installationDate.isBefore(request.purchaseDate)) {
                throw IllegalArgumentException("설치일은 구매일보다 늦어야 합니다")
            }
        }
        
        // 정비 주기 검증
        if (request.maintenanceCycleDays != null && request.maintenanceCycleDays <= 0) {
            throw IllegalArgumentException("정비 주기는 양수여야 합니다")
        }
    }
}