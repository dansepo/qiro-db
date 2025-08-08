package com.qiro.domain.insurance.service

import java.time.LocalDate
import java.util.*

/**
 * 보험 서비스 인터페이스
 * 
 * 건물 보험, 배상책임보험, 보험금 청구 등의 기능을 제공합니다.
 */
interface InsuranceService {
    
    /**
     * 보험 정책 등록
     */
    fun registerInsurancePolicy(
        companyId: UUID,
        policyType: String,
        insuranceCompany: String,
        policyNumber: String,
        coverageAmount: Double,
        premium: Double,
        startDate: LocalDate,
        endDate: LocalDate,
        coverageDetails: Map<String, Any>
    ): Map<String, Any>
    
    /**
     * 보험금 청구 접수
     */
    fun submitInsuranceClaim(
        companyId: UUID,
        policyId: UUID,
        claimType: String,
        incidentDate: LocalDate,
        claimAmount: Double,
        description: String,
        supportingDocuments: List<String>
    ): Map<String, Any>
    
    /**
     * 보험금 청구 처리 상태 조회
     */
    fun getClaimStatus(
        companyId: UUID,
        claimId: UUID
    ): Map<String, Any>
    
    /**
     * 보험 갱신 알림
     */
    fun checkInsuranceRenewalNotifications(companyId: UUID): List<Map<String, Any>>
    
    /**
     * 보험 적용 범위 검증
     */
    fun validateInsuranceCoverage(
        companyId: UUID,
        incidentType: String,
        estimatedCost: Double
    ): Map<String, Any>
}