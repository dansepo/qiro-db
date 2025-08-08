package com.qiro.domain.accounting.repository

import com.qiro.domain.accounting.entity.TaxDocument
import org.springframework.data.jpa.repository.JpaRepository
import org.springframework.data.jpa.repository.Query
import org.springframework.data.repository.query.Param
import org.springframework.stereotype.Repository
import java.time.LocalDate
import java.util.*

/**
 * 세무 서류 Repository
 */
@Repository
interface TaxDocumentRepository : JpaRepository<TaxDocument, UUID> {

    /**
     * 회사별 세무 서류 조회
     */
    fun findByCompanyIdOrderByCreatedAtDesc(companyId: UUID): List<TaxDocument>

    /**
     * 회사별, 서류 유형별 조회
     */
    fun findByCompanyIdAndDocumentTypeOrderByCreatedAtDesc(
        companyId: UUID,
        documentType: TaxDocument.DocumentType
    ): List<TaxDocument>

    /**
     * 회사별, 서류 카테고리별 조회
     */
    fun findByCompanyIdAndDocumentCategoryOrderByCreatedAtDesc(
        companyId: UUID,
        documentCategory: String
    ): List<TaxDocument>

    /**
     * 세무 기간별 서류 조회
     */
    fun findByCompanyIdAndRelatedTaxPeriodIdOrderByCreatedAtDesc(
        companyId: UUID,
        relatedTaxPeriodId: UUID
    ): List<TaxDocument>

    /**
     * 부가세 신고서 관련 서류 조회
     */
    fun findByCompanyIdAndRelatedVatReturnIdOrderByCreatedAtDesc(
        companyId: UUID,
        relatedVatReturnId: Long
    ): List<TaxDocument>

    /**
     * 원천징수 관련 서류 조회
     */
    fun findByCompanyIdAndRelatedWithholdingIdOrderByCreatedAtDesc(
        companyId: UUID,
        relatedWithholdingId: UUID
    ): List<TaxDocument>

    /**
     * 세금계산서 관련 서류 조회
     */
    fun findByCompanyIdAndRelatedTaxInvoiceIdOrderByCreatedAtDesc(
        companyId: UUID,
        relatedTaxInvoiceId: UUID
    ): List<TaxDocument>

    /**
     * 파일명으로 서류 검색
     */
    fun findByCompanyIdAndFileNameContainingIgnoreCaseOrderByCreatedAtDesc(
        companyId: UUID,
        fileName: String
    ): List<TaxDocument>

    /**
     * 서류명으로 서류 검색
     */
    fun findByCompanyIdAndDocumentNameContainingIgnoreCaseOrderByCreatedAtDesc(
        companyId: UUID,
        documentName: String
    ): List<TaxDocument>

    /**
     * 태그로 서류 검색
     */
    @Query("""
        SELECT td FROM TaxDocument td 
        WHERE td.companyId = :companyId 
        AND td.tags LIKE %:tag%
        ORDER BY td.createdAt DESC
    """)
    fun findByCompanyIdAndTag(
        @Param("companyId") companyId: UUID,
        @Param("tag") tag: String
    ): List<TaxDocument>

    /**
     * 보관 기간이 만료된 서류 조회
     */
    @Query("""
        SELECT td FROM TaxDocument td 
        WHERE td.companyId = :companyId 
        AND td.expiryDate <= :currentDate
        ORDER BY td.expiryDate ASC
    """)
    fun findExpiredDocuments(
        @Param("companyId") companyId: UUID,
        @Param("currentDate") currentDate: LocalDate
    ): List<TaxDocument>

    /**
     * 보관 기간이 임박한 서류 조회 (N일 이내 만료)
     */
    @Query("""
        SELECT td FROM TaxDocument td 
        WHERE td.companyId = :companyId 
        AND td.expiryDate BETWEEN :currentDate AND :futureDate
        ORDER BY td.expiryDate ASC
    """)
    fun findDocumentsExpiringWithin(
        @Param("companyId") companyId: UUID,
        @Param("currentDate") currentDate: LocalDate,
        @Param("futureDate") futureDate: LocalDate
    ): List<TaxDocument>

