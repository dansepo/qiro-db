package com.qiro.domain.facility.repository

import com.qiro.domain.facility.entity.AssetStatus
import com.qiro.domain.facility.entity.FacilityAsset
import com.qiro.domain.facility.entity.ImportanceLevel
import com.qiro.domain.facility.entity.UsageStatus
import org.springframework.data.domain.Page
import org.springframework.data.domain.Pageable
import org.springframework.data.jpa.repository.JpaRepository
import org.springframework.data.jpa.repository.Query
import org.springframework.data.repository.query.Param
import org.springframework.stereotype.Repository
import java.time.LocalDate

/**
 * 시설물 자산 Repository
 */
@Repository
interface FacilityAssetRepository : JpaRepository<FacilityAsset, Long> {

    /**
     * 자산 코드로 조회
     */
    fun findByAssetCode(assetCode: String): FacilityAsset?

    /**
     * 건물별 자산 조회
     */
    fun findByBuildingIdAndIsActiveTrue(buildingId: Long, pageable: Pageable): Page<FacilityAsset>

    /**
     * 자산 상태별 조회
     */
    fun findByAssetStatusAndIsActiveTrue(assetStatus: AssetStatus, pageable: Pageable): Page<FacilityAsset>

    /**
     * 자산 분류별 조회
     */
    fun findByAssetCategoryAndIsActiveTrue(assetCategory: String, pageable: Pageable): Page<FacilityAsset>

    /**
     * 위치별 자산 조회
     */
    fun findByLocationContainingIgnoreCaseAndIsActiveTrue(location: String, pageable: Pageable): Page<FacilityAsset>

    /**
     * 자산명으로 검색
     */
    fun findByAssetNameContainingIgnoreCaseAndIsActiveTrue(assetName: String, pageable: Pageable): Page<FacilityAsset>

    /**
     * 보증 만료 예정 자산 조회
     */
    @Query("""
        SELECT fa FROM FacilityAsset fa 
        WHERE fa.warrantyEndDate BETWEEN :startDate AND :endDate 
        AND fa.isActive = true
        ORDER BY fa.warrantyEndDate ASC
    """)
    fun findAssetsWithWarrantyExpiringSoon(
        @Param("startDate") startDate: LocalDate,
        @Param("endDate") endDate: LocalDate,
        pageable: Pageable
    ): Page<FacilityAsset>

    /**
     * 점검 필요 자산 조회
     */
    @Query("""
        SELECT fa FROM FacilityAsset fa 
        WHERE fa.nextMaintenanceDate <= :currentDate 
        AND fa.isActive = true
        ORDER BY fa.nextMaintenanceDate ASC
    """)
    fun findAssetsRequiringMaintenance(
        @Param("currentDate") currentDate: LocalDate,
        pageable: Pageable
    ): Page<FacilityAsset>

    /**
     * 중요도별 자산 조회
     */
    fun findByImportanceLevelAndIsActiveTrue(
        importanceLevel: ImportanceLevel,
        pageable: Pageable
    ): Page<FacilityAsset>

    /**
     * 담당자별 자산 조회
     */
    fun findByManagerIdAndIsActiveTrue(managerId: Long, pageable: Pageable): Page<FacilityAsset>

    /**
     * 복합 검색 (자산명, 위치, 제조사, 모델명)
     */
    @Query("""
        SELECT fa FROM FacilityAsset fa 
        WHERE fa.isActive = true
        AND (
            LOWER(fa.assetName) LIKE LOWER(CONCAT('%', :keyword, '%'))
            OR LOWER(fa.location) LIKE LOWER(CONCAT('%', :keyword, '%'))
            OR LOWER(fa.manufacturer) LIKE LOWER(CONCAT('%', :keyword, '%'))
            OR LOWER(fa.modelName) LIKE LOWER(CONCAT('%', :keyword, '%'))
        )
    """)
    fun searchAssets(@Param("keyword") keyword: String, pageable: Pageable): Page<FacilityAsset>

    /**
     * 건물별 자산 상태 통계
     */
    @Query("""
        SELECT fa.assetStatus, COUNT(fa) 
        FROM FacilityAsset fa 
        WHERE fa.buildingId = :buildingId AND fa.isActive = true
        GROUP BY fa.assetStatus
    """)
    fun getAssetStatusStatsByBuilding(@Param("buildingId") buildingId: Long): List<Array<Any>>

    /**
     * 자산 분류별 통계
     */
    @Query("""
        SELECT fa.assetCategory, COUNT(fa) 
        FROM FacilityAsset fa 
        WHERE fa.isActive = true
        GROUP BY fa.assetCategory
        ORDER BY COUNT(fa) DESC
    """)
    fun getAssetCategoryStats(): List<Array<Any>>

    /**
     * 월별 자산 등록 통계
     */
    @Query("""
        SELECT YEAR(fa.createdAt), MONTH(fa.createdAt), COUNT(fa)
        FROM FacilityAsset fa 
        WHERE fa.createdAt >= :startDate AND fa.isActive = true
        GROUP BY YEAR(fa.createdAt), MONTH(fa.createdAt)
        ORDER BY YEAR(fa.createdAt), MONTH(fa.createdAt)
    """)
    fun getMonthlyAssetRegistrationStats(@Param("startDate") startDate: LocalDate): List<Array<Any>>

    /**
     * 시리얼 번호 중복 확인
     */
    fun existsBySerialNumberAndIsActiveTrue(serialNumber: String): Boolean

    /**
     * 자산 코드 중복 확인
     */
    fun existsByAssetCodeAndIsActiveTrue(assetCode: String): Boolean

    /**
     * 건물 내 층별 자산 수 조회
     */
    @Query("""
        SELECT fa.floorNumber, COUNT(fa)
        FROM FacilityAsset fa 
        WHERE fa.buildingId = :buildingId AND fa.isActive = true
        GROUP BY fa.floorNumber
        ORDER BY fa.floorNumber
    """)
    fun getAssetCountByFloor(@Param("buildingId") buildingId: Long): List<Array<Any>>
}