package com.qiro.domain.billing.service

import com.qiro.domain.billing.dto.*
import org.springframework.data.domain.Page
import org.springframework.data.domain.Pageable
import java.math.BigDecimal
import java.time.LocalDate
import java.time.LocalDateTime
import java.util.*

/**
 * 청구 및 요금 관리 서비스 인터페이스
 * 
 * 기존 데이터베이스 프로시저들을 백엔드 서비스로 이관:
 * - 요금 계산 (12개 프로시저)
 * - 요금 정책 (6개 프로시저) 
 * - 청구 및 결제 처리 (5개 프로시저)
 */
interface BillingService {
    
    // === 월별 관리비 산정 관리 ===
    
    /**
     * 월별 관리비 산정 생성
     * 기존 프로시저: bms.create_monthly_fee_calculation
     */
    fun createMonthlyFeeCalculation(request: CreateMonthlyFeeCalculationRequest): MonthlyFeeCalculationDto
    
    /**
     * 월별 관리비 산정 조회
     */
    fun getMonthlyFeeCalculation(companyId: UUID, calculationId: UUID): MonthlyFeeCalculationDto?
    
    /**
     * 월별 관리비 산정 목록 조회
     */
    fun getMonthlyFeeCalculations(companyId: UUID, pageable: Pageable): Page<MonthlyFeeCalculationDto>
    
    /**
     * 월별 관리비 산정 필터 조회
     */
    fun getMonthlyFeeCalculationsWithFilter(filter: BillingFilter, pageable: Pageable): Page<MonthlyFeeCalculationDto>
    
    /**
     * 월별 관리비 산정 상태 업데이트
     */
    fun updateCalculationStatus(calculationId: UUID, request: UpdateCalculationStatusRequest): MonthlyFeeCalculationDto
    
    /**
     * 월별 관리비 산정 승인
     */
    fun approveCalculation(companyId: UUID, calculationId: UUID, approvedBy: UUID): MonthlyFeeCalculationDto
    
    /**
     * 월별 관리비 산정 삭제 (비활성화)
     */
    fun deleteCalculation(companyId: UUID, calculationId: UUID): Boolean
    
    // === 호실별 관리비 관리 ===
    
    /**
     * 호실별 관리비 생성
     * 기존 프로시저: bms.create_unit_monthly_fee
     */
    fun createUnitMonthlyFee(request: CreateUnitMonthlyFeeRequest): UnitMonthlyFeeDto
    
    /**
     * 호실별 관리비 조회
     */
    fun getUnitMonthlyFee(companyId: UUID, feeId: UUID): UnitMonthlyFeeDto?
    
    /**
     * 계산별 호실 관리비 목록 조회
     */
    fun getUnitMonthlyFeesByCalculation(calculationId: UUID, pageable: Pageable): Page<UnitMonthlyFeeDto>
    
    /**
     * 호실별 관리비 이력 조회
     */
    fun getUnitMonthlyFeeHistory(companyId: UUID, unitId: UUID, pageable: Pageable): Page<UnitMonthlyFeeDto>
    
    /**
     * 호실별 관리비 필터 조회
     */
    fun getUnitMonthlyFeesWithFilter(filter: BillingFilter, pageable: Pageable): Page<UnitMonthlyFeeDto>
    
    /**
     * 호실별 관리비 결제 상태 업데이트
     */
    fun updatePaymentStatus(feeId: UUID, request: UpdatePaymentStatusRequest): UnitMonthlyFeeDto
    
    /**
     * 연체된 관리비 조회
     */
    fun getOverdueFees(companyId: UUID, pageable: Pageable): Page<UnitMonthlyFeeDto>
    
    // === 요금 계산 기능 ===
    
    /**
     * 면적 기준 관리비 계산
     * 기존 프로시저: bms.calculate_area_based_fee
     */
    fun calculateAreaBasedFee(unitArea: BigDecimal, ratePerSqm: BigDecimal): BigDecimal
    
    /**
     * 사용량 기준 관리비 계산
     * 기존 프로시저: bms.calculate_usage_based_fee
     */
    fun calculateUsageBasedFee(usageAmount: BigDecimal, unitRate: BigDecimal): BigDecimal
    
    /**
     * 구간별 차등 요금 계산
     * 기존 프로시저: bms.calculate_tiered_fee
     */
    fun calculateTieredFee(usageAmount: BigDecimal, tierRates: Map<String, Any>): BigDecimal
    
    /**
     * 비례 배분 계산
     * 기존 프로시저: bms.calculate_proportional_fee
     */
    fun calculateProportionalFee(
        unitBasisValue: BigDecimal, 
        totalBasisValue: BigDecimal, 
        totalAmount: BigDecimal
    ): BigDecimal
    
    /**
     * 연체료 계산
     * 기존 프로시저: bms.calculate_late_fee
     */
    fun calculateLateFee(
        originalAmount: BigDecimal, 
        dueDate: LocalDate, 
        calculationDate: LocalDate = LocalDate.now()
    ): LateFeeCalculationResult
    