    /**
     * 파일 크기별 서류 조회
     */
    @Query("""
        SELECT td FROM TaxDocument td 
        WHERE td.companyId = :companyId 
        AND td.fileSize >= :minSize
        ORDER BY td.fileSize DESC
    """)
    fun findLargeDocuments(
        @Param("companyId") companyId: UUID,
        @Param("minSize") minSize: Long
    ): List<TaxDocument>

    /**
     * 파일 유형별 서류 조회
     */
    fun findByCompanyIdAndFileTypeOrderByCreatedAtDesc(
        companyId: UUID,
        fileType: String
    ): List<TaxDocument>

    /**
     * 서류 유형별 통계
     */
    @Query("""
        SELECT 
            td.documentType,
            COUNT(td) as count,
            SUM(td.fileSize) as totalSize,
            AVG(td.fileSize) as avgSize
        FROM TaxDocument td 
        WHERE td.companyId = :companyId 
        GROUP BY td.documentType
        ORDER BY count DESC
    """)
    fun getDocumentStatisticsByType(companyId: UUID): List<Array<Any>>

    /**
     * 월별 서류 등록 통계
     */
    @Query("""
        SELECT 
            EXTRACT(YEAR FROM td.createdAt) as year,
            EXTRACT(MONTH FROM td.createdAt) as month,
            COUNT(td) as count,
            SUM(td.fileSize) as totalSize
        FROM TaxDocument td 
        WHERE td.companyId = :companyId 
        AND td.createdAt BETWEEN :startDate AND :endDate
        GROUP BY EXTRACT(YEAR FROM td.createdAt), EXTRACT(MONTH FROM td.createdAt)
        ORDER BY year DESC, month DESC
    """)
    fun getMonthlyDocumentStatistics(
        @Param("companyId") companyId: UUID,
        @Param("startDate") startDate: LocalDate,
        @Param("endDate") endDate: LocalDate
    ): List<Array<Any>>

    /**
     * 전체 저장 공간 사용량 조회
     */
    @Query("""
        SELECT 
            COUNT(td) as totalCount,
            SUM(td.fileSize) as totalSize,
            AVG(td.fileSize) as avgSize,
            MAX(td.fileSize) as maxSize,
            MIN(td.fileSize) as minSize
        FROM TaxDocument td 
        WHERE td.companyId = :companyId
    """)
    fun getStorageStatistics(companyId: UUID): Array<Any>

    /**
     * 연관 관계가 없는 독립 서류 조회
     */
    @Query("""
        SELECT td FROM TaxDocument td 
        WHERE td.companyId = :companyId 
        AND td.relatedTaxPeriodId IS NULL
        AND td.relatedVatReturnId IS NULL
        AND td.relatedWithholdingId IS NULL
        AND td.relatedTaxInvoiceId IS NULL
        ORDER BY td.createdAt DESC
    """)
    fun findUnlinkedDocuments(companyId: UUID): List<TaxDocument>

    /**
     * 중복 파일명 검사
     */
    fun existsByCompanyIdAndFileName(companyId: UUID, fileName: String): Boolean

    /**
     * 파일 경로로 서류 조회
     */
    fun findByCompanyIdAndFilePath(companyId: UUID, filePath: String): TaxDocument?

    /**
     * 최근 업로드된 서류 조회 (N개)
     */
    @Query("""
        SELECT td FROM TaxDocument td 
        WHERE td.companyId = :companyId 
        ORDER BY td.createdAt DESC
        LIMIT :limit
    """)
    fun findRecentDocuments(
        @Param("companyId") companyId: UUID,
        @Param("limit") limit: Int
    ): List<TaxDocument>
}