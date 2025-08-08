package com.qiro.domain.insurance.service

import org.springframework.stereotype.Service
import org.springframework.transaction.annotation.Transactional
import java.time.LocalDate
import java.time.LocalDateTime
import java.time.temporal.ChronoUnit
import java.util.*

/**
 * 보험 서비스 구현체
 * 
 * 건물 보험, 배상책임보험, 보험금 청구 등의 기능을 구현합니다.
 */
@Service
@Transactional
class InsuranceServiceImpl : InsuranceService {

    override fun registerInsurancePolicy(
        companyId: UUID,
        policyType: String,
        insuranceCompany: String,
        policyNumber: String,
        coverageAmount: Double,
        premium: Double,
        startDate: LocalDate,
        endDate: LocalDate,
        coverageDetails: Map<String, Any>
    ): Map<String, Any> {
        val policyId = UUID.randomUUID()
        
        return mapOf(
            "policyId" to policyId,
            "policyType" to policyType,
            "insuranceCompany" to insuranceCompany,
            "policyNumber" to policyNumber,
            "coverageAmount" to coverageAmount,
            "premium" to premium,
            "startDate" to startDate,
            "endDate" to endDate,
            "coverageDetails" to coverageDetails,
            "status" to "ACTIVE",
            "registeredAt" to LocalDateTime.now(),
            "renewalNotificationDate" to endDate.minusDays(30),
            "deductible" to coverageDetails["deductible"] ?: 0.0,
            "coverageTypes" to extractCoverageTypes(coverageDetails)
        )
    }

    override fun submitInsuranceClaim(
        companyId: UUID,
        policyId: UUID,
        claimType: String,
        incidentDate: LocalDate,
        claimAmount: Double,
        description: String,
        supportingDocuments: List<String>
    ): Map<String, Any> {
        val claimId = UUID.randomUUID()
        val claimNumber = "CLM-${System.currentTimeMillis()}"
        
        // 청구 가능성 검증
        val eligibility = validateClaimEligibility(policyId, claimType, incidentDate, claimAmount)
        
        return mapOf(
            "claimId" to claimId,
            "claimNumber" to claimNumber,
            "policyId" to policyId,
            "claimType" to claimType,
            "incidentDate" to incidentDate,
            "claimAmount" to claimAmount,
            "description" to description,
            "supportingDocuments" to supportingDocuments,
            "status" to "SUBMITTED",
            "submittedAt" to LocalDateTime.now(),
            "eligibility" to eligibility,
            "estimatedProcessingTime" to calculateProcessingTime(claimType, claimAmount),
            "nextAction" to determineNextAction(eligibility),
            "assignedAdjuster" to assignClaimAdjuster(claimType, claimAmount)
        )
    }

    override fun getClaimStatus(
        companyId: UUID,
        claimId: UUID
    ): Map<String, Any> {
        // 실제 구현에서는 데이터베이스에서 조회
        val claimData = getClaimData(claimId)
        
        return mapOf(
            "claimId" to claimId,
            "claimNumber" to claimData["claimNumber"],
            "status" to claimData["status"],
            "submittedAt" to claimData["submittedAt"],
            "lastUpdated" to LocalDateTime.now(),
            "processedAmount" to claimData["processedAmount"] ?: 0.0,
            "remainingAmount" to calculateRemainingAmount(claimData),
            "statusHistory" to getClaimStatusHistory(claimId),
            "requiredDocuments" to getRequiredDocuments(claimId),
            "estimatedCompletionDate" to calculateEstimatedCompletion(claimData),
            "contactInfo" to mapOf(
                "adjusterName" to claimData["adjusterName"],
                "adjusterPhone" to claimData["adjusterPhone"],
                "adjusterEmail" to claimData["adjusterEmail"]
            )
        )
    }

