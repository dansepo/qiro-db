package com.qiro.domain.accounting.service

import com.qiro.domain.accounting.entity.LateFeePolicy
import com.qiro.domain.accounting.entity.Receivable
import com.qiro.domain.accounting.repository.LateFeePolicyRepository
import com.qiro.domain.accounting.repository.ReceivableRepository
import org.springframework.stereotype.Service
import org.springframework.transaction.annotation.Transactional
import java.math.BigDecimal
import java.time.LocalDate
import java.util.*

/**
 * 연체료 계산 서비스
 * 연체료 자동 계산 및 적용 기능을 제공
 */
@Service
@Transactional
class LateFeeCalculationService(
    private val receivableRepository: ReceivableRepository,
    private val lateFeePolicyRepository: LateFeePolicyRepository
) {

    /**
     * 연체료 계산
     */
    fun calculateLateFee(
        receivableId: UUID,
        calculationDate: LocalDate = LocalDate.now()
    ): BigDecimal {
        val receivable = receivableRepository.findById(receivableId)
            .orElseThrow { IllegalArgumentException("존재하지 않는 미수금입니다: $receivableId") }

        return calculateLateFeeForReceivable(receivable, calculationDate)
    }

    /**
     * 미수금에 대한 연체료 계산
     */
    private fun calculateLateFeeForReceivable(
        receivable: Receivable,
        calculationDate: LocalDate
    ): BigDecimal {
        // 연체 여부 확인
        if (!receivable.isOverdue(calculationDate)) {
            return BigDecimal.ZERO
        }

        // 연체료 정책 조회
        val policy = lateFeePolicyRepository.findEffectivePolicy(
            companyId = receivable.companyId,
            incomeTypeId = receivable.incomeRecord.incomeType.incomeTypeId,
            date = calculationDate
        ) ?: return BigDecimal.ZERO

        // 연체 일수 계산
        val overdueDays = receivable.calculateOverdueDays(calculationDate)

        // 연체료 계산
        return policy.calculateLateFee(receivable.outstandingAmount, overdueDays)
    }

    /**
     * 회사의 모든 연체 미수금에 대한 연체료 일괄 계산 및 적용
     */
    fun calculateAndApplyLateFees(companyId: UUID, calculationDate: LocalDate = LocalDate.now()): Int {
        val overdueReceivables = receivableRepository.findOverdueReceivables(companyId, calculationDate)
        var updatedCount = 0

        overdueReceivables.forEach { receivable ->
            val lateFee = calculateLateFeeForReceivable(receivable, calculationDate)
            
            // 연체료가 변경된 경우에만 업데이트
            if (lateFee != receivable.lateFeeAmount) {
                val updatedReceivable = receivable.applyLateFee(lateFee)
                receivableRepository.save(updatedReceivable)
                updatedCount++
            }
        }

        return updatedCount
    }

    /**
     * 특정 미수금에 연체료 적용
     */
    fun applyLateFeeToReceivable(
        receivableId: UUID,
        calculationDate: LocalDate = LocalDate.now()
    ): Receivable {
        val receivable = receivableRepository.findById(receivableId)
            .orElseThrow { IllegalArgumentException("존재하지 않는 미수금입니다: $receivableId") }

        val lateFee = calculateLateFeeForReceivable(receivable, calculationDate)
        val updatedReceivable = receivable.applyLateFee(lateFee)

        return receivableRepository.save(updatedReceivable)
    }

    /**
     * 연체료 정책 유효성 검증
     */
    @Transactional(readOnly = true)
    fun validateLateFeePolicy(policy: LateFeePolicy): List<String> {
        val errors = mutableListOf<String>()

        when (policy.lateFeeType) {
            LateFeePolicy.LateFeeType.PERCENTAGE, LateFeePolicy.LateFeeType.DAILY_RATE -> {
                if (policy.lateFeeRate == null || policy.lateFeeRate <= BigDecimal.ZERO) {
                    errors.add("비율 기반 연체료 정책은 연체료율이 필요합니다")
                }
                if (policy.lateFeeRate != null && policy.lateFeeRate > BigDecimal(100)) {
                    errors.add("연체료율은 100%를 초과할 수 없습니다")
                }
            }
            LateFeePolicy.LateFeeType.FIXED -> {
                if (policy.fixedLateFee == null || policy.fixedLateFee <= BigDecimal.ZERO) {
                    errors.add("고정 연체료 정책은 고정 연체료 금액이 필요합니다")
                }
            }
        }

        if (policy.gracePeriodDays < 0) {
            errors.add("유예 기간은 0일 이상이어야 합니다")
        }

        if (policy.maxLateFee != null && policy.maxLateFee <= BigDecimal.ZERO) {
            errors.add("최대 연체료는 0보다 커야 합니다")
        }

        if (policy.effectiveTo != null && policy.effectiveTo.isBefore(policy.effectiveFrom)) {
            errors.add("종료일은 시작일보다 늦어야 합니다")
        }

        return errors
    }

    /**
     * 연체료 계산 시뮬레이션
     */
    @Transactional(readOnly = true)
    fun simulateLateFeeCalculation(
        outstandingAmount: BigDecimal,
        overdueDays: Int,
        policy: LateFeePolicy
    ): BigDecimal {
        return policy.calculateLateFee(outstandingAmount, overdueDays)
    }

    /**
     * 연체료 계산 내역 조회
     */
    @Transactional(readOnly = true)
    fun getLateFeeCalculationDetails(
        receivableId: UUID,
        calculationDate: LocalDate = LocalDate.now()
    ): LateFeeCalculationDetails {
        val receivable = receivableRepository.findById(receivableId)
            .orElseThrow { IllegalArgumentException("존재하지 않는 미수금입니다: $receivableId") }

        val policy = lateFeePolicyRepository.findEffectivePolicy(
            companyId = receivable.companyId,
            incomeTypeId = receivable.incomeRecord.incomeType.incomeTypeId,
            date = calculationDate
        )

        val overdueDays = receivable.calculateOverdueDays(calculationDate)
        val lateFee = policy?.calculateLateFee(receivable.outstandingAmount, overdueDays) ?: BigDecimal.ZERO

        return LateFeeCalculationDetails(
            receivableId = receivableId,
            outstandingAmount = receivable.outstandingAmount,
            dueDate = receivable.dueDate,
            calculationDate = calculationDate,
            overdueDays = overdueDays,
            policy = policy,
            calculatedLateFee = lateFee,
            currentLateFee = receivable.lateFeeAmount
        )
    }
}

/**
 * 연체료 계산 상세 정보
 */
data class LateFeeCalculationDetails(
    val receivableId: UUID,
    val outstandingAmount: BigDecimal,
    val dueDate: LocalDate,
    val calculationDate: LocalDate,
    val overdueDays: Int,
    val policy: LateFeePolicy?,
    val calculatedLateFee: BigDecimal,
    val currentLateFee: BigDecimal
)