    /**
     * 호실별 관리비 총액 계산
     * 기존 프로시저: bms.calculate_unit_total_fee
     */
    fun calculateUnitTotalFee(unitId: UUID, calculationPeriod: LocalDate): FeeCalculationResult
    
    /**
     * 관리비 검증
     * 기존 프로시저: bms.validate_fee_calculation
     */
    fun validateFeeCalculation(calculationId: UUID): ValidationResult
    
    /**
     * 관리비 재계산
     * 기존 프로시저: bms.recalculate_unit_fees
     */
    fun recalculateUnitFees(calculationId: UUID, recalculateAll: Boolean = false): List<UnitMonthlyFeeDto>
    
    // === 결제 처리 ===
    
    /**
     * 결제 처리
     * 기존 프로시저: bms.process_payment
     */
    fun processPayment(request: ProcessPaymentRequest): PaymentTransactionDto
    
    /**
     * 결제 거래 조회
     */
    fun getPaymentTransaction(companyId: UUID, transactionId: UUID): PaymentTransactionDto?
    
    /**
     * 결제 거래 목록 조회
     */
    fun getPaymentTransactions(companyId: UUID, pageable: Pageable): Page<PaymentTransactionDto>
    
    /**
     * 호실별 결제 이력 조회
     */
    fun getPaymentTransactionsByUnit(companyId: UUID, unitId: UUID, pageable: Pageable): Page<PaymentTransactionDto>
    
    /**
     * 결제 거래 필터 조회
     */
    fun getPaymentTransactionsWithFilter(filter: BillingFilter, pageable: Pageable): Page<PaymentTransactionDto>
    
    /**
     * 결제 취소
     */
    fun cancelPayment(companyId: UUID, transactionId: UUID, reason: String): PaymentTransactionDto
    
    /**
     * 부분 결제 처리
     */
    fun processPartialPayment(
        companyId: UUID, 
        feeId: UUID, 
        paymentAmount: BigDecimal, 
        paymentMethod: String
    ): PaymentTransactionDto
    
    // === 관리비 항목 관리 ===
    
    /**
     * 관리비 항목 생성
     */
    fun createMaintenanceFeeItem(request: CreateMaintenanceFeeItemRequest): MaintenanceFeeItemDto
    
    /**
     * 관리비 항목 조회
     */
    fun getMaintenanceFeeItem(companyId: UUID, itemId: UUID): MaintenanceFeeItemDto?
    
    /**
     * 관리비 항목 목록 조회
     */
    fun getMaintenanceFeeItems(companyId: UUID, pageable: Pageable): Page<MaintenanceFeeItemDto>
    
    /**
     * 유효한 관리비 항목 조회
     */
    fun getEffectiveFeeItems(companyId: UUID, referenceDate: LocalDate = LocalDate.now()): List<MaintenanceFeeItemDto>
    
    /**
     * 관리비 항목 수정
     */
    fun updateMaintenanceFeeItem(itemId: UUID, request: CreateMaintenanceFeeItemRequest): MaintenanceFeeItemDto
    
    /**
     * 관리비 항목 삭제 (비활성화)
     */
    fun deleteMaintenanceFeeItem(companyId: UUID, itemId: UUID): Boolean
    
    // === 통계 및 분석 ===
    
    /**
     * 청구 통계 조회
     */
    fun getBillingStatistics(companyId: UUID): BillingStatisticsDto
    
    /**
     * 월별 청구 요약 조회
     */
    fun getMonthlyBillingSummary(
        companyId: UUID, 
        year: Int, 
        month: Int
    ): MonthlyBillingSummaryDto?
    
    /**
     * 기간별 청구 요약 조회
     */
    fun getBillingSummaryByPeriod(
        companyId: UUID, 
        startDate: LocalDate, 
        endDate: LocalDate
    ): List<MonthlyBillingSummaryDto>
    
    /**
     * 호실별 결제 현황 조회
     */
    fun getUnitPaymentStatus(companyId: UUID, unitId: UUID): Map<String, Any>
    
    /**
     * 결제율 분석
     */
    fun getPaymentRateAnalysis(companyId: UUID, calculationId: UUID): Map<String, Any>
    
    /**
     * 연체 분석
     */
    fun getOverdueAnalysis(companyId: UUID): Map<String, Any>
    
    /**
     * 수납 대사 처리
     * 기존 프로시저: bms.process_payment_reconciliation
     */
    fun processPaymentReconciliation(
        companyId: UUID, 
        reconciliationDate: LocalDate, 
        reconciliationData: Map<String, Any>
    ): Map<String, Any>
    
    /**
     * 자동 청구 생성
     * 기존 프로시저: bms.generate_monthly_billing
     */
    fun generateMonthlyBilling(
        companyId: UUID, 
        buildingId: UUID?, 
        year: Int, 
        month: Int
    ): MonthlyFeeCalculationDto
    
    /**
     * 청구서 발송 처리
     */
    fun processBillDelivery(calculationId: UUID, deliveryMethod: String): Boolean
}