    override fun checkInsuranceRenewalNotifications(companyId: UUID): List<Map<String, Any>> {
        // 실제 구현에서는 데이터베이스에서 만료 예정 보험을 조회
        val expiringPolicies = getExpiringPolicies(companyId)
        
        return expiringPolicies.map { policy ->
            val daysUntilExpiry = ChronoUnit.DAYS.between(LocalDate.now(), policy["endDate"] as LocalDate)
            
            mapOf(
                "policyId" to policy["policyId"],
                "policyType" to policy["policyType"],
                "insuranceCompany" to policy["insuranceCompany"],
                "policyNumber" to policy["policyNumber"],
                "endDate" to policy["endDate"],
                "daysUntilExpiry" to daysUntilExpiry,
                "urgency" to when {
                    daysUntilExpiry <= 7 -> "CRITICAL"
                    daysUntilExpiry <= 30 -> "HIGH"
                    daysUntilExpiry <= 60 -> "MEDIUM"
                    else -> "LOW"
                },
                "renewalOptions" to generateRenewalOptions(policy),
                "recommendedAction" to determineRenewalAction(daysUntilExpiry)
            )
        }
    }

    override fun validateInsuranceCoverage(
        companyId: UUID,
        incidentType: String,
        estimatedCost: Double
    ): Map<String, Any> {
        val applicablePolicies = findApplicablePolicies(companyId, incidentType)
        
        val coverageAnalysis = applicablePolicies.map { policy ->
            val coverageAmount = policy["coverageAmount"] as Double
            val deductible = policy["deductible"] as Double
            val isCovered = estimatedCost <= coverageAmount
            val payableAmount = if (isCovered) (estimatedCost - deductible).coerceAtLeast(0.0) else 0.0
            
            mapOf(
                "policyId" to policy["policyId"],
                "policyType" to policy["policyType"],
                "isCovered" to isCovered,
                "coverageAmount" to coverageAmount,
                "deductible" to deductible,
                "estimatedPayableAmount" to payableAmount,
                "coveragePercentage" to if (coverageAmount > 0) (estimatedCost / coverageAmount * 100).coerceAtMost(100.0) else 0.0
            )
        }
        
        val totalCoverage = coverageAnalysis.sumOf { it["estimatedPayableAmount"] as Double }
        val isFullyCovered = totalCoverage >= (estimatedCost - coverageAnalysis.minOfOrNull { it["deductible"] as Double } ?: 0.0)
        
        return mapOf(
            "incidentType" to incidentType,
            "estimatedCost" to estimatedCost,
            "isFullyCovered" to isFullyCovered,
            "totalCoverage" to totalCoverage,
            "outOfPocketCost" to (estimatedCost - totalCoverage).coerceAtLeast(0.0),
            "applicablePolicies" to coverageAnalysis,
            "recommendations" to generateCoverageRecommendations(isFullyCovered, estimatedCost, totalCoverage)
        )
    }

    private fun extractCoverageTypes(coverageDetails: Map<String, Any>): List<String> {
        return coverageDetails.keys.filter { key ->
            key.endsWith("Coverage") && coverageDetails[key] == true
        }
    }

    private fun validateClaimEligibility(
        policyId: UUID,
        claimType: String,
        incidentDate: LocalDate,
        claimAmount: Double
    ): Map<String, Any> {
        // 실제 구현에서는 정책 데이터를 조회하여 검증
        val policy = getPolicyData(policyId)
        val isWithinPolicyPeriod = incidentDate.isAfter(policy["startDate"] as LocalDate) && 
                                  incidentDate.isBefore(policy["endDate"] as LocalDate)
        val isWithinCoverageLimit = claimAmount <= (policy["coverageAmount"] as Double)
        val isCoveredType = (policy["coverageTypes"] as List<*>).contains(claimType)
        
        return mapOf(
            "isEligible" to (isWithinPolicyPeriod && isWithinCoverageLimit && isCoveredType),
            "withinPolicyPeriod" to isWithinPolicyPeriod,
            "withinCoverageLimit" to isWithinCoverageLimit,
            "coveredType" to isCoveredType,
            "eligibilityNotes" to generateEligibilityNotes(isWithinPolicyPeriod, isWithinCoverageLimit, isCoveredType)
        )
    }

