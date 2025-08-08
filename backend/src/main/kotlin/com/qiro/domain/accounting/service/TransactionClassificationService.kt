package com.qiro.domain.accounting.service

import com.qiro.common.tenant.TenantContext
import com.qiro.domain.accounting.entity.*
import com.qiro.domain.accounting.repository.*
import org.slf4j.LoggerFactory
import org.springframework.stereotype.Service
import org.springframework.transaction.annotation.Transactional
import java.math.BigDecimal
import java.util.*

/**
 * 거래 분류 서비스
 * 자동 계정과목 제안 및 매칭 로직을 제공합니다.
 */
@Service
@Transactional(readOnly = true)
class TransactionClassificationService(
    private val transactionRuleRepository: TransactionRuleRepository,
    private val accountRepository: AccountRepository
) {

    private val logger = LoggerFactory.getLogger(TransactionClassificationService::class.java)

    /**
     * 거래에 대한 계정과목 제안
     */
    fun suggestAccount(transaction: Transaction): AccountSuggestion? {
        val companyId = TenantContext.getCurrentTenantId()
        
        logger.info("거래 분류 시작: ${transaction.transactionId}")

        // 활성 규칙들을 우선순위 순으로 조회
        val rules = transactionRuleRepository.findByCompanyIdAndIsActiveTrueOrderByPriorityAscCreatedAtAsc(companyId)
        
        // 각 규칙에 대해 매칭 확인
        for (rule in rules) {
            if (rule.matches(transaction)) {
                logger.info("규칙 매칭 성공: ${rule.ruleName} -> ${rule.suggestedAccount.accountName}")
                
                // 규칙 사용 횟수 증가
                rule.incrementUsage()
                transactionRuleRepository.save(rule)
                
                return AccountSuggestion(
                    account = rule.suggestedAccount,
                    confidenceScore = rule.confidenceScore,
                    matchedRule = rule,
                    reason = "규칙 매칭: ${rule.ruleName}"
                )
            }
        }

        // 규칙 매칭이 실패한 경우 기본 계정과목 제안
        val defaultSuggestion = suggestDefaultAccount(transaction)
        if (defaultSuggestion != null) {
            logger.info("기본 계정과목 제안: ${defaultSuggestion.account.accountName}")
            return defaultSuggestion
        }

        logger.warn("계정과목 제안 실패: ${transaction.transactionId}")
        return null
    }

    /**
     * 승인된 거래로부터 학습
     */
    @Transactional
    fun learnFromApproval(transaction: Transaction, approvedAccount: Account) {
        val companyId = TenantContext.getCurrentTenantId()
        
        logger.info("거래 승인 학습 시작: ${transaction.transactionId} -> ${approvedAccount.accountName}")

        // 기존 제안이 정확했는지 확인
        if (transaction.suggestedAccount?.accountId == approvedAccount.accountId) {
            // 제안이 정확했다면 해당 규칙의 성공 횟수 증가
            val rules = transactionRuleRepository.findByCompanyIdAndIsActiveTrueOrderByPriorityAscCreatedAtAsc(companyId)
            for (rule in rules) {
                if (rule.matches(transaction) && rule.suggestedAccount.accountId == approvedAccount.accountId) {
                    rule.incrementSuccess()
                    transactionRuleRepository.save(rule)
                    logger.info("규칙 성공 횟수 증가: ${rule.ruleName}")
                    break
                }
            }
        } else {
            // 제안이 틀렸다면 새로운 규칙 생성 고려
            considerCreatingNewRule(transaction, approvedAccount)
        }
    }

    /**
     * 거래 패턴 분석
     */
    fun analyzeTransactionPatterns(companyId: UUID): TransactionPatternAnalysis {
        val rules = transactionRuleRepository.findByCompanyIdOrderByPriorityAscCreatedAtAsc(companyId)
        
        val totalRules = rules.size
        val activeRules = rules.count { it.isActive }
        val totalUsage = rules.sumOf { it.usageCount }
        val totalSuccess = rules.sumOf { it.successCount }
        val averageSuccessRate = if (totalUsage > 0) {
            BigDecimal(totalSuccess).divide(BigDecimal(totalUsage), 4, java.math.RoundingMode.HALF_UP)
        } else {
            BigDecimal.ZERO
        }

        val topPerformingRules = transactionRuleRepository.findTopPerformingRules(companyId, 5, 5)
        val mostUsedRules = transactionRuleRepository.findMostUsedRules(companyId, 5)

        return TransactionPatternAnalysis(
            totalRules = totalRules,
            activeRules = activeRules,
            totalUsage = totalUsage,
            totalSuccess = totalSuccess,
            averageSuccessRate = averageSuccessRate,
            topPerformingRules = topPerformingRules,
            mostUsedRules = mostUsedRules
        )
    }

    /**
     * 기본 계정과목 제안
     */
    private fun suggestDefaultAccount(transaction: Transaction): AccountSuggestion? {
        val companyId = TenantContext.getCurrentTenantId()
        
        // 거래 유형과 카테고리에 따른 기본 계정과목 매핑
        val defaultAccountCode = when (transaction.transactionType) {
            TransactionType.INCOME -> when (transaction.transactionCategory) {
                TransactionCategory.MANAGEMENT_FEE_INCOME -> "4200" // 관리비수익
                TransactionCategory.RENTAL_INCOME -> "4100" // 임대료수익
                TransactionCategory.PARKING_FEE_INCOME -> "4300" // 기타수익
                TransactionCategory.OTHER_INCOME -> "4300" // 기타수익
                else -> "4300" // 기타수익
            }
            TransactionType.EXPENSE -> when (transaction.transactionCategory) {
                TransactionCategory.FACILITY_MAINTENANCE -> "5100" // 관리비
                TransactionCategory.PERSONNEL_EXPENSE -> "5100" // 관리비
                TransactionCategory.UTILITY_EXPENSE -> "5300" // 세금과공과
                TransactionCategory.INSURANCE_EXPENSE -> "5500" // 기타비용
                TransactionCategory.TAX_EXPENSE -> "5300" // 세금과공과
                TransactionCategory.REPAIR_EXPENSE -> "5200" // 수선비
                TransactionCategory.CLEANING_EXPENSE -> "5100" // 관리비
                TransactionCategory.SECURITY_EXPENSE -> "5100" // 관리비
                TransactionCategory.OTHER_EXPENSE -> "5500" // 기타비용
                else -> "5500" // 기타비용
            }
        }

        val defaultAccount = accountRepository.findByCompanyIdAndAccountCode(companyId, defaultAccountCode)
        
        return if (defaultAccount != null) {
            AccountSuggestion(
                account = defaultAccount,
                confidenceScore = BigDecimal("0.60"), // 기본 제안은 낮은 신뢰도
                matchedRule = null,
                reason = "기본 계정과목 매핑: ${transaction.transactionCategory.name}"
            )
        } else {
            null
        }
    }

    /**
     * 새로운 규칙 생성 고려
     */
    private fun considerCreatingNewRule(transaction: Transaction, approvedAccount: Account) {
        val companyId = TenantContext.getCurrentTenantId()
        
        // 동일한 거래처나 설명 패턴이 반복되는지 확인
        val similarTransactions = findSimilarTransactions(transaction)
        
        if (similarTransactions.size >= 3) { // 3회 이상 반복되면 규칙 생성 고려
            logger.info("새로운 규칙 생성 고려: ${transaction.counterparty} -> ${approvedAccount.accountName}")
            
            // 자동 규칙 생성 (실제 구현에서는 관리자 승인 필요할 수 있음)
            val ruleName = "자동생성: ${transaction.counterparty ?: transaction.transactionCategory.name}"
            
            if (!transactionRuleRepository.existsByCompanyIdAndRuleName(companyId, ruleName)) {
                val newRule = TransactionRule(
                    ruleName = ruleName,
                    description = "자동 생성된 규칙",
                    transactionType = transaction.transactionType,
                    transactionCategory = transaction.transactionCategory,
                    counterpartyPattern = transaction.counterparty,
                    suggestedAccount = approvedAccount,
                    confidenceScore = BigDecimal("0.75"),
                    priority = 200 // 낮은 우선순위
                ).apply {
                    companyId = TenantContext.getCurrentTenantId()
                    createdBy = TenantContext.getCurrentUserId()
                }
                
                transactionRuleRepository.save(newRule)
                logger.info("새로운 규칙 생성됨: $ruleName")
            }
        }
    }

    /**
     * 유사한 거래 찾기
     */
    private fun findSimilarTransactions(transaction: Transaction): List<Transaction> {
        // 실제 구현에서는 TransactionRepository에 메서드 추가 필요
        // 여기서는 간단한 구현만 제공
        return emptyList()
    }
}

/**
 * 계정과목 제안 결과
 */
data class AccountSuggestion(
    val account: Account,
    val confidenceScore: BigDecimal,
    val matchedRule: TransactionRule?,
    val reason: String
)

/**
 * 거래 패턴 분석 결과
 */
data class TransactionPatternAnalysis(
    val totalRules: Int,
    val activeRules: Int,
    val totalUsage: Long,
    val totalSuccess: Long,
    val averageSuccessRate: BigDecimal,
    val topPerformingRules: List<TransactionRule>,
    val mostUsedRules: List<TransactionRule>
)