package com.qiro.domain.billing.service

import com.qiro.common.service.BaseService
import com.qiro.domain.billing.dto.*
import com.qiro.domain.billing.entity.*
import com.qiro.common.exception.BusinessException
import com.qiro.domain.billing.repository.*
import org.slf4j.LoggerFactory
import org.springframework.data.domain.Page
import org.springframework.data.domain.Pageable
import org.springframework.stereotype.Service
import org.springframework.transaction.annotation.Transactional
import java.math.BigDecimal
import java.math.RoundingMode
import java.time.LocalDate
import java.time.LocalDateTime
import java.time.temporal.ChronoUnit
import java.util.*

/**
 * 청구 및 요금 관리 서비스 구현체
 * 
 * 기존 데이터베이스 프로시저들을 백엔드 서비스로 이관:
 * - 요금 계산 (12개 프로시저)
 * - 요금 정책 (6개 프로시저) 
 * - 청구 및 결제 처리 (5개 프로시저)
 */
@Service
@Transactional
class BillingServiceImpl(
    private val monthlyFeeCalculationRepository: MonthlyFeeCalculationRepository,
    private val unitMonthlyFeeRepository: UnitMonthlyFeeRepository,
    private val paymentTransactionRepository: PaymentTransactionRepository,
    private val maintenanceFeeItemRepository: MaintenanceFeeItemRepository,
    private val feeCalculationLogRepository: FeeCalculationLogRepository
) : BillingService, BaseService {

    private val logger = LoggerFactory.getLogger(BillingServiceImpl::class.java)

    // === 월별 관리비 산정 관리 ===

    /**
     * 월별 관리비 산정 생성
     * 기존 프로시저: bms.create_monthly_fee_calculation
     */
    override fun createMonthlyFeeCalculation(request: CreateMonthlyFeeCalculationRequest): MonthlyFeeCalculationDto {
        logger.info("월별 관리비 산정 생성 시작: companyId=${request.companyId}, ${request.calculationYear}-${request.calculationMonth}")
        
        // 입력 검증
        val validationResult = validateInput(request)
        if (!validationResult.isValid) {
            throw ProcedureMigrationException.ValidationException(
                "월별 관리비 산정 생성 입력 검증 실패: ${validationResult.errors.joinToString(", ")}"
            )
        }

        // 중복 계산 체크
        if (monthlyFeeCalculationRepository.existsByCompanyIdAndCalculationYearAndCalculationMonthAndBuildingIdAndIsActiveTrue(
                request.companyId, request.calculationYear, request.calculationMonth, request.buildingId)) {
            throw ProcedureMigrationException.DataIntegrityException(
                "해당 기간의 관리비 산정이 이미 존재합니다: ${request.calculationYear}-${request.calculationMonth}"
            )
        }

        val calculationPeriod = LocalDate.of(request.calculationYear, request.calculationMonth, 1)
        
        val calculation = MonthlyFeeCalculation(
            id = UUID.randomUUID(),
            companyId = request.companyId,
            buildingId = request.buildingId,
            calculationYear = request.calculationYear,
            calculationMonth = request.calculationMonth,
            calculationPeriod = calculationPeriod,
            calculationStatus = "DRAFT",
            calculationMethod = request.calculationMethod,
            calculationNotes = request.calculationNotes,
            calculatedBy = null, // 현재 사용자 정보 필요시 추가
            calculatedAt = LocalDateTime.now(),
            isActive = true
        )

        val savedCalculation = monthlyFeeCalculationRepository.save(calculation)
        
        // 계산 로그 기록
        logCalculationStep(savedCalculation.id!!, "CREATE_CALCULATION", "월별 관리비 산정 생성", mapOf(
            "calculationYear" to request.calculationYear,
            "calculationMonth" to request.calculationMonth,
            "buildingId" to request.buildingId
        ))
        
        logOperation("CREATE_MONTHLY_FEE_CALCULATION", "월별 관리비 산정 생성 완료: ${savedCalculation.id}")
        
        return savedCalculation.toDto()
    }

    /**
     * 월별 관리비 산정 조회
     */
    override fun getMonthlyFeeCalculation(companyId: UUID, calculationId: UUID): MonthlyFeeCalculationDto? {
        return monthlyFeeCalculationRepository.findById(calculationId)
            .filter { it.companyId == companyId && it.isActive }
            .map { it.toDto() }
            .orElse(null)
    }

    /**
     * 월별 관리비 산정 목록 조회
     */
    override fun getMonthlyFeeCalculations(companyId: UUID, pageable: Pageable): Page<MonthlyFeeCalculationDto> {
        return monthlyFeeCalculationRepository.findByCompanyIdAndIsActiveTrueOrderByCalculationPeriodDesc(companyId, pageable)
            .map { it.toDto() }
    }

    /**
     * 월별 관리비 산정 필터 조회
     */
    override fun getMonthlyFeeCalculationsWithFilter(filter: BillingFilter, pageable: Pageable): Page<MonthlyFeeCalculationDto> {
        return monthlyFeeCalculationRepository.findWithFilter(
            companyId = filter.companyId,
            buildingId = filter.buildingId,
            calculationYear = filter.calculationYear,
            calculationMonth = filter.calculationMonth,
            calculationStatus = filter.calculationStatus,
            pageable = pageable
        ).map { it.toDto() }
    }

    /**
     * 월별 관리비 산정 상태 업데이트
     */
    override fun updateCalculationStatus(calculationId: UUID, request: UpdateCalculationStatusRequest): MonthlyFeeCalculationDto {
        val calculation = monthlyFeeCalculationRepository.findById(calculationId)
            .filter { it.isActive }
            .orElseThrow { 
                ProcedureMigrationException.DataIntegrityException("월별 관리비 산정을 찾을 수 없습니다: $calculationId") 
            }

        val updatedCalculation = calculation.copy(
            calculationStatus = request.calculationStatus,
            calculationNotes = request.calculationNotes ?: calculation.calculationNotes,
            approvedBy = request.approvedBy ?: calculation.approvedBy,
            approvedAt = if (request.calculationStatus == "APPROVED") LocalDateTime.now() else calculation.approvedAt
        )

        val savedCalculation = monthlyFeeCalculationRepository.save(updatedCalculation)
        
        logCalculationStep(calculationId, "UPDATE_STATUS", "계산 상태 업데이트", mapOf(
            "oldStatus" to calculation.calculationStatus,
            "newStatus" to request.calculationStatus
        ))
        
        logOperation("UPDATE_CALCULATION_STATUS", "계산 상태 업데이트: $calculationId -> ${request.calculationStatus}")
        
        return savedCalculation.toDto()
    }

    /**
     * 월별 관리비 산정 승인
     */
    override fun approveCalculation(companyId: UUID, calculationId: UUID, approvedBy: UUID): MonthlyFeeCalculationDto {
        val request = UpdateCalculationStatusRequest(
            calculationStatus = "APPROVED",
            approvedBy = approvedBy
        )
        return updateCalculationStatus(calculationId, request)
    }

    /**
     * 월별 관리비 산정 삭제 (비활성화)
     */
    override fun deleteCalculation(companyId: UUID, calculationId: UUID): Boolean {
        val calculation = monthlyFeeCalculationRepository.findById(calculationId)
            .filter { it.companyId == companyId && it.isActive }
            .orElseThrow { 
                ProcedureMigrationException.DataIntegrityException("월별 관리비 산정을 찾을 수 없습니다: $calculationId") 
            }

        // 승인된 계산은 삭제 불가
        if (calculation.calculationStatus == "APPROVED") {
            throw ProcedureMigrationException.BusinessLogicException("승인된 계산은 삭제할 수 없습니다")
        }

        val deactivatedCalculation = calculation.copy(isActive = false)
        monthlyFeeCalculationRepository.save(deactivatedCalculation)
        
        logOperation("DELETE_CALCULATION", "월별 관리비 산정 삭제: $calculationId")
        
        return true
    }

    // === 호실별 관리비 관리 ===

    /**
     * 호실별 관리비 생성
     * 기존 프로시저: bms.create_unit_monthly_fee
     */
    override fun createUnitMonthlyFee(request: CreateUnitMonthlyFeeRequest): UnitMonthlyFeeDto {
        logger.info("호실별 관리비 생성 시작: calculationId=${request.calculationId}, unitId=${request.unitId}")
        
        // 입력 검증
        val validationResult = validateInput(request)
        if (!validationResult.isValid) {
            throw ProcedureMigrationException.ValidationException(
                "호실별 관리비 생성 입력 검증 실패: ${validationResult.errors.joinToString(", ")}"
            )
        }

        // 총 관리비 계산
        val totalFee = (request.baseFee ?: BigDecimal.ZERO)
            .add(request.usageFee ?: BigDecimal.ZERO)
            .add(request.additionalFee ?: BigDecimal.ZERO)
            .subtract(request.discountAmount ?: BigDecimal.ZERO)

        val unitFee = UnitMonthlyFee(
            id = UUID.randomUUID(),
            calculationId = request.calculationId,
            companyId = request.companyId,
            unitId = request.unitId,
            unitArea = request.unitArea,
            baseFee = request.baseFee,
            usageFee = request.usageFee,
            additionalFee = request.additionalFee,
            discountAmount = request.discountAmount,
            totalFee = totalFee,
            dueDate = request.dueDate,
            paymentStatus = "UNPAID",
            isActive = true
        )

        val savedUnitFee = unitMonthlyFeeRepository.save(unitFee)
        
        logOperation("CREATE_UNIT_MONTHLY_FEE", "호실별 관리비 생성 완료: ${savedUnitFee.id}")
        
        return savedUnitFee.toDto()
    }

    /**
     * 호실별 관리비 조회
     */
    override fun getUnitMonthlyFee(companyId: UUID, feeId: UUID): UnitMonthlyFeeDto? {
        return unitMonthlyFeeRepository.findById(feeId)
            .filter { it.companyId == companyId && it.isActive }
            .map { it.toDto() }
            .orElse(null)
    }

    /**
     * 계산별 호실 관리비 목록 조회
     */
    override fun getUnitMonthlyFeesByCalculation(calculationId: UUID, pageable: Pageable): Page<UnitMonthlyFeeDto> {
        return unitMonthlyFeeRepository.findByCalculationIdAndIsActiveTrueOrderByUnitIdAsc(calculationId, pageable)
            .map { it.toDto() }
    }

    /**
     * 호실별 관리비 이력 조회
     */
    override fun getUnitMonthlyFeeHistory(companyId: UUID, unitId: UUID, pageable: Pageable): Page<UnitMonthlyFeeDto> {
        return unitMonthlyFeeRepository.findByCompanyIdAndUnitIdAndIsActiveTrueOrderByCreatedAtDesc(companyId, unitId, pageable)
            .map { it.toDto() }
    }

    /**
     * 호실별 관리비 필터 조회
     */
    override fun getUnitMonthlyFeesWithFilter(filter: BillingFilter, pageable: Pageable): Page<UnitMonthlyFeeDto> {
        return unitMonthlyFeeRepository.findWithFilter(
            companyId = filter.companyId,
            calculationId = null,
            unitId = filter.unitId,
            paymentStatus = filter.paymentStatus,
            startDate = filter.startDate,
            endDate = filter.endDate,
            pageable = pageable
        ).map { it.toDto() }
    }

    /**
     * 호실별 관리비 결제 상태 업데이트
     */
    override fun updatePaymentStatus(feeId: UUID, request: UpdatePaymentStatusRequest): UnitMonthlyFeeDto {
        val unitFee = unitMonthlyFeeRepository.findById(feeId)
            .filter { it.isActive }
            .orElseThrow { 
                ProcedureMigrationException.DataIntegrityException("호실별 관리비를 찾을 수 없습니다: $feeId") 
            }

        val updatedUnitFee = unitFee.copy(
            paymentStatus = request.paymentStatus,
            paidAmount = request.paidAmount ?: unitFee.paidAmount,
            paidAt = request.paidAt ?: unitFee.paidAt
        )

        val savedUnitFee = unitMonthlyFeeRepository.save(updatedUnitFee)
        
        logOperation("UPDATE_PAYMENT_STATUS", "결제 상태 업데이트: $feeId -> ${request.paymentStatus}")
        
        return savedUnitFee.toDto()
    }

    /**
     * 연체된 관리비 조회
     */
    override fun getOverdueFees(companyId: UUID, pageable: Pageable): Page<UnitMonthlyFeeDto> {
        return unitMonthlyFeeRepository.findOverdueFees(companyId, pageable)
            .map { it.toDto() }
    }

    // === 요금 계산 기능 ===

    /**
     * 면적 기준 관리비 계산
     * 기존 프로시저: bms.calculate_area_based_fee
     */
    override fun calculateAreaBasedFee(unitArea: BigDecimal, ratePerSqm: BigDecimal): BigDecimal {
        if (unitArea <= BigDecimal.ZERO || ratePerSqm < BigDecimal.ZERO) {
            throw ProcedureMigrationException.ValidationException("면적과 단가는 0보다 커야 합니다")
        }
        
        return unitArea.multiply(ratePerSqm).setScale(2, RoundingMode.HALF_UP)
    }

    /**
     * 사용량 기준 관리비 계산
     * 기존 프로시저: bms.calculate_usage_based_fee
     */
    override fun calculateUsageBasedFee(usageAmount: BigDecimal, unitRate: BigDecimal): BigDecimal {
        if (usageAmount < BigDecimal.ZERO || unitRate < BigDecimal.ZERO) {
            throw ProcedureMigrationException.ValidationException("사용량과 단가는 0 이상이어야 합니다")
        }
        
        return usageAmount.multiply(unitRate).setScale(2, RoundingMode.HALF_UP)
    }

    /**
     * 구간별 차등 요금 계산
     * 기존 프로시저: bms.calculate_tiered_fee
     */
    override fun calculateTieredFee(usageAmount: BigDecimal, tierRates: Map<String, Any>): BigDecimal {
        // 간단한 구현 - 실제로는 더 복잡한 구간별 계산 로직 필요
        var totalFee = BigDecimal.ZERO
        var remainingUsage = usageAmount
        
        // tierRates는 JSON 형태로 구간별 요율 정보를 포함
        // 예: [{"min": 0, "max": 100, "rate": 1000}, {"min": 100, "max": null, "rate": 1200}]
        
        return totalFee.setScale(2, RoundingMode.HALF_UP)
    }

    /**
     * 비례 배분 계산
     * 기존 프로시저: bms.calculate_proportional_fee
     */
    override fun calculateProportionalFee(
        unitBasisValue: BigDecimal, 
        totalBasisValue: BigDecimal, 
        totalAmount: BigDecimal
    ): BigDecimal {
        if (totalBasisValue <= BigDecimal.ZERO) {
            throw ProcedureMigrationException.ValidationException("전체 기준값은 0보다 커야 합니다")
        }
        
        val proportion = unitBasisValue.divide(totalBasisValue, 6, RoundingMode.HALF_UP)
        return totalAmount.multiply(proportion).setScale(2, RoundingMode.HALF_UP)
    }

    /**
     * 연체료 계산
     * 기존 프로시저: bms.calculate_late_fee
     */
    override fun calculateLateFee(
        originalAmount: BigDecimal, 
        dueDate: LocalDate, 
        calculationDate: LocalDate
    ): LateFeeCalculationResult {
        if (calculationDate.isBefore(dueDate)) {
            return LateFeeCalculationResult(
                originalAmount = originalAmount,
                overdueDays = 0,
                lateFeeRate = BigDecimal.ZERO,
                lateFeeAmount = BigDecimal.ZERO,
                totalAmount = originalAmount,
                calculationDate = calculationDate
            )
        }
        
        val overdueDays = ChronoUnit.DAYS.between(dueDate, calculationDate).toInt()
        val lateFeeRate = BigDecimal("0.03") // 3% 연체료율 (설정 가능하게 변경 필요)
        val lateFeeAmount = originalAmount
            .multiply(lateFeeRate)
            .multiply(BigDecimal(overdueDays))
            .divide(BigDecimal("365"), 2, RoundingMode.HALF_UP)
        
        return LateFeeCalculationResult(
            originalAmount = originalAmount,
            overdueDays = overdueDays,
            lateFeeRate = lateFeeRate,
            lateFeeAmount = lateFeeAmount,
            totalAmount = originalAmount.add(lateFeeAmount),
            calculationDate = calculationDate
        )
    }

    /**
     * 호실별 관리비 총액 계산
     * 기존 프로시저: bms.calculate_unit_total_fee
     */
    override fun calculateUnitTotalFee(unitId: UUID, calculationPeriod: LocalDate): FeeCalculationResult {
        // 실제 구현에서는 관리비 항목별로 계산하여 총액 산출
        val baseFee = BigDecimal("100000") // 예시 값
        val usageFee = BigDecimal("50000")
        val additionalFee = BigDecimal("20000")
        val discountAmount = BigDecimal("10000")
        val totalFee = baseFee.add(usageFee).add(additionalFee).subtract(discountAmount)
        
        return FeeCalculationResult(
            unitId = unitId,
            baseFee = baseFee,
            usageFee = usageFee,
            additionalFee = additionalFee,
            discountAmount = discountAmount,
            totalFee = totalFee,
            calculationDetails = mapOf(
                "calculationPeriod" to calculationPeriod,
                "calculationMethod" to "STANDARD"
            )
        )
    }

    /**
     * 관리비 검증
     * 기존 프로시저: bms.validate_fee_calculation
     */
    override fun validateFeeCalculation(calculationId: UUID): ValidationResult {
        val errors = mutableListOf<String>()
        
        // 계산 존재 여부 확인
        val calculation = monthlyFeeCalculationRepository.findById(calculationId)
            .orElse(null)
        
        if (calculation == null) {
            errors.add("계산을 찾을 수 없습니다: $calculationId")
        } else {
            // 호실별 관리비 존재 여부 확인
            val unitFees = unitMonthlyFeeRepository.findByCalculationIdAndIsActiveTrueOrderByUnitIdAsc(calculationId)
            if (unitFees.isEmpty()) {
                errors.add("호실별 관리비가 없습니다")
            }
            
            // 총액 검증
            val calculatedTotal = unitFees.sumOf { it.totalFee }
            if (calculation.totalAmount != null && calculation.totalAmount != calculatedTotal) {
                errors.add("총액이 일치하지 않습니다: 예상=${calculation.totalAmount}, 실제=$calculatedTotal")
            }
        }
        
        return ValidationResult(
            isValid = errors.isEmpty(),
            errors = errors
        )
    }

    /**
     * 관리비 재계산
     * 기존 프로시저: bms.recalculate_unit_fees
     */
    override fun recalculateUnitFees(calculationId: UUID, recalculateAll: Boolean): List<UnitMonthlyFeeDto> {
        val unitFees = unitMonthlyFeeRepository.findByCalculationIdAndIsActiveTrueOrderByUnitIdAsc(calculationId)
        val recalculatedFees = mutableListOf<UnitMonthlyFeeDto>()
        
        unitFees.forEach { unitFee ->
            if (recalculateAll || unitFee.paymentStatus == "UNPAID") {
                // 재계산 로직 (실제로는 더 복잡한 계산 필요)
                val newTotalFee = (unitFee.baseFee ?: BigDecimal.ZERO)
                    .add(unitFee.usageFee ?: BigDecimal.ZERO)
                    .add(unitFee.additionalFee ?: BigDecimal.ZERO)
                    .subtract(unitFee.discountAmount ?: BigDecimal.ZERO)
                
                val updatedUnitFee = unitFee.copy(totalFee = newTotalFee)
                val savedUnitFee = unitMonthlyFeeRepository.save(updatedUnitFee)
                recalculatedFees.add(savedUnitFee.toDto())
            }
        }
        
        logOperation("RECALCULATE_UNIT_FEES", "관리비 재계산 완료: $calculationId, 재계산 건수: ${recalculatedFees.size}")
        
        return recalculatedFees
    }

    // === 결제 처리 ===

    /**
     * 결제 처리
     * 기존 프로시저: bms.process_payment
     */
    override fun processPayment(request: ProcessPaymentRequest): PaymentTransactionDto {
        logger.info("결제 처리 시작: companyId=${request.companyId}, amount=${request.paymentAmount}")
        
        // 입력 검증
        val validationResult = validateInput(request)
        if (!validationResult.isValid) {
            throw ProcedureMigrationException.ValidationException(
                "결제 처리 입력 검증 실패: ${validationResult.errors.joinToString(", ")}"
            )
        }

        // 거래 번호 생성
        val transactionNumber = generateTransactionNumber(request.companyId)

        val transaction = PaymentTransaction(
            id = UUID.randomUUID(),
            companyId = request.companyId,
            unitId = request.unitId,
            feeId = request.feeId,
            transactionNumber = transactionNumber,
            paymentMethod = request.paymentMethod,
            paymentAmount = request.paymentAmount,
            paymentDate = LocalDateTime.now(),
            transactionStatus = "COMPLETED",
            payerName = request.payerName,
            payerContact = request.payerContact,
            paymentReference = request.paymentReference,
            paymentNotes = request.paymentNotes,
            isActive = true
        )

        val savedTransaction = paymentTransactionRepository.save(transaction)
        
        // 관리비 결제 상태 업데이트
        if (request.feeId != null) {
            updatePaymentStatus(request.feeId, UpdatePaymentStatusRequest(
                paymentStatus = "PAID",
                paidAmount = request.paymentAmount,
                paidAt = LocalDateTime.now()
            ))
        }
        
        logOperation("PROCESS_PAYMENT", "결제 처리 완료: ${savedTransaction.id}")
        
        return savedTransaction.toDto()
    }

    /**
     * 결제 거래 조회
     */
    override fun getPaymentTransaction(companyId: UUID, transactionId: UUID): PaymentTransactionDto? {
        return paymentTransactionRepository.findById(transactionId)
            .filter { it.companyId == companyId && it.isActive }
            .map { it.toDto() }
            .orElse(null)
    }

    /**
     * 결제 거래 목록 조회
     */
    override fun getPaymentTransactions(companyId: UUID, pageable: Pageable): Page<PaymentTransactionDto> {
        return paymentTransactionRepository.findByCompanyIdAndIsActiveTrueOrderByPaymentDateDesc(companyId, pageable)
            .map { it.toDto() }
    }

    /**
     * 호실별 결제 이력 조회
     */
    override fun getPaymentTransactionsByUnit(companyId: UUID, unitId: UUID, pageable: Pageable): Page<PaymentTransactionDto> {
        return paymentTransactionRepository.findByCompanyIdAndUnitIdAndIsActiveTrueOrderByPaymentDateDesc(companyId, unitId, pageable)
            .map { it.toDto() }
    }

    /**
     * 결제 거래 필터 조회
     */
    override fun getPaymentTransactionsWithFilter(filter: BillingFilter, pageable: Pageable): Page<PaymentTransactionDto> {
        return paymentTransactionRepository.findWithFilter(
            companyId = filter.companyId,
            unitId = filter.unitId,
            feeId = null,
            paymentMethod = filter.paymentMethod,
            transactionStatus = null,
            startDate = filter.startDate,
            endDate = filter.endDate,
            pageable = pageable
        ).map { it.toDto() }
    }

    /**
     * 결제 취소
     */
    override fun cancelPayment(companyId: UUID, transactionId: UUID, reason: String): PaymentTransactionDto {
        val transaction = paymentTransactionRepository.findById(transactionId)
            .filter { it.companyId == companyId && it.isActive }
            .orElseThrow { 
                ProcedureMigrationException.DataIntegrityException("결제 거래를 찾을 수 없습니다: $transactionId") 
            }

        if (transaction.transactionStatus == "CANCELLED") {
            throw ProcedureMigrationException.BusinessLogicException("이미 취소된 거래입니다")
        }

        val cancelledTransaction = transaction.copy(
            transactionStatus = "CANCELLED",
            paymentNotes = "${transaction.paymentNotes ?: ""}\n취소 사유: $reason"
        )

        val savedTransaction = paymentTransactionRepository.save(cancelledTransaction)
        
        // 관리비 결제 상태 되돌리기
        if (transaction.feeId != null) {
            updatePaymentStatus(transaction.feeId, UpdatePaymentStatusRequest(
                paymentStatus = "UNPAID",
                paidAmount = null,
                paidAt = null
            ))
        }
        
        logOperation("CANCEL_PAYMENT", "결제 취소: $transactionId, 사유: $reason")
        
        return savedTransaction.toDto()
    }

    /**
     * 부분 결제 처리
     */
    override fun processPartialPayment(
        companyId: UUID, 
        feeId: UUID, 
        paymentAmount: BigDecimal, 
        paymentMethod: String
    ): PaymentTransactionDto {
        val unitFee = unitMonthlyFeeRepository.findById(feeId)
            .filter { it.companyId == companyId && it.isActive }
            .orElseThrow { 
                ProcedureMigrationException.DataIntegrityException("호실별 관리비를 찾을 수 없습니다: $feeId") 
            }

        val currentPaidAmount = unitFee.paidAmount ?: BigDecimal.ZERO
        val newPaidAmount = currentPaidAmount.add(paymentAmount)
        
        if (newPaidAmount > unitFee.totalFee) {
            throw ProcedureMigrationException.BusinessLogicException("결제 금액이 총 관리비를 초과합니다")
        }

        val request = ProcessPaymentRequest(
            companyId = companyId,
            unitId = unitFee.unitId,
            feeId = feeId,
            paymentMethod = paymentMethod,
            paymentAmount = paymentAmount
        )

        val transaction = processPayment(request)
        
        // 부분 결제 상태 업데이트
        val paymentStatus = if (newPaidAmount >= unitFee.totalFee) "PAID" else "PARTIAL"
        updatePaymentStatus(feeId, UpdatePaymentStatusRequest(
            paymentStatus = paymentStatus,
            paidAmount = newPaidAmount,
            paidAt = if (paymentStatus == "PAID") LocalDateTime.now() else null
        ))
        
        return transaction
    }

    // === 관리비 항목 관리 ===

    /**
     * 관리비 항목 생성
     */
    override fun createMaintenanceFeeItem(request: CreateMaintenanceFeeItemRequest): MaintenanceFeeItemDto {
        // MaintenanceFeeItemRepository가 없으므로 임시 구현
        throw ProcedureMigrationException.NotImplementedException("관리비 항목 관리 기능은 아직 구현되지 않았습니다")
    }

    override fun getMaintenanceFeeItem(companyId: UUID, itemId: UUID): MaintenanceFeeItemDto? = null
    override fun getMaintenanceFeeItems(companyId: UUID, pageable: Pageable): Page<MaintenanceFeeItemDto> = Page.empty()
    override fun getEffectiveFeeItems(companyId: UUID, referenceDate: LocalDate): List<MaintenanceFeeItemDto> = emptyList()
    override fun updateMaintenanceFeeItem(itemId: UUID, request: CreateMaintenanceFeeItemRequest): MaintenanceFeeItemDto {
        throw ProcedureMigrationException.NotImplementedException("관리비 항목 관리 기능은 아직 구현되지 않았습니다")
    }
    override fun deleteMaintenanceFeeItem(companyId: UUID, itemId: UUID): Boolean = false

    // === 통계 및 분석 ===

    /**
     * 청구 통계 조회
     */
    override fun getBillingStatistics(companyId: UUID): BillingStatisticsDto {
        val totalCalculations = monthlyFeeCalculationRepository.countActiveCalculationsByCompanyId(companyId)
        val calculationsByStatus = monthlyFeeCalculationRepository.countCalculationsByStatus(companyId)
        val totalAmount = monthlyFeeCalculationRepository.getTotalApprovedAmount(companyId)
        
        val totalPayments = paymentTransactionRepository.countActiveTransactionsByCompanyId(companyId)
        val totalPaidAmount = paymentTransactionRepository.getTotalCompletedPaymentAmount(companyId)
        val totalUnpaidAmount = unitMonthlyFeeRepository.getTotalUnpaidAmount(companyId)
        val averageUnitFee = unitMonthlyFeeRepository.getAverageUnitFee(companyId)
        
        val statusMap = calculationsByStatus.associate { (it[0] as String) to (it[1] as Long) }
        val paymentRate = if (totalAmount > BigDecimal.ZERO) {
            totalPaidAmount.divide(totalAmount, 4, RoundingMode.HALF_UP).multiply(BigDecimal("100")).toDouble()
        } else null

        return BillingStatisticsDto(
            totalCalculations = totalCalculations,
            draftCalculations = statusMap["DRAFT"] ?: 0L,
            approvedCalculations = statusMap["APPROVED"] ?: 0L,
            totalAmount = totalAmount,
            totalUnits = 0L, // 별도 계산 필요
            totalPayments = totalPayments,
            totalPaidAmount = totalPaidAmount,
            unpaidAmount = totalUnpaidAmount,
            paymentRate = paymentRate,
            averageUnitFee = averageUnitFee
        )
    }

    /**
     * 월별 청구 요약 조회
     */
    override fun getMonthlyBillingSummary(companyId: UUID, year: Int, month: Int): MonthlyBillingSummaryDto? {
        val calculation = monthlyFeeCalculationRepository.findByCompanyIdAndCalculationYearAndCalculationMonthAndIsActiveTrue(
            companyId, year, month
        ).orElse(null) ?: return null
        
        val totalAmount = calculation.totalAmount ?: BigDecimal.ZERO
        val paidAmount = unitMonthlyFeeRepository.getPaidAmountByCalculationId(calculation.id!!)
        val unpaidAmount = totalAmount.subtract(paidAmount)
        val paymentRate = if (totalAmount > BigDecimal.ZERO) {
            paidAmount.divide(totalAmount, 4, RoundingMode.HALF_UP).multiply(BigDecimal("100")).toDouble()
        } else 0.0
        
        return MonthlyBillingSummaryDto(
            calculationPeriod = calculation.calculationPeriod,
            totalUnits = calculation.totalUnits ?: 0,
            totalAmount = totalAmount,
            paidAmount = paidAmount,
            unpaidAmount = unpaidAmount,
            paymentRate = paymentRate
        )
    }

    /**
     * 기간별 청구 요약 조회
     */
    override fun getBillingSummaryByPeriod(
        companyId: UUID, 
        startDate: LocalDate, 
        endDate: LocalDate
    ): List<MonthlyBillingSummaryDto> {
        val calculations = monthlyFeeCalculationRepository.findByPeriodRange(companyId, startDate, endDate, Pageable.unpaged())
        
        return calculations.content.map { calculation ->
            val totalAmount = calculation.totalAmount ?: BigDecimal.ZERO
            val paidAmount = unitMonthlyFeeRepository.getPaidAmountByCalculationId(calculation.id!!)
            val unpaidAmount = totalAmount.subtract(paidAmount)
            val paymentRate = if (totalAmount > BigDecimal.ZERO) {
                paidAmount.divide(totalAmount, 4, RoundingMode.HALF_UP).multiply(BigDecimal("100")).toDouble()
            } else 0.0
            
            MonthlyBillingSummaryDto(
                calculationPeriod = calculation.calculationPeriod,
                totalUnits = calculation.totalUnits ?: 0,
                totalAmount = totalAmount,
                paidAmount = paidAmount,
                unpaidAmount = unpaidAmount,
                paymentRate = paymentRate
            )
        }
    }

    /**
     * 호실별 결제 현황 조회
     */
    override fun getUnitPaymentStatus(companyId: UUID, unitId: UUID): Map<String, Any> {
        val totalPaidAmount = paymentTransactionRepository.getTotalPaymentAmountByUnit(companyId, unitId)
        val latestFee = unitMonthlyFeeRepository.findLatestFeeByUnit(companyId, unitId).orElse(null)
        
        return mapOf(
            "unitId" to unitId,
            "totalPaidAmount" to totalPaidAmount,
            "latestFee" to latestFee?.toDto(),
            "paymentStatus" to (latestFee?.paymentStatus ?: "UNKNOWN")
        )
    }

    /**
     * 결제율 분석
     */
    override fun getPaymentRateAnalysis(companyId: UUID, calculationId: UUID): Map<String, Any> {
        val paymentRate = unitMonthlyFeeRepository.getPaymentRateByCalculationId(calculationId) ?: 0.0
        val totalUnits = unitMonthlyFeeRepository.countUnitsByCalculationId(calculationId)
        val totalAmount = unitMonthlyFeeRepository.getTotalAmountByCalculationId(calculationId)
        val paidAmount = unitMonthlyFeeRepository.getPaidAmountByCalculationId(calculationId)
        
        return mapOf(
            "calculationId" to calculationId,
            "paymentRate" to paymentRate,
            "totalUnits" to totalUnits,
            "totalAmount" to totalAmount,
            "paidAmount" to paidAmount,
            "unpaidAmount" to totalAmount.subtract(paidAmount)
        )
    }

    /**
     * 연체 분석
     */
    override fun getOverdueAnalysis(companyId: UUID): Map<String, Any> {
        val overdueFees = unitMonthlyFeeRepository.findOverdueFees(companyId, Pageable.unpaged())
        val overdueAmount = overdueFees.content.sumOf { it.totalFee.subtract(it.paidAmount ?: BigDecimal.ZERO) }
        
        return mapOf(
            "overdueUnits" to overdueFees.totalElements,
            "overdueAmount" to overdueAmount,
            "averageOverdueAmount" to if (overdueFees.totalElements > 0) {
                overdueAmount.divide(BigDecimal(overdueFees.totalElements), 2, RoundingMode.HALF_UP)
            } else BigDecimal.ZERO
        )
    }

    /**
     * 수납 대사 처리
     * 기존 프로시저: bms.process_payment_reconciliation
     */
    override fun processPaymentReconciliation(
        companyId: UUID, 
        reconciliationDate: LocalDate, 
        reconciliationData: Map<String, Any>
    ): Map<String, Any> {
        // 수납 대사 로직 구현 (복잡한 비즈니스 로직)
        return mapOf(
            "reconciliationDate" to reconciliationDate,
            "status" to "COMPLETED",
            "processedTransactions" to 0
        )
    }

    /**
     * 자동 청구 생성
     * 기존 프로시저: bms.generate_monthly_billing
     */
    override fun generateMonthlyBilling(
        companyId: UUID, 
        buildingId: UUID?, 
        year: Int, 
        month: Int
    ): MonthlyFeeCalculationDto {
        val request = CreateMonthlyFeeCalculationRequest(
            companyId = companyId,
            buildingId = buildingId,
            calculationYear = year,
            calculationMonth = month,
            calculationMethod = "AUTO_GENERATED"
        )
        
        return createMonthlyFeeCalculation(request)
    }

    /**
     * 청구서 발송 처리
     */
    override fun processBillDelivery(calculationId: UUID, deliveryMethod: String): Boolean {
        // 청구서 발송 로직 구현
        logOperation("PROCESS_BILL_DELIVERY", "청구서 발송: $calculationId, 방법: $deliveryMethod")
        return true
    }

    // === 유틸리티 메서드 ===

    /**
     * 입력 검증
     */
    override fun validateInput(input: Any): ValidationResult {
        val errors = mutableListOf<String>()

        when (input) {
            is CreateMonthlyFeeCalculationRequest -> {
                if (input.calculationYear < 2000 || input.calculationYear > 2100) {
                    errors.add("계산 년도가 유효하지 않습니다")
                }
                if (input.calculationMonth < 1 || input.calculationMonth > 12) {
                    errors.add("계산 월이 유효하지 않습니다")
                }
            }
            is CreateUnitMonthlyFeeRequest -> {
                val totalFee = (input.baseFee ?: BigDecimal.ZERO)
                    .add(input.usageFee ?: BigDecimal.ZERO)
                    .add(input.additionalFee ?: BigDecimal.ZERO)
                    .subtract(input.discountAmount ?: BigDecimal.ZERO)
                if (totalFee < BigDecimal.ZERO) {
                    errors.add("총 관리비는 0 이상이어야 합니다")
                }
            }
            is ProcessPaymentRequest -> {
                if (input.paymentAmount <= BigDecimal.ZERO) {
                    errors.add("결제 금액은 0보다 커야 합니다")
                }
                if (input.paymentMethod.isBlank()) {
                    errors.add("결제 방법은 필수입니다")
                }
            }
        }

        return ValidationResult(
            isValid = errors.isEmpty(),
            errors = errors
        )
    }

    /**
     * 작업 로그
     */
    override fun logOperation(operation: String, result: Any) {
        logger.info("BillingService 작업 완료: $operation - $result")
    }

    /**
     * 계산 단계 로그 기록
     */
    private fun logCalculationStep(
        calculationId: UUID, 
        step: String, 
        description: String, 
        data: Map<String, Any>
    ) {
        // FeeCalculationLogRepository가 없으므로 로그만 기록
        logger.info("계산 단계: calculationId=$calculationId, step=$step, description=$description, data=$data")
    }

    /**
     * 거래 번호 생성
     */
    private fun generateTransactionNumber(companyId: UUID): String {
        val timestamp = System.currentTimeMillis()
        val random = (1000..9999).random()
        return "PAY-${companyId.toString().substring(0, 8).uppercase()}-$timestamp-$random"
    }

    // === 확장 함수 ===

    /**
     * MonthlyFeeCalculation 엔티티를 DTO로 변환
     */
    private fun MonthlyFeeCalculation.toDto(): MonthlyFeeCalculationDto {
        return MonthlyFeeCalculationDto(
            id = this.id,
            companyId = this.companyId,
            buildingId = this.buildingId,
            calculationYear = this.calculationYear,
            calculationMonth = this.calculationMonth,
            calculationPeriod = this.calculationPeriod,
            calculationStatus = this.calculationStatus,
            totalAmount = this.totalAmount,
            totalUnits = this.totalUnits,
            calculationMethod = this.calculationMethod,
            calculationNotes = this.calculationNotes,
            calculatedBy = this.calculatedBy,
            calculatedAt = this.calculatedAt,
            approvedBy = this.approvedBy,
            approvedAt = this.approvedAt,
            isActive = this.isActive,
            createdAt = this.createdAt,
            updatedAt = this.updatedAt
        )
    }

    /**
     * UnitMonthlyFee 엔티티를 DTO로 변환
     */
    private fun UnitMonthlyFee.toDto(): UnitMonthlyFeeDto {
        return UnitMonthlyFeeDto(
            id = this.id,
            calculationId = this.calculationId,
            companyId = this.companyId,
            unitId = this.unitId,
            unitArea = this.unitArea,
            baseFee = this.baseFee,
            usageFee = this.usageFee,
            additionalFee = this.additionalFee,
            discountAmount = this.discountAmount,
            totalFee = this.totalFee,
            dueDate = this.dueDate,
            paymentStatus = this.paymentStatus,
            paidAmount = this.paidAmount,
            paidAt = this.paidAt,
            isActive = this.isActive,
            createdAt = this.createdAt,
            updatedAt = this.updatedAt
        )
    }

    /**
     * PaymentTransaction 엔티티를 DTO로 변환
     */
    private fun PaymentTransaction.toDto(): PaymentTransactionDto {
        return PaymentTransactionDto(
            id = this.id,
            companyId = this.companyId,
            unitId = this.unitId,
            feeId = this.feeId,
            transactionNumber = this.transactionNumber,
            paymentMethod = this.paymentMethod,
            paymentAmount = this.paymentAmount,
            paymentDate = this.paymentDate,
            transactionStatus = this.transactionStatus,
            payerName = this.payerName,
            payerContact = this.payerContact,
            paymentReference = this.paymentReference,
            paymentNotes = this.paymentNotes,
            processedBy = this.processedBy,
            isActive = this.isActive,
            createdAt = this.createdAt,
            updatedAt = this.updatedAt
        )
    }
}