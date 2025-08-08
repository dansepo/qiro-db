package com.qiro.domain.accounting.repository

import com.qiro.domain.accounting.entity.Vendor
import org.springframework.data.domain.Page
import org.springframework.data.domain.Pageable
import org.springframework.data.jpa.repository.JpaRepository
import org.springframework.data.jpa.repository.Query
import org.springframework.data.repository.query.Param
import org.springframework.stereotype.Repository
import java.util.*

/**
 * 업체 Repository
 */
@Repository
interface VendorRepository : JpaRepository<Vendor, UUID> {

    /**
     * 회사별 업체 조회 (페이징)
     */
    fun findByCompanyIdOrderByVendorNameAsc(companyId: UUID, pageable: Pageable): Page<Vendor>

    /**
     * 회사별 활성 업체 조회
     */
    fun findByCompanyIdAndIsActiveTrueOrderByVendorNameAsc(companyId: UUID): List<Vendor>

    /**
     * 업체 코드로 조회
     */
    fun findByCompanyIdAndVendorCode(companyId: UUID, vendorCode: String): Vendor?

    /**
     * 업체명으로 검색
     */
    @Query("""
        SELECT v FROM Vendor v 
        WHERE v.companyId = :companyId 
        AND v.vendorName LIKE %:vendorName% 
        AND v.isActive = true
        ORDER BY v.vendorName
    """)
    fun findByVendorNameContaining(
        @Param("companyId") companyId: UUID,
        @Param("vendorName") vendorName: String
    ): List<Vendor>

    /**
     * 업체 유형별 조회
     */
    @Query("""
        SELECT v FROM Vendor v 
        WHERE v.companyId = :companyId 
        AND v.vendorType = :vendorType 
        AND v.isActive = true
        ORDER BY v.vendorName
    """)
    fun findByVendorType(
        @Param("companyId") companyId: UUID,
        @Param("vendorType") vendorType: String
    ): List<Vendor>

    /**
     * 사업자등록번호로 조회
     */
    fun findByCompanyIdAndBusinessNumber(companyId: UUID, businessNumber: String): Vendor?

    /**
     * 연락처로 검색
     */
    @Query("""
        SELECT v FROM Vendor v 
        WHERE v.companyId = :companyId 
        AND (v.phoneNumber LIKE %:contact% OR v.email LIKE %:contact%)
        AND v.isActive = true
        ORDER BY v.vendorName
    """)
    fun findByContact(
        @Param("companyId") companyId: UUID,
        @Param("contact") contact: String
    ): List<Vendor>

    /**
     * 업체 코드 중복 확인
     */
    fun existsByCompanyIdAndVendorCode(companyId: UUID, vendorCode: String): Boolean

    /**
     * 사업자등록번호 중복 확인
     */
    fun existsByCompanyIdAndBusinessNumber(companyId: UUID, businessNumber: String): Boolean

    /**
     * 최근 거래 업체 조회 (지출 기록 기준)
     */
    @Query("""
        SELECT DISTINCT v FROM Vendor v 
        JOIN ExpenseRecord er ON v.vendorId = er.vendor.vendorId
        WHERE v.companyId = :companyId 
        AND er.expenseDate >= :fromDate
        AND v.isActive = true
        ORDER BY MAX(er.expenseDate) DESC
    """)
    fun findRecentVendors(
        @Param("companyId") companyId: UUID,
        @Param("fromDate") fromDate: java.time.LocalDate
    ): List<Vendor>

    /**
     * 거래 실적이 있는 업체 조회
     */
    @Query("""
        SELECT DISTINCT v FROM Vendor v 
        WHERE v.companyId = :companyId 
        AND EXISTS (
            SELECT 1 FROM ExpenseRecord er 
            WHERE er.vendor.vendorId = v.vendorId
        )
        AND v.isActive = true
        ORDER BY v.vendorName
    """)
    fun findVendorsWithTransactions(@Param("companyId") companyId: UUID): List<Vendor>

    /**
     * 거래 실적이 없는 업체 조회
     */
    @Query("""
        SELECT v FROM Vendor v 
        WHERE v.companyId = :companyId 
        AND NOT EXISTS (
            SELECT 1 FROM ExpenseRecord er 
            WHERE er.vendor.vendorId = v.vendorId
        )
        AND v.isActive = true
        ORDER BY v.createdAt DESC
    """)
    fun findVendorsWithoutTransactions(@Param("companyId") companyId: UUID): List<Vendor>

    // Service에서 필요한 추가 메서드들
    
    /**
     * 회사별 활성 업체 조회
     */
    fun findByCompanyIdAndIsActiveTrue(companyId: UUID): List<Vendor>

    /**
     * 업체명으로 검색 (대소문자 무시)
     */
    fun findByCompanyIdAndVendorNameContainingIgnoreCase(companyId: UUID, vendorName: String): List<Vendor>
}