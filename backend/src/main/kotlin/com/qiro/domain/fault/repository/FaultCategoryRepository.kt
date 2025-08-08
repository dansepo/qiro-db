package com.qiro.domain.fault.repository

import com.qiro.domain.fault.entity.FaultCategory
import org.springframework.data.jpa.repository.JpaRepository
import org.springframework.data.jpa.repository.Query
import org.springframework.data.repository.query.Param
import org.springframework.stereotype.Repository
import java.util.*

/**
 * 고장 분류 Repository
 */
@Repository
interface FaultCategoryRepository : JpaRepository<FaultCategory, UUID> {

    /**
     * 회사별 고장 분류 조회 (활성화된 것만)
     */
    fun findByCompanyIdAndIsActiveTrueOrderByDisplayOrderAscCategoryNameAsc(companyId: UUID): List<FaultCategory>

    /**
     * 회사별 모든 고장 분류 조회
     */
    fun findByCompanyIdOrderByDisplayOrderAscCategoryNameAsc(companyId: UUID): List<FaultCategory>

    /**
     * 분류 코드로 조회
     */
    fun findByCompanyIdAndCategoryCode(companyId: UUID, categoryCode: String): FaultCategory?

    /**
     * 상위 분류별 하위 분류 조회
     */
    fun findByCompanyIdAndParentCategoryIdAndIsActiveTrueOrderByDisplayOrderAscCategoryNameAsc(
        companyId: UUID, 
        parentCategoryId: UUID
    ): List<FaultCategory>

    /**
     * 최상위 분류 조회 (부모가 없는 분류)
     */
    fun findByCompanyIdAndParentCategoryIdIsNullAndIsActiveTrueOrderByDisplayOrderAscCategoryNameAsc(
        companyId: UUID
    ): List<FaultCategory>

    /**
     * 레벨별 분류 조회
     */
    fun findByCompanyIdAndCategoryLevelAndIsActiveTrueOrderByDisplayOrderAscCategoryNameAsc(
        companyId: UUID, 
        categoryLevel: Int
    ): List<FaultCategory>

    /**
     * 즉시 응답 필요 분류 조회
     */
    fun findByCompanyIdAndRequiresImmediateResponseTrueAndIsActiveTrueOrderByCategoryNameAsc(
        companyId: UUID
    ): List<FaultCategory>

    /**
     * 전문가 필요 분류 조회
     */
    fun findByCompanyIdAndRequiresSpecialistTrueAndIsActiveTrueOrderByCategoryNameAsc(
        companyId: UUID
    ): List<FaultCategory>

    /**
     * 협력업체 필요 분류 조회
     */
    fun findByCompanyIdAndContractorRequiredTrueAndIsActiveTrueOrderByCategoryNameAsc(
        companyId: UUID
    ): List<FaultCategory>

    /**
     * 분류명으로 검색
     */
    @Query("""
        SELECT fc FROM FaultCategory fc 
        WHERE fc.companyId = :companyId 
        AND fc.isActive = true
        AND (LOWER(fc.categoryName) LIKE LOWER(CONCAT('%', :keyword, '%'))
             OR LOWER(fc.categoryDescription) LIKE LOWER(CONCAT('%', :keyword, '%')))
        ORDER BY fc.displayOrder ASC, fc.categoryName ASC
    """)
    fun searchByKeyword(
        @Param("companyId") companyId: UUID,
        @Param("keyword") keyword: String
    ): List<FaultCategory>

    /**
     * 팀별 기본 분류 조회
     */
    fun findByCompanyIdAndDefaultAssignedTeamAndIsActiveTrueOrderByCategoryNameAsc(
        companyId: UUID, 
        defaultAssignedTeam: String
    ): List<FaultCategory>

    /**
     * 분류 코드 중복 확인
     */
    fun existsByCompanyIdAndCategoryCode(companyId: UUID, categoryCode: String): Boolean

    /**
     * 하위 분류 존재 여부 확인
     */
    fun existsByCompanyIdAndParentCategoryId(companyId: UUID, parentCategoryId: UUID): Boolean

    /**
     * 계층 구조 조회 (재귀적으로 하위 분류까지)
     */
    @Query("""
        WITH RECURSIVE category_hierarchy AS (
            -- 최상위 분류
            SELECT fc.id, fc.category_code, fc.category_name, fc.parent_category_id, 
                   fc.category_level, fc.display_order, 0 as depth,
                   CAST(fc.category_name AS TEXT) as path
            FROM bms.fault_categories fc
            WHERE fc.company_id = :companyId 
            AND fc.parent_category_id IS NULL 
            AND fc.is_active = true
            
            UNION ALL
            
            -- 하위 분류
            SELECT fc.id, fc.category_code, fc.category_name, fc.parent_category_id,
                   fc.category_level, fc.display_order, ch.depth + 1,
                   CONCAT(ch.path, ' > ', fc.category_name)
            FROM bms.fault_categories fc
            INNER JOIN category_hierarchy ch ON fc.parent_category_id = ch.id
            WHERE fc.company_id = :companyId 
            AND fc.is_active = true
        )
        SELECT fc.* FROM FaultCategory fc
        INNER JOIN category_hierarchy ch ON fc.id = ch.id
        ORDER BY ch.path
    """, nativeQuery = true)
    fun findCategoryHierarchy(@Param("companyId") companyId: UUID): List<FaultCategory>

    /**
     * 특정 분류의 모든 하위 분류 조회
     */
    @Query("""
        WITH RECURSIVE subcategories AS (
            -- 시작 분류
            SELECT fc.id, fc.category_code, fc.category_name, fc.parent_category_id, 
                   fc.category_level, 0 as depth
            FROM bms.fault_categories fc
            WHERE fc.id = :categoryId 
            AND fc.company_id = :companyId
            
            UNION ALL
            
            -- 하위 분류들
            SELECT fc.id, fc.category_code, fc.category_name, fc.parent_category_id,
                   fc.category_level, sc.depth + 1
            FROM bms.fault_categories fc
            INNER JOIN subcategories sc ON fc.parent_category_id = sc.id
            WHERE fc.company_id = :companyId 
            AND fc.is_active = true
        )
        SELECT fc.* FROM FaultCategory fc
        INNER JOIN subcategories sc ON fc.id = sc.id
        WHERE sc.depth > 0
        ORDER BY sc.depth, fc.display_order, fc.category_name
    """, nativeQuery = true)
    fun findSubcategories(
        @Param("companyId") companyId: UUID,
        @Param("categoryId") categoryId: UUID
    ): List<FaultCategory>

    /**
     * 분류별 신고 건수 통계
     */
    @Query("""
        SELECT fc, COUNT(fr) as reportCount
        FROM FaultCategory fc
        LEFT JOIN FaultReport fr ON fc.id = fr.categoryId 
            AND fr.reportedAt >= :startDate 
            AND fr.reportedAt <= :endDate
        WHERE fc.companyId = :companyId 
        AND fc.isActive = true
        GROUP BY fc.id
        ORDER BY reportCount DESC, fc.categoryName ASC
    """)
    fun findCategoriesWithReportCount(
        @Param("companyId") companyId: UUID,
        @Param("startDate") startDate: java.time.LocalDateTime,
        @Param("endDate") endDate: java.time.LocalDateTime
    ): List<Array<Any>>
}