    private fun calculateProcessingTime(claimType: String, claimAmount: Double): Int {
        return when {
            claimAmount > 10000000 -> 30 // 대형 청구: 30일
            claimAmount > 5000000 -> 21  // 중형 청구: 21일
            claimType in listOf("FIRE", "FLOOD", "EARTHQUAKE") -> 28 // 재해 관련: 28일
            else -> 14 // 일반 청구: 14일
        }
    }

    private fun determineNextAction(eligibility: Map<String, Any>): String {
        return if (eligibility["isEligible"] as Boolean) {
            "문서 검토 및 현장 조사 예정"
        } else {
            "추가 서류 제출 또는 정책 확인 필요"
        }
    }

    private fun assignClaimAdjuster(claimType: String, claimAmount: Double): Map<String, String> {
        return when {
            claimAmount > 10000000 -> mapOf(
                "name" to "김전문",
                "phone" to "02-1234-5678",
                "email" to "expert.kim@insurance.com",
                "specialty" to "대형사고전문"
            )
            claimType in listOf("FIRE", "FLOOD") -> mapOf(
                "name" to "이재해",
                "phone" to "02-2345-6789", 
                "email" to "disaster.lee@insurance.com",
                "specialty" to "재해전문"
            )
            else -> mapOf(
                "name" to "박일반",
                "phone" to "02-3456-7890",
                "email" to "general.park@insurance.com",
                "specialty" to "일반사고"
            )
        }
    }

    private fun getClaimData(claimId: UUID): Map<String, Any> {
        // 실제 구현에서는 데이터베이스에서 조회
        return mapOf(
            "claimNumber" to "CLM-2024-001",
            "status" to "UNDER_REVIEW",
            "submittedAt" to LocalDateTime.now().minusDays(5),
            "processedAmount" to 0.0,
            "claimAmount" to 5000000.0,
            "adjusterName" to "김전문",
            "adjusterPhone" to "02-1234-5678",
            "adjusterEmail" to "expert.kim@insurance.com"
        )
    }

    private fun calculateRemainingAmount(claimData: Map<String, Any>): Double {
        val claimAmount = claimData["claimAmount"] as? Double ?: 0.0
        val processedAmount = claimData["processedAmount"] as? Double ?: 0.0
        return claimAmount - processedAmount
    }

    private fun getClaimStatusHistory(claimId: UUID): List<Map<String, Any>> {
        return listOf(
            mapOf(
                "status" to "SUBMITTED",
                "date" to LocalDateTime.now().minusDays(5),
                "note" to "청구 접수 완료"
            ),
            mapOf(
                "status" to "UNDER_REVIEW",
                "date" to LocalDateTime.now().minusDays(3),
                "note" to "서류 검토 중"
            )
        )
    }

    private fun getRequiredDocuments(claimId: UUID): List<String> {
        return listOf(
            "사고 현장 사진",
            "수리 견적서",
            "경찰서 신고 접수증",
            "의료진단서 (부상자 있는 경우)"
        )
    }

    private fun calculateEstimatedCompletion(claimData: Map<String, Any>): LocalDate {
        val submittedAt = claimData["submittedAt"] as LocalDateTime
        return submittedAt.toLocalDate().plusDays(14)
    }

    private fun getExpiringPolicies(companyId: UUID): List<Map<String, Any>> {
        // 실제 구현에서는 데이터베이스에서 조회
        return listOf(
            mapOf(
                "policyId" to UUID.randomUUID(),
                "policyType" to "BUILDING_INSURANCE",
                "insuranceCompany" to "대한화재보험",
                "policyNumber" to "POL-2024-001",
                "endDate" to LocalDate.now().plusDays(25),
                "coverageAmount" to 50000000.0,
                "premium" to 1200000.0
            )
        )
    }

    private fun generateRenewalOptions(policy: Map<String, Any>): List<Map<String, Any>> {
        val currentPremium = policy["premium"] as Double
        
        return listOf(
            mapOf(
                "option" to "SAME_COVERAGE",
                "description" to "동일 조건 갱신",
                "premium" to currentPremium * 1.05,
                "benefits" to listOf("기존 조건 유지", "간편한 갱신 절차")
            ),
            mapOf(
                "option" to "ENHANCED_COVERAGE",
                "description" to "보장 확대 갱신",
                "premium" to currentPremium * 1.15,
                "benefits" to listOf("보장 한도 증액", "추가 특약 포함")
            ),
            mapOf(
                "option" to "BASIC_COVERAGE",
                "description" to "기본 보장 갱신",
                "premium" to currentPremium * 0.95,
                "benefits" to listOf("보험료 절약", "필수 보장 유지")
            )
        )
    }

    private fun determineRenewalAction(daysUntilExpiry: Long): String {
        return when {
            daysUntilExpiry <= 7 -> "즉시 갱신 절차 진행 필요"
            daysUntilExpiry <= 30 -> "갱신 검토 및 견적 요청 권장"
            daysUntilExpiry <= 60 -> "갱신 계획 수립 시작"
            else -> "갱신 일정 모니터링"
        }
    }

    private fun findApplicablePolicies(companyId: UUID, incidentType: String): List<Map<String, Any>> {
        // 실제 구현에서는 데이터베이스에서 해당 사고 유형에 적용 가능한 보험을 조회
        return listOf(
            mapOf(
                "policyId" to UUID.randomUUID(),
                "policyType" to "BUILDING_INSURANCE",
                "coverageAmount" to 50000000.0,
                "deductible" to 500000.0,
                "coverageTypes" to listOf("FIRE", "WATER_DAMAGE", "THEFT")
            ),
            mapOf(
                "policyId" to UUID.randomUUID(),
                "policyType" to "LIABILITY_INSURANCE",
                "coverageAmount" to 30000000.0,
                "deductible" to 300000.0,
                "coverageTypes" to listOf("PERSONAL_INJURY", "PROPERTY_DAMAGE")
            )
        )
    }

    private fun generateCoverageRecommendations(
        isFullyCovered: Boolean,
        estimatedCost: Double,
        totalCoverage: Double
    ): List<String> {
        val recommendations = mutableListOf<String>()
        
        if (!isFullyCovered) {
            val gap = estimatedCost - totalCoverage
            recommendations.add("보장 부족액: ${gap.toInt()}원 - 추가 보험 가입을 검토하세요")
        }
        
        if (totalCoverage < estimatedCost * 0.8) {
            recommendations.add("보장 범위가 부족합니다. 보험 한도 증액을 고려하세요")
        }
        
        if (isFullyCovered) {
            recommendations.add("충분한 보장이 확인되었습니다. 신속한 청구 절차를 진행하세요")
        }
        
        return recommendations
    }

    private fun generateEligibilityNotes(
        withinPolicyPeriod: Boolean,
        withinCoverageLimit: Boolean,
        coveredType: Boolean
    ): List<String> {
        val notes = mutableListOf<String>()
        
        if (!withinPolicyPeriod) {
            notes.add("사고 발생일이 보험 기간 외입니다")
        }
        
        if (!withinCoverageLimit) {
            notes.add("청구 금액이 보장 한도를 초과합니다")
        }
        
        if (!coveredType) {
            notes.add("해당 사고 유형은 보장 대상이 아닙니다")
        }
        
        return notes
    }

    private fun getPolicyData(policyId: UUID): Map<String, Any> {
        // 실제 구현에서는 데이터베이스에서 조회
        return mapOf(
            "startDate" to LocalDate.now().minusYears(1),
            "endDate" to LocalDate.now().plusMonths(6),
            "coverageAmount" to 50000000.0,
            "coverageTypes" to listOf("FIRE", "WATER_DAMAGE", "THEFT", "LIABILITY")
        )
    }
}